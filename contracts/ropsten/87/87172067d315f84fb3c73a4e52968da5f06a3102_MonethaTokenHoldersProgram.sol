pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: contracts/IMonethaVoucher.sol

interface IMonethaVoucher {
    /**
    * @dev Total number of vouchers in shared pool
    */
    function totalInSharedPool() external view returns (uint256);

    /**
     * @dev Converts vouchers to equivalent amount of wei.
     * @param _value amount of vouchers (vouchers) to convert to amount of wei
     * @return A uint256 specifying the amount of wei.
     */
    function toWei(uint256 _value) external view returns (uint256);

    /**
     * @dev Converts amount of wei to equivalent amount of vouchers.
     * @param _value amount of wei to convert to vouchers (vouchers)
     * @return A uint256 specifying the amount of vouchers.
     */
    function fromWei(uint256 _value) external view returns (uint256);

    /**
     * @dev Applies discount for address by returning vouchers to shared pool and transferring funds (in wei). May be called only by Monetha.
     * @param _for address to apply discount for
     * @param _vouchers amount of vouchers to return to shared pool
     * @return Actual number of vouchers returned to shared pool and amount of funds (in wei) transferred.
     */
    function applyDiscount(address _for, uint256 _vouchers) external returns (uint256 amountVouchers, uint256 amountWei);

    /**
     * @dev Applies payback by transferring vouchers from the shared pool to the user.
     * The amount of transferred vouchers is equivalent to the amount of Ether in the `_amountWei` parameter.
     * @param _for address to apply payback for
     * @param _amountWei amount of Ether to estimate the amount of vouchers
     * @return The number of vouchers added
     */
    function applyPayback(address _for, uint256 _amountWei) external returns (uint256 amountVouchers);

    /**
     * @dev TODO. May be called only by Monetha.
     */
    function buyVouchers(uint256 _vouchers) external payable;

    /**
     * @dev TODO. May be called only by Monetha.
     */
    function sellVouchers(uint256 _vouchers) external returns(uint256 weis);

    /**
     * @dev TODO. May be called only by Monetha.
     */
    function releasePurchasedTo(address _to, uint256 _value) external returns (bool);

    /**
     * @dev TODO.
     */
    function purchasedBy(address owner) external view returns (uint256);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// File: contracts/Restricted.sol

/** @title Restricted
 *  Exposes onlyMonetha modifier
 */
contract Restricted is Ownable {

    //MonethaAddress set event
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

    /**
     *  Restrict methods in such way, that they can be invoked only by monethaAddress account.
     */
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

    /**
     *  Allows owner to set new monetha address
     */
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        MonethaAddressSet(_address, _isMonethaAddress);
    }
}

// File: contracts/DateTime.sol

library DateTime {
    /**
    * @dev For a given timestamp , toDate() converts it to specific Date.
    */
    function toDate(uint256 _ts) internal pure returns (uint256 year, uint256 month, uint256 day) {
        _ts /= 86400;
        uint256 a = (4 * _ts + 102032) / 146097 + 15;
        uint256 b = _ts + 2442113 + a - (a / 4);
        year = (20 * b - 2442) / 7305;
        uint256 d = b - 365 * year - (year / 4);
        month = d * 1000 / 30601;
        day = d - month * 30 - month * 601 / 1000;

        //January and February are counted as months 13 and 14 of the previous year
        if (month <= 13) {
            year -= 4716;
            month -= 1;
        } else {
            year -= 4715;
            month -= 13;
        }
    }

    /**
    * @dev Converts a given date to timestamp.
    */
    function toTimestamp(uint256 _year, uint256 _month, uint256 _day) internal pure returns (uint256 ts) {
        //January and February are counted as months 13 and 14 of the previous year
        if (_month <= 2) {
            _month += 12;
            _year -= 1;
        }

        // Convert years to days
        ts = (365 * _year) + (_year / 4) - (_year / 100) + (_year / 400);
        //Convert months to days
        ts += (30 * _month) + (3 * (_month + 1) / 5) + _day;
        //Unix time starts on January 1st, 1970
        ts -= 719561;
        //Convert days to seconds
        ts *= 86400;
    }
}

// File: contracts/ownership/CanReclaimEther.sol

