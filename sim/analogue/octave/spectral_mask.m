function y = spectral_mask(x)
% load with something like: for i = 1:601; y(i) = spectral_mask(x(i)); endfor

    l1_x = [   1.000e6,   2.000e6];
    l2_x = [   2.000e6,  18.375e6];
    l3_x = [  23.625e6,  50.000e6];
    l4_x = [  50.000e6, 105.000e6];
    l5_x = [ 105.000e6, 400.000e6];
    l1_y = [ -120, -80];
    l2_y = [  -80,  -3];
    l3_y = [   -3, -25];
    l4_y = [  -25, -34];
    l5_y = [  -34, -75];
    
    pf1 = polyfit(l1_x, l1_y, 1);
    pf2 = polyfit(l2_x, l2_y, 1);
    pf3 = polyfit(l3_x, l3_y, 1);
    pf4 = polyfit(l4_x, l4_y, 1);
    pf5 = polyfit(l5_x, l5_y, 1);

    for i = 1:numel(x)
	if (x(i) <=   1e6) 
	   y(i) = -120; 
	   continue;
	endif
    
	if (x(i) >= 400e6) 
	   y(i) = -75; 
	   continue;;
	endif
    
	if (x(i) >= 18.375e6) && (x(i) <= 23.625e6)
	   y(i) = 0;
	   continue;
	endif
    
	if (x(i) >   1.000e6) 
	   y(i) = pf1(1)*x(i) + pf1(2);
	endif
    
	if (x(i) >   2.000e6) 
	   y(i) = pf2(1)*x(i) + pf2(2);
	endif
    
	if (x(i) >  23.625e6) 
	   y(i) = pf3(1)*x(i) + pf3(2);
	endif
    
	if (x(i) >  50.000e6) 
	   y(i) = pf4(1)*x(i) + pf4(2);
	endif
    
	if (x(i) > 105.000e6) 
	   y(i) = pf5(1)*x(i) + pf5(2);
	endif
    endfor

endfunction
