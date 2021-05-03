/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
}

contract YieldingCapitalGateway is Ownable{
  address payable public target;

  constructor(address payable _target) {
    target = _target;
  }

  event Deposit(address indexed _from, uint _value);

  event NewTarget(address _from, address _newTarget);

  fallback() payable external{
    target.transfer(msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function changeTarget(address payable _newTarget) public onlyOwner {
    target = _newTarget;
    emit NewTarget(msg.sender, _newTarget);
  }
}