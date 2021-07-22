/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Lockup {


    address payable foilWallet;
    mapping(address => mapping(uint => uint256)) public deposites;
    
    // USDT instance
    IERC20 public usdt;
    
    //event 
    event Deposit(address userAddress,uint indexed side,uint256 amount);
    event Withdraw(uint256 amountAfterPercent);
    
    constructor(address payable _foilWallet,address _usdt) {
        require(_foilWallet != address(0),"The wallet address can not zero.");
        require(_usdt != address(0),"The USDT address can not zero.");
        foilWallet = _foilWallet;
        usdt = IERC20(_usdt);
    }
    
    
    function deposit(uint256 amount,uint side) payable external returns(bool){
        require(msg.value == amount);
        unchecked{
              deposites[msg.sender][side] = deposites[msg.sender][side] + (amount);
        }
        
        emit Deposit(msg.sender,side,amount);
      
        return true;
    }
    
    receive() external payable{
        
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function withdraw(uint256 percentage,uint side) external {
      
        uint256 amount = deposites[msg.sender][side];
        require(amount > 0 ,"Can not withdraw");
        uint256 amountAfterPercent ;
        unchecked{
              amountAfterPercent = amount * percentage / 1e4;
        }
       
        if(side == 1){
             usdt.transfer(foilWallet, amountAfterPercent);
                
        }
        else{
             foilWallet.transfer(amountAfterPercent);
        }
        
        emit Withdraw(amountAfterPercent);
       
    }
}

contract Ownable{
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner{
        require(newOwner != address(0));
        emit OwnershipTransferred(owner,newOwner);
        owner = newOwner;
    }
}


contract FoilSeedContract is Ownable{
    
    enum Side{
        ETH,
        USDT
    }
    
    // Exchange rates
    
    uint256 public constant PRICE_RATE = 50000;
    uint256 public constant PRICE_RATE_USDT = 20;
    uint256 public constant MONTH = 30 days;
    
    
    //Due to an emergency,set this to true to halt the contribution
    bool constant public halted = false;
    
    uint256 public finalizedTime; 
    uint256 public openSoldTokens;
    
    // ERC20  Foil token contract instance
    IERC20 public foilToken;
    
    // Lock up contract 
    Lockup public lockUp;

    mapping(address => uint256) public openWhiteListedTokens;
    mapping(address => WhitelistUser) private whitelisted;
    address[] private whitelistedIndex;
    
    // events 
    event ClaimTokens(address receipient,uint256 pendingToken,uint256 pendingPercentage);
    event Finalize(uint256 finalizedTime);
    event WhiteList(address userAddress,uint256 quota);
    event MaxBuyLimt(uint256 limit);
    event BuyFoilToken(address receipient,Side side);
    
    struct WhitelistUser {
        uint256 quota;
        uint256 index;
    }
    
    uint256 public maxBuyLimit = 50 ether;
    
    modifier notHalted(){
        require(!halted);
        _;
    }
    
   
    modifier ceilingNotReached(){
        require(openSoldTokens < getSeedSupply());
        _;
    }
    
    modifier isSaleEnded() {
        require(openSoldTokens >= getSeedSupply());
        _;
    }

    
    
    
    constructor(address _foilTokenAddress,Lockup _lockUp) {
        require(_foilTokenAddress != address(0),"The token address can not be zero");
        foilToken = IERC20(_foilTokenAddress);
        lockUp = _lockUp;
        
    }
    
    
    function getSeedSupply() public view returns(uint256){
        return foilToken.balanceOf(address(this));
    }
    
    
    function finalize() external onlyOwner{
        finalizedTime = block.number;
        
        emit Finalize(finalizedTime);
    }
    
        
    function setMaxBuyLimit(uint256 limit)
        external
        
        onlyOwner
    {
        maxBuyLimit = limit;
        emit MaxBuyLimt(limit);
    }
    
     /// @dev batch set quota for early user quota
    function addWhiteListUsers(address[] memory userAddresses, uint256[] memory quota)
        external
        onlyOwner
    {
        for( uint i = 0; i < userAddresses.length; i++) {
            addWhiteListUser(userAddresses[i], quota[i]);
        }
    }
    
    
    function addWhiteListUser(address userAddress, uint256 quota)
        public
        onlyOwner
    {
        
        if (!isWhitelisted(userAddress)) {
            whitelisted[userAddress].quota = quota;
            whitelistedIndex.push(userAddress);
            whitelisted[userAddress].index = whitelistedIndex.length - 1;
        }
        
        emit WhiteList(userAddress,quota);
    }

    /**
     * Fallback function 
     * 
     * @dev Set it to buy Token if anyone send ETH
     */
    
    // receive () external payable{
    //     // buyFoilToken(msg.sender);
    // }
    
    
    function claimTokens(address receipient,Side side)
        external
        isSaleEnded
    {
            uint256 pendingToken;
            uint256 pendingPercentage;
            (pendingToken,pendingPercentage) = getPendingToken(receipient);
            unchecked{
                 foilToken.balanceOf(address(this)) - pendingToken;
                 foilToken.balanceOf(receipient) + pendingToken;
            }
           
            foilToken.transfer(receipient,pendingToken);
            if(side == Side.USDT){
                 lockUp.withdraw(pendingPercentage,1);
            }
            else{
                 lockUp.withdraw(pendingPercentage,0);
            }
           
           emit ClaimTokens(receipient,pendingToken,pendingPercentage);
    }
    
    function getCurrentToken(uint256 supply,uint256 percent) internal pure returns(uint256){
        return supply * percent / 100;
    }
    
     function getPendingToken(address _userAddress) public view returns(uint256 canExtract,uint256 percentage){
         
         require(openSoldTokens >0 ,"Can't be zero amount.");
         canExtract=0;
         percentage =0;
         if(getTime() <= finalizedTime + months(2)){
             require(openSoldTokens < getCurrentToken(getSeedSupply(),20));
             canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],20);
             percentage = 2000;
         }
           else if(getTime() > (finalizedTime + months(2)) && getTime() <= (finalizedTime + months(3))){
              require(openSoldTokens < getCurrentToken(getSeedSupply(),30));
              canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],30);
              percentage = 1000;
        } 
         else if(getTime() > (finalizedTime + months(3)) && getTime() <= (finalizedTime + months(4))){
              require(openSoldTokens < getCurrentToken(getSeedSupply(),40));
              canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],40);
              percentage = 1000;
        } 
        else if(getTime() > (finalizedTime + months(4)) && getTime() <= (finalizedTime + months(5))){
                require(openSoldTokens < getCurrentToken(getSeedSupply(),50));
                canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],50);
                percentage = 1000;
        } 
        else if(getTime() > (finalizedTime + months(5)) && getTime() <= (finalizedTime + months(6))){
                require(openSoldTokens < getCurrentToken(getSeedSupply(),60));
                canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],60);
                percentage = 1000;
        }
        else if(getTime() > (finalizedTime + months(6)) && getTime() <= (finalizedTime + months(7))){
             require(openSoldTokens < getCurrentToken(getSeedSupply(),70));
                canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],70);
                percentage = 1000;
        } 
        else if(getTime() > (finalizedTime + months(7)) && getTime() <= (finalizedTime + months(8))){
              require(openSoldTokens < getCurrentToken(getSeedSupply(),80));
                canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],80);
                percentage = 1000;
        }
        else if(getTime() > (finalizedTime + months(8)) && getTime() <= (finalizedTime + months(9))){
              require(openSoldTokens < getCurrentToken(getSeedSupply(),90));
                canExtract = getCurrentToken(openWhiteListedTokens[_userAddress],90);
                percentage = 1000;
        } 
        else{
             require(openSoldTokens < getSeedSupply());
             canExtract = openWhiteListedTokens[_userAddress];
              percentage = 1000;
        }
      

    }
    
    function getTime() public view returns(uint256){
        return block.number;
    }
    
    function months(uint256 m) internal pure returns(uint256){
        return m * MONTH;
    }
  
    function buyFoilToken(address receipient,Side side) external ceilingNotReached {
      
        require(receipient != address(0));
        require(isWhitelisted(receipient));
       
        require(tx.gasprice <= 99000000000 wei);
        buyToken(receipient,side);
        
        emit BuyFoilToken(receipient,side);
        
        
    }
    
    function getWhitelistedAmount(address userAddress) public view returns(uint256){
        if (isWhitelisted(userAddress)){
            uint256 amount = whitelisted[userAddress].quota;
            return amount;
        }
        return 0;
    }
    
    
    // Get a user's whitelisted state
    
    function isWhitelisted(address userAddress) public view returns(bool isIndeed){
        if(whitelistedIndex.length == 0) return false;
        return (whitelistedIndex[whitelisted[userAddress].index] == userAddress);
    }
    
    function buyToken(address receipient,Side side) internal {
        uint256 tokenAvailable = getSeedSupply() - openSoldTokens;
        require(tokenAvailable > 0 );
        uint256 vaildFund = whitelisted[receipient].quota;
        require(vaildFund > 0,"You already had tokens.");
        
        uint256 toFund;
        uint256 toCollect;
        
        (toFund,toCollect) = costAndBuyTokens(tokenAvailable,vaildFund,side);
        buyCommon(receipient,toFund,toCollect,side);
        
    }
    
    
     function costAndBuyTokens(uint256 availableToken, uint256 validFund,Side side)  internal pure returns (uint256 costValue, uint256 getTokens){
        // all conditions has checked in the caller functions
        if(side == Side.USDT){
            getTokens = PRICE_RATE_USDT * validFund;
        } else{
            getTokens = PRICE_RATE * validFund;
        }
       
        if(availableToken >= getTokens){
            costValue = validFund;
        } else {
            if(side == Side.USDT){
                 costValue = availableToken / PRICE_RATE_USDT;
            }
            else{
                 costValue = availableToken / PRICE_RATE;
            }
           
            getTokens = availableToken;
        }
    }
    
    
    function buyCommon(address receipient,uint256 toFund,uint256 foilTokenCollect,Side side) internal {
            require(toFund > 0,"The amount can not zero.");
            unchecked{
                openWhiteListedTokens[receipient] = openWhiteListedTokens[receipient] + foilTokenCollect;
            }
         
            // lockupAddress.transfer(toFund);
            if(side == Side.USDT){
                 lockUp.deposit(toFund,1);
            }else{
                 lockUp.deposit(toFund,0);
            }
           
            unchecked{
                  openSoldTokens = openSoldTokens + foilTokenCollect;
            }
          
    }
        
}