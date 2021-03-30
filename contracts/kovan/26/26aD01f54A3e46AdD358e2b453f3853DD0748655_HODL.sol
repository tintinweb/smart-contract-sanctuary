/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title HODL
 * @dev Smart contract aiming to incentivize holding ETH
 */


interface IWETHGateway {
    /**
    * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
    * is minted.
    * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
    * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
    **/
    function depositETH(address onBehalfOf, uint16 referralCode) external payable;

    /**
    * @dev withdraws the WETH _reserves of msg.sender.
    * @param amount amount of aWETH to withdraw and receive native ETH
    * @param to address of the user who will receive native ETH
    */
    function withdrawETH(uint256 amount, address to) external;
    
    function getAWETHAddress() external returns (address);
}


contract HODL {
    
    IWETHGateway wgw = IWETHGateway(0xf8aC10E65F2073460aAD5f28E1EABE807DC287CF);

    struct info {
        uint256 amount;
        uint256 start;
        uint256 time;
        uint256 index;
    }
    address owner;
    uint256 mainPool = 0;
    
    mapping (address => info) apes;
    address[] apeList;

    constructor() {
        owner = msg.sender;
    }

    function trunc_list(uint256 index) private {
        require(apeList.length != 0, "List is empty!");
        if (apeList.length != 1) {
            apeList[index] = apeList[apeList.length - 1];
            apes[apeList[index]].index = index;
        } 
        apeList.pop();
    }
    
    
    /**
    * @dev deposit ETH to be held
    * @param amount amount of ETH to deposit
    * @param time number of seconds to hold the deposited ETH
    */
    function hold(uint256 amount, uint256 time) external payable {
        require(apes[msg.sender].amount == 0, "Already holding, call to_the_moon()!");
        require(amount > 0, "Deposit amount must be greater than 0!");
        require(msg.value == amount, "Deposit amount must match message value!");
        
        wgw.depositETH{value: msg.value}(address(this), 0);
        
        apes[msg.sender] = info(amount, block.timestamp, time, apeList.length);
        apeList.push(msg.sender);
        mainPool += amount;
    }

    /**
    * @dev add ETH to your deposit, reseting the holding time 
    * @param amount amount of ETH to deposit
    */
    function to_the_moon(uint256 amount) external payable {
        require(apes[msg.sender].amount != 0, "Not holding, call hold()!");
        require(amount > 0, "Deposit amount must be greater than 0!");
        require(msg.value == amount, "Deposit amount must match message value!");
        
        wgw.depositETH{value: msg.value}(address(this), 0);
        
        apes[msg.sender].amount += amount;
        apes[msg.sender].start = block.timestamp;
        mainPool += amount;
    }

    /**
    * @dev withdraw ETH before the holding time has expired, losing (abandoning) a portion of your deposit
    */
    function paper_hands() external {
        info memory ape = apes[msg.sender];
        require(ape.amount > 0, "Not holding any ETH!");
        require(block.timestamp < ape.start + ape.time, "Holding time has expired, call diamond_hands()!");
        uint256 abandoned = ape.amount * (ape.time + ape.start - block.timestamp) / ape.time / 2;
        uint256 payout = ape.amount - abandoned;
        
        address aWETH = wgw.getAWETHAddress();
        aWETH.call(abi.encodeWithSignature("approve(address,uint256)", wgw, payout));
        wgw.withdrawETH(payout, msg.sender);
        
        trunc_list(ape.index);
        mainPool -= ape.amount;
        for (uint256 i = 0; i < apeList.length; i++)
            apes[apeList[i]].amount += abandoned * apes[apeList[i]].amount / mainPool;
        mainPool += abandoned;
        delete apes[msg.sender];
    }

    /**
    * @dev withdraw ETH after the holding time has expired, gaining a portion of abandoned ETH
    */
    function diamond_hands() external {
        info memory ape = apes[msg.sender];
        require(ape.amount > 0, "Not holding any ETH!");
        require(block.timestamp >= ape.start + ape.time, "Holding time not yet expired!");
        
        address aWETH = wgw.getAWETHAddress();
        aWETH.call(abi.encodeWithSignature("approve(address,uint256)", wgw, ape.amount));
        wgw.withdrawETH(ape.amount, msg.sender);
        
        mainPool -= ape.amount;
        trunc_list(ape.index);
        delete apes[msg.sender];
    }

    /**
    * @dev transfers aave earnings to the contract creator
    */
    function transfer_earnings() external {
        require(msg.sender == owner, "You don't own this contract!");
        payable(owner).transfer(address(this).balance);
    }
}