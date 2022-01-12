rollout XRay_Skeleton_rol "x-ray load *.skls v.02"
(
button CreateList "Get animation file"
label FLabel "" align:#left
label ALabel "animations:" align:#left
listbox AnimList items:#() height:16
button LoadAnim "Load animation"
button ResetPoseBtn "Reset pose"

struct s_anim_name ( name, index )
local AnimFileName = undefined, Animas = #()

fn FNSortAnim v1 v2 =
(
		d = stricmp v1.name v2.name
		case  of
		(
				(d < 0 ) : -1
				(d > 0 ) : 1
				default: 0
		)
)

--------------------------------------------------------------------------------------------------------------------------------------------------
fn PassAnimation f =
(
		local a1 = readlong f
		local a2 = readlong f
		fseek f 25 #seek_cur
		local i, j, u, count, BoneName
		local NumBones = readshort f
		
		--format "% % % [%]\n" a1 a2 NumBones (ftell f)
		
		for i = 1 to NumBones do
		(
				BoneName = readstring f
				u = readbyte f
				--format "\t%, %\n" BoneName u
		
				for j = 1 to 6 do
				(
						readbyte f
						readbyte f
						count = readshort f --; format "\t\t%\n" count 
						fseek f (count*9) #seek_cur
				)
		) -- i
		
		--readlong f
		
		return #(a1,a2)
)

--------------------------------------------------------------------------------------------------------------------------------------------------
fn load_single_skl f start_t =
(
		local AName
		while true do
		(
			AName = readstring f
			if AName == undefined then exit
			if AName.count > 0 then exit
		)
		
		format "animation: %\n" AName
		local FStart = readlong f , FEnd = readlong f ; format "frames from % to %\n" FStart FEnd 
		local FRate = readfloat f ; format "frame rate : %\n" FRate 
		local UnkShort1 = readshort f , UnkByte1 = readbyte f , UnkShort2 = readshort f ; format "unk : %, %, %\n" UnkShort1 UnkByte1 UnkShort2 
		local ASpeed = readfloat f , AAccure = readfloat f, AFallof = readfloat f ; format "speed,acure,fallof | %, %, %\n" ASpeed AAccure AFallof 
		local UnkFloat1 = readfloat f ; format "UnkFloat1 = %\n" UnkFloat1
		local NumBones = readshort f ; format "num animated bones = %\n" NumBones
		local ctime, ctr
		local ControllerName = #("position.1","position.2","position.3","rotation.1","rotation.2","rotation.3")
		
		for i = 1 to NumBones do
		(
				BoneName = readstring f 
				u = readbyte f
				
				--bo = execute ("$" + BoneName)
				bo = undefined
				for xo in selection do if BoneName == xo.name then (bo = xo ; exit)
				
				format "bone: %\n" BoneName
				
				if bo == undefined then ( format "#################### BONE NOT FOUNDED\n")
				--else format "found bone %\n" bo

				ctr = for j = 1 to 6 collect linear_float ()
				ctime = linear_float ()
				
				
				for j = 1 to 6 do
				(
						u = #(readbyte f, readbyte f)
						count = readshort f
						--format "\t Controller % : %, %\n" j u count
						
						if count > 0 then format "\t% [%]\n" ControllerName[j] count
						
						for k = 1 to count do
						(
								v = readfloat f
								t = (readfloat f)*FRate + start_t
								b = readbyte f
								animate on at time t ctr[j].value = v
								addNewKey ctime t
								animate on at time t ctime.value = 1
								--format "\t\t %| %\n" t (if j > 3 then (radtodeg v) else v)
						)
				)
				
				
				if bo != undefined then
				(
						for k in ctime.keys do
						(
								t = k.time
								px = at time t ctr[1].value
								pz = at time t ctr[2].value
								py = at time t ctr[3].value
								rx = radtodeg (at time t ctr[4].value)
								rz = radtodeg (at time t ctr[5].value)
								ry = radtodeg (at time t ctr[6].value)
		
								--tm2 = ( (eulertoquat (eulerangles -(radtodeg ry) -(radtodeg rx) -(radtodeg rz)) order:4) as matrix3 )
								--tm2.row4 = [px,py,pz]
								
								animate on at time t bo.rotation.controller.value = eulertoquat (eulerangles -ry -rz -rx) order:4
								animate on at time t bo.position.controller.value = [px,py,pz]
								
								--ptm = if bo.parent == undefined then (matrix3 1) else (at time t bo.parent.transform)
								--tm2 *= ptm
								
								--animate on at time t bo.transform = inverse tm2
								
								--format "\t\t%: [%,%,%] \n" t px py pz
						)
						
						deletekeys bo.scale.controller.keys #allkeys
				)
				
				--if i > 6 then exit
		) -- i
		
		--if (FEnd-1) > FStart then animationRange = interval (FStart+start_t) (FEnd-1+start_t) else animationRange = interval (FStart+start_t) (FStart+1+start_t)
		if (FEnd-1) > 0 then animationRange = interval 0 (FEnd-1+start_t) else animationRange = interval 0 (FStart+1+start_t)
)

--------------------------------------------------------------------------------------------------------
on AnimList selected N do -- (Animas[AnimList.selection].index as string)
(
	--ALabel.text = "Animations: (selected " + (N as string) + "/" + (AnimList.items.count as string) + ")"
	ALabel.text = "Animations: (selected " + (Animas[N].index as string) + "/" + (AnimList.items.count as string) + ")"
)

--------------------------------------------------------------------------------------------------------
on ResetPoseBtn pressed do
(
		sliderTime = 0
		
		for obj in selection do
		(
				deletekeys obj.pos.controller
				deletekeys obj.rotation.controller
				deletekeys obj.scale.controller
				obj.assumeSkinPose()
		)
)
	
--------------------------------------------------------------------------------------------------------
on CreateList pressed do
(
		fname = getopenfilename types:"anims|*.skls|anim|*.skl|" \
				filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\"
		
		clearlistener ()
		
		if fname != undefined then
		(
				f = fopen fname "rb"
				if f == undefined then format "cant open file\n"
				else
				(
						AnimList.items = #()
						AnimFileName = fname
						NumAnims = readlong f ; format "Num anims = %\n" NumAnims
						TempList = #()
						Animas = #()
						
						for i = 1 to NumAnims do
						(
								while true do
								(
									str = readstring f
									if str == undefined then exit
									if str.count > 0 then exit
								)
								j = s_anim_name name:(str) index:i
								append Animas j
								b = PassAnimation f
								format "%:% %\n" i str b
						)
						
						--print Animas
						qsort Animas FNSortAnim
						--print Animas
						
						AnimList.items = for i in Animas collect i.name
						FLabel.text = "file:" + (filenamefrompath fname)
						ALabel.text = "animations: (selected " + (Animas[1].index as string) + "/" + (AnimList.items.count as string) + ")"
						AnimList.selection = 1
						fclose f
				)
		)
)

--------------------------------------------------------------------------------------------------------
on LoadAnim pressed do
(
		if AnimFileName != undefined then
		(
				clearlistener ()
				
				f = fopen AnimFileName "rb"
				if f == undefined then format "cant open file\n"
				else
				(
						NumAnims = readlong f ; format "Num anims = %\n" NumAnims
						--N = AnimList.selection
						N = Animas[AnimList.selection].index
						
						for i = 1 to N-1 do
						(
								while true do
								(
									str = readstring f
									if str == undefined then exit
									if str.count > 0 then exit
								)
								PassAnimation f
						)
						
						load_single_skl f sliderTime
						fclose f
				)
		)
)

) -- roll


try (closeRolloutFloater XRay_Skeleton_flo) catch ()
XRay_Skeleton_flo = newRolloutFloater "x-ray tools" 270 380 40 130
addRollout  XRay_Skeleton_rol XRay_Skeleton_flo











