const __modcol_root__ = dirname(@__FILE__);
require(abspath(joinpath(__modcol_root__, "constitutive.jl")));
require(abspath(joinpath(__modcol_root__, "forcing.jl")));
require(abspath(joinpath(__modcol_root__, "equilibrium.jl")));
require(abspath(joinpath(__modcol_root__, "..", "lattice.jl")));
require(abspath(joinpath(__modcol_root__, "mrt_matrices.jl")));
require(abspath(joinpath(__modcol_root__, "..", "multiscale.jl")));
require(abspath(joinpath(__modcol_root__, "..", "numerics.jl")));
require(abspath(joinpath(__modcol_root__, "..", "sim", "simtypes.jl")));

#! Single relaxation time collision function for incompressible Newtonian flow
#!
#! \param sim Simulation object
#! \param bounds Boundaries that define active parts of the lattice
#! \param constit_relation_f Constitutive relationship
function init_col_srt! (sim::Sim, bounds::Matrix{Int64},
                        constit_relation_f::Function)
  return (sim::Sim, bounds::Matrix{Int64}) -> begin
    lat = sim.lat;
    msm = sim.msm;
    const ni, nj = size(msm.rho);
    const nbounds = size(bounds, 2);

    for r = 1:nbounds
      i_min, i_max, j_min, j_max = bounds[:,r];
      for j = j_min:j_max, i = i_min:i_max
        rhoij = msm.rho[i,j];
        uij = msm.u[:,i,j];
        feq = Array(Float64, lat.n); 
        fneq = Array(Float64, lat.n); 
        for k = 1:lat.n 
          feq[k] = feq_incomp(lat, rhoij, uij, k);
          fneq[k] = lat.f[k,i,j] - feq[k];
        end
        const mu = constit_relation_f(sim, fneq, i, j);
        const omega = @omega(mu, lat.cssq, lat.dt);
        for k = 1:lat.n
          lat.f[k,i,j] = (omega * feq[k] + (1.0 - omega) * lat.f[k,i,j]);
        end
        msm.omega[i,j] = omega;
      end
    end
  end
end

#! Single relaxation time collision function for incompressible Newtonian flow
#!
#! \param sim Simulation object
#! \param bounds Boundaries that define active parts of the lattice
#! \param constit_relation_f Constitutive relationship
#! \param forcing_kf Forcing function
function init_col_srt! (sim::Sim, bounds::Matrix{Int64},
                        constit_relation_f::Function, forcing_kf::Function)
  const uf, colf = forcing_kf;
  return (sim::Sim, bounds::Matrix{Int64}) -> begin
    lat = sim.lat;
    msm = sim.msm;
    const ni, nj = size(msm.rho);
    const nbounds = size(bounds, 2);

    for r = 1:nbounds
      i_min, i_max, j_min, j_max = bounds[:,r];
      for j = j_min:j_max, i = i_min:i_max
        rhoij = msm.rho[i,j];
        uij = uf(lat, msm.u[:,i,j]);
        feq = Array(Float64, lat.n); 
        fneq = Array(Float64, lat.n); 
        for k = 1:lat.n 
          feq[k] = feq_incomp(lat, rhoij, uij, k);
          fneq[k] = lat.f[k,i,j] - feq[k];
        end
        const mu = constit_relation_f(sim, fneq, i, j);
        const omega = @omega(mu, lat.cssq, lat.dt);
        for k = 1:lat.n
          lat.f[k,i,j] = (omega * feq[k] + (1.0 - omega) * lat.f[k,i,j]
                          + colf(lat, omega, uij, k));
        end
        msm.omega[i,j] = omega;
      end
    end
  end
end

#! Multiple relaxation time collision function for incompressible flow
#!
#! \param sim Simulation object
#! \param S Function that returns (sparse) diagonal relaxation matrix
#! \param bounds 2D array, each row is i_min, i_max, j_min, j_max
#! \param constit_relation_f Constitutive relationship
function init_col_mrt!(sim::Sim, S::Function, bounds::Matrix{Int64}
                       constit_relation_f::Function)
  return (sim::Sim, bounds::Matrix{Int64}) -> begin
    lat = sim.lat;
    msm = sim.msm;
    const M = @DEFAULT_MRT_M();
    const iM = inv(M);
    const ni, nj = size(msm.rho);

    # calc f_eq vector ((f_eq_1, f_eq_2, ..., f_eq_9))
    feq = Array(Float64, lat.n);
    const nbounds = size(bounds, 2);

    #! Stream
    for r = 1:nbounds
      i_min, i_max, j_min, j_max = bounds[:,r];
      for j = j_min:j_max, i = i_min:i_max
        rhoij = msm.rho[i,j];
        uij = msm.u[:,i,j];

        for k=1:lat.n; feq[k] = feq_incomp(lat, rhoij, uij, k); end

        f = lat.f[:,i,j];
        mij = M * f;
        meq = M * feq;
        fneq = f - feq;

        muij = constit_relation_f(sim, S, M, iM, f, feq, fneq, mij, meq, i, j);
        Sij = S(mu, rhoij, lat.cssq, lat.dt);

        lat.f[:,i,j] = f - iM * Sij * (mij - meq); # perform collision

        # update collision frequency matrix
        msm.omega[i,j] = @omega(muij, lat.cssq, lat.dt);
      end
    end
  end
end

#! Multiple relaxation time collision function for incompressible flow
#!
#! \param sim Simulation object
#! \param S Function that returns (sparse) diagonal relaxation matrix
#! \param bounds 2D array, each row is i_min, i_max, j_min, j_max
#! \param constit_relation_f Constitutive relationship
#! \param forcing_kf Forcing function
function init_col_mrt!(sim::Sim, S::Function, bounds::Matrix{Int64}
                       constit_relation_f::Function, forcing_kf::Function)
  const uf, colf = forcing_kf;
  return (sim::Sim, bounds::Matrix{Int64}) -> begin
    lat = sim.lat;
    msm = sim.msm;
    const M = @DEFAULT_MRT_M();
    const iM = inv(M);
    const ni, nj = size(msm.rho);

    # calc f_eq vector ((f_eq_1, f_eq_2, ..., f_eq_9))
    feq = Array(Float64, lat.n);
    const nbounds = size(bounds, 2);

    #! Stream
    for r = 1:nbounds
      i_min, i_max, j_min, j_max = bounds[:,r];
      for j = j_min:j_max, i = i_min:i_max
        rhoij = msm.rho[i,j];
        uij = uf(msm.u[:,i,j]);

        for k=1:lat.n; feq[k] = feq_incomp(lat, rhoij, uij, k); end

        f = lat.f[:,i,j];
        mij = M * f;
        meq = M * feq;
        fneq = f - feq;

        muij = constit_relation_f(sim, S, M, iM, f, feq, fneq, mij, meq, i, j);
        Sij = S(mu, rhoij, lat.cssq, lat.dt);

        fdl = Array(Float64, lat.n);
        for k = 1:lat.n
          fdl[k] = colf(lat, omega, uij, k);
        end
        lat.f[:,i,j] = f - iM * Sij * (mij - meq) + fdl; # perform collision

        # update collision frequency matrix
        msm.omega[i,j] = @omega(muij, lat.cssq, lat.dt);
      end
    end
  end
end