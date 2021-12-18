// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityLockerV2 {
    function lockLPToken(
        address token_,
        address curercy_,
        uint256 saleAmount_,
        uint256 baseAmount_,
        uint256 unlock_date_,
        address payable withdrawer_
    ) external payable;

    function pairExists(address token_, address curercy_)
        external
        view
        returns (bool);
}

contract BaseILOV2 is ReentrancyGuard {
    //---------- Libraries ----------//
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    //---------- Contracts ----------//
    IERC20 public TOKEN;
    IERC20 public CURRENCY;
    ILiquidityLockerV2 public LOCKER;

    //---------- Variables ----------//
    EnumerableSet.AddressSet private WHITELIST;
    address public FACTORY;
    address payable public OWNER;
    address public ADMIN;
    bool internal Initialized;

    //---------- Enums -----------//
    enum State {
        NotExist,
        OnSale,
        Completed,
        Failed
    }

    //---------- Storage -----------//
    struct Info {
        uint256 round1Price;
        uint256 round1Max4user;
        uint256 round1Amount;
        uint256 round2Price;
        uint256 round2Max4user;
        uint256 round2Amount;
        uint256 TOTAL_COLLECTED;
        uint256 TOTAL_SOLD;
        uint256 TOTAL_BUYERS;
        State state;
    }

    struct Settings {
        uint256 Hardcap;
        uint256 Softcap;
        uint256 DexRate;
        uint256 Start;
        uint256 End;
        uint256 LockPercent;
        uint256 LockTime;
        bool inMATIC;
        bool Whitelist;
    }

    struct Buyer {
        uint256 bought;
        uint256 owed;
    }

    Info public INFO;
    Settings public SETTINGS;
    mapping(address => Buyer) public BUYERS;
    mapping(address => bool) public CLAIMED;

    //---------- Events -----------//
    event WithdrawLP(uint256 amount);
    event Withdraw(address buyer, uint256 amount);
    event CreatedLP(address LP, uint256 amount);

    //---------- Constructor ----------//
    constructor(address _factory, address _locker) {
        FACTORY = _factory;
        LOCKER = ILiquidityLockerV2(_locker);
    }

    //---------- Modifiers ----------//
    modifier onlyFactory() {
        require(FACTORY == msg.sender);
        _;
    }
    modifier onlyOwner() {
        require(OWNER == msg.sender || ADMIN == msg.sender);
        _;
    }

    //----------- External Functions -----------//
    function init(uint256[13] memory _data) external onlyFactory {
        require(!Initialized);
        INFO.round1Amount = _data[0];
        INFO.round1Price = _data[1];
        INFO.round1Max4user = _data[2];
        INFO.round2Amount = _data[3];
        INFO.round2Price = _data[4];
        INFO.round2Max4user = _data[5];
        SETTINGS.Hardcap = _data[6];
        SETTINGS.Softcap = _data[7];
        SETTINGS.LockPercent = _data[8];
        SETTINGS.DexRate = _data[9];
        SETTINGS.Start = _data[10];
        SETTINGS.End = _data[11];
        SETTINGS.LockTime = _data[12];
    }

    function init2(
        address admin,
        address payable _owner,
        address _token,
        bool inMATIC,
        address _currency
    ) external onlyFactory {
        require(!Initialized);
        INFO.state = State.OnSale;
        OWNER = _owner;
        SETTINGS.inMATIC = inMATIC;
        if (!inMATIC) {
            require(_currency != address(0));
            CURRENCY = IERC20(_currency);
        }
        TOKEN = IERC20(_token);
        ADMIN = admin;
        Initialized = true;
    }

    function status() public view returns (uint256) {
        if (INFO.state == State.Failed) {
            return 3;
        }
        if (
            block.timestamp > SETTINGS.End &&
            INFO.TOTAL_COLLECTED < SETTINGS.Softcap
        ) {
            return 3;
        }
        if (INFO.TOTAL_COLLECTED >= SETTINGS.Hardcap) {
            return 2;
        }
        if (
            block.timestamp > SETTINGS.End &&
            INFO.TOTAL_COLLECTED >= SETTINGS.Softcap
        ) {
            return 2;
        }
        if (
            block.timestamp >= SETTINGS.Start && block.timestamp <= SETTINGS.End
        ) {
            return 1;
        }
        return 0;
    }

    function round() public view returns (uint256) {
        if (INFO.TOTAL_SOLD >= INFO.round1Amount) {
            return 2;
        }
        return 1;
    }

    function remaining4Sale(uint256 round_) public view returns (uint256) {
        if (round_ == 1) {
            return
                (INFO.round1Amount.div(INFO.round1Price) * 1e18).sub(
                    INFO.TOTAL_COLLECTED
                );
        }
        if (round_ == 2) {
            return SETTINGS.Hardcap.sub(INFO.TOTAL_COLLECTED);
        }
        return 0;
    }

    function buy(uint256 amount_) external payable nonReentrant {
        require(status() == 1, "Not active");
        if (SETTINGS.Whitelist) {
            require(WHITELIST.contains(msg.sender), "Not allowed");
        }
        uint256 amount_in = SETTINGS.inMATIC ? msg.value : amount_;
        require(amount_in > 0, "Inlavid amount");
        uint256 currentRound = round();
        Buyer storage b = BUYERS[msg.sender];
        uint256 allowance = currentRound == 1
            ? INFO.round1Max4user
            : INFO.round2Max4user;
        allowance = allowance.sub(b.bought);
        uint256 remaining = remaining4Sale(currentRound);
        allowance = allowance > remaining ? remaining : allowance;
        if (amount_in > allowance) {
            amount_in = allowance;
        }
        if (amount_in > 0) {
            if (!SETTINGS.inMATIC) {
                require(
                    CURRENCY.transferFrom(msg.sender, address(this), amount_in),
                    "Transfer error"
                );
            }
            uint256 tokenPrice = currentRound == 1
                ? INFO.round1Price
                : INFO.round2Price;
            uint256 tokensSold = amount_in.mul(tokenPrice).div(10**18);
            require(tokensSold > 0, "ZERO TOKENS");
            if (b.bought == 0) {
                INFO.TOTAL_BUYERS++;
            }
            b.bought = b.bought.add(amount_in);
            b.owed = b.owed.add(tokensSold);
            INFO.TOTAL_COLLECTED = INFO.TOTAL_COLLECTED.add(amount_in);
            INFO.TOTAL_SOLD = INFO.TOTAL_SOLD.add(tokensSold);
        }
        if (SETTINGS.inMATIC && amount_in < msg.value) {
            payable(msg.sender).transfer(msg.value.sub(amount_in));
        }
    }

    function withdrawTokens() external nonReentrant {
        require(INFO.state == State.Completed, "Not completed");
        require(!CLAIMED[msg.sender], "Already claimed");
        CLAIMED[msg.sender] = true;
        Buyer storage b = BUYERS[msg.sender];
        uint256 tokensOwed = b.owed;
        require(tokensOwed > 0, "Nothing to withdraw");
        TOKEN.transfer(msg.sender, tokensOwed);
    }

    function withdrawCurrency() external nonReentrant {
        require(status() == 3, "Not failed");
        require(!CLAIMED[msg.sender], "Already claimed");
        CLAIMED[msg.sender] = true;
        Buyer storage b = BUYERS[msg.sender];
        uint256 spend = b.bought;
        require(spend > 0, "Nothing to withdraw");
        if (SETTINGS.inMATIC) {
            payable(msg.sender).transfer(spend);
        } else {
            CURRENCY.transfer(msg.sender, spend);
        }
    }

    function ownerWithdrawTokens() external onlyOwner {
        require(status() == 3);
        TOKEN.transfer(OWNER, TOKEN.balanceOf(address(this)));
    }

    function forceFailIfPairExists() external virtual {
        require(INFO.state != State.Completed);
        if (LOCKER.pairExists(address(TOKEN), address(CURRENCY))) {
            INFO.state = State.Failed;
        }
    }

    function forceFail() external onlyOwner {
        require(INFO.state != State.Completed);
        INFO.state = State.Failed;
    }

    function addLiquidity() external nonReentrant {
        require(INFO.state != State.Completed, "GENERATION COMPLETE");
        require(status() == 2, "NOT SUCCESS");
        if (LOCKER.pairExists(address(TOKEN), address(CURRENCY))) {
            INFO.state = State.Failed;
            return;
        }
        uint256 baseLiquidity = INFO
            .TOTAL_COLLECTED
            .mul(SETTINGS.LockPercent)
            .div(1000);
        uint256 tokenLiquidity = baseLiquidity.mul(SETTINGS.DexRate).div(
            10**18
        );
        TOKEN.transfer(address(LOCKER), tokenLiquidity);
        if (address(CURRENCY) != address(0)) {
            CURRENCY.transfer(address(LOCKER), baseLiquidity);
            LOCKER.lockLPToken(
                address(TOKEN),
                address(CURRENCY),
                tokenLiquidity,
                baseLiquidity,
                block.timestamp.add(SETTINGS.LockTime),
                OWNER
            );
            uint256 remainingBaseBalance = CURRENCY.balanceOf(address(this));
            CURRENCY.transfer(OWNER, remainingBaseBalance);
        } else {
            LOCKER.lockLPToken{value: baseLiquidity}(
                address(TOKEN),
                address(CURRENCY),
                tokenLiquidity,
                baseLiquidity,
                block.timestamp.add(SETTINGS.LockTime),
                OWNER
            );
            uint256 remainingBaseBalance = address(this).balance;
            OWNER.transfer(remainingBaseBalance);
        }

        uint256 remainingSBalance = TOKEN.balanceOf(address(this));
        if (remainingSBalance > INFO.TOTAL_SOLD) {
            uint256 burnAmount = remainingSBalance.sub(INFO.TOTAL_SOLD);
            TOKEN.transfer(
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );
        }

        INFO.state = State.Completed;
    }

    function setWhitelist(bool set_) external onlyOwner {
        SETTINGS.Whitelist = set_;
    }

    function editWhitelist(address[] memory _users, bool _add)
        external
        onlyOwner
    {
        if (_add) {
            for (uint256 i = 0; i < _users.length; i++) {
                WHITELIST.add(_users[i]);
            }
        } else {
            for (uint256 i = 0; i < _users.length; i++) {
                WHITELIST.remove(_users[i]);
            }
        }
    }

    function setMax4Buyer(uint256 _round1, uint256 _round2) external onlyOwner {
        require(_round1 > 0 && _round2 > 0);
        INFO.round1Max4user = _round1;
        INFO.round2Max4user = _round2;
    }

    function getWhitelistLength() external view returns (uint256) {
        return WHITELIST.length();
    }

    function whitelistAt(uint256 index_) external view returns (address) {
        return WHITELIST.at(index_);
    }

    function getUserWhitelistStatus(address _user)
        external
        view
        returns (bool)
    {
        return WHITELIST.contains(_user);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseILOV2.sol";

contract FactoryILOV2 is Ownable {   
    //---------- Libraries ----------//
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    //---------- Variables ----------//
    EnumerableSet.AddressSet private ILOS_INDEX;  
    address public LOCKER;

    //---------- Storage -----------//
    struct Request {
        uint256 amount;
        uint256 tokenPrice;
        uint256 maxSpendPerBuyer;
        uint256 amount2;
        uint256 tokenPrice2;
        uint256 maxSpendPerBuyer2;
        uint256 hardcap;
        uint256 softcap;
        uint256 liquidityPercent;
        uint256 listingRate; 
        uint256 startTime;
        uint256 endTime;
        uint256 lockPeriod;
    }

    //---------- Constructor ----------//
    constructor(address locker_) {
        LOCKER = locker_;
    }

    //----------- External Functions -----------//
    function calculateAmountRequired (uint256 _amount, uint256 _tokenPrice, uint256 _amount2, uint256 _tokenPrice2, uint256 _listingRate, uint256 _liquidityPercent) public pure returns (uint256) {
        uint256 listingRatePercent = _listingRate.mul(1000).div(_tokenPrice);
        uint256 listingRatePercent2 = _listingRate.mul(1000).div(_tokenPrice2);
        uint256 liquidityRequired = _amount.mul(_liquidityPercent).mul(listingRatePercent).div(1000000);
        uint256 liquidityRequired2 = _amount2.mul(_liquidityPercent).mul(listingRatePercent2).div(1000000);
        uint256 tokensRequiredForPresale = _amount.add(liquidityRequired);
        uint256 tokensRequiredForPresale2 = _amount2.add(liquidityRequired2);
        return tokensRequiredForPresale.add(tokensRequiredForPresale2);
    }

    function createILO(
      address _presaleOwner,
      address _presaleToken,
      bool _inMatic,
      address _currencyToken,
      uint256[13] memory uint_params
      ) external onlyOwner {   
        Request memory r;
        r.amount = uint_params[0];
        r.tokenPrice = uint_params[1];
        r.maxSpendPerBuyer = uint_params[2];
        r.amount2 = uint_params[3];
        r.tokenPrice2 = uint_params[4];
        r.maxSpendPerBuyer2 = uint_params[5];
        r.hardcap = uint_params[6];
        r.softcap = uint_params[7];
        r.liquidityPercent = uint_params[8];
        r.listingRate = uint_params[9];
        r.startTime = uint_params[10];
        r.endTime = uint_params[11];
        r.lockPeriod = uint_params[12];        
        if (r.lockPeriod < 4 weeks) {  
            r.lockPeriod = 4 weeks;
        }                    
        require(r.amount >= 10000); 
        require(r.endTime.sub(r.startTime) <= 1209600);
        require(r.softcap < r.hardcap);
        require(r.liquidityPercent >= 300 && r.liquidityPercent <= 1000);        
        uint256 tokensRequiredForPresale = calculateAmountRequired(r.amount, r.tokenPrice, r.amount2, r.tokenPrice2, r.listingRate, r.liquidityPercent);      
        BaseILOV2 newILO = new BaseILOV2(address(this), LOCKER);
        require(IERC20(_presaleToken).transferFrom(msg.sender, address(newILO), tokensRequiredForPresale), "Transfer tokens error");
        newILO.init([r.amount, r.tokenPrice, r.maxSpendPerBuyer, r.amount2, r.tokenPrice2, r.maxSpendPerBuyer2, r.hardcap, r.softcap, 
        r.liquidityPercent, r.listingRate, r.startTime, r.endTime, r.lockPeriod]);
        newILO.init2(owner(), payable(_presaleOwner), _presaleToken, _inMatic, _currencyToken);
        ILOS_INDEX.add(address(newILO));
    }

    function isILO(address _iloAddress) external view returns (bool) {
        return ILOS_INDEX.contains(_iloAddress);
    }
    
    function ilosLength() external view returns (uint256) {
        return ILOS_INDEX.length();
    }
    
    function iloAtIndex(uint256 _index) external view returns (address) {
        return ILOS_INDEX.at(_index);
    }

    function setILO(address ilo_, bool add_) external onlyOwner {
        if(add_) {
            ILOS_INDEX.add(ilo_);
        } else {
            ILOS_INDEX.remove(ilo_);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}