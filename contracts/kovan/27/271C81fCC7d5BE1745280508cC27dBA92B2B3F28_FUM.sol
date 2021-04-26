// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "erc20permit/contracts/ERC20Permit.sol";
import "./IUSM.sol";
import "./WithOptOut.sol";
import "./Ownable.sol";
import "./MinOut.sol";
import "./IUSM.sol";


/**
 * @title FUM Token
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 *
 * @notice This should be owned by the stablecoin.
 */
contract FUM is ERC20Permit, WithOptOut, Ownable {
    IUSM public immutable usm;

    constructor(IUSM usm_, address[] memory optedOut_, string memory name, string memory symbol)
        ERC20Permit(name, symbol)
        WithOptOut(optedOut_)
    {
        usm = usm_;
    }

    /**
     * @notice If anyone sends ETH here, assume they intend it as a `fund`.
     * If decimals 8 to 11 (included) of the amount of Ether received are `0000` then the next 7 will
     * be parsed as the minimum Ether price accepted, with 2 digits before and 5 digits after the comma.
     */
    receive() external payable {
        usm.fund{ value: msg.value }(msg.sender, MinOut.parseMinTokenOut(msg.value));
    }

    /**
     * @notice If a user sends FUM tokens directly to this contract (or to the USM contract), assume they intend it as a `defund`.
     * If using `transfer`/`transferFrom` as `defund`, and if decimals 8 to 11 (included) of the amount transferred received
     * are `0000` then the next 7 will be parsed as the maximum FUM price accepted, with 5 digits before and 2 digits after the comma.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override noOptOut(recipient) returns (bool) {
        if (recipient == address(this) || recipient == address(usm) || recipient == address(0)) {
            usm.defund(sender, payable(sender), amount, MinOut.parseMinEthOut(amount));
        } else {
            super._transfer(sender, recipient, amount);
        }
        return true;
    }

    /**
     * @notice Mint new FUM to the _recipient
     *
     * @param _recipient address to mint to
     * @param _amount amount to mint
     */
    function mint(address _recipient, uint _amount) external onlyOwner {
        _mint(_recipient, _amount);
    }

    /**
     * @notice Burn FUM from _holder
     *
     * @param _holder address to burn from
     * @param _amount amount to burn
     */
    function burn(address _holder, uint _amount) external onlyOwner {
        _burn(_holder, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/contracts/token/ERC20/ERC20Permit.sol
pragma solidity ^0.8.0;

import "acc-erc20/contracts/ERC20.sol";
import "./IERC2612.sol";

/**
 * @author Georgios Konstantopoulos
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _approve(owner, spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "acc-erc20/contracts/IERC20.sol";
import "./WadMath.sol";

abstract contract IUSM is IERC20 {
    enum Side {Buy, Sell}

    function mint(address to, uint minUsmOut) external virtual payable returns (uint);
    function burn(address from, address payable to, uint usmToBurn, uint minEthOut) external virtual returns (uint);
    function fund(address to, uint minFumOut) external virtual payable returns (uint);
    function defund(address from, address payable to, uint fumToBurn, uint minEthOut) external virtual returns (uint);

    function refreshPrice() public virtual returns (uint price, uint updateTime);

    function latestPrice() public virtual view returns (uint price, uint updateTime);
    function latestOraclePrice() public virtual view returns (uint price, uint updateTime);
    function ethPool() public virtual view returns (uint pool);
    function fumTotalSupply() public virtual view returns (uint supply);
    function bidAskAdjustment() public virtual view returns (uint adjustment);
    function timeSystemWentUnderwater() public virtual view returns (uint timestamp);

    function ethBuffer(uint ethUsdPrice, uint ethInPool, uint usmSupply, WadMath.Round upOrDown) public virtual pure returns (int buffer);
    function debtRatio(uint ethUsdPrice, uint ethInPool, uint usmSupply) public virtual pure returns (uint ratio);
    function ethToUsm(uint ethUsdPrice, uint ethAmount, WadMath.Round upOrDown) public virtual pure returns (uint usmOut);
    function usmToEth(uint ethUsdPrice, uint usmAmount, WadMath.Round upOrDown) public virtual pure returns (uint ethOut);
    function usmPrice(Side side, uint ethUsdPrice, uint debtRatio_) public virtual pure returns (uint price);
    function fumPrice(Side side, uint ethUsdPrice, uint ethInPool, uint usmEffectiveSupply, uint fumSupply, uint adjustment) public virtual pure returns (uint price);
    function checkIfUnderwater(uint usmActualSupply, uint ethPool_, uint ethUsdPrice, uint oldTimeUnderwater, uint currentTime) public virtual pure returns (uint timeSystemWentUnderwater_, uint usmSupplyForFumBuys);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


abstract contract WithOptOut {
    mapping(address => bool) public optedOut;  // true = address opted out of something

    constructor(address[] memory optedOut_) {
        for (uint i = 0; i < optedOut_.length; i++) {
            optedOut[optedOut_[i]] = true;
        }
    }

    modifier noOptOut(address target) {
        require(!optedOut[target], "Target opted out");
        _;
    }

    function optOut() public virtual {
        optedOut[msg.sender] = true;
    }

    function optBackIn() public virtual {
        optedOut[msg.sender] = false;
    }
}

// SPDX-License-Identifier: MIT
// Original from OpenZeppelin

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library MinOut {
    function parseMinTokenOut(uint ethIn) internal pure returns (uint minTokenOut) {
        uint minPrice = ethIn % 100000000000;
        if (minPrice != 0 && minPrice < 10000000) {
            minTokenOut = ethIn * minPrice / 100;
        }
    }

    function parseMinEthOut(uint tokenIn) internal pure returns (uint minEthOut) {
        uint maxPrice = tokenIn % 100000000000;
        if (maxPrice != 0 && maxPrice < 10000000) {
            minEthOut = tokenIn * 100 / maxPrice;
        }
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub

pragma solidity  ^0.8.0;
import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public    symbol;
    uint256                                           public    decimals = 18; // standard token precision. override to customize
    string                                            public    name = "";     // Optional token name

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address guy) public view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint wad) public virtual override returns (bool) {
        return _approve(msg.sender, spender, wad);
    }

    function transfer(address dst, uint wad) public virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public virtual override returns (bool) {
        uint256 allowed = _allowance[src][msg.sender];
        if (src != msg.sender && allowed != type(uint).max) {
            require(allowed >= wad, "ERC20: Insufficient approval");
            _approve(src, msg.sender, allowed - wad);
        }

        return _transfer(src, dst, wad);
    }

    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        _balanceOf[src] = _balanceOf[src] - wad;
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function _approve(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);
        return true;
    }

    function _mint(address dst, uint wad) internal virtual {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);
    }

    function _burn(address src, uint wad) internal virtual {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        _balanceOf[src] = _balanceOf[src] - wad;
        _totalSupply = _totalSupply - wad;
        emit Transfer(src, address(0), wad);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


/**
 * @title Fixed point arithmetic library
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 */
library WadMath {
    enum Round {Down, Up}

    uint public constant WAD = 10 ** 18;
    uint public constant WAD_MINUS_1 = WAD - 1;
    uint public constant WAD_OVER_10 = WAD / 10;
    uint public constant WAD_OVER_20 = WAD / 20;
    uint public constant HALF_TO_THE_ONE_TENTH = 933032991536807416;
    uint public constant LOG_2_WAD_SCALED = 158961593653514369813532673448321674075;   // log_2(10**18) * 2**121
    uint public constant LOG_2_E_SCALED_OVER_WAD = 3835341275459348170;                // log_2(e) * 2**121 / 10**18

    function wadMul(uint x, uint y, Round upOrDown) internal pure returns (uint z) {
        z = (upOrDown == Round.Down ? wadMulDown(x, y) : wadMulUp(x, y));
    }

    function wadMulDown(uint x, uint y) internal pure returns (uint z) {
        z = x * y;                  // Rounds down, truncating the last 18 digits.  So (imagining 2 dec places rather than 18):
        unchecked { z /= WAD; }     // 369 (3.69) * 271 (2.71) -> 99999 (9.9999) -> 999 (9.99).
    }

    function wadMulUp(uint x, uint y) internal pure returns (uint z) {
        z = x * y + WAD_MINUS_1;    // Rounds up.  So (again imagining 2 decimal places):
        unchecked { z /= WAD; }     // 383 (3.83) * 235 (2.35) -> 90005 (9.0005), + 99 (0.0099) -> 90104, / 100 -> 901 (9.01).
    }

    function wadDiv(uint x, uint y, Round upOrDown) internal pure returns (uint z) {
        z = (upOrDown == Round.Down ? wadDivDown(x, y) : wadDivUp(x, y));
    }

    function wadDivDown(uint x, uint y) internal pure returns (uint z) {
        z = (x * WAD) / y;          // Rounds down: 199 (1.99) / 1000 (10) -> (199 * 100) / 1000 -> 19 (0.19: 0.199 truncated).
    }

    function wadDivUp(uint x, uint y) internal pure returns (uint z) {
        z = x * WAD + y;            // 101 (1.01) / 1000 (10) -> (101 * 100 + 1000 - 1) / 1000 -> 11 (0.11 = 0.101 rounded up).
        unchecked { z -= 1; }       // Can do unchecked subtraction since division in next line will catch y = 0 case anyway
        z /= y;
    }

    function wadMax(uint x, uint y) internal pure returns (uint z) {
        z = (x > y ? x : y);
    }

    function wadMin(uint x, uint y) internal pure returns (uint z) {
        z = (x < y ? x : y);
    }

    /**
     * @return exp Just returns `wadHalfExp(power, MAX_VALUE)`, ie, an approximation of 0.5**`power`, with `power` uncapped.
     */
    function wadHalfExp(uint power) internal pure returns (uint exp) {
        exp = wadHalfExp(power, type(uint).max);
    }

    /**
     * @return exp a loose but "gas-efficient" approximation of 0.5**power, where power is rounded to the nearest 0.1, and is
     * capped at maxPower.  Note power is WAD-scaled (eg, 2.7364 * WAD), but maxPower is just a plain unscaled uint (eg, 10).
     * Negative powers are not handled (as implied by power being a uint).
     */
    function wadHalfExp(uint power, uint maxPower) internal pure returns (uint exp) {
        uint powerInTenthsUnscaled = power + WAD_OVER_20;       // Rounds 2.7499 -> 2.7, 2.7500 -> 2.8
        unchecked { powerInTenthsUnscaled /= WAD_OVER_10; }
        uint powerUnscaled;
        unchecked { powerUnscaled = powerInTenthsUnscaled / 10; }
        if (powerUnscaled <= maxPower) {    // If not, then 0.5**power is (more or less) tiny, so we just return exp = 0
            exp = wadPow(HALF_TO_THE_ONE_TENTH, powerInTenthsUnscaled);
        }
    }

    /**
     * @notice Adapted from rpow() in https://github.com/dapphub/ds-math/blob/master/src/math.sol - thank you!
     *
     * This famous algorithm is called "exponentiation by squaring" and calculates x^n with x as fixed-point and n as regular
     * unsigned.
     *
     * It's O(log n), instead of O(n) for naive repeated multiplication.
     *
     * These facts are why it works:
     *
     * - If n is even, then x^n = (x^2)^(n/2).
     * - If n is odd,  then x^n = x * x^(n-1),
     *   and applying the equation for even x gives
     *   x^n = x * (x^2)^((n-1) / 2).
     *
     * Also, EVM division is flooring and floor[(n-1) / 2] = floor[n / 2].
     */
    function wadPow(uint x, uint n) internal pure returns (uint z) {
        unchecked { z = n % 2 != 0 ? x : WAD; }

        unchecked { n /= 2; }
        bool divide;
        while (n != 0) {
            x = wadMulDown(x, x);

            unchecked { divide = n % 2 != 0; }
            if (divide) {
                z = wadMulDown(z, x);
            }
            unchecked { n /= 2; }
        }
    }

    /**
     * @return z The (approximate!) natural logarithm of x, where both x and the return value are in WAD fixed-point form.
     * @dev We're given X = x * 10**18 (WAD-formatted); we want to return Z = z * 10**18, where z =~ ln(x); and we have
     * `log_2(x)` below, which returns Y = y * 2**121, where y =~ log2(x).  So the math we use is:
     *
     *     K1 = log2(10**18) * 2**121
     *     K2 = log2(e) * 2**121 / 10**18
     *     Z = (`log_2(X)` - K1) / K2
     *       = (`log_2(x * 10**18)` - log2(10**18) * 2**121) / (log2(e) * 2**121 / 10**18)
     *       = (log2(x * 10**18) * 2**121 - log2(10**18) * 2**121) / (log2(e) * 2**121 / 10**18)
     *       = (log2(x * 10**18) - log2(10**18)) / (log2(e) / 10**18)
     *       = (log2(x) / log2(e)) * 10**18
     *       = ln(x) * 10**18
     */
    function wadLog(uint x) internal pure returns (int z) {
        require(x <= type(uint128).max, "x overflow");
        z = int(log_2(uint128(x)));
        unchecked { z = (z - int(LOG_2_WAD_SCALED)) / int(LOG_2_E_SCALED_OVER_WAD); }
    }

    /**
     * @return z e raised to the given power `y` (approximately!), specified in WAD 18-digit fixed-point form, and in, again,
     * WAD form.
     * @notice This library works only on positive uint inputs.  If you have a negative exponent (y < 0), you can calculate it
     * using this identity:
     *
     *     wadExp(y < 0) = 1 / wadExp(-y > 0) = WAD.div(wadExp(-y > 0))
     *
     * @dev We're given Y = y * 10**18 (WAD-formatted); we want to return Z = z * 10**18, where z =~ e**y; and we have
     * `pow_2(X = x * 2**121)` below, which returns y =~ 2**x = 2**(X / 2**121).  So the math we use is:
     *
     *     K1 = log2(10**18) * 2**121
     *     K2 = log2(e) * 2**121 / 10**18
     *     Z = `pow_2(K1 + K2 * Y)`
     *       = 2**((K1 + K2 * Y) / 2**121)
     *       = 2**((log2(10**18) * 2**121 + (log2(e) * 2**121 / 10**18) * (y * 10**18)) / 2**121)
     *       = 2**(log2(10**18) + log2(e) * y)
     *       = 2**(log2(10**18)) * 2**(log2(e) * y)
     *       = 10**18 * (2**log2(e))**y
     *       = e**y * 10**18
     */
    function wadExp(uint y) internal pure returns (uint z) {
        uint exponent = LOG_2_WAD_SCALED + LOG_2_E_SCALED_OVER_WAD * y;
        require(exponent <= type(uint128).max, "exponent overflow");
        z = pow_2(uint128(exponent));
    }

    /**
     * @return z The given number `x` raised to power `y` (approximately!), with all of `x`, `y` and `z` in WAD 18-digit
     * fixed-point form.
     * @notice This library works only on positive uint inputs.  If you have a negative base (x < 0) or a negative exponent
     * (y < 0), you can calculate them using these identities:
     *
     *     wadExp(x < 0, y) = -wadExp(-x > 0, y)
     *     wadExp(x, y < 0) = 1 / wadExp(x, -y > 0) = WAD.div(wadExp(x, -y > 0))
     *
     * @dev We're given X = x * 10**18, and Y = y * 10**18 (both WAD-formatted); we want Z = z * 10**18, where z =~ x**y; and
     * we have `log_2(x)`, which returns log2(x) * 2**121, and `pow_2(X = x * 2**121)`, which returns 2**x = 2**(X / 2**121).
     * The math we use is (essentially):
     *
     *     K = log2(10**18) * 2**121
     *     Z = `pow_2(K + (log_2(X) - K) * Y / 10**18)`
     *       = 2**((K + (log2(X) * 2**121 - K) * Y / 10**18) / 2**121)
     *       = 2**((log2(10**18) * 2**121 + (log2(x * 10**18) * 2**121 - log2(10**18) * 2**121) * (y * 10**18) / 10**18) / 2**121)
     *       = 2**(log2(10**18) + (log2(x * 10**18) - log2(10**18)) * y)
     *       = 2**(log2(10**18) + log2(x) * y)
     *       = 2**(log2(10**18)) * 2**(log2(x) * y)
     *       = 10**18 * (2**log2(x))**y
     *       = x**y * 10**18
     *
     * Except, because we're working with unsigned numbers, we need to be careful to handle two cases separately:
     * log_2(X) >= K, and log_2(X) < K.
     */
    function wadExp(uint x, uint y) internal pure returns (uint z) {
        require(x <= type(uint128).max, "x overflow");
        uint logX = log_2(uint128(x));
        uint exponent;
        if (logX >= LOG_2_WAD_SCALED) {
            // Case 1: Z = pow_2(LOG_2_WAD_SCALED + (log_2(X) - LOG_2_WAD_SCALED) * Y / WAD):
            unchecked { exponent = logX - LOG_2_WAD_SCALED; }
            exponent = LOG_2_WAD_SCALED + wadMulDown(exponent, y);
            require(exponent <= type(uint128).max, "exponent overflow");
            z = pow_2(uint128(exponent));
        } else {
            // Case 2: Z = pow_2(LOG_2_WAD_SCALED - (LOG_2_WAD_SCALED - log_2(X)) * Y / WAD):
            uint exponentSubtrahend;
            unchecked { exponentSubtrahend = LOG_2_WAD_SCALED - logX; }
            exponentSubtrahend = wadMulDown(exponentSubtrahend, y);
            if (exponentSubtrahend <= LOG_2_WAD_SCALED) {
                unchecked { exponent = LOG_2_WAD_SCALED - exponentSubtrahend; }
                z = pow_2(uint128(exponent));   // Needn't check for overflow since exp <= LOG_2_WAD_SCALED < type(uint128).max
            } else {
                // z = 0: exponent would be < 0, so pow_2(exponent) is vanishingly small (as a WAD-formatted num) - call it 0
            }
        }
    }

    /* ____________________ Exponential/logarithm fns borrowed from Yield Protocol ____________________
     *
     * See https://github.com/yieldprotocol/yieldspace-v1/blob/master/contracts/YieldMath.sol for Yield's code, originally
     * developed by the math gurus at https://www.abdk.consulting/.
     */

    /**
     * Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert in case x is zero.
     *
     * @param x number to calculate base 2 logarithm of
     * @return z base 2 logarithm of x, multiplied by 2^121
     */
    function log_2(uint128 x)
        internal pure returns (uint128 z)
    {
        unchecked {
            require (x != 0, "x = 0");

            uint b = x;

            uint l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {l -= 0x80000000000000000000000000000000; b <<= 64;}
            if (b < 0x1000000000000000000000000) {l -= 0x40000000000000000000000000000000; b <<= 32;}
            if (b < 0x10000000000000000000000000000) {l -= 0x20000000000000000000000000000000; b <<= 16;}
            if (b < 0x1000000000000000000000000000000) {l -= 0x10000000000000000000000000000000; b <<= 8;}
            if (b < 0x10000000000000000000000000000000) {l -= 0x8000000000000000000000000000000; b <<= 4;}
            if (b < 0x40000000000000000000000000000000) {l -= 0x4000000000000000000000000000000; b <<= 2;}
            if (b < 0x80000000000000000000000000000000) {l -= 0x2000000000000000000000000000000; b <<= 1;}

            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000;}
            /* Precision reduced to 64 bits
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) l |= 0x1;
            */

            z = uint128(l);
        }
    }

    /**
     * Calculate 2 raised into given power.
     *
     * @param x power to raise 2 into, multiplied by 2^121
     * @return z 2 raised into given power
     */
    function pow_2(uint128 x)
        internal pure returns (uint128 z)
    {
        unchecked {
            uint r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0) r = r * 0xb504f333f9de6484597d89b3754abe9f >> 127;
            if (x & 0x800000000000000000000000000000 > 0) r = r * 0x9837f0518db8a96f46ad23182e42f6f6 >> 127;
            if (x & 0x400000000000000000000000000000 > 0) r = r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90 >> 127;
            if (x & 0x200000000000000000000000000000 > 0) r = r * 0x85aac367cc487b14c5c95b8c2154c1b2 >> 127;
            if (x & 0x100000000000000000000000000000 > 0) r = r * 0x82cd8698ac2ba1d73e2a475b46520bff >> 127;
            if (x & 0x80000000000000000000000000000 > 0) r = r * 0x8164d1f3bc0307737be56527bd14def4 >> 127;
            if (x & 0x40000000000000000000000000000 > 0) r = r * 0x80b1ed4fd999ab6c25335719b6e6fd20 >> 127;
            if (x & 0x20000000000000000000000000000 > 0) r = r * 0x8058d7d2d5e5f6b094d589f608ee4aa2 >> 127;
            if (x & 0x10000000000000000000000000000 > 0) r = r * 0x802c6436d0e04f50ff8ce94a6797b3ce >> 127;
            if (x & 0x8000000000000000000000000000 > 0) r = r * 0x8016302f174676283690dfe44d11d008 >> 127;
            if (x & 0x4000000000000000000000000000 > 0) r = r * 0x800b179c82028fd0945e54e2ae18f2f0 >> 127;
            if (x & 0x2000000000000000000000000000 > 0) r = r * 0x80058baf7fee3b5d1c718b38e549cb93 >> 127;
            if (x & 0x1000000000000000000000000000 > 0) r = r * 0x8002c5d00fdcfcb6b6566a58c048be1f >> 127;
            if (x & 0x800000000000000000000000000 > 0) r = r * 0x800162e61bed4a48e84c2e1a463473d9 >> 127;
            if (x & 0x400000000000000000000000000 > 0) r = r * 0x8000b17292f702a3aa22beacca949013 >> 127;
            if (x & 0x200000000000000000000000000 > 0) r = r * 0x800058b92abbae02030c5fa5256f41fe >> 127;
            if (x & 0x100000000000000000000000000 > 0) r = r * 0x80002c5c8dade4d71776c0f4dbea67d6 >> 127;
            if (x & 0x80000000000000000000000000 > 0) r = r * 0x8000162e44eaf636526be456600bdbe4 >> 127;
            if (x & 0x40000000000000000000000000 > 0) r = r * 0x80000b1721fa7c188307016c1cd4e8b6 >> 127;
            if (x & 0x20000000000000000000000000 > 0) r = r * 0x8000058b90de7e4cecfc487503488bb1 >> 127;
            if (x & 0x10000000000000000000000000 > 0) r = r * 0x800002c5c8678f36cbfce50a6de60b14 >> 127;
            if (x & 0x8000000000000000000000000 > 0) r = r * 0x80000162e431db9f80b2347b5d62e516 >> 127;
            if (x & 0x4000000000000000000000000 > 0) r = r * 0x800000b1721872d0c7b08cf1e0114152 >> 127;
            if (x & 0x2000000000000000000000000 > 0) r = r * 0x80000058b90c1aa8a5c3736cb77e8dff >> 127;
            if (x & 0x1000000000000000000000000 > 0) r = r * 0x8000002c5c8605a4635f2efc2362d978 >> 127;
            if (x & 0x800000000000000000000000 > 0) r = r * 0x800000162e4300e635cf4a109e3939bd >> 127;
            if (x & 0x400000000000000000000000 > 0) r = r * 0x8000000b17217ff81bef9c551590cf83 >> 127;
            if (x & 0x200000000000000000000000 > 0) r = r * 0x800000058b90bfdd4e39cd52c0cfa27c >> 127;
            if (x & 0x100000000000000000000000 > 0) r = r * 0x80000002c5c85fe6f72d669e0e76e411 >> 127;
            if (x & 0x80000000000000000000000 > 0) r = r * 0x8000000162e42ff18f9ad35186d0df28 >> 127;
            if (x & 0x40000000000000000000000 > 0) r = r * 0x80000000b17217f84cce71aa0dcfffe7 >> 127;
            if (x & 0x20000000000000000000000 > 0) r = r * 0x8000000058b90bfc07a77ad56ed22aaa >> 127;
            if (x & 0x10000000000000000000000 > 0) r = r * 0x800000002c5c85fdfc23cdead40da8d6 >> 127;
            if (x & 0x8000000000000000000000 > 0) r = r * 0x80000000162e42fefc25eb1571853a66 >> 127;
            if (x & 0x4000000000000000000000 > 0) r = r * 0x800000000b17217f7d97f692baacded5 >> 127;
            if (x & 0x2000000000000000000000 > 0) r = r * 0x80000000058b90bfbead3b8b5dd254d7 >> 127;
            if (x & 0x1000000000000000000000 > 0) r = r * 0x8000000002c5c85fdf4eedd62f084e67 >> 127;
            if (x & 0x800000000000000000000 > 0) r = r * 0x800000000162e42fefa58aef378bf586 >> 127;
            if (x & 0x400000000000000000000 > 0) r = r * 0x8000000000b17217f7d24a78a3c7ef02 >> 127;
            if (x & 0x200000000000000000000 > 0) r = r * 0x800000000058b90bfbe9067c93e474a6 >> 127;
            if (x & 0x100000000000000000000 > 0) r = r * 0x80000000002c5c85fdf47b8e5a72599f >> 127;
            if (x & 0x80000000000000000000 > 0) r = r * 0x8000000000162e42fefa3bdb315934a2 >> 127;
            if (x & 0x40000000000000000000 > 0) r = r * 0x80000000000b17217f7d1d7299b49c46 >> 127;
            if (x & 0x20000000000000000000 > 0) r = r * 0x8000000000058b90bfbe8e9a8d1c4ea0 >> 127;
            if (x & 0x10000000000000000000 > 0) r = r * 0x800000000002c5c85fdf4745969ea76f >> 127;
            if (x & 0x8000000000000000000 > 0) r = r * 0x80000000000162e42fefa3a0df5373bf >> 127;
            if (x & 0x4000000000000000000 > 0) r = r * 0x800000000000b17217f7d1cff4aac1e1 >> 127;
            if (x & 0x2000000000000000000 > 0) r = r * 0x80000000000058b90bfbe8e7db95a2f1 >> 127;
            if (x & 0x1000000000000000000 > 0) r = r * 0x8000000000002c5c85fdf473e61ae1f8 >> 127;
            if (x & 0x800000000000000000 > 0) r = r * 0x800000000000162e42fefa39f121751c >> 127;
            if (x & 0x400000000000000000 > 0) r = r * 0x8000000000000b17217f7d1cf815bb96 >> 127;
            if (x & 0x200000000000000000 > 0) r = r * 0x800000000000058b90bfbe8e7bec1e0d >> 127;
            if (x & 0x100000000000000000 > 0) r = r * 0x80000000000002c5c85fdf473dee5f17 >> 127;
            if (x & 0x80000000000000000 > 0) r = r * 0x8000000000000162e42fefa39ef5438f >> 127;
            if (x & 0x40000000000000000 > 0) r = r * 0x80000000000000b17217f7d1cf7a26c8 >> 127;
            if (x & 0x20000000000000000 > 0) r = r * 0x8000000000000058b90bfbe8e7bcf4a4 >> 127;
            if (x & 0x10000000000000000 > 0) r = r * 0x800000000000002c5c85fdf473de72a2 >> 127;
            /* Precision reduced to 64 bits
            if (x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
            if (x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
            if (x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
            if (x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
            if (x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
            if (x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
            if (x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
            if (x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
            if (x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
            if (x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
            if (x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
            if (x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
            if (x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
            if (x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
            if (x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
            if (x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
            if (x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
            if (x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
            if (x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
            if (x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
            if (x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
            if (x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
            if (x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
            if (x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
            if (x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
            if (x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
            if (x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
            if (x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
            if (x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
            if (x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
            if (x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
            if (x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
            if (x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
            if (x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
            if (x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
            if (x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
            if (x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
            if (x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
            if (x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
            if (x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
            if (x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
            if (x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
            if (x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
            if (x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
            if (x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
            if (x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
            if (x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
            if (x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
            if (x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
            if (x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
            if (x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
            if (x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
            if (x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
            if (x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
            if (x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
            if (x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
            if (x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
            if (x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
            if (x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
            if (x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
            if (x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
            if (x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
            if (x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
            if (x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127;
            */

            r >>= 127 - (x >> 121);

            z = uint128(r);
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}