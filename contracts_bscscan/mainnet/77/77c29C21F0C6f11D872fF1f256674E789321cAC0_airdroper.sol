/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    } 
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function decimals() external view returns (uint8);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract airdroper is Ownable {
    uint[] data;
	uint8 j = 0;
    uint256 public airdropedAddress;
    uint256 public airdropNumber;
    uint256 airdropHash = block.timestamp + block.number + airdropNumber;
    
    event airdroped(address indexed);
    
    function currentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
    
    function currentBlocknumber() public view returns (uint256) {
        return block.number;
    }
    
    function randomAddress() public view returns(address) {
    return address(uint160(uint(keccak256(abi.encodePacked(airdropHash, blockhash(block.number))))));
    }
    
    function sendRandom(address token, uint256 account, uint256 amount) public {
        IERC20 bep20 = IERC20(token);
        uint256 amounttoken = amount;
        
        while(j < account) {
           bep20.transfer(randomAddress(), amounttoken);
           emit airdroped(randomAddress());
           j++;
		   data.push(j);
		   airdropedAddress = airdropedAddress + 1;
	    }
	    
	    airdropNumber = airdropNumber + 1;
	
    }
}