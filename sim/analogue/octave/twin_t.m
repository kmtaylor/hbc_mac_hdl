_C_1 = 22e-9;

w_z = 1.00e6;
w_0 = 49.8e6;
%w_0 = (2 + sqrt(3)) * 1e6;

Q = (w_z * w_0) / (w_z^2 + w_0^2);

printf("Q: %s\n", print_eng(Q));

%The corresponding pole:
w_2 = w_z^2 / w_0;
printf("Approx Zero: %s\n", print_eng(w_2));

g(1) = (1 - 8*Q^2 - sqrt(1 - 16*Q^2)) / (2*Q^2);
g(2) = (1 - 8*Q^2 + sqrt(1 - 16*Q^2)) / (2*Q^2);

C_2 = [_C_1 _C_1];
C_1 = C_2 .* (2./g);
R_1 = sqrt(2 ./ (C_1 .* C_2)) ./ (2 * pi * w_z); 
R_2 = R_1 .* C_2 ./ (4 .* C_1);

z = [2*pi*w_z*j -2*pi*w_z*j];
p = [-2*pi*w_0 -2*pi*w_2];
num = poly(z);
den = poly(p);

printf("\nSolution 1\n");
printf("C1: %s\n", print_eng(C_1(1)));
printf("C2: %s\n", print_eng(C_2(1)));
printf("R1: %s\n", print_eng(R_1(1)));
printf("R2: %s\n", print_eng(R_2(1)));

printf("\nSolution 2\n");
printf("C1: %s\n", print_eng(C_1(2)));
printf("C2: %s\n", print_eng(C_2(2)));
printf("R1: %s\n", print_eng(R_1(2)));
printf("R2: %s\n", print_eng(R_2(2)));
