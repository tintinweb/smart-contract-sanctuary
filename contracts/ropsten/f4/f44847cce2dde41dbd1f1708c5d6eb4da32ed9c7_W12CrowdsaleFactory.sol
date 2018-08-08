pragma solidity ^0.4.13;

interface IW12Crowdsale {
    function setParameters(uint32 _startDate, uint _price, address _serviceWallet) external;

    function setStages(uint32[] stage_endDates, uint8[] stage_discounts, uint32[] stage_vestings) external;

    function setStageVolumeBonuses(uint stage, uint[] volumeBoundaries, uint8[] volumeBonuses) external;

    function getWToken() external view returns(WToken);

    function () payable external;
}

interface IW12CrowdsaleFactory {
    function createCrowdsale(address _wTokenAddress, uint32 _startDate, uint price, address serviceWallet, uint8 serviceFee, address swap, address owner) external returns (IW12Crowdsale);
}

contract W12CrowdsaleFactory is IW12CrowdsaleFactory {

    event CrowdsaleCreated(address indexed owner, address indexed token, uint32 startDate, address crowdsaleAddress, address fundAddress);

    function createCrowdsale(
        address wTokenAddress,
        uint32 startDate,
        uint price,
        address serviceWallet,
        uint8 serviceFee,
        address swap,
        address owner)
        external returns (IW12Crowdsale result) {

        W12Fund fund = new W12Fund();

        result = new W12Crowdsale(WToken(wTokenAddress), startDate, price, serviceWallet, serviceFee, fund);
        Ownable(result).transferOwnership(owner);

        fund.setCrowdsale(result);
        fund.setSwap(swap);
        Ownable(fund).transferOwnership(owner);

        emit CrowdsaleCreated(owner, wTokenAddress, startDate, result, fund);
    }
}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract W12Crowdsale is IW12Crowdsale, Ownable, ReentrancyGuard {
    using SafeMath for uint;

    struct Stage {
        uint32 endDate;
        uint8 discount;
        uint32 vesting;
        uint[] volumeBoundaries;
        uint8[] volumeBonuses;
    }

    struct Milestone {
        uint32 endDate;
        uint8 tranchePercent;
        uint32 voteEndDate;
    }

    WToken public token;
    uint32 public startDate;
    uint public price;
    uint8 public serviceFee;
    address public serviceWallet;
    W12Fund public fund;

    Stage[] public stages;
    Milestone[] public milestones;

    event TokenPurchase(address indexed buyer, uint amountPaid, uint tokensBought);
    event StagesUpdated();

    constructor (address _token, uint32 _startDate, uint _price, address _serviceWallet, uint8 _serviceFee, W12Fund _fund) public {
        require(_token != address(0));
        require(_serviceFee >= 0 && _serviceFee < 100);
        require(_fund != address(0));

        token = WToken(_token);

        __setParameters(_startDate, _price, _serviceWallet);
        serviceFee = _serviceFee;
        fund = _fund;
    }

    function stagesLength() external view returns (uint) {
        return stages.length;
    }

    function milestonesLength() external view returns (uint) {
        return milestones.length;
    }

    function getStageVolumeBoundaries(uint stageNumber) external view returns (uint[]) {
        return stages[stageNumber].volumeBoundaries;
    }

    function getStageVolumeBonuses(uint stageNumber) external view returns (uint8[]) {
        return stages[stageNumber].volumeBonuses;
    }

    function __setParameters(uint32 _startDate, uint _price, address _serviceWallet) internal {
        require(_startDate >= now);
        require(_price > 0);
        require(_serviceWallet != address(0));

        startDate = _startDate;
        price = _price;
        serviceWallet = _serviceWallet;
    }

    function setParameters(uint32 _startDate, uint _price, address _serviceWallet) external onlyOwner {
        __setParameters(_startDate, _price, _serviceWallet);
    }

    function setStages(uint32[] stage_endDates, uint8[] stage_discounts, uint32[] stage_vestings) external onlyOwner {
        require(stage_endDates.length <= uint8(-1));
        require(stage_endDates.length > 0);
        require(stage_endDates.length == stage_discounts.length);
        require(stage_endDates.length == stage_vestings.length);

        uint8 stagesCount = uint8(stage_endDates.length);
        stages.length = stagesCount;

        for(uint8 i = 0; i < stagesCount; i++) {
            require(stage_discounts[i] >= 0 && stage_discounts[i] < 100);
            require(startDate < stage_endDates[i]);
            // Checking that stages entered in historical order
            if(i < stagesCount - 1)
                require(stage_endDates[i] < stage_endDates[i+1], "Stages are not in historical order");

            // Reverting stage order for future use
            stages[stagesCount - i - 1].endDate = stage_endDates[i];
            stages[stagesCount - i - 1].discount = stage_discounts[i];
            stages[stagesCount - i - 1].vesting = stage_vestings[i];
        }

        emit StagesUpdated();
    }

    function setStageVolumeBonuses(uint stage, uint[] volumeBoundaries, uint8[] volumeBonuses) external onlyOwner {
        require(volumeBoundaries.length == volumeBonuses.length);
        require(stage < stages.length);

        stages[stage].volumeBoundaries = volumeBoundaries;
        stages[stage].volumeBonuses = volumeBonuses;
    }

    function setMilestones(uint32[] endDates, uint8[] tranchePercents, uint32[] voteEndDates) external onlyOwner {
        require(endDates.length <= uint8(-1));
        require(endDates.length > 0);
        require(endDates.length == tranchePercents.length);
        require(endDates.length == voteEndDates.length);

        uint8 length = uint8(endDates.length);
        delete milestones;

        for(uint8 i = 0; i < length; i++)
            milestones.push(Milestone({
                endDate: endDates[i],
                tranchePercent: tranchePercents[i],
                voteEndDate: voteEndDates[i]
            }));
    }

    function buyTokens() payable nonReentrant public {
        require(msg.value > 0);
        require(startDate <= now);
        require(stages.length > 0);

        (uint8 discount, uint32 vesting, uint8 volumeBonus) = getCurrentStage();

        uint stagePrice = discount > 0 ? price.mul(100 - discount).div(100) : price;

        uint tokenAmount = msg.value
            .mul(100 + volumeBonus)
            .div(stagePrice)
            .div(100);

        require(token.vestingTransfer(msg.sender, tokenAmount, vesting));

        if(serviceFee > 0)
            serviceWallet.transfer(msg.value.mul(serviceFee).div(100));

        fund.recordPurchase.value(address(this).balance).gas(100000)(msg.sender, tokenAmount);

        emit TokenPurchase(msg.sender, msg.value, tokenAmount);
    }

    function getWToken() external view returns(WToken) {
        return token;
    }

    function getFund() external view returns(W12Fund) {
        return fund;
    }

    function getCurrentStage() internal returns(uint8 discount, uint32 vesting, uint8 volumeBonus) {
        if(stages.length == 0)
            return (0, 0, 0);

        Stage storage lastStage = stages[stages.length - 1];

        if(lastStage.endDate >= now) {
            volumeBonus = 0;
            uint lastLowerBoundary = 0;

            if(lastStage.volumeBoundaries.length > 0)
                for (uint i = 0; i < lastStage.volumeBoundaries.length - 1; i++)
                    if(msg.value >= lastLowerBoundary && msg.value < lastStage.volumeBoundaries[i]) {
                        volumeBonus = lastStage.volumeBonuses[i];
                        break;
                    }
                    else
                        lastLowerBoundary = lastStage.volumeBoundaries[i];

            return (lastStage.discount, lastStage.vesting, volumeBonus);
        }

        stages.length--;
        return getCurrentStage();
    }

    function () payable external {
        buyTokens();
    }

    function claimRemainingTokens() external onlyOwner {
        require(stages.length == 0);

        require(token.transfer(owner, token.balanceOf(address(this))));
    }
}

