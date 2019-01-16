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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
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
     * @dev Function to buy vouchers by transferring equivalent amount in Ether to contract. May be called only by Monetha.
     * After the vouchers are purchased, they can be sold or released to another user. Purchased vouchers are stored in
     * a separate pool and may not be expired.
     * @param _vouchers The amount of vouchers to buy. The caller must also transfer an equivalent amount of Ether.
     */
    function buyVouchers(uint256 _vouchers) external payable;

    /**
     * @dev The function allows Monetha account to sell previously purchased vouchers and get Ether from the sale.
     * The equivalent amount of Ether will be transferred to the caller. May be called only by Monetha.
     * @param _vouchers The amount of vouchers to sell.
     * @return A uint256 specifying the amount of Ether (in wei) transferred to the caller.
     */
    function sellVouchers(uint256 _vouchers) external returns(uint256 weis);

    /**
     * @dev Function allows Monetha account to release the purchased vouchers to any address.
     * The released voucher acquires an expiration property and should be used in Monetha ecosystem within 6 months, otherwise
     * it will be returned to shared pool. May be called only by Monetha.
     * @param _to address to release vouchers to.
     * @param _value the amount of vouchers to release.
     */
    function releasePurchasedTo(address _to, uint256 _value) external returns (bool);

    /**
     * @dev Function to check the amount of vouchers that an owner (Monetha account) allowed to sell or release to some user.
     * @param owner The address which owns the funds.
     * @return A uint256 specifying the amount of vouchers still available for the owner.
     */
    function purchasedBy(address owner) external view returns (uint256);
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

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }
}

// File: contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

// File: contracts/MonethaVoucher.sol

