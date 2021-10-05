/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // Mainnet BNB/USD
        // priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // Testnet BNB/USD
    }


    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract GrameenIDO {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint priceOfBNB = priceConsumerV3.getThePrice();
    
    struct Buyer{
        bool buyStatus;
        uint totalTokensBought;
    }
    
    
    address private owner = msg.sender;
    address public buyTokenAddr = 0x8ae38126C680A4ebBa37FEC81f7372Eb326Daf83; // Mainnet
    address private contractAddr = address(this);
    uint private buyPrice;
    mapping(address => Buyer) public buyer;
    bool private saleStatus;
    uint private saleEndTime;
    BEP20 token = BEP20(buyTokenAddr);
    
    event Received(address, uint);
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    
    constructor() {
        buyPrice = 320;
        saleStatus = true;
    }
    
    /**
     * @dev Buy token 
     * 
     * Requirements:
     * saleStatus has to be true
     * cannot send zero value transaction
     */
    function buyToken() public payable returns(bool) {
        
        address sender = msg.sender;
        
        uint tokens = (msg.value * priceOfBNB / 100000) / buyPrice;
        
        require(saleStatus == true, "Sale not started or has finished");
        require(msg.value > 0, "Zero value");
        require(token.balanceOf(address(this)) >= tokens, "Insufficient contract balance");
        
        buyer[sender].totalTokensBought += tokens;
        buyer[sender].buyStatus = true;
        token.transfer(sender, tokens);
        
        emit TokensBought(sender, tokens);
        return true;
    }
    
    // Set buy price 
    // Upto 3 decimals
    function setBuyPrice(uint _price) public {
        require(msg.sender == owner, "Only owner");
        buyPrice = _price;
    }
    
    // View tokens for bnb
    function getTokens(uint bnbAmt) public view returns(uint tokens) {
        
        tokens = (bnbAmt * priceOfBNB / 100000) / buyPrice;
        return tokens;
    }
    
    // View tokens for busd
    function getTokensForBusd(uint busdAmount) public view returns(uint tokens) {
        
        tokens = busdAmount / buyPrice * 10000;
        return tokens;
    }
    
    // Buy tokens with BUSD
    function buyTokenWithBUSD(uint busdAmount) public returns (bool) {
        
        BEP20 busd = BEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD address mainnet
        // BEP20 busd = BEP20(0x14e83f967C52764F7F1402bc5d867836C092F7f9); // BUSD address testnet
        
        address sender = msg.sender;
        uint tokens = busdAmount / buyPrice * 1000;
        // uint time = block.timestamp;
                
        require(saleStatus == true, "Sale not started or has finished");
        require(token.balanceOf(address(this)) >= tokens, "Insufficient contract balance");
        
        busd.transferFrom(sender, contractAddr, busdAmount);
        
        buyer[sender].totalTokensBought += tokens;
        buyer[sender].buyStatus = true;
        token.transfer(sender, tokens);
        
        emit TokensBought(sender, tokens);
        return true;
    }
    
    /** 
     * @dev Set sale status
     * 
     * Only to temporarily pause sale if necessary
     * Otherwise use 'endSale' function to end sale
     */
    function setSaleStatus(bool status) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        saleStatus = status;
        return true;
    }
    
    /** 
     * @dev End presale 
     * 
     * Requirements:
     * 
     * Only owner can call this function
     */
    function endSale() public returns (bool) {
        require(msg.sender == owner, "Only owner");
        saleStatus = false;
        saleEndTime = block.timestamp;
        return true;
    }
    
    /// Set claim token address
    function setClaimTokenAddress(address addr) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        buyTokenAddr
        = addr;
        return true;
    }
    
    /// View owner address
    function getOwner() public view returns(address){
        return owner;
    }
    
    /// View sale end time
    function viewSaleEndTime() public view returns(uint) {
        return saleEndTime;
    }
    
    /// View Buy Price
    function viewPrice() public view returns(uint){
        return buyPrice;
    }
    
    /// Return bought status of user
    function userBuyStatus(address user) public view returns (bool) {
        return buyer[user].buyStatus;
    }
    
    /// Return sale status
    function showSaleStatus() public view returns (bool) {
        return saleStatus;
    }
    
    /// Show USD Price of BNB
    function usdPrice(uint amount) external view returns(uint) {
        uint bnbAmt = amount * priceOfBNB;
        return bnbAmt/100000000;
    }
    
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 _token = BEP20(tokenAddress);
        _token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}