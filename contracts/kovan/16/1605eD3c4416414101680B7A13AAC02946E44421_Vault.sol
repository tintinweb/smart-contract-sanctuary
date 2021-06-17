/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "only the owner can call this method");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "ownership cannot be transferred to address 0");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
	    require(newOwner != address(0), "no new owner has been set up");
		require(msg.sender == newOwner, "only the new owner can accept ownership");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract Adminable is Ownable {
    mapping(address => bool) public admin;

    event AdminSet(address indexed adminAddress, bool indexed status);

	constructor() {
        admin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "only the admin can call this method");
        _;
    }

    function setAdmin(address adminAddress, bool status) public onlyOwner {
        emit AdminSet(adminAddress, status);
        admin[adminAddress] = status;
    }
}

abstract contract tokenInterface {
	function balanceOf(address _owner) public virtual view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public virtual returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
	function approve(address spender, uint256 addedValue) public virtual returns (bool);
}

contract Vault is Adminable {
    using SafeMath for uint256;

    mapping (address => uint256) public deposited;
    mapping (address => uint256) public withdrawn;
    
    uint256 public totalDeposited;
    uint256 public available;
    
    bool public active;

    tokenInterface public token;
    
    /*
     * Vault 
     */
     
    function availableRate() public view returns ( uint256 rate ) {
        rate = available.mul(1e18).div(totalDeposited);
    }
     
    function availableBalanceOf(address _tknHolder) public view returns (uint256 balance) {
        balance = deposited[_tknHolder]
                    .mul(availableRate())
                    .div(1e18)
                    .sub(withdrawn[_tknHolder]);
    }
     
     modifier isActive() {
		require( active, "the vault is not be actived yet." );
        _;
    }
    
     modifier isNotActive() {
		require( !active, "the vault is actived" );
        _;
    }
     
    function unlock() public {
        transfer(msg.sender, balanceOf(msg.sender));
    }
    
    /*
     * Admin 
     */
     
    function setActive() public onlyAdmin isNotActive {
        active = true;
    }
    
    function increaseAvailableToken(uint256 _amount) public onlyAdmin isActive {
        available = available.add(_amount);
    }
    
    function setToken(address _token) public onlyOwner returns(bool) {
        require( _token != address(0), "_token cannot be address(0)" );
        token = tokenInterface(_token);
		return true;
    }
    
    constructor(address _admin, address _tkn) {
        setAdmin(_admin, true);
        setToken(_tkn);
    }
    
    /*
     * Sale
     */

    function assignToken(address _to, uint256 _tokenAmount) public isNotActive() returns (bool) {
        

        deposited[_to] = deposited[_to].add(_tokenAmount);
        totalDeposited = totalDeposited.add(_tokenAmount);
        
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        
        emit Transfer(address(0), msg.sender, _tokenAmount);

        return true;
    }
    
    
	/*
	 * ERC20 Implementation
	 */
	 
 	string public name = "STARZ LOCKED";
    string public symbol = "STZL";
    uint8 public decimals = 18;
	
    function totalSupply() view public returns(uint256){
        return token.balanceOf(address(this));
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address _to, uint256 _amount) public isActive returns (bool) {
		require( _amount <= balanceOf(msg.sender), "not enough tokens" );
		require( _amount <= availableBalanceOf(msg.sender), "not enough tokens available" );
		
		withdrawn[msg.sender] = withdrawn[msg.sender].add(_amount);

		token.transfer(_to, _amount);
        emit Transfer(msg.sender, address(0), _amount);
		
        return true;
    }

    function balanceOf(address _tknHolder) public view returns (uint256 balance) {
        balance = deposited[_tknHolder].sub(withdrawn[_tknHolder]);
    }
}