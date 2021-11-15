pragma solidity ^0.7.0;

import "../openzeppelin/IERC20.sol";

import "../../vault/interfaces/IAsset.sol";
import "../../vault/interfaces/IWETH.sol";

abstract contract AssetHelpers {
   
    IWETH private immutable _weth;

   
   
   
    address private constant _ETH = address(0);

    constructor(IWETH weth) {
        _weth = weth;
    }

   
    function _WETH() internal view returns (IWETH) {
        return _weth;
    }

    
    function _isETH(IAsset asset) internal pure returns (bool) {
        return address(asset) == _ETH;
    }

    
    function _translateToIERC20(IAsset asset) internal view returns (IERC20) {
        return _isETH(asset) ? _WETH() : _asIERC20(asset);
    }

    
    function _translateToIERC20(IAsset[] memory assets) internal view returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](assets.length);
        for (uint256 i = 0; i < assets.length; ++i) {
            tokens[i] = _translateToIERC20(assets[i]);
        }
        return tokens;
    }

    
    function _asIERC20(IAsset asset) internal pure returns (IERC20) {
        return IERC20(address(asset));
    }
}

pragma solidity ^0.7.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.7.0;

interface IAsset {
   
}

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/helpers/AssetHelpers.sol";
import "../lib/openzeppelin/SafeERC20.sol";
import "../lib/openzeppelin/Address.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IVault.sol";

abstract contract AssetTransfersHandler is AssetHelpers {
    using SafeERC20 for IERC20;
    using Address for address payable;

    
    function _receiveAsset(
        IAsset asset,
        uint256 amount,
        address sender,
        bool fromInternalBalance
    ) internal {
        if (amount == 0) {
            return;
        }

        if (_isETH(asset)) {
            _require(!fromInternalBalance, Errors.INVALID_ETH_INTERNAL_BALANCE);

           
           

           
           
            _require(address(this).balance >= amount, Errors.INSUFFICIENT_ETH);
            _WETH().deposit{ value: amount }();
        } else {
            IERC20 token = _asIERC20(asset);

            if (fromInternalBalance) {
               
                uint256 deductedBalance = _decreaseInternalBalance(sender, token, amount, true);
               
               
                amount -= deductedBalance;
            }

            if (amount > 0) {
                token.safeTransferFrom(sender, address(this), amount);
            }
        }
    }

    
    function _sendAsset(
        IAsset asset,
        uint256 amount,
        address payable recipient,
        bool toInternalBalance
    ) internal {
        if (amount == 0) {
            return;
        }

        if (_isETH(asset)) {
           
           
            _require(!toInternalBalance, Errors.INVALID_ETH_INTERNAL_BALANCE);

           
           
            _WETH().withdraw(amount);

           
            recipient.sendValue(amount);
        } else {
            IERC20 token = _asIERC20(asset);
            if (toInternalBalance) {
                _increaseInternalBalance(recipient, token, amount);
            } else {
                token.safeTransfer(recipient, amount);
            }
        }
    }

    
    function _handleRemainingEth(uint256 amountUsed) internal {
        _require(msg.value >= amountUsed, Errors.INSUFFICIENT_ETH);

        uint256 excess = msg.value - amountUsed;
        if (excess > 0) {
            msg.sender.sendValue(excess);
        }
    }

    
    receive() external payable {
        _require(msg.sender == address(_WETH()), Errors.ETH_TRANSFER);
    }

   
   
   

    function _increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal virtual;

    function _decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool capped
    ) internal virtual returns (uint256);
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library Math {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}

pragma solidity ^0.7.0;

function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

function _revert(uint256 errorCode) pure {
   
   
   
   
   
   
   
   
   
   
    assembly {
       
       
       

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

       
       
       
       
       
       

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

       
       
       

       
       
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
       
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
       
        mstore(0x24, 7)
       
        mstore(0x44, revertReason)

       
       
        revert(0, 100)
    }
}

