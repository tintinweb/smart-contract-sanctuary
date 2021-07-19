/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.4.25;

/*
version 1.01
this works.
will automatically accept eth, 
send out specified token in real time to msg.sender
and send the eth to the contract owner

#1 deploy the contract
#2 call function TokenSaleSetup via ripple (specifying price, contractaddress of token to be sold)
#3 send tokens to the contract address (created in #1)
#4 users can then send eth to the contract

#to do, should have a way to end the contract
# verify what happens if users send more eth than token available for sale

#consider adding BurnableToken, PausableToken 

*/

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract EthToTokenExchangeContract {
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price;              // the price, in wei, per token
    address owner;
    string mystring;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);
    event Contribution(address buyer, uint256 amount);
    
    // try this
    //event Purchase(string mystring, address buyer, uint256 amount);

    function TokenSaleSetup(IERC20Token _tokenContract, uint256 _price) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
    }
    
    
    function () payable public {
    require(msg.sender != owner);   
    
    uint receiveTokens=msg.value/price;
    mystring='NewTransfer';
    
    buyTokens(receiveTokens);
    emit Sold(msg.sender, receiveTokens);
    //trythis
    //emit Purchase(mystring, msg.sender, receiveTokens);

    emit Contribution(msg.sender, msg.value);
    
    // Send Eth received for this purchase to the owner.
    owner.transfer(msg.value);
       
    }
    
    
    
    
    
    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function buyTokens(uint256 numberOfTokens) public payable {
        require(msg.value == safeMultiply(numberOfTokens, price));

        uint256 scaledAmount = safeMultiply(numberOfTokens,
            uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(this) >= scaledAmount);
        
        // verify purchase amount must be 0.1ETH
        require(msg.value == 100000000000000000);

        //emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount));
    }

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens back to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

        // Send Eth from contract to the owner.
        msg.sender.transfer(address(this).balance);
    }
}