contract W12Fund is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    IW12Crowdsale public crowdsale;
    address public swap;
    WToken public wToken;
    mapping (address=>TokenPriceInfo) public buyers;
    uint totalFunded;

    struct TokenPriceInfo {
        uint totalBought;
        uint averagePrice;
        uint totalFunded;
    }

    event FundsReceived(address indexed buyer, uint etherAmount, uint tokenAmount);

    function setCrowdsale(IW12Crowdsale _crowdsale) onlyOwner external {
        require(_crowdsale != address(0));

        crowdsale = _crowdsale;
        wToken = _crowdsale.getWToken();
    }

    function setSwap(address _swap) onlyOwner external {
        require(_swap != address(0));

        swap = _swap;
    }

    function recordPurchase(address buyer, uint tokenAmount) external payable onlyFrom(crowdsale) {
        uint tokensBoughtBefore = buyers[buyer].totalBought;

        buyers[buyer].totalBought = tokensBoughtBefore.add(tokenAmount);
        buyers[buyer].totalFunded = buyers[buyer].totalFunded.add(msg.value);
        buyers[buyer].averagePrice = buyers[buyer].totalFunded.div(buyers[buyer].totalBought);

        totalFunded += msg.value;

        emit FundsReceived(buyer, msg.value, tokenAmount);
    }

    function getInvestmentsInfo(address buyer) external view returns (uint totalTokensBought, uint averageTokenPrice) {
        require(buyer != address(0));

        return (buyers[buyer].totalBought, buyers[buyer].averagePrice);
    }

    function refund(uint wtokensToRefund) external nonReentrant {
        require(wToken.balanceOf(msg.sender) >= wtokensToRefund);
        require(buyers[msg.sender].totalBought >= wtokensToRefund);

        require(wToken.transferFrom(msg.sender, swap, wtokensToRefund));

        uint share = totalFunded.div(buyers[msg.sender].totalFunded);
        uint refundTokensShare = buyers[msg.sender].totalBought.div(wtokensToRefund);

        msg.sender.transfer(share.div(refundTokensShare));
    }

    modifier onlyFrom(address sender) {
        require(msg.sender == sender);

        _;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract WToken is DetailedERC20, Ownable {

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping(address => uint256) public balances;

    uint256 private _totalSupply;

    mapping (address => mapping (uint256 => uint256)) public vestingBalanceOf;

    mapping (address => uint[]) vestingTimes;

    mapping (address => bool) trustedAccounts;

    event VestingTransfer(address _from, address _to, uint256 value, uint256 agingTime);

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    constructor(string _name, string _symbol, uint8 _decimals) DetailedERC20(_name, _symbol, _decimals) public {
        trustedAccounts[msg.sender] = true;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _checkMyVesting(msg.sender);
        require(_to != address(0));
        require(_value <= accountBalance(msg.sender));

        balances[msg.sender] -= _value;

        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function vestingTransfer(address _to, uint256 _value, uint32 _vestingTime) external onlyTrusted(msg.sender) returns (bool) {
        transfer(_to, _value);

        if (_vestingTime > now) {
            _addToVesting(address(0x0), _to, _vestingTime, _value);
        }

        emit VestingTransfer(msg.sender, _to, _value, _vestingTime);

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

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _checkMyVesting(_from);

        require(_to != address(0));
        require(_value <= accountBalance(_from));
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);

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
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

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
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function mint(address _to, uint _amount, uint32 _vestingTime) external onlyTrusted(msg.sender) returns (bool) {
        require(_totalSupply + _amount > _totalSupply);

        if (_vestingTime > now) {
            _addToVesting(address(0x0), _to, _vestingTime, _amount);
        }

        balances[_to] += _amount;
        _totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);

        return true;
    }

    function _addToVesting(address _from, address _to, uint256 _vestingTime, uint256 _amount) internal {
        vestingBalanceOf[_to][0] += _amount;

        if(vestingBalanceOf[_to][_vestingTime] == 0)
            vestingTimes[_to].push(_vestingTime);

        vestingBalanceOf[_to][_vestingTime] += _amount;
        emit VestingTransfer(_from, _to, _amount, _vestingTime);
    }

    function () external {
        revert();
    }

    function _checkMyVesting(address _from) internal {
        if (vestingBalanceOf[_from][0] == 0) return;

        for (uint256 k = 0; k < vestingTimes[_from].length; k++) {
            if (vestingTimes[_from][k] < now) {
                vestingBalanceOf[_from][0] -= vestingBalanceOf[_from][vestingTimes[_from][k]];
                vestingBalanceOf[_from][vestingTimes[_from][k]] = 0;
            }
        }
    }

    function accountBalance(address _address) public view returns (uint256 balance) {
        return balances[_address] - vestingBalanceOf[_address][0];
    }

    function addTrustedAccount(address caller) external onlyOwner {
        trustedAccounts[caller] = true;
    }

    function removeTrustedAccount(address caller) external onlyOwner {
        trustedAccounts[caller] = false;
    }

    modifier onlyTrusted(address caller) {
        require(trustedAccounts[caller]);
        _;
    }
}