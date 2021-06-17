/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity 0.8.5;

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

interface Token {
    function transfer(address, uint256) external returns (bool);
}

contract TokenSell is Ownable {
    
    function Buy(address payable _buyer) public payable {
        
        if (msg.value < 25e16 || msg.value > 2 ether) { // if BNB amount less then 0.25 or more then 2, then the amount will transfer back to sender..
            _buyer.transfer(msg.value);
        }
    }
    
    // function to allow admin to claim BNB from this address..
    function transferBNB(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    
    // function to allow admin to claim BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
}