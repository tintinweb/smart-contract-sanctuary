contract AFAFishAssetRegister_v4 {

address private creator = msg.sender;

struct EnterBarcode {
    string Barcode;
    string Company;
    string Description;
    string Quantity;
    string ReceivedDate;
    uint256 BlockChainDateTime;
}

mapping(bytes9  => EnterBarcode) public Enter_Barcode;

function registerBarcode(bytes9 _barcode, string _barcode_string, string _company, string _description, string _quantity, string _receiveddate)  {
    
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
    
function FindMyFish_EnterBarcode(bytes9 _barcode) public constant returns(string, string, string, string, string, uint256) {
        return (Enter_Barcode[_barcode].Barcode, Enter_Barcode[_barcode].Company, Enter_Barcode[_barcode].Description, Enter_Barcode[_barcode].Quantity, Enter_Barcode[_barcode].ReceivedDate, Enter_Barcode[_barcode].BlockChainDateTime);
    }    
    
}