contract CanReclaimEther is Ownable {
    event ReclaimEther(address indexed to, uint256 amount);

    /**
     * @dev Transfer all Ether held by the contract to the owner.
     */
    function reclaimEther() external onlyOwner {
        uint256 value = address(this).balance;
        owner.transfer(value);

        emit ReclaimEther(owner, value);
    }

    /**
     * @dev Transfer specified amount of Ether held by the contract to the address.
     * @param _to The address which will receive the Ether
     * @param _value The amount of Ether to transfer
     */
    function reclaimEtherTo(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _to.transfer(_value);

        emit ReclaimEther(_to, _value);
    }
}

// File: contracts/ownership/CanReclaimTokens.sol

contract CanReclaimTokens is Ownable {
    using SafeERC20 for ERC20Basic;

    event ReclaimTokens(address indexed to, uint256 amount);

    /**
     * @dev Reclaim all ERC20Basic compatible tokens
     * @param _token ERC20Basic The address of the token contract
     */
    function reclaimToken(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        _token.safeTransfer(owner, balance);

        emit ReclaimTokens(owner, balance);
    }

    /**
     * @dev Reclaim specified amount of ERC20Basic compatible tokens
     * @param _token ERC20Basic The address of the token contract
     * @param _to The address which will receive the tokens
     * @param _value The amount of tokens to transfer
     */
    function reclaimTokenTo(ERC20Basic _token, address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _token.safeTransfer(_to, _value);

        emit ReclaimTokens(_to, _value);
    }
}

// File: contracts/MonethaTokenHoldersProgram.sol

