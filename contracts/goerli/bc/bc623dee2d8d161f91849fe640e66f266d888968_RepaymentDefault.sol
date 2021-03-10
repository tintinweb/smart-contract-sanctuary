/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.5.17;
contract Permissions {

  address public admin;

  
  constructor() public {
    admin = msg.sender;
  }
  
  
  modifier onlyAdmin(){
      require(msg.sender == admin);
      _;
  }
  
  function changeAdmin(address _newAdmin) external onlyAdmin{
      admin = _newAdmin;
  }

}

contract RatToken{
    //  function mintToken(address _to,uint256 _tokenId,uint256 _docID,uint256 _tokenType,address _addr) external returns(bool);
    //  function isValidToken(uint256 _tokeID) public view  returns (bool);
    //  function ownerOf(uint256 tokenId) public view returns (address);
    //  function getRatDetail(uint256 _tokenID) public view returns(uint256 _tokenType,uint256 _docID,address _contract);
      function intTransfer(address _from, address _to, uint256 tokenId) external returns(bool);
     
}

contract CATToken{
    //function mintFromContract(address _to,uint256 _amount,uint256 _contractID) external;
    // function mintFromRATToken(uint256 _tokenID) public returns(string memory result);
    // function balanceOf(address tokenOwner) public view returns (uint256 balance);
    // function intTransfer(address _from, address _to, uint256 _amount) external returns(bool);
    function allowDeposit(address _addr) public view returns (bool);
//    function mintFromWarpToken(address _token,uint256 _amount,address to) public returns(bool);
    function burnToken(address _from,uint256 _amount) external;
}


contract LoanContractDB{
  //    function createLoanContract(uint256 _docID,uint256 _contractID,uint256 _amount,address _borrow,uint256 _intCom,uint256 _intLean,uint256 _intGua,string memory _currency) public returns(bool);
    //  function isValidContract(uint256 _contractID) public view returns (bool);
    //  function setConID2Token(uint256 _TokenID,uint256 _conID) public returns(bool);
      function debitContract(uint256 _contractID) public view returns (uint256 _priciple,uint256 _comInt,uint256 _loanInt,uint256 _guaInt);
      function loanContractData(uint256 _idx) public view  returns(uint256[] memory _data,bytes8 _cur,address[] memory _addr);
  
     // function getLoanCredit(uint256 _contractID) public view returns (uint256);
     // function getBorrowAddr(uint256 _contractID) public view returns (address);
     // function getContractInfo(uint256 _conID) public view returns(uint256 _loan,uint256 _paid,uint256 _commission,uint256 _guaID,address _borrow,address _lean,uint256 _leanIdx);
 

    //  function conIDToToken(uint256 contractID) public view returns(uint256);
    //  function loanContractDataFromID(uint256 _conID) public view returns(uint256[] memory _data,bytes8 _cur,address[] memory _addr);
    //  function activeContract(uint256 _contractID,uint256 _termpay,
    //                        uint256 expirationTime,address lender,uint256 _guarantor, uint256 _exRate,uint256 _lenderID) public returns(bool);
    //  function getLoanAmount(uint256 _conID) public view returns(uint256);
    //  function updatePaidContract(uint256 _contractID,uint256 _paidAmount,uint256 _interPaid) external  returns(bool);
      
      function TokenToConID(uint256 _TokenID) public view returns (uint256);
      function loanConIDToIdx(uint256 _coinID) public view returns (uint256);
      
      function defaultContract(uint256 _contractID,uint256 _defAmount) external returns(bool);
      function getPaidInfo(uint256 _conID) public view  returns(uint256[] memory _data,address _contract);
      
    //  function loanInterest(uint256 _conID) public view returns(uint256 _com,uint256 _lend,uint256 _gua);
}

contract S1Global{
    function getAllMaxAddr() public returns(uint256);
    function getAddress(uint256 idx) public returns(address);
    function getAddressLabel(string memory _label) public view returns(address);
}


contract POOLS{
    function loanBalance() public view returns(uint256);
    function borrowWithAddr(uint256 amount,address _addr)public returns(uint256 contractID);
    function borrowInterest() public view returns(uint256);
    function rePaymentWithWrap(uint256 amount,uint256 conIdx,address _addr) public returns(bool);
    function setBorrowInterest(uint256 _newInterst) public;
   
    function pricipleAndInterest(uint256 conIdx) public view returns(uint256 principle,uint256 _int);
    function getBorrowData(uint256 condIdx) public view returns(uint256[] memory _data);

    function token() public view returns(address);
}

