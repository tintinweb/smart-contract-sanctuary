/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.5.8;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract members {

	using SafeMath for uint256;
	
	address payable public founder1;
	address payable public founder2;
	address payable public founder3;
	address payable public founder4;
	address payable public founder5;
	address payable public member1;	
	address payable public member2;
	address payable public member3;
	address payable public member4;
	address payable public member5;
	address payable public member6;
	
	uint256 public unlockRate1;
	bool public unlockRate1used = false;
    uint256 public unlockRate2;
    bool public unlockRate2used = false;
    uint256 public unlockRate3;
    uint256 public fullUnlock;
    uint256 public AmountToken;

    IERC20 public  TINV;	
    
//    bool public initialized = false;
    
      function depositTinv (uint256 _amount) external payable {
            address from = msg.sender;
            address to = address(this);
            AmountToken +=_amount;
            TINV.transferFrom(from, to, _amount);
        }

	// mapping for all the members
	mapping(address => bool) public members;
	// on deployment, add in all the members, and the token
    constructor(
        address payable founder1_, 
        address payable founder2_, 
        address payable founder3_, 
        address payable founder4_, 
        address payable founder5_,
        address payable member1_, 
        address payable member2_, 
        address payable member3_, 
        address payable member4_, 
        address payable member5_,
        address payable member6_, 
        IERC20 TINV_) 
        public {
            founder1 = founder1_;
            founder2 = founder2_;
            founder3 = founder3_;
            founder4 = founder4_;    
            founder5 = founder5_;
            member1 = member1_; 
            member2 = member2_; 
            member3 = member3_;  
            member4 = member4_; 
            member5 = member5_;  
            member6 = member6_;             
            TINV = TINV_;
            
            members[founder1] = true;
            members[founder2] = true;
	        members[founder3] = true;
	        members[founder4] = true;
	        members[founder5] = true;    
            members[member1] = true;
            members[member2] = true;
	        members[member3] = true;
	        members[member4] = true;
	        members[member5] = true;     	        
	        members[member6] = true;   
	        
	        unlockRate1 = now + 1 days;
            unlockRate2 = now + 30 days;
            unlockRate3 = now + 60 days;
            fullUnlock  = now + 90 days;
    }
	
	// mapping for allowance
	struct User {mapping(address => uint256) allowance;}
	struct Info {mapping(address => User) users;	}
	Info private info;
	event Approval(address indexed owner, address indexed spender, uint256 tokens);

	
    // read function, you can view how much allowance is granted from one founder to another
	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}


	function transferOne() public payable returns (bool) {
	  	require(members[msg.sender], "You are not a member");  
	  	require(!unlockRate1used, "already paid out");
	  	require(unlockRate1 < now, "too early");
	  	unlockRate1used = true;
        uint256 oneShare = (AmountToken/5)/16;
        TINV.transfer(member1,oneShare);
        TINV.transfer(member2,oneShare);
        TINV.transfer(member3,oneShare);
        TINV.transfer(member4,oneShare);
        TINV.transfer(member5,oneShare);
        TINV.transfer(member6,oneShare);
        TINV.transfer(founder1,oneShare*2);
        TINV.transfer(founder2,oneShare*2);
        TINV.transfer(founder3,oneShare*2);
        TINV.transfer(founder4,oneShare*2);
        TINV.transfer(founder5,oneShare*2);
	    AmountToken -= oneShare * 16;
		return true;
	}
}