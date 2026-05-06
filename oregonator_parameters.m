function [ eta1, eta2, q, f, t0, y0, tstop ] = oregonator_parameters ( ...
   eta1_user, eta2_user, q_user, f_user, t0_user, y0_user, tstop_user )

%*****************************************************************************80
%
%% oregonator_parameters() returns parameters for the oregonator ODE.
%
%  Discussion:
%
%    If input values are specified, this resets the default parameters.
%    Otherwise, the output will be the current defaults.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    23 April 2021
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    real ETA1_USER, ETA2_USER, Q_USER, F_USER: scaling parameters.
%
%    real T0_USER: the initial time, in seconds;
%
%    real Y0_USER(3): the initial values.
%
%    real TSTOP_USER: the final time.
%
%  Output:
%
%    real ETA1, ETA2, Q, F: scaling parameters.
%
%    real T0: the initial time, in seconds;
%
%    real Y0(3): the initial values.
%
%    real TSTOP: the final time.
%
  persistent eta1_default;
  persistent eta2_default;
  persistent q_default;
  persistent f_default;
  persistent t0_default;
  persistent y0_default;
  persistent tstop_default;
%
%  Initialize defaults.
%
  if ( isempty ( eta1_default ) )
    a = 0.06;
    b = 0.02;
    k5 = 33.6;
    kc = 1.0;
    eta1_default = kc * b / k5 / a;
  end

  if ( isempty ( eta2_default ) )
    a = 0.06;
    b = 0.02;
    k2 = 2.4E+06;
    k4 = 3.0E+03;
    k5 = 33.6;
    kc = 1.0;
    eta2_default = 2.0 * kc * k4 * b / k2 / k5 / a;
  end

  if ( isempty ( q_default ) )
    k2 = 2.4E+06;
    k3 = 1.28;
    k4 = 3.0E+03;
    k5 = 33.6;
    q_default = 2.0 * k3 * k4 / k2 / k5;
  end

  if ( isempty ( f_default ) )
    f_default = 1.0;
  end

  if ( isempty ( t0_default ) )
    t0_default = 0.0;
  end

  if ( isempty ( y0_default ) )
    y0_default = [ 1.0, 1.0, 1.0 ];;
  end

  if ( isempty ( tstop_default ) )
    tstop_default = 25.0;
  end
%
%  Update defaults if input was supplied.
%
  if ( 1 <= nargin )
    eta1_default = eta1_user;
  end

  if ( 2 <= nargin )
    eta2_default = eta2_user;
  end

  if ( 3 <= nargin )
    q_default = q_user;
  end

  if ( 4 <= nargin )
    f_default = f_user;
  end

  if ( 5 <= nargin )
    t0_default = t0_user;
  end

  if ( 6 <= nargin )
    y0_default = y0_user;
  end

  if ( 7 <= nargin )
    tstop_default = tstop_user;
  end
%
%  Return values.
%
  eta1 = eta1_default;
  eta2 = eta2_default;
  q = q_default;
  f = f_default;
  t0 = t0_default;
  y0 = y0_default;
  tstop = tstop_default;
  
  return
end

