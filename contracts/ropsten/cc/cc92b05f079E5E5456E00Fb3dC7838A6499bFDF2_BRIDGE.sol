/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity 0.8.6;

// ----------------------------------------------------------------------------
// BRIDGE contract 
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

interface ERC20Interface {

    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// RECEIVE  
// ----------------------------------------------------------------------------
contract BRIDGE is Owned {
    
    address public operator;
    
    constructor (address _operator) {
    operator = _operator;
    }
    
    modifier onlyOperator {
        require(msg.sender == operator);
        _;
    }
    
    function changeOperator(address _operator) external onlyOwner returns(bool) {
        operator = _operator;
        return true;
    }

    event TransferIn(address indexed from, uint256 tokens, address _contract, address _to);
    event TransferOut(address indexed to, uint256 tokens, address _contract);
    
    function input(uint256 _amount, address _contract, address _to) external returns (bool) {
        ERC20Interface(_contract).transferFrom(msg.sender, address(this), _amount);  
        emit TransferIn(msg.sender, _amount, _contract, _to);
        return true;
    }
    
     function output(address payable _to, uint256 _amount, address _contract) external onlyOperator returns(bool) {
        ERC20Interface(_contract).transfer(_to, _amount);
        emit TransferOut(_to, _amount, _contract);
        return true;
    }
}