contract MonethaTokenHoldersProgram is Restricted, CanReclaimEther, CanReclaimTokens {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC20 for ERC20Basic;

    event VouchersPurchased(uint256 vouchers, uint256 weis);
    event VouchersSold(uint256 vouchers, uint256 weis);
    event ParticipationStarted(address indexed participant, uint256 mthTokens);
    event ParticipationStopped(address indexed participant, uint256 mthTokens);
    event VouchersRedeemed(address indexed participant, uint256 vouchers);

    ERC20 public mthToken;
    IMonethaVoucher public monethaVoucher;

    uint256 public participateFromTimestamp;

    mapping(address => uint256) public stakedBy;
    uint256 public totalStacked;

    constructor(ERC20 _mthToken, IMonethaVoucher _monethaVoucher) public {
        require(_monethaVoucher != address(0), "must be valid address");
        require(_mthToken != address(0), "must be valid address");

        mthToken = _mthToken;
        monethaVoucher = _monethaVoucher;
        // don&#39;t allow to participate
        participateFromTimestamp = uint256(- 1);
    }

    /**
     * @dev Before holders of MTH tokens can participate in the program, it is necessary to buy vouchers for the Ether
     * available in the contract. 1/3 of Monetha&#39;s revenue will be transferred to this contract to buy the Monetha vouchers.
     * This method uses all available Ethers of contract to buy Monetha vouchers.
     * The method tries to buy the maximum possible amount of vouchers.
     */
    function buyVouchers() external onlyMonetha {
        uint256 amountToExchange = address(this).balance;
        require(amountToExchange > 0, "positive balance needed");

        uint256 vouchersAvailable = monethaVoucher.totalInSharedPool();
        require(vouchersAvailable > 0, "no vouchers available");

        uint256 vouchersToBuy = monethaVoucher.fromWei(address(this).balance);
        // limit vouchers
        if (vouchersToBuy > vouchersAvailable) {
            vouchersToBuy = vouchersAvailable;
            amountToExchange = monethaVoucher.toWei(vouchersToBuy);
        }

        (uint256 year, uint256 month,) = DateTime.toDate(now);
        participateFromTimestamp = _nextMonth1stDayTimestamp(year, month);

        monethaVoucher.buyVouchers.value(amountToExchange)(vouchersToBuy);

        emit VouchersPurchased(vouchersToBuy, amountToExchange);
    }

    /**
     * @dev Converts all available vouchers to Ether and stops the program until vouchers are purchased again by
     * calling `buyVouchers` method.
     * Holders of MTH token holders can still call `cancelParticipation` method to reclaim the MTH tokens.
     */
    function sellVouchers() external onlyMonetha {
        // don&#39;t allow to participate
        participateFromTimestamp = uint256(- 1);

        uint256 vouchersPool = monethaVoucher.purchasedBy(address(this));
        uint256 weis = monethaVoucher.sellVouchers(vouchersPool);

        emit VouchersSold(vouchersPool, weis);
    }

    /**
     * @dev Returns true when it&#39;s allowed to participate in token holders program, i.e. to call `participate()` method.
     */
    function isAllowedToParticipateNow() external view returns (bool) {
        return now >= participateFromTimestamp && _participateIsAllowed(now);
    }

    /**
     * @dev To redeem vouchers, holders of MTH token must declare their participation on the 1st day of the month by calling
     * this method. Before calling this method, holders of MTH token should approve this contract to transfer some amount
     * of MTH tokens in their behalf, by calling `approve(address _spender, uint _value)` method of MTH token contract.
     * `participate` method can be called on the first day of any month if the contract has purchased vouchers.
     */
    function participate() external {
        require(now >= participateFromTimestamp, "too early to participate");
        require(_participateIsAllowed(now), "participate on the 1st day of every month");

        uint256 allowedToTransfer = mthToken.allowance(msg.sender, address(this));
        require(allowedToTransfer > 0, "positive allowance needed");

        mthToken.safeTransferFrom(msg.sender, address(this), allowedToTransfer);
        stakedBy[msg.sender] = stakedBy[msg.sender].add(allowedToTransfer);
        totalStacked = totalStacked.add(allowedToTransfer);

        emit ParticipationStarted(msg.sender, allowedToTransfer);
    }

    /**
     * @dev Returns true when it&#39;s allowed to redeem vouchers and reclaim MTH tokens, i.e. to call `redeem()` method.
     */
    function isAllowedToRedeemNow() external view returns (bool) {
        return now >= participateFromTimestamp && _redeemIsAllowed(now);
    }

    /**
     * @dev Redeems vouchers to holder of MTH tokens and reclaims the MTH tokens.
     * The method can be invoked only if the holder of the MTH tokens declared participation on the first day of the month.
     * The method should be called half an hour after the beginning of the second day of the month and half an hour
     * before the beginning of the next month.
     */
    function redeem() external {
        require(now >= participateFromTimestamp, "too early to redeem");
        require(_redeemIsAllowed(now), "redeem is not allowed at the moment");

        (uint256 stackedBefore, uint256 totalStackedBefore) = _cancelParticipation();

        uint256 vouchersPool = monethaVoucher.purchasedBy(address(this));
        uint256 vouchers = vouchersPool.mul(stackedBefore).div(totalStackedBefore);

        require(monethaVoucher.releasePurchasedTo(msg.sender, vouchers), "vouchers was not released");

        emit VouchersRedeemed(msg.sender, vouchers);
    }

    /**
     * @dev Cancels participation of holder of MTH tokens at any time and reclaims MTH tokens.
     */
    function cancelParticipation() external {
        _cancelParticipation();
    }

    // Allows direct funds send by Monetha
    function() external onlyMonetha payable {
    }

    function _cancelParticipation() internal returns (uint256 stackedBefore, uint256 totalStackedBefore) {
        stackedBefore = stakedBy[msg.sender];
        require(stackedBefore > 0, "must be a participant");
        totalStackedBefore = totalStacked;

        stakedBy[msg.sender] = 0;
        totalStacked = totalStackedBefore.sub(stackedBefore);
        mthToken.safeTransfer(msg.sender, stackedBefore);

        emit ParticipationStopped(msg.sender, stackedBefore);
    }

    function _participateIsAllowed(uint256 _now) internal pure returns (bool) {
        (,, uint256 day) = DateTime.toDate(_now);
        return day == 1;
    }

    function _redeemIsAllowed(uint256 _now) internal pure returns (bool) {
        (uint256 year, uint256 month,) = DateTime.toDate(_now);
        return _currentMonth2ndDayTimestamp(year, month) + 30 minutes <= _now &&
        _now <= _nextMonth1stDayTimestamp(year, month) - 30 minutes;
    }

    function _currentMonth2ndDayTimestamp(uint256 _year, uint256 _month) internal pure returns (uint256) {
        return DateTime.toTimestamp(_year, _month, 2);
    }

    function _nextMonth1stDayTimestamp(uint256 _year, uint256 _month) internal pure returns (uint256) {
        _month += 1;
        if (_month > 12) {
            _year += 1;
            _month = 1;
        }
        return DateTime.toTimestamp(_year, _month, 1);
    }
}