library Errors {
   
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

   
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

   
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

   
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;

   
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

   
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

   
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

import "./IERC20.sol";

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function _callOptionalReturn(address token, bytes memory data) private {
       
       
        (bool success, bytes memory returndata) = token.call(data);

       
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

       
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library Address {
    
    function isContract(address account) internal view returns (bool) {
       
       
       

        uint256 size;
       
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        _require(address(this).balance >= amount, Errors.ADDRESS_INSUFFICIENT_BALANCE);

       
        (bool success, ) = recipient.call{ value: amount }("");
        _require(success, Errors.ADDRESS_CANNOT_SEND_VALUE);
    }
}

pragma experimental ABIEncoderV2;

import "../../lib/openzeppelin/IERC20.sol";

import "./IWETH.sol";
import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "../ProtocolFeesCollector.sol";

import "../../lib/helpers/ISignaturesValidator.sol";
import "../../lib/helpers/ITemporarilyPausable.sol";

pragma solidity ^0.7.0;

interface IVault is ISignaturesValidator, ITemporarilyPausable {
   
   
   
   
   
   
   
   
   
   
   
   
   
   

   
   
   
   
   

    
    function getAuthorizer() external view returns (IAuthorizer);

    
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

   
   
   
   
   
   
   
   
   
   
   
   
   

    
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

   
   
   
   
   
   
   
   
   

    
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

   

    
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

   
   
   
   
   
   
   
   
   
   
   
   
   

    
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

   
   
   
   
   
   
   
   
   
   
   
   
   
   

    
    function getProtocolFeesCollector() external view returns (ProtocolFeesCollector);

    
    function setPaused(bool paused) external;

    
    function WETH() external view returns (IWETH);
   
}

pragma solidity ^0.7.0;

interface IAuthorizer {
    
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/IERC20.sol";

interface IFlashLoanRecipient {
    
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin/IERC20.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/helpers/Authentication.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IAuthorizer.sol";

contract ProtocolFeesCollector is Authentication, ReentrancyGuard {
    using SafeERC20 for IERC20;

   
    uint256 private constant _MAX_PROTOCOL_SWAP_FEE_PERCENTAGE = 50e16;
    uint256 private constant _MAX_PROTOCOL_FLASH_LOAN_FEE_PERCENTAGE = 1e16;

    IVault public immutable vault;

   

   
   
   
    uint256 private _swapFeePercentage;

   
    uint256 private _flashLoanFeePercentage;

    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    constructor(IVault _vault)
       
       
        Authentication(bytes32(uint256(address(this))))
    {
        vault = _vault;
    }

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external nonReentrant authenticate {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            token.safeTransfer(recipient, amount);
        }
    }

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external authenticate {
        _require(newSwapFeePercentage <= _MAX_PROTOCOL_SWAP_FEE_PERCENTAGE, Errors.SWAP_FEE_PERCENTAGE_TOO_HIGH);
        _swapFeePercentage = newSwapFeePercentage;
        emit SwapFeePercentageChanged(newSwapFeePercentage);
    }

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external authenticate {
        _require(
            newFlashLoanFeePercentage <= _MAX_PROTOCOL_FLASH_LOAN_FEE_PERCENTAGE,
            Errors.FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH
        );
        _flashLoanFeePercentage = newFlashLoanFeePercentage;
        emit FlashLoanFeePercentageChanged(newFlashLoanFeePercentage);
    }

    function getSwapFeePercentage() external view returns (uint256) {
        return _swapFeePercentage;
    }

    function getFlashLoanFeePercentage() external view returns (uint256) {
        return _flashLoanFeePercentage;
    }

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts) {
        feeAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            feeAmounts[i] = tokens[i].balanceOf(address(this));
        }
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        return _getAuthorizer().canPerform(actionId, account, address(this));
    }

    function _getAuthorizer() internal view returns (IAuthorizer) {
        return vault.getAuthorizer();
    }
}

pragma solidity ^0.7.0;

interface ISignaturesValidator {
    
    function getDomainSeparator() external view returns (bytes32);

    
    function getNextNonce(address user) external view returns (uint256);
}

pragma solidity ^0.7.0;

interface ITemporarilyPausable {
    
    event PausedStateChanged(bool paused);

    
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

pragma solidity ^0.7.0;

import "../openzeppelin/IERC20.sol";

import "./BalancerErrors.sol";

import "../../vault/interfaces/IAsset.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IAsset[] memory array) internal pure {
        address[] memory addressArray;
       
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
       
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./IAuthentication.sol";

abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    
    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    
    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        _require(_canPerform(actionId, msg.sender), Errors.SENDER_NOT_ALLOWED);
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
       
       
       
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

abstract contract ReentrancyGuard {
   
   
   
   
   

   
   
   
   
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
       
        _require(_status != _ENTERED, Errors.REENTRANCY);

       
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
       
       
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.7.0;

interface IAuthentication {
    
    function getActionId(bytes4 selector) external view returns (bytes32);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/math/Math.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeCast.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./AssetTransfersHandler.sol";
import "./VaultAuthorization.sol";

abstract contract UserBalance is ReentrancyGuard, AssetTransfersHandler, VaultAuthorization {
    using Math for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

   
    mapping(address => mapping(IERC20 => uint256)) private _internalTokenBalance;

    function getInternalBalance(address user, IERC20[] memory tokens)
        external
        view
        override
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = _getInternalBalance(user, tokens[i]);
        }
    }

    function manageUserBalance(UserBalanceOp[] memory ops) external payable override nonReentrant {
       
        uint256 ethWrapped = 0;

       
        bool checkedCallerIsRelayer = false;
        bool checkedNotPaused = false;

        for (uint256 i = 0; i < ops.length; i++) {
            UserBalanceOpKind kind;
            IAsset asset;
            uint256 amount;
            address sender;
            address payable recipient;

           
            (kind, asset, amount, sender, recipient, checkedCallerIsRelayer) = _validateUserBalanceOp(
                ops[i],
                checkedCallerIsRelayer
            );

            if (kind == UserBalanceOpKind.WITHDRAW_INTERNAL) {
               
                _withdrawFromInternalBalance(asset, sender, recipient, amount);
            } else {
               

               
               
                if (!checkedNotPaused) {
                    _ensureNotPaused();
                    checkedNotPaused = true;
                }

                if (kind == UserBalanceOpKind.DEPOSIT_INTERNAL) {
                    _depositToInternalBalance(asset, sender, recipient, amount);

                   
                    if (_isETH(asset)) {
                        ethWrapped = ethWrapped.add(amount);
                    }
                } else {
                   
                    _require(!_isETH(asset), Errors.CANNOT_USE_ETH_SENTINEL);
                    IERC20 token = _asIERC20(asset);

                    if (kind == UserBalanceOpKind.TRANSFER_INTERNAL) {
                        _transferInternalBalance(token, sender, recipient, amount);
                    } else {
                       
                        _transferToExternalBalance(token, sender, recipient, amount);
                    }
                }
            }
        }

       
        _handleRemainingEth(ethWrapped);
    }

    function _depositToInternalBalance(
        IAsset asset,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _increaseInternalBalance(recipient, _translateToIERC20(asset), amount);
        _receiveAsset(asset, amount, sender, false);
    }

    function _withdrawFromInternalBalance(
        IAsset asset,
        address sender,
        address payable recipient,
        uint256 amount
    ) private {
       
        _decreaseInternalBalance(sender, _translateToIERC20(asset), amount, false);
        _sendAsset(asset, amount, recipient, false);
    }

    function _transferInternalBalance(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
       
        _decreaseInternalBalance(sender, token, amount, false);
        _increaseInternalBalance(recipient, token, amount);
    }

    function _transferToExternalBalance(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (amount > 0) {
            token.safeTransferFrom(sender, recipient, amount);
            emit ExternalBalanceTransfer(token, sender, recipient, amount);
        }
    }

    
    function _increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal override {
        uint256 currentBalance = _getInternalBalance(account, token);
        uint256 newBalance = currentBalance.add(amount);
        _setInternalBalance(account, token, newBalance, amount.toInt256());
    }

    
    function _decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool allowPartial
    ) internal override returns (uint256 deducted) {
        uint256 currentBalance = _getInternalBalance(account, token);
        _require(allowPartial || (currentBalance >= amount), Errors.INSUFFICIENT_INTERNAL_BALANCE);

        deducted = Math.min(currentBalance, amount);
       
       
        uint256 newBalance = currentBalance - deducted;
        _setInternalBalance(account, token, newBalance, -(deducted.toInt256()));
    }

    
    function _setInternalBalance(
        address account,
        IERC20 token,
        uint256 newBalance,
        int256 delta
    ) private {
        _internalTokenBalance[account][token] = newBalance;
        emit InternalBalanceChanged(account, token, delta);
    }

    
    function _getInternalBalance(address account, IERC20 token) internal view returns (uint256) {
        return _internalTokenBalance[account][token];
    }

    
    function _validateUserBalanceOp(UserBalanceOp memory op, bool checkedCallerIsRelayer)
        private
        view
        returns (
            UserBalanceOpKind,
            IAsset,
            uint256,
            address,
            address payable,
            bool
        )
    {
       
       
        address sender = op.sender;

        if (sender != msg.sender) {
           

           
           
            if (!checkedCallerIsRelayer) {
                _authenticateCaller();
                checkedCallerIsRelayer = true;
            }

            _require(_hasApprovedRelayer(sender, msg.sender), Errors.USER_DOESNT_ALLOW_RELAYER);
        }

        return (op.kind, op.asset, op.amount, sender, op.recipient, checkedCallerIsRelayer);
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library SafeCast {
    
    function toInt256(uint256 value) internal pure returns (int256) {
        _require(value < 2**255, Errors.SAFE_CAST_VALUE_CANT_FIT_INT256);
        return int256(value);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/Authentication.sol";
import "../lib/helpers/TemporarilyPausable.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/SignaturesValidator.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IAuthorizer.sol";

abstract contract VaultAuthorization is
    IVault,
    ReentrancyGuard,
    Authentication,
    SignaturesValidator,
    TemporarilyPausable
{
   
   

   
    bytes32 private constant _JOIN_TYPE_HASH = 0x3f7b71252bd19113ff48c19c6e004a9bcfcca320a0d74d58e85877cbd7dcae58;

   
    bytes32 private constant _EXIT_TYPE_HASH = 0x8bbc57f66ea936902f50a71ce12b92c43f3c5340bb40c27c4e90ab84eeae3353;

   
    bytes32 private constant _SWAP_TYPE_HASH = 0xe192dcbc143b1e244ad73b813fd3c097b832ad260a157340b4e5e5beda067abe;

   
    bytes32 private constant _BATCH_SWAP_TYPE_HASH = 0x9bfc43a4d98313c6766986ffd7c916c7481566d9f224c6819af0a53388aced3a;

   
   
    bytes32
        private constant _SET_RELAYER_TYPE_HASH = 0xa3f865aa351e51cfeb40f5178d1564bb629fe9030b83caf6361d1baaf5b90b5a;

    IAuthorizer private _authorizer;
    mapping(address => mapping(address => bool)) private _approvedRelayers;

    
    modifier authenticateFor(address user) {
        _authenticateFor(user);
        _;
    }

    constructor(IAuthorizer authorizer)
       
        Authentication(bytes32(uint256(address(this))))
        SignaturesValidator("Balancer V2 Vault")
    {
        _setAuthorizer(authorizer);
    }

    function setAuthorizer(IAuthorizer newAuthorizer) external override nonReentrant authenticate {
        _setAuthorizer(newAuthorizer);
    }

    function _setAuthorizer(IAuthorizer newAuthorizer) private {
        emit AuthorizerChanged(newAuthorizer);
        _authorizer = newAuthorizer;
    }

    function getAuthorizer() external view override returns (IAuthorizer) {
        return _authorizer;
    }

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external override nonReentrant whenNotPaused authenticateFor(sender) {
        _approvedRelayers[sender][relayer] = approved;
        emit RelayerApprovalChanged(relayer, sender, approved);
    }

    function hasApprovedRelayer(address user, address relayer) external view override returns (bool) {
        return _hasApprovedRelayer(user, relayer);
    }

    
    function _authenticateFor(address user) internal {
        if (msg.sender != user) {
           
            _authenticateCaller();

           
           
            if (!_hasApprovedRelayer(user, msg.sender)) {
                _validateSignature(user, Errors.USER_DOESNT_ALLOW_RELAYER);
            }
        }
    }

    
    function _hasApprovedRelayer(address user, address relayer) internal view returns (bool) {
        return _approvedRelayers[user][relayer];
    }

    function _canPerform(bytes32 actionId, address user) internal view override returns (bool) {
       
        return _authorizer.canPerform(actionId, user, address(this));
    }

    function _typeHash() internal pure override returns (bytes32 hash) {
       
       
       
        assembly {
           
           
           
            let selector := shr(224, calldataload(0))

           
           
            switch selector
                case 0xb95cac28 {
                    hash := _JOIN_TYPE_HASH
                }
                case 0x8bdb3913 {
                    hash := _EXIT_TYPE_HASH
                }
                case 0x52bbbe29 {
                    hash := _SWAP_TYPE_HASH
                }
                case 0x945bcec9 {
                    hash := _BATCH_SWAP_TYPE_HASH
                }
                case 0xfa6e671d {
                    hash := _SET_RELAYER_TYPE_HASH
                }
                default {
                    hash := 0x0000000000000000000000000000000000000000000000000000000000000000
                }
        }
    }
}

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./ITemporarilyPausable.sol";

abstract contract TemporarilyPausable is ITemporarilyPausable {
   
   

    uint256 private constant _MAX_PAUSE_WINDOW_DURATION = 90 days;
    uint256 private constant _MAX_BUFFER_PERIOD_DURATION = 30 days;

    uint256 private immutable _pauseWindowEndTime;
    uint256 private immutable _bufferPeriodEndTime;

    bool private _paused;

    constructor(uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        _require(pauseWindowDuration <= _MAX_PAUSE_WINDOW_DURATION, Errors.MAX_PAUSE_WINDOW_DURATION);
        _require(bufferPeriodDuration <= _MAX_BUFFER_PERIOD_DURATION, Errors.MAX_BUFFER_PERIOD_DURATION);

        uint256 pauseWindowEndTime = block.timestamp + pauseWindowDuration;

        _pauseWindowEndTime = pauseWindowEndTime;
        _bufferPeriodEndTime = pauseWindowEndTime + bufferPeriodDuration;
    }

    
    modifier whenNotPaused() {
        _ensureNotPaused();
        _;
    }

    
    function getPausedState()
        external
        view
        override
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        )
    {
        paused = !_isNotPaused();
        pauseWindowEndTime = _getPauseWindowEndTime();
        bufferPeriodEndTime = _getBufferPeriodEndTime();
    }

    
    function _setPaused(bool paused) internal {
        if (paused) {
            _require(block.timestamp < _getPauseWindowEndTime(), Errors.PAUSE_WINDOW_EXPIRED);
        } else {
            _require(block.timestamp < _getBufferPeriodEndTime(), Errors.BUFFER_PERIOD_EXPIRED);
        }

        _paused = paused;
        emit PausedStateChanged(paused);
    }

    
    function _ensureNotPaused() internal view {
        _require(_isNotPaused(), Errors.PAUSED);
    }

    
    function _isNotPaused() internal view returns (bool) {
       
        return block.timestamp > _getBufferPeriodEndTime() || !_paused;
    }

   

    function _getPauseWindowEndTime() private view returns (uint256) {
        return _pauseWindowEndTime;
    }

    function _getBufferPeriodEndTime() private view returns (uint256) {
        return _bufferPeriodEndTime;
    }
}

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./ISignaturesValidator.sol";
import "../openzeppelin/EIP712.sol";

abstract contract SignaturesValidator is ISignaturesValidator, EIP712 {
   
   
    uint256 internal constant _EXTRA_CALLDATA_LENGTH = 4 * 32;

   
    mapping(address => uint256) internal _nextNonce;

    constructor(string memory name) EIP712(name, "1") {
       
    }

    function getDomainSeparator() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getNextNonce(address user) external view override returns (uint256) {
        return _nextNonce[user];
    }

    
    function _validateSignature(address user, uint256 errorCode) internal {
        uint256 nextNonce = _nextNonce[user]++;
        _require(_isSignatureValid(user, nextNonce), errorCode);
    }

    function _isSignatureValid(address user, uint256 nonce) private view returns (bool) {
        uint256 deadline = _deadline();

       
       
        if (deadline < block.timestamp) {
            return false;
        }

        bytes32 typeHash = _typeHash();
        if (typeHash == bytes32(0)) {
           
            return false;
        }

       
        bytes32 structHash = keccak256(abi.encode(typeHash, keccak256(_calldata()), msg.sender, nonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = _signature();

        address recoveredAddress = ecrecover(digest, v, r, s);

       
        return recoveredAddress != address(0) && recoveredAddress == user;
    }

    
    function _typeHash() internal view virtual returns (bytes32);

    
    function _deadline() internal pure returns (uint256) {
       
        return uint256(_decodeExtraCalldataWord(0));
    }

    
    function _signature()
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
       
        v = uint8(uint256(_decodeExtraCalldataWord(0x20)));
        r = _decodeExtraCalldataWord(0x40);
        s = _decodeExtraCalldataWord(0x60);
    }

    
    function _calldata() internal pure returns (bytes memory result) {
        result = msg.data;
        if (result.length > _EXTRA_CALLDATA_LENGTH) {
           
            assembly {
               
                mstore(result, sub(calldatasize(), _EXTRA_CALLDATA_LENGTH))
            }
        }
    }

    
    function _decodeExtraCalldataWord(uint256 offset) private pure returns (bytes32 result) {
       
        assembly {
            result := calldataload(add(sub(calldatasize(), _EXTRA_CALLDATA_LENGTH), offset))
        }
    }
}

pragma solidity ^0.7.0;

abstract contract EIP712 {
    
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    

    
    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _getChainId(), address(this)));
    }

    
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
       
       
       
        this;

       
        assembly {
            chainId := chainid()
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./Fees.sol";
import "./PoolTokens.sol";
import "./UserBalance.sol";
import "./interfaces/IBasePool.sol";

abstract contract PoolBalances is Fees, ReentrancyGuard, PoolTokens, UserBalance {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using BalanceAllocation for bytes32;
    using BalanceAllocation for bytes32[];

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable override whenNotPaused {
       

       
       
        _joinOrExit(PoolBalanceChangeKind.JOIN, poolId, sender, payable(recipient), _toPoolBalanceChange(request));
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external override {
       
        _joinOrExit(PoolBalanceChangeKind.EXIT, poolId, sender, recipient, _toPoolBalanceChange(request));
    }

   
   
   
    struct PoolBalanceChange {
        IAsset[] assets;
        uint256[] limits;
        bytes userData;
        bool useInternalBalance;
    }

    
    function _toPoolBalanceChange(JoinPoolRequest memory request)
        private
        pure
        returns (PoolBalanceChange memory change)
    {
       
        assembly {
            change := request
        }
    }

    
    function _toPoolBalanceChange(ExitPoolRequest memory request)
        private
        pure
        returns (PoolBalanceChange memory change)
    {
       
        assembly {
            change := request
        }
    }

    
    function _joinOrExit(
        PoolBalanceChangeKind kind,
        bytes32 poolId,
        address sender,
        address payable recipient,
        PoolBalanceChange memory change
    ) private nonReentrant withRegisteredPool(poolId) authenticateFor(sender) {
       
       
       

        InputHelpers.ensureInputLengthMatch(change.assets.length, change.limits.length);

       
       
        IERC20[] memory tokens = _translateToIERC20(change.assets);
        bytes32[] memory balances = _validateTokensAndGetBalances(poolId, tokens);

       
       
        (
            bytes32[] memory finalBalances,
            uint256[] memory amountsInOrOut,
            uint256[] memory paidProtocolSwapFeeAmounts
        ) = _callPoolBalanceChange(kind, poolId, sender, recipient, change, balances);

       
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _setTwoTokenPoolCashBalances(poolId, tokens[0], finalBalances[0], tokens[1], finalBalances[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _setMinimalSwapInfoPoolBalances(poolId, tokens, finalBalances);
        } else {
           
            _setGeneralPoolBalances(poolId, finalBalances);
        }

        bool positive = kind == PoolBalanceChangeKind.JOIN;
        emit PoolBalanceChanged(
            poolId,
            sender,
            tokens,
           
            _unsafeCastToInt256(amountsInOrOut, positive),
            paidProtocolSwapFeeAmounts
        );
    }

    
    function _callPoolBalanceChange(
        PoolBalanceChangeKind kind,
        bytes32 poolId,
        address sender,
        address payable recipient,
        PoolBalanceChange memory change,
        bytes32[] memory balances
    )
        private
        returns (
            bytes32[] memory finalBalances,
            uint256[] memory amountsInOrOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
        (uint256[] memory totalBalances, uint256 lastChangeBlock) = balances.totalsAndLastChangeBlock();

        IBasePool pool = IBasePool(_getPoolAddress(poolId));
        (amountsInOrOut, dueProtocolFeeAmounts) = kind == PoolBalanceChangeKind.JOIN
            ? pool.onJoinPool(
                poolId,
                sender,
                recipient,
                totalBalances,
                lastChangeBlock,
                _getProtocolSwapFeePercentage(),
                change.userData
            )
            : pool.onExitPool(
                poolId,
                sender,
                recipient,
                totalBalances,
                lastChangeBlock,
                _getProtocolSwapFeePercentage(),
                change.userData
            );

        InputHelpers.ensureInputLengthMatch(balances.length, amountsInOrOut.length, dueProtocolFeeAmounts.length);

       
       
        finalBalances = kind == PoolBalanceChangeKind.JOIN
            ? _processJoinPoolTransfers(sender, change, balances, amountsInOrOut, dueProtocolFeeAmounts)
            : _processExitPoolTransfers(recipient, change, balances, amountsInOrOut, dueProtocolFeeAmounts);
    }

    
    function _processJoinPoolTransfers(
        address sender,
        PoolBalanceChange memory change,
        bytes32[] memory balances,
        uint256[] memory amountsIn,
        uint256[] memory dueProtocolFeeAmounts
    ) private returns (bytes32[] memory finalBalances) {
       
        uint256 wrappedEth = 0;

        finalBalances = new bytes32[](balances.length);
        for (uint256 i = 0; i < change.assets.length; ++i) {
            uint256 amountIn = amountsIn[i];
            _require(amountIn <= change.limits[i], Errors.JOIN_ABOVE_MAX);

           
            IAsset asset = change.assets[i];
            _receiveAsset(asset, amountIn, sender, change.useInternalBalance);

            if (_isETH(asset)) {
                wrappedEth = wrappedEth.add(amountIn);
            }

            uint256 feeAmount = dueProtocolFeeAmounts[i];
            _payFeeAmount(_translateToIERC20(asset), feeAmount);

           
           
            finalBalances[i] = (amountIn >= feeAmount)
                ? balances[i].increaseCash(amountIn - feeAmount)
                : balances[i].decreaseCash(feeAmount - amountIn);
        }

       
        _handleRemainingEth(wrappedEth);
    }

    
    function _processExitPoolTransfers(
        address payable recipient,
        PoolBalanceChange memory change,
        bytes32[] memory balances,
        uint256[] memory amountsOut,
        uint256[] memory dueProtocolFeeAmounts
    ) private returns (bytes32[] memory finalBalances) {
        finalBalances = new bytes32[](balances.length);
        for (uint256 i = 0; i < change.assets.length; ++i) {
            uint256 amountOut = amountsOut[i];
            _require(amountOut >= change.limits[i], Errors.EXIT_BELOW_MIN);

           
            IAsset asset = change.assets[i];
            _sendAsset(asset, amountOut, recipient, change.useInternalBalance);

            uint256 feeAmount = dueProtocolFeeAmounts[i];
            _payFeeAmount(_translateToIERC20(asset), feeAmount);

           
            finalBalances[i] = balances[i].decreaseCash(amountOut.add(feeAmount));
        }
    }

    
    function _validateTokensAndGetBalances(bytes32 poolId, IERC20[] memory expectedTokens)
        private
        view
        returns (bytes32[] memory)
    {
        (IERC20[] memory actualTokens, bytes32[] memory balances) = _getPoolTokens(poolId);
        InputHelpers.ensureInputLengthMatch(actualTokens.length, expectedTokens.length);
        _require(actualTokens.length > 0, Errors.POOL_NO_TOKENS);

        for (uint256 i = 0; i < actualTokens.length; ++i) {
            _require(actualTokens[i] == expectedTokens[i], Errors.TOKENS_MISMATCH);
        }

        return balances;
    }

    
    function _unsafeCastToInt256(uint256[] memory values, bool positive)
        private
        pure
        returns (int256[] memory signedValues)
    {
        signedValues = new int256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            signedValues[i] = positive ? int256(values[i]) : -int256(values[i]);
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/FixedPoint.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./ProtocolFeesCollector.sol";
import "./VaultAuthorization.sol";
import "./interfaces/IVault.sol";

abstract contract Fees is IVault {
    using SafeERC20 for IERC20;

    ProtocolFeesCollector private immutable _protocolFeesCollector;

    constructor() {
        _protocolFeesCollector = new ProtocolFeesCollector(IVault(this));
    }

    function getProtocolFeesCollector() public view override returns (ProtocolFeesCollector) {
        return _protocolFeesCollector;
    }

    
    function _getProtocolSwapFeePercentage() internal view returns (uint256) {
        return getProtocolFeesCollector().getSwapFeePercentage();
    }

    
    function _calculateFlashLoanFeeAmount(uint256 amount) internal view returns (uint256) {
       
       
        uint256 percentage = getProtocolFeesCollector().getFlashLoanFeePercentage();
        return FixedPoint.mulUp(amount, percentage);
    }

    function _payFeeAmount(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            token.safeTransfer(address(getProtocolFeesCollector()), amount);
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./AssetManagers.sol";
import "./PoolRegistry.sol";
import "./balances/BalanceAllocation.sol";

abstract contract PoolTokens is ReentrancyGuard, PoolRegistry, AssetManagers {
    using BalanceAllocation for bytes32;
    using BalanceAllocation for bytes32[];

    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external override nonReentrant whenNotPaused onlyPool(poolId) {
        InputHelpers.ensureInputLengthMatch(tokens.length, assetManagers.length);

       
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            _require(token != IERC20(0), Errors.INVALID_TOKEN);

            _poolAssetManagers[poolId][token] = assetManagers[i];
        }

        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _require(tokens.length == 2, Errors.TOKENS_LENGTH_MUST_BE_2);
            _registerTwoTokenPoolTokens(poolId, tokens[0], tokens[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _registerMinimalSwapInfoPoolTokens(poolId, tokens);
        } else {
           
            _registerGeneralPoolTokens(poolId, tokens);
        }

        emit TokensRegistered(poolId, tokens, assetManagers);
    }

    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens)
        external
        override
        nonReentrant
        whenNotPaused
        onlyPool(poolId)
    {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _require(tokens.length == 2, Errors.TOKENS_LENGTH_MUST_BE_2);
            _deregisterTwoTokenPoolTokens(poolId, tokens[0], tokens[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _deregisterMinimalSwapInfoPoolTokens(poolId, tokens);
        } else {
           
            _deregisterGeneralPoolTokens(poolId, tokens);
        }

       
       
        for (uint256 i = 0; i < tokens.length; ++i) {
            delete _poolAssetManagers[poolId][tokens[i]];
        }

        emit TokensDeregistered(poolId, tokens);
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        )
    {
        bytes32[] memory rawBalances;
        (tokens, rawBalances) = _getPoolTokens(poolId);
        (balances, lastChangeBlock) = rawBalances.totalsAndLastChangeBlock();
    }

    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        )
    {
        bytes32 balance;
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        if (specialization == PoolSpecialization.TWO_TOKEN) {
            balance = _getTwoTokenPoolBalance(poolId, token);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            balance = _getMinimalSwapInfoPoolBalance(poolId, token);
        } else {
           
            balance = _getGeneralPoolBalance(poolId, token);
        }

        cash = balance.cash();
        managed = balance.managed();
        lastChangeBlock = balance.lastChangeBlock();
        assetManager = _poolAssetManagers[poolId][token];
    }

    
    function _getPoolTokens(bytes32 poolId) internal view returns (IERC20[] memory tokens, bytes32[] memory balances) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _getTwoTokenPoolTokens(poolId);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _getMinimalSwapInfoPoolTokens(poolId);
        } else {
           
            return _getGeneralPoolTokens(poolId);
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./IPoolSwapStructs.sol";

interface IBasePool is IPoolSwapStructs {
    
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);
}

pragma solidity ^0.7.0;

import "./LogExpMath.sol";
import "../helpers/BalancerErrors.sol";

library FixedPoint {
    uint256 internal constant ONE = 1e18;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000;

   
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
       

        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       

        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        if (product == 0) {
            return 0;
        } else {
           
           
           
           
           

            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            _require(aInflated / a == ONE, Errors.DIV_INTERNAL);

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            _require(aInflated / a == ONE, Errors.DIV_INTERNAL);

           
           
           
           
           

            return ((aInflated - 1) / b) + 1;
        }
    }

    
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        if (raw < maxError) {
            return 0;
        } else {
            return sub(raw, maxError);
        }
    }

    
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        return add(raw, maxError);
    }

    
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library LogExpMath {
   
   

   
    int256 constant ONE_18 = 1e18;

   
   
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

   
   
   
   
   
   
   
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

   
   
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

   
    int256 constant x0 = 128000000000000000000;
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000;
    int256 constant x1 = 64000000000000000000;
    int256 constant a1 = 6235149080811616882910000000;

   
    int256 constant x2 = 3200000000000000000000;
    int256 constant a2 = 7896296018268069516100000000000000;
    int256 constant x3 = 1600000000000000000000;
    int256 constant a3 = 888611052050787263676000000;
    int256 constant x4 = 800000000000000000000;
    int256 constant a4 = 298095798704172827474000;
    int256 constant x5 = 400000000000000000000;
    int256 constant a5 = 5459815003314423907810;
    int256 constant x6 = 200000000000000000000;
    int256 constant a6 = 738905609893065022723;
    int256 constant x7 = 100000000000000000000;
    int256 constant a7 = 271828182845904523536;
    int256 constant x8 = 50000000000000000000;
    int256 constant a8 = 164872127070012814685;
    int256 constant x9 = 25000000000000000000;
    int256 constant a9 = 128402541668774148407;
    int256 constant x10 = 12500000000000000000;
    int256 constant a10 = 113314845306682631683;
    int256 constant x11 = 6250000000000000000;
    int256 constant a11 = 106449445891785942956;

    
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
           
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

       
       
       

       
        _require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

       
       

       
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = ln_36(x_int256);

           
           
           
           
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

       
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
           
           
           
            return ((ONE_18 * ONE_18) / exp(-x));
        }

       
       
       
       
       
       
       
       

       
       
       
       

       
       

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1;
        }

       
       
        x *= 100;

       
       
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

       

       
       

        int256 seriesSum = ONE_20;
        int256 term;

       
        term = x;
        seriesSum += term;

       
       

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

       

       
       
       
       

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    
    function ln(int256 a) internal pure returns (int256) {
       
        _require(a > 0, Errors.OUT_OF_BOUNDS);

        if (a < ONE_18) {
           
           
           
            return (-ln((ONE_18 * ONE_18) / a));
        }

       
       
       
       
       
       
       
       

       
       
       
       
       

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0;
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1;
            sum += x1;
        }

       
        sum *= 100;
        a *= 100;

       

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

       
       
       
       

       
       
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

       
        int256 num = z;

       
        int256 seriesSum = num;

       
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

       

       
        seriesSum *= 2;

       
       
       

        return (sum + seriesSum) / 100;
    }

    
    function log(int256 arg, int256 base) internal pure returns (int256) {
       

       
       

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = ln_36(base);
        } else {
            logBase = ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = ln_36(arg);
        } else {
            logArg = ln(arg) * ONE_18;
        }

       
        return (logArg * ONE_18) / logBase;
    }

    
    function ln_36(int256 x) private pure returns (int256) {
       
       

       
        x *= ONE_18;

       
       

       
       
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

       
        int256 num = z;

       
        int256 seriesSum = num;

       
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

       

       
        return seriesSum * 2;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/SafeERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./UserBalance.sol";
import "./balances/BalanceAllocation.sol";
import "./balances/GeneralPoolsBalance.sol";
import "./balances/MinimalSwapInfoPoolsBalance.sol";
import "./balances/TwoTokenPoolsBalance.sol";

abstract contract AssetManagers is
    ReentrancyGuard,
    GeneralPoolsBalance,
    MinimalSwapInfoPoolsBalance,
    TwoTokenPoolsBalance
{
    using Math for uint256;
    using SafeERC20 for IERC20;

   
    mapping(bytes32 => mapping(IERC20 => address)) internal _poolAssetManagers;

    function managePoolBalance(PoolBalanceOp[] memory ops) external override nonReentrant whenNotPaused {
       
       
        PoolBalanceOp memory op;

        for (uint256 i = 0; i < ops.length; ++i) {
           
            op = ops[i];

            bytes32 poolId = op.poolId;
            _ensureRegisteredPool(poolId);

            IERC20 token = op.token;
            _require(_isTokenRegistered(poolId, token), Errors.TOKEN_NOT_REGISTERED);
            _require(_poolAssetManagers[poolId][token] == msg.sender, Errors.SENDER_NOT_ASSET_MANAGER);

            PoolBalanceOpKind kind = op.kind;
            uint256 amount = op.amount;
            (int256 cashDelta, int256 managedDelta) = _performPoolManagementOperation(kind, poolId, token, amount);

            emit PoolBalanceManaged(poolId, msg.sender, token, cashDelta, managedDelta);
        }
    }

    
    function _performPoolManagementOperation(
        PoolBalanceOpKind kind,
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) private returns (int256, int256) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        if (kind == PoolBalanceOpKind.WITHDRAW) {
            return _withdrawPoolBalance(poolId, specialization, token, amount);
        } else if (kind == PoolBalanceOpKind.DEPOSIT) {
            return _depositPoolBalance(poolId, specialization, token, amount);
        } else {
           
            return _updateManagedBalance(poolId, specialization, token, amount);
        }
    }

    
    function _withdrawPoolBalance(
        bytes32 poolId,
        PoolSpecialization specialization,
        IERC20 token,
        uint256 amount
    ) private returns (int256 cashDelta, int256 managedDelta) {
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _twoTokenPoolCashToManaged(poolId, token, amount);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _minimalSwapInfoPoolCashToManaged(poolId, token, amount);
        } else {
           
            _generalPoolCashToManaged(poolId, token, amount);
        }

        if (amount > 0) {
            token.safeTransfer(msg.sender, amount);
        }

       
       
        cashDelta = int256(-amount);
        managedDelta = int256(amount);
    }

    
    function _depositPoolBalance(
        bytes32 poolId,
        PoolSpecialization specialization,
        IERC20 token,
        uint256 amount
    ) private returns (int256 cashDelta, int256 managedDelta) {
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _twoTokenPoolManagedToCash(poolId, token, amount);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _minimalSwapInfoPoolManagedToCash(poolId, token, amount);
        } else {
           
            _generalPoolManagedToCash(poolId, token, amount);
        }

        if (amount > 0) {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }

       
       
        cashDelta = int256(amount);
        managedDelta = int256(-amount);
    }

    
    function _updateManagedBalance(
        bytes32 poolId,
        PoolSpecialization specialization,
        IERC20 token,
        uint256 amount
    ) private returns (int256 cashDelta, int256 managedDelta) {
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            managedDelta = _setTwoTokenPoolManagedBalance(poolId, token, amount);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            managedDelta = _setMinimalSwapInfoPoolManagedBalance(poolId, token, amount);
        } else {
           
            managedDelta = _setGeneralPoolManagedBalance(poolId, token, amount);
        }

        cashDelta = 0;
    }

    
    function _isTokenRegistered(bytes32 poolId, IERC20 token) private view returns (bool) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _isTwoTokenPoolTokenRegistered(poolId, token);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _isMinimalSwapInfoPoolTokenRegistered(poolId, token);
        } else {
           
            return _isGeneralPoolTokenRegistered(poolId, token);
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./VaultAuthorization.sol";

abstract contract PoolRegistry is ReentrancyGuard, VaultAuthorization {
   
   
    mapping(bytes32 => bool) private _isPoolRegistered;

   
   
    uint256 private _nextPoolNonce;

    
    modifier withRegisteredPool(bytes32 poolId) {
        _ensureRegisteredPool(poolId);
        _;
    }

    
    modifier onlyPool(bytes32 poolId) {
        _ensurePoolIsSender(poolId);
        _;
    }

    
    function _ensureRegisteredPool(bytes32 poolId) internal view {
        _require(_isPoolRegistered[poolId], Errors.INVALID_POOL_ID);
    }

    
    function _ensurePoolIsSender(bytes32 poolId) private view {
        _ensureRegisteredPool(poolId);
        _require(msg.sender == _getPoolAddress(poolId), Errors.CALLER_NOT_POOL);
    }

    function registerPool(PoolSpecialization specialization)
        external
        override
        nonReentrant
        whenNotPaused
        returns (bytes32)
    {
       
       

        bytes32 poolId = _toPoolId(msg.sender, specialization, uint80(_nextPoolNonce));

        _require(!_isPoolRegistered[poolId], Errors.INVALID_POOL_ID);
        _isPoolRegistered[poolId] = true;

        _nextPoolNonce += 1;

       
        emit PoolRegistered(poolId, msg.sender, specialization);
        return poolId;
    }

    function getPool(bytes32 poolId)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (address, PoolSpecialization)
    {
        return (_getPoolAddress(poolId), _getPoolSpecialization(poolId));
    }

    
    function _toPoolId(
        address pool,
        PoolSpecialization specialization,
        uint80 nonce
    ) internal pure returns (bytes32) {
        bytes32 serialized;

        serialized |= bytes32(uint256(nonce));
        serialized |= bytes32(uint256(specialization)) << (10 * 8);
        serialized |= bytes32(uint256(pool)) << (12 * 8);

        return serialized;
    }

    
    function _getPoolAddress(bytes32 poolId) internal pure returns (address) {
       
       
        return address(uint256(poolId) >> (12 * 8));
    }

    
    function _getPoolSpecialization(bytes32 poolId) internal pure returns (PoolSpecialization specialization) {
       
        uint256 value = uint256(poolId >> (10 * 8)) & (2**(2 * 8) - 1);

       
       
       

       
       
        _require(value < 3, Errors.INVALID_POOL_ID);

       
       
        assembly {
            specialization := value
        }
    }
}

pragma solidity ^0.7.0;

import "../../lib/math/Math.sol";

library BalanceAllocation {
    using Math for uint256;

   
   

    
    function total(bytes32 balance) internal pure returns (uint256) {
       
       
        return cash(balance) + managed(balance);
    }

    
    function cash(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(balance) & mask;
    }

    
    function managed(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(balance >> 112) & mask;
    }

    
    function lastChangeBlock(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(32) - 1;
        return uint256(balance >> 224) & mask;
    }

    
    function managedDelta(bytes32 newBalance, bytes32 oldBalance) internal pure returns (int256) {
       
        return int256(managed(newBalance)) - int256(managed(oldBalance));
    }

    
    function totalsAndLastChangeBlock(bytes32[] memory balances)
        internal
        pure
        returns (
            uint256[] memory results,
            uint256 lastChangeBlock_
        )
    {
        results = new uint256[](balances.length);
        lastChangeBlock_ = 0;

        for (uint256 i = 0; i < results.length; i++) {
            bytes32 balance = balances[i];
            results[i] = total(balance);
            lastChangeBlock_ = Math.max(lastChangeBlock_, lastChangeBlock(balance));
        }
    }

    
    function isZero(bytes32 balance) internal pure returns (bool) {
       
        uint256 mask = 2**(224) - 1;
        return (uint256(balance) & mask) == 0;
    }

    
    function isNotZero(bytes32 balance) internal pure returns (bool) {
        return !isZero(balance);
    }

    
    function toBalance(
        uint256 _cash,
        uint256 _managed,
        uint256 _blockNumber
    ) internal pure returns (bytes32) {
        uint256 _total = _cash + _managed;

       
       
        _require(_total >= _cash && _total < 2**112, Errors.BALANCE_TOTAL_OVERFLOW);

       
        return _pack(_cash, _managed, _blockNumber);
    }

    
    function increaseCash(bytes32 balance, uint256 amount) internal view returns (bytes32) {
        uint256 newCash = cash(balance).add(amount);
        uint256 currentManaged = managed(balance);
        uint256 newLastChangeBlock = block.number;

        return toBalance(newCash, currentManaged, newLastChangeBlock);
    }

    
    function decreaseCash(bytes32 balance, uint256 amount) internal view returns (bytes32) {
        uint256 newCash = cash(balance).sub(amount);
        uint256 currentManaged = managed(balance);
        uint256 newLastChangeBlock = block.number;

        return toBalance(newCash, currentManaged, newLastChangeBlock);
    }

    
    function cashToManaged(bytes32 balance, uint256 amount) internal pure returns (bytes32) {
        uint256 newCash = cash(balance).sub(amount);
        uint256 newManaged = managed(balance).add(amount);
        uint256 currentLastChangeBlock = lastChangeBlock(balance);

        return toBalance(newCash, newManaged, currentLastChangeBlock);
    }

    
    function managedToCash(bytes32 balance, uint256 amount) internal pure returns (bytes32) {
        uint256 newCash = cash(balance).add(amount);
        uint256 newManaged = managed(balance).sub(amount);
        uint256 currentLastChangeBlock = lastChangeBlock(balance);

        return toBalance(newCash, newManaged, currentLastChangeBlock);
    }

    
    function setManaged(bytes32 balance, uint256 newManaged) internal view returns (bytes32) {
        uint256 currentCash = cash(balance);
        uint256 newLastChangeBlock = block.number;
        return toBalance(currentCash, newManaged, newLastChangeBlock);
    }

   

   
   
   
   
   
   
   
   
   
   
   
   
   

    
    function _decodeBalanceA(bytes32 sharedBalance) private pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(sharedBalance) & mask;
    }

    
    function _decodeBalanceB(bytes32 sharedBalance) private pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(sharedBalance >> 112) & mask;
    }

   

    
    function fromSharedToBalanceA(bytes32 sharedCash, bytes32 sharedManaged) internal pure returns (bytes32) {
       
       
        return toBalance(_decodeBalanceA(sharedCash), _decodeBalanceA(sharedManaged), lastChangeBlock(sharedCash));
    }

    
    function fromSharedToBalanceB(bytes32 sharedCash, bytes32 sharedManaged) internal pure returns (bytes32) {
       
       
        return toBalance(_decodeBalanceB(sharedCash), _decodeBalanceB(sharedManaged), lastChangeBlock(sharedCash));
    }

    
    function toSharedCash(bytes32 tokenABalance, bytes32 tokenBBalance) internal pure returns (bytes32) {
       
       
        uint32 newLastChangeBlock = uint32(Math.max(lastChangeBlock(tokenABalance), lastChangeBlock(tokenBBalance)));

        return _pack(cash(tokenABalance), cash(tokenBBalance), newLastChangeBlock);
    }

    
    function toSharedManaged(bytes32 tokenABalance, bytes32 tokenBBalance) internal pure returns (bytes32) {
       
        return _pack(managed(tokenABalance), managed(tokenBBalance), 0);
    }

   

    
    function _pack(
        uint256 _leastSignificant,
        uint256 _midSignificant,
        uint256 _mostSignificant
    ) private pure returns (bytes32) {
        return bytes32((_mostSignificant << 224) + (_midSignificant << 112) + _leastSignificant);
    }
}

