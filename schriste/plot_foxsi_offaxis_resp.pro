PRO plot_foxsi_offaxis_resp, OUTPS = outps

scale = 1
num_pixels = 128 / scale
plate_scale = 7.5 * scale

dim = num_pixels * plate_scale

arcsec_to_arcmin = 1 / 60.0

angle_array = fltarr(2, num_pixels, num_pixels)

phi_array = fltarr(num_pixels, num_pixels)

min_energy = 5
de = 5
max_energy = 20
energy_arr = findgen(max_energy / de) * de + min_energy
energy_arr = [4.5,  5.5,  6.5,  7.5,  8.5,  9.5, 11. , 13. , 15. , 17. , 19. , 22.5, 27.5]

result = fltarr(n_elements(energy_arr), num_pixels, num_pixels)

eff_area = fltarr(n_elements(energy_arr), num_pixels)
; one energy

popen, 'plot_foxsi_offaxis_resp'
r = get_foxsi_optics_effarea(module_number = 1, offaxis_angle = 0, /plot)

FOR i = 0, num_pixels-1 DO BEGIN
    FOR j = 0, num_pixels-1 DO BEGIN
        angle_array[0, i, j] = arcsec_to_arcmin * (i - num_pixels / 2.) * plate_scale
        angle_array[1, i, j] = arcsec_to_arcmin * (j - num_pixels / 2.) * plate_scale
        pan = angle_array[0, i, j]
        tilt = angle_array[1, i, j]
        res = get_foxsi_optics_effarea(module_number = 1, offaxis_angle = [pan, tilt])
        result[*, i, j] = res.eff_area_cm2
        rnorm = sqrt(pan ^ 2 + tilt ^ 2)
        phi_array[i, j] = acos(pan / rnorm)
    ENDFOR
ENDFOR

loadct, 5

FOR i = 0, n_elements(energy_arr)-1 DO BEGIN
    m = make_map(reform(result[i, *, *]), dx = plate_scale, dy = plate_scale, xc = 0, yc = 0, title = 'Energy = ' + num2str(energy_arr[i]))
    plot_map, m, title = 'Energy = ' + num2str(energy_arr[i], length = 4) + ' keV norm', dmin = 15, dmax = 0, /cbar
    plot_map, m, dmin = 15, dmax = 0, /cont, /noerase, levels = [25, 50, 75], /percent, title = ''
    plot_circle, 0, 0, radius = 100, /over, linestyle = 2
    oplot, [-1000, 1000], [0, 0], linestyle = 2
    oplot, [0, 0], [-1000, 1000], linestyle = 2
ENDFOR

FOR i = 0, n_elements(energy_arr)-1 DO BEGIN
    m = make_map(reform(result[i, *, *]), dx = plate_scale, dy = plate_scale, xc = 0, yc = 0, title = 'Energy = ' + num2str(energy_arr[i]))
    plot_map, m, title = 'Energy = ' + num2str(energy_arr[i], length = 4)  + ' keV', /cbar
    plot_map, m, /cont, /noerase, levels = [25, 50, 75], /percent, title = ''
    plot_circle, 0, 0, radius = 100, /over, linestyle = 2
    oplot, [-1000, 1000], [0, 0], linestyle = 2
    oplot, [0, 0], [-1000, 1000], linestyle = 2
ENDFOR

pclose

END

