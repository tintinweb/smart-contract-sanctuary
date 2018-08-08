pragma solidity ^0.4.23;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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
contract PreSale is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) public unconfirmedMap;
    mapping(address => uint256) public confirmedMap;
    mapping(address => address) public holderReferrer;
    mapping(address => uint256) public holdersOrder;
    address[] public holders;
    uint256 public holdersCount;
    mapping(address => uint256) public bonusMap;
    mapping(address => uint256) public topMap;
    uint256 public confirmedAmount;
    uint256 public bonusAmount;
    uint256 lastOf10 = 0;
    uint256 lastOf15 = 0;
    mapping(address => bool) _isConfirmed;
    uint256 public totalSupply;
    uint256 REF_BONUS_PERCENT = 50;
    uint256 MIN_AMOUNT = 9 * 10e15;
    uint256 OPERATIONS_FEE = 10e15;
    uint256 public startTime;
    uint256 public endTime;
    //48 hours
    uint256 public confirmTime = 48 * 3600;
    bool internal _isGoalReached = false;
    ERC20 token;
    constructor(
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        ERC20 _token
    ) public {
        require(_startTime >= now);
        require(_startTime < _endTime);
        totalSupply = _totalSupply;
        startTime = _startTime;
        endTime = _endTime;
        token = _token;
    }
    modifier pending() {
        require(now >= startTime && now < endTime);
        _;
    }
    modifier isAbleConfirmation() {
        require(now >= startTime && now < endTime + confirmTime);
        _;
    }
    modifier hasClosed() {
        require(now >= endTime + confirmTime);
        _;
    }
    modifier isGoalReached() {
        require(_isGoalReached);
        _;
    }
    modifier onlyConfirmed() {
        require(_isConfirmed[msg.sender]);
        _;
    }
    function() payable public pending {
        _buyTokens(msg.sender, msg.value);
    }
    function buyTokens(address holder) payable public pending {
        _buyTokens(holder, msg.value);
    }
    function buyTokensByReferrer(address holder, address referrer) payable public pending {
        if (_canSetReferrer(holder, referrer)) {
            _setReferrer(holder, referrer);
        }
        uint256 amount = msg.value - OPERATIONS_FEE;
        holder.transfer(OPERATIONS_FEE);
        _buyTokens(holder, amount);
    }
    function _buyTokens(address holder, uint256 amount) private {
        require(amount >= MIN_AMOUNT);
        if (_isConfirmed[holder]) {
            confirmedMap[holder] = confirmedMap[holder].add(amount);
            confirmedAmount = confirmedAmount.add(amount);
        } else {
            unconfirmedMap[holder] = unconfirmedMap[holder].add(amount);
        }
        if (holdersOrder[holder] == 0) {
            holders.push(holder);
            holdersOrder[holder] = holders.length;
            holdersCount++;
        }
        _addBonus(holder, amount);
    }
    function _addBonus(address holder, uint256 amount) internal {
        _addBonusOfTop(holder, amount);
        _topBonus();
        _addBonusOfReferrer(holder, amount);
    }
    function _addBonusOfTop(address holder, uint256 amount) internal {
        uint256 bonusOf = 0;
        if (holdersOrder[holder] <= holdersCount.div(10)) {
            bonusOf = amount.div(10);
        } else if (holdersOrder[holder] <= holdersCount.mul(15).div(100)) {
            bonusOf = amount.mul(5).div(100);
        }
        if (bonusOf == 0) {
            return;
        }
        topMap[holder] = topMap[holder].add(bonusOf);
        if (_isConfirmed[holder]) {
            bonusAmount = bonusAmount.add(bonusOf);
        }
    }
    function _topBonus() internal {
        uint256 bonusFor = 0;
        address holder;
        uint256 currentAmount;
        if (lastOf10 < holdersCount.div(10)) {
            holder = holders[lastOf10++];
            currentAmount = _isConfirmed[holder] ? confirmedMap[holder] : unconfirmedMap[holder];
            bonusFor = currentAmount.div(10);
        } else if (lastOf15 < holdersCount.mul(15).div(100)) {
            holder = holders[lastOf15++];
            currentAmount = _isConfirmed[holder] ? confirmedMap[holder] : unconfirmedMap[holder];
            bonusFor = currentAmount.div(20);
        } else {
            return;
        }
        if (bonusFor <= topMap[holder]) {
            return;
        }
        if (_isConfirmed[holder]) {
            uint256 diff = bonusFor - topMap[holder];
            bonusAmount = bonusAmount.add(diff);
        }
        topMap[holder] = bonusFor;
    }
    function _addBonusOfReferrer(address holder, uint256 amount) internal {
        if (holderReferrer[holder] == 0x0) {
            return;
        }
        address referrer = holderReferrer[holder];
        uint256 bonus = amount.div(2);
        bonusMap[holder] = bonusMap[holder].add(bonus);
        bonusMap[referrer] = bonusMap[referrer].add(bonus);
        if (_isConfirmed[holder]) {
            bonusAmount = bonusAmount.add(bonus);
        }
        if (_isConfirmed[referrer]) {
            bonusAmount = bonusAmount.add(bonus);
        }
    }
    function _canSetReferrer(address holder, address referrer) view private returns (bool) {
        return holderReferrer[holder] == 0x0
        && holder != referrer
        && referrer != 0x0
        && holderReferrer[referrer] != holder;
    }
    function _setReferrer(address holder, address referrer) private {
        holderReferrer[holder] = referrer;
        if (_isConfirmed[holder]) {
            _addBonusOfReferrer(holder, confirmedMap[holder]);
        } else {
            _addBonusOfReferrer(holder, unconfirmedMap[holder]);
        }
    }
    function setReferrer(address referrer) public pending {
        require(_canSetReferrer(msg.sender, referrer));
        _setReferrer(msg.sender, referrer);
    }
    function _confirm(address holder) private {
        confirmedMap[holder] = unconfirmedMap[holder];
        unconfirmedMap[holder] = 0;
        confirmedAmount = confirmedAmount.add(confirmedMap[holder]);
        bonusAmount = bonusAmount.add(bonusMap[holder]).add(topMap[holder]);
        _isConfirmed[holder] = true;
    }
    function isConfirmed(address holder) public view returns (bool) {
        return _isConfirmed[holder];
    }
    function getTokens() public hasClosed isGoalReached onlyConfirmed returns (uint256) {
        uint256 tokens = calculateTokens(msg.sender);
        require(tokens > 0);
        confirmedMap[msg.sender] = 0;
        bonusMap[msg.sender] = 0;
        topMap[msg.sender] = 0;
        require(token.transfer(msg.sender, tokens));
    }
    function getRefund() public hasClosed {
        address holder = msg.sender;
        uint256 funds = 0;
        if (_isConfirmed[holder]) {
            require(_isGoalReached == false);
            funds = confirmedMap[holder];
            require(funds > 0);
            confirmedMap[holder] = 0;
        } else {
            funds = unconfirmedMap[holder];
            require(funds > 0);
            unconfirmedMap[holder] = 0;
        }
        holder.transfer(funds);
    }
    function calculateTokens(address holder) public view returns (uint256) {
        return totalSupply.mul(calculateHolderPiece(holder)).div(calculatePie());
    }
    function calculatePie() public view returns (uint256) {
        return confirmedAmount.add(bonusAmount);
    }
    function getCurrentPrice() public view returns (uint256) {
        return calculatePie().div(totalSupply);
    }
    function calculateHolderPiece(address holder) public view returns (uint256){
        return confirmedMap[holder].add(bonusMap[holder]).add(topMap[holder]);
    }
    //***** admin ***
    function confirm(address holder) public isAbleConfirmation onlyOwner {
        require(!_isConfirmed[holder]);
        _confirm(holder);
    }
    function confirmBatch(address[] _holders) public isAbleConfirmation onlyOwner {
        for (uint i = 0; i < _holders.length; i++) {
            if (!_isConfirmed[_holders[i]]) {
                _confirm(_holders[i]);
            }
        }
    }
    function setReached(bool _isIt) public onlyOwner isAbleConfirmation {
        _isGoalReached = _isIt;
        if (!_isIt) {
            token.transfer(owner, totalSupply);
        }
    }
    function getRaised() public hasClosed isGoalReached onlyOwner {
        owner.transfer(confirmedAmount);
    }
}