contract MonethaVoucher is IMonethaVoucher, Restricted, Pausable, IERC20, CanReclaimEther, CanReclaimTokens {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event DiscountApplied(address indexed user, uint256 releasedVouchers, uint256 amountWeiTransferred);
    event PaybackApplied(address indexed user, uint256 addedVouchers, uint256 amountWeiEquivalent);
    event VouchersBought(address indexed user, uint256 vouchersBought);
    event VouchersSold(address indexed user, uint256 vouchersSold, uint256 amountWeiTransferred);
    event VoucherMthRateUpdated(uint256 oldVoucherMthRate, uint256 newVoucherMthRate);
    event MthEthRateUpdated(uint256 oldMthEthRate, uint256 newMthEthRate);
    event VouchersAdded(address indexed user, uint256 vouchersAdded);
    event VoucherReleased(address indexed user, uint256 releasedVoucher);
    event PurchasedVouchersReleased(address indexed from, address indexed to, uint256 vouchers);

    /* Public variables of the token */
    string constant public standard = "ERC20";
    string constant public name = "Monetha Voucher";
    string constant public symbol = "MTHV";
    uint8 constant public decimals = 5;

    /* For calculating half year */
    uint256 constant private DAY_IN_SECONDS = 86400;
    uint256 constant private YEAR_IN_SECONDS = 365 * DAY_IN_SECONDS;
    uint256 constant private LEAP_YEAR_IN_SECONDS = 366 * DAY_IN_SECONDS;
    uint256 constant private YEAR_IN_SECONDS_AVG = (YEAR_IN_SECONDS * 3 + LEAP_YEAR_IN_SECONDS) / 4;
    uint256 constant private HALF_YEAR_IN_SECONDS_AVG = YEAR_IN_SECONDS_AVG / 2;

    uint256 constant public RATE_COEFFICIENT = 1000000000000000000; // 10^18
    uint256 constant private RATE_COEFFICIENT2 = RATE_COEFFICIENT * RATE_COEFFICIENT; // RATE_COEFFICIENT^2
    
    uint256 public voucherMthRate; // number of voucher units in 10^18 MTH units
    uint256 public mthEthRate; // number of mth units in 10^18 wei
    uint256 internal voucherMthEthRate; // number of vouchers units (= voucherMthRate * mthEthRate) in 10^36 wei

    ERC20Basic public mthToken;

    mapping(address => uint256) public purchased; // amount of vouchers purchased by other monetha contract
    uint256 public totalPurchased;                        // total amount of vouchers purchased by monetha

    mapping(uint16 => uint256) public totalDistributedIn; // аmount of vouchers distributed in specific half-year
    mapping(uint16 => mapping(address => uint256)) public distributed; // amount of vouchers distributed in specific half-year to specific user

    constructor(uint256 _voucherMthRate, uint256 _mthEthRate, ERC20Basic _mthToken) public {
        require(_voucherMthRate > 0, "voucherMthRate should be greater than 0");
        require(_mthEthRate > 0, "mthEthRate should be greater than 0");
        require(_mthToken != address(0), "must be valid contract");

        voucherMthRate = _voucherMthRate;
        mthEthRate = _mthEthRate;
        mthToken = _mthToken;
        _updateVoucherMthEthRate();
    }

    /**
    * @dev Total number of vouchers in existence = vouchers in shared pool + vouchers distributed + vouchers purchased
    */
    function totalSupply() external view returns (uint256) {
        return _totalVouchersSupply();
    }

    /**
    * @dev Total number of vouchers in shared pool
    */
    function totalInSharedPool() external view returns (uint256) {
        return _vouchersInSharedPool(_currentHalfYear());
    }

    /**
    * @dev Total number of vouchers distributed
    */
    function totalDistributed() external view returns (uint256) {
        return _vouchersDistributed(_currentHalfYear());
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) external view returns (uint256) {
        return _distributedTo(owner, _currentHalfYear()).add(purchased[owner]);
    }

    /**
     * @dev Function to check the amount of vouchers that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of vouchers still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        owner;
        spender;
        return 0;
    }

    /**
    * @dev Transfer voucher for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool) {
        to;
        value;
        revert();
    }

    /**
     * @dev Approve the passed address to spend the specified amount of vouchers on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of vouchers to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        spender;
        value;
        revert();
    }

    /**
     * @dev Transfer vouchers from one address to another
     * @param from address The address which you want to send vouchers from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of vouchers to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        from;
        to;
        value;
        revert();
    }

    // Allows direct funds send by Monetha
    function () external onlyMonetha payable {
    }

    /**
     * @dev Converts vouchers to equivalent amount of wei.
     * @param _value amount of vouchers to convert to amount of wei
     * @return A uint256 specifying the amount of wei.
     */
    function toWei(uint256 _value) external view returns (uint256) {
        return _vouchersToWei(_value);
    }

    /**
     * @dev Converts amount of wei to equivalent amount of vouchers.
     * @param _value amount of wei to convert to vouchers
     * @return A uint256 specifying the amount of vouchers.
     */
    function fromWei(uint256 _value) external view returns (uint256) {
        return _weiToVouchers(_value);
    }

    /**
     * @dev Applies discount for address by returning vouchers to shared pool and transferring funds (in wei). May be called only by Monetha.
     * @param _for address to apply discount for
     * @param _vouchers amount of vouchers to return to shared pool
     * @return Actual number of vouchers returned to shared pool and amount of funds (in wei) transferred.
     */
    function applyDiscount(address _for, uint256 _vouchers) external onlyMonetha returns (uint256 amountVouchers, uint256 amountWei) {
        require(_for != address(0), "zero address is not allowed");
        uint256 releasedVouchers = _releaseVouchers(_for, _vouchers);
        uint256 amountToTransfer = _vouchersToWei(releasedVouchers);

        require(address(this).balance >= amountToTransfer, "insufficient funds");
        _for.transfer(amountToTransfer);

        emit DiscountApplied(_for, releasedVouchers, amountToTransfer);

        return (releasedVouchers, amountToTransfer);
    }

    /**
     * @dev Applies payback by transferring vouchers from the shared pool to the user.
     * The amount of transferred vouchers is equivalent to the amount of Ether in the `_amountWei` parameter.
     * @param _for address to apply payback for
     * @param _amountWei amount of Ether to estimate the amount of vouchers
     * @return The number of vouchers added
     */
    function applyPayback(address _for, uint256 _amountWei) external onlyMonetha returns (uint256 amountVouchers) {
        amountVouchers = _weiToVouchers(_amountWei);
        require(_addVouchers(_for, amountVouchers), "vouchers must be added");

        emit PaybackApplied(_for, amountVouchers, _amountWei);
    }

    /**
     * @dev Function to buy vouchers by transferring equivalent amount in Ether to contract. May be called only by Monetha.
     * After the vouchers are purchased, they can be sold or released to another user. Purchased vouchers are stored in
     * a separate pool and may not be expired.
     * @param _vouchers The amount of vouchers to buy. The caller must also transfer an equivalent amount of Ether.
     */
    function buyVouchers(uint256 _vouchers) external onlyMonetha payable {
        uint16 currentHalfYear = _currentHalfYear();
        require(_vouchersInSharedPool(currentHalfYear) >= _vouchers, "insufficient vouchers present");
        require(msg.value == _vouchersToWei(_vouchers), "insufficient funds");

        _addPurchasedTo(msg.sender, _vouchers);

        emit VouchersBought(msg.sender, _vouchers);
    }

    /**
     * @dev The function allows Monetha account to sell previously purchased vouchers and get Ether from the sale.
     * The equivalent amount of Ether will be transferred to the caller. May be called only by Monetha.
     * @param _vouchers The amount of vouchers to sell.
     * @return A uint256 specifying the amount of Ether (in wei) transferred to the caller.
     */
    function sellVouchers(uint256 _vouchers) external onlyMonetha returns(uint256 weis) {
        require(_vouchers <= purchased[msg.sender], "Insufficient vouchers");

        _subPurchasedFrom(msg.sender, _vouchers);
        weis = _vouchersToWei(_vouchers);
        msg.sender.transfer(weis);
        
        emit VouchersSold(msg.sender, _vouchers, weis);
    }

    /**
     * @dev Function allows Monetha account to release the purchased vouchers to any address.
     * The released voucher acquires an expiration property and should be used in Monetha ecosystem within 6 months, otherwise
     * it will be returned to shared pool. May be called only by Monetha.
     * @param _to address to release vouchers to.
     * @param _value the amount of vouchers to release.
     */
    function releasePurchasedTo(address _to, uint256 _value) external onlyMonetha returns (bool) {
        require(_value <= purchased[msg.sender], "Insufficient Vouchers");
        require(_to != address(0), "address should be valid");

        _subPurchasedFrom(msg.sender, _value);
        _addVouchers(_to, _value);

        emit PurchasedVouchersReleased(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Function to check the amount of vouchers that an owner (Monetha account) allowed to sell or release to some user.
     * @param owner The address which owns the funds.
     * @return A uint256 specifying the amount of vouchers still available for the owner.
     */
    function purchasedBy(address owner) external view returns (uint256) {
        return purchased[owner];
    }

    /**
     * @dev updates voucherMthRate.
     */
    function updateVoucherMthRate(uint256 _voucherMthRate) external onlyMonetha {
        require(_voucherMthRate > 0, "should be greater than 0");
        require(voucherMthRate != _voucherMthRate, "same as previous value");

        voucherMthRate = _voucherMthRate;
        _updateVoucherMthEthRate();

        emit VoucherMthRateUpdated(voucherMthRate, _voucherMthRate);
    }

    /**
     * @dev updates mthEthRate.
     */
    function updateMthEthRate(uint256 _mthEthRate) external onlyMonetha {
        require(_mthEthRate > 0, "should be greater than 0");
        require(mthEthRate != _mthEthRate, "same as previous value");
        
        mthEthRate = _mthEthRate;
        _updateVoucherMthEthRate();

        emit MthEthRateUpdated(mthEthRate, _mthEthRate);
    }

    function _addPurchasedTo(address _to, uint256 _value) internal {
        purchased[_to] = purchased[_to].add(_value);
        totalPurchased = totalPurchased.add(_value);
    }

    function _subPurchasedFrom(address _from, uint256 _value) internal {
        purchased[_from] = purchased[_from].sub(_value);
        totalPurchased = totalPurchased.sub(_value);
    }

    function _updateVoucherMthEthRate() internal {
        voucherMthEthRate = voucherMthRate.mul(mthEthRate);
    }

    /**
     * @dev Transfer vouchers from shared pool to address. May be called only by Monetha.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function _addVouchers(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "zero address is not allowed");

        uint16 currentHalfYear = _currentHalfYear();
        require(_vouchersInSharedPool(currentHalfYear) >= _value, "must be less or equal than vouchers present in shared pool");

        uint256 oldDist = totalDistributedIn[currentHalfYear];
        totalDistributedIn[currentHalfYear] = oldDist.add(_value);
        uint256 oldBalance = distributed[currentHalfYear][_to];
        distributed[currentHalfYear][_to] = oldBalance.add(_value);

        emit VouchersAdded(_to, _value);

        return true;
    }

    /**
     * @dev Transfer vouchers from address to shared pool
     * @param _from address The address which you want to send vouchers from
     * @param _value uint256 the amount of vouchers to be transferred
     * @return A uint256 specifying the amount of vouchers released to shared pool.
     */
    function _releaseVouchers(address _from, uint256 _value) internal returns (uint256) {
        require(_from != address(0), "must be valid address");

        uint16 currentHalfYear = _currentHalfYear();
        uint256 released = 0;
        if (currentHalfYear > 0) {
            released += _releaseVouchers(_from, _value, currentHalfYear - 1);
            _value = _value.sub(released);
        }
        released += _releaseVouchers(_from, _value, currentHalfYear);

        emit VoucherReleased(_from, released);

        return released;
    }

    function _releaseVouchers(address _from, uint256 _value, uint16 _currentHalfYear) internal returns (uint256) {
        if (_value == 0) {
            return 0;
        }

        uint256 oldBalance = distributed[_currentHalfYear][_from];
        uint256 subtracted = _value;
        if (oldBalance <= _value) {
            delete distributed[_currentHalfYear][_from];
            subtracted = oldBalance;
        } else {
            distributed[_currentHalfYear][_from] = oldBalance.sub(_value);
        }

        uint256 oldDist = totalDistributedIn[_currentHalfYear];
        if (oldDist == subtracted) {
            delete totalDistributedIn[_currentHalfYear];
        } else {
            totalDistributedIn[_currentHalfYear] = oldDist.sub(subtracted);
        }
        return subtracted;
    }

    // converts vouchers to Ether (in wei)
    function _vouchersToWei(uint256 _value) internal view returns (uint256) {
        return _value.mul(RATE_COEFFICIENT2).div(voucherMthEthRate);
    }

    // converts Ether (in wei) to vouchers
    function _weiToVouchers(uint256 _value) internal view returns (uint256) {
        return _value.mul(voucherMthEthRate).div(RATE_COEFFICIENT2);
    }

    // converts MTH tokens to vouchers
    function _mthToVouchers(uint256 _value) internal view returns (uint256) {
        return _value.mul(voucherMthRate).div(RATE_COEFFICIENT);
    }

    // converts Ether (in wei) to MTH
    function _weiToMth(uint256 _value) internal view returns (uint256) {
        return _value.mul(mthEthRate).div(RATE_COEFFICIENT);
    }

    function _totalVouchersSupply() internal view returns (uint256) {
        return _mthToVouchers(mthToken.balanceOf(address(this)));
    }

    function _vouchersInSharedPool(uint16 _currentHalfYear) internal view returns (uint256) {
        return _totalVouchersSupply().sub(_vouchersDistributed(_currentHalfYear)).sub(totalPurchased);
    }

    function _vouchersDistributed(uint16 _currentHalfYear) internal view returns (uint256) {
        uint256 dist = totalDistributedIn[_currentHalfYear];
        if (_currentHalfYear > 0) {
            // include previous half-year
            dist += totalDistributedIn[_currentHalfYear - 1];
        }
        return dist;
    }

    function _distributedTo(address _owner, uint16 _currentHalfYear) internal view returns (uint256) {
        uint256 balance = distributed[_currentHalfYear][_owner];
        if (_currentHalfYear > 0) {
            // include previous half-year
            balance += distributed[_currentHalfYear - 1][_owner];
        }
        return balance;
    }
    
    function _currentHalfYear() internal view returns (uint16) {
        return uint16(now / HALF_YEAR_IN_SECONDS_AVG);
    }
}