contract AFAFishAssetRegister_v5 {

address private creator = msg.sender;

struct EnterBarcode {
    bytes32 Barcode;
    bytes32 Company;
    string Description;
    bytes32 Quantity;
    bytes32 ReceivedDate;
    uint256 BlockChainDateTime;
}

mapping(bytes32  => EnterBarcode) public Enter_Barcode;

function registerBarcode(bytes32 _barcode, bytes32 _barcode_string, bytes32 _company, string _description, bytes32 _quantity, bytes32 _receiveddate)  {
    
        if (msg.sender == address(creator)) {
     
          EnterBarcode storage enterbarcode = Enter_Barcode[_barcode];
          enterbarcode.Barcode = _barcode_string;
          enterbarcode.Company = _company;
          enterbarcode.Description = _description;
          enterbarcode.Quantity = _quantity;
          enterbarcode.ReceivedDate = _receiveddate;
          enterbarcode.BlockChainDateTime = now;
          
        }
          
    }
    
function FindMyFish_EnterBarcode(bytes32 _barcode) public constant returns(bytes32, bytes32, string, bytes32, bytes32, uint256) {
        return (Enter_Barcode[_barcode].Barcode, Enter_Barcode[_barcode].Company, Enter_Barcode[_barcode].Description, Enter_Barcode[_barcode].Quantity, Enter_Barcode[_barcode].ReceivedDate, Enter_Barcode[_barcode].BlockChainDateTime);
    }    
    
}