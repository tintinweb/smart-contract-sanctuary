/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
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

contract PresaleTest is Ownable {
    mapping (address => bool) public hasWalletJoinedPresale;
    mapping (address => uint256) public walletContributionAmount;
    address[] _presaleParticipants;
    uint256[] _presaleParticipantsContributionAmount;
    
    // this is a fallback function, it triggers when BNB is sent to the contract address normally
    receive() external payable {
        require(block.timestamp >= 1625842800, "Presale has not started!");
        require(block.timestamp <= 9925929200, "Presale has ended!");
        // require sender to not have joined in the presale before
        require(hasWalletJoinedPresale[tx.origin] == false, "Oi you've joined the presale before");
        // remove the possibility of a contract entering the presale
        require(tx.origin == msg.sender, "Don't try any funny shit.");
        // require minimum presale contribution to be at least 0.1 BNB
        require(msg.value >= 0.1 * (10**18), "Must send at least 0.1 BNB");
        // require maximum presale contribution to be at most 1 BNB
        require(msg.value <= 1 * (10**18), "Maximum contribution of 1 BNB");
        // require contract balance to be below 100 BNB
        require(address(this).balance <= 100 * (10**18), "Presale already full and ended");
        // require total contract balance after this tx to be below or equal to presale address 
        require(address(this).balance + msg.value <= 100 * (10**18), "You sent too much, final contract value would be above presale hard cap.");
        
        walletContributionAmount[tx.origin] = msg.value;
        hasWalletJoinedPresale[tx.origin] = true;
        _presaleParticipants.push(tx.origin);
        _presaleParticipantsContributionAmount.push(msg.value);
    }
    
    // sends all presale bnb to destination
    function completePresale(address payable presaleBnbDestination) public onlyOwner {
        presaleBnbDestination.transfer(address(this).balance);
    }
    
    // from a given address, get their contribution
    function getParticipantsContribution(address participant) public view returns (uint256) {
        return walletContributionAmount[participant];
    }
    // get all participants
    function getParticipants() public view returns (address[] memory) {
        return _presaleParticipants;
    }
    // get all amounts
    function getAmounts() public view returns (uint256[] memory) {
        return _presaleParticipantsContributionAmount;
    }
}