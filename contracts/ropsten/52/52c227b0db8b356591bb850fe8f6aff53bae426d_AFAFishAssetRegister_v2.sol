pragma solidity ^0.4.8;

contract AFAFishAssetRegister_v2 {

address private creator = msg.sender;

struct EnterBarcode {
    bytes9 Barcode;
    bytes3 Company;
    string Description;
    string Quantity;
    bytes19 ReceivedDate;
    uint256 BlockChainDateTime;
}

mapping(bytes9  => EnterBarcode) public Enter_Barcode;

function registerBarcode(bytes9 _barcode, bytes3 _company, string _description, string _quantity, bytes19 _receiveddate)  {
    
        if (msg.sender == address(creator)) {
     
          EnterBarcode storage enterbarcode = Enter_Barcode[_barcode];
          enterbarcode.Barcode = _barcode;
          enterbarcode.Company = _company;
          enterbarcode.Description = _description;
          enterbarcode.Quantity = _quantity;
          enterbarcode.ReceivedDate = _receiveddate;
          enterbarcode.BlockChainDateTime = now;
          
        }
          
    }
    
}