/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/DecimalMath.sol


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/lib/Ownable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeERC20.sol



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/DODOVendingMachine/intf/IDVM.sol


interface IDVM {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function _MT_FEE_RATE_MODEL_() external returns (address);

    function getVaultReserve() external returns (uint256 baseReserve, uint256 quoteReserve);

    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);

    function buyShares(address to) external returns (uint256,uint256,uint256);

}

// File: contracts/lib/InitializableOwnable.sol


/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/CloneFactory.sol


interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/Factory/DVMFactory.sol




interface IDVMFactory {
    function createDODOVendingMachine(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external returns (address newVendingMachine);
}


/**
 * @title DODO VendingMachine Factory
 * @author DODO Breeder
 *
 * @notice Create And Register DVM Pools 
 */
contract DVMFactory is InitializableOwnable {
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _DEFAULT_MAINTAINER_;
    address public immutable _DEFAULT_MT_FEE_RATE_MODEL_;
    address public _DVM_TEMPLATE_;

    // ============ Registry ============

    // base -> quote -> DVM address list
    mapping(address => mapping(address => address[])) public _REGISTRY_;
    // creator -> DVM address list
    mapping(address => address[]) public _USER_REGISTRY_;

    // ============ Events ============

    event NewDVM(
        address baseToken,
        address quoteToken,
        address creator,
        address dvm
    );

    event RemoveDVM(address dvm);

    // ============ Functions ============

    constructor(
        address cloneFactory,
        address dvmTemplate,
        address defaultMaintainer,
        address defaultMtFeeRateModel
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _DVM_TEMPLATE_ = dvmTemplate;
        _DEFAULT_MAINTAINER_ = defaultMaintainer;
        _DEFAULT_MT_FEE_RATE_MODEL_ = defaultMtFeeRateModel;
    }

    function createDODOVendingMachine(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external returns (address newVendingMachine) {
        newVendingMachine = ICloneFactory(_CLONE_FACTORY_).clone(_DVM_TEMPLATE_);
        {
            IDVM(newVendingMachine).init(
                _DEFAULT_MAINTAINER_,
                baseToken,
                quoteToken,
                lpFeeRate,
                _DEFAULT_MT_FEE_RATE_MODEL_,
                i,
                k,
                isOpenTWAP
            );
        }
        _REGISTRY_[baseToken][quoteToken].push(newVendingMachine);
        _USER_REGISTRY_[tx.origin].push(newVendingMachine);
        emit NewDVM(baseToken, quoteToken, tx.origin, newVendingMachine);
    }

    // ============ Admin Operation Functions ============

    function updateDvmTemplate(address _newDVMTemplate) external onlyOwner {
        _DVM_TEMPLATE_ = _newDVMTemplate;
    }

    function addPoolByAdmin(
        address creator,
        address baseToken, 
        address quoteToken,
        address pool
    ) external onlyOwner {
        _REGISTRY_[baseToken][quoteToken].push(pool);
        _USER_REGISTRY_[creator].push(pool);
        emit NewDVM(baseToken, quoteToken, creator, pool);
    }

    function removePoolByAdmin(
        address creator,
        address baseToken, 
        address quoteToken,
        address pool
    ) external onlyOwner {
        address[] memory registryList = _REGISTRY_[baseToken][quoteToken];
        for (uint256 i = 0; i < registryList.length; i++) {
            if (registryList[i] == pool) {
                registryList[i] = registryList[registryList.length - 1];
                break;
            }
        }
        _REGISTRY_[baseToken][quoteToken] = registryList;
        _REGISTRY_[baseToken][quoteToken].pop();
        address[] memory userRegistryList = _USER_REGISTRY_[creator];
        for (uint256 i = 0; i < userRegistryList.length; i++) {
            if (userRegistryList[i] == pool) {
                userRegistryList[i] = userRegistryList[userRegistryList.length - 1];
                break;
            }
        }
        _USER_REGISTRY_[creator] = userRegistryList;
        _USER_REGISTRY_[creator].pop();
        emit RemoveDVM(pool);
    }

    // ============ View Functions ============

    function getDODOPool(address baseToken, address quoteToken)
        external
        view
        returns (address[] memory machines)
    {
        return _REGISTRY_[baseToken][quoteToken];
    }

    function getDODOPoolBidirection(address token0, address token1)
        external
        view
        returns (address[] memory baseToken0Machines, address[] memory baseToken1Machines)
    {
        return (_REGISTRY_[token0][token1], _REGISTRY_[token1][token0]);
    }

    function getDODOPoolByUser(address user)
        external
        view
        returns (address[] memory machines)
    {
        return _USER_REGISTRY_[user];
    }
}

// File: contracts/lib/ReentrancyGuard.sol


/**
 * @title ReentrancyGuard
 * @author DODO Breeder
 *
 * @notice Protect functions from Reentrancy Attack
 */
contract ReentrancyGuard {
    // https://solidity.readthedocs.io/en/latest/control-structures.html?highlight=zero-state#scoping-and-declarations
    // zero-state of _ENTERED_ is false
    bool private _ENTERED_;

    modifier preventReentrant() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }
}

// File: contracts/lib/PermissionManager.sol


interface IPermissionManager {
    function initOwner(address) external;