pragma solidity ^0.7.0;

import "../../lib/helpers/BalancerErrors.sol";
import "../../lib/openzeppelin/EnumerableMap.sol";
import "../../lib/openzeppelin/IERC20.sol";

import "./BalanceAllocation.sol";

abstract contract GeneralPoolsBalance {
    using BalanceAllocation for bytes32;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

   
   
   
   
   
   
   
   
   

   
   
    mapping(bytes32 => EnumerableMap.IERC20ToBytes32Map) internal _generalPoolsBalances;

    
    function _registerGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
           
           
            bool added = poolBalances.set(tokens[i], 0);
            _require(added, Errors.TOKEN_ALREADY_REGISTERED);
        }
    }

    
    function _deregisterGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);
            _require(currentBalance.isZero(), Errors.NONZERO_TOKEN_BALANCE);

           
           
            poolBalances.remove(token);
        }
    }

    
    function _setGeneralPoolBalances(bytes32 poolId, bytes32[] memory balances) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < balances.length; ++i) {
           
           
            poolBalances.unchecked_setAt(i, balances[i]);
        }
    }

    
    function _generalPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    
    function _generalPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    
    function _setGeneralPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateGeneralPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    
    function _updateGeneralPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) private returns (int256) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);

        bytes32 newBalance = mutation(currentBalance, amount);
        poolBalances.set(token, newBalance);

        return newBalance.managedDelta(currentBalance);
    }

    
    function _getGeneralPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        tokens = new IERC20[](poolBalances.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
           
           
            (tokens[i], balances[i]) = poolBalances.unchecked_at(i);
        }
    }

    
    function _getGeneralPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return _getGeneralPoolBalance(poolBalances, token);
    }

    
    function _getGeneralPoolBalance(EnumerableMap.IERC20ToBytes32Map storage poolBalances, IERC20 token)
        private
        view
        returns (bytes32)
    {
        return poolBalances.get(token, Errors.TOKEN_NOT_REGISTERED);
    }

    
    function _isGeneralPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return poolBalances.contains(token);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/helpers/BalancerErrors.sol";
import "../../lib/openzeppelin/EnumerableSet.sol";
import "../../lib/openzeppelin/IERC20.sol";

import "./BalanceAllocation.sol";
import "../PoolRegistry.sol";

abstract contract MinimalSwapInfoPoolsBalance is PoolRegistry {
    using BalanceAllocation for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

   
   
   
   
   
   
   
   
   

    mapping(bytes32 => mapping(IERC20 => bytes32)) internal _minimalSwapInfoPoolsBalances;
    mapping(bytes32 => EnumerableSet.AddressSet) internal _minimalSwapInfoPoolsTokens;

    
    function _registerMinimalSwapInfoPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            bool added = poolTokens.add(address(tokens[i]));
            _require(added, Errors.TOKEN_ALREADY_REGISTERED);
           
           
        }
    }

    
    function _deregisterMinimalSwapInfoPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            _require(_minimalSwapInfoPoolsBalances[poolId][token].isZero(), Errors.NONZERO_TOKEN_BALANCE);

           
           
            delete _minimalSwapInfoPoolsBalances[poolId][token];

            bool removed = poolTokens.remove(address(token));
            _require(removed, Errors.TOKEN_NOT_REGISTERED);
        }
    }

    
    function _setMinimalSwapInfoPoolBalances(
        bytes32 poolId,
        IERC20[] memory tokens,
        bytes32[] memory balances
    ) internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            _minimalSwapInfoPoolsBalances[poolId][tokens[i]] = balances[i];
        }
    }

    
    function _minimalSwapInfoPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    
    function _minimalSwapInfoPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    
    function _setMinimalSwapInfoPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    
    function _updateMinimalSwapInfoPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) internal returns (int256) {
        bytes32 currentBalance = _getMinimalSwapInfoPoolBalance(poolId, token);

        bytes32 newBalance = mutation(currentBalance, amount);
        _minimalSwapInfoPoolsBalances[poolId][token] = newBalance;

        return newBalance.managedDelta(currentBalance);
    }

    
    function _getMinimalSwapInfoPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];
        tokens = new IERC20[](poolTokens.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
           
           
            IERC20 token = IERC20(poolTokens.unchecked_at(i));
            tokens[i] = token;
            balances[i] = _minimalSwapInfoPoolsBalances[poolId][token];
        }
    }

    
    function _getMinimalSwapInfoPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        bytes32 balance = _minimalSwapInfoPoolsBalances[poolId][token];

       
       
       
        bool tokenRegistered = balance.isNotZero() || _minimalSwapInfoPoolsTokens[poolId].contains(address(token));

        if (!tokenRegistered) {
           
           
            _ensureRegisteredPool(poolId);
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }

        return balance;
    }

    
    function _isMinimalSwapInfoPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];
        return poolTokens.contains(address(token));
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/helpers/BalancerErrors.sol";
import "../../lib/openzeppelin/IERC20.sol";

import "./BalanceAllocation.sol";
import "../PoolRegistry.sol";

abstract contract TwoTokenPoolsBalance is PoolRegistry {
    using BalanceAllocation for bytes32;

   
   
   
   
   
   
   
   
   
   

    struct TwoTokenPoolBalances {
        bytes32 sharedCash;
        bytes32 sharedManaged;
    }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

    struct TwoTokenPoolTokens {
        IERC20 tokenA;
        IERC20 tokenB;
        mapping(bytes32 => TwoTokenPoolBalances) balances;
    }

    mapping(bytes32 => TwoTokenPoolTokens) private _twoTokenPoolTokens;

    
    function _registerTwoTokenPoolTokens(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    ) internal {
       
       
        _require(tokenX != tokenY, Errors.TOKEN_ALREADY_REGISTERED);

        _require(tokenX < tokenY, Errors.UNSORTED_TOKENS);

       
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        _require(poolTokens.tokenA == IERC20(0) && poolTokens.tokenB == IERC20(0), Errors.TOKENS_ALREADY_SET);

       
        poolTokens.tokenA = tokenX;
        poolTokens.tokenB = tokenY;

       
       
    }

    
    function _deregisterTwoTokenPoolTokens(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    ) internal {
        (
            bytes32 balanceA,
            bytes32 balanceB,
            TwoTokenPoolBalances storage poolBalances
        ) = _getTwoTokenPoolSharedBalances(poolId, tokenX, tokenY);

        _require(balanceA.isZero() && balanceB.isZero(), Errors.NONZERO_TOKEN_BALANCE);

        delete _twoTokenPoolTokens[poolId];

       
       
        delete poolBalances.sharedCash;
    }

    
    function _setTwoTokenPoolCashBalances(
        bytes32 poolId,
        IERC20 tokenA,
        bytes32 balanceA,
        IERC20 tokenB,
        bytes32 balanceB
    ) internal {
        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);
        TwoTokenPoolBalances storage poolBalances = _twoTokenPoolTokens[poolId].balances[pairHash];
        poolBalances.sharedCash = BalanceAllocation.toSharedCash(balanceA, balanceB);
    }

    
    function _twoTokenPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    
    function _twoTokenPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    
    function _setTwoTokenPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    
    function _updateTwoTokenPoolSharedBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) private returns (int256) {
        (
            TwoTokenPoolBalances storage balances,
            IERC20 tokenA,
            bytes32 balanceA,
            ,
            bytes32 balanceB
        ) = _getTwoTokenPoolBalances(poolId);

        int256 delta;
        if (token == tokenA) {
            bytes32 newBalance = mutation(balanceA, amount);
            delta = newBalance.managedDelta(balanceA);
            balanceA = newBalance;
        } else {
           
            bytes32 newBalance = mutation(balanceB, amount);
            delta = newBalance.managedDelta(balanceB);
            balanceB = newBalance;
        }

        balances.sharedCash = BalanceAllocation.toSharedCash(balanceA, balanceB);
        balances.sharedManaged = BalanceAllocation.toSharedManaged(balanceA, balanceB);

        return delta;
    }

    
    function _getTwoTokenPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        (, IERC20 tokenA, bytes32 balanceA, IERC20 tokenB, bytes32 balanceB) = _getTwoTokenPoolBalances(poolId);

       
       
        if (tokenA == IERC20(0) || tokenB == IERC20(0)) {
            return (new IERC20[](0), new bytes32[](0));
        }

       
       

        tokens = new IERC20[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        balances = new bytes32[](2);
        balances[0] = balanceA;
        balances[1] = balanceB;
    }

    
    function _getTwoTokenPoolBalances(bytes32 poolId)
        private
        view
        returns (
            TwoTokenPoolBalances storage poolBalances,
            IERC20 tokenA,
            bytes32 balanceA,
            IERC20 tokenB,
            bytes32 balanceB
        )
    {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        tokenA = poolTokens.tokenA;
        tokenB = poolTokens.tokenB;

        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);
        poolBalances = poolTokens.balances[pairHash];

        bytes32 sharedCash = poolBalances.sharedCash;
        bytes32 sharedManaged = poolBalances.sharedManaged;

        balanceA = BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
        balanceB = BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    
    function _getTwoTokenPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
       
       
        (, IERC20 tokenA, bytes32 balanceA, IERC20 tokenB, bytes32 balanceB) = _getTwoTokenPoolBalances(poolId);

        if (token == tokenA) {
            return balanceA;
        } else if (token == tokenB) {
            return balanceB;
        } else {
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }
    }

    
    function _getTwoTokenPoolSharedBalances(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    )
        internal
        view
        returns (
            bytes32 balanceA,
            bytes32 balanceB,
            TwoTokenPoolBalances storage poolBalances
        )
    {
        (IERC20 tokenA, IERC20 tokenB) = _sortTwoTokens(tokenX, tokenY);
        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);

        poolBalances = _twoTokenPoolTokens[poolId].balances[pairHash];

       
       
        bytes32 sharedCash = poolBalances.sharedCash;
        bytes32 sharedManaged = poolBalances.sharedManaged;

       
       
       
        bool tokensRegistered = sharedCash.isNotZero() ||
            sharedManaged.isNotZero() ||
            (_isTwoTokenPoolTokenRegistered(poolId, tokenA) && _isTwoTokenPoolTokenRegistered(poolId, tokenB));

        if (!tokensRegistered) {
           
           
            _ensureRegisteredPool(poolId);
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }

        balanceA = BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
        balanceB = BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    
    function _isTwoTokenPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];

       
        return (token == poolTokens.tokenA || token == poolTokens.tokenB) && token != IERC20(0);
    }

    
    function _getTwoTokenPairHash(IERC20 tokenA, IERC20 tokenB) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    
    function _sortTwoTokens(IERC20 tokenX, IERC20 tokenY) private pure returns (IERC20, IERC20) {
        return tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
    }
}

pragma solidity ^0.7.0;

import "./IERC20.sol";

import "../helpers/BalancerErrors.sol";

