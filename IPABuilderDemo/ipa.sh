#!/bin/bash



if [[ ! `which jq` ]]; then
    #statements
    echo "not found jq"
    echo "install jq"
    brew install jq || exit 1

fi
filepath=`pwd`/ipa_config.json

#工程名字(Target名字)
Project_Name=`cat $filepath | jq -r ".projectName"`
echo -e "\033[41;37m Project_Name $Project_Name \033[0m \n"

#配置环境，Release或者Debug,默认release
Configuration=`cat $filepath | jq -r ".configuration"`
echo -e "\033[41;37m configuration $Configuration \033[0m \n"

#bundleID
bundleID=`cat $filepath | jq -r ".bundleID"`
echo -e "\033[41;37m bundleID $bundleID \033[0m \n"

#workspace的名字
Workspace_Name=$Project_Name
#配置环境，Release或者Debug,默认release
#Configuration="Release"

# ADHOC证书名
CODE_SIGN_IDENTITY=`cat $filepath | jq -r ".codesign"`
echo -e "\033[41;37m CODE_SIGN_IDENTITY $CODE_SIGN_IDENTITY \033[0m \n"
#描述文件 adhoc
ADHOCPROVISIONING_PROFILE_NAME=`cat $filepath | jq -r ".adhoc_profile_udid"`
echo -e "\033[41;37m 描述文件 adhoc $ADHOCPROVISIONING_PROFILE_NAME \033[0m \n"
#描述文件 appstore
APPSTOREROVISIONING_PROFILE_NAME=`cat $filepath | jq -r ".appstore_profile_udid"`
echo -e "\033[41;37m 描述文件 appstore $APPSTOREROVISIONING_PROFILE_NAME \033[0m \n"
#蒲公英 UKEY
UKEY=`cat $filepath | jq -r ".UKEY"`
echo -e "\033[41;37m 蒲公英 UKEY $UKEY \033[0m \n"
#蒲公英 APIKEY
APIKEY=`cat $filepath | jq -r ".APIKEY"`
echo -e "\033[41;37m 蒲公英 APIKEY $APIKEY \033[0m \n"

ADHOCFILEPATH=`pwd`/ipa/$Project_Name-adhoc/$Project_Name.ipa
ADHOCFILEPATH=${ADHOCFILEPATH}

#加载各个版本的plist文件
ADHOCExportOptionsPlist=./ADHOCExportOptionsPlist.plist
AppStoreExportOptionsPlist=./AppStoreExportOptionsPlist.plist
#EnterpriseExportOptionsPlist=./EnterpriseExportOptionsPlist.plist

ADHOCExportOptionsPlist=${ADHOCExportOptionsPlist}
AppStoreExportOptionsPlist=${AppStoreExportOptionsPlist}
#EnterpriseExportOptionsPlist=${EnterpriseExportOptionsPlist}

echo "~~~~~~~~~~~~选择打包方式(输入序号)~~~~~~~~~~~~~~~"
echo "  1 adHoc"
echo "  2 AppStore"
#echo "  3 Enterprise"

# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

echo "使用workspace？"
echo "yes/no"

read parameter

isuseworkspace="$parameter"


# 判读用户是否有输入
if [ -n "$method" ]
then

#clean下
#xcodebuild clean -xcodeproj ./$Project_Name.xcodeproj -configuration $Configuration -alltargets

    if [ "$method" = "1" ]
    then

    if [[ "$isuseworkspace" = "yes" ]]; then
    	#statements
xcodebuild \
-workspace $Workspace_Name.xcworkspace \
-scheme $Project_Name -configuration $Configuration \
-archivePath build/$Project_Name-adhoc.xcarchive \
clean archive build \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${ADHOCPROVISIONING_PROFILE_NAME}" \
PRODUCT_BUNDLE_IDENTIFIER="${bundleID}"

    	else
 xcodebuild \
-project $Project_Name.xcodeproj \
-scheme $Project_Name \
-configuration $Configuration \
-archivePath build/$Project_Name-adhoc.xcarchive \
clean archive build \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${ADHOCPROVISIONING_PROFILE_NAME}" \
PRODUCT_BUNDLE_IDENTIFIER="${bundleID}"
    fi
#adhoc脚本


xcodebuild  -exportArchive -archivePath build/$Project_Name-adhoc.xcarchive \
-exportOptionsPlist ${ADHOCExportOptionsPlist} \
-exportPath ./ipa/$Project_Name-adhoc

    elif [ "$method" = "2" ]
    then

    if [[ "$isuseworkspace" = "yes" ]]; then
    	#statements
xcodebuild \
-workspace $Workspace_Name.xcworkspace \
-scheme $Project_Name -configuration $Configuration \
-archivePath build/$Project_Name-appstore.xcarchive \
clean archive build \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${APPSTOREROVISIONING_PROFILE_NAME}" \
PRODUCT_BUNDLE_IDENTIFIER="${bundleID}"

    	else
 xcodebuild \
-project $Project_Name.xcodeproj \
-scheme $Project_Name \
-configuration $Configuration \
-archivePath build/$Project_Name-appstore.xcarchive \
clean archive build \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${APPSTOREROVISIONING_PROFILE_NAME}" \
PRODUCT_BUNDLE_IDENTIFIER="${bundleID}"
    fi
#appstore脚本

xcodebuild  -exportArchive \
-archivePath build/$Project_Name-appstore.xcarchive \
-exportOptionsPlist ${AppStoreExportOptionsPlist} \
-exportPath ./ipa/$Project_Name-appstore

echo "是否上传蒲公英?"
echo "yes/no"
read parameter

    else
    echo "参数无效...."
    exit 1
    fi
fi

if [[ $parameter = "yes" ]]; then
    #statements
    curl -F "file=@${ADHOCFILEPATH}" \
    -F "uKey=${UKEY}" \
    -F "_api_key=${APIKEY}" \
    https://www.pgyer.com/apiv1/app/upload
fi

