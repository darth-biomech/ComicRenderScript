test_ca = attributes custom_parameters attribID:#(0x7847187d, 0x4c3b92b5) version:1
(
	parameters Comic_Params rollout:Comic
	(
		FX_pass type:#boolean default:false ui:FX_pass_ui
		Second_tonemap type:#boolean default:false ui:Second_tonemap_ui
		LineWidth type:#float ui:LineWidth_ui
		Fisheye type:#boolean default:false ui:Fisheye_ui
		Fisheye_Dist type:#float default:1.012 ui:Fisheye_Dist_ui
		Fisheye_Curv type:#float default:0.35 ui:Fisheye_Curv_ui
	)
	rollout Comic "Comic Parameters"
	( 
		Checkbox FX_pass_ui "Has FX" type:#boolean
		Checkbox Second_tonemap_ui "Second tonemap" type:#boolean
		spinner LineWidth_ui "Line Width" type:#worldunits 
		Checkbox Fisheye_ui "Enable Fisheye" type:#boolean
		spinner Fisheye_Dist_ui "Fisheye dist" type:#float 
		spinner Fisheye_Curv_ui "Fisheye curve" type:#float 
	)
)

fn patch_file =(
	wanted_names = getPropNames test_ca
	
	datanode = getNodeByName "!ComicData" 
	
	if datanode != undefined do (
		base_values = #()
		controllers = #()
		
		with undo off (
			sliderTime = animationRange.start.frame
			
			for p in wanted_names do (
				
				if hasProperty datanode.custom_parameters p then (
					append base_values (getProperty dataNode p)
					append controllers (getPropertyController datanode p) 
				)
				else (
					append base_values undefined
					append controllers undefined
				)
			)
			
			format "%\n%\n%\n" wanted_names base_values controllers
			
			custAttributes.delete datanode 1
			custAttributes.add datanode test_ca
			
			for i = 1 to wanted_names.count do (
				
				p = wanted_names[i]
				val = base_values[i]
				ctrl = controllers[i]
				
				if val != undefined do (
					setProperty datanode p val
				)
				
				if ctrl != undefined do (
					setPropertyController datanode p ctrl
				)
			)
		)
	)
)

fn batch_files dir =(
	
	wanted_names = getPropNames test_ca
	files = getFiles dir
	
	for f in files do (
		
		format "\nLoading File \"%\"...\n" f
		loadMaxFile f useFileUnits:True quiet:True
		
		format "Patching...\n"
		
		patch_file()
		
		max file save
		format "OK! Closing...\n"
	)
		format "Done!\n"
)

clearListener()

file_dir = @"Q:\!Raharrs_and_all_about\!comic\COMIC_PROPS\*.max"

batch_files file_dir

--patch_file()