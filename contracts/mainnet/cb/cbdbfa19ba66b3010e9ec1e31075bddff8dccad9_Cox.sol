pragma solidity ^0.4.17;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
}


library TableLib {
    using SafeMath for uint256;

    struct TableValue {
      bool exists;
      uint256 value;
    }

    struct Table {
        mapping (address => TableValue) tableMapping;
        address[] addressList;
    }

    function getNum(Table storage tbl, address adrs) internal view returns (uint256 num) {
      return tbl.tableMapping[adrs].value;
    }

    function add(Table storage tbl, address adrs, uint256 num) internal {
        if (!tbl.tableMapping[adrs].exists) {
          tbl.addressList.push(adrs);
          tbl.tableMapping[adrs].exists = true;
        }
        tbl.tableMapping[adrs].value = tbl.tableMapping[adrs].value.add(num);
    }

    function getValues(Table storage tbl, uint256 page) internal view
    returns (uint256 count, address[] addressList, uint256[] numList) {
      count = tbl.addressList.length;
      uint256 maxPageSize = 50;
      uint256 index = 0;
      uint256 pageSize = maxPageSize;
      if ( page*maxPageSize > count ) {
        pageSize = count - (page-1)*maxPageSize;
      }
      addressList = new address[](pageSize);
      numList = new uint256[](pageSize);
      for (uint256 i = (page - 1) * maxPageSize; i < count && index < pageSize; i++) {
        address adrs = tbl.addressList[i];
        addressList[index] = adrs;
        numList[index] = tbl.tableMapping[adrs].value;
        index++;
      }
    }
}


