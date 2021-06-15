/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

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



library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
   function percent(uint a, uint b) internal pure returns (uint) {
    return b * a / 100;
  }
}

contract Ownable{
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    
    constructor() public{
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        emit OwnershipTransferred(owner,newOwner);
        owner = newOwner;
    }
}




contract FoilSeedContribution is Ownable{
    
    using SafeMath for uint256;
 
    
    
    // Exchange rates
    
    uint256 public constant PRICE_RATE = 50000;
    
    // Address that storing all ether
    address payable foilWallet;
    
    //Due to an emergency,set this to true to halt the contribution
    bool public halted;
    
    uint256 public finalizedTime; 
    uint256 public openSoldTokens;
    
    // ERC20  Foil token contract instance
    IERC20 public foilToken;
    
    // USDT instance
    IERC20 public usdt;
    
    
    mapping(address => uint256) private cliamedTokens;
    mapping(address => uint256) public openWhiteListedTokens;
    mapping(address => WhitelistUser) private whitelisted;
    address[] private whitelistedIndex;

    
    struct WhitelistUser {
        uint256 quota;
        uint256 index;
    }
    
    uint256 public maxBuyLimit = 50 ether;
    
    modifier notHalted(){
        require(!halted);
        _;
    }
    
    modifier initialized() {
        require(address(foilWallet) != address(0));
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

    
    
    
    constructor(address _foilTokenAddress,address payable _foilWallet) public{
        require(_foilWallet != address(0));
        foilToken = IERC20(_foilTokenAddress);
        foilWallet = _foilWallet;
        // usdt = IERC20(_usdt);
        
    }
    
    
    function getSeedSupply() public view returns(uint256){
        return foilToken.balanceOf(address(this));
    }
    
    
    function finalize() public onlyOwner{
        finalizedTime = now;
    }
    
        
    function setMaxBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
    {
        maxBuyLimit = limit;
    }
    
     /// @dev batch set quota for early user quota
    function addWhiteListUsers(address[] memory userAddresses, uint256[] memory quota)
        public
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
    }

    /**
     * Fallback function 
     * 
     * @dev Set it to buy Token if anyone send ETH
     */
    
    receive () external payable{
        buyFoilToken(msg.sender);
    }
    
    
    function claimTokens(address receipient)
        public
        isSaleEnded
    {
        
            uint256 pendingToken = getPendingToken(receipient);
            foilToken.balanceOf(address(this)).sub(pendingToken);
            foilToken.balanceOf(receipient).add(pendingToken);
            foilToken.transfer(receipient,pendingToken);
        
    }
    
    
     function getPendingToken(address _userAddress) internal view returns(uint256){
         
         require(openSoldTokens >0 ,"Can't be zero amount.");
         uint256 canExtract=0;
         if(getTime() <= finalizedTime.add(months(2))){
             require(openSoldTokens < getSeedSupply().percent(20));
             canExtract = openWhiteListedTokens[_userAddress].percent(20);
         }
           else if(getTime() > finalizedTime.add(months(2)) && getTime() <= finalizedTime.add(months(3))){
              require(openSoldTokens < getSeedSupply().percent(30));
              canExtract = openWhiteListedTokens[_userAddress].percent(30);

        } 
         else if(getTime() > finalizedTime.add(months(3)) && getTime() <= finalizedTime.add(months(4))){
              require(openSoldTokens < getSeedSupply().percent(40));
              canExtract = openWhiteListedTokens[_userAddress].percent(40);
        } 
        else if(getTime() > finalizedTime.add(months(4)) && getTime() <= finalizedTime.add(months(5))){
              require(openSoldTokens < getSeedSupply().percent(50));
              canExtract = openWhiteListedTokens[_userAddress].percent(50);
        } 
        else if(getTime() > finalizedTime.add(months(5)) && getTime() <= finalizedTime.add(months(6))){
              require(openSoldTokens < getSeedSupply().percent(60));
              canExtract = openWhiteListedTokens[_userAddress].percent(60);
        }
        else if(getTime() > finalizedTime.add(months(6)) && getTime() <= finalizedTime.add(months(7))){
              require(openSoldTokens < getSeedSupply().percent(70));
             canExtract = openWhiteListedTokens[_userAddress].percent(70);
        } 
        else if(getTime() > finalizedTime.add(months(7)) && getTime() <= finalizedTime.add(months(8))){
              require(openSoldTokens < getSeedSupply().percent(80));
             canExtract = openWhiteListedTokens[_userAddress].percent(80);
        }
        else if(getTime() > finalizedTime.add(months(8)) && getTime() <= finalizedTime.add(months(9))){
              require(openSoldTokens < getSeedSupply().percent(90));
             canExtract = openWhiteListedTokens[_userAddress].percent(90);
        } 
        else{
             require(openSoldTokens < getSeedSupply());
             canExtract = openWhiteListedTokens[_userAddress];
        }
        return canExtract;

    }
    
    
    function getTime() public view returns(uint256){
        return now;
    }
    
    function months(uint256 m) internal pure returns(uint256){
        return m.mul(30 days);
    }
  
    
    
    function buyFoilToken(address receipient) public payable  initialized ceilingNotReached returns(bool){
        require(receipient != address(0));
        require(isWhitelisted(receipient));
        require(tx.gasprice <= 99000000000 wei);
        
        buyToken(receipient);
        
        
    }
    
    // Get a user's whitelisted amount
    
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
    
    function buyToken(address receipient) internal {
        uint256 tokenAvailable = getSeedSupply().sub(openSoldTokens);
        require(tokenAvailable > 0 );
        uint256 vaildFund = whitelisted[receipient].quota;
        require(vaildFund > 0,"You already had tokens.");
        
        uint256 toFund;
        uint256 toCollect;
        
        (toFund,toCollect) = costAndBuyTokens(tokenAvailable,vaildFund);
        buyCommon(receipient,toFund,toCollect);
        
    }
    
    
     function costAndBuyTokens(uint256 availableToken, uint256 validFund)  internal pure returns (uint256 costValue, uint256 getTokens){
        // all conditions has checked in the caller functions
        getTokens = PRICE_RATE * validFund;
        if(availableToken >= getTokens){
            costValue = validFund;
        } else {
            costValue = availableToken / PRICE_RATE;
            getTokens = availableToken;
        }
    }
    
    
    function buyCommon(address receipient,uint256 toFund,uint256 foilTokenCollect) internal {
            require(toFund > 0);
            openWhiteListedTokens[receipient] = openWhiteListedTokens[receipient].add(foilTokenCollect);
            foilWallet.transfer(toFund);
           
            // receiving usdt
            // usdt.transfer(foilWallet, toFund);
            openSoldTokens = openSoldTokens.add(foilTokenCollect);
    }
    
    
    
}