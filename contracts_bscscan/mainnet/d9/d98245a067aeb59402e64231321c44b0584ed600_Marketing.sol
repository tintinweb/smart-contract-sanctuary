/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


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

contract Marketing {

	using SafeMath for uint256;
	
	// 3 Founders all are public, and can be viewed from read functions
	address public founder1;
	address public founder2;
	address public founder3;
	
	// The token are also public, and can be viewed from the red function
    IERC20 public CFB;	


	// mapping for all the founders
	mapping(address => bool) public founders;
	
	// on deployment, add in all the founders, and the token
    constructor(address founder1_, address founder2_, address founder3_, IERC20 CFB_) public {
            founder1 = founder1_;
            founder2 = founder2_;
            founder3 = founder3_;
            CFB = CFB_;
            founders[founder1] = true;
            founders[founder2] = true;
	        founders[founder3] = true;
    }
	
	// mapping for allowance
	struct User {mapping(address => uint256) allowance;}
	struct Info {mapping(address => User) users;	}
	Info private info;
	event Approval(address indexed owner, address indexed spender, uint256 tokens);

    // write function, can only be called by a founders
    // approve allowance to a fellow founder, enter the amount of tokens you want to give that founder access to
    // to rewoke allowance set allowance to 0 
	function approve(address _spender, uint256 _tokens) external returns (bool) {
	    require(founders[msg.sender], "You are not a founder");	   
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}
	
 
    // read function, you can view how much allowance is granted from one founder to another
	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

    // write function, can only be called by a founders
    // enter the amount of tokens to withdraw
    // function requires the allowance from each founder to be greater or equal to the amount the user tries to withdraw
    // amount of tokens gets substracted from the allowance given from the other founders
    // tokens get released
	function transferTokens(uint256 _tokens) external returns (bool) {
	  	require(founders[msg.sender], "You are not a founder");  
	  	require(info.users[founder1].allowance[msg.sender] >= _tokens || msg.sender == founder1);
	  	require(info.users[founder2].allowance[msg.sender] >= _tokens || msg.sender == founder2);
	  	require(info.users[founder3].allowance[msg.sender] >= _tokens || msg.sender == founder3);
		info.users[founder1].allowance[msg.sender] -= _tokens;
		info.users[founder2].allowance[msg.sender] -= _tokens;
		info.users[founder3].allowance[msg.sender] -= _tokens;
		CFB.transfer(msg.sender, _tokens);
		return true;
	}
}