    function isAllowed(address) external view returns (bool);
}

contract PermissionManager is InitializableOwnable {
    bool public _WHITELIST_MODE_ON_;

    mapping(address => bool) internal _whitelist_;
    mapping(address => bool) internal _blacklist_;

    function isAllowed(address account) external view returns (bool) {
        if (_WHITELIST_MODE_ON_) {
            return _whitelist_[account];
        } else {
            return !_blacklist_[account];
        }
    }

    function openBlacklistMode() external onlyOwner {
        _WHITELIST_MODE_ON_ = false;
    }

    function openWhitelistMode() external onlyOwner {
        _WHITELIST_MODE_ON_ = true;
    }

    function addToWhitelist(address account) external onlyOwner {
        _whitelist_[account] = true;
    }

    function removeFromWhitelist(address account) external onlyOwner {
        _whitelist_[account] = false;
    }

    function addToBlacklist(address account) external onlyOwner {
        _blacklist_[account] = true;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        _blacklist_[account] = false;
    }
}

// File: contracts/lib/FeeRateModel.sol



interface IFeeRateImpl {
    function getFeeRate(address pool, address trader) external view returns (uint256);
}

interface IFeeRateModel {
    function getFeeRate(address trader) external view returns (uint256);
}

contract FeeRateModel is InitializableOwnable {
    address public feeRateImpl;

    function setFeeProxy(address _feeRateImpl) public onlyOwner {
        feeRateImpl = _feeRateImpl;
    }
    
    function getFeeRate(address trader) external view returns (uint256) {
        if(feeRateImpl == address(0))
            return 0;
        return IFeeRateImpl(feeRateImpl).getFeeRate(msg.sender,trader);
    }
}

// File: contracts/CrowdPooling/impl/CPStorage.sol


contract CPStorage is InitializableOwnable, ReentrancyGuard {
    using SafeMath for uint256;

    // ============ Constant ============
    
    uint256 internal constant _SETTLEMENT_EXPIRE_ = 86400 * 7;
    uint256 internal constant _SETTEL_FUND_ = 200 finney;
    bool public _IS_OPEN_TWAP_ = false;

    // ============ Timeline ============

    uint256 public _PHASE_BID_STARTTIME_;
    uint256 public _PHASE_BID_ENDTIME_;
    uint256 public _PHASE_CALM_ENDTIME_;
    uint256 public _SETTLED_TIME_;
    bool public _SETTLED_;

    // ============ Core Address ============

    IERC20 public _BASE_TOKEN_;
    IERC20 public _QUOTE_TOKEN_;

    // ============ Distribution Parameters ============

    uint256 public _TOTAL_BASE_;
    uint256 public _POOL_QUOTE_CAP_;

    // ============ Settlement ============

    uint256 public _QUOTE_RESERVE_;

    uint256 public _UNUSED_BASE_;
    uint256 public _UNUSED_QUOTE_;

    uint256 public _TOTAL_SHARES_;
    mapping(address => uint256) internal _SHARES_;
    mapping(address => bool) public _CLAIMED_;

    address public _POOL_FACTORY_;
    address public _POOL_;
    uint256 public _AVG_SETTLED_PRICE_;

    // ============ Advanced Control ============

    address public _MAINTAINER_;
    IFeeRateModel public _MT_FEE_RATE_MODEL_;
    IPermissionManager public _BIDDER_PERMISSION_;

    // ============ PMM Parameters ============

    uint256 public _K_;
    uint256 public _I_;

    // ============ LP Token Vesting ============

    uint256 public _TOTAL_LP_AMOUNT_;
    uint256 public _FREEZE_DURATION_;
    uint256 public _VESTING_DURATION_;
    uint256 public _CLIFF_RATE_;

    // ============ Modifiers ============

    modifier phaseBid() {
        require(
            block.timestamp >= _PHASE_BID_STARTTIME_ && block.timestamp < _PHASE_BID_ENDTIME_,
            "NOT_PHASE_BID"
        );
        _;
    }

    modifier phaseCalm() {
        require(
            block.timestamp >= _PHASE_BID_ENDTIME_ && block.timestamp < _PHASE_CALM_ENDTIME_,
            "NOT_PHASE_CALM"
        );
        _;
    }

    modifier phaseBidOrCalm() {
        require(
            block.timestamp >= _PHASE_BID_STARTTIME_ && block.timestamp < _PHASE_CALM_ENDTIME_,
            "NOT_PHASE_BID_OR_CALM"
        );
        _;
    }

    modifier phaseSettlement() {
        require(block.timestamp >= _PHASE_CALM_ENDTIME_, "NOT_PHASE_EXE");
        _;
    }

    modifier phaseVesting() {
        require(_SETTLED_, "NOT_VESTING");
        _;
    }
}

// File: contracts/lib/DODOMath.sol

/**
 * @title DODOMath
 * @author DODO Breeder
 *
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library DODOMath {
    using SafeMath for uint256;

    /*
        Integrate dodo curve from V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))

        i is the price of V-res trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        uint256 fairAmount = i.mul(V1.sub(V2)); // i*delta
        if (k == 0) {
            return fairAmount.div(DecimalMath.ONE);
        }
        uint256 V0V0V1V2 = DecimalMath.divFloor(V0.mul(V0).div(V1), V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return DecimalMath.ONE.sub(k).add(penalty).mul(fairAmount).div(DecimalMath.ONE2);
    }

    /*
        Follow the integration function above
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0

        i is the price of delta-V trading pair
        give out target of V

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTarget(
        uint256 V1,
        uint256 delta,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        if (V1 == 0) {
            return 0;
        }
        if (k == 0) {
            return V1.add(DecimalMath.mulFloor(i, delta));
        }
        // V0 = V1*(1+(sqrt-1)/2k)
        // sqrt = √(1+4kidelta/V1)
        // premium = 1+(sqrt-1)/2k
        // uint256 sqrt = (4 * k).mul(i).mul(delta).div(V1).add(DecimalMath.ONE2).sqrt();
        uint256 sqrt;
        uint256 ki = (4 * k).mul(i);
        if (ki == 0) {
            sqrt = DecimalMath.ONE;
        } else if ((ki * delta) / ki == delta) {
            sqrt = (ki * delta).div(V1).add(DecimalMath.ONE2).sqrt();
        } else {
            sqrt = ki.div(V1).mul(delta).add(DecimalMath.ONE2).sqrt();
        }
        uint256 premium =
            DecimalMath.divFloor(sqrt.sub(DecimalMath.ONE), k * 2).add(DecimalMath.ONE);
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mulFloor(V1, premium);
    }

    /*
        Follow the integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2 
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan

        if deltaBSig=true, then Q2>Q1, user sell Q and receive B
        if deltaBSig=false, then Q2<Q1, user sell B and receive Q
        return |Q1-Q2|

        as we only support sell amount as delta, the deltaB is always negative
        the input ideltaB is actually -ideltaB in the equation

        i is the price of delta-V trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 V0,
        uint256 V1,
        uint256 delta,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        if (delta == 0) {
            return 0;
        }

        if (k == 0) {
            return DecimalMath.mulFloor(i, delta) > V1 ? V1 : DecimalMath.mulFloor(i, delta);
        }

        if (k == DecimalMath.ONE) {
            // if k==1
            // Q2=Q1/(1+ideltaBQ1/Q0/Q0)
            // temp = ideltaBQ1/Q0/Q0
            // Q2 = Q1/(1+temp)
            // Q1-Q2 = Q1*(1-1/(1+temp)) = Q1*(temp/(1+temp))
            // uint256 temp = i.mul(delta).mul(V1).div(V0.mul(V0));
            uint256 temp;
            uint256 idelta = i.mul(delta);
            if (idelta == 0) {
                temp = 0;
            } else if ((idelta * V1) / idelta == V1) {
                temp = (idelta * V1).div(V0.mul(V0));
            } else {
                temp = delta.mul(V1).div(V0).mul(i).div(V0);
            }
            return V1.mul(temp).div(temp.add(DecimalMath.ONE));
        }

        // calculate -b value and sig
        // b = kQ0^2/Q1-i*deltaB-(1-k)Q1
        // part1 = (1-k)Q1 >=0
        // part2 = kQ0^2/Q1-i*deltaB >=0
        // bAbs = abs(part1-part2)
        // if part1>part2 => b is negative => bSig is false
        // if part2>part1 => b is positive => bSig is true
        uint256 part2 = k.mul(V0).div(V1).mul(V0).add(i.mul(delta)); // kQ0^2/Q1-i*deltaB
        uint256 bAbs = DecimalMath.ONE.sub(k).mul(V1); // (1-k)Q1

        bool bSig;
        if (bAbs >= part2) {
            bAbs = bAbs - part2;
            bSig = false;
        } else {
            bAbs = part2 - bAbs;
            bSig = true;
        }
        bAbs = bAbs.div(DecimalMath.ONE);

        // calculate sqrt
        uint256 squareRoot =
            DecimalMath.mulFloor(
                DecimalMath.ONE.sub(k).mul(4),
                DecimalMath.mulFloor(k, V0).mul(V0)
            ); // 4(1-k)kQ0^2
        squareRoot = bAbs.mul(bAbs).add(squareRoot).sqrt(); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = DecimalMath.ONE.sub(k).mul(2); // 2(1-k)
        uint256 numerator;
        if (bSig) {
            numerator = squareRoot.sub(bAbs);
        } else {
            numerator = bAbs.add(squareRoot);
        }

        uint256 V2 = DecimalMath.divCeil(numerator, denominator);
        if (V2 > V1) {
            return 0;
        } else {
            return V1 - V2;
        }
    }
}

// File: contracts/lib/PMMPricing.sol


/**
 * @title Pricing
 * @author DODO Breeder
 *
 * @notice DODO Pricing model
 */

library PMMPricing {
    using SafeMath for uint256;

    enum RState {ONE, ABOVE_ONE, BELOW_ONE}

    struct PMMState {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 Q;
        uint256 B0;
        uint256 Q0;
        RState R;
    }

    // ============ buy & sell ============

    function sellBaseToken(PMMState memory state, uint256 payBaseAmount)
        internal
        pure
        returns (uint256 receiveQuoteAmount, RState newR)
    {
        if (state.R == RState.ONE) {
            // case 1: R=1
            // R falls below one
            receiveQuoteAmount = _ROneSellBaseToken(state, payBaseAmount);
            newR = RState.BELOW_ONE;
        } else if (state.R == RState.ABOVE_ONE) {
            uint256 backToOnePayBase = state.B0.sub(state.B);
            uint256 backToOneReceiveQuote = state.Q.sub(state.Q0);
            // case 2: R>1
            // complex case, R status depends on trading amount
            if (payBaseAmount < backToOnePayBase) {
                // case 2.1: R status do not change
                receiveQuoteAmount = _RAboveSellBaseToken(state, payBaseAmount);
                newR = RState.ABOVE_ONE;
                if (receiveQuoteAmount > backToOneReceiveQuote) {
                    // [Important corner case!] may enter this branch when some precision problem happens. And consequently contribute to negative spare quote amount
                    // to make sure spare quote>=0, mannually set receiveQuote=backToOneReceiveQuote
                    receiveQuoteAmount = backToOneReceiveQuote;
                }
            } else if (payBaseAmount == backToOnePayBase) {
                // case 2.2: R status changes to ONE
                receiveQuoteAmount = backToOneReceiveQuote;
                newR = RState.ONE;
            } else {
                // case 2.3: R status changes to BELOW_ONE
                receiveQuoteAmount = backToOneReceiveQuote.add(
                    _ROneSellBaseToken(state, payBaseAmount.sub(backToOnePayBase))
                );
                newR = RState.BELOW_ONE;
            }
        } else {
            // state.R == RState.BELOW_ONE
            // case 3: R<1
            receiveQuoteAmount = _RBelowSellBaseToken(state, payBaseAmount);
            newR = RState.BELOW_ONE;
        }
    }

    function sellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (uint256 receiveBaseAmount, RState newR)
    {
        if (state.R == RState.ONE) {
            receiveBaseAmount = _ROneSellQuoteToken(state, payQuoteAmount);
            newR = RState.ABOVE_ONE;
        } else if (state.R == RState.ABOVE_ONE) {
            receiveBaseAmount = _RAboveSellQuoteToken(state, payQuoteAmount);
            newR = RState.ABOVE_ONE;
        } else {
            uint256 backToOnePayQuote = state.Q0.sub(state.Q);
            uint256 backToOneReceiveBase = state.B.sub(state.B0);
            if (payQuoteAmount < backToOnePayQuote) {
                receiveBaseAmount = _RBelowSellQuoteToken(state, payQuoteAmount);
                newR = RState.BELOW_ONE;
                if (receiveBaseAmount > backToOneReceiveBase) {
                    receiveBaseAmount = backToOneReceiveBase;
                }
            } else if (payQuoteAmount == backToOnePayQuote) {
                receiveBaseAmount = backToOneReceiveBase;
                newR = RState.ONE;
            } else {
                receiveBaseAmount = backToOneReceiveBase.add(
                    _ROneSellQuoteToken(state, payQuoteAmount.sub(backToOnePayQuote))
                );
                newR = RState.ABOVE_ONE;
            }
        }
    }

    // ============ R = 1 cases ============

    function _ROneSellBaseToken(PMMState memory state, uint256 payBaseAmount)
        internal
        pure
        returns (
            uint256 // receiveQuoteToken
        )
    {
        // in theory Q2 <= targetQuoteTokenAmount
        // however when amount is close to 0, precision problems may cause Q2 > targetQuoteTokenAmount
        return
            DODOMath._SolveQuadraticFunctionForTrade(
                state.Q0,
                state.Q0,
                payBaseAmount,
                state.i,
                state.K
            );
    }

    function _ROneSellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (
            uint256 // receiveBaseToken
        )
    {
        return
            DODOMath._SolveQuadraticFunctionForTrade(
                state.B0,
                state.B0,
                payQuoteAmount,
                DecimalMath.reciprocalFloor(state.i),
                state.K
            );
    }

    // ============ R < 1 cases ============

    function _RBelowSellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (
            uint256 // receiveBaseToken
        )
    {
        return
            DODOMath._GeneralIntegrate(
                state.Q0,
                state.Q.add(payQuoteAmount),
                state.Q,
                DecimalMath.reciprocalFloor(state.i),
                state.K
            );
    }

    function _RBelowSellBaseToken(PMMState memory state, uint256 payBaseAmount)
        internal
        pure
        returns (
            uint256 // receiveQuoteToken
        )
    {
        return
            DODOMath._SolveQuadraticFunctionForTrade(
                state.Q0,
                state.Q,
                payBaseAmount,
                state.i,
                state.K
            );
    }

    // ============ R > 1 cases ============

    function _RAboveSellBaseToken(PMMState memory state, uint256 payBaseAmount)
        internal
        pure
        returns (
            uint256 // receiveQuoteToken
        )
    {
        return
            DODOMath._GeneralIntegrate(
                state.B0,
                state.B.add(payBaseAmount),
                state.B,
                state.i,
                state.K
            );
    }

    function _RAboveSellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (
            uint256 // receiveBaseToken
        )
    {
        return
            DODOMath._SolveQuadraticFunctionForTrade(
                state.B0,
                state.B,
                payQuoteAmount,
                DecimalMath.reciprocalFloor(state.i),
                state.K
            );
    }

    // ============ Helper functions ============

    function adjustedTarget(PMMState memory state) internal pure {
        if (state.R == RState.BELOW_ONE) {
            state.Q0 = DODOMath._SolveQuadraticFunctionForTarget(
                state.Q,
                state.B.sub(state.B0),
                state.i,
                state.K
            );
        } else if (state.R == RState.ABOVE_ONE) {
            state.B0 = DODOMath._SolveQuadraticFunctionForTarget(
                state.B,
                state.Q.sub(state.Q0),
                DecimalMath.reciprocalFloor(state.i),
                state.K
            );
        }
    }

    function getMidPrice(PMMState memory state) internal pure returns (uint256) {
        if (state.R == RState.BELOW_ONE) {
            uint256 R = DecimalMath.divFloor(state.Q0.mul(state.Q0).div(state.Q), state.Q);
            R = DecimalMath.ONE.sub(state.K).add(DecimalMath.mulFloor(state.K, R));
            return DecimalMath.divFloor(state.i, R);
        } else {
            uint256 R = DecimalMath.divFloor(state.B0.mul(state.B0).div(state.B), state.B);
            R = DecimalMath.ONE.sub(state.K).add(DecimalMath.mulFloor(state.K, R));
            return DecimalMath.mulFloor(state.i, R);
        }
    }
}

// File: contracts/intf/IDODOCallee.sol


interface IDODOCallee {
    function DVMSellShareCall(
        address sender,
        uint256 burnShareAmount,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;

    function CPCancelCall(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external;

	function CPClaimBidCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;
}

// File: contracts/CrowdPooling/impl/CPFunding.sol





contract CPFunding is CPStorage {
    using SafeERC20 for IERC20;
    
    // ============ Events ============
    
    event Bid(address to, uint256 amount, uint256 fee);
    event Cancel(address to,uint256 amount);
    event Settle();

    // ============ BID & CALM PHASE ============
    
    modifier isBidderAllow(address bidder) {
        require(_BIDDER_PERMISSION_.isAllowed(bidder), "BIDDER_NOT_ALLOWED");
        _;
    }

    function bid(address to) external phaseBid preventReentrant isBidderAllow(to) {
        uint256 input = _getQuoteInput();
        uint256 mtFee = DecimalMath.mulFloor(input, _MT_FEE_RATE_MODEL_.getFeeRate(to));
        _transferQuoteOut(_MAINTAINER_, mtFee);
        _mintShares(to, input.sub(mtFee));
        _sync();
        emit Bid(to, input, mtFee);
    }

    function cancel(address to, uint256 amount, bytes calldata data) external phaseBidOrCalm preventReentrant {
        require(_SHARES_[msg.sender] >= amount, "SHARES_NOT_ENOUGH");
        _burnShares(msg.sender, amount);
        _transferQuoteOut(to, amount);
        _sync();

        if(data.length > 0){
            IDODOCallee(to).CPCancelCall(msg.sender,amount,data);
        }

        emit Cancel(msg.sender,amount);
    }

    function _mintShares(address to, uint256 amount) internal {
        _SHARES_[to] = _SHARES_[to].add(amount);
        _TOTAL_SHARES_ = _TOTAL_SHARES_.add(amount);
    }

    function _burnShares(address from, uint256 amount) internal {
        _SHARES_[from] = _SHARES_[from].sub(amount);
        _TOTAL_SHARES_ = _TOTAL_SHARES_.sub(amount);
    }

    // ============ SETTLEMENT ============

    function settle() external phaseSettlement preventReentrant {
        _settle();

        (uint256 poolBase, uint256 poolQuote, uint256 poolI, uint256 unUsedBase, uint256 unUsedQuote) = getSettleResult();
        _UNUSED_BASE_ = unUsedBase;
        _UNUSED_QUOTE_ = unUsedQuote;

        address _poolBaseToken;
        address _poolQuoteToken;

        if (_UNUSED_BASE_ > poolBase) {
            _poolBaseToken = address(_QUOTE_TOKEN_);
            _poolQuoteToken = address(_BASE_TOKEN_);
        } else {
            _poolBaseToken = address(_BASE_TOKEN_);
            _poolQuoteToken = address(_QUOTE_TOKEN_);
        }

        _POOL_ = IDVMFactory(_POOL_FACTORY_).createDODOVendingMachine(
            _poolBaseToken,
            _poolQuoteToken,
            3e15, // 0.3% lp feeRate
            poolI,
            DecimalMath.ONE,
            _IS_OPEN_TWAP_
        );

        uint256 avgPrice = unUsedBase == 0 ? _I_ : DecimalMath.divCeil(poolQuote, unUsedBase);
        _AVG_SETTLED_PRICE_ = avgPrice;

        _transferBaseOut(_POOL_, poolBase);
        _transferQuoteOut(_POOL_, poolQuote);

        (_TOTAL_LP_AMOUNT_, ,) = IDVM(_POOL_).buyShares(address(this));

        msg.sender.transfer(_SETTEL_FUND_);

        emit Settle();
    }

    // in case something wrong with base token contract
    function emergencySettle() external phaseSettlement preventReentrant {
        require(block.timestamp >= _PHASE_CALM_ENDTIME_.add(_SETTLEMENT_EXPIRE_), "NOT_EMERGENCY");
        _settle();
        _UNUSED_QUOTE_ = _QUOTE_TOKEN_.balanceOf(address(this));
    }

    function _settle() internal {
        require(!_SETTLED_, "ALREADY_SETTLED");
        _SETTLED_ = true;
        _SETTLED_TIME_ = block.timestamp;
    }

    // ============ Pricing ============

    function getSettleResult() public view returns (uint256 poolBase, uint256 poolQuote, uint256 poolI, uint256 unUsedBase, uint256 unUsedQuote) {
        poolQuote = _QUOTE_TOKEN_.balanceOf(address(this));
        if (poolQuote > _POOL_QUOTE_CAP_) {
            poolQuote = _POOL_QUOTE_CAP_;
        }
        (uint256 soldBase,) = PMMPricing.sellQuoteToken(_getPMMState(), poolQuote);
        poolBase = _TOTAL_BASE_.sub(soldBase);

        unUsedQuote = _QUOTE_TOKEN_.balanceOf(address(this)).sub(poolQuote);
        unUsedBase = _BASE_TOKEN_.balanceOf(address(this)).sub(poolBase);

        // Try to make midPrice equal to avgPrice
        // k=1, If quote and base are not balanced, one side must be cut off
        // DVM truncated quote, but if more quote than base entering the pool, we need set the quote to the base

        // m = avgPrice
        // i = m (1-quote/(m*base))
        // if quote = m*base i = 1
        // if quote > m*base reverse
        uint256 avgPrice = unUsedBase == 0 ? _I_ : DecimalMath.divCeil(poolQuote, unUsedBase);
        uint256 baseDepth = DecimalMath.mulFloor(avgPrice, poolBase);

        if (poolQuote == 0) {
            // ask side only DVM
            poolI = _I_;
        } else if (unUsedBase== poolBase) {
            // standard bonding curve
            poolI = 1;
        } else if (unUsedBase < poolBase) {
            // poolI up round
            uint256 ratio = DecimalMath.ONE.sub(DecimalMath.divFloor(poolQuote, baseDepth));
            poolI = avgPrice.mul(ratio).mul(ratio).divCeil(DecimalMath.ONE2);
        } else if (unUsedBase > poolBase) {
            // poolI down round
            uint256 ratio = DecimalMath.ONE.sub(DecimalMath.divCeil(baseDepth, poolQuote));
            poolI = ratio.mul(ratio).div(avgPrice);
        }
    }

    function _getPMMState() internal view returns (PMMPricing.PMMState memory state) {
        state.i = _I_;
        state.K = _K_;
        state.B = _TOTAL_BASE_;
        state.Q = 0;
        state.B0 = state.B;
        state.Q0 = 0;
        state.R = PMMPricing.RState.ONE;
    }

    function getExpectedAvgPrice() external view returns (uint256) {
        require(!_SETTLED_, "ALREADY_SETTLED");
        (uint256 poolBase, uint256 poolQuote, , , ) = getSettleResult();
        return DecimalMath.divCeil(poolQuote, _BASE_TOKEN_.balanceOf(address(this)).sub(poolBase));
    }

    // ============ Asset In ============

    function _getQuoteInput() internal view returns (uint256 input) {
        return _QUOTE_TOKEN_.balanceOf(address(this)).sub(_QUOTE_RESERVE_);
    }

    // ============ Set States ============

    function _sync() internal {
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));
        if (quoteBalance != _QUOTE_RESERVE_) {
            _QUOTE_RESERVE_ = quoteBalance;
        }
    }

