/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

contract MyNFT {
    address private owner;
    constructor () public payable{
        owner = msg.sender;
    }
    
    mapping(address => uint256) private deposits;
    
    event depositEvent(address depositor, uint256 amount);
    event withdrawEvent(address withdrawal, uint256 amount);
    event transferToEvent(address from_, address to_, uint256 amount);
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    function totalBalance() public onlyOwner view returns(uint256) {
        return address(this).balance;
    }
    
    function getBalance() public view returns(uint256) {
        return deposits[msg.sender];
    }
    
    function deposit() public payable {
        deposits[msg.sender] += msg.value;
        emit depositEvent(msg.sender, msg.value);
    }
    
    function withdraw(uint _amount) public {
        require(deposits[msg.sender] >= _amount);
        address payable to = payable(msg.sender);
        deposits[msg.sender] -= _amount;
        to.transfer(_amount);
        emit withdrawEvent(msg.sender, _amount);
    }
    
    function transferTo(address payable _to, uint _amount) public {
        require(deposits[msg.sender] >= _amount);
        require(_to != address(0));
        deposits[msg.sender] -= _amount;
        deposits[_to] += _amount;
        emit transferToEvent(msg.sender, _to, _amount);
    }
}