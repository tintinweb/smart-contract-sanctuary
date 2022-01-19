/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

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

// File: contracts/DODOFee/UserQuota.sol



interface IQuota {
    function getUserQuota(address user) external view returns (int);
}

contract UserQuota is InitializableOwnable, IQuota {

    mapping(address => uint256) public userQuota;
    
    event SetQuota(address user, uint256 amount);

    function setUserQuota(address[] memory users, uint256[] memory quotas) external onlyOwner {
        require(users.length == quotas.length, "PARAMS_LENGTH_NOT_MATCH");
        for(uint256 i = 0; i< users.length; i++) {
            require(users[i] != address(0), "USER_INVALID");
            userQuota[users[i]] = quotas[i];
            // emit SetQuota(users[i],quotas[i]);
        }
    }

    function getUserQuota(address user) override external view returns (int) {
        return int(userQuota[user]);
    }
}

// File: contracts/lib/SafeMath.sol



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

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e.div(2));
            p = p.mul(p) / (10**18);
            if (e % 2 == 1) {
                p = p.mul(target) / (10**18);
            }
            return p;
        }
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

// File: contracts/DODOStarter/impl/Storage.sol



contract Storage is InitializableOwnable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public _FORCE_STOP_ = false;
    address public _QUOTA_; 

    // ============ Token & Balance ============

    uint256 public _FUNDS_RESERVE_;
    address public _FUNDS_ADDRESS_;
    address public _TOKEN_ADDRESS_;
    uint256 public _TOTAL_TOKEN_AMOUNT_;

    uint256 public _TOTAL_RAISED_FUNDS_;
    
    // ============ Vesting Timeline ============

    uint256 public _TOKEN_VESTING_START_;
    uint256 public _TOKEN_VESTING_DURATION_;
    uint256 public _TOKEN_CLIFF_RATE_;
    mapping(address => uint256) _CLAIMED_TOKEN_;

    uint256 public _FUNDS_VESTING_START_;
    uint256 public _FUNDS_VESTING_DURATION_;
    uint256 public _FUNDS_CLIFF_RATE_;
    uint256 _CLAIMED_FUNDS_;

    uint256 public _LP_VESTING_START_;
    uint256 public _LP_VESTING_DURATION_;
    uint256 public _LP_CLIFF_RATE_;
    uint256 _CLAIMED_LP_;

    // ============ Liquidity Params ============

    address public _POOL_FACTORY_;
    address public _INITIAL_POOL_;
    uint256 public _INITIAL_FUND_LIQUIDITY_;
    uint256 public _TOTAL_LP_;
    
    // ============ Timeline ==============
    uint256 public _START_TIME_;
    uint256 public _BIDDING_DURATION_;


    // ============ Modifiers ============
    modifier isNotForceStop() {
        require(!_FORCE_STOP_, "FORCE_STOP");
        _;
    }

    // ============ Ownable Control ============
    function forceStop() external onlyOwner {
        require(block.timestamp < _START_TIME_, "FUNDING_ALREADY_STARTED");
        _FORCE_STOP_ = true;
        _TOTAL_TOKEN_AMOUNT_ = 0;
        uint256 tokenAmount = IERC20(_TOKEN_ADDRESS_).balanceOf(address(this));
        IERC20(_TOKEN_ADDRESS_).safeTransfer(_OWNER_, tokenAmount);
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

    function addressToShortString(address _addr) external pure returns (string memory);

    function getMidPrice() external view returns (uint256 midPrice);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        bytes calldata data,
        uint256 deadline
    ) external  returns (uint256 baseAmount, uint256 quoteAmount);

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
    address public immutable _DEFAULT_MT_FEE_RATE_MODEL_;
    address public _DEFAULT_MAINTAINER_;
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
    
    function updateDefaultMaintainer(address _newMaintainer) external onlyOwner {
        _DEFAULT_MAINTAINER_ = _newMaintainer;
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

// File: contracts/DODOStarter/impl/Vesting.sol



contract Vesting is Storage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function claimLp(address to) external preventReentrant onlyOwner {
        require(_INITIAL_POOL_ != address(0), "LIQUIDITY_NOT_ESTABLISHED");
        uint256 remainingLp = DecimalMath.mulFloor(
            getRemainingRatio(block.timestamp,2),
            _TOTAL_LP_
        );
        uint256 claimableLp = _TOTAL_LP_.sub(remainingLp).sub(_CLAIMED_LP_);

        _CLAIMED_LP_ = _CLAIMED_LP_.add(claimableLp);
        IERC20(_INITIAL_POOL_).safeTransfer(to, claimableLp);
    }

    //tokenType 0: BaseToken, 1: Fund, 2: LpToken
    function getRemainingRatio(uint256 timestamp, uint256 tokenType) public view returns (uint256) {
        uint256 vestingStart;
        uint256 vestingDuration;
        uint256 cliffRate;

        if(tokenType == 0) {
            vestingStart = _TOKEN_VESTING_START_;
            vestingDuration = _TOKEN_VESTING_DURATION_;
            cliffRate = _TOKEN_CLIFF_RATE_;
        } else if(tokenType == 1) {
            vestingStart = _FUNDS_VESTING_START_;
            vestingDuration = _FUNDS_VESTING_DURATION_;
            cliffRate = _FUNDS_CLIFF_RATE_;
        } else {
            vestingStart = _LP_VESTING_START_;
            vestingDuration = _LP_VESTING_DURATION_;
            cliffRate = _LP_CLIFF_RATE_;
        }

        require(timestamp >= vestingStart, "NOT_START_TO_CLAIM");

        uint256 timePast = timestamp.sub(vestingStart);
        if (timePast < vestingDuration) {
            uint256 remainingTime = vestingDuration.sub(timePast);
            return DecimalMath.ONE.sub(cliffRate).mul(remainingTime).div(vestingDuration);
        } else {
            return 0;
        }
    }


    // ============ Internal Function ============
    function _claimToken(address to, uint256 totalAllocation) internal {
        uint256 remainingToken = DecimalMath.mulFloor(
            getRemainingRatio(block.timestamp,0),
            totalAllocation
        );
        uint256 claimableTokenAmount = totalAllocation.sub(remainingToken).sub(_CLAIMED_TOKEN_[msg.sender]);
        _CLAIMED_TOKEN_[msg.sender] = _CLAIMED_TOKEN_[msg.sender].add(claimableTokenAmount);
        IERC20(_TOKEN_ADDRESS_).safeTransfer(to,claimableTokenAmount);
    }

    function _claimFunds(address to, uint256 totalUsedRaiseFunds) internal {
        require(totalUsedRaiseFunds > _INITIAL_FUND_LIQUIDITY_, "FUND_NOT_ENOUGH");
        uint256 vestingFunds = totalUsedRaiseFunds.sub(_INITIAL_FUND_LIQUIDITY_);
        uint256 remainingFund = DecimalMath.mulFloor(
            getRemainingRatio(block.timestamp,1),
            vestingFunds
        );
        uint256 claimableFund = vestingFunds.sub(remainingFund).sub(_CLAIMED_FUNDS_);
        _CLAIMED_FUNDS_ = _CLAIMED_FUNDS_.add(claimableFund);
        IERC20(_FUNDS_ADDRESS_).safeTransfer(to, claimableFund);
    }

    function _initializeLiquidity(uint256 initialTokenAmount, uint256 totalUsedRaiseFunds, uint256 lpFeeRate, bool isOpenTWAP) internal {
        _INITIAL_POOL_ = IDVMFactory(_POOL_FACTORY_).createDODOVendingMachine(
            _TOKEN_ADDRESS_,
            _FUNDS_ADDRESS_,
            lpFeeRate,
            1,
            DecimalMath.ONE,
            isOpenTWAP
        );
        IERC20(_TOKEN_ADDRESS_).safeTransferFrom(msg.sender, _INITIAL_POOL_, initialTokenAmount);
        
        if(totalUsedRaiseFunds > _INITIAL_FUND_LIQUIDITY_) {
            IERC20(_FUNDS_ADDRESS_).safeTransfer(_INITIAL_POOL_, _INITIAL_FUND_LIQUIDITY_);
        }else {
            IERC20(_FUNDS_ADDRESS_).safeTransfer(_INITIAL_POOL_, totalUsedRaiseFunds);
        }
        
        (_TOTAL_LP_, , ) = IDVM(_INITIAL_POOL_).buyShares(address(this));
    }
}

