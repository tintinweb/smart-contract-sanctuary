/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-15
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
      function intTransfer(address _from, address _to, uint256 tokenId) external returns(bool);
     
}

contract CATToken{
    function allowDeposit(address _addr) public view returns (bool);
    function burnToken(address _from,uint256 _amount) external;
}


contract LoanContractDB{
      function debitContract(uint256 _contractID) public view returns (uint256 _priciple,uint256 _comInt,uint256 _loanInt,uint256 _guaInt);
      function loanContractData(uint256 _idx) public view  returns(uint256[] memory _data,bytes8 _cur,address[] memory _addr);

      function TokenToConID(uint256 _TokenID) public view returns (uint256);
      function loanConIDToIdx(uint256 _coinID) public view returns (uint256);
      
      function defaultContract(uint256 _contractID,uint256 _defAmount) external returns(bool);
      function getPaidInfo(uint256 _conID) public view  returns(uint256[] memory _data,address _contract);
      
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

    uint256 public version = 1;
    uint256 public decimal = 18;
    string public CURRENCY = 'USD';
    uint256 public SECPYEAR = 31536000;

    CATToken public catToken;
    RatToken public ratToken;
    LoanContractDB public contractDB;
    SELLSZO  public sellSZO;
    

    constructor() public{
        catToken = CATToken(0xD216356c91b88609C82Bd988d4425bb7EDf1Beb4);
        ratToken = RatToken(0x8bE308B0A4CB6753783E078cF12E4A236c11a85A);
        sellSZO = SELLSZO(0x0D80089B5E171eaC7b0CdC7afe6bC353B71832d1);
        contractDB = LoanContractDB(0xd3F0D9a6DDC61f5a2C40458EF81A3b9fb735b7e3);
    }
    
    function setCatToken(address _addr) public onlyAdmin returns(bool){
        catToken = CATToken(_addr);
        return true;
    }
    
    function setRatToken(address _addr) public onlyAdmin returns(bool){
        ratToken = RatToken(_addr);
        return true;
    }
    
    function setSellSZO(address _addr) public onlyAdmin returns(bool){
        sellSZO = SELLSZO(_addr);
        return true;
    }
    
    function setContractDB(address _addr) public onlyAdmin returns(bool){
        contractDB = LoanContractDB(_addr);
        return true;
    }
    
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
        require(_fee >= 10 ether,"Can't pay for fee");
        return _paidContract(_loanConID,_amount,_fee,_from,poolAddr,_tokenID,_conID);
    }



}