library EnumerableMap {
   
   

    struct IERC20ToBytes32MapEntry {
        IERC20 _key;
        bytes32 _value;
    }

    struct IERC20ToBytes32Map {
       
        uint256 _length;
       
        mapping(uint256 => IERC20ToBytes32MapEntry) _entries;
       
       
        mapping(IERC20 => uint256) _indexes;
    }

    
    function set(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        bytes32 value
    ) internal returns (bool) {
       
        uint256 keyIndex = map._indexes[key];

       
        if (keyIndex == 0) {
            uint256 previousLength = map._length;
            map._entries[previousLength] = IERC20ToBytes32MapEntry({ _key: key, _value: value });
            map._length = previousLength + 1;

           
           
            map._indexes[key] = previousLength + 1;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    
    function unchecked_setAt(
        IERC20ToBytes32Map storage map,
        uint256 index,
        bytes32 value
    ) internal {
        map._entries[index]._value = value;
    }

    
    function remove(IERC20ToBytes32Map storage map, IERC20 key) internal returns (bool) {
       
        uint256 keyIndex = map._indexes[key];

       
        if (keyIndex != 0) {
           
           
           

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._length - 1;

           
           

            IERC20ToBytes32MapEntry storage lastEntry = map._entries[lastIndex];

           
            map._entries[toDeleteIndex] = lastEntry;
           
            map._indexes[lastEntry._key] = toDeleteIndex + 1;

           
            delete map._entries[lastIndex];
            map._length = lastIndex;

           
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    
    function contains(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    
    function length(IERC20ToBytes32Map storage map) internal view returns (uint256) {
        return map._length;
    }

    
    function at(IERC20ToBytes32Map storage map, uint256 index) internal view returns (IERC20, bytes32) {
        _require(map._length > index, Errors.OUT_OF_BOUNDS);
        return unchecked_at(map, index);
    }

    
    function unchecked_at(IERC20ToBytes32Map storage map, uint256 index) internal view returns (IERC20, bytes32) {
        IERC20ToBytes32MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    
    function unchecked_valueAt(IERC20ToBytes32Map storage map, uint256 index) internal view returns (bytes32) {
        return map._entries[index]._value;
    }

    
    function get(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        uint256 errorCode
    ) internal view returns (bytes32) {
        uint256 index = map._indexes[key];
        _require(index > 0, errorCode);
        return unchecked_valueAt(map, index - 1);
    }

    
    function unchecked_indexOf(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (uint256) {
        return map._indexes[key];
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library EnumerableSet {
   
   

    struct AddressSet {
       
        address[] _values;
       
       
        mapping(address => uint256) _indexes;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
           
           
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
       
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
           
           
           
           

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

           
           

            address lastValue = set._values[lastIndex];

           
            set._values[toDeleteIndex] = lastValue;
           
            set._indexes[lastValue] = toDeleteIndex + 1;

           
            set._values.pop();

           
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function length(AddressSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        _require(set._values.length > index, Errors.OUT_OF_BOUNDS);
        return unchecked_at(set, index);
    }

    
    function unchecked_at(AddressSet storage set, uint256 index) internal view returns (address) {
        return set._values[index];
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/openzeppelin/IERC20.sol";

import "./IVault.sol";

interface IPoolSwapStructs {
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
       
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/openzeppelin/EnumerableMap.sol";
import "../lib/openzeppelin/EnumerableSet.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeCast.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./PoolBalances.sol";
import "./interfaces/IPoolSwapStructs.sol";
import "./interfaces/IGeneralPool.sol";
import "./interfaces/IMinimalSwapInfoPool.sol";
import "./balances/BalanceAllocation.sol";

abstract contract Swaps is ReentrancyGuard, PoolBalances {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    using Math for int256;
    using Math for uint256;
    using SafeCast for uint256;
    using BalanceAllocation for bytes32;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        authenticateFor(funds.sender)
        returns (uint256 amountCalculated)
    {
       
       
        _require(block.timestamp <= deadline, Errors.SWAP_DEADLINE);

       
       
        _require(singleSwap.amount > 0, Errors.UNKNOWN_AMOUNT_IN_FIRST_SWAP);

        IERC20 tokenIn = _translateToIERC20(singleSwap.assetIn);
        IERC20 tokenOut = _translateToIERC20(singleSwap.assetOut);
        _require(tokenIn != tokenOut, Errors.CANNOT_SWAP_SAME_TOKEN);

       
        IPoolSwapStructs.SwapRequest memory poolRequest;
        poolRequest.poolId = singleSwap.poolId;
        poolRequest.kind = singleSwap.kind;
        poolRequest.tokenIn = tokenIn;
        poolRequest.tokenOut = tokenOut;
        poolRequest.amount = singleSwap.amount;
        poolRequest.userData = singleSwap.userData;
        poolRequest.from = funds.sender;
        poolRequest.to = funds.recipient;
       

        uint256 amountIn;
        uint256 amountOut;

        (amountCalculated, amountIn, amountOut) = _swapWithPool(poolRequest);
        _require(singleSwap.kind == SwapKind.GIVEN_IN ? amountOut >= limit : amountIn <= limit, Errors.SWAP_LIMIT);

        _receiveAsset(singleSwap.assetIn, amountIn, funds.sender, funds.fromInternalBalance);
        _sendAsset(singleSwap.assetOut, amountOut, funds.recipient, funds.toInternalBalance);

       
        _handleRemainingEth(_isETH(singleSwap.assetIn) ? amountIn : 0);
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        authenticateFor(funds.sender)
        returns (int256[] memory assetDeltas)
    {
       
       
        _require(block.timestamp <= deadline, Errors.SWAP_DEADLINE);

        InputHelpers.ensureInputLengthMatch(assets.length, limits.length);

       
        assetDeltas = _swapWithPools(swaps, assets, funds, kind);

       
       
        uint256 wrappedEth = 0;
        for (uint256 i = 0; i < assets.length; ++i) {
            IAsset asset = assets[i];
            int256 delta = assetDeltas[i];
            _require(delta <= limits[i], Errors.SWAP_LIMIT);

            if (delta > 0) {
                uint256 toReceive = uint256(delta);
                _receiveAsset(asset, toReceive, funds.sender, funds.fromInternalBalance);

                if (_isETH(asset)) {
                    wrappedEth = wrappedEth.add(toReceive);
                }
            } else if (delta < 0) {
                uint256 toSend = uint256(-delta);
                _sendAsset(asset, toSend, funds.recipient, funds.toInternalBalance);
            }
        }

       
        _handleRemainingEth(wrappedEth);
    }

   
   

    
    function _tokenGiven(
        SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) private pure returns (IERC20) {
        return kind == SwapKind.GIVEN_IN ? tokenIn : tokenOut;
    }

    
    function _tokenCalculated(
        SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) private pure returns (IERC20) {
        return kind == SwapKind.GIVEN_IN ? tokenOut : tokenIn;
    }

    
    function _getAmounts(
        SwapKind kind,
        uint256 amountGiven,
        uint256 amountCalculated
    ) private pure returns (uint256 amountIn, uint256 amountOut) {
        if (kind == SwapKind.GIVEN_IN) {
            (amountIn, amountOut) = (amountGiven, amountCalculated);
        } else {
           
            (amountIn, amountOut) = (amountCalculated, amountGiven);
        }
    }

    
    function _swapWithPools(
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        SwapKind kind
    ) private returns (int256[] memory assetDeltas) {
        assetDeltas = new int256[](assets.length);

       
       
        BatchSwapStep memory batchSwapStep;
        IPoolSwapStructs.SwapRequest memory poolRequest;

       
        IERC20 previousTokenCalculated;
        uint256 previousAmountCalculated;

        for (uint256 i = 0; i < swaps.length; ++i) {
            batchSwapStep = swaps[i];

            bool withinBounds = batchSwapStep.assetInIndex < assets.length &&
                batchSwapStep.assetOutIndex < assets.length;
            _require(withinBounds, Errors.OUT_OF_BOUNDS);

            IERC20 tokenIn = _translateToIERC20(assets[batchSwapStep.assetInIndex]);
            IERC20 tokenOut = _translateToIERC20(assets[batchSwapStep.assetOutIndex]);
            _require(tokenIn != tokenOut, Errors.CANNOT_SWAP_SAME_TOKEN);

           
            if (batchSwapStep.amount == 0) {
               
               
               
                _require(i > 0, Errors.UNKNOWN_AMOUNT_IN_FIRST_SWAP);
                bool usingPreviousToken = previousTokenCalculated == _tokenGiven(kind, tokenIn, tokenOut);
                _require(usingPreviousToken, Errors.MALCONSTRUCTED_MULTIHOP_SWAP);
                batchSwapStep.amount = previousAmountCalculated;
            }

           
            poolRequest.poolId = batchSwapStep.poolId;
            poolRequest.kind = kind;
            poolRequest.tokenIn = tokenIn;
            poolRequest.tokenOut = tokenOut;
            poolRequest.amount = batchSwapStep.amount;
            poolRequest.userData = batchSwapStep.userData;
            poolRequest.from = funds.sender;
            poolRequest.to = funds.recipient;
           

            uint256 amountIn;
            uint256 amountOut;
            (previousAmountCalculated, amountIn, amountOut) = _swapWithPool(poolRequest);

            previousTokenCalculated = _tokenCalculated(kind, tokenIn, tokenOut);

           
            assetDeltas[batchSwapStep.assetInIndex] = assetDeltas[batchSwapStep.assetInIndex].add(amountIn.toInt256());
            assetDeltas[batchSwapStep.assetOutIndex] = assetDeltas[batchSwapStep.assetOutIndex].sub(
                amountOut.toInt256()
            );
        }
    }

    
    function _swapWithPool(IPoolSwapStructs.SwapRequest memory request)
        private
        returns (
            uint256 amountCalculated,
            uint256 amountIn,
            uint256 amountOut
        )
    {
       
        address pool = _getPoolAddress(request.poolId);
        PoolSpecialization specialization = _getPoolSpecialization(request.poolId);

        if (specialization == PoolSpecialization.TWO_TOKEN) {
            amountCalculated = _processTwoTokenPoolSwapRequest(request, IMinimalSwapInfoPool(pool));
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            amountCalculated = _processMinimalSwapInfoPoolSwapRequest(request, IMinimalSwapInfoPool(pool));
        } else {
           
            amountCalculated = _processGeneralPoolSwapRequest(request, IGeneralPool(pool));
        }

        (amountIn, amountOut) = _getAmounts(request.kind, request.amount, amountCalculated);
        emit Swap(request.poolId, request.tokenIn, request.tokenOut, amountIn, amountOut);
    }

    function _processTwoTokenPoolSwapRequest(IPoolSwapStructs.SwapRequest memory request, IMinimalSwapInfoPool pool)
        private
        returns (uint256 amountCalculated)
    {
       
       

        (
            bytes32 tokenABalance,
            bytes32 tokenBBalance,
            TwoTokenPoolBalances storage poolBalances
        ) = _getTwoTokenPoolSharedBalances(request.poolId, request.tokenIn, request.tokenOut);

       
        bytes32 tokenInBalance;
        bytes32 tokenOutBalance;

       
        if (request.tokenIn < request.tokenOut) {
           
            tokenInBalance = tokenABalance;
            tokenOutBalance = tokenBBalance;
        } else {
           
            tokenOutBalance = tokenABalance;
            tokenInBalance = tokenBBalance;
        }

       
        (tokenInBalance, tokenOutBalance, amountCalculated) = _callMinimalSwapInfoPoolOnSwapHook(
            request,
            pool,
            tokenInBalance,
            tokenOutBalance
        );

       
        poolBalances.sharedCash = request.tokenIn < request.tokenOut
            ? BalanceAllocation.toSharedCash(tokenInBalance, tokenOutBalance)
            : BalanceAllocation.toSharedCash(tokenOutBalance, tokenInBalance);
    }

    function _processMinimalSwapInfoPoolSwapRequest(
        IPoolSwapStructs.SwapRequest memory request,
        IMinimalSwapInfoPool pool
    ) private returns (uint256 amountCalculated) {
        bytes32 tokenInBalance = _getMinimalSwapInfoPoolBalance(request.poolId, request.tokenIn);
        bytes32 tokenOutBalance = _getMinimalSwapInfoPoolBalance(request.poolId, request.tokenOut);

       
        (tokenInBalance, tokenOutBalance, amountCalculated) = _callMinimalSwapInfoPoolOnSwapHook(
            request,
            pool,
            tokenInBalance,
            tokenOutBalance
        );

        _minimalSwapInfoPoolsBalances[request.poolId][request.tokenIn] = tokenInBalance;
        _minimalSwapInfoPoolsBalances[request.poolId][request.tokenOut] = tokenOutBalance;
    }

    
    function _callMinimalSwapInfoPoolOnSwapHook(
        IPoolSwapStructs.SwapRequest memory request,
        IMinimalSwapInfoPool pool,
        bytes32 tokenInBalance,
        bytes32 tokenOutBalance
    )
        internal
        returns (
            bytes32 newTokenInBalance,
            bytes32 newTokenOutBalance,
            uint256 amountCalculated
        )
    {
        uint256 tokenInTotal = tokenInBalance.total();
        uint256 tokenOutTotal = tokenOutBalance.total();
        request.lastChangeBlock = Math.max(tokenInBalance.lastChangeBlock(), tokenOutBalance.lastChangeBlock());

       
        amountCalculated = pool.onSwap(request, tokenInTotal, tokenOutTotal);
        (uint256 amountIn, uint256 amountOut) = _getAmounts(request.kind, request.amount, amountCalculated);

        newTokenInBalance = tokenInBalance.increaseCash(amountIn);
        newTokenOutBalance = tokenOutBalance.decreaseCash(amountOut);
    }

    function _processGeneralPoolSwapRequest(IPoolSwapStructs.SwapRequest memory request, IGeneralPool pool)
        private
        returns (uint256 amountCalculated)
    {
        bytes32 tokenInBalance;
        bytes32 tokenOutBalance;

       
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[request.poolId];
        uint256 indexIn = poolBalances.unchecked_indexOf(request.tokenIn);
        uint256 indexOut = poolBalances.unchecked_indexOf(request.tokenOut);

        if (indexIn == 0 || indexOut == 0) {
           
           
            _ensureRegisteredPool(request.poolId);
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }

       
       
        indexIn -= 1;
        indexOut -= 1;

        uint256 tokenAmount = poolBalances.length();
        uint256[] memory currentBalances = new uint256[](tokenAmount);

        request.lastChangeBlock = 0;
        for (uint256 i = 0; i < tokenAmount; i++) {
           
           
            bytes32 balance = poolBalances.unchecked_valueAt(i);

            currentBalances[i] = balance.total();
            request.lastChangeBlock = Math.max(request.lastChangeBlock, balance.lastChangeBlock());

            if (i == indexIn) {
                tokenInBalance = balance;
            } else if (i == indexOut) {
                tokenOutBalance = balance;
            }
        }

       
        amountCalculated = pool.onSwap(request, currentBalances, indexIn, indexOut);
        (uint256 amountIn, uint256 amountOut) = _getAmounts(request.kind, request.amount, amountCalculated);
        tokenInBalance = tokenInBalance.increaseCash(amountIn);
        tokenOutBalance = tokenOutBalance.decreaseCash(amountOut);

       
       
        poolBalances.unchecked_setAt(indexIn, tokenInBalance);
        poolBalances.unchecked_setAt(indexOut, tokenOutBalance);
    }

   
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external override returns (int256[] memory) {
       
       
       
       
       
       
       
       
       
       
       
       
       
       

        if (msg.sender != address(this)) {
           
           

           
            (bool success, ) = address(this).call(msg.data);

           
            assembly {
               
                switch success
                    case 0 {
                       
                       

                       
                       
                        returndatacopy(0, 0, 0x04)
                        let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                       
                        if eq(eq(error, 0xfa61cc1200000000000000000000000000000000000000000000000000000000), 0) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                       
                       
                       
                       
                       
                        mstore(0, 32)

                       
                       
                       
                        let size := sub(returndatasize(), 0x04)
                        returndatacopy(0x20, 0x04, size)

                       
                       
                        return(0, add(size, 32))
                    }
                    default {
                       
                        invalid()
                    }
            }
        } else {
            int256[] memory deltas = _swapWithPools(swaps, assets, funds, kind);

           
            assembly {
               
               
               
                let size := mul(mload(deltas), 32)

               
               
               
               
                mstore(sub(deltas, 0x20), 0x00000000000000000000000000000000000000000000000000000000fa61cc12)
                let start := sub(deltas, 0x04)

               
               
                revert(start, add(size, 36))
            }
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

interface IGeneralPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amount);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./Fees.sol";
import "./interfaces/IFlashLoanRecipient.sol";

abstract contract FlashLoans is Fees, ReentrancyGuard, TemporarilyPausable {
    using SafeERC20 for IERC20;

    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external override nonReentrant whenNotPaused {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        uint256[] memory feeAmounts = new uint256[](tokens.length);
        uint256[] memory preLoanBalances = new uint256[](tokens.length);

       
        IERC20 previousToken = IERC20(0);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];

            _require(token > previousToken, token == IERC20(0) ? Errors.ZERO_TOKEN : Errors.UNSORTED_TOKENS);
            previousToken = token;

            preLoanBalances[i] = token.balanceOf(address(this));
            feeAmounts[i] = _calculateFlashLoanFeeAmount(amount);

            _require(preLoanBalances[i] >= amount, Errors.INSUFFICIENT_FLASH_LOAN_BALANCE);
            token.safeTransfer(address(recipient), amount);
        }

        recipient.receiveFlashLoan(tokens, amounts, feeAmounts, userData);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 preLoanBalance = preLoanBalances[i];

           
           
            uint256 postLoanBalance = token.balanceOf(address(this));
            _require(postLoanBalance >= preLoanBalance, Errors.INVALID_POST_LOAN_BALANCE);

           
            uint256 receivedFeeAmount = postLoanBalance - preLoanBalance;
            _require(receivedFeeAmount >= feeAmounts[i], Errors.INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT);

            _payFeeAmount(token, receivedFeeAmount);
            emit FlashLoan(recipient, token, amounts[i], receivedFeeAmount);
        }
    }
}

pragma solidity ^0.7.0;

import "../lib/math/Math.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "../vault/interfaces/IFlashLoanRecipient.sol";
import "../vault/interfaces/IVault.sol";

import "./TestToken.sol";

contract MockFlashLoanRecipient is IFlashLoanRecipient {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address public immutable vault;
    bool public repayLoan;
    bool public repayInExcess;
    bool public reenter;

    constructor(address _vault) {
        vault = _vault;
        repayLoan = true;
        repayInExcess = false;
        reenter = false;
    }

    function setRepayLoan(bool _repayLoan) public {
        repayLoan = _repayLoan;
    }

    function setRepayInExcess(bool _repayInExcess) public {
        repayInExcess = _repayInExcess;
    }

    function setReenter(bool _reenter) public {
        reenter = _reenter;
    }

   
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            uint256 feeAmount = feeAmounts[i];

            require(token.balanceOf(address(this)) == amount, "INVALID_FLASHLOAN_BALANCE");

            if (reenter) {
                IVault(msg.sender).flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, userData);
            }

            TestToken(address(token)).mint(address(this), repayInExcess ? feeAmount.add(1) : feeAmount);

            uint256 totalDebt = amount.add(feeAmount);

            if (!repayLoan) {
                totalDebt = totalDebt.sub(1);
            } else if (repayInExcess) {
                totalDebt = totalDebt.add(1);
            }

            token.safeTransfer(vault, totalDebt);
        }
    }
}

pragma solidity ^0.7.0;

import "../lib/openzeppelin/ERC20.sol";
import "../lib/openzeppelin/ERC20Burnable.sol";
import "../lib/openzeppelin/AccessControl.sol";

contract TestToken is AccessControl, ERC20, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        address admin,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        _setupDecimals(decimals);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    function mint(address recipient, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER");
        _mint(recipient, amount);
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE)
        );
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, Errors.ERC20_DECREASED_ALLOWANCE_BELOW_ZERO)
        );
        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _require(sender != address(0), Errors.ERC20_TRANSFER_FROM_ZERO_ADDRESS);
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_BALANCE);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        _require(account != address(0), Errors.ERC20_MINT_TO_ZERO_ADDRESS);

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        _require(account != address(0), Errors.ERC20_BURN_FROM_ZERO_ADDRESS);

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, Errors.ERC20_BURN_EXCEEDS_ALLOWANCE);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _require(owner != address(0), Errors.ERC20_APPROVE_FROM_ZERO_ADDRESS);
        _require(spender != address(0), Errors.ERC20_APPROVE_TO_ZERO_ADDRESS);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.7.0;

import "./ERC20.sol";

abstract contract ERC20Burnable is ERC20 {
    using SafeMath for uint256;

    
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, Errors.ERC20_BURN_EXCEEDS_ALLOWANCE);

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

import "./EnumerableSet.sol";

abstract contract AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].members.contains(account);
    }

    
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    
    function grantRole(bytes32 role, address account) public virtual {
        _require(hasRole(_roles[role].adminRole, msg.sender), Errors.GRANT_SENDER_NOT_ADMIN);

        _grantRole(role, account);
    }

    
    function revokeRole(bytes32 role, address account) public virtual {
        _require(hasRole(_roles[role].adminRole, msg.sender), Errors.REVOKE_SENDER_NOT_ADMIN);

        _revokeRole(role, account);
    }

    
    function renounceRole(bytes32 role, address account) public virtual {
        _require(account == msg.sender, Errors.RENOUNCE_SENDER_NOT_ALLOWED);

        _revokeRole(role, account);
    }

    
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, Errors.SUB_OVERFLOW);
    }

    
    function sub(uint256 a, uint256 b, uint256 errorCode) internal pure returns (uint256) {
        _require(b <= a, errorCode);
        uint256 c = a - b;

        return c;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin/Address.sol";
import "../lib/openzeppelin/Create2.sol";

import "./TestToken.sol";

contract TokenFactory {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _tokens;

    event TokenCreated(address indexed token);

    constructor() {
       
    }

    function getTotalTokens() external view returns (uint256) {
        return _tokens.length();
    }

    function getTokens(uint256 start, uint256 end) external view returns (address[] memory) {
        require((end >= start) && (end - start) <= _tokens.length(), "OUT_OF_BOUNDS");

        address[] memory token = new address[](end - start);
        for (uint256 i = 0; i < token.length; ++i) {
            token[i] = _tokens.at(i + start);
        }

        return token;
    }

    function create(
        address admin,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address) {
        bytes memory creationCode = abi.encodePacked(
            type(TestToken).creationCode,
            abi.encode(admin, name, symbol, decimals)
        );

        address expectedToken = Create2.computeAddress(0, keccak256(creationCode));

        if (expectedToken.isContract()) {
            return expectedToken;
        } else {
            address token = Create2.deploy(0, 0, creationCode);
            assert(token == expectedToken);

            _tokens.add(token);
            emit TokenCreated(token);

            return token;
        }
    }
}

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

library Create2 {
    
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, 'CREATE2_INSUFFICIENT_BALANCE');
        require(bytecode.length != 0, 'CREATE2_BYTECODE_ZERO');
       
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), 'CREATE2_DEPLOY_FAILED');
        return addr;
    }

    
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin/IERC20.sol";

import "../vault/interfaces/IVault.sol";
import "../vault/interfaces/IBasePool.sol";

