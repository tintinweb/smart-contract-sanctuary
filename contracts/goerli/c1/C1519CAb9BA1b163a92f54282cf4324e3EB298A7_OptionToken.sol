// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Initializable } from "../openzeppelin/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "../openzeppelin/token/ERC20/ERC20Upgradeable.sol";
import { IERC20 } from "../openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "../openzeppelin/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../openzeppelin/token/ERC721/IERC721Receiver.sol";
import { IERC1155 } from "../openzeppelin/token/ERC1155/IERC1155.sol";
import { ReentrancyGuardUpgradeable } from "../openzeppelin/security/ReentrancyGuardUpgradeable.sol";

import { DateTimeLibrary } from "../libraries/DateTimeLibrary.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { PolyMath } from "../libraries/PolyMath.sol";

import { IProtocol } from "./implementations/IProtocol.sol";

contract OptionToken is Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using DateTimeLibrary for uint64;
    using SafeERC20 for IERC20;
    using PolyMath for uint256;

    /* ============ Immutables ============ */
    // Address of the option registry contract
    address public immutable optionRegistry;

    /* ============ State Variables ============ */

    // Total payout
    uint256 public totalPayout;
    // Total supply at expiry
    uint256 public totalSupplyAtExpiry;
    // Mapping of option protocol implementations enabled for this option
    mapping(address => bool) public implementations;
    // Array of implementations enabled
    IProtocol[] public protocols;

    // Option metadata
    DataTypes.OptionData public data;
    // Option hash
    bytes32 public optionHash;
    // Collateral instance
    IERC20 public collateral;

    constructor(address optionRegistry_) {
        require(optionRegistry_ != address(0x0), "OptionToken::zero-addr");

        optionRegistry = optionRegistry_;
    }

    /* ============ Events ============ */
    /**
     @notice Emitted when a new option is minted
     @param impl Address of the implementation contract
     @param user User address
     @param amt Amount of options minted
     @param mintData Additional mint data passed down to the impl
     */
    event Mint(address indexed impl, address indexed user, uint256 amt, bytes mintData);

    /**
     @notice Emitted when a new option is minted via wrapping
     @param impl Address of the implementation contract
     @param user User address
     @param amt Amount of options wrapped
     @param wrapData Additional wrap data passed down to the impl
     */
    event Wrap(address indexed impl, address indexed user, uint256 amt, bytes wrapData);

    /**
     @notice Emitted when an option is redeemed for collateral
     @param impl Address of the implementation contract
     @param user User address
     @param amt Amount of options to redeem
     @param redeemData Additional redeem data passed down to the impl
     */
    event Redeem(address indexed impl, address indexed user, uint256 amt, bytes redeemData);

    /**
     @notice Emitted when all implementations are settled
     */
    event Settle();

    /**
     @notice Emitted when an option implementation is settled after expiry
     @param impl Address of the implementation contract
     */
    event SettleOne(address indexed impl);

    /**
     @notice Emitted when the collateral & payout is claimed by the user
     @param user Address of the user
     @param userPayout Amount of user Payout
     */
    event Claim(address indexed user, uint256 userPayout);

    /* ============ Initializer ============ */

    /**
     @notice Initializes the option token
     @param underlyingName Underlying asset name
     @param underlyingSymbol Underlying token name
     */
    function initialize(
        string memory underlyingName,
        string memory underlyingSymbol,
        DataTypes.Option memory optionData
    ) external initializer {
        require(msg.sender == optionRegistry, "OptionToken::no-auth");

        string memory tokenName;
        string memory tokenSymbol;

        // Human readable token name and symbol
        (tokenName, tokenSymbol) = optionData.expiry.getTokenName(
            optionData.strikePrice,
            underlyingName,
            underlyingSymbol,
            optionData.isCall
        );

        // Initialize the token
        __ERC20_init(tokenName, tokenSymbol);

        protocols = new IProtocol[](optionData.impls.length);

        // Activate given implementations
        for (uint256 i = 0; i < optionData.impls.length; i++) {
            implementations[optionData.impls[i]] = true;
            protocols[i] = IProtocol(optionData.impls[i]);
        }

        data.expiry = optionData.expiry;
        data.isCall = optionData.isCall;
        data.strikePrice = optionData.strikePrice;
        data.collateral = optionData.collateral;
        data.underlying = optionData.underlying;

        optionHash = keccak256(abi.encode(data));

        collateral = IERC20(optionData.collateral);

        // Give token approvals to implementations based on the token type
        for (uint256 i = 0; i < optionData.impls.length; i++) {
            IProtocol protocol = IProtocol(optionData.impls[i]);
            require(protocol.create(optionData), "OptionToken::fail");
            (address token, DataTypes.TokenType tokenType) = protocol.getOptionToken(data);
            if (tokenType == DataTypes.TokenType.ERC20) {
                IERC20(token).safeApprove(address(protocol), type(uint256).max);
            } else if (tokenType == DataTypes.TokenType.ERC721) {
                IERC721(token).setApprovalForAll(address(protocol), true);
            } else if (tokenType == DataTypes.TokenType.ERC1155) {
                IERC1155(token).setApprovalForAll(address(protocol), true);
            }
        }

        __ReentrancyGuard_init();
    }

    /* ============ Stateful Methods ============ */

    /**
     @notice Mint a new option using an approved implementation
     @param impl Address of the implementation being used
     @param amt Amount of options to mint
     @param mintData Additional data being passed down to the implementation. Used for passing impl specific data
     */
    function mint(address impl, uint256 amt, bytes memory mintData) external nonReentrant {
        require(implementations[impl], "OptionToken::invalid-impl");
        require(block.timestamp < data.expiry, "OptionToken::expired");

        IProtocol protocol = IProtocol(impl);

        // Calculate pre-mint balance of options held by Polynomial Protocol
        uint256 subOptionBal = protocol.balanceOf(data, address(this));

        // Calculate amount of tokens required for minting `amt` options & transfer the tokens to `impl`
        // Should move to safeTransfer here + Approve on impl?
        uint256 mintAmt = protocol.getMintAmt(data, amt, mintData);
        collateral.safeTransferFrom(msg.sender, impl, mintAmt);

        // Mint new options using the impl
        require(protocol.mint(data, amt, msg.sender, mintData), "OptionToken::mint-failed");

        // Verify that the contract has received new options
        uint256 newSubOptionBal = protocol.balanceOf(data, address(this));
        require(newSubOptionBal >= subOptionBal + amt, "OptionToken::token-not-received");

        // Mint Polynomial option tokens accordingly
        _mint(msg.sender, amt);

        emit Mint(impl, msg.sender, amt, mintData);
    }

    /**
     * @notice Mint Polynomial Option Token by submitting any of the implementation option tokens
     * @param impl Address of the implementation being used
     * @param amt Amount of options to mint
     * @param tokenData Additional token data for ERC721/1155
     */
    function wrap(address impl, uint256 amt, bytes memory tokenData) external nonReentrant {
        require(implementations[impl], "OptionToken::invalid-impl");
        require(block.timestamp < data.expiry, "OptionToken::expired");

        IProtocol protocol = IProtocol(impl);

        // Get token address if any
        (address token, DataTypes.TokenType tokenType) = protocol.getOptionToken(data);

        require(tokenType != DataTypes.TokenType.None, "OptionToken::not-tokenized");

        // Collect token from user
        if (tokenType == DataTypes.TokenType.ERC20) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amt);
        } else if (tokenType == DataTypes.TokenType.ERC721) {
            (uint256 tokenId) = abi.decode(tokenData, (uint256));
            IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId, "");
        } else if (tokenType == DataTypes.TokenType.ERC1155) {
            (uint256 id) = abi.decode(tokenData, (uint256));
            IERC1155(token).safeTransferFrom(msg.sender, address(this), id, amt, "");
        }

        _mint(msg.sender, amt);

        emit Wrap(impl, msg.sender, amt, tokenData);
    }

    /**
     * @notice Claim collateral before expiry, to be called by the minter (if allowed by the underlying protocol/impl)
     * @param impl Address of the implementation being used
     * @param amt Amount of options/collateral to claim
     * @param redeemData Additional data being passed down to the implementation. Used for passing impl specific data
     */
    function redeem(address impl, uint256 amt, bytes memory redeemData) external nonReentrant {
        require(implementations[impl], "OptionToken::invalid-impl");
        require(balanceOf(msg.sender) >= amt, "OptionToken::missing-options");
        require(block.timestamp < data.expiry, "OptionToken::expired");

        IProtocol protocol = IProtocol(impl);

        // Calculate pre-mint balance of options held by Polynomial Protocol
        uint256 subOptionBal = protocol.balanceOf(data, address(this));

        // Execute redeem
        require(protocol.redeem(data, amt, msg.sender, redeemData), "OptionToken::redeem-failed");

        // Verify that the contract has burned the options new options
        uint256 newSubOptionBal = protocol.balanceOf(data, address(this));
        require(newSubOptionBal >= subOptionBal - amt, "OptionToken::burn-failed");

        // Burn Polynomial option tokens accordingly
        _burn(msg.sender, amt);

        emit Redeem(impl, msg.sender, amt, redeemData);
    }

    /**
     * @notice Settle options & collaterals. Only called after expiry + 6 hours
     * @notice Settling happens once for all options and collateral. The option settlement from all impls are distributed to holders
     */
    function settle() external nonReentrant {
        require(block.timestamp >= data.expiry + 21600, "OptionToken::not-expired");

        IProtocol protocol;
        bytes32 id = keccak256(abi.encode(data));

        for (uint i = 0; i < protocols.length; i++) {
            protocol = protocols[i];

            if (!protocol.hasSettled(id)) {
                (bool isSuccess, uint256 payout) = protocol.settle(data);

                require(isSuccess, "OptionToken::settlement-failed");

                totalPayout += payout;
            }
        }

        if (totalSupplyAtExpiry == 0) {
            totalSupplyAtExpiry = totalSupply();
        }

        emit Settle();
    }

    /**
     @notice Settle one implementation
     @param impl Address of the implementation
     */
    function settleOne(address impl) external nonReentrant returns (bool) {
        require(implementations[impl], "OptionToken::invalid-impl");
        // Expiry + 6 Hours
        require(block.timestamp >= data.expiry + 21600, "OptionToken::not-expired");

        IProtocol protocol = IProtocol(impl);
        bytes32 id = keccak256(abi.encode(data));

        require(!protocol.hasSettled(id), "OptionToken::already-settled");

        (bool isSuccess, uint256 payout) = protocol.settle(data);

        require(isSuccess, "OptionToken::settlement-failed");

        totalPayout += payout;

        if (totalSupplyAtExpiry == 0) {
            totalSupplyAtExpiry = totalSupply();
        }

        emit SettleOne(impl);

        return true;
    }

    /**
     @notice Claim payout & remaining collateral from all impls
     */
    function claim() external nonReentrant {
        IProtocol protocol;
        bytes32 id = keccak256(abi.encode(data));
        uint256 userPayout;

        for (uint i = 0; i < protocols.length; i++) {
            protocol = protocols[i];
            require(protocol.hasSettled(id), "OptionToken::settlement-pending");

            uint256 payoutRatio = totalPayout.wdiv(totalSupplyAtExpiry);
            userPayout = payoutRatio.wmul(balanceOf(msg.sender));

            if (protocol.collateralBalanceOf(data, msg.sender) > 0) {
                protocol.claimCollateral(data, msg.sender);
            }
        }

        collateral.safeTransfer(msg.sender, userPayout);

        emit Claim(msg.sender, userPayout);
    }

    function onERC721Received(
        address , address , uint256 , bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address, address, uint256, uint256, bytes memory
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
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
import "../../../utils/Address.sol";

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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Date and time library
 */
library DateTimeLibrary {
    uint64 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint64 constant SECONDS_PER_HOUR = 60 * 60;
    uint64 constant SECONDS_PER_MINUTE = 60;
    int64 constant OFFSET19700101 = 2440588;

    uint256 private constant STRIKE_PRICE_SCALE = 1e8;
    uint256 private constant STRIKE_PRICE_DIGITS = 8;

    /**
     * @notice Authored by BokkyPooBah
     */
    function _daysToDate(uint64 _days) internal pure returns (uint64 year, uint64 month, uint64 day) {
        int64 __days = int64(_days);

        int64 L = __days + 68569 + OFFSET19700101;
        int64 N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int64 _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int64 _month = 80 * L / 2447;
        int64 _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint64(_year);
        month = uint64(_month);
        day = uint64(_day);
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function timestampToDate(uint64 timestamp) internal pure returns (uint64 year, uint64 month, uint64 day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     */
    function getMonthString(uint64 month) internal pure returns (string memory shortString, string memory longString) {
        if (month == 1) {
            return ("JAN", "January");
        } else if (month == 2) {
            return ("FEB", "February");
        } else if (month == 3) {
            return ("MAR", "March");
        } else if (month == 4) {
            return ("APR", "April");
        } else if (month == 5) {
            return ("MAY", "May");
        } else if (month == 6) {
            return ("JUN", "June");
        } else if (month == 7) {
            return ("JUL", "July");
        } else if (month == 8) {
            return ("AUG", "August");
        } else if (month == 9) {
            return ("SEP", "September");
        } else if (month == 10) {
            return ("OCT", "October");
        } else if (month == 11) {
            return ("NOV", "November");
        } else {
            return ("DEC", "December");
        }
    }

    function getTokenName(
        uint64 timestamp,
        uint256 strikePrice,
        string memory name,
        string memory symbol,
        bool isCall
    ) internal pure returns (string memory tokenName, string memory tokenSymbol) {
        (uint64 year, uint64 month, uint64 day) = timestampToDate(timestamp);
        (string memory shortMonth, ) = getMonthString(month);
        string memory displayStrikePrice = getDisplayedStrikePrice(strikePrice);

        string memory tail = isCall ? "-C" : "-P";
        string memory optionType = isCall ? " Call " : " Put ";

        tokenName = string(abi.encodePacked(
            "Polynomial ",
            name,
            optionType,
            uintTo2Chars(day),
            shortMonth,
            toString(year),
            " ",
            displayStrikePrice
        ));

        tokenSymbol = string(abi.encodePacked(
            "P-",
            symbol,
            "-",
            uintTo2Chars(day),
            shortMonth,
            toString(year),
            "-",
            displayStrikePrice,
            tail
        ));
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function getHour(uint64 timestamp) internal pure returns (uint64 hour) {
        uint64 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function getMinute(uint64 timestamp) internal pure returns (uint64 minute) {
        uint64 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function getSecond(uint64 timestamp) internal pure returns (uint64 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     * @dev return a representation of a number using 2 characters, adds a leading 0 if one digit, uses two trailing digits if a 3 digit number
     * @return str 2 characters that corresponds to a number
     */
    function uintTo2Chars(uint64 number) internal pure returns (string memory str) {
        if (number > 99) number = number % 100;
        str = toString(number);
        if (number < 10) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     * @dev convert strike price scaled by 1e8 to human readable number string
     * @param _strikePrice strike price scaled by 1e8
     * @return strike price string
     */
    function getDisplayedStrikePrice(uint256 _strikePrice) internal pure returns (string memory) {
        uint256 remainder = _strikePrice % STRIKE_PRICE_SCALE;
        uint256 quotient = _strikePrice / STRIKE_PRICE_SCALE;
        string memory quotientStr = toString256(quotient);

        if (remainder == 0) return quotientStr;

        uint256 trailingZeroes = 0;
        while (remainder % 10 == 0) {
            remainder = remainder / 10;
            trailingZeroes += 1;
        }

        // pad the number with "1 + starting zeroes"
        remainder += 10**(STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory tmpStr = toString256(remainder);
        tmpStr = slice(tmpStr, 1, 1 + STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory completeStr = string(abi.encodePacked(quotientStr, ".", tmpStr));
        return completeStr;
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     * @dev cut string s into s[start:end]
     * @param _s the string to cut
     * @param _start the starting index
     * @param _end the ending index (excluded in the substring)
     */
    function slice(
        string memory _s,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(_end - _start);
        for (uint256 i = 0; i < _end - _start; i++) {
            a[i] = bytes(_s)[_start + i];
        }
        return string(a);
    }



    /**
     * @notice Authored by OpenZeppelin
     * @dev Converts a `uint64` to its ASCII `string` decimal representation.
     */
    function toString(uint64 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint64 temp = value;
        uint64 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint64(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @notice Authored by OpenZeppelin
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString256(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DataTypes {
    // Asset specification
    struct Asset {
        bool isActive; // Whether the asset is active or not
        string name; // Name of the asset
        string symbol; // Symbol of the asset
    }

    // Option specification with implementations
    struct Option {
        uint64 expiry; // Expiry timestamp of the option
        bool isCall; // Whether the option is call or put
        uint256 strikePrice; // Strike price in 8 decimals
        address collateral; // Address of the collateral
        address underlying; // Address of the underlying
        address[] impls; // Array of valid implementations
    }

    // Option specification
    struct OptionData {
        uint64 expiry; // Expiry timestamp of the option
        bool isCall; // Whether the option is call or put
        uint256 strikePrice; // Strike price in 8 decimals
        address collateral; // Address of the collateral
        address underlying; // Address of the underlying
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        None
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PolyMath {
    function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 d) {
        d = a * b / c;
    }

    function mulDivCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 d) {
        d = mulDiv(a, b, c);
        uint256 mod = (a * b) % c;
        if (mod > 0) {
            d++;
        }
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = mulDiv(a, b, 10 ** 18);
    }

    function wmulCeil(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = mulDivCeil(a, b, 10 ** 18);
    }

    function wdiv(uint256 a, uint b) internal pure returns (uint256 c) {
        c = a * (10 ** 18) / b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DataTypes } from "../../libraries/DataTypes.sol";

interface IProtocol {

    /**
     * @notice Name of the implementation
     */
    function name() external view returns (string memory _name);

    /**
     * @notice This method checks whether the underlying protocol can mint options of the mentioned specs
     * @param isCall Whether the option is a call option
     * @param asset Address of the underlying asset
     * @param collateral Address of the collateral asset (if put option => asset ≠ collateral)
     */
    function isSupported(bool isCall, address asset, address collateral) external view returns (bool _isSupported);

    /**
     * @notice Returns whether the options have been settled from the protocol
     * @param id Option id/hash
     * @return _hasSettled Status of the settlement
     */
    function hasSettled(bytes32 id) external view returns (bool _hasSettled);

    /**
     * @notice This method calculates the amount of collateral required to mint a specified number of options
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of options being minted
     * @param mintData Additional mint data being passed to the protocol
     * @return _collateralNeeded Amount of collateral needed to mint the option
     */
    function getMintAmt(
        DataTypes.OptionData memory data,
        uint256 amt,
        bytes memory mintData
    ) external view returns (uint256 _collateralNeeded);

    /**
     * @notice Returns the address of the option token used by the protocol, if any
     * @param data Option specification. Check DataTypes.OptionData
     * @return _subOption Address of the option token used by the protocol, 0x0 if the protocol doesn't use any token
     * @return _type The type of token standard
     */
    function getOptionToken(DataTypes.OptionData memory data) external view returns (address _subOption, DataTypes.TokenType _type);

    /**
     * @notice Returns the amount of (sub)options held by an account. After taking care of protocols which doesn't use tokens to account
     * @param data Option specification. Check DataTypes.OptionData
     * @param account Address of the account to check
     * @return _bal Amount of options held by the account
     */
    function balanceOf(DataTypes.OptionData memory data, address account) external view returns (uint256 _bal);

    /**
     * @notice Returns the maximum amount of collateral that can be claimed by an account. After taking care of protocols which doesn't use tokens to account
     * @param data Option specification. Check DataTypes.OptionData
     * @param account Address of the account to check
     * @return _bal Amount of collateral claimed by the account
     */
    function collateralBalanceOf(DataTypes.OptionData memory data, address account) external view returns (uint256 _bal);
    
    /**
     * @notice Mint (sub)options and transfer to polynomial option, if any
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of options being minted
     * @param minter Address of the minter
     * @param mintData Additional mint data being passed to the protocol
     * @return _hasCreated Returns whether the action was successful
     */
    function mint(
        DataTypes.OptionData memory data,
        uint256 amt,
        address minter,
        bytes memory mintData
    ) external returns (bool _hasCreated);

    /**
     * @notice Redeem collateral before expiry
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of options to redeem
     * @param user Address of the account that is redeeming the tokens
     * @param redeemData Additional redeem data being passed to the protocol
     * @return _hasRedeemed Returns whether the action was successful
     */
    function redeem(
        DataTypes.OptionData memory data,
        uint256 amt,
        address user,
        bytes memory redeemData
    ) external returns (bool _hasRedeemed);

    /**
     * @notice Settle options and collateral after expiry + 6 hours
     * @param data Option specification. Check DataTypes.OptionData
     * @return _hasSettled Returns whether the action was successful
     */
    function settle(
        DataTypes.OptionData memory data
    ) external returns (bool _hasSettled, uint256 _returnedAmt);

    /**
     * @notice Claim collateral after settlement is completed
     * @param data Option specification. Check DataTypes.OptionData
     * @return _isSuccess Returns whether the action was successful
     */
    function claimCollateral(
        DataTypes.OptionData memory data
    ) external returns (bool _isSuccess);

    /**
     * @notice Claim collateral after settlement is completed (called by rootToken)
     * @param data Option specification. Check DataTypes.OptionData
     * @param user Address of the user
     * @return _isSuccess Returns whether the action was successful
     */
    function claimCollateral(
        DataTypes.OptionData memory data,
        address user
    ) external returns (bool _isSuccess);

    /**
     * @notice Transfer collateral
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of collateral to transfer
     * @param to Target account
     * @return _isSuccess Returns whether the action was successful
     */
    function transferCollateral(
        DataTypes.OptionData memory data,
        uint256 amt,
        address to
    ) external returns (bool _isSuccess);

    /**
     * @notice Create a (sub)option token if it is required by the protocol. Can be ignored for some protocols. Only called by optionRegistry
     * @param data Option specification. Check DataTypes.OptionData
     * @return _isSuccess Returns whether the action was successful
     */
    function create(
        DataTypes.Option memory data
    ) external returns (bool _isSuccess);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}