using ArrayViews

const __tracking_root__ = dirname(@__FILE__);
require(abspath(joinpath(__tracking_root__, "..", "multiscale.jl")));
require(abspath(joinpath(__tracking_root__, "simtypes.jl")));

#! Check to see if a pair of indices fall inside a bounds
function inbounds(i::Int, j::Int, sbounds::Matrix{Int64})
  return (all(b -> b <= i, view(sbounds, :, 1)) &&
          all(b -> b >= i, view(sbounds, :, 2)) &&
          all(b -> b <= j, view(sbounds, :, 3)) &&
          all(b -> b >= j, view(sbounds, :, 4)));
end

#! Simulate mass transfer across interface cells
#!
#! \param sim FreeSurfSim object
#! \param sbounds Bounds where fluid can be streaming
function masstransfer!(sim::FreeSurfSim, sbounds::Matrix{Int64})
  t = sim.tracker;
  lat = sim.lat;
  msm = sim.msm;

  for node in t.interfacels
    i, j = node.val;
    if !inbounds(i, j, sbounds)
      continue;
    end
    for k=1:lat.n
      i_nbr = i + lat.c[1,k];
      j_nbr = j + lat.c[2,k];
      if t.state[i_nbr,j_nbr] == GAS || !inbounds(i_nbr, j_nbr, sbounds)
        continue;
      elseif t.state[i_nbr,j_nbr] == FLUID
        opk = opp_lat_vec(lat, k);
        t.M[i,j] += lat.f[opk,i_nbr,j_nbr] - lat.f[k,i,j] # m in - m out
      elseif t.state[i_nbr,j_nbr] == INTERFACE
        opk = opp_lat_vec(lat, k);
        epsx = t.M[i,j] / msm.rho[i,j];
        epsxe = t.M[i_nbr,j_nbr] / msm.rho[i_nbr,j_nbr];
        t.M[i,j] += (epsx + epsxe) / 2 * lat.f[opk,i_nbr,j_nbr] - lat.f[k,i,j];
      else
        @assert false && "state not understood or invalid";
      end
    end
  end
end

#! Update cell states of tracker
#!
#! \param sim FreeSurfSim object
#! \param sbounds Bounds where fluid can be streaming
function update!(sim::FreeSurfSim, sbounds::Matrix{Int64})
  t = sim.tracker;
  msm = sim.msm;

  for node in t.interfacels
    i, j = node.val;
    if !inbounds(i, j, sbounds)
      continue;
    end
    
    if t.M[i,j] < 0
      t.M[i,j] = 0;
      t.state[i,j] = GAS;
      remove!(lst, node); # no longer an interface cell
      for ci in (-1, 1), cj in (-1, 1)
        if t.state[i+ci,j+cj] == FLUID
          t.state[i+ci,j+cj] = INTERFACE;
          push!(t.interfacels, (i+ci, j+cj)); # push into interface list
        end
      end
      for ci in (-1, 1)
        if t.state[i+ci,j] == FLUID
          t.state[i+ci,j] = INTERFACE;
          push!(t.interfacels, (i+ci, j)); # push into interface list
        end
      end
      for cj in (-1, 1)
        if t.state[i,j+cj] == FLUID
          t.state[i,j+cj] = INTERFACE;
          push!(t.interfacels, (i, j+cj)); # push into interface list
        end
      end
    elseif t.M[i,j] > msm.rho[i,j]
      t.M[i,j] = msm.rho[i,j];
      t.state[i,j] = FLUID;
      remove!(lst, node); # no longer an interface cell
      for ci in (-1, 1), cj in (-1, 1)
        if t.state[i+ci,j+cj] == GAS
          t.state[i+ci,j+cj] = INTERFACE;
          push!(t.interfacels, (i+ci, j+cj)); # push into interface list
        end
      end
      for ci in (-1, 1)
        if t.state[i+ci,j] == GAS
          t.state[i+ci,j] = INTERFACE;
          push!(t.interfacels, (i+ci, j)); # push into interface list
        end
      end
      for cj in (-1, 1)
        if t.state[i,j+cj] == GAS
          t.state[i,j+cj] = INTERFACE;
          push!(t.interfacels, (i, j+cj)); # push into interface list
        end
      end
    end
  end
end