contract MockVault {
    struct Pool {
        IERC20[] tokens;
        mapping(IERC20 => uint256) balances;
    }

    IAuthorizer private _authorizer;
    mapping(bytes32 => Pool) private pools;

    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFees
    );

    constructor(IAuthorizer authorizer) {
        _authorizer = authorizer;
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _authorizer;
    }

    function getPoolTokens(bytes32 poolId) external view returns (IERC20[] memory tokens, uint256[] memory balances) {
        Pool storage pool = pools[poolId];
        tokens = new IERC20[](pool.tokens.length);
        balances = new uint256[](pool.tokens.length);

        for (uint256 i = 0; i < pool.tokens.length; i++) {
            tokens[i] = pool.tokens[i];
            balances[i] = pool.balances[tokens[i]];
        }
    }

    function registerPool(IVault.PoolSpecialization) external view returns (bytes32) {
       
    }

    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory
    ) external {
        Pool storage pool = pools[poolId];
        for (uint256 i = 0; i < tokens.length; i++) {
            pool.tokens.push(tokens[i]);
        }
    }

    function callJoinPool(
        address poolAddress,
        bytes32 poolId,
        address recipient,
        uint256[] memory currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolFeePercentage,
        bytes memory userData
    ) external {
        (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts) = IBasePool(poolAddress).onJoinPool(
            poolId,
            msg.sender,
            recipient,
            currentBalances,
            lastChangeBlock,
            protocolFeePercentage,
            userData
        );

        Pool storage pool = pools[poolId];
        for (uint256 i = 0; i < pool.tokens.length; i++) {
            pool.balances[pool.tokens[i]] += amountsIn[i];
        }

        IERC20[] memory tokens = new IERC20[](currentBalances.length);
        int256[] memory deltas = new int256[](amountsIn.length);
        for (uint256 i = 0; i < amountsIn.length; ++i) {
            deltas[i] = int256(amountsIn[i]);
        }

        emit PoolBalanceChanged(poolId, msg.sender, tokens, deltas, dueProtocolFeeAmounts);
    }

    function callExitPool(
        address poolAddress,
        bytes32 poolId,
        address recipient,
        uint256[] memory currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolFeePercentage,
        bytes memory userData
    ) external {
        (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts) = IBasePool(poolAddress).onExitPool(
            poolId,
            msg.sender,
            recipient,
            currentBalances,
            lastChangeBlock,
            protocolFeePercentage,
            userData
        );

        Pool storage pool = pools[poolId];
        for (uint256 i = 0; i < pool.tokens.length; i++) {
            pool.balances[pool.tokens[i]] -= amountsOut[i];
        }

        IERC20[] memory tokens = new IERC20[](currentBalances.length);
        int256[] memory deltas = new int256[](amountsOut.length);
        for (uint256 i = 0; i < amountsOut.length; ++i) {
            deltas[i] = int256(-amountsOut[i]);
        }

        emit PoolBalanceChanged(poolId, msg.sender, tokens, deltas, dueProtocolFeeAmounts);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../vault/interfaces/IVault.sol";
import "../../vault/interfaces/IBasePool.sol";

abstract contract BasePoolFactory {
    IVault private immutable _vault;
    mapping(address => bool) private _isPoolFromFactory;

    event PoolCreated(address indexed pool);

    constructor(IVault vault) {
        _vault = vault;
    }

    
    function getVault() public view returns (IVault) {
        return _vault;
    }

    
    function isPoolFromFactory(address pool) external view returns (bool) {
        return _isPoolFromFactory[pool];
    }

    
    function _register(address pool) internal {
        _isPoolFromFactory[pool] = true;
        emit PoolCreated(pool);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../vault/interfaces/IVault.sol";

import "../pools/factories/BasePoolFactory.sol";

contract MockFactoryCreatedPool {
    function getPoolId() external view returns (bytes32) {
        return bytes32(uint256(address(this)));
    }
}

contract MockPoolFactory is BasePoolFactory {
    constructor(IVault _vault) BasePoolFactory(_vault) {
       
    }

    function create() external returns (address) {
        address pool = address(new MockFactoryCreatedPool());
        _register(pool);
        return pool;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/math/FixedPoint.sol";
import "../../lib/helpers/InputHelpers.sol";

import "../BaseMinimalSwapInfoPool.sol";

import "./WeightedMath.sol";
import "./WeightedPoolUserDataHelpers.sol";

contract WeightedPool is BaseMinimalSwapInfoPool, WeightedMath {
    using FixedPoint for uint256;
    using WeightedPoolUserDataHelpers for bytes;

   
   
    uint256 private immutable _maxWeightTokenIndex;

    uint256 private immutable _normalizedWeight0;
    uint256 private immutable _normalizedWeight1;
    uint256 private immutable _normalizedWeight2;
    uint256 private immutable _normalizedWeight3;
    uint256 private immutable _normalizedWeight4;
    uint256 private immutable _normalizedWeight5;
    uint256 private immutable _normalizedWeight6;
    uint256 private immutable _normalizedWeight7;

    uint256 private _lastInvariant;

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory normalizedWeights,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BaseMinimalSwapInfoPool(
            vault,
            name,
            symbol,
            tokens,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        uint256 numTokens = tokens.length;
        InputHelpers.ensureInputLengthMatch(numTokens, normalizedWeights.length);

       
        uint256 normalizedSum = 0;
        uint256 maxWeightTokenIndex = 0;
        uint256 maxNormalizedWeight = 0;
        for (uint8 i = 0; i < numTokens; i++) {
            uint256 normalizedWeight = normalizedWeights[i];
            _require(normalizedWeight >= _MIN_WEIGHT, Errors.MIN_WEIGHT);

            normalizedSum = normalizedSum.add(normalizedWeight);
            if (normalizedWeight > maxNormalizedWeight) {
                maxWeightTokenIndex = i;
                maxNormalizedWeight = normalizedWeight;
            }
        }
       
        _require(normalizedSum == FixedPoint.ONE, Errors.NORMALIZED_WEIGHT_INVARIANT);

        _maxWeightTokenIndex = maxWeightTokenIndex;
        _normalizedWeight0 = normalizedWeights.length > 0 ? normalizedWeights[0] : 0;
        _normalizedWeight1 = normalizedWeights.length > 1 ? normalizedWeights[1] : 0;
        _normalizedWeight2 = normalizedWeights.length > 2 ? normalizedWeights[2] : 0;
        _normalizedWeight3 = normalizedWeights.length > 3 ? normalizedWeights[3] : 0;
        _normalizedWeight4 = normalizedWeights.length > 4 ? normalizedWeights[4] : 0;
        _normalizedWeight5 = normalizedWeights.length > 5 ? normalizedWeights[5] : 0;
        _normalizedWeight6 = normalizedWeights.length > 6 ? normalizedWeights[6] : 0;
        _normalizedWeight7 = normalizedWeights.length > 7 ? normalizedWeights[7] : 0;
    }

    function _normalizedWeight(IERC20 token) internal view virtual returns (uint256) {
       
        if (token == _token0) { return _normalizedWeight0; }
        else if (token == _token1) { return _normalizedWeight1; }
        else if (token == _token2) { return _normalizedWeight2; }
        else if (token == _token3) { return _normalizedWeight3; }
        else if (token == _token4) { return _normalizedWeight4; }
        else if (token == _token5) { return _normalizedWeight5; }
        else if (token == _token6) { return _normalizedWeight6; }
        else if (token == _token7) { return _normalizedWeight7; }
        else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    function _normalizedWeights() internal view virtual returns (uint256[] memory) {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory normalizedWeights = new uint256[](totalTokens);

       
        {
            if (totalTokens > 0) { normalizedWeights[0] = _normalizedWeight0; } else { return normalizedWeights; }
            if (totalTokens > 1) { normalizedWeights[1] = _normalizedWeight1; } else { return normalizedWeights; }
            if (totalTokens > 2) { normalizedWeights[2] = _normalizedWeight2; } else { return normalizedWeights; }
            if (totalTokens > 3) { normalizedWeights[3] = _normalizedWeight3; } else { return normalizedWeights; }
            if (totalTokens > 4) { normalizedWeights[4] = _normalizedWeight4; } else { return normalizedWeights; }
            if (totalTokens > 5) { normalizedWeights[5] = _normalizedWeight5; } else { return normalizedWeights; }
            if (totalTokens > 6) { normalizedWeights[6] = _normalizedWeight6; } else { return normalizedWeights; }
            if (totalTokens > 7) { normalizedWeights[7] = _normalizedWeight7; } else { return normalizedWeights; }
        }

        return normalizedWeights;
    }

    function getLastInvariant() external view returns (uint256) {
        return _lastInvariant;
    }

    
    function getInvariant() public view returns (uint256) {
        (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());

       
       
        _upscaleArray(balances, _scalingFactors());

        uint256[] memory normalizedWeights = _normalizedWeights();
        return WeightedMath._calculateInvariant(normalizedWeights, balances);
    }

    function getNormalizedWeights() external view returns (uint256[] memory) {
        return _normalizedWeights();
    }

   

   

    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) internal view virtual override whenNotPaused returns (uint256) {
       

        return
            WeightedMath._calcOutGivenIn(
                currentBalanceTokenIn,
                _normalizedWeight(swapRequest.tokenIn),
                currentBalanceTokenOut,
                _normalizedWeight(swapRequest.tokenOut),
                swapRequest.amount
            );
    }

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) internal view virtual override whenNotPaused returns (uint256) {
       

        return
            WeightedMath._calcInGivenOut(
                currentBalanceTokenIn,
                _normalizedWeight(swapRequest.tokenIn),
                currentBalanceTokenOut,
                _normalizedWeight(swapRequest.tokenOut),
                swapRequest.amount
            );
    }

   

    function _onInitializePool(
        bytes32,
        address,
        address,
        bytes memory userData
    ) internal virtual override whenNotPaused returns (uint256, uint256[] memory) {
       
       

        WeightedPool.JoinKind kind = userData.joinKind();
        _require(kind == WeightedPool.JoinKind.INIT, Errors.UNINITIALIZED);

        uint256[] memory amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(_getTotalTokens(), amountsIn.length);
        _upscaleArray(amountsIn, _scalingFactors());

        uint256[] memory normalizedWeights = _normalizedWeights();

        uint256 invariantAfterJoin = WeightedMath._calculateInvariant(normalizedWeights, amountsIn);

       
       
        uint256 bptAmountOut = Math.mul(invariantAfterJoin, _getTotalTokens());

        _lastInvariant = invariantAfterJoin;

        return (bptAmountOut, amountsIn);
    }

   

    function _onJoinPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        virtual
        override
        whenNotPaused
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
       

        uint256[] memory normalizedWeights = _normalizedWeights();

       
       
       
        uint256 invariantBeforeJoin = WeightedMath._calculateInvariant(normalizedWeights, balances);

        uint256[] memory dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(
            balances,
            normalizedWeights,
            _lastInvariant,
            invariantBeforeJoin,
            protocolSwapFeePercentage
        );

       
        _mutateAmounts(balances, dueProtocolFeeAmounts, FixedPoint.sub);
        (uint256 bptAmountOut, uint256[] memory amountsIn) = _doJoin(balances, normalizedWeights, userData);

       
       
        _lastInvariant = _invariantAfterJoin(balances, amountsIn, normalizedWeights);

        return (bptAmountOut, amountsIn, dueProtocolFeeAmounts);
    }

    function _doJoin(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        bytes memory userData
    ) private view returns (uint256, uint256[] memory) {
        JoinKind kind = userData.joinKind();

        if (kind == JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return _joinExactTokensInForBPTOut(balances, normalizedWeights, userData);
        } else if (kind == JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT) {
            return _joinTokenInForExactBPTOut(balances, normalizedWeights, userData);
        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    function _joinExactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        bytes memory userData
    ) private view returns (uint256, uint256[] memory) {
        (uint256[] memory amountsIn, uint256 minBPTAmountOut) = userData.exactTokensInForBptOut();
        InputHelpers.ensureInputLengthMatch(_getTotalTokens(), amountsIn.length);

        _upscaleArray(amountsIn, _scalingFactors());

        uint256 bptAmountOut = WeightedMath._calcBptOutGivenExactTokensIn(
            balances,
            normalizedWeights,
            amountsIn,
            totalSupply(),
            _swapFeePercentage
        );

        _require(bptAmountOut >= minBPTAmountOut, Errors.BPT_OUT_MIN_AMOUNT);

        return (bptAmountOut, amountsIn);
    }

    function _joinTokenInForExactBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        bytes memory userData
    ) private view returns (uint256, uint256[] memory) {
        (uint256 bptAmountOut, uint256 tokenIndex) = userData.tokenInForExactBptOut();
       

        _require(tokenIndex < _getTotalTokens(), Errors.OUT_OF_BOUNDS);

        uint256[] memory amountsIn = new uint256[](_getTotalTokens());
        amountsIn[tokenIndex] = WeightedMath._calcTokenInGivenExactBptOut(
            balances[tokenIndex],
            normalizedWeights[tokenIndex],
            bptAmountOut,
            totalSupply(),
            _swapFeePercentage
        );

        return (bptAmountOut, amountsIn);
    }

   

    function _onExitPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        virtual
        override
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
       
       

        uint256[] memory normalizedWeights = _normalizedWeights();

        if (_isNotPaused()) {
           
           
           
            uint256 invariantBeforeExit = WeightedMath._calculateInvariant(normalizedWeights, balances);
            dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(
                balances,
                normalizedWeights,
                _lastInvariant,
                invariantBeforeExit,
                protocolSwapFeePercentage
            );

           
            _mutateAmounts(balances, dueProtocolFeeAmounts, FixedPoint.sub);
        } else {
           
           
            dueProtocolFeeAmounts = new uint256[](_getTotalTokens());
        }

        (bptAmountIn, amountsOut) = _doExit(balances, normalizedWeights, userData);

       
       
        _lastInvariant = _invariantAfterExit(balances, amountsOut, normalizedWeights);

        return (bptAmountIn, amountsOut, dueProtocolFeeAmounts);
    }

    function _doExit(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        bytes memory userData
    ) private view returns (uint256, uint256[] memory) {
        ExitKind kind = userData.exitKind();

        if (kind == ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT) {
            return _exitExactBPTInForTokenOut(balances, normalizedWeights, userData);
        } else if (kind == ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            return _exitExactBPTInForTokensOut(balances, userData);
        } else {
           
            return _exitBPTInForExactTokensOut(balances, normalizedWeights, userData);
        }
    }

    function _exitExactBPTInForTokenOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        bytes memory userData
    ) private view whenNotPaused returns (uint256, uint256[] memory) {
       

        (uint256 bptAmountIn, uint256 tokenIndex) = userData.exactBptInForTokenOut();
       

        _require(tokenIndex < _getTotalTokens(), Errors.OUT_OF_BOUNDS);

       
        uint256[] memory amountsOut = new uint256[](_getTotalTokens());

       
        amountsOut[tokenIndex] = WeightedMath._calcTokenOutGivenExactBptIn(
            balances[tokenIndex],
            normalizedWeights[tokenIndex],
            bptAmountIn,
            totalSupply(),
            _swapFeePercentage
        );

        return (bptAmountIn, amountsOut);
    }

    function _exitExactBPTInForTokensOut(uint256[] memory balances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
       
       
       
       

        uint256 bptAmountIn = userData.exactBptInForTokensOut();
       

        uint256[] memory amountsOut = WeightedMath._calcTokensOutGivenExactBptIn(balances, bptAmountIn, totalSupply());
        return (bptAmountIn, amountsOut);
    }

    function _exitBPTInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        bytes memory userData
    ) private view whenNotPaused returns (uint256, uint256[] memory) {
       

        (uint256[] memory amountsOut, uint256 maxBPTAmountIn) = userData.bptInForExactTokensOut();
        InputHelpers.ensureInputLengthMatch(amountsOut.length, _getTotalTokens());
        _upscaleArray(amountsOut, _scalingFactors());

        uint256 bptAmountIn = WeightedMath._calcBptInGivenExactTokensOut(
            balances,
            normalizedWeights,
            amountsOut,
            totalSupply(),
            _swapFeePercentage
        );
        _require(bptAmountIn <= maxBPTAmountIn, Errors.BPT_IN_MAX_AMOUNT);

        return (bptAmountIn, amountsOut);
    }

   

    function _getDueProtocolFeeAmounts(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 previousInvariant,
        uint256 currentInvariant,
        uint256 protocolSwapFeePercentage
    ) private view returns (uint256[] memory) {
       
        uint256[] memory dueProtocolFeeAmounts = new uint256[](_getTotalTokens());

       
        if (protocolSwapFeePercentage == 0) {
            return dueProtocolFeeAmounts;
        }

       
       
        dueProtocolFeeAmounts[_maxWeightTokenIndex] = WeightedMath._calcDueTokenProtocolSwapFeeAmount(
            balances[_maxWeightTokenIndex],
            normalizedWeights[_maxWeightTokenIndex],
            previousInvariant,
            currentInvariant,
            protocolSwapFeePercentage
        );

        return dueProtocolFeeAmounts;
    }

    
    function _invariantAfterJoin(
        uint256[] memory balances,
        uint256[] memory amountsIn,
        uint256[] memory normalizedWeights
    ) private view returns (uint256) {
        _mutateAmounts(balances, amountsIn, FixedPoint.add);
        return WeightedMath._calculateInvariant(normalizedWeights, balances);
    }

    function _invariantAfterExit(
        uint256[] memory balances,
        uint256[] memory amountsOut,
        uint256[] memory normalizedWeights
    ) private view returns (uint256) {
        _mutateAmounts(balances, amountsOut, FixedPoint.sub);
        return WeightedMath._calculateInvariant(normalizedWeights, balances);
    }

    
    function _mutateAmounts(
        uint256[] memory toMutate,
        uint256[] memory arguments,
        function(uint256, uint256) pure returns (uint256) mutation
    ) private view {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            toMutate[i] = mutation(toMutate[i], arguments[i]);
        }
    }

    
    function getRate() public view returns (uint256) {
       
        return Math.mul(getInvariant(), _getTotalTokens()).divDown(totalSupply());
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BasePool.sol";
import "../vault/interfaces/IMinimalSwapInfoPool.sol";

abstract contract BaseMinimalSwapInfoPool is IMinimalSwapInfoPool, BasePool {
    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BasePool(
            vault,
            tokens.length == 2 ? IVault.PoolSpecialization.TWO_TOKEN : IVault.PoolSpecialization.MINIMAL_SWAP_INFO,
            name,
            symbol,
            tokens,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
       
    }

   

    function onSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) external view virtual override returns (uint256) {
        uint256 scalingFactorTokenIn = _scalingFactor(request.tokenIn);
        uint256 scalingFactorTokenOut = _scalingFactor(request.tokenOut);

        if (request.kind == IVault.SwapKind.GIVEN_IN) {
           
            request.amount = _subtractSwapFeeAmount(request.amount);

           
            balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
            balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);
            request.amount = _upscale(request.amount, scalingFactorTokenIn);

            uint256 amountOut = _onSwapGivenIn(request, balanceTokenIn, balanceTokenOut);

           
            return _downscaleDown(amountOut, scalingFactorTokenOut);
        } else {
           
            balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
            balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);
            request.amount = _upscale(request.amount, scalingFactorTokenOut);

            uint256 amountIn = _onSwapGivenOut(request, balanceTokenIn, balanceTokenOut);

           
            amountIn = _downscaleUp(amountIn, scalingFactorTokenIn);

           
            return _addSwapFeeAmount(amountIn);
        }
    }

    
    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal view virtual returns (uint256);

    
    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal view virtual returns (uint256);
}

pragma solidity ^0.7.0;

import "../../lib/math/FixedPoint.sol";
import "../../lib/math/Math.sol";
import "../../lib/helpers/InputHelpers.sol";

contract WeightedMath {
    using FixedPoint for uint256;
   
   
    uint256 internal constant _MIN_WEIGHT = 0.01e18;
   
   
    uint256 internal constant _MAX_WEIGHTED_TOKENS = 100;

   
   

   
    uint256 internal constant _MAX_IN_RATIO = 0.3e18;
    uint256 internal constant _MAX_OUT_RATIO = 0.3e18;

   
    uint256 internal constant _MAX_INVARIANT_RATIO = 3e18;
   
    uint256 internal constant _MIN_INVARIANT_RATIO = 0.7e18;

   
   
   
    function _calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
        internal
        pure
        returns (uint256 invariant)
    {
        

        invariant = FixedPoint.ONE;
        for (uint256 i = 0; i < normalizedWeights.length; i++) {
            invariant = invariant.mulDown(balances[i].powDown(normalizedWeights[i]));
        }

        _require(invariant > 0, Errors.ZERO_INVARIANT);
    }

   
   
    function _calcOutGivenIn(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    ) internal pure returns (uint256) {
        

       

       
       

       
        _require(amountIn <= balanceIn.mulDown(_MAX_IN_RATIO), Errors.MAX_IN_RATIO);

        uint256 denominator = balanceIn.add(amountIn);
        uint256 base = balanceIn.divUp(denominator);
        uint256 exponent = weightIn.divDown(weightOut);
        uint256 power = base.powUp(exponent);

        return balanceOut.mulDown(power.complement());
    }

   
   
    function _calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut
    ) internal pure returns (uint256) {
        

       

       
       

       
        _require(amountOut <= balanceOut.mulDown(_MAX_OUT_RATIO), Errors.MAX_OUT_RATIO);

        uint256 base = balanceOut.divUp(balanceOut.sub(amountOut));
        uint256 exponent = weightOut.divUp(weightIn);
        uint256 power = base.powUp(exponent);

       
       
        uint256 ratio = power.sub(FixedPoint.ONE);

        return balanceIn.mulUp(ratio);
    }

    function _calcBptOutGivenExactTokensIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) internal pure returns (uint256) {
       

        uint256[] memory balanceRatiosWithFee = new uint256[](amountsIn.length);

        uint256 invariantRatioWithFees = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            balanceRatiosWithFee[i] = balances[i].add(amountsIn[i]).divDown(balances[i]);
            invariantRatioWithFees = invariantRatioWithFees.add(balanceRatiosWithFee[i].mulDown(normalizedWeights[i]));
        }

        uint256 invariantRatio = FixedPoint.ONE;
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 amountInWithoutFee;

            if (balanceRatiosWithFee[i] > invariantRatioWithFees) {
                uint256 nonTaxableAmount = balances[i].mulDown(invariantRatioWithFees.sub(FixedPoint.ONE));
                uint256 taxableAmount = amountsIn[i].sub(nonTaxableAmount);
                amountInWithoutFee = nonTaxableAmount.add(taxableAmount.mulDown(FixedPoint.ONE.sub(swapFee)));
            } else {
                amountInWithoutFee = amountsIn[i];
            }

            uint256 balanceRatio = balances[i].add(amountInWithoutFee).divDown(balances[i]);

            invariantRatio = invariantRatio.mulDown(balanceRatio.powDown(normalizedWeights[i]));
        }

        if (invariantRatio >= FixedPoint.ONE) {
            return bptTotalSupply.mulDown(invariantRatio.sub(FixedPoint.ONE));
        } else {
            return 0;
        }
    }

    function _calcTokenInGivenExactBptOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) internal pure returns (uint256) {
        

       

       
        uint256 invariantRatio = bptTotalSupply.add(bptAmountOut).divUp(bptTotalSupply);
        _require(invariantRatio <= _MAX_INVARIANT_RATIO, Errors.MAX_OUT_BPT_FOR_TOKEN_IN);

       
        uint256 balanceRatio = invariantRatio.powUp(FixedPoint.ONE.divUp(normalizedWeight));

        uint256 amountInWithoutFee = balance.mulUp(balanceRatio.sub(FixedPoint.ONE));

       
       
        uint256 taxablePercentage = normalizedWeight.complement();
        uint256 taxableAmount = amountInWithoutFee.mulUp(taxablePercentage);
        uint256 nonTaxableAmount = amountInWithoutFee.sub(taxableAmount);

        return nonTaxableAmount.add(taxableAmount.divUp(swapFee.complement()));
    }

    function _calcBptInGivenExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) internal pure returns (uint256) {
       

        uint256[] memory balanceRatiosWithoutFee = new uint256[](amountsOut.length);
        uint256 invariantRatioWithoutFees = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            balanceRatiosWithoutFee[i] = balances[i].sub(amountsOut[i]).divUp(balances[i]);
            invariantRatioWithoutFees = invariantRatioWithoutFees.add(
                balanceRatiosWithoutFee[i].mulUp(normalizedWeights[i])
            );
        }

        uint256 invariantRatio = FixedPoint.ONE;
        for (uint256 i = 0; i < balances.length; i++) {
           
           
           

            uint256 amountOutWithFee;
            if (invariantRatioWithoutFees > balanceRatiosWithoutFee[i]) {
                uint256 nonTaxableAmount = balances[i].mulDown(invariantRatioWithoutFees.complement());
                uint256 taxableAmount = amountsOut[i].sub(nonTaxableAmount);

                amountOutWithFee = nonTaxableAmount.add(taxableAmount.divUp(swapFee.complement()));
            } else {
                amountOutWithFee = amountsOut[i];
            }

            uint256 balanceRatio = balances[i].sub(amountOutWithFee).divDown(balances[i]);

            invariantRatio = invariantRatio.mulDown(balanceRatio.powDown(normalizedWeights[i]));
        }

        return bptTotalSupply.mulUp(invariantRatio.complement());
    }

    function _calcTokenOutGivenExactBptIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) internal pure returns (uint256) {
        

       
       

       
        uint256 invariantRatio = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply);
        _require(invariantRatio >= _MIN_INVARIANT_RATIO, Errors.MIN_BPT_IN_FOR_TOKEN_OUT);

       
        uint256 balanceRatio = invariantRatio.powUp(FixedPoint.ONE.divDown(normalizedWeight));

       
        uint256 amountOutWithoutFee = balance.mulDown(balanceRatio.complement());

       
       
        uint256 taxablePercentage = normalizedWeight.complement();

       
       
        uint256 taxableAmount = amountOutWithoutFee.mulUp(taxablePercentage);
        uint256 nonTaxableAmount = amountOutWithoutFee.sub(taxableAmount);

        return nonTaxableAmount.add(taxableAmount.mulDown(swapFee.complement()));
    }

    function _calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) internal pure returns (uint256[] memory) {
        

       
       

        uint256 bptRatio = bptAmountIn.divDown(totalBPT);

        uint256[] memory amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsOut[i] = balances[i].mulDown(bptRatio);
        }

        return amountsOut;
    }

    function _calcDueTokenProtocolSwapFeeAmount(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 previousInvariant,
        uint256 currentInvariant,
        uint256 protocolSwapFeePercentage
    ) internal pure returns (uint256) {
        

        if (currentInvariant <= previousInvariant) {
           
           
            return 0;
        }

       
       

       
       

        uint256 base = previousInvariant.divUp(currentInvariant);
        uint256 exponent = FixedPoint.ONE.divDown(normalizedWeight);

       
       
       
        base = Math.max(base, FixedPoint.MIN_POW_BASE_FREE_EXPONENT);

        uint256 power = base.powUp(exponent);

        uint256 tokenAccruedFees = balance.mulDown(power.complement());
        return tokenAccruedFees.mulDown(protocolSwapFeePercentage);
    }
}

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/IERC20.sol";

