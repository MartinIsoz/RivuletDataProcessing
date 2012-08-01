function fluidData = fluidDataFcn(LiquidName,angle)
%
%   function fluidData = fluidDataFcn(LiquidName,angle)
%
% database function which returns fluidData for selected liquid type
%
% INPUT variable
% LiquidName    ... name of the liquid used for the experiment
% angle         ... plate inclination angle (for calculation of g)
%
% OUTPUT variable
% fluidData     ... necessary data for the rivulet processing
%                   [g sigma rho eta reg]
%   - g         ... gravitational acceleration for plate inclination angle,
%                   m/s^2
%   - sigma     ... surface tension of the liquid, N/m
%   - rho       ... density of the liquid, kg/m^3
%   - eta       ... dynymic viscozity of the liquid, Pas
%   - reg       ... vector with polynomial coefficients for the rotameter
%                   calibration: reg(1)x^n + reg(2)x^(n-1) ... reg(n+1)
%
% See also: RIVULETEXPDATAPROCESSING RIVULETPROCESSING

g   = sin(angle/180*pi)*9.81;                                               %gravitational acceleration, plate incl. angle conv deg -> rad

switch LiquidName
    case '???'                                                              %liquid used for testing of the program, different than the others
        sigma   = 0.0202;
        rho     = 930;
        eta     = 0.0093;
        reg     = [0.00268867271984935...
                   0.0165546451606565...
                   0.0738965243420832];
    case 'DC 5'
        sigma   = 17.57e-3;
        rho     = 920;
        eta     = 10.419e-3;
        reg     = [0.00268867271984935...
                   0.0165546451606565...
                   0.0738965243420832];
    case 'DC 10'
        sigma   = 17.89e-3;
        rho     = 940;
        eta     = 5.073e-3;
        reg     = [0.00268867271984935...
                   0.0165546451606565...
                   0.0738965243420832];
    case 'Water'
        sigma   = 55.18e-3;
        rho     = 998;
        eta     = 1.178e-3;
        reg     = [0.00268867271984935...
                   0.0165546451606565...
                   0.0738965243420832];
    case 'Tenzids'
        sigma   = 29.36e-3;
        rho     = 998;
        eta     = 1.114e-3;
        reg     = [0.00268867271984935...
                   0.0165546451606565...
                   0.0738965243420832];
end

fluidData = [g sigma rho eta reg];