contract SZO {

    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
       
	function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
	function intTransfer(address _from, address _to, uint256 _value) external  returns(bool);
	function haveKYC(address _addr) public view returns(bool);
}

contract SELLSZO{
     function buyToken(address _tokenAddr,address _toAddr,uint256 amount,uint256 wallID) public returns(bool);
     function buyUseAndBurn(address _tokenAddr,address _toAddr,uint256 amount) public returns(bool);
     function useAndBurn(address _fromAddress,uint256 amount) public returns(bool);
     function sellPrices(address _addr) public view returns(uint256);
}

contract RepaymentDefault is Permissions{
   // using SafeMath for uint256;

    
    uint256 public version = 1;
    uint256 public decimal = 18;
    string public CURRENCY = 'USD';
    uint256 public SECPYEAR = 31536000;

    CATToken public catToken;
    RatToken public ratToken;
    LoanContractDB public contractDB;
    SELLSZO  public sellSZO;
 //   SZO     public szoToken;
 //   S1Global public s1Global;


    // function setS1Global(address _addr) public onlyAdmin returns (bool){
    // //    s1Global = S1Global(_addr);
    //     catToken = CATToken(s1Global.getAddressLabel("cattoken"));
    //     contractDB = LoanContractDB(s1Global.getAddressLabel("contractdb"));//LoanContractDB(s1Global.contractDB());
    // }

    constructor() public{
       // s1Global = S1Global(0x5F83AdBAf2Ddb9242F7604FD589CFc96dc09867f);
        catToken = CATToken(0x89E5e3bA2576e0E2904601b1c628B79f61F80951);
        ratToken = RatToken(0xbce827633Bf633c2769c6D0bCd0B84123f2BC102);
  //      szoToken = SZO(0xDFC1b3aE5c77cdc8005F22f0De5862bfE8475F15);
        sellSZO = SELLSZO(0xBc699F15C3de12cB9F36403E936B8ABc70C48C7b);
        contractDB = LoanContractDB(0xd31c5E4E67E1462576EBadA6C8226E1Aa4646bf7);
    }

    function setSellSZO(address _addr) public onlyAdmin returns(bool){
        sellSZO = SELLSZO(_addr);
        return true;
    }
    
    // function setSZOToken(address _addr)public onlyAdmin returns(bool){
    //     szoToken = SZO(_addr);
    //     return true;
    // }
    
    function setContractDB(address _addr) public onlyAdmin returns(bool){
        contractDB = LoanContractDB(_addr);
        return true;
    }
    
//   function _interest(uint256 _amount,uint256 _intPY,uint256 _time) internal view returns(uint256 fullInt){
      

//       fullInt = _intPY / 31536000 / 100;  
//       fullInt = (fullInt * _time); 
//       fullInt = fullInt.mul(_amount,decimal);

//   }
  
//   function getBorrowData(uint256 condIdx) public view returns(uint256[] memory _data){
//       require(condIdx <= borrows.length && condIdx > 0,"Error not have this idx");
//       uint256 idx = condIdx - 1;
//       _data = new uint256[](7);

//       _data[0] = borrows[idx].amount;
//       _data[1] = borrows[idx].interest;
//       _data[2] = borrows[idx].repayAmount;
//       _data[3] = borrows[idx].interestPay;
//       _data[4] = borrows[idx].time;
//       _data[5] = borrows[idx].status;
//       _data[6] = borrows[idx].startTime;

//   }  

//   function pricipleAndInterest(uint256 conIdx,address _poolAddr) public view returns(uint256 principle,uint256 _int){
//   //    require(conIdx <= borrows.length && conIdx > 0,"Error not have this idx");
  
//       POOLS pools;
//       uint256[] memory data = new uint256[](7);
//       pools = POOLS(_poolAddr);
//       data = pools.getBorrowData(conIdx);
  
//       if(data[5] == 0){
//          return (0,0);
//       }

//       _data[2] 
//       if(borrows[idx].repayAmount > borrows[idx].amount)
//         principle = 0;
//       else
//         principle = borrows[idx].amount - borrows[idx].repayAmount; 

//       uint256 fullInt = _interest(principle,borrows[idx].interest,now - borrows[idx].time); //_intPerSec(borrows[idx].interest) * (now - borrows[idx].time); 

// //      fullInt = fullInt.mul(borrows[idx].amount,decimal);

//       if(borrows[idx].interestPay > fullInt)
//          _int = 0;
//       else
//          _int  = fullInt - borrows[idx].interestPay;

//   }
    
    
    
//     function getLoanAmountPool(uint256 _conID) external view returns(uint256 _priciple,uint256 _interest){
//   //      require(catToken.allowDeposit(_tokenAddr) == true,"This token not allow to paid");
    
//         uint256[] memory data;
//         address  poolsAddr;
//         data = new uint256[](5);
//         (data,poolsAddr) = contractDB.getPaidInfo(_conID);
        
         
         
//          return  pools.pricipleAndInterest(data[4]);
//         //pricipleAndInterest
//     }
    function getTokenDetail(uint256 _tokenID) public view returns(bool error,string memory message,address _tokenAddr,address _poolAddr,uint256 principle,uint256 sumInt,uint256 _loanConID,uint256 _status,uint256 _conID){
        uint256[] memory data;
        uint256[] memory dataInfo;
        POOLS pools;

        data = new uint256[](5);
        dataInfo = new uint256[](17);
        
        error = false;
        _conID = contractDB.TokenToConID(_tokenID);
        if(_conID == 0)
            error = true;
        else
        {
            (data,_poolAddr) = contractDB.getPaidInfo(_conID);
            uint256 conIdx = contractDB.loanConIDToIdx(_conID);
            (dataInfo,,) = contractDB.loanContractData(conIdx-1);
            _status = dataInfo[14];
            pools = POOLS(_poolAddr);
        
            _tokenAddr = pools.token();
            
            if(catToken.allowDeposit(_tokenAddr)  == false)
            {
                error = true;
                message = "This token not allow to paid";
            }
            else
            {
                _loanConID = data[4];
                 (principle,sumInt) = pools.pricipleAndInterest(data[4]);
            }
        
        }
        
    }


    function _testPaidContract(uint256 _conID,uint256 _amount) public view returns(uint256 principlePaid,uint256  sumInt,uint256 poolConid,uint256 data2,uint256 data0,string memory _error){
        uint256[] memory data;
        POOLS pools;
        address  poolsAddr;
        data = new uint256[](5);
        
        (data,poolsAddr) = contractDB.getPaidInfo(_conID);
        pools = POOLS(poolsAddr);
        
        address _tokenAddr = pools.token();
        if(catToken.allowDeposit(_tokenAddr)  == false) _error = "This token not allow to pai";
        poolConid  = data[4];
        
        (principlePaid,sumInt) = pools.pricipleAndInterest(data[4]);
        
        
    //    pools.rePaymentWithWrap(_amount,data[4],_from); // pay to pool
        data2 = data[2];
        data0 = data[0];
        if(_amount >= principlePaid + sumInt){
            
           // catToken.burnToken(_from,principlePaid); // interest from pool can't burn
        }
        else
        {
         //    catToken.burnToken(_from,_amount);
        }
        
    }

    function _paidContract(uint256 _loanConID,uint256 _amount,uint256 _fee,address _from,address poolAddr,uint256 _tokenID,uint256 _conID) internal returns(bool){
        uint256 principle;
        uint256 sumInt;
        POOLS pools;
      
        
        pools = POOLS(poolAddr);
        
        address _tokenAddr = pools.token();
        
        require(catToken.allowDeposit(_tokenAddr) == true,"This token not allow to paid");
        
        if(payFee(_from,_fee,_tokenAddr) == false)
           return false;
        
        (principle,sumInt) = pools.pricipleAndInterest(_loanConID);
       //data[4] = pool contract id;
        pools.rePaymentWithWrap(_amount,_loanConID,_from); // pay to pool
        
        if(_amount >= principle + sumInt){
            catToken.burnToken(_from,principle); // interest from pool can't burn
            // 
            contractDB.defaultContract(_conID,_amount);
            ratToken.intTransfer(poolAddr,_from,_tokenID);
        }
        else
        {
             catToken.burnToken(_from,_amount - sumInt);
        }    
        return true;
    } 

    
    function payFee(address _from,uint256 amount,address _tokenAddr) internal returns(bool){

            return sellSZO.buyUseAndBurn(_tokenAddr,_from,amount);
    }
    

    function paidTokenDefaultFee(uint256 _loanConID,uint256 _amount,uint256 _fee,address _from,address poolAddr,uint256 _tokenID,uint256 _conID) external returns(bool) {

           
       // if(payFee(_from,_fee,_tokenAddr) == true)
        return _paidContract(_loanConID,_amount,_fee,_from,poolAddr,_tokenID,_conID);
//        else
//            return false;
    }

    // function paidContractDefaultFee(uint256 _conID,uint256 _amount,address _tokenAddr,address _from,uint256 _fee) external returns(bool){
    //     if(payFee(_from,_fee,_tokenAddr) == true)
    //         return _paidContract(_conID,_amount,_tokenAddr,_from);
    //     else
    //         return false;
    // }

}