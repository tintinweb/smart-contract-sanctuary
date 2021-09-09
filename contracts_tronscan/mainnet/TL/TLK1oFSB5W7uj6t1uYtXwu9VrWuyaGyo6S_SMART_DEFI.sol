//SourceUnit: mysmart_defi.sol

pragma solidity ^0.5.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ITRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}


contract SMART_DEFI {
 
 	using SafeMath for uint256;
    uint256 public latestReferrerCode;
    
    address payable private adminAccount_;

    address payable private savingAccount_;
 
    mapping(uint256=>address) public idToAddress;
    mapping(address=>uint256) public addresstoUid;
    
	ITRC20 private SMART_DEFI; 


    event Registration(string waddress,address investor,uint256 investorId,address referrer,uint256 referrerId,address promoter,uint256 promoterId);
    event Deposit(address investor,uint256 investorId,uint256 amount,uint8 _type,uint8 is_member_count,uint256 trx_amt );
    
  
    constructor(address payable _saving,address payable _admin,ITRC20 _SMART_DEFI) public 
    {
		SMART_DEFI=_SMART_DEFI;
        adminAccount_=_admin;
        savingAccount_=_saving;
        latestReferrerCode++;
        idToAddress[latestReferrerCode]=_admin;
        addresstoUid[_admin]=latestReferrerCode;
    }

  
    
    function setAdminAccount(address payable _newAccount,address payable _saving) public  {
        require(_newAccount != address(0) && msg.sender==adminAccount_);
        adminAccount_ = _newAccount;
        savingAccount_=_saving;
    }
    
  
    
    function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == adminAccount_, "onlyOwner");
        _sender.transfer(_amt*1e6);
    }
    
  

    function getBalance() public view returns (uint256) 
    {
        return address(this).balance;
    }


    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender==adminAccount_,"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);            
        }
    }


    function _invest(string memory _user,uint256 _referrerCode) public payable
    {
       // require(msg.value==500 trx || msg.value==1000 trx || msg.value==2000 trx || msg.value==3000 trx  || msg.value==4000 trx || msg.value==5000 trx,"Invalid Amount");
        require(idToAddress[_referrerCode]!=address(0),"Invalid Referrer ID");
        if(addresstoUid[msg.sender]==0)
        {
			//Trnasfer Token 
			SMART_DEFI.transfer(msg.sender , (1000*100000000));
            latestReferrerCode++;
            idToAddress[latestReferrerCode]=msg.sender;
            addresstoUid[msg.sender]=latestReferrerCode;
            emit Registration(_user,msg.sender,latestReferrerCode,idToAddress[_referrerCode],_referrerCode,idToAddress[latestReferrerCode-1],latestReferrerCode-1);
        }
         address(uint160(savingAccount_)).transfer(address(this).balance);
         emit Deposit(msg.sender,addresstoUid[msg.sender], 1000,1,0,msg.value);
    }

      function reinvest(string memory _user) public payable
    {
      // require(msg.value==500 trx || msg.value==1000 trx || msg.value==2000 trx || msg.value==3000 trx  || msg.value==4000 trx || msg.value==5000 trx,"Invalid Amount");
        require(addresstoUid[msg.sender]>0,"Register first");
        address(uint160(savingAccount_)).transfer(address(this).balance);
		//Trnasfer Token 
		SMART_DEFI.transfer(msg.sender , (1000*100000000));
        emit Deposit(msg.sender,addresstoUid[msg.sender], 1000,1,1,msg.value);
    }

}