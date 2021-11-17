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
    constructor() {
        _setOwner(_msgSender());
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OvalCompoundToken.sol";
import "../interface/CErc20.sol";

/// @title Oval Smart Contract
/// @notice This is the main smart contract that the user will interact with.
contract Oval is Ownable {
    /// Events - fire events on state changes etc
    /// message, amount, msg.sender
    event Supply(string message, uint256 amount, address indexed from);
    event Redeem(string message, uint256 amount, address indexed to);
    event Withdraw(string, uint256 amount, address indexed to);

    ERC20 public Erc20Contract;
    CErc20 public cErc20Contract;
    OvalCompoundToken public ocErc20Contract;
    address public USDCAddress;
    address public cUSDCAddress;
    address public oErc20Address;

    uint256 public OCompoundToUSDCER;
    uint256 public OCompoundCheckpoint;

    uint256 public OAaveToUSDCER;
    uint256 public OAaveCheckpoint;

    uint256 public BLOCKSINAYEAR;

    uint256 CompoundAPR;
    uint256 AaveAPR;

    constructor(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _oCompoundToUSDCER,
        uint256 _oAaveToUSDCER,
        uint256 _blocksInaYear,
        uint256 _compoundAPR,
        uint256 _aaveAPR
    ) {
        /// Create a reference to the underlying asset contract, like USDC.
        Erc20Contract = ERC20(_erc20Contract);
        /// Create a reference to the Compound asset contract, like cUSDC
        cErc20Contract = CErc20(_cErc20Contract);
        USDCAddress = _erc20Contract;
        cUSDCAddress = _cErc20Contract;
        OCompoundToUSDCER = _oCompoundToUSDCER; //initial ER
        OAaveToUSDCER = _oAaveToUSDCER;
        BLOCKSINAYEAR = _blocksInaYear; //6570 blocks in a day, same as Compound protocol
        CompoundAPR = _compoundAPR;
        AaveAPR = _aaveAPR;
    }

    /// @notice This function is responsible for supplying USDC into the compound protocol
    /// @dev first require the user to have approved the amount by calling the approve function beforehand
    /// @param  _numTokensToSupply a parameter for providing the number of tokens to supply to the protocol
    /// @param ER exchange rate(usdc/ocusdc) scaled by 1e18
    /// @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    function supplyErc20ToCompound(uint256 _numTokensToSupply, uint256 ER) public returns (bool) {
        require(_numTokensToSupply > 0, "You need to supply some tokens");

        /// transfer the tokens from sender to current smart contract
        Erc20Contract.transferFrom(msg.sender, address(this), _numTokensToSupply);

        /// Approve transfer on the ERC20 contract
        Erc20Contract.approve(cUSDCAddress, _numTokensToSupply);

        /// Mint cTokens
        cErc20Contract.mint(_numTokensToSupply);

        emit Supply("Supplied USDC to Compound", _numTokensToSupply, msg.sender);

        /// Calculate amount based on Exchange Rate
        /// TODO: Fix amount, set user defined for now
        uint256 ovalTokensToMint = (_numTokensToSupply * 1e30) / ER; //Oval Token scale 1e18, usdc scale 1e6 and ER scale 30+6-18 = 18

        /// Mint oTokens for user
        ocErc20Contract.mint(msg.sender, ovalTokensToMint); /// Oval Token scale 1e18, USDC scale 1e6. 18-6 = 12

        return true;
    }

    /// @notice This function, will redeem USDC in exchange of Compound tokens
    /// @dev If redeemType is true, specified amount is Ctoken else it is USDC
    /// @param amount a parameter for the specified amount. redeemType = true, amount scale = 1e8, else scale = 1e6
    /// @param redeemType a boolean parameter for the type of redemption
    /// @return a true boolean if the redemption is successful
    function redeemCErc20Tokens(uint256 amount, bool redeemType) private returns (bool) {
        uint256 redeemResult;

        if (redeemType == true) {
            /// Retrieve your asset based on a cToken amount
            /// converts a specified quantity of cTokens into the underlying asset
            redeemResult = cErc20Contract.redeem(amount);
        } else {
            /// Retrieve your asset based on an amount of the asset
            /// converts cTokens into a specified quantity of the underlying asset
            redeemResult = cErc20Contract.redeemUnderlying(amount);
        }
        /// Error code 13 for TOKEN_INSUFFICIENT_BALANCE
        require(redeemResult != 13, "TOKEN_INSUFFICIENT_BALANCE");
        /// Error code 0 for NO ERROR
        require(redeemResult == 0, "REDEEM FAILED");
        return true;
    }

    /// @notice Redeem the compound oval token for USDC.
    /// @dev Takes ocUSDC, burns it. Redeem compound token for USDC from Compound Contract. Transfers said amount to the caller.
    /// @param amount ocUSDC token value scaled by 1e18
    /// @param ER exchange rate(usdc/ocusdc) scaled by 1e18
    /// @return boolean true on success
    function redeemCompoundOvalToken(uint256 amount, uint256 ER) public returns (bool) {
        // burn user oval tokens
        ocErc20Contract.burn(msg.sender, amount);

        uint256 usdcAmount = (amount * ER) / 1e30; // Oval Token scale 1e18, USDC scale 1e6. 18-6 = 12. ER also scaled by 1e18
        uint256 usdcBalance = Erc20Contract.balanceOf(address(this));
        if (usdcAmount > usdcBalance) {
            // redeem cERC20 ie. cERC20 for USDC
            redeemCErc20Tokens(usdcAmount - usdcBalance, false);
        }

        // transfer USDC to the user.
        Erc20Contract.transfer(msg.sender, usdcAmount);

        emit Redeem("Redeem Successful", amount, msg.sender);
        return true;
    }

    /// @notice The function is responsible for the withdrawal of USDC from the Smart Contract to the recipient
    /// @dev Only the current owner of the contract can transfer the USDC from contract to recipient
    /// @param _USDCToWithdraw a parameter specified amount to withraw
    /// @param _recipient a parameter receiver of the withdrawn amount
    function withdrawUSDC(uint256 _USDCToWithdraw, address _recipient) public onlyOwner {
        Erc20Contract.transfer(_recipient, _USDCToWithdraw);
        emit Withdraw("Amount withdrawn from Smart Contract", _USDCToWithdraw, msg.sender);
    }

    function updateCompoundER() private {
        uint256 oldER = OCompoundToUSDCER;
        uint256 blocksElapsed = ((block.timestamp - OCompoundCheckpoint) * 100) / 1315;
        OCompoundToUSDCER = oldER * ((1 + CompoundAPR / BLOCKSINAYEAR)**blocksElapsed);
        OCompoundCheckpoint = block.timestamp;
    }

    function updateAaveER() private {
        uint256 oldER = OAaveToUSDCER;
        uint256 blocksElapsed = ((block.timestamp - OAaveCheckpoint) * 100) / 1315;
        OAaveToUSDCER = oldER * ((1 + AaveAPR / BLOCKSINAYEAR)**blocksElapsed);
        OAaveCheckpoint = block.timestamp;
    }

    /// Admin should be able to set OvalToken address
    function setOvalTokenAddress(address _newoERC20Address) public onlyOwner {
        require(_newoERC20Address != address(0), "new oERC20Address is 0 address");
        oErc20Address = _newoERC20Address;
        /// Create a reference to the oval token contract, oUSDC.
        ocErc20Contract = OvalCompoundToken(_newoERC20Address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./utils/Controllable.sol";

contract OvalCompoundToken is ERC20, Controllable {
    constructor() ERC20("Oval-Compound Token", "ocUSDC") {}

    /**
     * @dev mint tokens onlyController function
     * @param user address of user that initiated mint of tokens
     * @param amount value scaled by 1e18
     */
    function mint(address user, uint256 amount) external onlyController {
        _mint(user, amount);
    }

    /**
     * @dev burn tokens onlyController function
     * @param user address of user that initiated burn of tokens
     * @param amount value scaled by 1e18
     */
    function burn(address user, uint256 amount) external onlyController {
        _burn(user, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    address private _controller;
    event ControlTransferred(address indexed previousController, address indexed newController);

    modifier onlyController() {
        require(_controller != address(0), "Controller cannot be 0 address, set a controller first");
        require(msg.sender == _controller, "Only controller can call this function.");
        _;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the current owner.
     */
    function transferControl(address newController) public virtual onlyOwner {
        require(newController != address(0), "Controllable: new controller is a zero address");
        _setController(newController);
    }

    function _setController(address newController) private {
        address oldController = _controller;
        _controller = newController;
        emit ControlTransferred(oldController, newController);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);
}