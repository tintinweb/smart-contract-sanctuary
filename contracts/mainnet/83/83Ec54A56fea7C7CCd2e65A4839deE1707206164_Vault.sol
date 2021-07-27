/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-16
*/

// SPDX-License-Identifier: MIT

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

abstract contract atomicBridgeInterface {
	function depositTokenBob(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bytes memory _msg) public virtual payable returns (bool);
	function withdrawToken(bytes32 _secret) public virtual returns (bool);
	function startRecovery(bytes32 _secretHash) public virtual returns (bool);
	function recoveryWithdraw(bytes32 _secretHash) public virtual payable returns (bool);
}

contract Vault is Adminable {
    using SafeMath for uint256;
    
    atomicBridgeInterface public atomicBridge;
    mapping (address => uint256) public limitAmountOf;
    mapping (address => uint256) public todaySpentAmountOf;
    mapping (address => uint256) public lastTimeOf;
    mapping (address => uint256) public periodOf;
    
    function setAtomicBridge(address _newAtomicBridge) public onlyOwner {
        atomicBridge = atomicBridgeInterface(_newAtomicBridge);
    }
    
    function setSpendLimit(address _tkn, uint256 _newLimitAmount) public onlyOwner {
        limitAmountOf[_tkn] = _newLimitAmount;
    }
    
    function setPeriod(address _tkn, uint256 _newPeriod) public onlyOwner {
        periodOf[_tkn] = _newPeriod;
    }
    
    constructor(address _admin, address _newAtomicBridge, address _tkn, uint256 _newLimitAmount) {
        setAdmin(_admin, true);
        setAtomicBridge(_newAtomicBridge);
        setSpendLimit(_tkn, _newLimitAmount);
        setPeriod(_tkn, 1 days);
    }
    

    function dayIsOver(address _tkn) internal {
        if (block.timestamp >= lastTimeOf[_tkn] + periodOf[_tkn]) {
            lastTimeOf[_tkn] = block.timestamp;
            todaySpentAmountOf[_tkn] = 0;
        }
        
    }
    
    modifier spendingLimit(address _tkn, uint256 _amount) {
        dayIsOver(_tkn);
        require(todaySpentAmountOf[_tkn].add(_amount) < limitAmountOf[_tkn], "you have exceeded your spending limit");
        todaySpentAmountOf[_tkn] = todaySpentAmountOf[_tkn].add(_amount);
        _;
    }

    function readAvailableAmount(address _tkn) public view returns (uint256) {
        if (block.timestamp >= lastTimeOf[_tkn] + periodOf[_tkn]) {
            return limitAmountOf[_tkn];
        } else {
            return limitAmountOf[_tkn].sub(todaySpentAmountOf[_tkn]);
        }
    }
    
    function depositTokenBob(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bytes memory _msg) public payable onlyAdmin spendingLimit(_tokenAddress, _tokenAmount) returns (bool status) {
        tokenInterface tkn = tokenInterface(_tokenAddress);
        tkn.approve(address(atomicBridge), _tokenAmount);
        
        status = atomicBridge.depositTokenBob(_secretHash, _tokenAmount, _tokenAddress, _to, _msg);
    }
    

    function withdrawToken(bytes32 _secret) public onlyAdmin returns (bool status) {
        status = atomicBridge.withdrawToken(_secret);

        if (address(this).balance > 0 ) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    

    function startRecovery(bytes32 _secretHash) public onlyAdmin returns (bool status) {
        status = atomicBridge.startRecovery(_secretHash);
    }
    
    function recoveryWithdraw(bytes32 _secretHash) public payable onlyAdmin returns (bool status) {
        status = atomicBridge.recoveryWithdraw(_secretHash);
    }
    
    function withdrawVault(address _tkn, uint256 _amount) public onlyAdmin spendingLimit(_tkn, _amount) {
        tokenInterface tkn = tokenInterface(_tkn);
        tkn.transfer(msg.sender, _amount);
    }
    
    receive() external payable {

    }
}