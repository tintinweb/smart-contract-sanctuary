// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../shared/ProtocolConstants.sol";

import "../interfaces/tokens/IUSDV.sol";
import "../interfaces/tokens/IVader.sol";
import "../interfaces/tokens/vesting/ILinearVesting.sol";
import "../interfaces/tokens/converter/IConverter.sol";

/**
 * @dev Implementation of the {IVader} interface.
 *
 * The Vader token that acts as the backbone of the Vader protocol,
 * burned and minted to mint and burn USDV tokens respectively.
 *
 * The token has a fixed initial supply at 25 billion units that is meant to then
 * fluctuate depending on the amount of USDV minted into and burned from circulation.
 *
 * Emissions are initially controlled by the Vader team and then will be governed
 * by the DAO.
 */
contract Vader is IVader, ProtocolConstants, ERC20, Ownable {
    /* ========== STATE VARIABLES ========== */

    // The Vader <-> Vether converter contract
    IConverter public converter;

    // The Vader Team vesting contract
    ILinearVesting public vest;

    // The USDV contract, used to apply proper access control
    IUSDV public usdv;

    // The initial maximum supply of the token, equivalent to 25 bn units
    uint256 public maxSupply = _INITIAL_VADER_SUPPLY;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Mints the ecosystem growth fund and grant allocation amount described in the whitepaper to the
     * token contract itself.
     *
     * As the token is meant to be minted and burned freely between USDV and itself,
     * there is no real initialization taking place apart from the initially minted
     * supply for the following components:
     *
     * - Grant Allocation: The amount of funds meant to be distributed by the DAO as grants to expand the protocol
     *
     * - Ecosystem Growth: An allocation that is released to strategic partners for the
     * protocol's expansion
     *
     * The latter two of the allocations are minted at a later date given that the addresses of
     * the converter and vesting contract are not known on deployment.
     */
    constructor() ERC20("Vader", "VADER") {
        _mint(address(this), _GRANT_ALLOCATION);
        _mint(address(this), _ECOSYSTEM_GROWTH);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Creates a manual emission event
     *
     * Emits an {Emission} event indicating the amount emitted as well as what the current
     * era's timestamp is.
     */
    function createEmission(address user, uint256 amount)
        external
        override
        onlyOwner
    {
        _transfer(address(this), user, amount);
        emit Emission(user, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Sets the initial {converter} and {vest} contract addresses. Additionally, mints
     * the Vader amount available for conversion as well as the team allocation that is meant
     * to be vested to each respective contract.
     *
     * Emits a {ProtocolInitialized} event indicating all the supplied values of the function.
     *
     * Requirements:
     *
     * - the caller must be the deployer of the contract
     * - the contract must not have already been initialized
     */
    function setComponents(
        IConverter _converter,
        ILinearVesting _vest,
        address[] calldata vesters,
        uint192[] calldata amounts
    ) external onlyOwner {
        require(
            _converter != IConverter(_ZERO_ADDRESS) &&
                _vest != ILinearVesting(_ZERO_ADDRESS),
            "Vader::setComponents: Incorrect Arguments"
        );
        require(
            converter == IConverter(_ZERO_ADDRESS),
            "Vader::setComponents: Already Set"
        );

        converter = _converter;
        vest = _vest;

        _mint(address(_converter), _VETH_ALLOCATION);
        _mint(address(_vest), _TEAM_ALLOCATION);

        _vest.begin(vesters, amounts);

        emit ProtocolInitialized(
            address(_converter),
            address(_vest)
        );
    }

    /**
     * @dev Set USDV
     * Emits a {USDVSet} event indicating that USDV is set
     *
     * Requirements:
     *
     * - the caller must be owner
     * - USDV must be of a non-zero address
     * - USDV must not be set
     */
    function setUSDV(IUSDV _usdv) external onlyOwner {
        require(_usdv != IUSDV(_ZERO_ADDRESS), "Vader::setUSDV: Invalid USDV address");
        require(usdv == IUSDV(_ZERO_ADDRESS), "Vader::setUSDV: USDV already set");

        usdv = _usdv;
        emit USDVSet(address(_usdv));
    }

    /**
     * @dev Allows a strategic partnership grant to be claimed.
     *
     * Emits a {GrantClaimed} event indicating the beneficiary of the grant as
     * well as the grant amount.
     *
     * Requirements:
     *
     * - the caller must be the DAO
     * - the token must hold sufficient Vader allocation for the grant
     * - the grant must be of a non-zero amount
     */
    function claimGrant(address beneficiary, uint256 amount) external onlyOwner {
        require(amount != 0, "Vader::claimGrant: Non-Zero Amount Required");
        emit GrantClaimed(beneficiary, amount);
        _transfer(address(this), beneficiary, amount);
    }

    /**
     * @dev Allows the maximum supply of the token to be adjusted.
     *
     * Emits an {MaxSupplyChanged} event indicating the previous and next maximum
     * total supplies.
     *
     * Requirements:
     *
     * - the caller must be the DAO
     * - the new maximum supply must be greater than the current supply
     */
    function adjustMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(
            _maxSupply >= totalSupply(),
            "Vader::adjustMaxSupply: Max supply cannot subcede current supply"
        );
        emit MaxSupplyChanged(maxSupply, _maxSupply);
        maxSupply = _maxSupply;
    }

    /**
     * @dev Allows the USDV token to perform mints of VADER tokens
     *
     * Emits an ERC-20 {Transfer} event signaling the minting operation.
     *
     * Requirements:
     *
     * - the caller must be the USDV
     * - the new supply must be below the maximum supply
     */
    function mint(address _user, uint256 _amount) external onlyUSDV {
        require(
            maxSupply >= totalSupply() + _amount,
            "Vader::mint: Max supply reached"
        );
        _mint(_user, _amount);
    }

    /**
     * @dev Allows the USDV token to perform burns of VADER tokens
     *
     * Emits an ERC-20 {Transfer} event signaling the burning operation.
     *
     * Requirements:
     *
     * - the caller must be the USDV
     * - the USDV contract must have a sufficient VADER balance
     */
    function burn(uint256 _amount) external onlyUSDV {
        _burn(msg.sender, _amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Ensures only the USDV is able to invoke a particular function by validating that the
     * contract has been set up and that the msg.sender is the USDV address
     */
    function _onlyUSDV() private view {
        require(
            address(usdv) == msg.sender,
            "Vader::_onlyUSDV: Insufficient Privileges"
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if invoked by anyone else other than the USDV
     */
    modifier onlyUSDV() {
        _onlyUSDV();
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

abstract contract ProtocolConstants {
    /* ========== GENERAL ========== */

    // The zero address, utility
    address internal constant _ZERO_ADDRESS = address(0);

    // One year, utility
    uint256 internal constant _ONE_YEAR = 365 days;

    // Basis Points
    uint256 internal constant _MAX_BASIS_POINTS = 100_00;

    /* ========== VADER TOKEN ========== */

    // Max VADER supply
    uint256 internal constant _INITIAL_VADER_SUPPLY = 25_000_000_000 * 1 ether;

    // Allocation for VETH holders
    uint256 internal constant _VETH_ALLOCATION = 7_500_000_000 * 1 ether;

    // Team allocation vested over {VESTING_DURATION} years
    uint256 internal constant _TEAM_ALLOCATION = 2_500_000_000 * 1 ether;

    // Ecosystem growth fund unlocked for partnerships & USDV provision
    uint256 internal constant _ECOSYSTEM_GROWTH = 2_500_000_000 * 1 ether;

    // Total grant tokens
    uint256 internal constant _GRANT_ALLOCATION = 12_500_000_000 * 1 ether;

    // Emission Era
    uint256 internal constant _EMISSION_ERA = 24 hours;

    // Initial Emission Curve, 5
    uint256 internal constant _INITIAL_EMISSION_CURVE = 5;

    // Fee Basis Points
    uint256 internal constant _MAX_FEE_BASIS_POINTS = 1_00;

    /* ========== VESTING ========== */

    // Vesting Duration
    uint256 internal constant _VESTING_DURATION = 2 * _ONE_YEAR;

    /* ========== CONVERTER ========== */

    // Vader -> Vether Conversion Rate (1000:1)
    uint256 internal constant _VADER_VETHER_CONVERSION_RATE = 10_000;

    // Burn Address
    address internal constant _BURN =
        0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD;

    /* ========== SWAP QUEUE ========== */

    // A minimum of 10 swaps will be executed per block
    uint256 internal constant _MIN_SWAPS_EXECUTED = 10;

    // Expressed in basis points (50%)
    uint256 internal constant _DEFAULT_SWAPS_EXECUTED = 50_00;

    // The queue size of each block is 100 units
    uint256 internal constant _QUEUE_SIZE = 100;

    /* ========== GAS QUEUE ========== */

    // Address of Chainlink Fast Gas Price Oracle
    address internal constant _FAST_GAS_ORACLE =
        0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    /* ========== VADER RESERVE ========== */

    // Minimum delay between grants
    uint256 internal constant _GRANT_DELAY = 30 days;

    // Maximum grant size divisor
    uint256 internal constant _MAX_GRANT_BASIS_POINTS = 10_00;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface ILinearVesting {
    /* ========== STRUCTS ========== */

    // Struct of a vesting member, tight-packed to 256-bits
    struct Vester {
        uint192 amount;
        uint64 lastClaim;
        uint128 start;
        uint128 end;
    }

    /* ========== FUNCTIONS ========== */

    function getClaim(address _vester)
        external
        view
        returns (uint256 vestedAmount);

    function claim() external returns (uint256 vestedAmount);

    //    function claimConverted() external returns (uint256 vestedAmount);

    function begin(address[] calldata vesters, uint192[] calldata amounts)
        external;

    function vestFor(address user, uint256 amount) external;

    /* ========== EVENTS ========== */

    event VestingInitialized(uint256 duration);

    event VestingCreated(address user, uint256 amount);

    event Vested(address indexed from, uint256 amount);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface IConverter {
    /* ========== FUNCTIONS ========== */

    function convert(bytes32[] calldata proof, uint256 amount, uint256 minVader)
        external
        returns (uint256 vaderReceived);

    /* ========== EVENTS ========== */

    event Conversion(
        address indexed user,
        uint256 vetherAmount,
        uint256 vaderAmount
    );
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface IVader {
    /* ========== FUNCTIONS ========== */

    function createEmission(address user, uint256 amount) external;

    /* ========== EVENTS ========== */

    event Emission(address to, uint256 amount);

    event EmissionChanged(uint256 previous, uint256 next);

    event MaxSupplyChanged(uint256 previous, uint256 next);

    event GrantClaimed(address indexed beneficiary, uint256 amount);

    event ProtocolInitialized(
        address converter,
        address vest
    );

    event USDVSet(address usdv);

    /* ========== DEPRECATED ========== */

    // function getCurrentEraEmission() external view returns (uint256);

    // function getEraEmission(uint256 currentSupply)
    //     external
    //     view
    //     returns (uint256);

    // function calculateFee() external view returns (uint256 basisPoints);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface IUSDV {
    /* ========== STRUCTS ========== */
    /* ========== FUNCTIONS ========== */
    /* ========== EVENTS ========== */
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