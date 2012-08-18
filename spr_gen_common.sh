#!/bin/bash
#Program:
#    This tool is to generate SPR files for the first time of a new project or for some new CTR codes of a exist project.
#How to:
#    1.delete all the obsolete SPR files in the Setting baseline dir.
#    2.run this script following the instruction.
#History:
#    2012-06-12 Bingnan Duan(david.3.duan@nokia.com) Initial version

read -p "Please enter mode code (for example: RM811,RM827...)" MODE_CODE
echo Mode code: $MODE_CODE

read -p "Please enter the SPR templet file name (for example: RM810_059P1X6.SPR,RM827_059P551.SPR...)" SPR_TEMPLET
echo SPR templet name: $SPR_TEMPLET

read -p "Please enter the setting baseline code path (for example: /xx/xx/../rm810_sw_settings)" SETTINGS_CODE_PATH
echo Setting baseline code path $SETTINGS_CODE_PATH

mkdir ./SPR_TEMP
mkdir ./SPR_TEMPLET
unzip -n $SPR_TEMPLET -d ./SPR_TEMPLET

SPR_TEMPLET_Lang_Varaint_code=$(grep "Content: " ./SPR_TEMPLET/ContentPackageVersionVerifier_v1.0.xml | sed 's/^.*Content: //g')
echo SPR Templet Language Varaint code is : $SPR_TEMPLET_Lang_Varaint_code


ls $SETTINGS_CODE_PATH | grep 'defaults' > regions_list.txt

cat regions_list.txt | while read Region_Folder
do
    echo default region line: $Region_Folder | grep -i "brazil"
    
    if [ $? -eq 0 ];then
        IsBRAZIL="YES"
    else
        IsBRAZIL="NO"
    fi
    
    echo default region line: $Region_Folder | grep -i "lta"
    
    if [ $? -eq 0 ];then
        IsLTA="YES"
    else
        IsLTA="NO"
    fi	
    
    ls $SETTINGS_CODE_PATH/$Region_Folder | grep '05' | tee one_region_variant_code.txt
    
    cat one_region_variant_code.txt | while read Variant_Folder
        do 
            echo /=============================BEGIN========================================/
            Variant_Code=${Variant_Folder:0:7}
            echo Varinat code:$Variant_Code
            
            SPR_FILE_NAME=${MODE_CODE}_${Variant_Code}.SPR
            echo SPR FILE NAME:$SPR_FILE_NAME
            
            echo copy SPR templet file into all varaint code folders...
            cp -f $SPR_TEMPLET $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/EXT_DCP_FILES
            mv -f $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/EXT_DCP_FILES/$SPR_TEMPLET $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/EXT_DCP_FILES/$SPR_FILE_NAME
            
            echo Unzip old spr file
            mkdir ./SPR_TEMP/$Variant_Code
            unzip -n $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/EXT_DCP_FILES/$SPR_FILE_NAME -d ./SPR_TEMP/$Variant_Code
            
            Variant_Configuration_file=${Variant_Code}.xml
            echo Variant Configuration file:$Variant_Configuration_file
            
            Lang_Variant_code=$(grep "image_" $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/VariantConfiguration/$Variant_Configuration_file | sed 's/^.*image_//g' | sed 's/<\/Name>//g')
            
            Lang_code=$(grep "ppm_" $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/VariantConfiguration/$Variant_Configuration_file | sed 's/^.*ppm_//g' | sed 's/<\/Name>//g')
            LANG_CODE=$(echo $Lang_code | tr [a-z] [A-Z])
            
            #modify ContentPackageVersionVerifier_v1.0.xml
            sed -i "s/$SPR_TEMPLET_Lang_Varaint_code/$Lang_Variant_code/g" ./SPR_TEMP/$Variant_Code/ContentPackageVersionVerifier_v1.0.xml
            
            unix2dos ./SPR_TEMP/$Variant_Code/ContentPackageVersionVerifier_v1.0.xml
            
            #modify PpmInfoVerifier_v1.0.xml
            if [ "$Lang_code" == "a" -o "$Lang_code" == "a1" -o "$Lang_code" == "e1" -o "$Lang_code" == "e2" -o "$Lang_code" == "e3" -o "$Lang_code" == "e4" -o "$Lang_code" == "e5" ];then
                sed -i "6c $Lang_code</VersionString></PpmInfoVerifier></SettingsData>" ./SPR_TEMP/$Variant_Code/PpmInfoVerifier_v1.0.xml
            else
                sed -i "6c $LANG_CODE</VersionString></PpmInfoVerifier></SettingsData>" ./SPR_TEMP/$Variant_Code/PpmInfoVerifier_v1.0.xml
            fi
            
            unix2dos ./SPR_TEMP/$Variant_Code/PpmInfoVerifier_v1.0.xml
            
            #modify DateTimeSettings_v1.0.xml
            if [ "$IsBRAZIL" == "YES" -o "$IsLTA" == "YES" ];then
                sed -i '4c \\t\t<AutomaticUpdate>On</AutomaticUpdate>' ./SPR_TEMP/$Variant_Code/DateTimeSettings_v1.0.xml
            else
                sed -i '4c \\t\t<AutomaticUpdate>Off</AutomaticUpdate>' ./SPR_TEMP/$Variant_Code/DateTimeSettings_v1.0.xml
            fi
            
            unix2dos ./SPR_TEMP/$Variant_Code/DateTimeSettings_v1.0.xml
            
            echo Zip .xml files
            cd ./SPR_TEMP/$Variant_Code/
            zip $SPR_FILE_NAME *.*
            
            echo Move new SPR file into orignal folder.
            mv -f $SPR_FILE_NAME $SETTINGS_CODE_PATH/$Region_Folder/$Variant_Folder/EXT_DCP_FILES/
            cd ../../
            
            echo /=============================END========================================/ 
        done
    
done

rm -rf ./SPR_TEMP
rm -rf ./SPR_TEMPLET
rm -f ./one_region_variant_code.txt
rm -f ./regions_list.txt
