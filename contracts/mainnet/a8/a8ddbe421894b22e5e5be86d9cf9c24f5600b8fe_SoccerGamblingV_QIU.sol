pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 //We have to specify what version of the compiler this code will use

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract QIUToken is StandardToken,Ownable {
    string public name = &#39;QIUToken&#39;;
    string public symbol = &#39;QIU&#39;;
    uint8 public decimals = 0;
    uint public INITIAL_SUPPLY = 5000000000;
    uint public eth2qiuRate = 10000;

    function() public payable { } // make this contract to receive ethers

    function QIUToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY / 10;
        balances[this] = INITIAL_SUPPLY - balances[owner];
    }

    function getOwner() public view returns (address) {
        return owner;
    }  
    
    /**
    * @dev Transfer tokens from one address to another, only owner can do this super-user operate
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function ownerTransferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(tx.origin == owner); // only the owner can call the method.
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

      /**
    * @dev transfer token for a specified address,but different from transfer is replace msg.sender with tx.origin
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function originTransfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[tx.origin]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[tx.origin] = balances[tx.origin].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(tx.origin, _to, _value);
        return true;
    }

    event ExchangeForETH(address fromAddr,address to,uint qiuAmount,uint ethAmount);
    function exchangeForETH(uint qiuAmount) public returns (bool){
        uint ethAmount = qiuAmount * 1000000000000000000 / eth2qiuRate; // only accept multiple of 100
        require(this.balance >= ethAmount);
        balances[this] = balances[this].add(qiuAmount);
        balances[msg.sender] = balances[msg.sender].sub(qiuAmount);
        msg.sender.transfer(ethAmount);
        ExchangeForETH(this,msg.sender,qiuAmount,ethAmount);
        return true;
    }

    event ExchangeForQIU(address fromAddr,address to,uint qiuAmount,uint ethAmount);
    function exchangeForQIU() payable public returns (bool){
        uint qiuAmount = msg.value * eth2qiuRate / 1000000000000000000;
        require(qiuAmount <= balances[this]);
        balances[this] = balances[this].sub(qiuAmount);
        balances[msg.sender] = balances[msg.sender].add(qiuAmount);
        ExchangeForQIU(this,msg.sender,qiuAmount,msg.value);
        return true;
    }

    /*
    // transfer out method
    function ownerETHCashout(address account) public onlyOwner {
        account.transfer(this.balance);
    }*/
    function getETHBalance() public view returns (uint) {
        return this.balance; // balance is "inherited" from the address type
    }
}