import "./WeightedPool.sol";

library WeightedPoolUserDataHelpers {
    function joinKind(bytes memory self) internal pure returns (WeightedPool.JoinKind) {
        return abi.decode(self, (WeightedPool.JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (WeightedPool.ExitKind) {
        return abi.decode(self, (WeightedPool.ExitKind));
    }

   

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (WeightedPool.JoinKind, uint256[]));
    }

    function exactTokensInForBptOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsIn, uint256 minBPTAmountOut)
    {
        (, amountsIn, minBPTAmountOut) = abi.decode(self, (WeightedPool.JoinKind, uint256[], uint256));
    }

    function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
        (, bptAmountOut, tokenIndex) = abi.decode(self, (WeightedPool.JoinKind, uint256, uint256));
    }

   

    function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
        (, bptAmountIn, tokenIndex) = abi.decode(self, (WeightedPool.ExitKind, uint256, uint256));
    }

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (WeightedPool.ExitKind, uint256));
    }

    function bptInForExactTokensOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
    {
        (, amountsOut, maxBPTAmountIn) = abi.decode(self, (WeightedPool.ExitKind, uint256[], uint256));
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/FixedPoint.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/helpers/TemporarilyPausable.sol";
import "../lib/openzeppelin/ERC20.sol";

import "./BalancerPoolToken.sol";
import "./BasePoolAuthorization.sol";
import "../vault/interfaces/IVault.sol";
import "../vault/interfaces/IBasePool.sol";

abstract contract BasePool is IBasePool, BasePoolAuthorization, BalancerPoolToken, TemporarilyPausable {
    using FixedPoint for uint256;

    uint256 private constant _MIN_TOKENS = 2;
    uint256 private constant _MAX_TOKENS = 8;

   
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12;
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 1e17;

    uint256 private constant _MINIMUM_BPT = 1e6;

    uint256 internal _swapFeePercentage;

    IVault private immutable _vault;
    bytes32 private immutable _poolId;
    uint256 private immutable _totalTokens;

    IERC20 internal immutable _token0;
    IERC20 internal immutable _token1;
    IERC20 internal immutable _token2;
    IERC20 internal immutable _token3;
    IERC20 internal immutable _token4;
    IERC20 internal immutable _token5;
    IERC20 internal immutable _token6;
    IERC20 internal immutable _token7;

   
   
   

    uint256 internal immutable _scalingFactor0;
    uint256 internal immutable _scalingFactor1;
    uint256 internal immutable _scalingFactor2;
    uint256 internal immutable _scalingFactor3;
    uint256 internal immutable _scalingFactor4;
    uint256 internal immutable _scalingFactor5;
    uint256 internal immutable _scalingFactor6;
    uint256 internal immutable _scalingFactor7;

    event SwapFeePercentageChanged(uint256 swapFeePercentage);

    constructor(
        IVault vault,
        IVault.PoolSpecialization specialization,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
       
       
       
       
       
        Authentication(bytes32(uint256(msg.sender)))
        BalancerPoolToken(name, symbol)
        BasePoolAuthorization(owner)
        TemporarilyPausable(pauseWindowDuration, bufferPeriodDuration)
    {
        _require(tokens.length >= _MIN_TOKENS, Errors.MIN_TOKENS);
        _require(tokens.length <= _MAX_TOKENS, Errors.MAX_TOKENS);

       
       
       
       
       
        InputHelpers.ensureArrayIsSorted(tokens);

        _setSwapFeePercentage(swapFeePercentage);

        bytes32 poolId = vault.registerPool(specialization);

       
        vault.registerTokens(poolId, tokens, new address[](tokens.length));

       
        _vault = vault;
        _poolId = poolId;
        _totalTokens = tokens.length;

       
        _token0 = tokens.length > 0 ? tokens[0] : IERC20(0);
        _token1 = tokens.length > 1 ? tokens[1] : IERC20(0);
        _token2 = tokens.length > 2 ? tokens[2] : IERC20(0);
        _token3 = tokens.length > 3 ? tokens[3] : IERC20(0);
        _token4 = tokens.length > 4 ? tokens[4] : IERC20(0);
        _token5 = tokens.length > 5 ? tokens[5] : IERC20(0);
        _token6 = tokens.length > 6 ? tokens[6] : IERC20(0);
        _token7 = tokens.length > 7 ? tokens[7] : IERC20(0);

        _scalingFactor0 = tokens.length > 0 ? _computeScalingFactor(tokens[0]) : 0;
        _scalingFactor1 = tokens.length > 1 ? _computeScalingFactor(tokens[1]) : 0;
        _scalingFactor2 = tokens.length > 2 ? _computeScalingFactor(tokens[2]) : 0;
        _scalingFactor3 = tokens.length > 3 ? _computeScalingFactor(tokens[3]) : 0;
        _scalingFactor4 = tokens.length > 4 ? _computeScalingFactor(tokens[4]) : 0;
        _scalingFactor5 = tokens.length > 5 ? _computeScalingFactor(tokens[5]) : 0;
        _scalingFactor6 = tokens.length > 6 ? _computeScalingFactor(tokens[6]) : 0;
        _scalingFactor7 = tokens.length > 7 ? _computeScalingFactor(tokens[7]) : 0;
    }

   

    function getVault() public view returns (IVault) {
        return _vault;
    }

    function getPoolId() public view returns (bytes32) {
        return _poolId;
    }

    function _getTotalTokens() internal view returns (uint256) {
        return _totalTokens;
    }

    function getSwapFeePercentage() external view returns (uint256) {
        return _swapFeePercentage;
    }

   
    function setSwapFeePercentage(uint256 swapFeePercentage) external virtual authenticate whenNotPaused {
        _setSwapFeePercentage(swapFeePercentage);
    }

    function _setSwapFeePercentage(uint256 swapFeePercentage) private {
        _require(swapFeePercentage >= _MIN_SWAP_FEE_PERCENTAGE, Errors.MIN_SWAP_FEE_PERCENTAGE);
        _require(swapFeePercentage <= _MAX_SWAP_FEE_PERCENTAGE, Errors.MAX_SWAP_FEE_PERCENTAGE);

        _swapFeePercentage = swapFeePercentage;
        emit SwapFeePercentageChanged(swapFeePercentage);
    }

   
    function setPaused(bool paused) external authenticate {
        _setPaused(paused);
    }

   

    modifier onlyVault(bytes32 poolId) {
        _require(msg.sender == address(getVault()), Errors.CALLER_NOT_VAULT);
        _require(poolId == getPoolId(), Errors.INVALID_POOL_ID);
        _;
    }

    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external virtual override onlyVault(poolId) returns (uint256[] memory, uint256[] memory) {
        uint256[] memory scalingFactors = _scalingFactors();

        if (totalSupply() == 0) {
            (uint256 bptAmountOut, uint256[] memory amountsIn) = _onInitializePool(poolId, sender, recipient, userData);

           
           
           
            _require(bptAmountOut >= _MINIMUM_BPT, Errors.MINIMUM_BPT);
            _mintPoolTokens(address(0), _MINIMUM_BPT);
            _mintPoolTokens(recipient, bptAmountOut - _MINIMUM_BPT);

           
            _downscaleUpArray(amountsIn, scalingFactors);

            return (amountsIn, new uint256[](_getTotalTokens()));
        } else {
            _upscaleArray(balances, scalingFactors);
            (uint256 bptAmountOut, uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts) = _onJoinPool(
                poolId,
                sender,
                recipient,
                balances,
                lastChangeBlock,
                protocolSwapFeePercentage,
                userData
            );

           

            _mintPoolTokens(recipient, bptAmountOut);

           
            _downscaleUpArray(amountsIn, scalingFactors);
           
            _downscaleDownArray(dueProtocolFeeAmounts, scalingFactors);

            return (amountsIn, dueProtocolFeeAmounts);
        }
    }

    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external virtual override onlyVault(poolId) returns (uint256[] memory, uint256[] memory) {
        uint256[] memory scalingFactors = _scalingFactors();
        _upscaleArray(balances, scalingFactors);

        (uint256 bptAmountIn, uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts) = _onExitPool(
            poolId,
            sender,
            recipient,
            balances,
            lastChangeBlock,
            protocolSwapFeePercentage,
            userData
        );

       

        _burnPoolTokens(sender, bptAmountIn);

       
        _downscaleDownArray(amountsOut, scalingFactors);
        _downscaleDownArray(dueProtocolFeeAmounts, scalingFactors);

        return (amountsOut, dueProtocolFeeAmounts);
    }

   

    
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        InputHelpers.ensureInputLengthMatch(balances.length, _getTotalTokens());

        _queryAction(
            poolId,
            sender,
            recipient,
            balances,
            lastChangeBlock,
            protocolSwapFeePercentage,
            userData,
            _onJoinPool,
            _downscaleUpArray
        );

       
       
        return (bptOut, amountsIn);
    }

    
    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        InputHelpers.ensureInputLengthMatch(balances.length, _getTotalTokens());

        _queryAction(
            poolId,
            sender,
            recipient,
            balances,
            lastChangeBlock,
            protocolSwapFeePercentage,
            userData,
            _onExitPool,
            _downscaleDownArray
        );

       
       
        return (bptIn, amountsOut);
    }

   
   

    
    function _onInitializePool(
        bytes32 poolId,
        address sender,
        address recipient,
        bytes memory userData
    ) internal virtual returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    
    function _onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        virtual
        returns (
            uint256 bptAmountOut,
            uint256[] memory amountsIn,
            uint256[] memory dueProtocolFeeAmounts
        );

    
    function _onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        virtual
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        );

   

    
    function _addSwapFeeAmount(uint256 amount) internal view returns (uint256) {
       
        return amount.divUp(_swapFeePercentage.complement());
    }

    
    function _subtractSwapFeeAmount(uint256 amount) internal view returns (uint256) {
       
        uint256 feeAmount = amount.mulUp(_swapFeePercentage);
        return amount.sub(feeAmount);
    }

   

    
    function _computeScalingFactor(IERC20 token) private view returns (uint256) {
       
        uint256 tokenDecimals = ERC20(address(token)).decimals();

       
        uint256 decimalsDifference = Math.sub(18, tokenDecimals);
        return 10**decimalsDifference;
    }

    
    function _scalingFactor(IERC20 token) internal view returns (uint256) {
       
        if (token == _token0) { return _scalingFactor0; }
        else if (token == _token1) { return _scalingFactor1; }
        else if (token == _token2) { return _scalingFactor2; }
        else if (token == _token3) { return _scalingFactor3; }
        else if (token == _token4) { return _scalingFactor4; }
        else if (token == _token5) { return _scalingFactor5; }
        else if (token == _token6) { return _scalingFactor6; }
        else if (token == _token7) { return _scalingFactor7; }
        else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    
    function _scalingFactors() internal view returns (uint256[] memory) {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory scalingFactors = new uint256[](totalTokens);

       
        {
            if (totalTokens > 0) { scalingFactors[0] = _scalingFactor0; } else { return scalingFactors; }
            if (totalTokens > 1) { scalingFactors[1] = _scalingFactor1; } else { return scalingFactors; }
            if (totalTokens > 2) { scalingFactors[2] = _scalingFactor2; } else { return scalingFactors; }
            if (totalTokens > 3) { scalingFactors[3] = _scalingFactor3; } else { return scalingFactors; }
            if (totalTokens > 4) { scalingFactors[4] = _scalingFactor4; } else { return scalingFactors; }
            if (totalTokens > 5) { scalingFactors[5] = _scalingFactor5; } else { return scalingFactors; }
            if (totalTokens > 6) { scalingFactors[6] = _scalingFactor6; } else { return scalingFactors; }
            if (totalTokens > 7) { scalingFactors[7] = _scalingFactor7; } else { return scalingFactors; }
        }

        return scalingFactors;
    }

    
    function _upscale(uint256 amount, uint256 scalingFactor) internal pure returns (uint256) {
        return Math.mul(amount, scalingFactor);
    }

    
    function _upscaleArray(uint256[] memory amounts, uint256[] memory scalingFactors) internal view {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            amounts[i] = Math.mul(amounts[i], scalingFactors[i]);
        }
    }

    
    function _downscaleDown(uint256 amount, uint256 scalingFactor) internal pure returns (uint256) {
        return Math.divDown(amount, scalingFactor);
    }

    
    function _downscaleDownArray(uint256[] memory amounts, uint256[] memory scalingFactors) internal view {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            amounts[i] = Math.divDown(amounts[i], scalingFactors[i]);
        }
    }

    
    function _downscaleUp(uint256 amount, uint256 scalingFactor) internal pure returns (uint256) {
        return Math.divUp(amount, scalingFactor);
    }

    
    function _downscaleUpArray(uint256[] memory amounts, uint256[] memory scalingFactors) internal view {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            amounts[i] = Math.divUp(amounts[i], scalingFactors[i]);
        }
    }

    function _getAuthorizer() internal view override returns (IAuthorizer) {
       
       
       
       
        return getVault().getAuthorizer();
    }

    function _queryAction(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData,
        function(bytes32, address, address, uint256[] memory, uint256, uint256, bytes memory)
            internal
            returns (uint256, uint256[] memory, uint256[] memory) _action,
        function(uint256[] memory, uint256[] memory) internal view _downscaleArray
    ) private {
       
       

        if (msg.sender != address(this)) {
           
           

           
            (bool success, ) = address(this).call(msg.data);

           
            assembly {
               
                switch success
                    case 0 {
                       
                       

                       
                       
                        returndatacopy(0, 0, 0x04)
                        let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                       
                        if eq(eq(error, 0x43adbafb00000000000000000000000000000000000000000000000000000000), 0) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                       
                       
                       
                       
                       
                       
                       
                       
                       
                       
                       
                       
                       
                       

                       
                       
                        returndatacopy(0, 0x04, 32)

                       
                       
                        mstore(0x20, 64)

                       
                       
                       
                        returndatacopy(0x40, 0x24, sub(returndatasize(), 36))

                       
                       
                       
                        return(0, add(returndatasize(), 28))
                    }
                    default {
                       
                        invalid()
                    }
            }
        } else {
            uint256[] memory scalingFactors = _scalingFactors();
            _upscaleArray(balances, scalingFactors);

            (uint256 bptAmount, uint256[] memory tokenAmounts, ) = _action(
                poolId,
                sender,
                recipient,
                balances,
                lastChangeBlock,
                protocolSwapFeePercentage,
                userData
            );

            _downscaleArray(tokenAmounts, scalingFactors);

           
            assembly {
               
               
               
                let size := mul(mload(tokenAmounts), 32)

               
               
               
                let start := sub(tokenAmounts, 0x20)
                mstore(start, bptAmount)

               
               
                mstore(sub(start, 0x20), 0x0000000000000000000000000000000000000000000000000000000043adbafb)
                start := sub(start, 0x04)

               
               
                revert(start, add(size, 68))
            }
        }
    }
}

pragma solidity ^0.7.0;

import "../lib/math/Math.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/IERC20Permit.sol";
import "../lib/openzeppelin/EIP712.sol";