library HolderLib {
    using SafeMath for uint256;

    struct HolderValue {
      uint256 value;
      uint256[] relatedRoundIds;
      uint256 fromIndex;
      string refCode;
    }

    struct Holder {
        mapping (address => HolderValue) holderMap;
    }

    function getNum(Holder storage holder, address adrs) internal view returns (uint256 num) {
        return holder.holderMap[adrs].value;
    }

    function setRefCode(Holder storage holder, address adrs, string refCode) internal {
        holder.holderMap[adrs].refCode = refCode;
    }

    function getRefCode(Holder storage holder, address adrs) internal view returns (string refCode) {
        return holder.holderMap[adrs].refCode;
    }

    function add(Holder storage holder, address adrs, uint256 num) internal {
        holder.holderMap[adrs].value = holder.holderMap[adrs].value.add(num);
    }

    function sub(Holder storage holder, address adrs, uint256 num) internal {
        holder.holderMap[adrs].value = holder.holderMap[adrs].value.sub(num);
    }

    function setNum(Holder storage holder, address adrs, uint256 num) internal {
        holder.holderMap[adrs].value = num;
    }

    function addRelatedRoundId(Holder storage holder, address adrs, uint256 roundId) internal {
        uint256[] storage ids = holder.holderMap[adrs].relatedRoundIds;
        if (ids.length > 0 && ids[ids.length - 1] == roundId) {
          return;
        }
        ids.push(roundId);
    }

    function removeRelatedRoundId(Holder storage holder, address adrs, uint256 roundId) internal {
        HolderValue storage value = holder.holderMap[adrs];
        require(value.relatedRoundIds[value.fromIndex] == roundId, &#39;only the fromIndex element can be removed&#39;);
        value.fromIndex++;
    }
}

library RoundLib {
    using SafeMath for uint256;
    using HolderLib for HolderLib.Holder;
    using TableLib for TableLib.Table;

    event Log(string str, uint256 v1, uint256 v2, uint256 v3);

    uint256 constant private roundSizeIncreasePercent = 160;

    struct Round {
        uint256 roundId;
        uint256 roundNum;
        uint256 max;
        TableLib.Table investers;
        uint256 raised;
        uint256 pot;
        address addressOfMaxInvestment;
    }

    function getInitRound(uint256 initSize) internal pure returns (Round) {
        TableLib.Table memory investers;
        return Round({
            roundId: 1,
            roundNum: 1,
            max: initSize,
            investers: investers,
            raised: 0,
            pot: 0,
            addressOfMaxInvestment: 0
        });
    }

    function getNextRound(Round storage round, uint256 initSize) internal view returns (Round) {
        TableLib.Table memory investers;
        bool isFinished = round.max == round.raised;
        return Round({
            roundId: round.roundId + 1,
            roundNum: isFinished ? round.roundNum + 1 : 1,
            max: isFinished ? round.max * roundSizeIncreasePercent / 100 : initSize,
            investers: investers,
            raised: 0,
            pot: 0,
            addressOfMaxInvestment: 0
        });
    }

    function add (Round storage round, address adrs, uint256 amount) internal
    returns (bool isFinished, uint256 amountUsed) {
        if (round.raised + amount >= round.max) {
            isFinished = true;
            amountUsed = round.max - round.raised;
        } else {
            isFinished = false;
            amountUsed = amount;
        }
        round.investers.add(adrs, amountUsed);
        if (round.addressOfMaxInvestment == 0 || getNum(round, adrs) > getNum(round, round.addressOfMaxInvestment)) {
            round.addressOfMaxInvestment = adrs;
        }
        round.raised = round.raised.add(amountUsed);
    }

    function getNum(Round storage round, address adrs) internal view returns (uint256) {
        return round.investers.getNum(adrs);
    }

    function getBalance(Round storage round, address adrs)
    internal view returns (uint256) {
        uint256 balance = round.investers.getNum(adrs);
        if (balance == 0) {
          return balance;
        }
        return balance * round.pot / round.raised;
    }

    function moveToHolder(Round storage round, address adrs, HolderLib.Holder storage coinHolders) internal {
        if (round.pot == 0) {
          return;
        }
        uint256 amount = getBalance(round, adrs);
        if (amount > 0) {
            coinHolders.add(adrs, amount);
            coinHolders.removeRelatedRoundId(adrs, round.roundId);
        }
    }

    function getInvestList(Round storage round, uint256 page) internal view
    returns (uint256 count, address[] addressList, uint256[] numList) {
        return round.investers.getValues(page);
    }
}

library DealerLib {
    using SafeMath for uint256;

    struct DealerInfo {
        address addr;
        uint256 amount;
        uint256 rate; // can not more than 300
    }

    struct Dealers {
        mapping (string => DealerInfo) dealerMap;
        mapping (address => string) addressToCodeMap;
    }

    function query(Dealers storage dealers, string code) internal view returns (DealerInfo storage) {
        return dealers.dealerMap[code];
    }

    function queryCodeByAddress(Dealers storage dealers, address adrs) internal view returns (string code) {
        return dealers.addressToCodeMap[adrs];
    }

    function dealerExisted(Dealers storage dealers, string code) internal view returns (bool value) {
        return dealers.dealerMap[code].addr != 0x0;
    }

    function insert(Dealers storage dealers, string code, address addr, uint256 rate) internal {
        require(!dealerExisted(dealers, code), "code existed");
        require(bytes(queryCodeByAddress(dealers, addr)).length == 0, "address existed in dealers");
        setDealer(dealers, code, addr, rate);
    }

    function update(Dealers storage dealers, string code, address addr, uint256 rate) internal {
        address oldAddr = dealers.dealerMap[code].addr;

        require(oldAddr != 0x0, "code not exist");
        require(bytes(queryCodeByAddress(dealers, addr)).length == 0, "address existed in dealers");

        delete dealers.addressToCodeMap[oldAddr];
        setDealer(dealers, code, addr, rate);
    }

    function setDealer(Dealers storage dealers, string code, address addr, uint256 rate) private {
        require(addr != 0x0, "invalid address");
        require(rate <= 300, "invalid rate");
        dealers.addressToCodeMap[addr] = code;
        dealers.dealerMap[code].addr = addr;
        dealers.dealerMap[code].rate = rate;
    }

    function addAmount(Dealers storage dealers, string code, uint256 amountUsed) internal
    returns (uint256 amountToDealer) {
        require(amountUsed > 0, "amount must be greater than 0");
        require(dealerExisted(dealers, code), "code not exist");
        amountToDealer = amountUsed * dealers.dealerMap[code].rate / 10000;
        dealers.dealerMap[code].amount = dealers.dealerMap[code].amount.add(amountToDealer);
    }
}


contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Cox is Ownable {
    using SafeMath for uint256;
    using HolderLib for HolderLib.Holder;
    using RoundLib for RoundLib.Round;
    using DealerLib for DealerLib.Dealers;

    event RoundIn(address addr, uint256 amt, uint256 currentRoundRaised, uint256 round, uint256 bigRound, string refCode);
    event Log(string str, uint256 value);
    event PoolAdd(uint256 value);
    event PoolSub(uint256 value);

    uint256 private roundDuration = 1 days;
    uint256 private initSize = 10 ether;       // fund of first round
    uint256 private minRecharge = 0.01 ether;  // minimum of invest amount
    bool private mIsActive = false;
    bool private isAutoRestart = true;
    uint256 private rate = 300;                // 300 of ten thousand
    string private defaultRefCode = "owner";

    DealerLib.Dealers private dealers;    // dealer information
    HolderLib.Holder private coinHolders; // all investers information
    RoundLib.Round[] private roundList;

    uint256 private fundPoolSize;
    uint256 private roundStartTime;
    uint256 private roundEndTime;
    uint256 private bigRound = 1;
    uint256 private totalAmountInvested = 0;

    constructor() public {
        roundList.push(RoundLib.getInitRound(initSize));
        dealers.insert(defaultRefCode, msg.sender, 100);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        Ownable.transferOwnership(_newOwner);
        dealers.update(defaultRefCode, _newOwner, 100);
    }

    function poolAdd(uint256 value) private {
      fundPoolSize = fundPoolSize.add(value);
      emit PoolAdd(value);
    }

    function poolSub(uint256 value) private {
      fundPoolSize = fundPoolSize.sub(value);
      emit PoolSub(value);
    }

    modifier isActive() {
        require(mIsActive == true, "it&#39;s not ready yet.");
        require(now >= roundStartTime, "it&#39;s not started yet.");
        _;
    }

    modifier callFromHuman(address addr) {
        uint size;
        assembly {size := extcodesize(addr)}
        require(size == 0, "not human");
        _;
    }

    // deposit
    function recharge(string code) public isActive callFromHuman(msg.sender) payable {
        require(msg.value >= minRecharge, "not enough fund");

        string memory _code = coinHolders.getRefCode(msg.sender);
        if (bytes(_code).length > 0) {
            code = _code;
        } else {
            if (!dealers.dealerExisted(code)) {
                code = defaultRefCode;
            }
            coinHolders.setRefCode(msg.sender, code);
        }

        coinHolders.add(msg.sender, msg.value);
        roundIn(msg.value, code);
    }

    function moveRoundsToHolder(address adrs) internal {
      HolderLib.HolderValue storage holderValue = coinHolders.holderMap[adrs];
      uint256[] memory roundIds = holderValue.relatedRoundIds;
      uint256 roundId;

      for (uint256 i = holderValue.fromIndex; i < roundIds.length; i++) {
        roundId = roundIds[i];
        roundList[roundId - 1].moveToHolder(adrs, coinHolders);
      }
    }

    function withdraw() public callFromHuman(msg.sender) {
        moveRoundsToHolder(msg.sender);
        uint256 amount = coinHolders.getNum(msg.sender);
        if (amount > 0) {
            coinHolders.sub(msg.sender, amount);
            //transfer
            msg.sender.transfer(amount);
        }
    }

    function roundIn() public isActive {
        string memory code = coinHolders.getRefCode(msg.sender);
        require(bytes(code).length > 0, "code must not be empty");
        require(dealers.dealerExisted(code), "dealer not exist");

        moveRoundsToHolder(msg.sender);
        uint256 amount = coinHolders.getNum(msg.sender);
        require(amount > 0, "your balance is 0");
        roundIn(amount, code);
    }

    function endRound() public isActive {
      RoundLib.Round storage curRound = roundList[roundList.length - 1];
      endRoundWhenTimeout(curRound);
    }

    function endRoundWhenTimeout(RoundLib.Round storage curRound) private isActive {
      if (now >= roundEndTime) {
          uint256 preRoundMax = 0;
          if (curRound.roundNum > 1) {
              RoundLib.Round storage preRound = roundList[roundList.length - 2];
              preRoundMax = preRound.max;
          }
          uint256 last2RoundsRaised = preRoundMax + curRound.raised;

          if (last2RoundsRaised > 0) {
              if (curRound.addressOfMaxInvestment != 0) {
                  // 20% of fund pool going to the lucky dog
                  uint256 amountToLuckyDog = fundPoolSize * 2 / 10;
                  coinHolders.add(curRound.addressOfMaxInvestment, amountToLuckyDog);
                  poolSub(amountToLuckyDog);
              }

              curRound.pot = curRound.raised * fundPoolSize / last2RoundsRaised;
              if (curRound.roundNum > 1) {
                  preRound.pot = preRound.raised * fundPoolSize / last2RoundsRaised;
                  poolSub(preRound.pot);
              }
              poolSub(curRound.pot);
          }

          mIsActive = isAutoRestart;
          startNextRound(curRound);
          bigRound++;
      }
    }

    function startNextRound(RoundLib.Round storage curRound) private {
        roundList.push(curRound.getNextRound(initSize));
        roundStartTime = now;
        roundEndTime = now + roundDuration;
    }

    function roundIn(uint256 amt, string code) private isActive {
        require(coinHolders.getNum(msg.sender) >= amt, "not enough coin");
        RoundLib.Round storage curRound = roundList[roundList.length - 1];

        if (now >= roundEndTime) {
            endRoundWhenTimeout(curRound);
            return;
        }

        (bool isFinished, uint256 amountUsed) = curRound.add(msg.sender, amt);
        totalAmountInvested = totalAmountInvested.add(amountUsed);

        require(amountUsed > 0, &#39;amountUsed must greater than 0&#39;);

        emit RoundIn(msg.sender, amountUsed, curRound.raised, curRound.roundNum, bigRound, code);

        coinHolders.addRelatedRoundId(msg.sender, curRound.roundId);

        coinHolders.sub(msg.sender, amountUsed);

        uint256 amountToDealer = dealers.addAmount(code, amountUsed);
        uint256 amountToOwner = (amountUsed * rate / 10000).sub(amountToDealer);
        coinHolders.add(owner, amountToOwner);
        coinHolders.add(dealers.query(code).addr, amountToDealer);
        poolAdd(amountUsed.sub(amountToDealer).sub(amountToOwner));

        if (isFinished) {
            if (curRound.roundNum > 1) {
                RoundLib.Round storage preRound2 = roundList[roundList.length - 2];
                preRound2.pot = preRound2.max * 11 / 10;
                poolSub(preRound2.pot);
            }

            startNextRound(curRound);
        }
    }

    function verifyCodeLength(string code) public pure returns (bool) {
        return bytes(code).length >= 4 && bytes(code).length <= 20;
    }

    function addDealer(string code, address addr, uint256 _rate) public onlyOwner {
        require(verifyCodeLength(code), "code length should between 4 and 20");
        dealers.insert(code, addr, _rate);
    }

    function addDealerForSender(string code) public {
        require(verifyCodeLength(code), "code length should between 4 and 20");
        dealers.insert(code, msg.sender, 100);
    }

    function getDealerInfo(string code) public view returns (string _code, address adrs, uint256 amount, uint256 _rate) {
        DealerLib.DealerInfo storage dealer = dealers.query(code);
        return (code, dealer.addr, dealer.amount, dealer.rate);
    }

    function updateDealer(string code, address addr, uint256 _rate) public onlyOwner {
        dealers.update(code, addr, _rate);
    }

    function setIsAutoRestart(bool isAuto) public onlyOwner {
        isAutoRestart = isAuto;
    }

    function setMinRecharge(uint256 a) public onlyOwner {
        minRecharge = a;
    }

    function setRoundDuration(uint256 a) public onlyOwner {
        roundDuration = a;
    }

    function setInitSize(uint256 size) public onlyOwner {
        initSize = size;
        RoundLib.Round storage curRound = roundList[roundList.length - 1];
        if (curRound.roundNum == 1 && curRound.raised < size) {
            curRound.max = size;
        }
    }

    function activate() public onlyOwner {
        // can only be ran once
        require(mIsActive == false, "already activated");
        // activate the contract
        mIsActive = true;
        roundStartTime = now;
        roundEndTime = now + roundDuration;
    }

    function setStartTime(uint256 startTime) public onlyOwner {
        roundStartTime = startTime;
        roundEndTime = roundStartTime + roundDuration;
    }

    function deactivate() public onlyOwner {
        require(mIsActive == true, "already deactivated");
        mIsActive = false;
    }

    function getGlobalInfo() public view returns
    (bool _isActive, bool _isAutoRestart, uint256 _round, uint256 _bigRound,
      uint256 _curRoundSize, uint256 _curRoundRaised, uint256 _fundPoolSize,
      uint256 _roundStartTime, uint256 _roundEndTime, uint256 _totalAmountInvested) {
        RoundLib.Round storage curRound = roundList[roundList.length - 1];
        return (mIsActive, isAutoRestart, curRound.roundNum, bigRound,
          curRound.max, curRound.raised, fundPoolSize,
          roundStartTime, roundEndTime, totalAmountInvested);
    }

    function getMyInfo() public view
      returns (address ethAddress, uint256 balance, uint256 preRoundAmount, uint256 curRoundAmount,
        string dealerCode, uint256 dealerAmount, uint256 dealerRate) {
      return getAddressInfo(msg.sender);
    }

    function getAddressInfo(address _address) public view
    returns (address ethAddress, uint256 balance, uint256 preRoundAmount, uint256 curRoundAmount,
      string dealerCode, uint256 dealerAmount, uint256 dealerRate) {
        RoundLib.Round storage curRound = roundList[roundList.length - 1];
        preRoundAmount = 0;
        if (curRound.roundNum > 1) {
            RoundLib.Round storage preRound = roundList[roundList.length - 2];
            preRoundAmount = preRound.getNum(_address);
        }

        (dealerCode, , dealerAmount, dealerRate) = getDealerInfo(dealers.queryCodeByAddress(_address));

        return (_address, coinHolders.getNum(_address) + getBalanceFromRound(_address),
        preRoundAmount, curRound.getNum(_address), dealerCode, dealerAmount, dealerRate);
    }

    function getBalanceFromRound(address adrs) internal view returns (uint256) {
        HolderLib.HolderValue storage holderValue = coinHolders.holderMap[adrs];
        uint256[] storage roundIds = holderValue.relatedRoundIds;
        uint256 roundId;

        uint256 balance = 0;
        for (uint256 i = holderValue.fromIndex; i < roundIds.length; i++) {
          roundId = roundIds[i];
          balance += roundList[roundId - 1].getBalance(adrs);
        }
        return balance;
    }

    function getRoundInfo(uint256 roundId, uint256 page) public view
    returns (uint256 _roundId, uint256 roundNum, uint256 max, uint256 raised, uint256 pot,
      uint256 count, address[] addressList, uint256[] numList) {
        RoundLib.Round storage round = roundList[roundId - 1];
        _roundId = round.roundId;
        roundNum = round.roundNum;
        max = round.max;
        raised = round.raised;
        pot = round.pot;
        (count, addressList, numList) = round.getInvestList(page);
    }
}