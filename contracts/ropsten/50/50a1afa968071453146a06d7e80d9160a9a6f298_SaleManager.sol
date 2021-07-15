/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract SaleManager{

    struct User{
        bool claimed;
        uint share; //all addresses shares start as zero
    }

    mapping(address => User) public shareLedger;
    address public owner;
    address public nft;
    uint public balance;
    uint public allocatedShare;
    bool public claimsStarted;

    constructor(address _owner, address _nft){
        owner = _owner;
        nft = _nft;
    }

    receive() external payable{}

    /** 
    * @dev biggest point of power for the owner bc they could choose to not call this function, but doing so means they don't get paid
    * if malicous owner sent 1 eth to contract, then called balance, then claimed their share, then everyones share would be based off 1 Eth instead of actual conctract balance
    * ^^^^^ mitigated by making the NFT in charge of calling this function when withdraw is called on the NFT
    **/
    function logEther() external {//could maybe have the nft contract call this to remove owner power to not call it?
        require(msg.sender == nft, 'Only the nft can log ether');
        require(!claimsStarted, 'Users have already started claiming Eth from the contract');
        balance = address(this).balance;
    }

    /**
    * @dev only deploy nft contract once shareLedger is finalized, then set the SalesManager in the nft equal to this address
    **/
    function createUser(address _address, uint _share) external{
        require(msg.sender == owner, 'Only the owner can create users');
        require(_share > 0, 'Share must be greater than zero');//makes it so that owner can not zero out shares after allocated shares is equal to 100
        require(allocatedShare + _share <= 100, 'Total share allocation greater than 100');
        shareLedger[_address] = User({
            claimed: false,
            share: _share
        });
        allocatedShare += _share;
    }

    function claimEther() external{
        require(balance > 0, 'Balance has not been set');
        require(shareLedger[msg.sender].share > 0, 'Caller has no share to claim');
        require(!shareLedger[msg.sender].claimed, 'Caller already claimed Ether');
        shareLedger[msg.sender].claimed = true;
        uint etherOwed = shareLedger[msg.sender].share * balance / 100;
        if(etherOwed > address(this).balance){//safety check for rounding errors
            etherOwed = address(this).balance;
        }
        claimsStarted = true;
        msg.sender.transfer(etherOwed);
    }
}