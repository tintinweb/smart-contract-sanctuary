/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

//SPDX-License-Identifier: MiT

pragma solidity ^0.8.0;

contract Lotto {
    address payable []_gamblers;
    // mapping(address => bool) _isBets;
    address _owner;
    uint _betAmount;
    event Bet(address indexed gambler, uint amount);
    event Random(address indexed winner, uint amount);
    
    constructor() {
        _owner = msg.sender;
        _betAmount = 1000000000000000000;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner, "not authorized");
        _;
    }
    
    function bet() public payable {
        require(msg.value == _betAmount, "amount is not correct");
        require(!isBet(), "bet already");
        
        address payable gambler = payable(msg.sender);
        _gamblers.push(gambler);
        
        emit Bet(msg.sender, msg.value);
    }
    
    function isBet() private view returns(bool) {
        for (uint i = 0; i < _gamblers.length; i++) {
            if (_gamblers[i] == msg.sender) return true;
        }
        return false;
    }
    
    function random() public onlyOwner returns(address, uint) {
        require(_gamblers.length > 0, "must be at least one gambler");
        
        uint number = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % _gamblers.length;
        
        address payable winner = _gamblers[number];
        uint amount = address(this).balance;
        winner.transfer(amount);
        
        delete _gamblers;
        
        emit Random(winner, amount);
        
        return (winner, amount);
    }
    
    function setBetAmount(uint amount) public onlyOwner {
        _betAmount = amount;
    }
    
    function totalSupply() public view returns(uint) {
        return address(this).balance;
    }
    
    function betAmount() public view returns(uint) {
        return _betAmount;
    }
    
    function gamblers() public view returns(uint count, address payable[] memory) {
        return (_gamblers.length, _gamblers);
    }
}