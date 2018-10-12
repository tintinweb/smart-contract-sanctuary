pragma solidity ^0.4.25;

contract AFAFishAssetRegister_v9 {

address public owner;
address private creator = msg.sender;
modifier onlyOwner {if(msg.sender != owner) revert();_;}
//function Owned() {owner=msg.sender;}

struct BarCode {
  // fields about this class
  uint barcodeListPointer; // points to a row on the oneList
  string barcode_string;
  bytes32[] barcodedataKeys;
  mapping(bytes32 => uint) barcodedataKeyPointers;
}

// random access
mapping(bytes32 => BarCode) barcodeStructs; // key could be address or uint

// sequential access
bytes32[] barcodeList;

struct BarCodeData {
  // fields about this class
  uint barcodedataListPointer; // points to a row on the manyList
  bytes32 barcodeKey; //<-- here.
   string DataBarCode;
   int InternalID;
    string Company;
    //string Description;
    //string Quantity;
    //string ReceivedDate;
    //uint256 BlockChainDateTime;
}

mapping(bytes32 => BarCodeData) barcodedataStructs; // these are for access by key
bytes32[] barcodedataList; 

function isBarCode(bytes32 _barcode) 
      public 
      constant 
      returns(bool isIndeed) 
    {
      if(barcodeList.length==0) return false;
      return barcodeList[barcodeStructs[_barcode].barcodeListPointer]==_barcode;
    }
    
function isBarCodeData(bytes32 _barcodedataId) 
      public 
      constant 
      returns(bool isIndeed) 
    {
      if(barcodedataList.length==0) return false;
      return barcodedataList[barcodedataStructs[_barcodedataId].barcodedataListPointer]==_barcodedataId;
    }    
    
function getBarCodeDataCount(bytes32 _barcode) 
  public 
  constant 
  returns(uint barcdodedataCount) 
{
  if(!isBarCode(_barcode)) revert();
  return barcodeStructs[_barcode].barcodedataKeys.length;
}

function getBarCodeDataAtIndex(bytes32 _barcode, uint row) 
  public 
  constant 
  returns(bytes32 barcodedataKey) 
{
  if(!isBarCode(_barcode)) revert();
  return barcodeStructs[_barcode].barcodedataKeys[row];
}

function createBarCode(bytes32 _barcode) 
      onlyOwner 
      returns(bool success) 
    {
      if(isBarCode(_barcode)) revert(); // duplicate key prohibited
      barcodeStructs[_barcode].barcodeListPointer = barcodeList.push(_barcode)-1;
      //LogNewOne(msg.sender, oneId);
      return true;
    }
    
function createBarCodeData(bytes32 _barcodedataId, bytes32 _barcode, int _internalID, string _company) onlyOwner returns(bool success) {
  if(!isBarCode(_barcode)) revert();
  if(isBarCodeData(_barcodedataId)) revert(); 
  barcodedataStructs[_barcodedataId].barcodedataListPointer = barcodedataList.push(_barcodedataId)-1;
  barcodedataStructs[_barcodedataId].barcodeKey = _barcode; 
  barcodedataStructs[_barcodedataId].InternalID = _internalID;
  barcodedataStructs[_barcodedataId].Company = _company;
          //enterbarcode.Description = _description;
          //enterbarcode.Quantity = _quantity;
          //enterbarcode.ReceivedDate = _receiveddate;
          //enterbarcode.BlockChainDateTime = now;
  
  barcodeStructs[_barcode].barcodedataKeyPointers[_barcodedataId] = 
   barcodeStructs[_barcode].barcodedataKeys.push(_barcodedataId) - 1;
  //LogNewMany(msg.sender, manyId, oneId);
  return true;
}

}