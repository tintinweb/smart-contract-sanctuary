// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./PendleBaseToken.sol";
import "../interfaces/IPendleForge.sol";
import "../interfaces/IPendleYieldTokenCommon.sol";

contract PendleFutureYieldToken is PendleBaseToken, IPendleYieldTokenCommon {
    address public immutable override forge;
    address public immutable override underlyingAsset;
    address public immutable override underlyingYieldToken;

    constructor(
        address _router,
        address _forge,
        address _underlyingAsset,
        address _underlyingYieldToken,
        string memory _name,
        string memory _symbol,
        uint8 _underlyingYieldTokenDecimals,
        uint256 _start,
        uint256 _expiry
    ) PendleBaseToken(_router, _name, _symbol, _underlyingYieldTokenDecimals, _start, _expiry) {
        require(
            _underlyingAsset != address(0) && _underlyingYieldToken != address(0),
            "ZERO_ADDRESS"
        );
        require(_forge != address(0), "ZERO_ADDRESS");
        forge = _forge;
        underlyingAsset = _underlyingAsset;
        underlyingYieldToken = _underlyingYieldToken;
    }

    modifier onlyForge() {
        require(msg.sender == address(forge), "ONLY_FORGE");
        _;
    }

    /**
     * @dev Burns OT or XYT tokens from user, reducing the total supply.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    function burn(address user, uint256 amount) public override onlyForge {
        _burn(user, amount);
        emit Burn(user, amount);
    }

    /**
     * @dev Mints new OT or XYT tokens for user, increasing the total supply.
     * @param user The address to send the minted tokens.
     * @param amount The amount to be minted.
     **/
    function mint(address user, uint256 amount) public override onlyForge {
        _mint(user, amount);
        emit Mint(user, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0))
            IPendleForge(forge).updateDueInterests(underlyingAsset, expiry, from);
        if (to != address(0)) IPendleForge(forge).updateDueInterests(underlyingAsset, expiry, to);
    }

    function approveRouter(address user) external {
        require(msg.sender == address(router), "NOT_ROUTER");
        _approve(user, address(router), type(uint256).max);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../interfaces/IPendleBaseToken.sol";
import "../interfaces/IPendleRouter.sol";

/**
 *   @title PendleBaseToken
 *   @dev The contract implements the standard ERC20 functions, plus some
 *        Pendle specific fields and functions, namely:
 *          - expiry
 *
 *        This abstract contract is inherited by PendleFutureYieldToken
 *        and PendleOwnershipToken contracts.
 **/
abstract contract PendleBaseToken is ERC20 {
    using SafeMath for uint256;

    uint256 public immutable start;
    uint256 public immutable expiry;
    IPendleRouter public immutable router;

    //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol
    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    //// End of EIP-2612 related part

    constructor(
        address _router,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _start,
        uint256 _expiry
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        start = _start;
        expiry = _expiry;
        router = IPendleRouter(_router);

        //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol, except for the noted parts below
        uint256 chainId;
        assembly {
            chainId := chainid() // chainid() is a function in assembly in this solidity version
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)), // use our own _name here
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        //// End of EIP-2612 related part
    }

    //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    //// End of EIP-2612 related part

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(to != address(this), "SEND_TO_TOKEN_CONTRACT");
        require(to != from, "SEND_TO_SELF");
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";
import "./IPendleRewardManager.sol";
import "./IPendleYieldContractDeployer.sol";
import "./IPendleData.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleForge {
    /**
     * @dev Emitted when the Forge has minted the OT and XYT tokens.
     * @param forgeId The forgeId
     * @param underlyingAsset The address of the underlying yield token.
     * @param expiry The expiry of the XYT token
     * @param amountToTokenize The amount of yield bearing assets to tokenize
     * @param amountTokenMinted The amount of OT/XYT minted
     **/
    event MintYieldTokens(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToTokenize,
        uint256 amountTokenMinted,
        address indexed user
    );

    /**
     * @dev Emitted when the Forge has created new yield token contracts.
     * @param forgeId The forgeId
     * @param underlyingAsset The address of the underlying asset.
     * @param expiry The date in epoch time when the contract will expire.
     * @param ot The address of the ownership token.
     * @param xyt The address of the new future yield token.
     **/
    event NewYieldContracts(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        address ot,
        address xyt,
        address yieldBearingAsset
    );

    /**
     * @dev Emitted when the Forge has redeemed the OT and XYT tokens.
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param amountToRedeem The amount of OT to be redeemed.
     * @param redeemedAmount The amount of yield token received
     **/
    event RedeemYieldToken(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToRedeem,
        uint256 redeemedAmount,
        address indexed user
    );

    /**
     * @dev Emitted when interest claim is settled
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param user Interest receiver Address
     * @param amount The amount of interest claimed
     **/
    event DueInterestsSettled(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amount,
        uint256 forgeFeeAmount,
        address indexed user
    );

    /**
     * @dev Emitted when forge fee is withdrawn
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param amount The amount of interest claimed
     **/
    event ForgeFeeWithdrawn(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amount
    );

    function setUpEmergencyMode(
        address _underlyingAsset,
        uint256 _expiry,
        address spender
    ) external;

    function newYieldContracts(address underlyingAsset, uint256 expiry)
        external
        returns (address ot, address xyt);

    function redeemAfterExpiry(
        address user,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        address user,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 interests);

    function updateDueInterests(
        address underlyingAsset,
        uint256 expiry,
        address user
    ) external;

    function updatePendingRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external;

    function redeemUnderlying(
        address user,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToRedeem
    ) external returns (uint256 redeemedAmount);

    function mintOtAndXyt(
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToTokenize,
        address to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    function withdrawForgeFee(address underlyingAsset, uint256 expiry) external;

    function getYieldBearingToken(address underlyingAsset) external returns (address);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    function data() external view returns (IPendleData);

    function rewardManager() external view returns (IPendleRewardManager);

    function yieldContractDeployer() external view returns (IPendleYieldContractDeployer);

    function rewardToken() external view returns (IERC20);

    /**
     * @notice Gets the bytes32 ID of the forge.
     * @return Returns the forge and protocol identifier.
     **/
    function forgeId() external view returns (bytes32);

    function dueInterests(
        address _underlyingAsset,
        uint256 expiry,
        address _user
    ) external view returns (uint256);

    function yieldTokenHolders(address _underlyingAsset, uint256 _expiry)
        external
        view
        returns (address yieldTokenHolder);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

interface IPendleYieldTokenCommon {
    /**
     * @notice Emitted when burning OT or XYT tokens.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    event Burn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when minting OT or XYT tokens.
     * @param user The address performing the mint.
     * @param amount The amount to be minted.
     **/
    event Mint(address indexed user, uint256 amount);

    /**
     * @notice Burns OT or XYT tokens from user, reducing the total supply.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    function burn(address user, uint256 amount) external;

    /**
     * @notice Mints new OT or XYT tokens for user, increasing the total supply.
     * @param user The address to send the minted tokens.
     * @param amount The amount to be minted.
     **/
    function mint(address user, uint256 amount) external;

    /**
     * @notice Gets the forge address of the PendleForge contract for this yield token.
     * @return Retuns the forge address.
     **/
    function forge() external view returns (address);

    /**
     * @notice Returns the address of the underlying asset.
     * @return Returns the underlying asset address.
     **/
    function underlyingAsset() external view returns (address);

    /**
     * @notice Returns the address of the underlying yield token.
     * @return Returns the underlying yield token address.
     **/
    function underlyingYieldToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleBaseToken is IERC20 {
    /**
     * @notice Decreases the allowance granted to spender by the caller.
     * @param spender The address to reduce the allowance from.
     * @param subtractedValue The amount allowance to subtract.
     * @return Returns true if allowance has decreased, otherwise false.
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice The yield contract start in epoch time.
     * @return Returns the yield start date.
     **/
    function start() external view returns (uint256);

    /**
     * @notice The yield contract expiry in epoch time.
     * @return Returns the yield expiry date.
     **/
    function expiry() external view returns (uint256);

    /**
     * @notice Increases the allowance granted to spender by the caller.
     * @param spender The address to increase the allowance from.
     * @param addedValue The amount allowance to add.
     * @return Returns true if allowance has increased, otherwise false
     **/
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Returns the number of decimals the token uses.
     * @return Returns the token's decimals.
     **/
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the token.
     * @return Returns the token's name.
     **/
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * @return Returns the token's symbol.
     **/
    function symbol() external view returns (string memory);

    /**
     * @notice approve using the owner's signature
     **/
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IWETH.sol";
import "./IPendleData.sol";
import "../libraries/PendleStructs.sol";
import "./IPendleMarketFactory.sol";

interface IPendleRouter {
    /**
     * @notice Emitted when a market for a future yield token and an ERC20 token is created.
     * @param marketFactoryId Forge identifier.
     * @param xyt The address of the tokenized future yield token as the base asset.
     * @param token The address of an ERC20 token as the quote asset.
     * @param market The address of the newly created market.
     **/
    event MarketCreated(
        bytes32 marketFactoryId,
        address indexed xyt,
        address indexed token,
        address indexed market
    );

    /**
     * @notice Emitted when a swap happens on the market.
     * @param trader The address of msg.sender.
     * @param inToken The input token.
     * @param outToken The output token.
     * @param exactIn The exact amount being traded.
     * @param exactOut The exact amount received.
     * @param market The market address.
     **/
    event SwapEvent(
        address indexed trader,
        address inToken,
        address outToken,
        uint256 exactIn,
        uint256 exactOut,
        address market
    );

    /**
     * @dev Emitted when user adds liquidity
     * @param sender The user who added liquidity.
     * @param token0Amount the amount of token0 (xyt) provided by user
     * @param token1Amount the amount of token1 provided by user
     * @param market The market address.
     * @param exactOutLp The exact LP minted
     */
    event Join(
        address indexed sender,
        uint256 token0Amount,
        uint256 token1Amount,
        address market,
        uint256 exactOutLp
    );

    /**
     * @dev Emitted when user removes liquidity
     * @param sender The user who removed liquidity.
     * @param token0Amount the amount of token0 (xyt) given to user
     * @param token1Amount the amount of token1 given to user
     * @param market The market address.
     * @param exactInLp The exact Lp to remove
     */
    event Exit(
        address indexed sender,
        uint256 token0Amount,
        uint256 token1Amount,
        address market,
        uint256 exactInLp
    );

    /**
     * @notice Gets a reference to the PendleData contract.
     * @return Returns the data contract reference.
     **/
    function data() external view returns (IPendleData);

    /**
     * @notice Gets a reference of the WETH9 token contract address.
     * @return WETH token reference.
     **/
    function weth() external view returns (IWETH);

    /***********
     *  FORGE  *
     ***********/

    function newYieldContracts(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (address ot, address xyt);

    function redeemAfterExpiry(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        address user
    ) external returns (uint256 interests);

    function redeemUnderlying(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToRedeem
    ) external returns (uint256 redeemedAmount);

    function renewYield(
        bytes32 forgeId,
        uint256 oldExpiry,
        address underlyingAsset,
        uint256 newExpiry,
        uint256 renewalRate
    )
        external
        returns (
            uint256 redeemedAmount,
            uint256 amountRenewed,
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    function tokenizeYield(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToTokenize,
        address to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    /***********
     *  MARKET *
     ***********/

    function addMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    )
        external
        payable
        returns (
            uint256 amountXytUsed,
            uint256 amountTokenUsed,
            uint256 lpOut
        );

    function addMarketLiquiditySingle(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        bool forXyt,
        uint256 exactInAsset,
        uint256 minOutLp
    ) external payable returns (uint256 exactOutLp);

    function removeMarketLiquidityDual(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        uint256 exactInLp,
        uint256 minOutXyt,
        uint256 minOutToken
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    function removeMarketLiquiditySingle(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        bool forXyt,
        uint256 exactInLp,
        uint256 minOutAsset
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    /**
     * @notice Creates a market given a protocol ID, future yield token, and an ERC20 token.
     * @param marketFactoryId Market Factory identifier.
     * @param xyt Token address of the future yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the address of the newly created market.
     **/
    function createMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token
    ) external returns (address market);

    function bootstrapMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external payable;

    function swapExactIn(
        address tokenIn,
        address tokenOut,
        uint256 inTotalAmount,
        uint256 minOutTotalAmount,
        bytes32 marketFactoryId
    ) external payable returns (uint256 outTotalAmount);

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 outTotalAmount,
        uint256 maxInTotalAmount,
        bytes32 marketFactoryId
    ) external payable returns (uint256 inTotalAmount);

    function redeemLpInterests(address market, address user) external returns (uint256 interests);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";
import "./IPendleYieldToken.sol";
import "./IPendlePausingManager.sol";
import "./IPendleMarket.sol";

interface IPendleData {
    /**
     * @notice Emitted when validity of a forge-factory pair is updated
     * @param _forgeId the forge id
     * @param _marketFactoryId the market factory id
     * @param _valid valid or not
     **/
    event ForgeFactoryValiditySet(bytes32 _forgeId, bytes32 _marketFactoryId, bool _valid);

    /**
     * @notice Emitted when Pendle and PendleFactory addresses have been updated.
     * @param treasury The address of the new treasury contract.
     **/
    event TreasurySet(address treasury);

    /**
     * @notice Emitted when LockParams is changed
     **/
    event LockParamsSet(uint256 lockNumerator, uint256 lockDenominator);

    /**
     * @notice Emitted when ExpiryDivisor is changed
     **/
    event ExpiryDivisorSet(uint256 expiryDivisor);

    /**
     * @notice Emitted when forge fee is changed
     **/
    event ForgeFeeSet(uint256 forgeFee);

    /**
     * @notice Emitted when interestUpdateRateDeltaForMarket is changed
     * @param interestUpdateRateDeltaForMarket new interestUpdateRateDeltaForMarket setting
     **/
    event InterestUpdateRateDeltaForMarketSet(uint256 interestUpdateRateDeltaForMarket);

    /**
     * @notice Emitted when market fees are changed
     * @param _swapFee new swapFee setting
     * @param _protocolSwapFee new protocolSwapFee setting
     **/
    event MarketFeesSet(uint256 _swapFee, uint256 _protocolSwapFee);

    /**
     * @notice Emitted when the curve shift block delta is changed
     * @param _blockDelta new block delta setting
     **/
    event CurveShiftBlockDeltaSet(uint256 _blockDelta);

    /**
     * @dev Emitted when new forge is added
     * @param marketFactoryId Human Readable Market Factory ID in Bytes
     * @param marketFactoryAddress The Market Factory Address
     */
    event NewMarketFactory(bytes32 indexed marketFactoryId, address indexed marketFactoryAddress);

    /**
     * @notice Set/update validity of a forge-factory pair
     * @param _forgeId the forge id
     * @param _marketFactoryId the market factory id
     * @param _valid valid or not
     **/
    function setForgeFactoryValidity(
        bytes32 _forgeId,
        bytes32 _marketFactoryId,
        bool _valid
    ) external;

    /**
     * @notice Sets the PendleTreasury contract addresses.
     * @param newTreasury Address of new treasury contract.
     **/
    function setTreasury(address newTreasury) external;

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function pausingManager() external view returns (IPendlePausingManager);

    /**
     * @notice Gets the treasury contract address where fees are being sent to.
     * @return Address of the treasury contract.
     **/
    function treasury() external view returns (address);

    /***********
     *  FORGE  *
     ***********/

    /**
     * @notice Emitted when a forge for a protocol is added.
     * @param forgeId Forge and protocol identifier.
     * @param forgeAddress The address of the added forge.
     **/
    event ForgeAdded(bytes32 indexed forgeId, address indexed forgeAddress);

    /**
     * @notice Adds a new forge for a protocol.
     * @param forgeId Forge and protocol identifier.
     * @param forgeAddress The address of the added forge.
     **/
    function addForge(bytes32 forgeId, address forgeAddress) external;

    /**
     * @notice Store new OT and XYT details.
     * @param forgeId Forge and protocol identifier.
     * @param ot The address of the new XYT.
     * @param xyt The address of the new XYT.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     **/
    function storeTokens(
        bytes32 forgeId,
        address ot,
        address xyt,
        address underlyingAsset,
        uint256 expiry
    ) external;

    /**
     * @notice Set a new forge fee
     * @param _forgeFee new forge fee
     **/
    function setForgeFee(uint256 _forgeFee) external;

    /**
     * @notice Gets the OT and XYT tokens.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingYieldToken Token address of the underlying yield token.
     * @param expiry Yield contract expiry in epoch time.
     * @return ot The OT token references.
     * @return xyt The XYT token references.
     **/
    function getPendleYieldTokens(
        bytes32 forgeId,
        address underlyingYieldToken,
        uint256 expiry
    ) external view returns (IPendleYieldToken ot, IPendleYieldToken xyt);

    /**
     * @notice Gets a forge given the identifier.
     * @param forgeId Forge and protocol identifier.
     * @return forgeAddress Returns the forge address.
     **/
    function getForgeAddress(bytes32 forgeId) external view returns (address forgeAddress);

    /**
     * @notice Checks if an XYT token is valid.
     * @param forgeId The forgeId of the forge.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     * @return True if valid, false otherwise.
     **/
    function isValidXYT(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (bool);

    /**
     * @notice Checks if an OT token is valid.
     * @param forgeId The forgeId of the forge.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     * @return True if valid, false otherwise.
     **/
    function isValidOT(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (bool);

    function validForgeFactoryPair(bytes32 _forgeId, bytes32 _marketFactoryId)
        external
        view
        returns (bool);

    /**
     * @notice Gets a reference to a specific OT.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingYieldToken Token address of the underlying yield token.
     * @param expiry Yield contract expiry in epoch time.
     * @return ot Returns the reference to an OT.
     **/
    function otTokens(
        bytes32 forgeId,
        address underlyingYieldToken,
        uint256 expiry
    ) external view returns (IPendleYieldToken ot);

    /**
     * @notice Gets a reference to a specific XYT.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingAsset Token address of the underlying asset
     * @param expiry Yield contract expiry in epoch time.
     * @return xyt Returns the reference to an XYT.
     **/
    function xytTokens(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (IPendleYieldToken xyt);

    /***********
     *  MARKET *
     ***********/

    event MarketPairAdded(address indexed market, address indexed xyt, address indexed token);

    function addMarketFactory(bytes32 marketFactoryId, address marketFactoryAddress) external;

    function isMarket(address _addr) external view returns (bool result);

    function isXyt(address _addr) external view returns (bool result);

    function addMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        address market
    ) external;

    function setMarketFees(uint256 _swapFee, uint256 _protocolSwapFee) external;

    function setInterestUpdateRateDeltaForMarket(uint256 _interestUpdateRateDeltaForMarket)
        external;

    function setLockParams(uint256 _lockNumerator, uint256 _lockDenominator) external;

    function setExpiryDivisor(uint256 _expiryDivisor) external;

    function setCurveShiftBlockDelta(uint256 _blockDelta) external;

    /**
     * @notice Displays the number of markets currently existing.
     * @return Returns markets length,
     **/
    function allMarketsLength() external view returns (uint256);

    function forgeFee() external view returns (uint256);

    function interestUpdateRateDeltaForMarket() external view returns (uint256);

    function expiryDivisor() external view returns (uint256);

    function lockNumerator() external view returns (uint256);

    function lockDenominator() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function protocolSwapFee() external view returns (uint256);

    function curveShiftBlockDelta() external view returns (uint256);

    function getMarketByIndex(uint256 index) external view returns (address market);

    /**
     * @notice Gets a market given a future yield token and an ERC20 token.
     * @param xyt Token address of the future yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the market address.
     **/
    function getMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token
    ) external view returns (address market);

    /**
     * @notice Gets a market factory given the identifier.
     * @param marketFactoryId MarketFactory identifier.
     * @return marketFactoryAddress Returns the factory address.
     **/
    function getMarketFactoryAddress(bytes32 marketFactoryId)
        external
        view
        returns (address marketFactoryAddress);

    function getMarketFromKey(
        address xyt,
        address token,
        bytes32 marketFactoryId
    ) external view returns (address market);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

struct TokenReserve {
    uint256 weight;
    uint256 balance;
}

struct PendingTransfer {
    uint256 amount;
    bool isOut;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";

interface IPendleMarketFactory {
    /**
     * @notice Creates a market given a protocol ID, future yield token, and an ERC20 token.
     * @param xyt Token address of the futuonlyCorere yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the address of the newly created market.
     **/
    function createMarket(address xyt, address token) external returns (address market);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    function marketFactoryId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPendleBaseToken.sol";
import "./IPendleForge.sol";

interface IPendleYieldToken is IERC20, IPendleBaseToken {
    /**
     * @notice Emitted when burning OT or XYT tokens.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    event Burn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when minting OT or XYT tokens.
     * @param user The address performing the mint.
     * @param amount The amount to be minted.
     **/
    event Mint(address indexed user, uint256 amount);

    /**
     * @notice Burns OT or XYT tokens from user, reducing the total supply.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    function burn(address user, uint256 amount) external;

    /**
     * @notice Mints new OT or XYT tokens for user, increasing the total supply.
     * @param user The address to send the minted tokens.
     * @param amount The amount to be minted.
     **/
    function mint(address user, uint256 amount) external;

    /**
     * @notice Gets the forge address of the PendleForge contract for this yield token.
     * @return Retuns the forge address.
     **/
    function forge() external view returns (IPendleForge);

    /**
     * @notice Returns the address of the underlying asset.
     * @return Returns the underlying asset address.
     **/
    function underlyingAsset() external view returns (address);

    /**
     * @notice Returns the address of the underlying yield token.
     * @return Returns the underlying yield token address.
     **/
    function underlyingYieldToken() external view returns (address);

    /**
     * @notice let the router approve itself to spend OT/XYT/LP from any wallet
     * @param user user to approve
     **/
    function approveRouter(address user) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendlePausingManager {
    event AddPausingAdmin(address admin);
    event RemovePausingAdmin(address admin);
    event PendingForgeEmergencyHandler(address _pendingForgeHandler);
    event PendingMarketEmergencyHandler(address _pendingMarketHandler);
    event PendingLiqMiningEmergencyHandler(address _pendingLiqMiningHandler);
    event ForgeEmergencyHandlerSet(address forgeEmergencyHandler);
    event MarketEmergencyHandlerSet(address marketEmergencyHandler);
    event LiqMiningEmergencyHandlerSet(address liqMiningEmergencyHandler);

    event PausingManagerLocked();
    event ForgeHandlerLocked();
    event MarketHandlerLocked();
    event LiqMiningHandlerLocked();

    event SetForgePaused(bytes32 forgeId, bool settingToPaused);
    event SetForgeAssetPaused(bytes32 forgeId, address underlyingAsset, bool settingToPaused);
    event SetForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool settingToPaused
    );

    event SetForgeLocked(bytes32 forgeId);
    event SetForgeAssetLocked(bytes32 forgeId, address underlyingAsset);
    event SetForgeAssetExpiryLocked(bytes32 forgeId, address underlyingAsset, uint256 expiry);

    event SetMarketFactoryPaused(bytes32 marketFactoryId, bool settingToPaused);
    event SetMarketPaused(bytes32 marketFactoryId, address market, bool settingToPaused);

    event SetMarketFactoryLocked(bytes32 marketFactoryId);
    event SetMarketLocked(bytes32 marketFactoryId, address market);

    event SetLiqMiningPaused(address liqMiningContract, bool settingToPaused);
    event SetLiqMiningLocked(address liqMiningContract);

    function forgeEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function marketEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function liqMiningEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function permLocked() external view returns (bool);

    function permForgeHandlerLocked() external view returns (bool);

    function permMarketHandlerLocked() external view returns (bool);

    function permLiqMiningHandlerLocked() external view returns (bool);

    function isPausingAdmin(address) external view returns (bool);

    function setPausingAdmin(address admin, bool isAdmin) external;

    function requestForgeHandlerChange(address _pendingForgeHandler) external;

    function requestMarketHandlerChange(address _pendingMarketHandler) external;

    function requestLiqMiningHandlerChange(address _pendingLiqMiningHandler) external;

    function applyForgeHandlerChange() external;

    function applyMarketHandlerChange() external;

    function applyLiqMiningHandlerChange() external;

    function lockPausingManagerPermanently() external;

    function lockForgeHandlerPermanently() external;

    function lockMarketHandlerPermanently() external;

    function lockLiqMiningHandlerPermanently() external;

    function setForgePaused(bytes32 forgeId, bool paused) external;

    function setForgeAssetPaused(
        bytes32 forgeId,
        address underlyingAsset,
        bool paused
    ) external;

    function setForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool paused
    ) external;

    function setForgeLocked(bytes32 forgeId) external;

    function setForgeAssetLocked(bytes32 forgeId, address underlyingAsset) external;

    function setForgeAssetExpiryLocked(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external;

    function checkYieldContractStatus(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (bool _paused, bool _locked);

    function setMarketFactoryPaused(bytes32 marketFactoryId, bool paused) external;

    function setMarketPaused(
        bytes32 marketFactoryId,
        address market,
        bool paused
    ) external;

    function setMarketFactoryLocked(bytes32 marketFactoryId) external;

    function setMarketLocked(bytes32 marketFactoryId, address market) external;

    function checkMarketStatus(bytes32 marketFactoryId, address market)
        external
        returns (bool _paused, bool _locked);

    function setLiqMiningPaused(address liqMiningContract, bool settingToPaused) external;

    function setLiqMiningLocked(address liqMiningContract) external;

    function checkLiqMiningStatus(address liqMiningContract)
        external
        returns (bool _paused, bool _locked);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IPendleRouter.sol";
import "./IPendleBaseToken.sol";
import "../libraries/PendleStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleMarket is IERC20 {
    /**
     * @notice Emitted when reserves pool has been updated
     * @param reserve0 The XYT reserves.
     * @param weight0  The XYT weight
     * @param reserve1 The generic token reserves.
     * For the generic Token weight it can be inferred by (2^40) - weight0
     **/
    event Sync(uint256 reserve0, uint256 weight0, uint256 reserve1);

    function setUpEmergencyMode(address spender) external;

    function bootstrap(
        address user,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external returns (PendingTransfer[2] memory transfers, uint256 exactOutLp);

    function addMarketLiquiditySingle(
        address user,
        address inToken,
        uint256 inAmount,
        uint256 minOutLp
    ) external returns (PendingTransfer[2] memory transfers, uint256 exactOutLp);

    function addMarketLiquidityDual(
        address user,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    ) external returns (PendingTransfer[2] memory transfers, uint256 lpOut);

    function removeMarketLiquidityDual(
        address user,
        uint256 inLp,
        uint256 minOutXyt,
        uint256 minOutToken
    ) external returns (PendingTransfer[2] memory transfers);

    function removeMarketLiquiditySingle(
        address user,
        address outToken,
        uint256 exactInLp,
        uint256 minOutToken
    ) external returns (PendingTransfer[2] memory transfers);

    function swapExactIn(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 minOutAmount
    ) external returns (uint256 outAmount, PendingTransfer[2] memory transfers);

    function swapExactOut(
        address inToken,
        uint256 maxInAmount,
        address outToken,
        uint256 outAmount
    ) external returns (uint256 inAmount, PendingTransfer[2] memory transfers);

    function redeemLpInterests(address user) external returns (uint256 interests);

    function getReserves()
        external
        view
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        );

    function factoryId() external view returns (bytes32);

    function token() external view returns (address);

    function xyt() external view returns (address);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendleRewardManager {
    event UpdateFrequencySet(address[], uint256[]);
    event SkippingRewardsSet(bool);

    event DueRewardsSettled(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountOut,
        address user
    );

    function redeemRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external returns (uint256 dueRewards);

    function updatePendingRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external;

    function updateParamLManual(address _underlyingAsset, uint256 _expiry) external;

    function setUpdateFrequency(
        address[] calldata underlyingAssets,
        uint256[] calldata frequencies
    ) external;

    function setSkippingRewards(bool skippingRewards) external;

    function forgeId() external returns (bytes32);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendleYieldContractDeployer {
    function forgeId() external returns (bytes32);

    function forgeOwnershipToken(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _expiry
    ) external returns (address ot);

    function forgeFutureYieldToken(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _expiry
    ) external returns (address xyt);

    function deployYieldTokenHolder(address yieldToken, uint256 expiry)
        external
        returns (address yieldTokenHolder);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}