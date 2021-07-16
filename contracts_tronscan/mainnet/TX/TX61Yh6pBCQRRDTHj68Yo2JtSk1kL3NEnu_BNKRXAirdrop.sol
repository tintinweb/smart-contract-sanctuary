//SourceUnit: Airdrop.sol

/*
    SPDX-License-Identifier: MIT
    A Bankteller Production
    Bankroll Network
    Copyright 2020
*/

pragma solidity ^0.4.25;

contract Token {

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {}

    function transfer(address to, uint256 value) public returns (bool) {}

    function balanceOf(address who) public view returns (uint256) {}

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

}

contract BNKRXAirdrop {

    struct User {
        uint256 total_airdrops;
        uint256 total_received;
        uint256 last_airdrop;
    }

    mapping(address => User) public users;

    //BNKRX
    address public bnkrxTokenAddress = address(
        0x4167da83cfc7d0a1894bb52d7fb12ac8f536b0716f
    ); //TKSLNVrDjb7xCiAySZvjXB9SxxVFieZA7C

    //Stockpile
    address public stockpileAddress = address(
        0x418fb744764073b0e5bc7d9fafeb6bea7f2d038dbc
    ); //TP57B8nKa2P3uVQutu6Mk7a8JtX26NSDcd

    Token private bnkrx;

    uint256 public total_airdrops; 
    uint256 public total_stockpile;
    uint256 public total_recipients;
    uint256 public total_txs; 

    event onAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    constructor() public {
        
        //BNKRX
        bnkrx = Token(bnkrxTokenAddress);
    
    }

    //@dev Send specified BNKRX amount supplying an upline referral
    function send(address _to, uint256 _amount) external {

        address _addr = msg.sender; 

        //Check allowance and send BNKRX to the contract; future proof error reporting a little
        require(bnkrx.allowance(_addr, address(this)) >= _amount, "Insufficient allowance for airdrop contract");

        //This can only fail if the balance is insufficient
        require(
            bnkrx.transferFrom(
                _addr,
                address(this),
                _amount
            ),
            "BNKRX to contract transfer failed; check balance"
        );

      
        //Transfer to the final destination; all transfers from this point are from the contract and will succeed
        bnkrx.transfer(_to, (_amount * 90) / 100);

        //User stats
        users[_addr].total_airdrops += _amount;
        users[_addr].last_airdrop = now;
        
        //track recipients
        if (users[_to].total_received == 0){
            total_recipients += 1;
        }
        users[_to].total_received += _amount;

        //Keep track of overall stats
        total_airdrops += _amount;
        total_txs += 1;

        //Pay stockpile holders
        sweep(false);

        //Let em know!
        emit onAirdrop(_addr, _to, _amount, now);
    }

    //@dev Get current user snapshot 
    function userInfo(address _addr) view external returns(uint256 _airdrops, uint256 _received, uint256 last_airdrop) {
        return (users[_addr].total_airdrops, users[_addr].total_received, users[_addr].last_airdrop);
    }

    //@dev Get contract global stats
    function stats() view external returns (uint256 _airdrops, uint256 _stockpile, uint256 _recipients, uint256 _txs){
        return (total_airdrops, total_stockpile, total_recipients, total_txs);
    }

    //@dev Sweep excess, 10%, to stockpile 
    function  sweep(bool force_sweep) public {
        uint256 _balance = bnkrx.balanceOf(address(this));

        //Nothing to do
        if (_balance == 0){
            return;
        }

        //We buffer 1K BNKRX to reduce fees
        if (_balance > 1000e6 || force_sweep) {
            bnkrx.transfer(stockpileAddress, _balance);

            //track contribution to stockpile
            total_stockpile += _balance;
        }
    }

}