contract SoccerGamblingV_QIU is Ownable {

    using SafeMath for uint;

    struct BettingInfo {
        uint id;
        address bettingOwner;
        bool buyHome;
        bool buyAway;
        bool buyDraw;
        uint bettingAmount;
    }
    
    struct GamblingPartyInfo {
        uint id;
        address dealerAddress; // The address of the inital founder
        uint homePayRate;
        uint awayPayRate;
        uint drawPayRate;
        uint payRateScale;
        uint bonusPool; // count by wei
        uint baseBonusPool;
        int finalScoreHome;
        int finalScoreAway;
        bool isEnded;
        bool isLockedForBet;
        BettingInfo[] bettingsInfo;
    }

    mapping (uint => GamblingPartyInfo) public gamblingPartiesInfo;
    mapping (uint => uint[]) public matchId2PartyId;
    uint private _nextGamblingPartyId;
    uint private _nextBettingInfoId;
    QIUToken public _internalToken;

    uint private _commissionNumber;
    uint private _commissionScale;
    

    function SoccerGamblingV_QIU(QIUToken _tokenAddress) public {
        _nextGamblingPartyId = 0;
        _nextBettingInfoId = 0;
        _internalToken = _tokenAddress;
        _commissionNumber = 2;
        _commissionScale = 100;
    }

    function modifyCommission(uint number,uint scale) public onlyOwner returns(bool){
        _commissionNumber = number;
        _commissionScale = scale;
        return true;
    }

    function _availableBetting(uint gamblingPartyId,uint8 buySide,uint bettingAmount) private view returns(bool) {
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        uint losePay = 0;
        if (buySide==0)
            losePay = losePay.add((gpInfo.homePayRate.mul(bettingAmount)).div(gpInfo.payRateScale));
        else if (buySide==1)
            losePay = losePay.add((gpInfo.awayPayRate.mul(bettingAmount)).div(gpInfo.payRateScale));
        else if (buySide==2)
            losePay = losePay.add((gpInfo.drawPayRate.mul(bettingAmount)).div(gpInfo.payRateScale));
        uint mostPay = 0;
        for (uint idx = 0; idx<gpInfo.bettingsInfo.length; idx++) {
            BettingInfo storage bInfo = gpInfo.bettingsInfo[idx];
            if (bInfo.buyHome && (buySide==0))
                mostPay = mostPay.add((gpInfo.homePayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale));
            else if (bInfo.buyAway && (buySide==1))
                mostPay = mostPay.add((gpInfo.awayPayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale));
            else if (bInfo.buyDraw && (buySide==2))
                mostPay = mostPay.add((gpInfo.drawPayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale));
        }
        if (mostPay + losePay > gpInfo.bonusPool)
            return false;
        else 
            return true;
    }

    event NewBettingSucceed(address fromAddr,uint newBettingInfoId);
    function betting(uint gamblingPartyId,uint8 buySide,uint bettingAmount) public {
        require(bettingAmount > 0);
        require(_internalToken.balanceOf(msg.sender) >= bettingAmount);
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        require(gpInfo.isEnded == false);
        require(gpInfo.isLockedForBet == false);
        require(_availableBetting(gamblingPartyId, buySide, bettingAmount));
        BettingInfo memory bInfo;
        bInfo.id = _nextBettingInfoId;
        bInfo.bettingOwner = msg.sender;
        bInfo.buyHome = false;
        bInfo.buyAway = false;
        bInfo.buyDraw = false;
        bInfo.bettingAmount = bettingAmount;
        if (buySide == 0)
            bInfo.buyHome = true;
        if (buySide == 1)
            bInfo.buyAway = true;
        if (buySide == 2)
            bInfo.buyDraw = true;
        _internalToken.originTransfer(this,bettingAmount);
        gpInfo.bettingsInfo.push(bInfo);
        _nextBettingInfoId++;
        gpInfo.bonusPool = gpInfo.bonusPool.add(bettingAmount);
        NewBettingSucceed(msg.sender,bInfo.id);
    }

    function remainingBettingFor(uint gamblingPartyId) public view returns
        (uint remainingAmountHome,
         uint remainingAmountAway,
         uint remainingAmountDraw
        ) {
        for (uint8 buySide = 0;buySide<3;buySide++){
            GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
            uint bonusPool = gpInfo.bonusPool;
            for (uint idx = 0; idx<gpInfo.bettingsInfo.length; idx++) {
                BettingInfo storage bInfo = gpInfo.bettingsInfo[idx];
                if (bInfo.buyHome && (buySide==0))
                    bonusPool = bonusPool.sub((gpInfo.homePayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale));
                else if (bInfo.buyAway && (buySide==1))
                    bonusPool = bonusPool.sub((gpInfo.awayPayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale));
                else if (bInfo.buyDraw && (buySide==2))
                    bonusPool = bonusPool.sub((gpInfo.drawPayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale));
            }
            if (buySide == 0)
                remainingAmountHome = (bonusPool.mul(gpInfo.payRateScale)).div(gpInfo.homePayRate);
            else if (buySide == 1)
                remainingAmountAway = (bonusPool.mul(gpInfo.payRateScale)).div(gpInfo.awayPayRate);
            else if (buySide == 2)
                remainingAmountDraw = (bonusPool.mul(gpInfo.payRateScale)).div(gpInfo.drawPayRate);
        }
    }

    event MatchAllGPsLock(address fromAddr,uint matchId,bool isLocked);
    function lockUnlockMatchGPForBetting(uint matchId,bool lock) public {
        uint[] storage gamblingPartyIds = matchId2PartyId[matchId];
        for (uint idx = 0;idx < gamblingPartyIds.length;idx++) {
            lockUnlockGamblingPartyForBetting(gamblingPartyIds[idx],lock);
        }
        MatchAllGPsLock(msg.sender,matchId,lock);        
    }

    function lockUnlockGamblingPartyForBetting(uint gamblingPartyId,bool lock) public onlyOwner {
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        gpInfo.isLockedForBet = lock;
    }

    function getGamblingPartyInfo(uint gamblingPartyId) public view returns (uint gpId,
                                                                            address dealerAddress,
                                                                            uint homePayRate,
                                                                            uint awayPayRate,
                                                                            uint drawPayRate,
                                                                            uint payRateScale,
                                                                            uint bonusPool,
                                                                            int finalScoreHome,
                                                                            int finalScoreAway,
                                                                            bool isEnded) 
    {

        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        gpId = gpInfo.id;
        dealerAddress = gpInfo.dealerAddress; // The address of the inital founder
        homePayRate = gpInfo.homePayRate;
        awayPayRate = gpInfo.awayPayRate;
        drawPayRate = gpInfo.drawPayRate;
        payRateScale = gpInfo.payRateScale;
        bonusPool = gpInfo.bonusPool; // count by wei
        finalScoreHome = gpInfo.finalScoreHome;
        finalScoreAway = gpInfo.finalScoreAway;
        isEnded = gpInfo.isEnded;
    }

    //in this function, I removed the extra return value to fix the compiler exception caused by solidity limitation 
    //exception is: CompilerError: Stack too deep, try removing local variables.
    //to get the extra value for the gambingParty , need to invoke the method getGamblingPartyInfo
    function getGamblingPartySummarizeInfo(uint gamblingPartyId) public view returns(
        uint gpId,
        //uint salesAmount,
        uint homeSalesAmount,
        int  homeSalesEarnings,
        uint awaySalesAmount,
        int  awaySalesEarnings,
        uint drawSalesAmount,
        int  drawSalesEarnings,
        int  dealerEarnings,
        uint baseBonusPool
    ){
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        gpId = gpInfo.id;
        baseBonusPool = gpInfo.baseBonusPool;
        for (uint idx = 0; idx < gpInfo.bettingsInfo.length; idx++) {
            BettingInfo storage bInfo = gpInfo.bettingsInfo[idx];
            if (bInfo.buyHome){
                homeSalesAmount += bInfo.bettingAmount;
                if (gpInfo.isEnded && (gpInfo.finalScoreHome > gpInfo.finalScoreAway)){
                    homeSalesEarnings = homeSalesEarnings - int(bInfo.bettingAmount*gpInfo.homePayRate/gpInfo.payRateScale);
                }else
                    homeSalesEarnings += int(bInfo.bettingAmount);
            } else if (bInfo.buyAway){
                awaySalesAmount += bInfo.bettingAmount;
                if (gpInfo.isEnded && (gpInfo.finalScoreHome < gpInfo.finalScoreAway)){
                    awaySalesEarnings = awaySalesEarnings - int(bInfo.bettingAmount*gpInfo.awayPayRate/gpInfo.payRateScale);
                }else
                    awaySalesEarnings += int(bInfo.bettingAmount);
            } else if (bInfo.buyDraw){
                drawSalesAmount += bInfo.bettingAmount;
                if (gpInfo.isEnded && (gpInfo.finalScoreHome == gpInfo.finalScoreAway)){
                    drawSalesEarnings = drawSalesEarnings - int(bInfo.bettingAmount*gpInfo.drawPayRate/gpInfo.payRateScale);
                }else
                    drawSalesEarnings += int(bInfo.bettingAmount);
            }
        }
        int commission;    
        if(gpInfo.isEnded){
            dealerEarnings = int(gpInfo.bonusPool);
        }else{
            dealerEarnings = int(gpInfo.bonusPool);
            return;
        }
        if (homeSalesEarnings > 0){
            commission = homeSalesEarnings * int(_commissionNumber) / int(_commissionScale);
            homeSalesEarnings -= commission;
        }
        if (awaySalesEarnings > 0){
            commission = awaySalesEarnings * int(_commissionNumber) / int(_commissionScale);
            awaySalesEarnings -= commission;
        }
        if (drawSalesEarnings > 0){
            commission = drawSalesEarnings * int(_commissionNumber) / int(_commissionScale);
            drawSalesEarnings -= commission;
        }
        if (homeSalesEarnings < 0)
            dealerEarnings = int(gpInfo.bonusPool) + homeSalesEarnings;
        if (awaySalesEarnings < 0)
            dealerEarnings = int(gpInfo.bonusPool) + awaySalesEarnings;
        if (drawSalesEarnings < 0)
            dealerEarnings = int(gpInfo.bonusPool) + drawSalesEarnings;
        commission = dealerEarnings * int(_commissionNumber) / int(_commissionScale);
        dealerEarnings -= commission;
    }

    function getMatchSummarizeInfo(uint matchId) public view returns (
                                                            uint mSalesAmount,
                                                            uint mHomeSalesAmount,
                                                            uint mAwaySalesAmount,
                                                            uint mDrawSalesAmount,
                                                            int mDealerEarnings,
                                                            uint mBaseBonusPool
                                                        )
    {
        for (uint idx = 0; idx<matchId2PartyId[matchId].length; idx++) {
            uint gamblingPartyId = matchId2PartyId[matchId][idx];
            var (,homeSalesAmount,,awaySalesAmount,,drawSalesAmount,,dealerEarnings,baseBonusPool) = getGamblingPartySummarizeInfo(gamblingPartyId);
            mHomeSalesAmount += homeSalesAmount;
            mAwaySalesAmount += awaySalesAmount;
            mDrawSalesAmount += drawSalesAmount;
            mSalesAmount += homeSalesAmount + awaySalesAmount + drawSalesAmount;
            mDealerEarnings += dealerEarnings;
            mBaseBonusPool = baseBonusPool;
        }
    }

    function getSumOfGamblingPartiesBonusPool(uint matchId) public view returns (uint) {
        uint sum = 0;
        for (uint idx = 0; idx<matchId2PartyId[matchId].length; idx++) {
            uint gamblingPartyId = matchId2PartyId[matchId][idx];
            GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
            sum += gpInfo.bonusPool;
        }
        return sum;
    }

    function getWinLoseAmountByBettingOwnerInGamblingParty(uint gamblingPartyId,address bettingOwner) public view returns (int) {
        int winLose = 0;
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        require(gpInfo.isEnded);
        for (uint idx = 0; idx < gpInfo.bettingsInfo.length; idx++) {
            BettingInfo storage bInfo = gpInfo.bettingsInfo[idx];
            if (bInfo.bettingOwner == bettingOwner) {
                if ((gpInfo.finalScoreHome > gpInfo.finalScoreAway) && (bInfo.buyHome)) {
                    winLose += int(gpInfo.homePayRate * bInfo.bettingAmount / gpInfo.payRateScale);
                } else if ((gpInfo.finalScoreHome < gpInfo.finalScoreAway) && (bInfo.buyAway)) {
                    winLose += int(gpInfo.awayPayRate * bInfo.bettingAmount / gpInfo.payRateScale);
                } else if ((gpInfo.finalScoreHome == gpInfo.finalScoreAway) && (bInfo.buyDraw)) {
                    winLose += int(gpInfo.drawPayRate * bInfo.bettingAmount / gpInfo.payRateScale);
                } else {
                    winLose -= int(bInfo.bettingAmount);
                }
            }
        }   
        if (winLose > 0){
            int commission = winLose * int(_commissionNumber) / int(_commissionScale);
            winLose -= commission;
        }
        return winLose;
    }

    function getWinLoseAmountByBettingIdInGamblingParty(uint gamblingPartyId,uint bettingId) public view returns (int) {
        int winLose = 0;
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        require(gpInfo.isEnded);
        for (uint idx = 0; idx < gpInfo.bettingsInfo.length; idx++) {
            BettingInfo storage bInfo = gpInfo.bettingsInfo[idx];
            if (bInfo.id == bettingId) {
                if ((gpInfo.finalScoreHome > gpInfo.finalScoreAway) && (bInfo.buyHome)) {
                    winLose += int(gpInfo.homePayRate * bInfo.bettingAmount / gpInfo.payRateScale);
                } else if ((gpInfo.finalScoreHome < gpInfo.finalScoreAway) && (bInfo.buyAway)) {
                    winLose += int(gpInfo.awayPayRate * bInfo.bettingAmount / gpInfo.payRateScale);
                } else if ((gpInfo.finalScoreHome == gpInfo.finalScoreAway) && (bInfo.buyDraw)) {
                    winLose += int(gpInfo.drawPayRate * bInfo.bettingAmount / gpInfo.payRateScale);
                } else {
                    winLose -= int(bInfo.bettingAmount);
                }
                break;
            }
        }   
        if (winLose > 0){
            int commission = winLose * int(_commissionNumber) / int(_commissionScale);
            winLose -= commission;
        }
        return winLose;
    }

    event NewGamblingPartyFounded(address fromAddr,uint newGPId);
    function foundNewGamblingParty(
        uint matchId,
        uint homePayRate,
        uint awayPayRate,
        uint drawPayRate,
        uint payRateScale,
        uint basePool
        ) public
        {
        address sender = msg.sender;
        require(basePool > 0);
        require(_internalToken.balanceOf(sender) >= basePool);
        uint newId = _nextGamblingPartyId;
        gamblingPartiesInfo[newId].id = newId;
        gamblingPartiesInfo[newId].dealerAddress = sender;
        gamblingPartiesInfo[newId].homePayRate = homePayRate;
        gamblingPartiesInfo[newId].awayPayRate = awayPayRate;
        gamblingPartiesInfo[newId].drawPayRate = drawPayRate;
        gamblingPartiesInfo[newId].payRateScale = payRateScale;
        gamblingPartiesInfo[newId].bonusPool = basePool;
        gamblingPartiesInfo[newId].baseBonusPool = basePool;
        gamblingPartiesInfo[newId].finalScoreHome = -1;
        gamblingPartiesInfo[newId].finalScoreAway = -1;
        gamblingPartiesInfo[newId].isEnded = false;
        gamblingPartiesInfo[newId].isLockedForBet = false;
        _internalToken.originTransfer(this,basePool);
        matchId2PartyId[matchId].push(gamblingPartiesInfo[newId].id);
        _nextGamblingPartyId++;
        NewGamblingPartyFounded(sender,newId);//fire event
    }

    event MatchAllGPsEnded(address fromAddr,uint matchId);
    function endMatch(uint matchId,int homeScore,int awayScore) public {
        uint[] storage gamblingPartyIds = matchId2PartyId[matchId];
        for (uint idx = 0;idx < gamblingPartyIds.length;idx++) {
            endGamblingParty(gamblingPartyIds[idx],homeScore,awayScore);
        }
        MatchAllGPsEnded(msg.sender,matchId);        
    }

    event GamblingPartyEnded(address fromAddr,uint gamblingPartyId);
    function endGamblingParty(uint gamblingPartyId,int homeScore,int awayScore) public onlyOwner {
        GamblingPartyInfo storage gpInfo = gamblingPartiesInfo[gamblingPartyId];
        require(!gpInfo.isEnded);
        gpInfo.finalScoreHome = homeScore;
        gpInfo.finalScoreAway = awayScore;
        gpInfo.isEnded = true;
        int flag = -1;
        if (homeScore > awayScore)
            flag = 0;
        else if (homeScore < awayScore)
            flag = 1;
        else
            flag = 2;
        uint commission; // variable for commission caculation.
        uint bonusPool = gpInfo.bonusPool;
        for (uint idx = 0; idx < gpInfo.bettingsInfo.length; idx++) {
            BettingInfo storage bInfo = gpInfo.bettingsInfo[idx];
            uint transferAmount = 0;
            if (flag == 0 && bInfo.buyHome)
                transferAmount = (gpInfo.homePayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale);
            if (flag == 1 && bInfo.buyAway)
                transferAmount = (gpInfo.awayPayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale);
            if (flag == 2 && bInfo.buyDraw)
                transferAmount = (gpInfo.drawPayRate.mul(bInfo.bettingAmount)).div(gpInfo.payRateScale);
            if (transferAmount != 0) {
                bonusPool = bonusPool.sub(transferAmount);
                commission = (transferAmount.mul(_commissionNumber)).div(_commissionScale);
                transferAmount = transferAmount.sub(commission);
                _internalToken.ownerTransferFrom(this,bInfo.bettingOwner,transferAmount);
                _internalToken.ownerTransferFrom(this,owner,commission);
            }
        }    
        if (bonusPool > 0) {
            uint amount = bonusPool;
            // subs the commission
            commission = (amount.mul(_commissionNumber)).div(_commissionScale);
            amount = amount.sub(commission);
            _internalToken.ownerTransferFrom(this,gpInfo.dealerAddress,amount);
            _internalToken.ownerTransferFrom(this,owner,commission);
        }
        GamblingPartyEnded(msg.sender,gpInfo.id);
    }

    function getETHBalance() public view returns (uint) {
        return this.balance; // balance is "inherited" from the address type
    }
}