    // ============ Asset Out ============

    function _transferBaseOut(address to, uint256 amount) internal {
        if (amount > 0) {
            _BASE_TOKEN_.safeTransfer(to, amount);
        }
    }

    function _transferQuoteOut(address to, uint256 amount) internal {
        if (amount > 0) {
            _QUOTE_TOKEN_.safeTransfer(to, amount);
        }
    }

    function getShares(address user) external view returns (uint256) {
        return _SHARES_[user];
    }
}

// File: contracts/CrowdPooling/impl/CPVesting.sol





/**
 * @title CPVesting
 * @author DODO Breeder
 *
 * @notice Lock Token and release it linearly
 */

contract CPVesting is CPFunding {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Events ============
    
    event Claim(address user, uint256 baseAmount, uint256 quoteAmount);
    event ClaimLP(uint256 amount);


    // ================ Modifiers ================

    modifier afterSettlement() {
        require(_SETTLED_, "NOT_SETTLED");
        _;
    }

    modifier afterFreeze() {
        require(_SETTLED_ && block.timestamp >= _SETTLED_TIME_.add(_FREEZE_DURATION_), "FREEZED");
        _;
    }

    // ============ Bidder Functions ============

    function bidderClaim(address to,bytes calldata data) external afterSettlement {
        require(!_CLAIMED_[msg.sender], "ALREADY_CLAIMED");
        _CLAIMED_[msg.sender] = true;

		uint256 baseAmount = _UNUSED_BASE_.mul(_SHARES_[msg.sender]).div(_TOTAL_SHARES_);
		uint256 quoteAmount = _UNUSED_QUOTE_.mul(_SHARES_[msg.sender]).div(_TOTAL_SHARES_);

        _transferBaseOut(to, baseAmount);
        _transferQuoteOut(to, quoteAmount);

		if(data.length>0){
			IDODOCallee(to).CPClaimBidCall(msg.sender,baseAmount,quoteAmount,data);
		}

        emit Claim(msg.sender, baseAmount, quoteAmount);
    }

    // ============ Owner Functions ============

    function claimLPToken() external onlyOwner afterFreeze {
        uint256 lpAmount = getClaimableLPToken();
        IERC20(_POOL_).safeTransfer(_OWNER_, lpAmount);
        emit ClaimLP(lpAmount);
    }

    function getClaimableLPToken() public view afterFreeze returns (uint256) {
        uint256 remainingLPToken = DecimalMath.mulFloor(
            getRemainingLPRatio(block.timestamp),
            _TOTAL_LP_AMOUNT_
        );
        return IERC20(_POOL_).balanceOf(address(this)).sub(remainingLPToken);
    }

    function getRemainingLPRatio(uint256 timestamp) public view afterFreeze returns (uint256) {
        uint256 timePast = timestamp.sub(_SETTLED_TIME_.add(_FREEZE_DURATION_));
        if (timePast < _VESTING_DURATION_) {
            uint256 remainingTime = _VESTING_DURATION_.sub(timePast);
            return DecimalMath.ONE.sub(_CLIFF_RATE_).mul(remainingTime).div(_VESTING_DURATION_);
        } else {
            return 0;
        }
    }
}

// File: contracts/CrowdPooling/impl/CP.sol



/**
 * @title DODO CrowdPooling
 * @author DODO Breeder
 *
 * @notice CrowdPooling initialization
 */
contract CP is CPVesting {
    using SafeMath for uint256;

    receive() external payable {}

    function init(
        address[] calldata addressList,
        uint256[] calldata timeLine,
        uint256[] calldata valueList,
        bool isOpenTWAP
    ) external {
        /*
        Address List
        0. owner
        1. maintainer
        2. baseToken
        3. quoteToken
        4. permissionManager
        5. feeRateModel
        6. poolFactory
      */

        require(addressList.length == 7, "LIST_LENGTH_WRONG");

        initOwner(addressList[0]);
        _MAINTAINER_ = addressList[1];
        _BASE_TOKEN_ = IERC20(addressList[2]);
        _QUOTE_TOKEN_ = IERC20(addressList[3]);
        _BIDDER_PERMISSION_ = IPermissionManager(addressList[4]);
        _MT_FEE_RATE_MODEL_ = IFeeRateModel(addressList[5]);
        _POOL_FACTORY_ = addressList[6];

        /*
        Time Line
        0. phase bid starttime
        1. phase bid duration
        2. phase calm duration
        3. freeze duration
        4. vesting duration
        */

        require(timeLine.length == 5, "LIST_LENGTH_WRONG");

        _PHASE_BID_STARTTIME_ = timeLine[0];
        _PHASE_BID_ENDTIME_ = _PHASE_BID_STARTTIME_.add(timeLine[1]);
        _PHASE_CALM_ENDTIME_ = _PHASE_BID_ENDTIME_.add(timeLine[2]);

        _FREEZE_DURATION_ = timeLine[3];
        _VESTING_DURATION_ = timeLine[4];

        require(block.timestamp <= _PHASE_BID_STARTTIME_, "TIMELINE_WRONG");

        /*
        Value List
        0. pool quote cap
        1. k
        2. i
        3. cliff rate
        */

        require(valueList.length == 4, "LIST_LENGTH_WRONG");

        _POOL_QUOTE_CAP_ = valueList[0];
        _K_ = valueList[1];
        _I_ = valueList[2];
        _CLIFF_RATE_ = valueList[3];

        require(_I_ > 0 && _I_ <= 1e36, "I_VALUE_WRONG");
        require(_K_ <= 1e18, "K_VALUE_WRONG");
        require(_CLIFF_RATE_ <= 1e18, "CLIFF_RATE_WRONG");

        _TOTAL_BASE_ = _BASE_TOKEN_.balanceOf(address(this));

        _IS_OPEN_TWAP_ = isOpenTWAP;

        require(address(this).balance == _SETTEL_FUND_, "SETTLE_FUND_NOT_MATCH");
    }
}