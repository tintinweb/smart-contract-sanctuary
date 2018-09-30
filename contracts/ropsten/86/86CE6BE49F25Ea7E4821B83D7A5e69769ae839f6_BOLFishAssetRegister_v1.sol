pragma solidity ^0.4.8;

contract BOLFishAssetRegister_v1 {

address private creator = msg.sender;

struct AssetHeader {
    int cdid;
    string sitekey;
    string sfmcode;
    string vendor;
    string fisher;
    string item;
    uint256 timestamp;
}

struct AssetDetail {
    int cdid;
    string item;
    string process;
    string size;
    string grade;
    string state;
    string qty;
    int unittype;
    uint256 timestamp;
}

struct AssetComment {
    int cdid;
    string item;
    string comment;
    uint256 registerdate;
    uint256 timestamp;
}

mapping(int  => AssetHeader) public assetHeaderStore;
mapping(int  => AssetDetail) public assetDetailStore;
mapping(int  => AssetComment) public assetCommentStore;

function registerAssetHeader(int _cdid, string _sitekey, string _sfmcode, string _vendor, string _fisher, string _item)  {
    
        if (msg.sender == address(creator)) {
     
          AssetHeader storage assetheader = assetHeaderStore[_cdid];
          assetheader.cdid = _cdid;
          assetheader.sitekey = _sitekey;
          assetheader.sfmcode = _sfmcode;
          assetheader.vendor = _vendor;
          assetheader.fisher = _fisher;
          assetheader.item = _item;
          assetheader.timestamp = now;
          
        }
          
    }
    
function registerAssetDetail(int _cdid, string _item, string _process, string _size, string _grade, string _state, string _qty, int _unittype)  {
    
     if (msg.sender == address(creator)) {
 
          AssetDetail storage assetdetail = assetDetailStore[_cdid];
          assetdetail.cdid = _cdid;
          assetdetail.item = _item;
          assetdetail.process = _process;
          assetdetail.size = _size;
          assetdetail.grade = _grade;
          assetdetail.state = _state;
          assetdetail.qty = _qty;
          assetdetail.unittype = _unittype;
          assetdetail.timestamp = now;
          
         }
    }    
    

function registerAssetComment(int _cdid, string _item, string _comment,  uint256 _registerdate)  {
 
    if (msg.sender == address(creator)) {
          AssetComment storage assetcomment = assetCommentStore[_cdid];
          assetcomment.cdid = _cdid;
          assetcomment.item = _item;
          assetcomment.comment = _comment;
          assetcomment.registerdate = _registerdate;
          assetcomment.timestamp = now;
        }     
    }    
  
}