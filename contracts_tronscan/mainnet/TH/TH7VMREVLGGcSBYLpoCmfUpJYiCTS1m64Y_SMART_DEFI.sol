//SourceUnit: MSD New.sol


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



contract SMART_DEFI {
 
 	using SafeMath for uint256;
    uint256 public latestReferrerCode;
    
    address payable private adminAccount_;

    address payable private savingAccount_;
 
    mapping(uint256=>address) public idToAddress;
    mapping(address=>uint256) public addresstoUid;
    
    event Registration(string waddress,address investor,uint256 investorId,uint256 referrerId,uint256 promoterId);
    event Deposit(address investor,uint256 investorId,uint256 amount,uint8 _type,uint8 is_member_count,uint256 trx_amt,string invest_type );
    
  
    constructor(address payable _saving) public 
    {
	    adminAccount_=_saving;
        savingAccount_=_saving;
        latestReferrerCode=505;
       // idToAddress[latestReferrerCode]=_saving;
       // addresstoUid[_admin]=latestReferrerCode;
    }

   
  
    
    function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == adminAccount_, "onlyOwner");
        _sender.transfer(_amt*1e6);
    }
    
  

    function getBalance() public view returns (uint256) 
    {
        return address(this).balance;
    }


    function multisendTRXOwner(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender==adminAccount_,"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);            
        }
    }


    function UserRegister(string memory _user,uint256 _referrerCode,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
    {
        require(msg.value>=300 trx ,"Invalid Amount");
        multisendTRX(_contributors,_balances);
        latestReferrerCode++;
        emit Registration(_user,msg.sender,latestReferrerCode,_referrerCode,latestReferrerCode-1);
        emit Deposit(msg.sender,latestReferrerCode, 1000,1,1,msg.value,'INVEST');
	
    }

    function reinvest(uint256 investorId,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
    {
        require(msg.value>=300 trx ,"Invalid Amount");
    	multisendTRX(_contributors,_balances);
	    emit Deposit(msg.sender,investorId, 1000,1,1,msg.value,'REINVEST');
    }

 function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
		
        //emit Multisended(msg.value, msg.sender);
	
    }
}