pragma solidity ^0.4.18;


contract CryptoStrippers{

    uint256 public COINS_TO_HATCH_1STRIPPERS = 86400;
    uint256 public STARTING_STRIPPERS = 500;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = true;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryStrippers;
    mapping (address => uint256) public claimedCoins;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketCoins;


    function CryptoStrippers() public{
        ceoAddress = msg.sender;
    }

    /**
    * @dev hatchCoins produce coins
    */
    function hatchCoins(address ref) public{
        require(initialized);
        if(referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender){
            referrals[msg.sender] = ref;
        }
        uint256 coinsUsed = getMyCoins();
        uint256 newStrippers = SafeMath.div(coinsUsed,COINS_TO_HATCH_1STRIPPERS);
        hatcheryStrippers[msg.sender] = SafeMath.add(hatcheryStrippers[msg.sender],newStrippers);
        claimedCoins[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        claimedCoins[referrals[msg.sender]] = SafeMath.add(claimedCoins[referrals[msg.sender]],SafeMath.div(coinsUsed,5));
        marketCoins = SafeMath.add(marketCoins,SafeMath.div(coinsUsed,10));
    }

    function sellCoins() public{
        require(initialized);
        uint256 hasCoins = getMyCoins();
        uint256 coinValue = calculateCoinSell(hasCoins);
        uint256 fee = devFee(coinValue);
        claimedCoins[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketCoins = SafeMath.add(marketCoins,hasCoins);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(coinValue,fee));
    }

    function buyCoins() public payable{
        require(initialized);
        uint256 coinsBought = calculateCoinBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        coinsBought = SafeMath.sub(coinsBought,devFee(coinsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedCoins[msg.sender] = SafeMath.add(claimedCoins[msg.sender],coinsBought);
    }

    /**
    * @dev Computational cost
    */
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateCoinSell(uint256 coins) public view returns(uint256){
        return calculateTrade(coins,marketCoins,this.balance);
    }

    function calculateCoinBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketCoins);
    }

    function calculateCoinBuySimple(uint256 eth) public view returns(uint256){
        return calculateCoinBuy(eth,this.balance);
    }

    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }

    function seedMarket(uint256 coins) public payable{
        require(marketCoins==0);
        initialized=true;
        marketCoins=coins;
    }

    function getFreeStrippers() public{
        require(initialized);
        require(hatcheryStrippers[msg.sender]==0);
        lastHatch[msg.sender]=now;
        hatcheryStrippers[msg.sender]=STARTING_STRIPPERS;
    }

    function getBalance() public view returns(uint256){
        return this.balance;
    }

    function getMyStrippers() public view returns(uint256){
        return hatcheryStrippers[msg.sender];
    }

    function getMyCoins() public view returns(uint256){
        return SafeMath.add(claimedCoins[msg.sender],getCoinsSinceLastHatch(msg.sender));
    }

    function getCoinsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(COINS_TO_HATCH_1STRIPPERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryStrippers[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

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
    uint256 c = a / b;
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
}