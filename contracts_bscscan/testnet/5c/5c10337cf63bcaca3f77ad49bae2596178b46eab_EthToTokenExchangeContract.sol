/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.4.25;

/*

todo: 
show current token balance.
add delay to sending 
enable min,max sales amount


version 1.02
v1-0xeac7692ef86a105a91473b0ac74905460f81cd4d
this works.
will automatically accept eth, 
send out specified token in real time to msg.sender
and send the eth to the contract owner

#1 deploy the contract
#2 call function TokenSaleSetup via remix (specifying price, contractaddress of token to be sold)
eg. 100000000000000 uint256 for price = 10,000 tokens per eth
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
    IERC20Token public tokenContract;  // the token being sold => used in TokenSaleSetup
    uint256 public price;              // the price, in wei, per token => used in TokenSaleSetup
    uint256 public min_eth_amt;        // the minimum someone can Purchase => used in TokenSaleSetup
    uint256 public max_eth_amt;        // the maximum someone can Purchase => used in TokenSaleSetup
    
    address owner;
    string mystring;

    uint256 public tokensSold;
    
    //uint256 public heldTotal;//v3
    mapping (address => uint256) public purchasedTokens;//v3
    //mapping (address => uint) public heldTimeline;//v3
    
    /**
    struct Vester {
        uint vestingTokens; // weight is accumulated by delegation
        address thisPerson; // person delegated to
    }
    
    mapping(address => Vester) public vesters;
**/

    event Sold(address buyer, uint256 amount);
    event Contribution(address buyer, uint256 amount);
    //event ReleaseTokens(address buyer, uint256 amount); //v3
    
    // try this
    //event Purchase(string mystring, address buyer, uint256 amount);

    function TokenSaleSetup(IERC20Token _tokenContract, uint256 _price,uint256 _min_eth_amt,uint256 _max_eth_amt) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
        min_eth_amt=_min_eth_amt;
        max_eth_amt=_max_eth_amt;
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
        //require(msg.value == 100000000000000000);
        require(msg.value >= min_eth_amt);
        require(msg.value <= max_eth_amt);

        //emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount)); 
        //add some function here to assign tokens
        //Voter storage thisPerson = msg.sender;
        //Voter storage vestingTokens = scaledAmount;
        purchasedTokens[msg.sender] += scaledAmount; //v3
        
        
    }

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens back to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

        // Send Eth from contract to the owner.
        msg.sender.transfer(address(this).balance);
        
    }
}