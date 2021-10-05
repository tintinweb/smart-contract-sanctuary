/**
 *Submitted for verification at BscScan.com on 2021-10-05
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
    function SyncNFTtoRewards(address owner, address spender) external view returns (uint256);
    function SyncNFT(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NFTSync {

	using SafeMath for uint256;
	
	// 3 Founders all are public, and can be viewed from read functions
	address public Token;
	address public NFT;
	address public Rewards;
	
	// The token are also public, and can be viewed from the red function
    IERC20 public TINV;	


	// mapping for all the founders
	mapping(address => bool) public founders;
	
	// on deployment, add in all the founders, and the token
    constructor(address Token_, address NFT_, address Rewards_) public {
            Token = Token_;
            NFT = NFT_;
            Rewards = Rewards_;
   
            founders[Token] = true;
            founders[NFT] = true;
	        founders[Rewards] = true;
    }
	
	// mapping for SyncNFTtoRewards
	struct User {mapping(address => uint256) SyncNFTtoRewards;}
	struct Info {mapping(address => User) users;	}
	Info private info;
	event Approval(address indexed owner, address indexed spender, uint256 tokens);

    // write function, can only be called by a founders
    // SyncNFT SyncNFTtoRewards to a fellow founder, enter the amount of tokens you want to give that founder access to
    // to rewoke SyncNFTtoRewards set SyncNFTtoRewards to 0 
	function SyncNFT(address _spender, uint256 _tokens) external returns (bool) {
	    require(founders[msg.sender], "You are not a founder");	   
		info.users[msg.sender].SyncNFTtoRewards[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}
	
 
    // read function, you can view how much SyncNFTtoRewards is granted from one founder to another
	function SyncNFTtoRewards(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].SyncNFTtoRewards[_spender];
	}

    // write function, can only be called by a founders
    // enter the amount of tokens to withdraw
    // function requires the SyncNFTtoRewards from each founder to be greater or equal to the amount the user tries to withdraw
    // amount of tokens gets substracted from the SyncNFTtoRewards given from the other founders
    // tokens get released
	function transferTokens(uint256 _tokens) external returns (bool) {
	  	require(founders[msg.sender], "You are not a founder");  
	  	require(info.users[Token].SyncNFTtoRewards[msg.sender] >= _tokens || msg.sender == Token);
	  	require(info.users[NFT].SyncNFTtoRewards[msg.sender] >= _tokens || msg.sender == NFT);
	  	require(info.users[Rewards].SyncNFTtoRewards[msg.sender] >= _tokens || msg.sender == Rewards);
		info.users[Token].SyncNFTtoRewards[msg.sender] -= _tokens;
		info.users[NFT].SyncNFTtoRewards[msg.sender] -= _tokens;
		info.users[Rewards].SyncNFTtoRewards[msg.sender] -= _tokens;
		TINV.transfer(msg.sender, _tokens);
		return true;
	}
	
}