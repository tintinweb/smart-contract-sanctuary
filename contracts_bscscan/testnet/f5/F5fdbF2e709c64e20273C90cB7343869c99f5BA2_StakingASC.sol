// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../common/ERC20MintBurn.sol";
import "../interface/IPoolManager.sol";
import "../common/Ownable.sol";

contract ASC is ERC20MintBurn, Ownable {

    //****************
    // META DATA
    //****************
    string public override name = "AS Coin";
    string public override symbol = "ASC";
    uint8 public constant override decimals = 18;

    IPoolManager public ipm;

    //****************
    // MODIFIES
    //****************
    modifier onlyPools() {
        require(ipm.pools(msg.sender) == true, "Only pools!");
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint256 _premint, address _owner) Ownable(_owner) {
        _mint(owner(), _premint);
    }


    // ------------------------------------------------------------------------
    // Called by pools, mint new ASC
    // ------------------------------------------------------------------------
    function poolMint(address to, uint256 amount) public onlyPools {
        super._mint(to, amount);
        emit ASCMinted(msg.sender, to, amount);
    }


    // ------------------------------------------------------------------------
    // Called by pools, burn ASC
    // ------------------------------------------------------------------------
    function poolBurnFrom(address from, uint256 amount) public onlyPools {
        super._burnFrom(from, amount);
        emit ASCBurned(from, msg.sender, amount);
    }
    

    // ------------------------------------------------------------------------
    // Set ipm
    // ------------------------------------------------------------------------
    function setPoolManager(address _poolManager) public onlyOwner {
        ipm = IPoolManager(_poolManager);
    }


    //****************
    // EVENTS
    //****************
    event ASCMinted(address indexed from, address indexed to, uint256 amount);
    event ASCBurned(address indexed from, address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../common/ERC20MintBurn.sol";
import "../interface/IPoolManager.sol";
import "../common/Ownable.sol";

contract CRS is ERC20MintBurn, Ownable {


    //****************
    // META DATA
    //****************
    string public override name = "Ceres";
    string public override symbol = "CRS";
    uint8 public constant override decimals = 18;
    
    IPoolManager public ipm;

    //****************
    // MODIFIES
    //****************
    modifier onlyPools() {
        require(ipm.pools(msg.sender) == true, "Only pools!");
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint256 _premint, address _owner) Ownable(_owner) {
        _mint(owner(), _premint);
    }


    // ------------------------------------------------------------------------
    // Called by pools, mint new CRS
    // ------------------------------------------------------------------------
    function poolMint(address to, uint256 amount) public onlyPools {
        super._mint(to, amount);
        emit CRSMinted(msg.sender, to, amount);
    }


    // ------------------------------------------------------------------------
    // Called by pools, burn CRS
    // ------------------------------------------------------------------------
    function poolBurnFrom(address from, uint256 amount) public onlyPools {
        super._burnFrom(from, amount);
        emit CRSBurned(from, msg.sender, amount);
    }
    

    // ------------------------------------------------------------------------
    // Set ipm
    // ------------------------------------------------------------------------
    function setPoolManager(address _poolManager) public onlyOwner {
        ipm = IPoolManager(_poolManager);
    }


    //****************
    // EVENTS
    //****************
    event CRSMinted(address indexed from, address indexed to, uint256 amount);
    event CRSBurned(address indexed from, address indexed to, uint256 amount);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/IOracle.sol";
import "../interface/IChainlink.sol";
import "../common/Ownable.sol";
import "../common/Governable.sol";

contract CeresAnchor is Ownable, Governable {
    
    enum Coin {ASC, CRS}

    //****************
    // PRICER
    //****************
    address public busdAddress;

    IChainlink public busdChainlink;
    uint8 public busdPriceDecimals;

    IOracle public ascBusdOracle;
    IOracle public crsBusdOracle;

    //****************
    // SYSTEM PARAMS
    //****************
    uint256 public collateralRatio; // collateral ratio of asc
    uint256 public lastUpdateTime; // last time update ratio
    uint256 public ratioStep; // step that collateral rate changes every time
    uint256 public priceBand; // threshold of automint / autoredeem
    uint256 public updateCooldown; // cooldown between raito changes 

    uint256 public constant CERES_PRECISION = 1e6;  // 1000000 <=> 1 integer
    uint256 public constant PRICE_TARGET = 1e6;  // 1:1 to USD
    uint256 public seignioragePercent = 5000;

    //****************
    // COEFFICIENT
    //****************
    uint256 public CiRate;
    uint256 public Cp;
    uint256 public Vp;


    //****************
    // MODIFIES
    //****************
    modifier onlyGovernance() {
        require(msg.sender == owner() || msg.sender == timelock() || msg.sender == controller(), "Only Governance!");
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner) Ownable(_owner){
        
        collateralRatio = 850000;
        ratioStep = 2500;
        priceBand = 5000;
        updateCooldown = 3600;

        CiRate = 50000;
        Cp = 1000000;
        Vp = 500000;
    }


    // ------------------------------------------------------------------------
    // Update collateral ratio according to ASC/USD price in current
    // ------------------------------------------------------------------------
    function updateCollateralRatio() public {
        uint256 ascPrice = getASCPrice();
        require(block.timestamp - lastUpdateTime >= updateCooldown, "Wait after cooldown!");

        if (ascPrice > PRICE_TARGET + priceBand) {
            // decrease collateral ratio, minimum to 0
            if (collateralRatio <= ratioStep)
                collateralRatio = 0;
            else
                collateralRatio -= ratioStep;
        } else if (ascPrice < PRICE_TARGET - priceBand) {
            // increase collateral ratio, maximum to 1000000, i.e 100% in CERES_PRECISION
            if (collateralRatio + ratioStep >= 1000000)
                collateralRatio = 1000000;
            else
                collateralRatio += ratioStep;
        }

        // update last time
        lastUpdateTime = block.timestamp;
    }

    // ------------------------------------------------------------------------
    // Setting of system of params
    // ------------------------------------------------------------------------
    function setRatioStep(uint256 newStep) public onlyGovernance {
        ratioStep = newStep;
    }

    function setUpdateCooldown(uint256 newCooldown) public onlyGovernance {
        updateCooldown = newCooldown;
    }

    function setPriceBand(uint256 newBand) public onlyGovernance {
        priceBand = newBand;
    }

    function setCollateralRatio(uint256 newRatio) public onlyGovernance {
        collateralRatio = newRatio;
    }

    function setSeignioragePercent(uint256 newPercent) public onlyGovernance {
        seignioragePercent = newPercent;
    }

    function setCiRate(uint256 newCiRate) public onlyGovernance {
        collateralRatio = newCiRate;
    }

    function setCp(uint256 newCp) public onlyGovernance {
        collateralRatio = newCp;
    }

    function setVp(uint256 newVp) public onlyGovernance {
        collateralRatio = newVp;
    }

    function setController(address newController) public onlyOwner {
        _setController(newController);
    }

    function setTimelock(address newTimelock) public onlyOwner {
        _setTimelock(newTimelock);
    }

    // ------------------------------------------------------------------------
    // Setting of oracles
    // ------------------------------------------------------------------------
    function setAscBusdOracle(address oracleAddr) public onlyGovernance {
        ascBusdOracle = IOracle(oracleAddr);
    }

    function setCrsBusdOracle(address oracleAddr) public onlyGovernance {
        crsBusdOracle = IOracle(oracleAddr);
    }

    function setBusdChainLink(address chainlinkAddress) public onlyGovernance {
        busdChainlink = IChainlink(chainlinkAddress);
        busdPriceDecimals = busdChainlink.getDecimals();
    }

    function setBusdAddress(address newAddress) public onlyGovernance {
        busdAddress = newAddress;
    }
    
    // ------------------------------------------------------------------------
    // Get ASC price in USD
    // ------------------------------------------------------------------------
    function getASCPrice() public view returns (uint256) {
        return oraclePrice(Coin.ASC);
    }

    // ------------------------------------------------------------------------
    // Get CRS price in USD
    // ------------------------------------------------------------------------
    function getCRSPrice() public view returns (uint256) {
        return oraclePrice(Coin.CRS);
    }

    // ------------------------------------------------------------------------
    // Get ASC price in USD
    // ------------------------------------------------------------------------
    function getBUSDPrice() public view returns (uint256) {
        return uint256(busdChainlink.getLatestPrice()) * (CERES_PRECISION) / (uint256(10) ** busdPriceDecimals);
    }

    // ------------------------------------------------------------------------
    // Get coin price in USD - internal
    // ------------------------------------------------------------------------
    function oraclePrice(Coin choice) internal view returns (uint256) {
        // get BUSD price in USD
        uint256 busdPriceInUSD = uint256(busdChainlink.getLatestPrice()) * (CERES_PRECISION) / (uint256(10) ** busdPriceDecimals);

        uint256 priceVsBusd;

        if (choice == Coin.ASC) {
            priceVsBusd = uint256(ascBusdOracle.consult(busdAddress, CERES_PRECISION));
        } else if (choice == Coin.CRS) {
            priceVsBusd = uint256(crsBusdOracle.consult(busdAddress, CERES_PRECISION));
        }

        else revert("INVALID COIN!");

        // return in 1e6 format
        return busdPriceInUSD * CERES_PRECISION / priceVsBusd;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "../common/Context.sol";
import "../interface/IERC20.sol";
import "../library/SafeMath.sol";


// Due to compiling issues, _name, _symbol, and _decimals were removed


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20MintBurn is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic governing control mechanism, where
 * there is an governing account that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governing account will be empty. This
 * can later be changed by governor or owner.
 *
 */
abstract contract Governable is Context {
    
    address internal _controller;
    address internal _timelock;

    event ControllerTransferred(address indexed previousController, address indexed newController);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);
    
    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }
    
    /**
     * @dev Returns the address of the current timelock.
     */
    function timelock() public view virtual returns (address) {
        return _timelock;
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(controller() == _msgSender(), "Controller: caller is not the controller");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the timelock.
     */
    modifier onlyTimelock() {
        require(timelock() == _msgSender(), "Timelock: caller is not the timelock");
        _;
    }

    /**
     * @dev Transfers controller of the contract to a new account
     * Can only be called by the current controller.
     */
    function transferController(address newController) public virtual onlyController {
        require(newController != address(0), "Controller: new controller is the zero address");
        _setController(newController);
    }

    /**
    * @dev Leaves the contract without controller. It will not be possible to call
     * `onlyController` functions anymore. Can only be called by the current owner.
     */
    function renounceController() public virtual onlyController {
        _setController(address(0));
    }

    function _setController(address newController) internal {
        address old = _controller;
        _controller = newController;
        emit ControllerTransferred(old, newController);
    }
    
    /**
     * @dev Transfers timelock of the contract to a new account
     * Can only be called by the current timelock.
     */
    function transferTimelock(address newTimelock) public virtual onlyTimelock {
        require(newTimelock != address(0), "Timelock: new timelock is the zero address");
        _setTimelock(newTimelock);
    }
    
    /**
    * @dev Leaves the contract without timelock. It will not be possible to call
     * `onlyTimelock` functions anymore. Can only be called by the current owner.
     */
    function renounceTimelock() public virtual onlyTimelock {
        _setTimelock(address(0));
    }

    function _setTimelock(address newTimelock) internal {
        address old = _timelock;
        _timelock = newTimelock;
        emit TimelockTransferred(old, newTimelock);
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
    constructor(address _owner_) {
        _setOwner(_owner_);
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
        require(owner() == _msgSender(), "Only Owner!");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlink {

    function getLatestPrice() external view returns (int);

    function getDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     * metadata functions - name
     */
    function name() external view returns (string memory);


    /**
     * metadata functions - symbol
     */
    function symbol() external view returns (string memory);

    /**
     * metadata functions - decimals
     */
    function decimals() external view returns (uint8);
    

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
pragma solidity ^0.8.4;
import "./IPool.sol";

interface IMinter is IPool{

    function notifyMint(uint256 ascAmount, uint256 collateralAmount) external;

    function claimMintWithPercent(uint256 percent) external;

    function reinvestMint() external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {

    function consult(address token, uint amountIn) external view returns (uint amountOut);

    function update() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPool {

    function collateralBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoolManager {

    function pools(address sender) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRedeemer {

    function notifyRedeem(uint256 ascAmount, uint256 collateral0Amount, uint256 collateral1Amount) external;

    function claimRedeemWithPercent(uint256 percent) external;

    function reinvestRedeem() external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IReferral {

    function record(address user, address referral) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking {

    struct UserLock {
        uint256 shareAmount;
        uint256 timeEnd;
    }

    // Views
    function totalStaking() external view returns (uint256);

    function stakingBalanceOf(address account) external view returns (uint256);
    
    function totalShare() external view returns (uint256);

    function shareBalanceOf(address account) external view returns (uint256);

    function yieldAPR() external view returns (uint256);
    
    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 shareAmount) external;

    function withdrawAll(uint256 shareAmount) external;

    function reinvestReward() external;
    
    function notifyReinvest(address account, uint256 amount) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingManager {

    function stakings(address sender) external view returns (bool);

    function stakingAddress(address staingToken) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interface/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }

    /**
    * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interface/IStaking.sol";
import "../common/Pausable.sol";
import "../library/SafeMath.sol";
import "../library/SafeERC20.sol";
import "../asset/CRS.sol";
import "../asset/ASC.sol";
import "../autopool/CeresAnchor.sol";
import "../interface/IReferral.sol";
import "../interface/IStakingManager.sol";

abstract contract Staking is IStaking, ReentrancyGuard, Pausable, Ownable, Governable {

    using SafeMath for uint256;

    //****************
    // METADATA
    //****************
    CRS public coinCRS;
    address public crsAddress;

    ASC public coinASC;
    address public ascAddress;

    IPoolManager public ipm;
    
    IStakingManager public ism;
    
    IReferral public iReferal;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 365 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;

    uint256 public shareUnusedRatio = 1e10;
    uint256 public lockTime = 3 days;
    mapping(address => UserLock) public userLocks;

    mapping(address => uint256) public userRewardPerSharePaid;
    mapping(address => uint256) public rewards;

    uint256 internal _totalStaking;
    uint256 internal _totalShare;
    mapping(address => uint256) internal _shareBalances;

    CeresAnchor public ceresAnchor;

    uint256 public constant CERES_PRECISION = 1e6;
    uint256 public constant SHARE_PRECISION = 1e10;

    //****************
    // MODIFIES
    //****************
    modifier onlyGovernance() {
        require(msg.sender == owner() || msg.sender == timelock() || msg.sender == controller(), "Only Governance!");
        _;
    }
    
    modifier onlyPools() {
        require(ipm.pools(msg.sender) == true, "Only pools!");
        _;
    }

    modifier onlyStakings() {
        require(ism.stakings(msg.sender) == true, "Only staking!");
        _;
    }

    modifier updateReward(address account) {
        rewardPerShareStored = rewardPerShare();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerSharePaid[account] = rewardPerShareStored;
        }
        _;
    }

    // ------------------------------------------------------------------------
    // Setters
    // ------------------------------------------------------------------------
    function setCeresAnchor(address anchorAddress) public onlyGovernance {
        ceresAnchor = CeresAnchor(anchorAddress);
    }
    
    function setLockTime(uint256 _lockTime) public onlyGovernance {
        lockTime = _lockTime;
    }

    function setController(address newController) public onlyOwner {
        _setController(newController);
    }

    function setTimelock(address newTimelock) public onlyOwner {
        _setTimelock(newTimelock);
    }

    function setPoolManager(address _poolManager) public onlyGovernance {
        ipm = IPoolManager(_poolManager);
    }

    function setStakingManager(address _stakingManager) public onlyGovernance {
        ism = IStakingManager(_stakingManager);
    }
    
    function setIReferral(address _iReferral) public onlyGovernance {
        iReferal = IReferral(_iReferral);
    }

    
    // ------------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------------
    function totalStaking() public override view returns (uint256) {
        return _totalStaking;
    }

    function stakingBalanceOf(address account) public override view returns (uint256) {
        if (_totalShare > 0)
            return shareBalanceOf(account) * _totalStaking / _totalShare;
        else
            return 0;
    }

    function totalShare() public override view returns (uint256) {
        return _totalShare;
    }

    function shareBalanceOf(address account) public override view returns (uint256) {
        return _shareBalances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerShare() public view returns (uint256) {
        if (_totalShare == 0) {
            return rewardPerShareStored;
        }
        return
        rewardPerShareStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalShare)
        );
    }

    function earned(address account) public view returns (uint256) {
        return _shareBalances[account].mul(rewardPerShare().sub(userRewardPerSharePaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function availableShareOf(address account) public view returns (uint256) {

        if (userLocks[account].timeEnd > block.timestamp)
            return _shareBalances[account] - userLocks[account].shareAmount;
        else
            return _shareBalances[account];
    }

    // ------------------------------------------------------------------------
    // Stake - interal
    // ------------------------------------------------------------------------
    function _stake(address account, uint256 amount) internal {

        // stake increase
        _totalStaking += amount;

        // update lock
        uint256 userShare = amount * SHARE_PRECISION / shareUnusedRatio;
        _updateLock(account, userShare);

        // share increase
        _totalShare += userShare;
        _shareBalances[account] += userShare;

        emit Staked(account, amount);
    }


    function stake(uint256 amount) public override virtual;
    
    
    // ------------------------------------------------------------------------
    // User stake with referral
    // ------------------------------------------------------------------------
    function stakeWithReferral(uint256 amount, address referer) external {
        require(msg.sender != referer, "Referer can't be yourself!");
        stake(amount);
        iReferal.record(msg.sender, referer);
    }

    
    // ------------------------------------------------------------------------
    // Update user lock - interal
    // ------------------------------------------------------------------------
    function _updateLock(address account, uint256 shareAmount) internal {

        UserLock memory _userLock = userLocks[account];
        if (_userLock.timeEnd > 0 && _userLock.timeEnd <= block.timestamp)
            userLocks[account].shareAmount = shareAmount;
        else
            userLocks[account].shareAmount += shareAmount;

        userLocks[account].timeEnd = block.timestamp + lockTime;

        emit Staked(account, shareAmount);
    }

    // ------------------------------------------------------------------------
    // Reinvest staking reward by user
    // ------------------------------------------------------------------------
    function reinvestReward() public virtual override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            address stakingCRS = ism.stakingAddress(crsAddress);
            if (stakingCRS != address(this))
                SafeERC20.safeTransfer(coinCRS, stakingCRS, reward);
            IStaking(stakingCRS).notifyReinvest(msg.sender, reward);
        }
    }

    // ------------------------------------------------------------------------
    // Get staking reward by percent 1-100
    // ------------------------------------------------------------------------
    function claimRewardWithPercent(uint256 percent) public virtual nonReentrant updateReward(msg.sender) {
        require(percent > 0 && percent <= 100, "percent wrong");
        uint256 reward = rewards[msg.sender] * percent / 100;
        if (reward > 0) {
            rewards[msg.sender] -= reward;
            SafeERC20.safeTransfer(coinCRS, msg.sender, reward);
            emit RewardPaid(msg.sender, percent);
        }
    }

    // ------------------------------------------------------------------------
    // Notify after reward transferred
    // ------------------------------------------------------------------------
    function notifyRewardAmount(uint256 reward) external virtual onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = coinCRS.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }


    // ------------------------------------------------------------------------
    // Set durtaion
    // ------------------------------------------------------------------------
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    //****************
    // EVENTS
    //****************
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 percent);
    event RewardsDurationUpdated(uint256 newDuration);

    event MintPaid(address indexed user, uint256 percent);
    event RedeemPaid(address indexed user, uint256 percent);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Staking.sol";
import "../library/SafeERC20.sol";
import "../interface/IRedeemer.sol";
import "../interface/IMinter.sol";

contract StakingASC is Staking, IRedeemer {

    IERC20 public BUSD;
    address public busdAddress;

    uint256 public redeemPerShareStoredCRS;
    uint256 public redeemPerShareStoredBUSD;

    mapping(address => uint256) public userRedeemPerSharePaidCRS;
    mapping(address => uint256) public userRedeemPerSharePaidBUSD;

    mapping(address => uint256) public redeemsCRS;
    mapping(address => uint256) public redeemsBUSD;

    uint256 public lastRedeemAmountCRS;
    uint256 public lastRedeemAmountBUSD;


    //****************
    // MODIFIES
    //****************
    modifier updateRedeem(address account){
        redeemsCRS[account] = redeemEarnedCRS(account);
        redeemsBUSD[account] = redeemEarnedBUSD(account);
        userRedeemPerSharePaidCRS[account] = redeemPerShareStoredCRS;
        userRedeemPerSharePaidBUSD[account] = redeemPerShareStoredBUSD;
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address busd, address asc, address crs, address _owner) Ownable(_owner){

        BUSD = IERC20(busd);
        busdAddress = busd;
        coinASC = ASC(asc);
        ascAddress = asc;
        coinCRS = CRS(crs);
        crsAddress = crs;
    }


    // ------------------------------------------------------------------------
    // User redeem amount - CRS
    // ------------------------------------------------------------------------
    function redeemEarnedCRS(address account) public view returns (uint256) {
        return _shareBalances[account] * (redeemPerShareStoredCRS - userRedeemPerSharePaidCRS[account])
        / 1e18 + redeemsCRS[account];
    }


    // ------------------------------------------------------------------------
    // User redeem amount - BUSD
    // ------------------------------------------------------------------------
    function redeemEarnedBUSD(address account) public view returns (uint256) {
        return _shareBalances[account] * (redeemPerShareStoredBUSD - userRedeemPerSharePaidBUSD[account])
        / 1e18 + redeemsBUSD[account];
    }


    // ------------------------------------------------------------------------
    // Notify auto redeem
    // ------------------------------------------------------------------------
    function notifyRedeem(uint256 ascAmount, uint256 crsAmount, uint256 busdAmount) public override onlyPools {

        if (ascAmount > 0) {

            coinASC.burn(ascAmount);

            uint256 leftRatio = (_totalStaking - ascAmount) * SHARE_PRECISION / _totalStaking;
            uint256 newUnusedRatio = shareUnusedRatio * leftRatio / SHARE_PRECISION;
            if (newUnusedRatio > 0)
                shareUnusedRatio = newUnusedRatio;

            _totalStaking -= ascAmount;
        }

        if (crsAmount > 0) {
            lastRedeemAmountCRS = crsAmount;
            redeemPerShareStoredCRS += crsAmount * 1e18 / _totalShare;
        }
        if (busdAmount > 0) {
            lastRedeemAmountBUSD = busdAmount;
            redeemPerShareStoredBUSD += busdAmount * 1e18 / _totalShare;
        }

    }


    // ------------------------------------------------------------------------
    // User stake
    // ------------------------------------------------------------------------
    function stake(uint256 amount) public override nonReentrant whenNotPaused updateReward(msg.sender) updateRedeem(msg.sender) {
        require(amount > 0, "cannot stake 0");

        SafeERC20.safeTransferFrom(coinASC, msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }


    // ------------------------------------------------------------------------
    // Reinvest mint & reward
    // ------------------------------------------------------------------------
    function reinvestAll() external {
        reinvestRedeem();
        reinvestReward();
    }


    // ------------------------------------------------------------------------
    // Reinvest mint
    // ------------------------------------------------------------------------
    function reinvestRedeem() public override nonReentrant updateRedeem(msg.sender) {

        uint256 redeemBUSD = redeemsBUSD[msg.sender];
        if (redeemBUSD > 0) {
            redeemsBUSD[msg.sender] = 0;
            address stakingBUSD = ism.stakingAddress(busdAddress);
            SafeERC20.safeTransfer(BUSD, stakingBUSD, redeemBUSD);
            IStaking(stakingBUSD).notifyReinvest(msg.sender, redeemBUSD);
        }

        uint256 redeemCRS = redeemsCRS[msg.sender];
        if (redeemCRS > 0) {
            redeemsCRS[msg.sender] = 0;
            address stakingCRS = ism.stakingAddress(crsAddress);
            SafeERC20.safeTransfer(coinCRS, stakingCRS, redeemCRS);
            IStaking(stakingCRS).notifyReinvest(msg.sender, redeemCRS);
        }
    }


    // ------------------------------------------------------------------------
    // Notify user stake change
    // ------------------------------------------------------------------------
    function notifyReinvest(address account, uint256 amount) external override updateReward(account) updateRedeem(account) onlyStakings {
        require(_totalStaking + amount <= coinASC.balanceOf(address(this)), "Notify amount exceeds balance!");

        if (amount > 0)
            _stake(account, amount);
    }


    // ------------------------------------------------------------------------
    // User withdraw by shareAmount
    // ------------------------------------------------------------------------
    function withdrawAll(uint256 shareAmount) external override {

        uint256 percent = shareAmount * 100 / availableShareOf(msg.sender);
        withdraw(shareAmount);
        claimRewardWithPercent(percent);
        claimRedeemWithPercent(percent);
    }


    function withdraw(uint256 shareAmount) public override nonReentrant updateReward(msg.sender) updateRedeem(msg.sender) {
        require(shareAmount > 0 && shareAmount <= availableShareOf(msg.sender), "your share balance is not enough!");

        uint256 withdrawAmount = shareAmount * _totalStaking / _totalShare;
        _totalStaking -= withdrawAmount;

        _totalShare -= shareAmount;
        _shareBalances[msg.sender] -= shareAmount;

        SafeERC20.safeTransfer(coinASC, msg.sender, withdrawAmount);
        emit Withdrawn(msg.sender, shareAmount);
    }


    // ------------------------------------------------------------------------
    // Claim redeem reward by percent 1-100
    // ------------------------------------------------------------------------
    function claimRedeemWithPercent(uint256 percent) public override nonReentrant updateRedeem(msg.sender) {
        require(percent > 0 && percent <= 100, "percent wrong");
        uint256 redeemCRS = redeemsCRS[msg.sender] * percent / 100;
        uint256 redeemBUSD = redeemsBUSD[msg.sender] * percent / 100;

        if (redeemCRS > 0) {
            redeemsCRS[msg.sender] -= redeemCRS;
            SafeERC20.safeTransfer(coinCRS, msg.sender, redeemCRS);
        }
        if (redeemBUSD > 0) {
            redeemsBUSD[msg.sender] -= redeemBUSD;
            SafeERC20.safeTransfer(BUSD, msg.sender, redeemBUSD);
        }
        emit RedeemPaid(msg.sender, percent);
    }


    // ------------------------------------------------------------------------
    // Get yield APR
    // ------------------------------------------------------------------------
    function yieldAPR() public override view returns (uint256){
        if (_totalStaking > 0)
            return rewardRate * 31536000 * ceresAnchor.getCRSPrice() * CERES_PRECISION / _totalStaking / ceresAnchor.getASCPrice();
        else
            return 999999999999;
    }

    // ------------------------------------------------------------------------
    // Reverse pause
    // ------------------------------------------------------------------------
    function reversePause() external onlyOwner {
        if (paused())
            _unpause();
        else
            _pause();
    }


}