// File: contracts/DODOStarter/impl/FairFunding.sol



contract FairFunding is Vesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant _SETTEL_FUND_ = 200 finney;
    // ============ Fair Mode ============
    uint256 public _COOLING_DURATION_;

    mapping(address => uint256) _FUNDS_DEPOSITED_;
    mapping(address => bool) _FUNDS_CLAIMED_;
    uint256 public _USED_FUND_RATIO_;
    uint256 public _FINAL_PRICE_;

    uint256 public _LOWER_LIMIT_PRICE_;
    uint256 public _UPPER_LIMIT_PRICE_;

    bool public _IS_OVERCAP_STOP = false;

    receive() external payable {
        require(_INITIALIZED_ == false, "WE_NOT_SAVE_ETH_AFTER_INIT");
    }

    // ============ Init ============
    function init(
        address[] calldata addressList,
        uint256[] calldata timeLine,
        uint256[] calldata valueList,
        bool isOverCapStop
    ) external {
        /*
        Address List
        0. owner
        1. sellToken
        2. fundToken
        3. quotaManager
        4. poolFactory
      */

        require(addressList.length == 5, "ADDR_LENGTH_WRONG");

        initOwner(addressList[0]);
        _TOKEN_ADDRESS_ = addressList[1];
        _FUNDS_ADDRESS_ = addressList[2];
        _QUOTA_ = addressList[3];
        _POOL_FACTORY_ = addressList[4];

        /*
        Time Line
        0. starttime
        1. bid duration
        2. calm duration
        3. token vesting starttime
        4. token vesting duration
        5. fund vesting starttime
        6. fund vesting duration
        7. lp vesting starttime
        8. lp vesting duration
        */

        require(timeLine.length == 9, "TIME_LENGTH_WRONG");

        _START_TIME_ = timeLine[0];
        _BIDDING_DURATION_ = timeLine[1];
        _COOLING_DURATION_ = timeLine[2];

        _TOKEN_VESTING_START_ = timeLine[3];
        _TOKEN_VESTING_DURATION_ = timeLine[4];

        _FUNDS_VESTING_START_ = timeLine[5];
        _FUNDS_VESTING_DURATION_ = timeLine[6];

        _LP_VESTING_START_ = timeLine[7];
        _LP_VESTING_DURATION_ = timeLine[8];

        require(block.timestamp <= _START_TIME_, "START_TIME_WRONG");
        require(_START_TIME_.add(_BIDDING_DURATION_).add(_COOLING_DURATION_) <= _TOKEN_VESTING_START_, "TOKEN_VESTING_TIME_WRONG");
        require(_START_TIME_.add(_BIDDING_DURATION_).add(_COOLING_DURATION_) <= _FUNDS_VESTING_START_, "FUND_VESTING_TIME_WRONG");
        require(_START_TIME_.add(_BIDDING_DURATION_).add(_COOLING_DURATION_) <= _LP_VESTING_START_, "LP_VESTING_TIME_WRONG");

        /*
        Value List
        0. lower price
        1. upper price
        2. token cliffRate
        3. fund cliffRate
        4. lp cliffRate
        5. initial liquidity
        */

        require(valueList.length == 6, "VALUE_LENGTH_WRONG");

        _LOWER_LIMIT_PRICE_ = valueList[0];
        _UPPER_LIMIT_PRICE_ = valueList[1];

        _TOKEN_CLIFF_RATE_ = valueList[2];
        _FUNDS_CLIFF_RATE_ = valueList[3];
        _LP_CLIFF_RATE_ = valueList[4];

        _INITIAL_FUND_LIQUIDITY_ = valueList[5];

        require(_LOWER_LIMIT_PRICE_ > 0, "LOWER_PRICE_WRONG");
        require(_LOWER_LIMIT_PRICE_ <= _UPPER_LIMIT_PRICE_, "PRICE_WRONG");
        require(_TOKEN_CLIFF_RATE_ <= 1e18, "TOKEN_CLIFF_RATE_WRONG");
        require(_FUNDS_CLIFF_RATE_ <= 1e18, "FUND_CLIFF_RATE_WRONG");
        require(_LP_CLIFF_RATE_ <= 1e18, "LP_CLIFF_RATE_WRONG");

        _IS_OVERCAP_STOP = isOverCapStop;

        _TOTAL_TOKEN_AMOUNT_ = IERC20(_TOKEN_ADDRESS_).balanceOf(address(this));

        require(_TOTAL_TOKEN_AMOUNT_ > 0, "NO_TOKEN_TRANSFERED");
        require(address(this).balance == _SETTEL_FUND_, "SETTLE_FUND_NOT_MATCH");
    }

    // ============ View Functions ============

    function getCurrentPrice() public view returns (uint256) {
        return getPrice(_TOTAL_RAISED_FUNDS_);
    }

    function getPrice(uint256 fundAmount) public view returns (uint256 price) {
        price = DecimalMath.divFloor(fundAmount, _TOTAL_TOKEN_AMOUNT_);
        if (price < _LOWER_LIMIT_PRICE_) {
            price = _LOWER_LIMIT_PRICE_;
        }
        if (price > _UPPER_LIMIT_PRICE_) {
            price = _UPPER_LIMIT_PRICE_;
        }
    }

    function getUserTokenAllocation(address user) public view returns (uint256) {
        if (_FINAL_PRICE_ == 0) {
            return 0;
        } else {
            return
                DecimalMath.divFloor(
                    DecimalMath.mulFloor(_FUNDS_DEPOSITED_[user], _USED_FUND_RATIO_),
                    _FINAL_PRICE_
                );
        }
    }

    function getUserFundsUnused(address user) public view returns (uint256) {
        return
            DecimalMath.mulFloor(_FUNDS_DEPOSITED_[user], DecimalMath.ONE.sub(_USED_FUND_RATIO_));
    }

    function getUserFundsUsed(address user) public view returns (uint256) {
        return DecimalMath.mulFloor(_FUNDS_DEPOSITED_[user], _USED_FUND_RATIO_);
    }

    // ============ Settle Functions ============

    function settle() public isNotForceStop preventReentrant {
        require(_FINAL_PRICE_ == 0 && isFundingEnd(), "CAN_NOT_SETTLE");
        _FINAL_PRICE_ = getCurrentPrice();
        if(_TOTAL_RAISED_FUNDS_ == 0) {
            return;
        } 
        _USED_FUND_RATIO_ = DecimalMath.divFloor(
            DecimalMath.mulFloor(_TOTAL_TOKEN_AMOUNT_, _FINAL_PRICE_),
            _TOTAL_RAISED_FUNDS_
        );
        if (_USED_FUND_RATIO_ > DecimalMath.ONE) {
            _USED_FUND_RATIO_ = DecimalMath.ONE;
        }

         msg.sender.transfer(_SETTEL_FUND_);
    }

    // ============ Funding Functions ============

    function depositFunds(address to) external preventReentrant isNotForceStop returns(uint256 inputFund) {
        require(isDepositOpen(), "DEPOSIT_NOT_OPEN");

        uint256 currentFundBalance = IERC20(_FUNDS_ADDRESS_).balanceOf(address(this));

        if(_IS_OVERCAP_STOP) {
            require(currentFundBalance <= DecimalMath.mulFloor(_TOTAL_TOKEN_AMOUNT_, _UPPER_LIMIT_PRICE_), "ALREADY_OVER_CAP");
        }        

        // input fund check
        inputFund = currentFundBalance.sub(_FUNDS_RESERVE_);
        _FUNDS_RESERVE_ = _FUNDS_RESERVE_.add(inputFund);

        if (_QUOTA_ != address(0)) {
            require(
                inputFund.add(_FUNDS_DEPOSITED_[to]) <= uint256(IQuota(_QUOTA_).getUserQuota(to)),
                "QUOTA_EXCEED"
            );
        }

        _FUNDS_DEPOSITED_[to] = _FUNDS_DEPOSITED_[to].add(inputFund);
        _TOTAL_RAISED_FUNDS_ = _TOTAL_RAISED_FUNDS_.add(inputFund);
    }

    function withdrawFunds(address to, uint256 amount) external preventReentrant {
        if (!isSettled()) {
            require(_FUNDS_DEPOSITED_[msg.sender] >= amount, "WITHDRAW_TOO_MUCH");
            _FUNDS_DEPOSITED_[msg.sender] = _FUNDS_DEPOSITED_[msg.sender].sub(amount);
            _TOTAL_RAISED_FUNDS_ = _TOTAL_RAISED_FUNDS_.sub(amount);
            _FUNDS_RESERVE_ = _FUNDS_RESERVE_.sub(amount);
            IERC20(_FUNDS_ADDRESS_).safeTransfer(to, amount);
        } else {
            require(!_FUNDS_CLAIMED_[msg.sender], "ALREADY_CLAIMED");
            _FUNDS_CLAIMED_[msg.sender] = true;
            IERC20(_FUNDS_ADDRESS_).safeTransfer(to, getUserFundsUnused(msg.sender));
        }
    }

    function claimToken(address to) external {
        require(isSettled(), "NOT_SETTLED");
        uint256 totalAllocation = getUserTokenAllocation(msg.sender);
        _claimToken(to, totalAllocation);

        if(!_FUNDS_CLAIMED_[msg.sender]) {
            _FUNDS_CLAIMED_[msg.sender] = true;
            IERC20(_FUNDS_ADDRESS_).safeTransfer(to, getUserFundsUnused(msg.sender));
        }
    }    

    // ============ Ownable Functions ============

    function withdrawUnallocatedToken(address to) external preventReentrant onlyOwner {
        require(isSettled(), "NOT_SETTLED");
        require(_FINAL_PRICE_ == _LOWER_LIMIT_PRICE_, "NO_TOKEN_LEFT");
        uint256 allocatedToken = DecimalMath.divCeil(_TOTAL_RAISED_FUNDS_, _FINAL_PRICE_);
        IERC20(_TOKEN_ADDRESS_).safeTransfer(to, _TOTAL_TOKEN_AMOUNT_.sub(allocatedToken));
        _TOTAL_TOKEN_AMOUNT_ = allocatedToken;
    }

    function initializeLiquidity(uint256 initialTokenAmount, uint256 lpFeeRate, bool isOpenTWAP) external preventReentrant onlyOwner {
        require(isSettled(), "NOT_SETTLED");
        uint256 totalUsedRaiseFunds = DecimalMath.mulFloor(_TOTAL_RAISED_FUNDS_, _USED_FUND_RATIO_);
        _initializeLiquidity(initialTokenAmount, totalUsedRaiseFunds, lpFeeRate, isOpenTWAP);
    }

    function claimFund(address to) external preventReentrant onlyOwner {
        require(isSettled(), "NOT_SETTLED");
        uint256 totalUsedRaiseFunds = DecimalMath.mulFloor(_TOTAL_RAISED_FUNDS_, _USED_FUND_RATIO_);
        _claimFunds(to,totalUsedRaiseFunds);
    }

    // ============ Timeline Control Functions ============

    function isDepositOpen() public view returns (bool) {
        return
            block.timestamp >= _START_TIME_ &&
            block.timestamp < _START_TIME_.add(_BIDDING_DURATION_);
    }

    function isFundingEnd() public view returns (bool) {
        return block.timestamp > _START_TIME_.add(_BIDDING_DURATION_).add(_COOLING_DURATION_);
    }

    function isSettled() public view returns (bool) {
        return _FINAL_PRICE_ != 0;
    }
}