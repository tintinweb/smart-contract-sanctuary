pragma solidity ^0.4.18;



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint8 public decimals;

  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
    

/**
 * Copyright (C) 2018  Smartz, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).
 */
 
/**
 * @title SwapTokenForEther
 * Swap tokens of participant1 for ether of participant2
 *
 * @author Vladimir Khramov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="27514b46434e4a4e55094c4f55464a485167544a4655535d094e48">[email&#160;protected]</a>>
 */
contract Swap {

    address public participant1;
    address public participant2;

    ERC20Basic public participant1Token;
    uint256 public participant1TokensCount;

    uint256 public participant2EtherCount;

    bool public isFinished = false;


    function Swap() public payable {

        participant1 = msg.sender;
        participant2 = 0x6422665474ff39b0cfce217587123521c56cf33d;

        participant1Token = ERC20Basic(0x6422665474fF39B0Cfce217587123521C56cF33d);
        require(participant1Token.decimals() <= 18);
        
        participant1TokensCount = 1000 ether / 10**(18-uint256(participant1Token.decimals()));

        participant2EtherCount = 0.001 ether;
        
        assert(participant1 != participant2);
        assert(participant1Token != address(0));
        assert(participant1TokensCount > 0);
        assert(participant2EtherCount > 0);
        
        
    }

    /**
     * Ether accepted
     */
    function () external payable {
        require(!isFinished);
        require(msg.sender == participant2);

        if (msg.value > participant2EtherCount) {
            msg.sender.transfer(msg.value - participant2EtherCount);
        }
    }

    /**
     * Swap tokens for ether
     */
    function swap() external {
        require(!isFinished);

        require(this.balance >= participant2EtherCount);

        uint256 tokensBalance = participant1Token.balanceOf(this);
        require(tokensBalance >= participant1TokensCount);

        isFinished = true;
        
        
        //check transfer
        uint token1Participant2InitialBalance = participant1Token.balanceOf(participant2);
    

        require(participant1Token.transfer(participant2, participant1TokensCount));
        if (tokensBalance > participant1TokensCount) {
            require(
                participant1Token.transfer(participant1, tokensBalance - participant1TokensCount)
            );
        }

        participant1.transfer(this.balance);
        
        
        //check transfer
        assert(participant1Token.balanceOf(participant2) >= token1Participant2InitialBalance+participant1TokensCount);
    
    }

    /**
     * Refund tokens or ether by participants
     */
    function refund() external {
        if (msg.sender == participant1) {
            uint256 tokensBalance = participant1Token.balanceOf(this);
            require(tokensBalance>0);

            participant1Token.transfer(participant1, tokensBalance);
        } else if (msg.sender == participant2) {
            require(this.balance > 0);
            participant2.transfer(this.balance);
        } else {
            revert();
        }
    }
    

    /**
     * Tokens count sent by participant #1
     */
    function participant1SentTokensCount() public view returns (uint256) {
        return participant1Token.balanceOf(this);
    }

    /**
     * Ether count sent by participant #2
     */
    function participant2SentEtherCount() public view returns (uint256) {
        return this.balance;
    }
}