function dydt = oregonator_deriv ( t, y )

%*****************************************************************************80
%
%% oregonator_deriv() returns the right hand side of the oregonator ODE.
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
%  Reference:
%
%    Richard Field, Endre Koros, Richard Noyes,
%    Oscillations in Chemical Systems II. Thorough analysis of temporal 
%    oscillations in the Ce-BrO3-malonic acid system,
%    Journal of the American Chemical Society,
%    Volume 94, pages 8649-8664, 1972.
%
%  Input:
%
%    real T, the current time.
%
%    real Y(3), the current state values.
%
%  Output:
%
%    real DYDT(3), the time derivatives of the current state values.
%
  [ eta1, eta2, q, f, t0, y0, tstop ] = oregonator_parameters ( );

  u = y(1);
  v = y(2);
  w = y(3);

  dudt = (   q * v - u * v + u * ( 1.0 - u ) ) / eta1;
  dvdt = ( - q * v - u * v + f * w ) / eta2;
  dwdt = u - w;

  dydt = [ dudt; dvdt; dwdt ];

  return
end