contract BalancerPoolToken is IERC20, IERC20Permit, EIP712 {
    using Math for uint256;

   

    uint8 private constant _DECIMALS = 18;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _nonces;

   
    bytes32 private immutable _PERMIT_TYPE_HASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

   

    constructor(string memory tokenName, string memory tokenSymbol) EIP712(tokenName, "1") {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

   

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balance[account];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _setAllowance(msg.sender, spender, amount);

        return true;
    }

    function increaseApproval(address spender, uint256 amount) external returns (bool) {
        _setAllowance(msg.sender, spender, _allowance[msg.sender][spender].add(amount));

        return true;
    }

    function decreaseApproval(address spender, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowance[msg.sender][spender];

        if (amount >= currentAllowance) {
            _setAllowance(msg.sender, spender, 0);
        } else {
            _setAllowance(msg.sender, spender, currentAllowance.sub(amount));
        }

        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _move(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowance[sender][msg.sender];
        _require(msg.sender == sender || currentAllowance >= amount, Errors.INSUFFICIENT_ALLOWANCE);

        _move(sender, recipient, amount);

        if (msg.sender != sender && currentAllowance != uint256(-1)) {
           
            _setAllowance(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
       
        _require(block.timestamp <= deadline, Errors.EXPIRED_PERMIT);

        uint256 nonce = _nonces[owner];

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPE_HASH, owner, spender, value, nonce, deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ecrecover(hash, v, r, s);
        _require((signer != address(0)) && (signer == owner), Errors.INVALID_SIGNATURE);

        _nonces[owner] = nonce + 1;
        _setAllowance(owner, spender, value);
    }

   

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }

   
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

   

    function _mintPoolTokens(address recipient, uint256 amount) internal {
        _balance[recipient] = _balance[recipient].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), recipient, amount);
    }

    function _burnPoolTokens(address sender, uint256 amount) internal {
        uint256 currentBalance = _balance[sender];
        _require(currentBalance >= amount, Errors.INSUFFICIENT_BALANCE);

        _balance[sender] = currentBalance - amount;
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(sender, address(0), amount);
    }

    function _move(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 currentBalance = _balance[sender];
        _require(currentBalance >= amount, Errors.INSUFFICIENT_BALANCE);
       
       
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _balance[sender] = currentBalance - amount;
        _balance[recipient] = _balance[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

   

    function _setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

pragma solidity ^0.7.0;

import "../lib/helpers/Authentication.sol";
import "../vault/interfaces/IAuthorizer.sol";

import "./BasePool.sol";

abstract contract BasePoolAuthorization is Authentication {
    address private immutable _owner;

    address private constant _DELEGATE_OWNER = 0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B;

    constructor(address owner) {
        _owner = owner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        if ((getOwner() != _DELEGATE_OWNER) && _isOwnerOnlyAction(actionId)) {
           
            return msg.sender == getOwner();
        } else {
           
            return _getAuthorizer().canPerform(actionId, account, address(this));
        }
    }

    function _isOwnerOnlyAction(bytes32 actionId) private view returns (bool) {
       
        return actionId == getActionId(BasePool.setSwapFeePercentage.selector);
    }

    function _getAuthorizer() internal view virtual returns (IAuthorizer);
}

pragma solidity ^0.7.0;

interface IERC20Permit {
    
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    
    function nonces(address owner) external view returns (uint256);

    
   
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity ^0.7.0;

import "./interfaces/IAuthorizer.sol";
import "../lib/openzeppelin/AccessControl.sol";
import "../lib/helpers/InputHelpers.sol";

contract Authorizer is AccessControl, IAuthorizer {
    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function canPerform(
        bytes32 actionId,
        address account,
        address
    ) public view override returns (bool) {
       
        return AccessControl.hasRole(actionId, account);
    }

    
    function grantRoles(bytes32[] memory roles, address account) external {
        for (uint256 i = 0; i < roles.length; i++) {
            grantRole(roles[i], account);
        }
    }

    
    function grantRolesToMany(bytes32[] memory roles, address[] memory accounts) external {
        InputHelpers.ensureInputLengthMatch(roles.length, accounts.length);
        for (uint256 i = 0; i < roles.length; i++) {
            grantRole(roles[i], accounts[i]);
        }
    }

    
    function revokeRoles(bytes32[] memory roles, address account) external {
        for (uint256 i = 0; i < roles.length; i++) {
            revokeRole(roles[i], account);
        }
    }

    
    function revokeRolesFromMany(bytes32[] memory roles, address[] memory accounts) external {
        InputHelpers.ensureInputLengthMatch(roles.length, accounts.length);
        for (uint256 i = 0; i < roles.length; i++) {
            revokeRole(roles[i], accounts[i]);
        }
    }
}

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/EnumerableMap.sol";
import "../../lib/openzeppelin/IERC20.sol";

contract EnumerableIERC20ToBytes32MapMock {
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    event OperationResult(bool result);

    EnumerableMap.IERC20ToBytes32Map private _map;

    function contains(IERC20 key) public view returns (bool) {
        return _map.contains(key);
    }

    function set(IERC20 key, bytes32 value) public {
        bool result = _map.set(key, value);
        emit OperationResult(result);
    }

    function unchecked_indexOf(IERC20 key) public view returns (uint256) {
        return _map.unchecked_indexOf(key);
    }

    function unchecked_setAt(uint256 index, bytes32 value) public {
        _map.unchecked_setAt(index, value);
    }

    function remove(IERC20 key) public {
        bool result = _map.remove(key);
        emit OperationResult(result);
    }

    function length() public view returns (uint256) {
        return _map.length();
    }

    function at(uint256 index) public view returns (IERC20 key, bytes32 value) {
        return _map.at(index);
    }

    function unchecked_at(uint256 index) public view returns (IERC20 key, bytes32 value) {
        return _map.unchecked_at(index);
    }

    function unchecked_valueAt(uint256 index) public view returns (bytes32 value) {
        return _map.unchecked_valueAt(index);
    }

    function get(IERC20 key, uint256 errorCode) public view returns (bytes32) {
        return _map.get(key, errorCode);
    }
}

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/ReentrancyGuard.sol";
import "./ReentrancyAttack.sol";

contract ReentrancyMock is ReentrancyGuard {
    uint256 public counter;

    constructor() {
        counter = 0;
    }

    function callback() external nonReentrant {
        _count();
    }

    function countLocalRecursive(uint256 n) public nonReentrant {
        if (n > 0) {
            _count();
            countLocalRecursive(n - 1);
        }
    }

    function countThisRecursive(uint256 n) public nonReentrant {
        if (n > 0) {
            _count();
           
            (bool success, ) = address(this).call(abi.encodeWithSignature("countThisRecursive(uint256)", n - 1));
            require(success, "REENTRANCY_MOCK");
        }
    }

    function countAndCall(ReentrancyAttack attacker) public nonReentrant {
        _count();
        bytes4 func = bytes4(keccak256("callback()"));
        attacker.callSender(func);
    }

    function _count() private {
        counter += 1;
    }
}

pragma solidity >=0.6.0 <0.8.0;

contract ReentrancyAttack {
    function callSender(bytes4 data) public {
       
        (bool success, ) = msg.sender.call(abi.encodeWithSelector(data));
        require(success, "REENTRANCY_ATTACK");
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../pools/BasePool.sol";

contract MockBasePool is BasePool {
    constructor(
        IVault vault,
        IVault.PoolSpecialization specialization,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BasePool(
            vault,
            specialization,
            name,
            symbol,
            tokens,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {}

    function _onInitializePool(
        bytes32 poolId,
        address sender,
        address recipient,
        bytes memory userData
    ) internal override returns (uint256, uint256[] memory) {}

    function _onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {}

    function _onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {}

}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/FixedPoint.sol";
import "../lib/openzeppelin/IERC20.sol";

import "../vault/interfaces/IVault.sol";
import "../vault/interfaces/IGeneralPool.sol";
import "../vault/interfaces/IMinimalSwapInfoPool.sol";

contract MockPool is IGeneralPool, IMinimalSwapInfoPool {
    using FixedPoint for uint256;

    IVault private immutable _vault;
    bytes32 private immutable _poolId;

    constructor(IVault vault, IVault.PoolSpecialization specialization) {
        _poolId = vault.registerPool(specialization);
        _vault = vault;
    }

    function getVault() external view returns (IVault) {
        return _vault;
    }

    function getPoolId() external view returns (bytes32) {
        return _poolId;
    }

    function registerTokens(IERC20[] memory tokens, address[] memory assetManagers) external {
        _vault.registerTokens(_poolId, tokens, assetManagers);
    }

    function deregisterTokens(IERC20[] memory tokens) external {
        _vault.deregisterTokens(_poolId, tokens);
    }

    event OnJoinPoolCalled(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes userData
    );

    event OnExitPoolCalled(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes userData
    );

    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external override returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts) {
        emit OnJoinPoolCalled(
            poolId,
            sender,
            recipient,
            currentBalances,
            lastChangeBlock,
            protocolSwapFeePercentage,
            userData
        );

        (amountsIn, dueProtocolFeeAmounts) = abi.decode(userData, (uint256[], uint256[]));
    }

    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external override returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts) {
        emit OnExitPoolCalled(
            poolId,
            sender,
            recipient,
            currentBalances,
            lastChangeBlock,
            protocolSwapFeePercentage,
            userData
        );

        (amountsOut, dueProtocolFeeAmounts) = abi.decode(userData, (uint256[], uint256[]));
    }

   
    uint256 private _multiplier = FixedPoint.ONE;

    function setMultiplier(uint256 newMultiplier) external {
        _multiplier = newMultiplier;
    }

   
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory,
        uint256,
        uint256
    ) external view override returns (uint256 amount) {
        return
            swapRequest.kind == IVault.SwapKind.GIVEN_IN
                ? swapRequest.amount.mulDown(_multiplier)
                : swapRequest.amount.divDown(_multiplier);
    }

   
    function onSwap(
        SwapRequest memory swapRequest,
        uint256,
        uint256
    ) external view override returns (uint256) {
        return
            swapRequest.kind == IVault.SwapKind.GIVEN_IN
                ? swapRequest.amount.mulDown(_multiplier)
                : swapRequest.amount.divDown(_multiplier);
    }

}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BasePool.sol";
import "../vault/interfaces/IGeneralPool.sol";

abstract contract BaseGeneralPool is IGeneralPool, BasePool {
    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BasePool(
            vault,
            IVault.PoolSpecialization.GENERAL,
            name,
            symbol,
            tokens,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
       
    }

   

    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view virtual override returns (uint256) {
        _validateIndexes(indexIn, indexOut, _getTotalTokens());
        uint256[] memory scalingFactors = _scalingFactors();

        return
            swapRequest.kind == IVault.SwapKind.GIVEN_IN
                ? _swapGivenIn(swapRequest, balances, indexIn, indexOut, scalingFactors)
                : _swapGivenOut(swapRequest, balances, indexIn, indexOut, scalingFactors);
    }

    function _swapGivenIn(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut,
        uint256[] memory scalingFactors
    ) internal view returns (uint256) {
       
        swapRequest.amount = _subtractSwapFeeAmount(swapRequest.amount);

        _upscaleArray(balances, scalingFactors);
        swapRequest.amount = _upscale(swapRequest.amount, scalingFactors[indexIn]);

        uint256 amountOut = _onSwapGivenIn(swapRequest, balances, indexIn, indexOut);

       
        return _downscaleDown(amountOut, scalingFactors[indexOut]);
    }

    function _swapGivenOut(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut,
        uint256[] memory scalingFactors
    ) internal view returns (uint256) {
        _upscaleArray(balances, scalingFactors);
        swapRequest.amount = _upscale(swapRequest.amount, scalingFactors[indexOut]);

        uint256 amountIn = _onSwapGivenOut(swapRequest, balances, indexIn, indexOut);

       
        amountIn = _downscaleUp(amountIn, scalingFactors[indexIn]);

       
        return _addSwapFeeAmount(amountIn);
    }

    
    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal view virtual returns (uint256);

    
    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal view virtual returns (uint256);

    function _validateIndexes(
        uint256 indexIn,
        uint256 indexOut,
        uint256 limit
    ) private pure {
        _require(indexIn < limit && indexOut < limit, Errors.OUT_OF_BOUNDS);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/math/FixedPoint.sol";
import "../../lib/helpers/InputHelpers.sol";

import "../BaseGeneralPool.sol";

import "./StableMath.sol";
import "./StablePoolUserDataHelpers.sol";

contract StablePool is BaseGeneralPool, StableMath {
    using FixedPoint for uint256;
    using StablePoolUserDataHelpers for bytes;

    uint256 private immutable _amplificationParameter;

    uint256 private _lastInvariant;

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amplificationParameter,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BaseGeneralPool(
            vault,
            name,
            symbol,
            tokens,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        _require(amplificationParameter >= _MIN_AMP, Errors.MIN_AMP);
        _require(amplificationParameter <= _MAX_AMP, Errors.MAX_AMP);

        _require(tokens.length <= _MAX_STABLE_TOKENS, Errors.MAX_STABLE_TOKENS);

        _amplificationParameter = amplificationParameter;
    }

    function getAmplificationParameter() external view returns (uint256) {
        return _amplificationParameter;
    }

   

   

    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal view virtual override whenNotPaused returns (uint256) {
        uint256 amountOut = StableMath._calcOutGivenIn(
            _amplificationParameter,
            balances,
            indexIn,
            indexOut,
            swapRequest.amount
        );

        return amountOut;
    }

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal view virtual override whenNotPaused returns (uint256) {
        uint256 amountIn = StableMath._calcInGivenOut(
            _amplificationParameter,
            balances,
            indexIn,
            indexOut,
            swapRequest.amount
        );

        return amountIn;
    }

   

    function _onInitializePool(
        bytes32,
        address,
        address,
        bytes memory userData
    ) internal virtual override whenNotPaused returns (uint256, uint256[] memory) {
        StablePool.JoinKind kind = userData.joinKind();
        _require(kind == StablePool.JoinKind.INIT, Errors.UNINITIALIZED);

        uint256[] memory amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(amountsIn.length, _getTotalTokens());
        _upscaleArray(amountsIn, _scalingFactors());

        uint256 invariantAfterJoin = StableMath._calculateInvariant(_amplificationParameter, amountsIn);
        uint256 bptAmountOut = invariantAfterJoin;

        _lastInvariant = invariantAfterJoin;

        return (bptAmountOut, amountsIn);
    }

   

    function _onJoinPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        virtual
        override
        whenNotPaused
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
       
       
       
        uint256[] memory dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(
            balances,
            _lastInvariant,
            protocolSwapFeePercentage
        );

       
       
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            balances[i] = balances[i].sub(dueProtocolFeeAmounts[i]);
        }

        (uint256 bptAmountOut, uint256[] memory amountsIn) = _doJoin(balances, userData);

       
       
        _lastInvariant = _invariantAfterJoin(balances, amountsIn);

        return (bptAmountOut, amountsIn, dueProtocolFeeAmounts);
    }

    function _doJoin(uint256[] memory balances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
        JoinKind kind = userData.joinKind();

        if (kind == JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return _joinExactTokensInForBPTOut(balances, userData);
        } else if (kind == JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT) {
            return _joinTokenInForExactBPTOut(balances, userData);
        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    function _joinExactTokensInForBPTOut(uint256[] memory balances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
        (uint256[] memory amountsIn, uint256 minBPTAmountOut) = userData.exactTokensInForBptOut();
        InputHelpers.ensureInputLengthMatch(_getTotalTokens(), amountsIn.length);
        _upscaleArray(amountsIn, _scalingFactors());

        uint256 bptAmountOut = StableMath._calcBptOutGivenExactTokensIn(
            _amplificationParameter,
            balances,
            amountsIn,
            totalSupply(),
            _swapFeePercentage
        );

        _require(bptAmountOut >= minBPTAmountOut, Errors.BPT_OUT_MIN_AMOUNT);

        return (bptAmountOut, amountsIn);
    }

    function _joinTokenInForExactBPTOut(uint256[] memory balances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
        (uint256 bptAmountOut, uint256 tokenIndex) = userData.tokenInForExactBptOut();

        uint256 amountIn = StableMath._calcTokenInGivenExactBptOut(
            _amplificationParameter,
            balances,
            tokenIndex,
            bptAmountOut,
            totalSupply(),
            _swapFeePercentage
        );

       
       
        uint256[] memory downscaledAmountsIn = new uint256[](_getTotalTokens());
        downscaledAmountsIn[tokenIndex] = amountIn;

        return (bptAmountOut, downscaledAmountsIn);
    }

   

    function _onExitPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        virtual
        override
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
        if (_isNotPaused()) {
           
           
           
            dueProtocolFeeAmounts = _getDueProtocolFeeAmounts(balances, _lastInvariant, protocolSwapFeePercentage);

           
           
            for (uint256 i = 0; i < _getTotalTokens(); ++i) {
                balances[i] = balances[i].sub(dueProtocolFeeAmounts[i]);
            }
        } else {
           
            dueProtocolFeeAmounts = new uint256[](_getTotalTokens());
        }

        (bptAmountIn, amountsOut) = _doExit(balances, userData);

       
       
        _lastInvariant = _invariantAfterExit(balances, amountsOut);

        return (bptAmountIn, amountsOut, dueProtocolFeeAmounts);
    }

    function _doExit(uint256[] memory balances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
        ExitKind kind = userData.exitKind();

        if (kind == ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT) {
            return _exitExactBPTInForTokenOut(balances, userData);
        } else if (kind == ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            return _exitExactBPTInForTokensOut(balances, userData);
        } else {
           
            return _exitBPTInForExactTokensOut(balances, userData);
        }
    }

    function _exitExactBPTInForTokenOut(uint256[] memory balances, bytes memory userData)
        private
        view
        whenNotPaused
        returns (uint256, uint256[] memory)
    {
       
        uint256 totalTokens = _getTotalTokens();
        (uint256 bptAmountIn, uint256 tokenIndex) = userData.exactBptInForTokenOut();
        _require(tokenIndex < totalTokens, Errors.OUT_OF_BOUNDS);

       
        uint256[] memory amountsOut = new uint256[](totalTokens);

        amountsOut[tokenIndex] = StableMath._calcTokenOutGivenExactBptIn(
            _amplificationParameter,
            balances,
            tokenIndex,
            bptAmountIn,
            totalSupply(),
            _swapFeePercentage
        );

        return (bptAmountIn, amountsOut);
    }

    function _exitExactBPTInForTokensOut(uint256[] memory balances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
       
       
       
       
        uint256 bptAmountIn = userData.exactBptInForTokensOut();

        uint256[] memory amountsOut = StableMath._calcTokensOutGivenExactBptIn(balances, bptAmountIn, totalSupply());

        return (bptAmountIn, amountsOut);
    }

    function _exitBPTInForExactTokensOut(uint256[] memory balances, bytes memory userData)
        private
        view
        whenNotPaused
        returns (uint256, uint256[] memory)
    {
       

        (uint256[] memory amountsOut, uint256 maxBPTAmountIn) = userData.bptInForExactTokensOut();
        InputHelpers.ensureInputLengthMatch(amountsOut.length, _getTotalTokens());

        _upscaleArray(amountsOut, _scalingFactors());

        uint256 bptAmountIn = StableMath._calcBptInGivenExactTokensOut(
            _amplificationParameter,
            balances,
            amountsOut,
            totalSupply(),
            _swapFeePercentage
        );

        _require(bptAmountIn <= maxBPTAmountIn, Errors.BPT_IN_MAX_AMOUNT);

        return (bptAmountIn, amountsOut);
    }

   

    function _getDueProtocolFeeAmounts(
        uint256[] memory balances,
        uint256 previousInvariant,
        uint256 protocolSwapFeePercentage
    ) private view returns (uint256[] memory) {
       
        uint256[] memory dueProtocolFeeAmounts = new uint256[](_getTotalTokens());

       
        if (protocolSwapFeePercentage == 0) {
            return dueProtocolFeeAmounts;
        }

       
       
       

       
        uint256 chosenTokenIndex = 0;
        uint256 maxBalance = balances[0];
        for (uint256 i = 1; i < _getTotalTokens(); ++i) {
            uint256 currentBalance = balances[i];
            if (currentBalance > maxBalance) {
                chosenTokenIndex = i;
                maxBalance = currentBalance;
            }
        }

       
        dueProtocolFeeAmounts[chosenTokenIndex] = StableMath._calcDueTokenProtocolSwapFeeAmount(
            _amplificationParameter,
            balances,
            previousInvariant,
            chosenTokenIndex,
            protocolSwapFeePercentage
        );

        return dueProtocolFeeAmounts;
    }

    function _invariantAfterJoin(uint256[] memory balances, uint256[] memory amountsIn) private view returns (uint256) {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            balances[i] = balances[i].add(amountsIn[i]);
        }

        return StableMath._calculateInvariant(_amplificationParameter, balances);
    }

    function _invariantAfterExit(uint256[] memory balances, uint256[] memory amountsOut)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _getTotalTokens(); ++i) {
            balances[i] = balances[i].sub(amountsOut[i]);
        }

        return StableMath._calculateInvariant(_amplificationParameter, balances);
    }

    
    function getRate() public view returns (uint256) {
        (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());
        return StableMath._calculateInvariant(_amplificationParameter, balances).divDown(totalSupply());
    }
}

pragma solidity ^0.7.0;

import "../../lib/math/Math.sol";
import "../../lib/math/FixedPoint.sol";

contract StableMath {
    using FixedPoint for uint256;

    uint256 internal constant _MIN_AMP = 1e18;
    uint256 internal constant _MAX_AMP = 5000 * (1e18);

    uint256 internal constant _MAX_STABLE_TOKENS = 5;

   
   
    function _calculateInvariant(uint256 amplificationParameter, uint256[] memory balances)
        internal
        pure
        returns (uint256)
    {
        

       

        uint256 sum = 0;
        uint256 numTokens = balances.length;
        for (uint256 i = 0; i < numTokens; i++) {
            sum = sum.add(balances[i]);
        }
        if (sum == 0) {
            return 0;
        }
        uint256 prevInvariant = 0;
        uint256 invariant = sum;
        uint256 ampTimesTotal = Math.mul(amplificationParameter, numTokens);

        for (uint256 i = 0; i < 255; i++) {
            uint256 P_D = Math.mul(numTokens, balances[0]);
            for (uint256 j = 1; j < numTokens; j++) {
                P_D = Math.divUp(Math.mul(Math.mul(P_D, balances[j]), numTokens), invariant);
            }
            prevInvariant = invariant;
            invariant = Math.divUp(
                Math.mul(Math.mul(numTokens, invariant), invariant).add(Math.mul(Math.mul(ampTimesTotal, sum), P_D)),
                Math.mul(numTokens.add(1), invariant).add(Math.mul(ampTimesTotal.sub(1), P_D))
            );

            if (invariant > prevInvariant) {
                if (invariant.sub(prevInvariant) <= 1) {
                    break;
                }
            } else if (prevInvariant.sub(invariant) <= 1) {
                break;
            }
        }
        return invariant;
    }

   
   
    function _calcOutGivenIn(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn
    ) internal pure returns (uint256) {
        

       

        uint256 invariant = _calculateInvariant(amplificationParameter, balances);

        balances[tokenIndexIn] = balances[tokenIndexIn].add(tokenAmountIn);

        uint256 finalBalanceOut = _getTokenBalanceGivenInvariantAndAllOtherBalances(
            amplificationParameter,
            balances,
            invariant,
            tokenIndexOut
        );

        balances[tokenIndexIn] = balances[tokenIndexIn].sub(tokenAmountIn);

        return balances[tokenIndexOut].sub(finalBalanceOut).sub(1);
    }

   
   
   
    function _calcInGivenOut(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountOut
    ) internal pure returns (uint256) {
        

       

        uint256 invariant = _calculateInvariant(amplificationParameter, balances);

        balances[tokenIndexOut] = balances[tokenIndexOut].sub(tokenAmountOut);

        uint256 finalBalanceIn = _getTokenBalanceGivenInvariantAndAllOtherBalances(
            amplificationParameter,
            balances,
            invariant,
            tokenIndexIn
        );

        balances[tokenIndexOut] = balances[tokenIndexOut].add(tokenAmountOut);

        return finalBalanceIn.sub(balances[tokenIndexIn]).add(1);
    }

    
    function _calcBptOutGivenExactTokensIn(
        uint256 amp,
        uint256[] memory balances,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
       

       
        uint256 currentInvariant = _calculateInvariant(amp, balances);

       
       
        uint256 sumBalances = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            sumBalances = sumBalances.add(balances[i]);
        }

       
        uint256[] memory tokenBalanceRatiosWithoutFee = new uint256[](amountsIn.length);
       
        uint256 weightedBalanceRatio = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 currentWeight = balances[i].divDown(sumBalances);
            tokenBalanceRatiosWithoutFee[i] = balances[i].add(amountsIn[i]).divDown(balances[i]);
            weightedBalanceRatio = weightedBalanceRatio.add(tokenBalanceRatiosWithoutFee[i].mulDown(currentWeight));
        }

       
        uint256[] memory newBalances = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
           
            uint256 tokenBalancePercentageExcess;
           
           
           
            if (weightedBalanceRatio >= tokenBalanceRatiosWithoutFee[i]) {
                tokenBalancePercentageExcess = 0;
            } else {
                tokenBalancePercentageExcess = tokenBalanceRatiosWithoutFee[i].sub(weightedBalanceRatio).divUp(
                    tokenBalanceRatiosWithoutFee[i].sub(FixedPoint.ONE)
                );
            }

            uint256 swapFeeExcess = swapFeePercentage.mulUp(tokenBalancePercentageExcess);

            uint256 amountInAfterFee = amountsIn[i].mulDown(swapFeeExcess.complement());

            newBalances[i] = balances[i].add(amountInAfterFee);
        }

       
        uint256 newInvariant = _calculateInvariant(amp, newBalances);

       
        return bptTotalSupply.mulDown(newInvariant.divDown(currentInvariant).sub(FixedPoint.ONE));
    }

    
    function _calcTokenInGivenExactBptOut(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndex,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
       

       
        uint256 currentInvariant = _calculateInvariant(amp, balances);

       
        uint256 newInvariant = bptTotalSupply.add(bptAmountOut).divUp(bptTotalSupply).mulUp(currentInvariant);

       
       
        uint256 sumBalances = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            sumBalances = sumBalances.add(balances[i]);
        }

       
        uint256 newBalanceTokenIndex = _getTokenBalanceGivenInvariantAndAllOtherBalances(
            amp,
            balances,
            newInvariant,
            tokenIndex
        );
        uint256 amountInAfterFee = newBalanceTokenIndex.sub(balances[tokenIndex]);

       
        uint256 currentWeight = balances[tokenIndex].divDown(sumBalances);
        uint256 tokenBalancePercentageExcess = currentWeight.complement();

        uint256 swapFeeExcess = swapFeePercentage.mulUp(tokenBalancePercentageExcess);

        return amountInAfterFee.divUp(swapFeeExcess.complement());
    }

    
    function _calcBptInGivenExactTokensOut(
        uint256 amp,
        uint256[] memory balances,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) internal pure returns (uint256) {
       

       
        uint256 currentInvariant = _calculateInvariant(amp, balances);

       
       
        uint256 sumBalances = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            sumBalances = sumBalances.add(balances[i]);
        }

       
        uint256[] memory tokenBalanceRatiosWithoutFee = new uint256[](amountsOut.length);
        uint256 weightedBalanceRatio = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 currentWeight = balances[i].divUp(sumBalances);
            tokenBalanceRatiosWithoutFee[i] = balances[i].sub(amountsOut[i]).divUp(balances[i]);
            weightedBalanceRatio = weightedBalanceRatio.add(tokenBalanceRatiosWithoutFee[i].mulUp(currentWeight));
        }

       
        uint256[] memory newBalances = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 tokenBalancePercentageExcess;
           
           
            if (weightedBalanceRatio <= tokenBalanceRatiosWithoutFee[i]) {
                tokenBalancePercentageExcess = 0;
            } else {
                tokenBalancePercentageExcess = weightedBalanceRatio.sub(tokenBalanceRatiosWithoutFee[i]).divUp(
                    tokenBalanceRatiosWithoutFee[i].complement()
                );
            }

            uint256 swapFeeExcess = swapFee.mulUp(tokenBalancePercentageExcess);

            uint256 amountOutBeforeFee = amountsOut[i].divUp(swapFeeExcess.complement());

            newBalances[i] = balances[i].sub(amountOutBeforeFee);
        }

       
        uint256 newInvariant = _calculateInvariant(amp, newBalances);

       
        return bptTotalSupply.mulUp(newInvariant.divUp(currentInvariant).complement());
    }

    
    function _calcTokenOutGivenExactBptIn(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndex,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
       
        uint256 currentInvariant = _calculateInvariant(amp, balances);
       
        uint256 newInvariant = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply).mulUp(currentInvariant);

       
       
        uint256 sumBalances = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            sumBalances = sumBalances.add(balances[i]);
        }

       
        uint256 newBalanceTokenIndex = _getTokenBalanceGivenInvariantAndAllOtherBalances(
            amp,
            balances,
            newInvariant,
            tokenIndex
        );
        uint256 amountOutBeforeFee = balances[tokenIndex].sub(newBalanceTokenIndex);

       
        uint256 currentWeight = balances[tokenIndex].divDown(sumBalances);
        uint256 tokenBalancePercentageExcess = currentWeight.complement();

        uint256 swapFeeExcess = swapFeePercentage.mulUp(tokenBalancePercentageExcess);

        return amountOutBeforeFee.mulDown(swapFeeExcess.complement());
    }

    function _calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 bptTotalSupply
    ) internal pure returns (uint256[] memory) {
        

       
       

        uint256 bptRatio = bptAmountIn.divDown(bptTotalSupply);

        uint256[] memory amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsOut[i] = balances[i].mulDown(bptRatio);
        }

        return amountsOut;
    }

   
    function _calcDueTokenProtocolSwapFeeAmount(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 lastInvariant,
        uint256 tokenIndex,
        uint256 protocolSwapFeePercentage
    ) internal pure returns (uint256) {
        

       

        uint256 finalBalanceFeeToken = _getTokenBalanceGivenInvariantAndAllOtherBalances(
            amplificationParameter,
            balances,
            lastInvariant,
            tokenIndex
        );

       
        uint256 accumulatedTokenSwapFees = balances[tokenIndex] > finalBalanceFeeToken
            ? balances[tokenIndex].sub(finalBalanceFeeToken)
            : 0;
        return accumulatedTokenSwapFees.mulDown(protocolSwapFeePercentage).divDown(FixedPoint.ONE);
    }

   

   
   
    function _getTokenBalanceGivenInvariantAndAllOtherBalances(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 invariant,
        uint256 tokenIndex
    ) private pure returns (uint256) {
       

        uint256 ampTimesTotal = Math.mul(amplificationParameter, balances.length);
        uint256 sum = balances[0];
        uint256 P_D = Math.mul(balances.length, balances[0]);
        for (uint256 j = 1; j < balances.length; j++) {
            P_D = Math.divDown(Math.mul(Math.mul(P_D, balances[j]), balances.length), invariant);
            sum = sum.add(balances[j]);
        }
        sum = sum.sub(balances[tokenIndex]);

        uint256 c = Math.divUp(Math.mul(invariant, invariant), ampTimesTotal);
       
        c = c.mulUp(balances[tokenIndex]).divUp(P_D);

        uint256 b = sum.add(invariant.divDown(ampTimesTotal));

       
        uint256 prevTokenBalance = 0;
       
       
        uint256 tokenBalance = invariant.mulUp(invariant).add(c).divUp(invariant.add(b));

        for (uint256 i = 0; i < 255; i++) {
            prevTokenBalance = tokenBalance;

            tokenBalance = tokenBalance.mulUp(tokenBalance).add(c).divUp(
                Math.mul(tokenBalance, 2).add(b).sub(invariant)
            );

            if (tokenBalance > prevTokenBalance) {
                if (tokenBalance.sub(prevTokenBalance) <= 1) {
                    break;
                }
            } else if (prevTokenBalance.sub(tokenBalance) <= 1) {
                break;
            }
        }
        return tokenBalance;
    }
}

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/IERC20.sol";

