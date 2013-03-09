FUNCTION FOXSI_COUNT_SPECTRUM, EM, T, TIME=TIME, BINSIZE=BINSIZE, STOP=STOP, $
	DATA_DIR = data_dir, LET_FILE = let_file

; General function for computing FOXSI expected count rates, no imaging.  
; Note that no field of view is taken into account here.  
; If the plasma is a whole-disk plasma, need to adjust for FOV.  
; If source area is smaller than FOV then no correction needed.  
; No energy resolution is considered in this simulation.
; Livetime is not considered.
;
;	EM: 	 emission measure in units of 10.^49 cm^-3
;	T:  	 temperature in MK
;	TIME:  	 time interval for observation, in seconds
;	BINSIZE: width of energy bins

if not keyword_set(time) then time=1.
if not keyword_set(binsize) then binsize=0.5

; Set up energy bins 2-12 keV
e1 = dindgen(1000)/100+2
e2 = get_edges(e1,/edges_2)
emid = get_edges(e1,/mean)

TEMP = T/11.6      ; switch temperature to units of keV

flux = f_vth(e2, [EM, TEMP, 1.], /cont)	; compute thermal X-ray flux

; note to self: there's a peak above 2.5 keV for T=7MK. Should there be a line there at this temperature?

;
; Get FOXSI response
;
; First, get area for individual factors (optics area, detector efficiency (inc. LET), 
; off-axis response, blanketing aborption) 
; Then get area including all these effects.
;
area_bare =    get_foxsi_effarea( $ 	; optics only
		energy=emid, data_dir=data_dir, /nodet, /noshut, /nopath)
area_blankets =get_foxsi_effarea( $ 	; optics + blankets
		energy=emid, data_dir=data_dir, /nodet, /noshut)
area_det = 	   get_foxsi_effarea( $ 	; optics + detectors
		energy=emid, data_dir=data_dir, /noshut, /nopath, let_file=let_file)
area_offaxis = get_foxsi_effarea( $		; optics + off-axis response factor
		energy=emid, data_dir=data_dir, /nodet, /noshut, /nopath, offaxis_angle=7.0)

area = get_foxsi_effarea( $
		energy=emid, data_dir=data_dir, let_file=let_file, offaxis_angle=7.0)

if keyword_set(stop) then stop

; fold flux with FOXSI response
counts = flux*area.eff_area_cm2  ; now the units are counts per second per keV
;counts = counts*binsize		 ; now the units are counts per second.

; coarser energy bins.
e2_coarse = findgen(10./binsize+1)*binsize+2
emid_coarse = get_edges(e2_coarse, /mean)
counts_coarse = time*interpol(counts, emid, emid_coarse)
y_err_raw = sqrt(counts_coarse)

; if uncertainty is 100% or greater, kill it.
i=where(y_err_raw gt counts_coarse)
if i[0] gt -1 then begin
	counts_coarse[i] = sqrt(-1)
	y_err_raw[i] = sqrt(-1)
endif

result = create_struct("energy_keV", emid_coarse, "counts", counts_coarse, "count_error", y_err_raw)

return, result

END

; example of plotting
; f = foxsi_count_spectrum(3.e-5,7.,time=60)
; plot, f.energy_kev, f.counts, psym=10, /xlog, /ylog
; ploterr,f.energy_kev,f.counts,fltarr(20),f.count_error,psym=10,/xlog, $
;	/ylog,yr=[1.e-1,1.e3],xr=[1,20],xstyle=1