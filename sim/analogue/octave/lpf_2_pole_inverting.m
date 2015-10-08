function [R_1, R_2, R_3, C_1, C_2] = lpf_2_pole_inverting(f_0, Q, g, n);

    m = Q .* ((n + 1./n) + g.*n);

    C_2 = 10e-12;
    C_1 = C_2 .* m.^2;

    R = 1 ./ (2 .* pi .* f_0 .* sqrt(C_1 .* C_2));
    R_3 = R ./ n;
    R_2 = R .* n;
    R_1 = R_3 ./ g;

    printf("C_1: %sF\n", print_eng(C_1));
    printf("C_2: %sF\n", print_eng(C_2));
    printf("R_1: %s\n", print_eng(R_1));
    printf("R_2: %s\n", print_eng(R_2));
    printf("R_3: %s\n", print_eng(R_3));

%(R_1 ./ C_2) .* sqrt(R_2.*R_3.*C_1.*C_2) ./ (R_1.*R_2 + R_2.*R_3 + R_1.*R_3);
%1 ./ (2.* pi .* sqrt(R_2.*R_3.*C_1.*C_2));
%R_3 ./ R_1;
endfunction
