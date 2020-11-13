// SPDX-License-Identifier: MIT

/**
 * LYNC Network
 * https://lync.network
 *
 * Additional details for contract and wallet information:
 * https://lync.network/tracking/
 *
 * The cryptocurrency network designed for passive token rewards for its community.
 */

pragma solidity ^0.7.0;

import "./lynctoken.sol";

contract LYNCTokenSale {

   //Enable SafeMath
    using SafeMath for uint256;

    address payable owner;
    address public contractAddress;
    uint256 public tokensSold;
    uint256 public priceETH;
    uint256 public SCALAR = 1e18;           // multiplier
    uint256 public maxBuyETH = 10;          // in ETH
    uint256 public tokenOverFlow = 5e20;    // 500 tokens
    uint256 public tokenPrice = 70;         // in cents
    uint256 public batchSize = 1;           // batch size of distribution

    bool public saleEnabled = false;

    LYNCToken public tokenContract;

    //Events
    event Sell(address _buyer, uint256 _amount);


    //Mappings
    mapping(address => uint256) public purchaseData;

    //Buyers list
    address[] userIndex;

    //On deployment
    constructor(LYNCToken _tokenContract, uint256 _priceETH) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        contractAddress = address(this);
        priceETH = _priceETH;
    }

    //Buy tokens with ETH
    function buyTokens(uint256 _ethSent) public payable {

        require(saleEnabled == true, "The LYNC Initial Token Offering will commence on the 28th of September @ 5PM UTC");
        require(_ethSent <= maxBuyETH.mul(SCALAR), "Exceeded maximum purchase per transaction");
        require(_ethSent >= 1e17, "Minimum purchase per transaction is 0.1 ETH");

        uint256 _priceETH = priceETH.mul(SCALAR);

        //Check if there are enough tokens available in this round
        if (tokensSold < (100000 * SCALAR)) {

            //Scale up token price
            uint256 _tokenPrice = tokenPrice.mul(SCALAR);

            //Calculate tokens based on current eth price in contract
            uint256 _tokensPerETH = _priceETH.div(_tokenPrice);
            uint256 _numberOfTokens = _ethSent.mul(_tokensPerETH);

            //Calculate how many tokens left in this round
            uint256 _tokensRemaining = (100000 * SCALAR).sub(tokensSold);

            //Check that the purchase amount does not exceed tokens remaining in this round, including overflow
            require(_numberOfTokens < _tokensRemaining.add(tokenOverFlow), "Not enough tokens remain in Round 1");

            //Record purchased tokens
            if(purchaseData[msg.sender] == 0) {
                userIndex.push(msg.sender);
            }

            purchaseData[msg.sender] = purchaseData[msg.sender].add(_numberOfTokens);
            tokensSold = tokensSold.add(_numberOfTokens);
            emit Sell(msg.sender, _numberOfTokens);

            //Update token price if round max is met after this tranasaction
            if(tokensSold > 100000 * SCALAR) {
              //Set the token price for Round 2
              tokenPrice = 80; //in cents
            }

        } else if (tokensSold > (100000 * SCALAR) && tokensSold < (250000 * SCALAR)) {

            //Scale up token price
            uint256 _tokenPrice = tokenPrice.mul(SCALAR);

            //Calculate tokens based on current eth price in contract
            uint256 _tokensPerETH = _priceETH.div(_tokenPrice);
            uint256 _numberOfTokens = _ethSent.mul(_tokensPerETH);

            //Calculate how many tokens left in this round
            uint256 _tokensRemaining = (250000 * SCALAR).sub(tokensSold);

            //Check that the purchase amount does not exceed tokens remaining in this round, including overflow
            require(_numberOfTokens < _tokensRemaining.add(tokenOverFlow), "Not enough tokens remain in Round 2");

            //Record purchased tokens
            if(purchaseData[msg.sender] == 0) {
                userIndex.push(msg.sender);
            }
            purchaseData[msg.sender] = purchaseData[msg.sender].add(_numberOfTokens);
            tokensSold = tokensSold.add(_numberOfTokens);
            emit Sell(msg.sender, _numberOfTokens);

            //Update token price if round max is met after this tranasaction
            if(tokensSold > 250000 * SCALAR) {
              //Set the token price for Round 3
              tokenPrice = 90; //in cents
            }

        } else {

            //Scale up token price
            uint256 _tokenPrice = tokenPrice.mul(SCALAR);

            //Calculate tokens based on current eth price in contract
            uint256 _tokensPerETH = _priceETH.div(_tokenPrice);
            uint256 _numberOfTokens = _ethSent.mul(_tokensPerETH);

            //Check that the purchase amount does not exceed remaining tokens
            require(_numberOfTokens <= tokenContract.balanceOf(address(this)), "Not enough tokens remain in Round 3");

            //Record purchased tokens
            if(purchaseData[msg.sender] == 0) {
                userIndex.push(msg.sender);
            }
            purchaseData[msg.sender] = purchaseData[msg.sender].add(_numberOfTokens);
            tokensSold = tokensSold.add(_numberOfTokens);
            emit Sell(msg.sender, _numberOfTokens);
        }
    }

    //Return total number of buyers
    function totalBuyers() view public returns (uint256) {
        return userIndex.length;
    }

    //Enable the token sale
    function enableSale(bool _saleStatus) public onlyOwner {
        saleEnabled = _saleStatus;
    }

    //Update the current ETH price in cents
    function updatePriceETH(uint256 _updateETH) public onlyOwner {
        priceETH = _updateETH;
    }

    //Update the maximum buy in ETH
    function updateMaxBuyETH(uint256 _maxBuyETH) public onlyOwner {
        maxBuyETH = _maxBuyETH;
    }

    //Update the distribution batch size
    function updateBatchSize(uint256 _batchSize) public onlyOwner {
        batchSize = _batchSize;
    }

    //Distribute purchased tokens in batches
    function distributeTokens() public onlyOwner {

        for (uint256 i = 0; i < batchSize; i++) {
            address _userAddress = userIndex[i];
            uint256 _tokensOwed = purchaseData[_userAddress];
            if(_tokensOwed > 0) {
                require(tokenContract.transfer(_userAddress, _tokensOwed));
                purchaseData[_userAddress] = 0;
            }
        }
    }

    //Withdraw current ETH balance
    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    //End the token sale and transfer remaining ETH and tokens to the owner
    function endSale() public onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        msg.sender.transfer(address(this).balance);
        saleEnabled = false;
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only current owner can call this function");
        _;
    }
}
