//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20WithPermit.sol";
import "./interfaces/IGsnRelay.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract GsnRelay is IGsnRelay, Ownable {
    // Exchange router
    IUniswapV2Router02 private router;

    address private txFeePayer = address(0);
    uint256 private txRelayGasUsage = 100000;

    string public constant name = 'Plasma Finance GSN Relay';
    string public constant version = '1';
    bytes32 public constant TX_REQUEST_TYPEHASH = keccak256("TxRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 deadline)");
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    modifier onlyFeePayer() {
        require(msg.sender == txFeePayer, "GsnRelay: Unknown relay address");
        require(msg.sender == tx.origin, "GsnRelay: Relay must sender of transaction");
        _;
    }

    constructor(address _router, address _txFeePayer) {
        router = IUniswapV2Router02(_router);
        txFeePayer = _txFeePayer;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function setRouter(IUniswapV2Router02 _router) external onlyOwner {
        router = _router;
    }

    function getRouter() external view returns (address) {
        return address(router);
    }

    function setTxFeePayer(address _txFeePayer) external onlyOwner {
        require(false, 'GsnRelay: Some error');
        txFeePayer = _txFeePayer;
    }

    function getTxFeePayer() external view returns (address) {
        return txFeePayer;
    }

    function setTxRelayGasUsage(uint256 _txRelayGasUsage) external onlyOwner {
        txRelayGasUsage = _txRelayGasUsage;
    }

    function getTxRelayGasUsage() external view returns (uint256) {
        return txRelayGasUsage;
    }


    function getNonce(address from) external view returns (uint256) {
        return nonces[from];
    }

    function sendTransaction(TxRequest calldata txReq, TxSettings calldata settings, bytes calldata signature) external onlyFeePayer {
        _verify(txReq, signature);
        require(txReq.deadline == 0 || txReq.deadline > block.timestamp, "GsnRelay: Request expired");

        IERC20WithPermit token = IERC20WithPermit(settings.feeToken);

        // Approve fee token by EIP712
        if (settings.approvalData.length == 160) {
            (uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(settings.approvalData, (uint256, uint256, uint8, bytes32, bytes32));
            token.permit(txReq.from, txFeePayer, value, deadline, v, r, s);
        }

        // token.allowance(txReq.from, txFeePayer);

        bytes memory callData = abi.encodePacked(txReq.data, txReq.from);
        (bool success,) = txReq.to.call{gas: gasleft(), value: txReq.value}(callData);

        require(success, "GsnRelay: External call error");
    }

    function execute(address from, address to, uint256 value, bytes calldata data) external view {
        (value);
        bytes memory callData = abi.encodePacked(data, from);
        (bool success,) = to.staticcall(callData);

        require(success, "GsnRelay: External call error");
    }

//    function _call(address from, address to, uint256 value, bytes calldata data) internal {
//        uint256 gasBeforeCall = gasleft();
//
//        bytes memory callData = abi.encodePacked(data, from);
//        (bool success, bytes memory resultData) = to.call{gas: gasleft(), value : value}(callData);
//
//        require(success, "GsnRelay: External call error");
//    }

    function _verify(TxRequest calldata req, bytes calldata signature) internal {
        require(nonces[req.from]++ == req.nonce, "GsnRelay: Nonce mismatch");

        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encodePacked(
                    TX_REQUEST_TYPEHASH,
                    uint256(uint160(req.from)),
                    uint256(uint160(req.to)),
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data),
                    req.deadline
                ))
            ));

        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0) && signer == req.from, 'GsnRelay: Invalid signature');
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _swapPair(address tokenAddress) internal returns (address[] memory) {
        address[] memory swapPair = new address[](2);

        swapPair[0] = tokenAddress;
        swapPair[1] = router.WETH();
        return swapPair;
    }

    function _splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "GsnRelay: Signature invalid length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "GsnRelay: Signature invalid v byte");
    }

//    function _calculateCharge(uint256 gasUsed, TxSettings calldata settings) public view returns (uint256) {
//        uint256 basefee;
//        if (settings.maxFeePerGas == relayData.maxPriorityFeePerGas) {
//            basefee = 0;
//        } else {
//            basefee = block.basefee;
//        }
//        uint256 chargeableGasPrice = Math.min(relayData.maxFeePerGas, Math.min(tx.gasprice, basefee + relayData.maxPriorityFeePerGas));
//
//        return relayData.baseRelayFee.add((gasUsed.mul(chargeableGasPrice).mul(relayData.pctRelayFee.add(100))).div(100));
//    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function factory() external returns (address);

    function WETH() external returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] memory path, address to, uint256 deadline)
    external
    payable
    returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] memory path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";

interface IGsnRelay {
    struct TxRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 deadline;
    }

    struct TxSettings {
        address feeToken;
        bytes approvalData;
        uint256 gasPrice;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    function setRouter(IUniswapV2Router02 _router) external;
    function getRouter() external view returns (address);

    function setTxFeePayer(address _txFeePayer) external;
    function getTxFeePayer() external view returns (address);

    function setTxRelayGasUsage(uint256 _txRelayGasUsage) external;
    function getTxRelayGasUsage() external view returns (uint256);

    function getNonce(address from) external view returns (uint256);

    function sendTransaction(TxRequest calldata txReq, TxSettings calldata settings, bytes calldata signature) external;

    function execute(address from, address to, uint256 value, bytes calldata data) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20WithPermit is IERC20, IERC20Permit {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
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
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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