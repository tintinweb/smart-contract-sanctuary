/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

pragma solidity ^0.8.8;

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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

abstract contract EIP712Domain {
    /**
     * @dev EIP712 Domain Separator
     */
    bytes32 public DOMAIN_SEPARATOR;
}


/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */




/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}


/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32
        public constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    address(this),
                    bytes32(chainId)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDistributor {
    function finishDistribution() external;
    function startDistribution() external;
    function setDistributionParameters(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external;
    function setShares(address shareholder, uint256 amount) external;
    function process() external;
    function deposit() external payable;
    function claim(address shareholder) external;
    function getUnpaidRewards(address shareholder) external view returns (uint256);
    function getPaidRewards(address shareholder) external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function getTotalRewards() external view returns (uint256);
    function getTotalRewarded() external view returns (uint256);
    function migrate(address distributor) external;
}

interface IAntiSnipe {
    function initialize(address liquidityPair) external;
    function protect(address from, address to, uint256 amount) external returns (bool shouldProtect);
}

contract SIMP is Context, Ownable, ReentrancyGuard, EIP712Domain {
    using Address for address;
    
    string private _name = "SIMP Token";
    string private _symbol = "SIMP";
    uint8 private _decimals = 6;

    // From EIP3009
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;
    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;
    // keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
    bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH =
        0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

    /**
     * @dev authorizer address => nonce => state (true = used / false = unused)
     */
    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;
    string internal constant _INVALID_SIGNATURE_ERROR =
        "EIP3009: invalid signature";
    string internal constant _AUTHORIZATION_USED_ERROR =
        "EIP3009: authorization is used";

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances; //standard ERC20
    address[] private _excluded;
    mapping(address => bool) private _isExcludedFromRewards;

    mapping(address => bool) private _taxWhitelist; // tax-free whitelist
    mapping(address => bool) private _liqProvWhitelist; // can add liquidity to PancakeSwap before launchLiquidity called

    address public marketingWallet;
    address public liquidityWallet;
    uint256 gnosisGas = 30000;

    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 1_000_000_000_000 * (10 ** _decimals); // 1 trillion units with 6 decimal units each
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => bool) public liquidityPools;
    mapping (address => IPancakeRouter02) public markets;
    
    IDistributor public distributor;

    // === ANTI SNIPE VARS ===
    bool public liquidityLaunched = false; // to track if launchLiquidity function has been called
    uint256 public lastSnipeTaxBlock; // set to blocks after liq added
    uint256 public snipeBlocks;
    uint256 public endSnipeLimitPeriod; // 2 mins + (big tax blocks) * 3 seconds, after liquidity added
    uint256 private maxAntiSnipeTxSize = 500_000_000 * (10 ** _decimals); // Max transfer per tx in anti snipe period (in SIMP) (<- 500 mil SIMP)
    mapping(address => uint256) private lastTransferTimes; // tracks when last user transfered for anti snipe
    
    bool public swapAndLiquifyEnabled = true;
    bool public inSwap = false;

    // Tokenomics:
    // 3.5% BNB rewards
    // 1% SIMP rewards
    // 3% marketing (in BNB) => marketingWallet
    // 1% for LP

    // BNB = 7.5% (3.5 + 3 + 1)
    // SIMP = 1%

    uint256 public _taxFee = 10; // 10 / 1000 = 1% SIMP reflection
    uint256 private _previousTaxFee = _taxFee;
    uint256 public totalFeesToLP = 10; // 10 / 1000 = 1% --> 0.5% in BNB, 0.5% in SIMP
    uint256 public totalFeesToMarketing = 30;

    // 1% will be added pool, 3.5% will be converted to BNB for rewards, 3% converted to BNB for marketing
    uint256 public _liquidityFee = 75; // over 1000 --> 7.5%
    uint256 private _previousLiquidityFee = _liquidityFee; //_liquidityFee is also the 7% of fee that will be swapped to BNB in swapAndLiquify

    uint256 public minTokenNumberToSell = _tTotal / 10000; // 0.01% max tx amount will trigger swap and add liquidity
    
    mapping (address => bool) teamMember;
    
    IAntiSnipe public protection;
    mapping (address => bool) protect;
    uint256 public protectedFrom;
    bool public protectionEnabled = true;
    uint256 public protectionEnd;

    event Protected(address);
    event ProtectionDisabled();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // From EIP3009
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event ClaimBNBSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );
    
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    modifier onlyTeam() {
        require(teamMember[msg.sender] || msg.sender == owner(), "Caller is not a team member");
        _;
    }

    constructor(address _marketing, address _liquidity) {
        _tOwned[msg.sender] = _tTotal;
        _rOwned[msg.sender] = _rTotal;

        //address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);
        // Create a pancake pair for this new token
        address pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );
        liquidityPools[pancakePair] = true;
        markets[pancakePair] = pancakeRouter;

        // set the rest of the contract variables
        marketingWallet = _marketing;
        liquidityWallet = _liquidity;

        //exclude owner and this contract from fee
        _taxWhitelist[msg.sender] = true;
        _liqProvWhitelist[msg.sender] = true;
        _taxWhitelist[_marketing] = true;
        _taxWhitelist[address(this)] = true;
        
        _isExcludedFromRewards[address(this)] = true;
        _excluded.push(address(this));
        _isExcludedFromRewards[burnAddress] = true;
        _excluded.push(burnAddress);
        _isExcludedFromRewards[msg.sender] = true;
        _excluded.push(msg.sender);
        _isExcludedFromRewards[pancakePair] = true;
        _excluded.push(pancakePair);
        
        _approve(address(this), routerAddress, _tTotal);
        _approve(msg.sender, routerAddress, _tTotal);

        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator("SIMP", "1.0");

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcludedFromRewards[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function setTeamMember(address _team, bool _enabled) external onlyOwner {
        teamMember[_team] = _enabled;
    }
    
    function startDistribution() external onlyTeam {
        distributor.startDistribution();
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function excludeFromReward(address account) public onlyTeam {
        require(
            !_isExcludedFromRewards[account],
            "Account is already excluded"
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
        
        distributor.setShares(account, 0);
    }

    function includeInReward(address account) public onlyTeam {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                distributor.setShares(account, balanceOf(account));
                break;
            }
        }
    }


    function allowance(address _owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "Amount must < total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function setAccountWhitelisted(address account, bool whitelisted) public onlyTeam
    {
        _taxWhitelist[account] = whitelisted;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyTeam {
        
        _taxFee = taxFee;
        _previousTaxFee = _taxFee;
    }

    function setBNBFeePercent(uint256 totalBNBFee, uint256 _marketingFee, uint256 _lpFee) external onlyTeam {
        _liquidityFee = totalBNBFee;
        _previousLiquidityFee = _liquidityFee;
        
        totalFeesToLP = _lpFee;
        totalFeesToMarketing = _marketingFee;
        //remainder goes to BNB distribution
        
        require(totalFeesToLP + totalFeesToMarketing <= _liquidityFee);
    }
    
    function setAmountToSell(uint256 _divisor) external onlyTeam {
        minTokenNumberToSell = _tTotal / _divisor;
    }

    function setMarketingWallet(address _newAddress) external onlyTeam {
        marketingWallet = _newAddress;
    }
    
    function setLiquidityWallet(address _newAddress) external onlyTeam {
        liquidityWallet = _newAddress;
    }

    function setLiqidityProviderWhitelisted(address _address, bool _whitelisted) external onlyTeam {
        _liqProvWhitelist[_address] = _whitelisted;
        _taxWhitelist[_address] = _whitelisted; // tax whitelists LPs to avoid tax on initial LP
        if (_whitelisted)
            excludeFromReward(_address);
        else
            includeInReward(_address);
    }

    // view function for LP whitelist address values as set above
    function getLPWhitelisted(address _account) external view returns (bool) {
        return _liqProvWhitelist[_account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyTeam {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    //call this before adding liquidity to enable high-tax blocks
    function setSnipeBlocks(uint8 _blocks) external onlyTeam {
        require(_blocks < 8 && !liquidityLaunched);
        snipeBlocks = _blocks;
    }
    
    function addLiquidityPool(address lp, bool isPool) external onlyTeam {
        liquidityPools[lp] = isPool;
        excludeFromReward(lp);
    }
    
    function addMarket(address _market) external onlyTeam {
        IPancakeRouter02 router = IPancakeRouter02(_market);
        address pair = IPancakeFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        liquidityPools[pair] = true;
        markets[pair] = router;
        excludeFromReward(pair);
    }

    //to receive BNB
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - (tFee + tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - (rFee + rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }


        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcludedFromRewards[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;

    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return
            (_amount * _taxFee) / 1000;
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return
            (_amount * _liquidityFee) / 1000;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _taxWhitelist[account];
    }
    
    function activateLP(bool _enabled) external onlyOwner {
    	require(protectionEnabled);
        liquidityLaunched = _enabled;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "BEP20: approve from zero address");
        require(spender != address(0), "BEP20: approve to zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function setProtection(IAntiSnipe _protection, address liquidityPair) external onlyTeam {
        protection = _protection;
        protection.initialize(liquidityPair);
    }
    
    function disableProtection() external onlyTeam {
        protectionEnabled = false;
        emit ProtectionDisabled();
    }
    
    function clearProtection(address[] calldata holders) external onlyTeam  {
        for(uint256 i; i<holders.length; i++){
            protect[holders[i]] = false;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from 0x0");
        require(to != address(0), "BEP20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        
        // No adding liquidity before launched in SIMP contract
        if (!liquidityLaunched) {
            if (_liqProvWhitelist[from] && liquidityPools[to]) {
                // allow whitelisted LPs to add liq and start anti snipe

                // block function being called again
                liquidityLaunched = true;
                //setSwapAndLiquifyEnabled(true);
                
                // high tax ends in x blocks
                lastSnipeTaxBlock = block.number + snipeBlocks;
                // after high tax (3 * x seconds), 2 more mins of tx limits
                endSnipeLimitPeriod = block.timestamp + ((3 * snipeBlocks) + 2 minutes);
		protectionEnd = block.timestamp + 1 hours;
            } else {
                require(_liqProvWhitelist[from] || _liqProvWhitelist[to], "Liquidity not launched yet");
            }
        }

        uint256 prevTax = _taxFee;

        // Anti snipe checks here
        if (liquidityLaunched && block.number <= lastSnipeTaxBlock) {
            _taxFee = 920; // change tax to 99% [(920 + 70) / 1000]
        }
        
        
        if (liquidityLaunched && block.timestamp <= endSnipeLimitPeriod && liquidityPools[from]) {
            if (lastTransferTimes[to] <= endSnipeLimitPeriod - 1 minutes) {
                // require 1 min wait if your tx was done in first min of anti-snipe
                require(
                    lastTransferTimes[to] + 1 minutes < block.timestamp,
                    "Cooldown 1 min between txs"
                );
            }
            require(
                amount <= maxAntiSnipeTxSize,
                "Early tx size limit exceeded"
            );
            
            lastTransferTimes[to] = block.timestamp;
        }
        

        // swap and liquify
        if (shouldSwap(to)) swapAndLiquify(to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _taxWhitelist account then remove the fee
        if (_taxWhitelist[from] || _taxWhitelist[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        // resetting tax to prev value if in anti snipe blocks
        if (block.number <= lastSnipeTaxBlock) {
            _taxFee = prevTax;
        }
        
        if(protectionEnabled && protectionEnd > block.timestamp){
            try protection.protect(from, to, amount) returns (bool shouldProtect) {
                if(shouldProtect){
                    protect[to] = true;
                    protectedFrom++;
                    emit Protected(to);
                }
            } catch { }
        }
        require(!protect[from], "Protected");
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        _transferStandard(sender, recipient, amount);
        
        if(!_isExcludedFromRewards[sender]){ try distributor.setShares(sender, balanceOf(sender)) {} catch {} }
        if(!_isExcludedFromRewards[recipient]){ try distributor.setShares(recipient, balanceOf(recipient)) {} catch {} }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        if (_isExcludedFromRewards[sender])
            _tOwned[sender] -= tAmount;
        if (_isExcludedFromRewards[recipient])
            _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function nextAvailableClaimDate(address holder) external view returns (uint256) {
      return distributor.getClaimTime(holder);
    }
    
    function claimBNBReward() external nonReentrant {
        require(
            distributor.getClaimTime(msg.sender) == 0,
            "Next available claim date not reached"
        );
        require(balanceOf(msg.sender) >= 0, "Must own SIMP to claim reward");

        
        uint256 reward = distributor.getUnpaidRewards(msg.sender);

        distributor.claim(msg.sender);
        
        emit ClaimBNBSuccessfully(
            msg.sender,
            reward,
            distributor.getClaimTime(msg.sender)
        );
    }
    
    function pauseDistribution() external onlyTeam {
        distributor.finishDistribution();
    }
    
    function shouldSwap(address to) internal view returns(bool) {
        return 
            !inSwap &&
            swapAndLiquifyEnabled &&
            balanceOf(address(this)) >= minTokenNumberToSell &&
            !liquidityPools[msg.sender] &&
            liquidityPools[to] && 
            _liquidityFee > 0;
    }
    
    function updateGnosisGas(uint256 _amount) external onlyTeam {
        gnosisGas = _amount;
    }

    function swapAndLiquify(address to) internal swapping {
        // only sell for minTokenNumberToSell, decouple from _maxTxAmount
        uint256 amountToSwap = minTokenNumberToSell;

        uint256 simpForLP = ((amountToSwap * totalFeesToLP) / _liquidityFee) / 2;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(
            to,
            amountToSwap - simpForLP
        );

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 totalBNBFee = _liquidityFee - totalFeesToLP / 2;

        uint256 bnbToBeAddedToLiquidity = ((deltaBalance * totalFeesToLP) / totalBNBFee) / 2;

        if (bnbToBeAddedToLiquidity > 0)
            addLiquidity(to, liquidityWallet, simpForLP, bnbToBeAddedToLiquidity);

        uint256 bnbToBeAddedToMarketing = (deltaBalance * totalFeesToMarketing) / totalBNBFee;
        
        if (bnbToBeAddedToMarketing > 0) {
            (bool sent, bytes memory data) = marketingWallet.call{value: bnbToBeAddedToMarketing, gas: gnosisGas}("");
            require(sent, "Failed to send to marketing");
        }
            
        if (deltaBalance - (bnbToBeAddedToLiquidity + bnbToBeAddedToMarketing) > 0)
            try distributor.deposit{value: address(this).balance}() {} catch {}
        //send remainder to BNB rewards
        
        emit SwapAndLiquify(amountToSwap, deltaBalance, simpForLP);
    }

    function swapTokensForEth(
        address pair,
        uint256 tokenAmount
    ) internal {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = markets[pair].WETH();

        // make the swap
        markets[pair].swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        address pair,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        // add the liquidity
        markets[pair].addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
    
    function updateShares(address shareholder) external onlyOwner {
        if(!_isExcludedFromRewards[shareholder]){ distributor.setShares(shareholder, balanceOf(shareholder)); }
        else distributor.setShares(shareholder, 0);
    }
    
    function updateDistributor(address _distributor, bool migrate) external onlyOwner {
        if (migrate) distributor.migrate(_distributor);
        distributor = IDistributor(_distributor);
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 gas) external onlyTeam {
        require(gas < 750000);
        distributor.setDistributionParameters(_minPeriod, _minDistribution, gas);
    }
    
    function getPoolStatistics() external view returns (uint256 totalAmount, uint256 totalClaimed, uint256 holders) {
        totalAmount = distributor.getTotalRewards();
        totalClaimed = distributor.getTotalRewarded();
        holders = distributor.countShareholders();
    }
    
    function calculateBNBReward(address wallet) external view returns (uint256 unclaimed, uint256 claimed) {
	    unclaimed = distributor.getUnpaidRewards(wallet);
	    claimed = distributor.getPaidRewards(wallet);
	}
	
    function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyTeam
    {
        require(_addresses.length == _amount.length);
        bool previousSwap = swapAndLiquifyEnabled;
        swapAndLiquifyEnabled = false;
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]]);
            _transfer(msg.sender, _addresses[i], _amount[i] * (10 ** _decimals));
        }
        swapAndLiquifyEnabled = previousSwap;
    }

    // ------------ Start of EIP3009 function ------------------

    /**
     * @notice Returns the state of an authorization
     * @dev Nonces are randomly generated 32-byte data unique to the authorizer's
     * address
     * @param authorizer    Authorizer's address
     * @param nonce         Nonce of the authorization
     * @return True if the nonce is used
     */
    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    /**
     * @notice Execute a transfer with a signed authorization
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _transferWithAuthorization(
            TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address matches
     * the caller of this function to prevent front-running attacks. (See security
     * considerations)
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(to == msg.sender, "EIP3009: caller must be payee");

        _transferWithAuthorization(
            RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    /**
     * @notice Attempt to cancel an authorization
     * @param authorizer    Authorizer's address
     * @param nonce         Nonce of the authorization
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function cancelAuthorization(
        address authorizer,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            !_authorizationStates[authorizer][nonce],
            _AUTHORIZATION_USED_ERROR
        );

        bytes memory data = abi.encode(
            CANCEL_AUTHORIZATION_TYPEHASH,
            authorizer,
            nonce
        );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == authorizer,
            _INVALID_SIGNATURE_ERROR
        );

        _authorizationStates[authorizer][nonce] = true;
        emit AuthorizationCanceled(authorizer, nonce);
    }

    function _transferWithAuthorization(
        bytes32 typeHash,
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp > validAfter, "EIP3009: auth is not yet valid");
        require(block.timestamp < validBefore, "EIP3009: auth is expired");
        require(!_authorizationStates[from][nonce], _AUTHORIZATION_USED_ERROR);

        bytes memory data = abi.encode(
            typeHash,
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce
        );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
            _INVALID_SIGNATURE_ERROR
        );

        _authorizationStates[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }

    // ------------ End of EIP3009 function ------------------
}