pragma solidity ^0.4.18;

contract WineMarket{

    bool public initialized=false;
    address public ceoAddress;
    address public ceoWallet;

    uint256 public marketWine;

    mapping (address => uint256) public totalWineTransferredFromVineyard;
    mapping (address => uint256) public currentWineAmount;

    address constant public VINEYARD_ADDRESS = 0x66593d57B26Ed56Fd7881a016fcd0AF66636A9F0;
    VineyardInterface vineyardContract;

    function WineMarket(address _wallet) public{
        require(_wallet != address(0));
        ceoAddress = msg.sender;
        ceoWallet = _wallet;
        vineyardContract = VineyardInterface(VINEYARD_ADDRESS);
    }

    function transferWalletOwnership(address newWalletAddress) public {
      require(msg.sender == ceoAddress);
      require(newWalletAddress != address(0));
      ceoWallet = newWalletAddress;
    }

    modifier initializedMarket {
        require(initialized);
        _;
    }

    function transferWineFromVineyardCellar() initializedMarket public {
        require(vineyardContract.wineInCellar(msg.sender) > totalWineTransferredFromVineyard[msg.sender]);
        // More wine bottles have been produced from Vineyard. Transfer the difference here.
        uint256 wineToTransfer = SafeMath.sub(vineyardContract.wineInCellar(msg.sender),totalWineTransferredFromVineyard[msg.sender]);
        currentWineAmount[msg.sender] = SafeMath.add(currentWineAmount[msg.sender],wineToTransfer);
        totalWineTransferredFromVineyard[msg.sender] = SafeMath.add(totalWineTransferredFromVineyard[msg.sender],wineToTransfer);
    }

    function consumeWine(uint256 numBottlesToConsume) initializedMarket public returns(uint256) {
        require(currentWineAmount[msg.sender] > 0);
        require(numBottlesToConsume >= currentWineAmount[msg.sender]);

        // Once wine is consumed, it is gone forever
        currentWineAmount[msg.sender] = SafeMath.sub(currentWineAmount[msg.sender],numBottlesToConsume);

        // return amount consumed
        return numBottlesToConsume;
    }

    function sellWine(uint256 numBottlesToSell) initializedMarket public {
        require(numBottlesToSell > 0);

        uint256 myAvailableWine = currentWineAmount[msg.sender];
        uint256 adjustedNumBottlesToSell = numBottlesToSell;
        if (numBottlesToSell > myAvailableWine) {
          // don&#39;t allow sell larger than the owner actually has
          adjustedNumBottlesToSell = myAvailableWine;
        }
        if (adjustedNumBottlesToSell > marketWine) {
          // don&#39;t allow sell larger than the current market holdings
          adjustedNumBottlesToSell = marketWine;
        }

        uint256 wineValue = calculateWineSellSimple(adjustedNumBottlesToSell);
        uint256 fee = devFee(wineValue);
        currentWineAmount[msg.sender] = SafeMath.sub(myAvailableWine, adjustedNumBottlesToSell);
        marketWine = SafeMath.add(marketWine,adjustedNumBottlesToSell);
        ceoWallet.transfer(fee);
        msg.sender.transfer(SafeMath.sub(wineValue, fee));
    }

    function buyWine() initializedMarket public payable{
        require(msg.value <= SafeMath.sub(this.balance,msg.value));

        uint256 fee = devFee(msg.value);
        uint256 buyValue = SafeMath.sub(msg.value, fee);
        uint256 wineBought = calculateWineBuy(buyValue, SafeMath.sub(this.balance, buyValue));
        marketWine = SafeMath.sub(marketWine, wineBought);
        ceoWallet.transfer(fee);
        currentWineAmount[msg.sender] = SafeMath.add(currentWineAmount[msg.sender],wineBought);
    }

    function calculateTrade(uint256 valueIn, uint256 marketInv, uint256 Balance) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(Balance, 10000), SafeMath.add(SafeMath.div(SafeMath.add(SafeMath.mul(marketInv,10000), SafeMath.mul(valueIn, 5000)), valueIn), 5000));
    }

    function calculateWineSell(uint256 wine, uint256 marketWineValue) public view returns(uint256) {
        return calculateTrade(wine, marketWineValue, this.balance);
    }

    function calculateWineSellSimple(uint256 wine) public view returns(uint256) {
        return calculateTrade(wine, marketWine, this.balance);
    }

    function calculateWineBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketWine);
    }

    function calculateWineBuySimple(uint256 eth) public view returns(uint256) {
        return calculateWineBuy(eth,this.balance);
    }

    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3), 100);
    }

    function seedMarket(uint256 wineBottles) public payable{
        require(marketWine == 0);
        require(ceoAddress == msg.sender);
        initialized = true;
        marketWine = wineBottles;
    }

    function getBalance() public view returns(uint256) {
        return this.balance;
    }

    function getMyWine() public view returns(uint256) {
        return SafeMath.add(SafeMath.sub(vineyardContract.wineInCellar(msg.sender),totalWineTransferredFromVineyard[msg.sender]),currentWineAmount[msg.sender]);
    }

    function getMyTransferredWine() public view returns(uint256) {
        return totalWineTransferredFromVineyard[msg.sender];
    }

    function getMyAvailableWine() public view returns(uint256) {
        return currentWineAmount[msg.sender];
    }
}

contract VineyardInterface {
    function wineInCellar(address) public returns (uint256);
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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