function [f, Q, g, n] = lpf_2_pole_inverting_inv(R_1, R_2, R_3, C_1, C_2)
    Q = (R_1 ./ C_2) .* sqrt(R_2.*R_3.*C_1.*C_2) ./ \ 
	(R_1.*R_2 + R_2.*R_3 + R_1.*R_3);
    f = 1 ./ (2.* pi .* sqrt(R_2.*R_3.*C_1.*C_2));
    g = R_3 ./ R_1;
    n = sqrt(R_2 ./ R_3);
endfunction
