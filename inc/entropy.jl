# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

include("lattice.jl");

#! Calculate the classical Boltzmann entropy
#!
#! \param lat Lattice
#! \param i   ith index at which to calculate the Boltzmann entropy
#! \param j   jth index at which to calculate the Boltzmann entropy
#! \return    Entropy
function entropy_lat_boltzmann(lat::Lattice, i::Int, j::Int)
  ent = 0.0;
  for k = 1:lat.n
    ent -= lat.f[k, i, j] * log(lat.f[k, i, j] / lat.w[k]);
  end
  return ent
end

#! Calculate the classical Boltzmann entropy
function entropy_lat_boltzmann(lat::Lattice)
  const ni, nj = size(lat.f, 2), size(lat.f, 3);
  ent = Array{Float64,2}(lat.ni, lat.nj);
  for i = 1:ni, j = 1:nj
    ent[i, j] = lat_boltzmann_entropy(lat, i, j);
  end

  return ent;
end

#! Calculate relative non-equilibrium entropy density
#!
#! \param   f       Particle distributions
#! \param   f_eq    Equilibrium distributions
#! \param   f_neq   Non-equilibrium distributions
#! \return          Relative non-equilibrium entropy density
function entropy_noneq_density(f::Vector{Float64}, f_eq::Vector{Float64},
                               f_neq::Vector{Float64})
  const nk = length(f);
  ds = 0.0;
  for k = 1:nk
    ds += f[k] * log(f[k] / f_eq[k]) - f_neq;
  end

  return ds;
end

#! Calculate relative non-equilibrium entropy density
#!
#! \param   f     Particle distributions
#! \param   f_eq  Equilibrium distributions
#! \return        Relative non-equilibrium entropy density
function entropy_noneq_density(f::Vector{Float64}, f_eq::Vector{Float64})
  return entropy_noneq_density(f, f_eq, f - f_eq);
end

#! Calculate the quadratic entropy
#!
#! \param   f       Particle distributions
#! \param   f_eq    Equilibrium distributions
#! \param   f_neq   Non-equilibrium distributions
#! \return          Quadratic entropy
function entropy_quadratic(f::Vector{Float64}, f_eq::Vector{Float64},
                           f_neq::Vector{Float64})
  const nk = length(f);
  ds = 0.0;
  for k = 1:nk
    ds += f_neq[k]^2 / (2 * f_eq[k]);
  end
 
  return ds;
end

#! Calculate the quadratic entropy
#!
#! \param   f       Particle distributions
#! \param   f_eq    Equilibrium distributions
#! \param   f_neq   Non-equilibrium distributions
#! \return          Quadratic entropy
function entropy_quadratic(f::Vector{Float64}, f_eq::Vector{Float64})
  return entropy_quadratic(f, f_eq, f - f_eq);
end
