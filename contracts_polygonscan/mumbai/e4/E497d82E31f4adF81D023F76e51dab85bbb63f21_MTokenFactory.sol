/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


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
    constructor () {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/interfaces/MTokenFactoryInterface.sol


pragma solidity 0.8.0;


/**
 * @title Marble Coin Register Interface
 * @dev describes all externaly accessible functions neccessery to run Marble Auctions
 */
interface MTokenFactoryInterface {


  /**
  * @dev Create mToken with provided name.
  * @param _mTokenName Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
  */
  function createMToken(
    string calldata _mTokenName, string calldata _mTokenSymbol
  )
   external returns(address);

  /**
  * @dev Event emited when a new MTokenRegister contract is set
  * @param mTokenContract Contract of newly created MToken contract
  */
  event MTokenCreated(address mTokenContract);

}

// File: contracts/interfaces/MTokenRegisterInterface.sol


pragma solidity 0.8.0;




/**
 * @title Marble Coin Register Interface
 * @dev describes all externaly accessible functions neccessery to run Marble Auctions
 */
interface MTokenRegisterInterface {

  /**
  * @dev Create mToken with provided name.
  * @param _mTokenName Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
  * @param _mTokenSymbol Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
  */
  function createMToken(
    string calldata _mTokenName, string calldata _mTokenSymbol
  )
   external
   returns(uint256 index);


  /**
  * @dev Add new contract as registered one.
  */
  function totalRegistered()
   external 
   view 
   returns (uint256 mtokensRegisteredCount);

  
  /**
  * @dev Event emited when a new MToken is created and added to register
  * @param mTokenContract Address of new MToken contract
  */
  event MTokenRegistered(address mTokenContract, uint256 creationPrice, uint256 initialReserveCurrencySupply);
}

// File: contracts/bancor/IBancorFormula.sol

// License: Apache License v2.0
// copied from: https://github.com/bancorprotocol/contracts-solidity/blob/master/solidity/contracts/converter/interfaces/IBancorFormula.sol
pragma solidity ^0.8.0;

/*
    Bancor Formula interface
*/
interface IBancorFormula {
    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function crossReserveTargetAmount(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function fundSupplyAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function balancedWeights(
        uint256 _primaryReserveStakedBalance,
        uint256 _primaryReserveBalance,
        uint256 _secondaryReserveBalance,
        uint256 _reserveRateNumerator,
        uint256 _reserveRateDenominator
    ) external view returns (uint32, uint32);
}

// File: contracts/Memecoin.sol


pragma solidity 0.8.0;





/**
* @title Memecoin token
* @dev main ERC20 currency for meme.com contracts
*/
contract Memecoin is Ownable, Pausable, ERC20 {

  constructor(uint256 _totalSupply, string memory _memeTokenName, string memory _memeTokenSymbol) ERC20(_memeTokenName, _memeTokenSymbol)
  {
    _mint(msg.sender, _totalSupply);
  }

  /**
  * @dev See {ERC20-transfer}.
  * - adds trasfer only when contract is not paused 
  */
  function transfer(address recipient, uint256 amount) 
    public 
    virtual 
    override 
    whenNotPaused 
    returns (bool) 
  {
    return super.transfer(recipient, amount);
  }

  /**
  * @dev See {ERC20-transferFrom}.
  * - adds trasferForm only when contract is not paused
  */
  function transferFrom(address from, address to, uint256 value) 
    public 
    virtual 
    override 
    whenNotPaused 
    returns (bool) 
  {
    return super.transferFrom(from, to, value);
  }

  /**
  * @dev Allows address to burn a number of coins in its ownership
  * @param _amount Amount of coins to burn
  */
  function burn(uint256 _amount) 
    virtual
    external 
    whenNotPaused
  {    
    _burn(msg.sender, _amount);
  }

  /**
  * @dev Pause contract
  */
  function pause()
    external
    onlyOwner
  {
    _pause();
  }

  /**
  * @dev Unpoause contract 
  */
  function unpause()
    external
    onlyOwner
  {
    _unpause();     
  }
}

// File: contracts/interfaces/MTokenInitialSettingInterface.sol


pragma solidity 0.8.0;



/// @title MTokenInitialSettingInterface
/// @dev Contract providing initial setting for creation of MToken contracts
interface MTokenInitialSettingInterface {

  /**
  * @dev Event emited when MToken creation price change
  * @param newPrice new price of MToken creation
  * @param oldPrice old price of MToken creation
  */
  event CreationPriceChanged(uint256 newPrice, uint256 oldPrice);

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newInitialSupplyOfReserveCurrency new amount of initial supply of reserve currency
  * @param oldInitialSupplyOfReserveCurrency old amount of initial supply of reserve currency
  */
  event ReserveCurrencyInitialSupplyChanged(uint256 newInitialSupplyOfReserveCurrency, uint256 oldInitialSupplyOfReserveCurrency);

  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getCreationPrice() 
    external
    view
    returns (uint256 creationPrice);

  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getReserveCurrencyInitialSupply() 
    external
    view
    returns (uint256 reserveCurrencyInitialSupply);
}

// File: contracts/MTokenInitialSetting.sol


pragma solidity 0.8.0;



/// @title MTokenInitialSetting
/// @dev Contract providing initial setting for creation of MToken contracts
contract MTokenInitialSetting is Ownable, MTokenInitialSettingInterface {


    string internal constant ERROR_PRICE_CAN_NOT_BE_ZERO = 'ERROR_PRICE_CAN_NOT_BE_ZERO';
    string internal constant ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO = 'ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO';
    string internal constant ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO = 'ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO';
    string internal constant ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO = 'ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO';
    string internal constant ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO = 'ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO';
    string internal constant ERROR_FEE_ABOVE_LIMIT = 'ERROR_FEE_ABOVE_LIMIT';
    string internal constant ERROR_FEE_LIMIT_ABOVE_OR_EQAULS_TO_HUNDRED_PERCENT = 'ERROR_FEE_LIMIT_ABOVE_OR_EQAULS_TO_HUNDRED_PERCENT';
    string internal constant ERROR_RESERVE_CURRENCY_WEIGHT_IS_ABOVE_MAX = 'ERROR_RESERVE_CURRENCY_WEIGHT_IS_ABOVE_MAX';

    uint16 internal constant ONE_HUNDRED_PERCENT = 10000;
    uint32 internal constant MAX_RESERVE_CURRENCY_WEIGHT = 1000000;

  /** 
  * @dev Structure what hold MToken initial settings
  * @param mTokenCreationPrice Price of mToken creation/registration
  * @param mTokenInitialSupply Amount of initial supply of newly created
  * @param mTokenInitialFee initial fee to set for newly created mToken
  * @param mTokenInitialFeeLimit initial fee limit to set for newly created mToken
  * @param mTokenReserveCurrencyInitialSupply Amount of reserve currency to be transfered to newly created contract as initial reserve currency supply  
  * @param reserveCurrencyWeight weight of reserve currency compared to created mTokens
  * (creationPrice, initialSupply, fee, feeLimit, reserveCurrencyWeight, reserveCurrencyInitialSupply)
  */
  struct MTokenSetting {
    uint256 creationPrice;
    uint256 initialSupply;
    uint16 fee;
    uint16 feeLimit;
    uint32 reserveCurrencyWeight;
    uint256 reserveCurrencyInitialSupply;
  }

  MTokenSetting public mTokenSetting;

  /**
  * @dev modifier Throws when value is not above zero
  */
  modifier aboveZero(uint256 _value, string memory _error) {
    require(_value > 0, _error);
    _;
  }

  /**
  * @dev modifier Throws when provided _fee is above fee limit property
  */
  modifier feeSmallerThanLimit(uint16 _fee, uint16 _feeLimit) {
    require(_fee < _feeLimit, ERROR_FEE_ABOVE_LIMIT);
    _;
  }

  /**
  * @dev modifier Throws when provided _feeLimit is above fee limit property
  */
  modifier feeLimitSmallerThanHundredPercent(uint16 _feeLimit) {
    require(_feeLimit < ONE_HUNDRED_PERCENT, ERROR_FEE_LIMIT_ABOVE_OR_EQAULS_TO_HUNDRED_PERCENT);
    _;
  }

  /**
  * @dev modifier Throws when provided _feeLimit is above fee limit property
  */
  modifier reserveCurrencyWeightBelowMax(uint32 _reserveCurrencyWeight) {
    require(_reserveCurrencyWeight <= MAX_RESERVE_CURRENCY_WEIGHT, ERROR_RESERVE_CURRENCY_WEIGHT_IS_ABOVE_MAX);
    _;
  }

  constructor(    
    uint256 _creationPrice,
    uint256 _initialSupply,
    uint16 _fee,
    uint16 _feeLimit,
    uint32 _reserveCurrencyWeight,
    uint256 _reserveCurrencyInitialSupply
  ) {
    MTokenSetting memory _mTokenSetting = MTokenSetting(
      _creationPrice,
      _initialSupply,
      _fee,
      _feeLimit,
      _reserveCurrencyWeight,
      _reserveCurrencyInitialSupply
    );

    checkCosntructorRequirements(_mTokenSetting);

    mTokenSetting = _mTokenSetting;
  }

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newInitialSupply new amount of initial supply
  * @param oldInitialSupply old amount of initial supply
  */
  event InitialSupplyChanged(uint256 newInitialSupply, uint256 oldInitialSupply);

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newFee new amount of initial supply
  * @param oldFee old amount of initial supply
  */
  event InitialFeeChanged(uint256 newFee, uint256 oldFee);

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newFeeLimit new amount of initial supply
  * @param oldFeeLimit old amount of initial supply
  */
  event InitialFeeLimitChanged(uint256 newFeeLimit, uint256 oldFeeLimit);


  /**
  * @dev Weight of reserve currency compared to printed mToken coins
  * @param newWeight new weight
  * @param oldWeight old weight
  */
  event ReserveCurrencyWeightChanged(uint32 newWeight, uint32 oldWeight);  


  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getMTokenInitialSetting() 
    public
    view
    returns (MTokenSetting memory currentSetting)
  {
    return mTokenSetting;
  }


  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getCreationPrice() 
    public
    view
    override
    returns (uint256 creationPrice)
  {
    return mTokenSetting.creationPrice;
  }

  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getReserveCurrencyInitialSupply() 
    public
    view
    override
    returns (uint256 creationPrice)
  {
    return mTokenSetting.reserveCurrencyInitialSupply;
  }


  /**
  * @dev Sets new price for creation MToken contracts
  * @param _price new price for MToken creation
  */
  function setCreationPrice(uint256 _price)
    public
    onlyOwner
    aboveZero(_price, ERROR_PRICE_CAN_NOT_BE_ZERO)
  {
    uint256 oldPrice = mTokenSetting.creationPrice;

    mTokenSetting.creationPrice = _price;

    emit CreationPriceChanged(mTokenSetting.creationPrice, oldPrice);
  }

  /**
  * @dev Sets initial supply of reseve currency transfered to newly created mToken.
  * @param _mTokenReserveCurrencyInitialSupply amount of reserve currency as initial supply
  */
  function setReserveCurrencyInitialSupply(uint256 _mTokenReserveCurrencyInitialSupply)
    public
    onlyOwner
    aboveZero(_mTokenReserveCurrencyInitialSupply, ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO)
  {
    uint256 oldMTokenInitialReserveCurrencySupply = mTokenSetting.reserveCurrencyInitialSupply;

    mTokenSetting.reserveCurrencyInitialSupply = _mTokenReserveCurrencyInitialSupply;

    emit ReserveCurrencyInitialSupplyChanged(mTokenSetting.reserveCurrencyInitialSupply, oldMTokenInitialReserveCurrencySupply);
  }

  /**
  * @dev Sets initial supply of newly created MToken contract.
  * @param _mTokenInitialSupply amount of initial supply
  */
  function setInitialSupply(uint256 _mTokenInitialSupply)
    public
    onlyOwner
    aboveZero(_mTokenInitialSupply, ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO)
  {
    uint256 oldMTokenInitialSupply = mTokenSetting.initialSupply;

    mTokenSetting.initialSupply = _mTokenInitialSupply;

    emit InitialSupplyChanged(mTokenSetting.initialSupply, oldMTokenInitialSupply);
  }

  /**
  * @dev Sets mToken initial buy/sale fee.
  * @param _fee initial fee of newly created mToken
  */
  function setInitialFee(uint16 _fee)
    public
    onlyOwner
    feeSmallerThanLimit(_fee, mTokenSetting.feeLimit)
  {
    uint16 oldFee = mTokenSetting.fee;

    mTokenSetting.fee = _fee;

    emit InitialFeeChanged(mTokenSetting.fee, oldFee);
  }

  /**
  * @dev Sets mToken initial buy/sale fee limit.
  * @param _feeLimit initial fee of newly created mToken
  */
  function setInitialFeeLimit(uint16 _feeLimit)
    public
    onlyOwner
    aboveZero(_feeLimit, ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO)
    feeLimitSmallerThanHundredPercent(_feeLimit)
  {
    uint16 oldFeeLimit = mTokenSetting.feeLimit;

    mTokenSetting.feeLimit = _feeLimit;

    emit InitialFeeLimitChanged(mTokenSetting.feeLimit, oldFeeLimit);
  }

  /**
  * @dev Sets weight of reserve currency compared to mToken coins
  * @param _weight hit some heavy numbers !! :)
  */
  function setReserveCurrencyWeight(uint32 _weight)
    public
    onlyOwner
    aboveZero(_weight, ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO)
    reserveCurrencyWeightBelowMax(_weight)
  {
    uint32 oldReserveCurrencyWeight = mTokenSetting.reserveCurrencyWeight;

    mTokenSetting.reserveCurrencyWeight = _weight;

    emit ReserveCurrencyWeightChanged(mTokenSetting.reserveCurrencyWeight, oldReserveCurrencyWeight);
  }


  /**
  * @dev modifiers evaluating constructor requirements moved over here to avoid "Stack Too Deep" error
  */
  function checkCosntructorRequirements(MTokenSetting memory _mTokenSetting)
    private
    aboveZero(_mTokenSetting.creationPrice, ERROR_PRICE_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.initialSupply, ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.reserveCurrencyWeight, ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.reserveCurrencyInitialSupply, ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.feeLimit, ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO)
    feeLimitSmallerThanHundredPercent(_mTokenSetting.feeLimit)
    feeSmallerThanLimit(_mTokenSetting.fee, _mTokenSetting.feeLimit)
    reserveCurrencyWeightBelowMax(_mTokenSetting.reserveCurrencyWeight)
  { }
}

// File: @openzeppelin/contracts/utils/Address.sol



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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/MTokenInterface.sol


pragma solidity 0.8.0;


/**
 * @title Marble Coin Register Interface
 * @dev describes all externaly accessible functions neccessery to run Marble Auctions
 */
interface MTokenInterface is IERC20 {

  /**
  * @dev Sets transaction fee. Fee should be limited in implementation to be not used for market total market control!
  * @param _transactionFee Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
  */
  function setTransactionFee(
    uint16 _transactionFee
  )
    external;

  /**
  * @dev Amount of reserve currency is bought for mTokens
  * @param _amountOfReserveCurrency amount of reserve Currency to buy
  * @param _minimumBuyTargetAmount minimum amount of mTokens gainned by this buy. if not met then fails. Fee included.
  */
  function buy(
    uint256 _amountOfReserveCurrency,
    uint256 _minimumBuyTargetAmount
  )
    external;

  /**
  * @dev Sell share of mTokens and get corrsponding amount of Main Currency
  * @param _amountOfMTokens amount of mTokens to sell
  * @param _minimumSaleTargetAmount minimum amount of reserve currency to target by sale. if not met then fails. Fee included.
  */
  function sellShare(
    uint256 _amountOfMTokens,
    uint256 _minimumSaleTargetAmount
  )
    external;

  /**
   * @dev Calculate amount of mTokens obtained by buying the given amount of Main Currency.
   * @param _amountOfReserveCurrency amount of Main Currency to buy
   */
  function calculateBuyReward(
    uint256 _amountOfReserveCurrency
  )
    external
    view
    returns (uint256);

  /**
   * @dev Calculate amount of Main Currency obtained from transaction call to sellShare method.
   * @param _amountOfMTokens amount of mTokens to sell
   */
  function calculateSellShareReward(
    uint256 _amountOfMTokens
  )
    external
    view
    returns (uint256);

  /**
  * @dev Stops minting of coins.. should be activated in case of bonding curve evaluation is lower than price of token in external markets
  */
  function pauseMinting()
    external;

  /**
  * @dev Activates minting of coins.. 
  */
  function unpauseMinting()
    external;

  /**
  * @dev Create mToken with provided name.
  */
  function isMintingPaused()
    external
    view
    returns (bool);

  event Buy(
    address buyer, 
    uint256 feeInReserveCurrency, 
    uint256 buyInReserveCurrency, 
    uint256 gainedAmountOfMTokens);

  event SoldShare(
    address buyer,
    uint256 feeInReserveCurrency, 
    uint256 revenueInReserveCurrency, 
    uint256 amountSoldOfMTokens);

  event TransactionFeeChanged(
    uint256 newFee,
    uint256 oldFee);

}

// File: contracts/MToken.sol


pragma solidity 0.8.0;








/// @title ERC20 token
/// @dev Memetic token contract with self-curation of buying and selling it
contract MToken is Ownable, Pausable, ERC20, MTokenInterface  {

  using SafeERC20 for IERC20;

  string internal constant ERROR_FEE_IS_ABOVE_LIMIT = 'ERROR_FEE_IS_ABOVE_LIMIT';

  string internal constant ERROR_FEE_LIMIT_IS_HIGHER_THAN_HUNDRED_PERCENT = 'ERROR_FEE_LIMIT_IS_HIGHER_THAN_HUNDRED_PERCENT';

  string internal constant ERROR_CALLER_HAS_NOT_ENOUGH_MTOKENS_TO_SELL = 'ERROR_CALLER_HAS_NOT_ENOUGH_MTOKENS_TO_SELL';

  string internal constant ERROR_MINIMUM_SALE_TARGET_AMOUNT_NOT_MET = 'ERROR_MINIMUM_SALE_TARGET_AMOUNT_NOT_MET';

  string internal constant ERROR_MINIMUM_BUY_TARGET_AMOUNT_NOT_MET = 'ERROR_MINIMUM_BUY_TARGET_AMOUNT_NOT_MET';

  uint256 public constant ONE_MTOKEN = 1e18;

  uint16 internal constant ONE_HUNDRED_PERCENT = 10000;

  /**
  * @dev Transaction fee applied to buy and sale prices where 1% is equal to 100. 100% equals to 10000
  */
  uint16 public transactionFee;

  /**
  * @dev Transaction fee limit.. limits fee to max 10% of reserveCurrency
  */
  uint16 public immutable transactionFeeLimit;


  /**
  * @dev Contracts reserve currency   
  */
  IERC20 public immutable reserveCurrency;


  /**
  * @dev Reverse weight can not be changed after creation, one of Bancors properties   
  */
  uint32 public immutable reserveWeight;


  /**
  * @dev Bancor formula providing token minting and burning strategy   
  */
  IBancorFormula public immutable bancorFormula;

  constructor(
    address _owner,
    uint256 _initialSupply,
    string memory _memeTokenName, 
    string memory _memeTokenSymbol,
    IERC20 _reserveCurrency,
    uint32 _reserveWeight,
    uint16 _fee,
    uint16 _feeLimit,
    IBancorFormula _formula) ERC20(_memeTokenName, _memeTokenSymbol)
  {
    require(_feeLimit < ONE_HUNDRED_PERCENT, ERROR_FEE_LIMIT_IS_HIGHER_THAN_HUNDRED_PERCENT);
    transferOwnership(_owner);

    _mint(address(this), _initialSupply);

    reserveCurrency = _reserveCurrency;
    reserveWeight = _reserveWeight;

    transactionFee = _fee;
    transactionFeeLimit = _feeLimit;

    bancorFormula = _formula;
  }

  /**
  * @dev Sets transaction fee. Fee should be limited in implementation to be not used for market total market control!
  * @param _transactionFee Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
  */
  function setTransactionFee(
    uint16 _transactionFee
  )
    external
    override
    onlyOwner
  {

    require(transactionFeeLimit > _transactionFee, ERROR_FEE_IS_ABOVE_LIMIT);
    uint256 oldFee = transactionFee;
    transactionFee = _transactionFee;

    emit TransactionFeeChanged(_transactionFee, oldFee);
  }

  /**
  * @dev Amount of Main Currency is bought for mTokens
  * @param _amountOfReserveCurrency amount of reserve currency to be bought
  * @param _minimumBuyTargetAmount minimum amount of mTokens gainned by this buy. if not met then fails. Fee included.
  */
  function buy(
    uint256 _amountOfReserveCurrency,
    uint256 _minimumBuyTargetAmount
  )
    external
    override
    whenNotPaused
  {
    uint256 fee = computeFee(_amountOfReserveCurrency);
    uint256 amountOfReserveCurrencyExcludingFee = _amountOfReserveCurrency - fee;

    uint256 reserveBalance = reserveCurrency.balanceOf(address(this));
    uint256 mTokenAmount = bancorFormula.purchaseTargetAmount(totalSupply(), reserveBalance, reserveWeight, amountOfReserveCurrencyExcludingFee);

    require(mTokenAmount >= _minimumBuyTargetAmount, ERROR_MINIMUM_BUY_TARGET_AMOUNT_NOT_MET);

    reserveCurrency.safeTransferFrom(msg.sender, address(this), amountOfReserveCurrencyExcludingFee);
    reserveCurrency.safeTransferFrom(msg.sender, owner(), fee);
    _mint(msg.sender, mTokenAmount);

    emit Buy(msg.sender, fee, amountOfReserveCurrencyExcludingFee, mTokenAmount);
  }

  /**
  * @dev Sell share of mTokens and get corrsponding amount of Main Currency
  * @param _amountOfMTokens amount of mTokens to sell
  * @param _minimumSaleTargetAmount minimum amount of reserve currency to target by sale. if not met then fails. Fee included.
  */
  function sellShare(
    uint256 _amountOfMTokens,
    uint256 _minimumSaleTargetAmount
  )
    external
    override
  {
    uint256 reserveBalance = reserveCurrency.balanceOf(address(this));
    uint256 reserveCurrencyAmountToReturnTotal = bancorFormula.saleTargetAmount(totalSupply(), reserveBalance, reserveWeight, _amountOfMTokens);


    uint256 fee = computeFee(reserveCurrencyAmountToReturnTotal);
    uint256 reserveCurrencyAmountToReturn = reserveCurrencyAmountToReturnTotal - fee;

    require(reserveCurrencyAmountToReturn >= _minimumSaleTargetAmount, ERROR_MINIMUM_SALE_TARGET_AMOUNT_NOT_MET);

    reserveCurrency.safeTransfer(msg.sender, reserveCurrencyAmountToReturn);
    reserveCurrency.safeTransfer(owner(), fee);
    _burn(msg.sender, _amountOfMTokens);

    emit SoldShare(msg.sender, fee, reserveCurrencyAmountToReturn, _amountOfMTokens);
  }

  /**
  * @dev Calculate amount of mTokens obtained by buying the given amount of Main Currency.
  * @param _amountOfReserveCurrency amount of Main Currency
  */
  function calculateBuyReward(
    uint256 _amountOfReserveCurrency
  )
    external
    override
    view
    returns (uint256)
  {
    uint256 fee = computeFee(_amountOfReserveCurrency);
    uint256 amountOfReserveCurrencyExcludingFee = _amountOfReserveCurrency - fee;

    uint256 reserveBalance = reserveCurrency.balanceOf(address(this));
    uint256 mTokenAmount = bancorFormula.purchaseTargetAmount(totalSupply(), reserveBalance, reserveWeight, amountOfReserveCurrencyExcludingFee);

    return mTokenAmount;    
  }

  /**
  * @dev Calculate amount of Main Currency obtained by selling the given amount of Mtokens.
    @param _amountOfMTokens amount of mTokens to sell
  */
  function calculateSellShareReward(
    uint256 _amountOfMTokens
  )
    external
    override
    view
    returns (uint256)
  {
    uint256 reserveBalance = reserveCurrency.balanceOf(address(this));
    uint256 reserveCurrencyAmountToReturnTotal = bancorFormula.saleTargetAmount(totalSupply(), reserveBalance, reserveWeight, _amountOfMTokens);
    uint256 fee = computeFee(reserveCurrencyAmountToReturnTotal);
    uint256 reserveCurrencyAmountToReturn = reserveCurrencyAmountToReturnTotal - fee;

    return reserveCurrencyAmountToReturn;
  }

  /**
  * @dev Stops minting of coins.. in other words direct buy to coin is postponed 
  */
  function pauseMinting()
    external
    override
    onlyOwner
  {
    _pause();
  }

  /**
  * @dev Activates minting of coins.. 
  */
  function unpauseMinting()
    external
    override
    onlyOwner
  {
    _unpause();     
  }

  /**
  * @dev checks if minting of new coins is paused.
  */
  function isMintingPaused()
    external
    override
    view
    returns (bool) 
  {
    return paused();
  }


  /**
   * @dev Computes owners fee.
   * @param amount amount of tokens to be fee counted from
   */
  function computeFee(uint256 amount)
    public
    view
    returns (uint256)
  {
    return amount * transactionFee / ONE_HUNDRED_PERCENT;
  }
}

// File: contracts/MTokenFactory.sol


pragma solidity 0.8.0;











/**
 * @title Memetic Token Factory Contract
 * @notice simple contract with purpose to create Memetic Token Contracts
 */
contract MTokenFactory is Ownable, Pausable, MTokenFactoryInterface {

  string internal constant ERROR_CALLER_IS_NOT_MEME_COIN_REGISTER = 'ERROR_CALLER_IS_NOT_MEME_COIN_REGISTER';

  MTokenRegisterInterface public immutable mTokenRegister;
  Memecoin public immutable reserveCurrency;
  MTokenInitialSetting public immutable mTokenInitialSetting;
  IBancorFormula public immutable bancorFormula;

  constructor(MTokenRegisterInterface _mTokenRegister, Memecoin _reserveCurrency, MTokenInitialSetting _mTokenInitialSetting,  IBancorFormula _bancorFormula) {
    mTokenRegister = _mTokenRegister;
    reserveCurrency = _reserveCurrency;
    mTokenInitialSetting = _mTokenInitialSetting;
    bancorFormula = _bancorFormula;
  }

  /**
  * @dev Allows mTokenRegister as caller to create new MemeticToken Contract (MToken). 
  * @param _mTokenName name of new MToken contract
  * @param _mTokenSymbol symbol of new MToken contract
  */
  function createMToken(string calldata _mTokenName, string calldata _mTokenSymbol)
    external
    override
    whenNotPaused
    returns(address) 
  {
    require(msg.sender == address(mTokenRegister), ERROR_CALLER_IS_NOT_MEME_COIN_REGISTER);
  
    MTokenInitialSetting.MTokenSetting memory mTokenSetting = mTokenInitialSetting.getMTokenInitialSetting();

    MToken mToken = new MToken(
      owner(),
      mTokenSetting.initialSupply,
      _mTokenName,
      _mTokenSymbol,
      reserveCurrency,
      mTokenSetting.reserveCurrencyWeight,
      mTokenSetting.fee,
      mTokenSetting.feeLimit,
      bancorFormula
    );

    address mTokenAddress = address(mToken);
    emit MTokenCreated(mTokenAddress);

    return mTokenAddress;
  }

  /**
  * @dev Pause contract
  */
  function pause()
    external
    onlyOwner
  {
    _pause();
  }

  /**
  * @dev Unpoause contract 
  */
  function unpause()
    external
    onlyOwner
  {
    _unpause();     
  }
}