// SPDX-License-Identifier: CC-BY-NC-3.0

pragma solidity ^0.8.4;

import "Ownable.sol";
import "SafeMath.sol";

/// @author cschmidt.eth
/// @title A simple escrow contract
contract EscrowTapped is Ownable {
    using SafeMath for uint256;
    
    mapping(address => mapping(address => uint256)) private _funds; // wei
    mapping(address => bool) public whitelist;
    
    uint256 public changeJar;
    uint256 public percentage;
    
    constructor() {
        whitelist[msg.sender] = true;
        percentage = 1;
    }
    
    /// @param _sender the address paying into the escrow balance
    /// @param _receiver the address receiving from the escrow balance
    /// @return uint256 the balance amount in wei
    function checkBalance(address _sender, address _receiver) public view returns(uint256) {
        return _funds[_sender][_receiver];
    }
    
    /// @param _to the address to which funds will be released
    /// @notice percentage cannot be changed for funds already deposited
    function depositFunds(address _to) public payable {
        uint256 _percentage = percentage;
        if (whitelist[_to] || whitelist[msg.sender]) _percentage = 0;
        
        uint256 _change = msg.value.mul(_percentage).div(100);
        uint256 _remaining = msg.value.sub(_change);
        
        changeJar += _change;
        _funds[msg.sender][_to] += _remaining;
    }
    
    /// @param _to the address to which funds will be released
    /// @param _amount the amount of wei to be released
    function releaseFunds(address _to, uint256 _amount) public {
        require(_amount <= _funds[msg.sender][_to], "NSF");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "failed to send ether");
        _funds[msg.sender][_to] -= _amount;
    }
    
    /// @param _to the address to which funds will be returned
    /// @param _amount the amount of wei to be returned
    function returnFunds(address _to, uint256 _amount) public {
        require(_amount <= _funds[_to][msg.sender], "NSF");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "failed to send ether");
        _funds[_to][msg.sender] -= _amount;
    }
    
    /// @param _address the address to be added or removed from whitelist
    /// @param _whitelisted the new value of their whitelist status
    function setWhitelist(address _address, bool _whitelisted) public onlyOwner() {
        whitelist[_address] = _whitelisted;
    }
    
    /// @param _percentage the percentage to update the dev fee to
    function setPercentage(uint256 _percentage) public onlyOwner() {
        percentage = _percentage;
    }
    
    function emptyJar() public {
        (bool success, ) = owner().call{value: changeJar}("");
        require(success, "failed to send ether");
    }
}