import "./StablePool.sol";

library StablePoolUserDataHelpers {
    function joinKind(bytes memory self) internal pure returns (StablePool.JoinKind) {
        return abi.decode(self, (StablePool.JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (StablePool.ExitKind) {
        return abi.decode(self, (StablePool.ExitKind));
    }

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (StablePool.JoinKind, uint256[]));
    }

    function exactTokensInForBptOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsIn, uint256 minBPTAmountIn)
    {
        (, amountsIn, minBPTAmountIn) = abi.decode(self, (StablePool.JoinKind, uint256[], uint256));
    }

    function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
        (, bptAmountOut, tokenIndex) = abi.decode(self, (StablePool.JoinKind, uint256, uint256));
    }

    function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
        (, bptAmountIn, tokenIndex) = abi.decode(self, (StablePool.ExitKind, uint256, uint256));
    }

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (StablePool.ExitKind, uint256));
    }

    function bptInForExactTokensOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
    {
        (, amountsOut, maxBPTAmountIn) = abi.decode(self, (StablePool.ExitKind, uint256[], uint256));
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../vault/interfaces/IVault.sol";

import "../factories/BasePoolFactory.sol";
import "../factories/FactoryWidePauseWindow.sol";

import "./StablePool.sol";

contract StablePoolFactory is BasePoolFactory, FactoryWidePauseWindow {
    constructor(IVault vault) BasePoolFactory(vault) {
       
    }

    
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amplificationParameter,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address) {
        (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) = getPauseConfiguration();

        address pool = address(
            new StablePool(
                getVault(),
                name,
                symbol,
                tokens,
                amplificationParameter,
                swapFeePercentage,
                pauseWindowDuration,
                bufferPeriodDuration,
                owner
            )
        );
        _register(pool);
        return pool;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract FactoryWidePauseWindow {
   
   

    uint256 private constant _INITIAL_PAUSE_WINDOW_DURATION = 90 days;
    uint256 private constant _BUFFER_PERIOD_DURATION = 30 days;

   
   
    uint256 private immutable _poolsPauseWindowEndTime;

    constructor() {
        _poolsPauseWindowEndTime = block.timestamp + _INITIAL_PAUSE_WINDOW_DURATION;
    }

    
    function getPauseConfiguration() public view returns (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        uint256 currentTime = block.timestamp;
        if (currentTime < _poolsPauseWindowEndTime) {
           
           

            pauseWindowDuration = _poolsPauseWindowEndTime - currentTime;
            bufferPeriodDuration = _BUFFER_PERIOD_DURATION;
        } else {
           
           

            pauseWindowDuration = 0;
            bufferPeriodDuration = 0;
        }
    }
}

pragma solidity ^0.7.0;

import "../pools/stable/StableMath.sol";

contract MockStableMath is StableMath {
    function invariant(uint256 amp, uint256[] memory balances) external pure returns (uint256) {
        return _calculateInvariant(amp, balances);
    }

    function outGivenIn(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn
    ) external pure returns (uint256) {
        return _calcOutGivenIn(amp, balances, tokenIndexIn, tokenIndexOut, tokenAmountIn);
    }

    function inGivenOut(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountOut
    ) external pure returns (uint256) {
        return _calcInGivenOut(amp, balances, tokenIndexIn, tokenIndexOut, tokenAmountOut);
    }

    function exactTokensInForBPTOut(
        uint256 amp,
        uint256[] memory balances,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcBptOutGivenExactTokensIn(amp, balances, amountsIn, bptTotalSupply, swapFee);
    }

    function tokenInForExactBPTOut(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndex,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcTokenInGivenExactBptOut(amp, balances, tokenIndex, bptAmountOut, bptTotalSupply, swapFee);
    }

    function exactBPTInForTokenOut(
        uint256 amp,
        uint256[] memory balances,
        uint256 tokenIndex,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcTokenOutGivenExactBptIn(amp, balances, tokenIndex, bptAmountIn, bptTotalSupply, swapFee);
    }

    function exactBPTInForTokensOut(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 bptTotalSupply
    ) external pure returns (uint256[] memory) {
        return _calcTokensOutGivenExactBptIn(balances, bptAmountIn, bptTotalSupply);
    }

    function bptInForExactTokensOut(
        uint256 amp,
        uint256[] memory balances,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcBptInGivenExactTokensOut(amp, balances, amountsOut, bptTotalSupply, swapFee);
    }

    function calculateDueTokenProtocolSwapFeeAmount(
        uint256 amp,
        uint256[] memory balances,
        uint256 lastInvariant,
        uint256 tokenIndex,
        uint256 protocolSwapFeePercentage
    ) external pure returns (uint256) {
        return _calcDueTokenProtocolSwapFeeAmount(amp, balances, lastInvariant, tokenIndex, protocolSwapFeePercentage);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/math/FixedPoint.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "../vault/AssetTransfersHandler.sol";

contract MockAssetTransfersHandler is AssetTransfersHandler {
    using Math for uint256;
    using SafeERC20 for IERC20;

    mapping(address => mapping(IERC20 => uint256)) private _internalTokenBalance;

    constructor(IWETH weth) AssetHelpers(weth) {}

    function receiveAsset(
        IAsset asset,
        uint256 amount,
        address sender,
        bool fromInternalBalance
    ) external payable {
        _receiveAsset(asset, amount, sender, fromInternalBalance);
    }

    function sendAsset(
        IAsset asset,
        uint256 amount,
        address payable recipient,
        bool toInternalBalance
    ) external {
        _sendAsset(asset, amount, recipient, toInternalBalance);
    }

    function getInternalBalance(address account, IERC20 token) external view returns (uint256) {
        return _internalTokenBalance[account][token];
    }

    function depositToInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) external {
        token.safeTransferFrom(account, address(this), amount);
        _increaseInternalBalance(account, token, amount);
    }

    function _increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal override {
        _internalTokenBalance[account][token] += amount;
    }

    function _decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool capped
    ) internal override returns (uint256 deducted) {
        uint256 currentBalance = _internalTokenBalance[account][token];
        deducted = capped ? Math.min(currentBalance, amount) : amount;
        _internalTokenBalance[account][token] = currentBalance.sub(deducted);
    }
}

pragma solidity ^0.7.0;

import "../pools/weighted/WeightedMath.sol";

contract MockWeightedMath is WeightedMath {
    function invariant(uint256[] memory normalizedWeights, uint256[] memory balances) external pure returns (uint256) {
        return _calculateInvariant(normalizedWeights, balances);
    }

    function outGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn
    ) external pure returns (uint256) {
        return _calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
    }

    function inGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut
    ) external pure returns (uint256) {
        return _calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut);
    }

    function exactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcBptOutGivenExactTokensIn(balances, normalizedWeights, amountsIn, bptTotalSupply, swapFee);
    }

    function tokenInForExactBPTOut(
        uint256 tokenBalance,
        uint256 tokenNormalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcTokenInGivenExactBptOut(tokenBalance, tokenNormalizedWeight, bptAmountOut, bptTotalSupply, swapFee);
    }

    function exactBPTInForTokenOut(
        uint256 tokenBalance,
        uint256 tokenNormalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcTokenOutGivenExactBptIn(tokenBalance, tokenNormalizedWeight, bptAmountIn, bptTotalSupply, swapFee);
    }

    function exactBPTInForTokensOut(
        uint256[] memory currentBalances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) external pure returns (uint256[] memory) {
        return _calcTokensOutGivenExactBptIn(currentBalances, bptAmountIn, totalBPT);
    }

    function bptInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcBptInGivenExactTokensOut(balances, normalizedWeights, amountsOut, bptTotalSupply, swapFee);
    }

    function calculateDueTokenProtocolSwapFeeAmount(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 previousInvariant,
        uint256 currentInvariant,
        uint256 protocolSwapFeePercentage
    ) external pure returns (uint256) {
        return
            _calcDueTokenProtocolSwapFeeAmount(
                balance,
                normalizedWeight,
                previousInvariant,
                currentInvariant,
                protocolSwapFeePercentage
            );
    }
}

pragma solidity ^0.7.0;

import "../pools/BalancerPoolToken.sol";

contract MockBalancerPoolToken is BalancerPoolToken {
    constructor(string memory name, string memory symbol) BalancerPoolToken(name, symbol) {}

    function mint(address recipient, uint256 amount) external {
        _mintPoolTokens(recipient, amount);
    }

    function burn(address sender, uint256 amount) external {
        _burnPoolTokens(sender, amount);
    }
}

pragma solidity ^0.7.0;

import "../../lib/helpers/SignaturesValidator.sol";

contract SignaturesValidatorMock is SignaturesValidator {
    bytes32 internal immutable AUTH_TYPE_HASH = keccak256(
        "Authorization(bytes calldata,address sender,uint256 nonce,uint256 deadline)"
    );

    event Authenticated(address user, address sender);
    event CalldataDecoded(bytes data, uint256 deadline, uint8 v, bytes32 r, bytes32 s);

    constructor() SignaturesValidator("Balancer V2 Vault") {
       
    }

    function decodeCalldata() external {
        _decodeCalldata();
    }

    function authenticateCall(address user) external {
        _validateSignature(user, Errors.INVALID_SIGNATURE);
        _decodeCalldata();
        emit Authenticated(user, msg.sender);
    }

    function anotherFunction(address user) external {
       
    }

    function increaseNonce(address user) external {
        _nextNonce[user]++;
    }

    function _decodeCalldata() internal {
        (uint8 v, bytes32 r, bytes32 s) = _signature();
        emit CalldataDecoded(_calldata(), _deadline(), v, r, s);
    }

    function _typeHash() internal view override returns (bytes32) {
        return AUTH_TYPE_HASH;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../math/Math.sol";
import "../math/FixedPoint.sol";

import "./InputHelpers.sol";
import "./AssetHelpers.sol";
import "./BalancerErrors.sol";

import "../../pools/BasePool.sol";
import "../../vault/ProtocolFeesCollector.sol";
import "../../vault/interfaces/IWETH.sol";
import "../../vault/interfaces/IVault.sol";
import "../../vault/balances/BalanceAllocation.sol";

contract BalancerHelpers is AssetHelpers {
    using Math for uint256;
    using BalanceAllocation for bytes32;
    using BalanceAllocation for bytes32[];

    IVault public immutable vault;

    constructor(IVault _vault) AssetHelpers(_vault.WETH()) {
        vault = _vault;
    }

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        (address pool, ) = vault.getPool(poolId);
        (uint256[] memory balances, uint256 lastChangeBlock) = _validateAssetsAndGetBalances(poolId, request.assets);
        ProtocolFeesCollector feesCollector = vault.getProtocolFeesCollector();

        (bptOut, amountsIn) = BasePool(pool).queryJoin(
            poolId,
            sender,
            recipient,
            balances,
            lastChangeBlock,
            feesCollector.getSwapFeePercentage(),
            request.userData
        );
    }

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IVault.ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        (address pool, ) = vault.getPool(poolId);
        (uint256[] memory balances, uint256 lastChangeBlock) = _validateAssetsAndGetBalances(poolId, request.assets);
        ProtocolFeesCollector feesCollector = vault.getProtocolFeesCollector();

        (bptIn, amountsOut) = BasePool(pool).queryExit(
            poolId,
            sender,
            recipient,
            balances,
            lastChangeBlock,
            feesCollector.getSwapFeePercentage(),
            request.userData
        );
    }

    function _validateAssetsAndGetBalances(bytes32 poolId, IAsset[] memory expectedAssets)
        internal
        view
        returns (uint256[] memory balances, uint256 lastChangeBlock)
    {
        IERC20[] memory actualTokens;
        IERC20[] memory expectedTokens = _translateToIERC20(expectedAssets);

        (actualTokens, balances, lastChangeBlock) = vault.getPoolTokens(poolId);
        InputHelpers.ensureInputLengthMatch(actualTokens.length, expectedTokens.length);

        for (uint256 i = 0; i < actualTokens.length; ++i) {
            IERC20 token = actualTokens[i];
            _require(token == expectedTokens[i], Errors.TOKENS_MISMATCH);
        }
    }
}

pragma solidity ^0.7.0;

import "../lib/openzeppelin/AccessControl.sol";

import "../vault/interfaces/IWETH.sol";

contract WETH is AccessControl, IWETH {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(address minter) {
        _setupRole(DEFAULT_ADMIN_ROLE, minter);
        _setupRole(MINTER_ROLE, minter);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable override {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public override {
        require(balanceOf[msg.sender] >= wad, "INSUFFICIENT_BALANCE");
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

   
    function mint(address destinatary, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER");
        balanceOf[destinatary] += amount;
        emit Deposit(destinatary, amount);
    }

    function totalSupply() public view override returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public override returns (bool) {
        require(balanceOf[src] >= wad, "INSUFFICIENT_BALANCE");

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, "INSUFFICIENT_ALLOWANCE");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

pragma solidity ^0.7.0;

import "../../lib/helpers/TemporarilyPausable.sol";

contract TemporarilyPausableMock is TemporarilyPausable {
    constructor(uint256 pauseWindowDuration, uint256 bufferPeriodDuration)
        TemporarilyPausable(pauseWindowDuration, bufferPeriodDuration)
    {}

    function setPaused(bool paused) external {
        _setPaused(paused);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin/IERC20.sol";

import "../vault/interfaces/IVault.sol";
import "../lib/helpers/InputHelpers.sol";

contract MockInternalBalanceRelayer {
    IVault public vault;

    constructor(IVault _vault) {
        vault = _vault;
    }

    function depositAndWithdraw(
        address payable sender,
        IAsset asset,
        uint256[] memory depositAmounts,
        uint256[] memory withdrawAmounts
    ) public {
        InputHelpers.ensureInputLengthMatch(depositAmounts.length, withdrawAmounts.length);
        for (uint256 i = 0; i < depositAmounts.length; i++) {
            IVault.UserBalanceOp[] memory deposit = _buildUserBalanceOp(
                IVault.UserBalanceOpKind.DEPOSIT_INTERNAL,
                sender,
                asset,
                depositAmounts[i]
            );
            vault.manageUserBalance(deposit);

            IVault.UserBalanceOp[] memory withdraw = _buildUserBalanceOp(
                IVault.UserBalanceOpKind.WITHDRAW_INTERNAL,
                sender,
                asset,
                withdrawAmounts[i]
            );
            vault.manageUserBalance(withdraw);
        }
    }

    function _buildUserBalanceOp(
        IVault.UserBalanceOpKind kind,
        address payable sender,
        IAsset asset,
        uint256 amount
    ) internal pure returns (IVault.UserBalanceOp[] memory ops) {
        ops = new IVault.UserBalanceOp[](1);
        ops[0] = IVault.UserBalanceOp({ asset: asset, amount: amount, sender: sender, recipient: sender, kind: kind });
    }
}

pragma solidity ^0.7.0;

import "../vault/balances/BalanceAllocation.sol";

contract BalanceAllocationMock {
    using BalanceAllocation for bytes32;

    function total(bytes32 balance) public pure returns (uint256) {
        return balance.total();
    }

    function totals(bytes32[] memory balances) public pure returns (uint256[] memory result) {
        (result, ) = BalanceAllocation.totalsAndLastChangeBlock(balances);
    }

    function cash(bytes32 balance) public pure returns (uint256) {
        return balance.cash();
    }

    function managed(bytes32 balance) public pure returns (uint256) {
        return balance.managed();
    }

    function lastChangeBlock(bytes32 balance) public pure returns (uint256) {
        return balance.lastChangeBlock();
    }

    function isNotZero(bytes32 balance) public pure returns (bool) {
        return balance.isNotZero();
    }

    function isZero(bytes32 balance) public pure returns (bool) {
        return balance.isZero();
    }

    function toBalance(
        uint256 _cash,
        uint256 _managed,
        uint256 _lastChangeBlock
    ) public pure returns (bytes32) {
        return BalanceAllocation.toBalance(_cash, _managed, _lastChangeBlock);
    }

    function increaseCash(bytes32 balance, uint256 amount) public view returns (bytes32) {
        return balance.increaseCash(amount);
    }

    function decreaseCash(bytes32 balance, uint256 amount) public view returns (bytes32) {
        return balance.decreaseCash(amount);
    }

    function cashToManaged(bytes32 balance, uint256 amount) public pure returns (bytes32) {
        return balance.cashToManaged(amount);
    }

    function managedToCash(bytes32 balance, uint256 amount) public pure returns (bytes32) {
        return balance.managedToCash(amount);
    }

    function setManaged(bytes32 balance, uint256 newManaged) public view returns (bytes32) {
        return balance.setManaged(newManaged);
    }

    function fromSharedToBalanceA(bytes32 sharedCash, bytes32 sharedManaged) public pure returns (bytes32) {
        return BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
    }

    function fromSharedToBalanceB(bytes32 sharedCash, bytes32 sharedManaged) public pure returns (bytes32) {
        return BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    function toSharedCash(bytes32 tokenABalance, bytes32 tokenBBalance) public pure returns (bytes32) {
        return BalanceAllocation.toSharedCash(tokenABalance, tokenBBalance);
    }

    function toSharedManaged(bytes32 tokenABalance, bytes32 tokenBBalance) public pure returns (bytes32) {
        return BalanceAllocation.toSharedManaged(tokenABalance, tokenBBalance);
    }
}

pragma solidity ^0.7.0;

import "../../lib/helpers/BalancerErrors.sol";

contract BalancerErrorsMock {
    function fail(uint256 code) external pure {
        _revert(code);
    }
}

