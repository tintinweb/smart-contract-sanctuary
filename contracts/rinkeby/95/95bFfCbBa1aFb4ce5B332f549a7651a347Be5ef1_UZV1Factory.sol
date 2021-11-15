// contracts/UZV1Factory.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUZV1Factory} from "./interfaces/staking/IUZV1Factory.sol";
import {IUZV1Router} from "./interfaces/staking/IUZV1Router.sol";
import {IUZV1RewardPool} from "./interfaces/pools/IUZV1RewardPool.sol";
import {IUZV1PayableRewardPool} from "./interfaces/pools/IUZV1PayableRewardPool.sol";

import {SharedDataTypes} from "./libraries/SharedDataTypes.sol";
import {UZV1ProAccess} from "./membership/UZV1ProAccess.sol";

/**
 * @title UnizenStakingFactory
 * @author Unizen
 * @notice Factory is used to keep track of existing reward pools and generate new reward pool contracts
 **/
contract UZV1Factory is IUZV1Factory, UZV1ProAccess {
    /* === STATE VARIABLES === */
    // address of currently used router
    address public router;

    // list of all existing reward pools, limited to 10 at once
    address[] public activePools;
    // list of all created pools
    address[] public allPools;
    // lookup table for pool addresses
    mapping(address => bool) public validPools;

    // base contracts for pool types that can be cloned
    mapping(uint8 => address) internal _basePools;

    /* === CONSTRUCTOR === */
    constructor(address _accessToken) UZV1ProAccess(_accessToken) {}

    /* === VIEW FUNCTIONS === */
    /**
     * @dev  Loops through the maximum amount of valid active pools,
     * returns an array of pool address and the count of currently active pools
     * @return address[] List of active pool addresses
     **/
    function getActivePools()
        external
        view
        override
        returns (address[] memory)
    {
        // return pool list and pool count
        return activePools;
    }

    /**
     * @dev Checks if a pool address is a valid pool address
     * of this staking system, to ensure it can be trusted and
     * nor harmful third-party code gets executed.
     * @param pool address of the pool contract to check
     **/
    function isValidPool(address pool) external view override returns (bool) {
        // if pool address has an id, it's valid since it was
        // added via the factory contract.
        return validPools[pool];
    }

    /* === MUTATING FUNCTIONS === */
    /// control functions
    /**
     * @dev  Updates the router address
     * @param _router Address of new router
     **/
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "ZERO_ADDRESS");
        require(_router != router, "SAME_ADDRESS");
        router = _router;
    }

    /**
     * @dev Allow the owner to add / update / remove addresses for base pools
     * of specific type.
     *
     * @param _pool address of the new base pool contract
     * @param _type type of the base reward pool
     **/
    function setBaseContractForType(address _pool, uint8 _type)
        external
        onlyOwner
    {
        // only allow zero addresses for existing base pools (for deletions)
        if (_basePools[_type] == address(0)) {
            require(_pool != address(0), "ZERO_ADDRESS");
        }
        // update base contract address for pool type
        _basePools[_type] = _pool;
    }

    /**
     * @dev  Pool factory that creates a new reward pool by cloning
     * existing deployed reward pool contracts and initiating them
     * with the desired input data
     * @param _inputData object with all required input data
     *  * uint256 totalRewards - amount of tokens / allocation for distribution
     *  * uint256 startBlock - block number when distribution phase begins
     *  * uint256 endBlock - block number when distribution phase ends
     *  * address token - address of rewardable token (not needed for mainnet pools)
     *  * uint8 type of reward pool
     *  * PoolInfo object containing ui information for pool
     *    * string name - optional name of pool
     *    * string blockchain - name of used blockchain
     *    * string cAddress - address of token used on blockchain
     * @return address Address of created reward pool
     **/
    function createNewPool(SharedDataTypes.PoolInputData calldata _inputData)
        external
        override
        onlyOwner
        returns (address)
    {
        // an assigned router is required for creating pools
        require(router != address(0), "NO_ROUTER");
        // check current pool count, only 10 can exist
        require(activePools.length < 10, "MAX_POOLS");
        // check reward amount
        require(_inputData.totalRewards > 0, "ZERO_REWARDS");
        // start block cant be in the past
        require(_inputData.startBlock >= block.number, "INVALID_START_BLOCK");
        // end block cant be in the past
        require(
            _inputData.endBlock > _inputData.startBlock,
            "INVALID_END_BLOCK"
        );
        // a base pool contract needs to exist for that pool type
        require(
            _basePools[_inputData.poolType] != address(0),
            "INVALID_POOL_TYPE"
        );

        // get base reward contract for the desired pool type
        address _basePool = _basePools[_inputData.poolType];
        // address of cloned contract
        address _newPoolAddress;
        // new pool instance
        IUZV1RewardPool _newPool;
        // reward token instance
        IERC20 _token;

        // create new pool by cloning
        _newPoolAddress = _createClone(_basePool);

        // check that pool address is valid
        require(_newPoolAddress != address(0), "CLONE:ZERO_ADDRESS");
        require(_newPoolAddress != _basePool, "CLONE:SAME_ADDRESS");

        // assign pool instance
        _newPool = IUZV1RewardPool(_newPoolAddress);
        // init the new pool and assign router
        _newPool.init(router, address(_membershipToken));
        // set the pool data
        _newPool.setPoolData(_inputData);

        // check if pool type is a token or mainnet reward pool
        bool _isTokenPool = _newPool.canReceiveRewards();

        // check if the desired reward pool is a token or mainnet
        if (_isTokenPool) {
            // onchain distribution, so token address needs to exist
            require(_inputData.token != address(0), "NO_REWARD_TOKEN");

            _token = IERC20(_inputData.token);
            require(
                _token.allowance(_msgSender(), address(this)) >=
                    _inputData.totalRewards,
                "INSUFFICIENT_ALLOWANCE"
            );

            // transfer funds to contract, if needed
            SafeERC20.safeTransferFrom(
                _token,
                _msgSender(),
                _newPoolAddress,
                _inputData.totalRewards
            );
        }

        // if everything went well, add new pool to pool list
        addPoolToPoolList(_newPoolAddress);

        emit PoolCreated(
            _newPoolAddress,
            _inputData.token,
            _inputData.totalRewards,
            _inputData.startBlock,
            _inputData.endBlock
        );

        // return the new pool address
        return _newPoolAddress;
    }

    /**
     * @dev  Adds pool to active pool list
     * @param _pool Address of pool
     **/
    function addPoolToPoolList(address _pool) public onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        // check current pool count, only 10 can exist
        require(activePools.length < 10, "MAX_POOLS");
        // add pool to active list on desired index
        activePools.push(_pool);
        // add pools to total pool list
        allPools.push(_pool);
        // add index to lookup table for valid pools list
        validPools[_pool] = true;
    }

    /**
     * @dev  Removes pool from active pool list
     * @param _pool Address of pool
     **/
    function removePool(address _pool) external override onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");

        // get index of active pool
        uint8 _idx = 255;
        // loop through maximum active pool count
        for (uint8 i = 0; i < activePools.length; i++) {
            // check if pool address is the desired address
            if (activePools[i] == _pool) {
                // assign current index
                _idx = i;
            }
        }
        // check that a pool index was found
        require(_idx < 255, "NO_ACTIVE_POOL");

        // remove from active pools list
        activePools[_idx] = activePools[activePools.length - 1];
        activePools.pop();
    }

    function setMainnet(address _pool, bool _isMainnet)
        external
        override
        onlyOwner
    {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");

        IUZV1PayableRewardPool(_pool).setMainnet(_isMainnet);
    }

    /**
     * @dev  Updates reward pool with a new staking window
     * @param _pool address of the pool to change
     * @param _startBlock start of the staking window
     * @param _endBlock end of the staking window
     **/
    function setStakingWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external override onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");
        // start block cant be in the past
        require(_startBlock >= block.number, "INVALID_START_BLOCK");
        // end block cant be in the past
        require(_endBlock > _startBlock, "INVALID_END_BLOCK");
        IUZV1RewardPool(_pool).setStakingWindow(_startBlock, _endBlock);
    }

    /**
     * @dev Updates the reward pool with a new payment receiver
     * @param _pool address of the pool to change
     * @param _receiver address of the payment receiver
     **/
    function setPaymentAddress(address _pool, address _receiver)
        external
        override
        onlyOwner
    {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");
        IUZV1PayableRewardPool(_pool).setPaymentAddress(_receiver);
    }

    /**
     * @dev  Updates reward pool with a new payment window
     * @param _pool address of the pool to change
     * @param _startBlock start of the payment window window
     * @param _endBlock end of the payment window
     **/
    function setPaymentWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external override onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");
        // start block cant be in the past
        require(_startBlock >= block.number, "INVALID_START_BLOCK");
        // end block cant be in the past
        require(_endBlock > _startBlock, "INVALID_END_BLOCK");
        IUZV1PayableRewardPool(_pool).setPaymentWindow(_startBlock, _endBlock);
    }

    /**
     * @dev  Adds a new payable token to a incubator pool
     * @param _pool address of the pool to change
     * @param _token address of the payable token
     * @param _pricePerReward price of a single reward
     **/
    function setPaymentToken(
        address _pool,
        address _token,
        uint256 _pricePerReward
    ) external override onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");
        IUZV1PayableRewardPool(_pool).setPaymentToken(_token, _pricePerReward);
    }

    /**
     * @dev  Updates reward pool with a new distribution window
     * @param _pool address of the pool to change
     * @param _startBlock start of the distribution window
     * @param _endBlock end of the distribution window
     **/
    function setDistributionWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external override onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");
        // start block cant be in the past
        require(_startBlock >= block.number, "INVALID_START_BLOCK");
        // end block cant be in the past
        require(_endBlock > _startBlock, "INVALID_END_BLOCK");

        IUZV1PayableRewardPool(_pool).setDistributionWindow(
            _startBlock,
            _endBlock
        );
    }

    /**
     * @dev  Emergency function to withdraw accidentally transferred tokens to a pool contract
     * @param _pool address of the pool to change
     * @param _tokenAddress address of the erc20 token to withdraw
     * @param _amount amount to withdraw. if bigger than balance, it will withdraw everything to owner
     **/
    function withdrawTokens(
        address _pool,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        require(validPools[_pool], "INVALID_POOL");
        IUZV1RewardPool(_pool).withdrawTokens(_tokenAddress, _amount);

        IERC20 _token = IERC20(_tokenAddress);
        uint256 _receivedAmount = (_amount <= _token.balanceOf(address(this)))
            ? _amount
            : _token.balanceOf(address(this));

        SafeERC20.safeTransfer(_token, owner(), _receivedAmount);
    }

    /* === INTERNAL FUNCTIONS === */
    // Original to be found here, just added as function
    // https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
    function _createClone(address _targetContract) internal returns (address) {
        bytes20 targetBytes = bytes20(_targetContract);
        address result;
        assembly {
            let _clone := mload(0x40)
            mstore(
                _clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(_clone, 0x14), targetBytes)
            mstore(
                add(_clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, _clone, 0x37)
        }
        return result;
    }

    /* === MODIFIERS === */

    /* === EVENTS === */
    event PoolCreated(
        address indexed _pool,
        address indexed _token,
        uint256 _totalReward,
        uint256 _startBlock,
        uint256 _endBlock
    );
    event PoolUpdated(address indexed _pool);
    event PoolRemoved(address indexed _pool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// contracts/interfaces/staking/IUZV1Factory.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {SharedDataTypes} from "../../libraries/SharedDataTypes.sol";

interface IUZV1Factory {
    /* view functions */
    function getActivePools() external view returns (address[] memory);

    function isValidPool(address pool) external view returns (bool);

    /* control functions */
    function createNewPool(SharedDataTypes.PoolInputData calldata _inputData) external returns (address);

    function removePool(address _pool) external;

    function setMainnet(
        address _pool,
        bool _isMainnet
    ) external;

    function setStakingWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function setPaymentAddress(
        address _pool,
        address _receiver
    ) external;

    function setPaymentWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function setDistributionWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function withdrawTokens(
        address _pool,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function setPaymentToken(
        address _pool,
        address _token,
        uint256 _pricePerReward
    ) external;
}

// contracts/interfaces/staking/IUZV1Router.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IUZV1RewardPool} from "../pools/IUZV1RewardPool.sol";

interface IUZV1Router {
    /* view functions */
    function getAllUserRewards(address _user)
        external
        view
        returns (address[] memory _pools, uint256[] memory _rewards);

    function getAllPools() external view returns (address[] memory);

    function getAllTokens()
        external
        view
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        );

    function getAllTokens(uint256 _blocknumber)
        external
        view
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        );

    function getTVLs() external view returns (uint256[] memory _tokenTVLs);

    function getTVLs(uint256 _blocknumber)
        external
        view
        returns (uint256[] memory _tokenTVLs);

    function getTokenWeights()
        external
        view
        returns (uint256[] memory weights, uint256 combinedWeight);

    function getUserStakes(address _user)
        external
        view
        returns (uint256 totalStakedAmount, uint256[] memory userStakes);

    function getUserStakes(address _user, uint256 _blocknumber)
        external
        view
        returns (uint256 totalStakedAmount, uint256[] memory userStakes);

    /* mutating functions */
    function claimAllRewards() external;

    function claimReward(address _pool) external returns (bool);

    function claimRewardsFor(IUZV1RewardPool[] calldata pools) external;

    function payRewardPool(address _pool, uint256 _amount) external;

    /* control functions */
    function setMainnetAddressForPool(
        address _poolAddress,
        string calldata _receiver
    ) external;
}

// contracts/interfaces/pools/IUZV1RewardPool.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {SharedDataTypes} from "../../libraries/SharedDataTypes.sol";

interface IUZV1RewardPool {
    /* mutating functions */
    function claimRewards(address _user) external;

    function pay(
        address _user,
        uint256 _amount
    ) external returns (uint256 refund);

    /* view functions */
    // pool specific
    function canReceiveRewards() external view returns (bool);

    function isPoolActive() external view returns (bool);

    function isPayable() external view returns (bool);

    function isMainnet() external view returns (bool);

    function getPoolState() external view returns (SharedDataTypes.PoolState);

    function getPoolType() external view returns (uint8);

    function getPoolTypeString() external view returns (string memory);

    function getPoolInfo() external view returns (SharedDataTypes.PoolData memory);

    function getAmountOfOpenRewards() external view returns (uint256);

    function getStartBlock() external view returns (uint256);

    function getEndBlock() external view returns (uint256);

    function getTimeWindows() external view returns (uint256[] memory);

    function getUserReceiverAddress(address user) external view returns (string memory receiverAddress);

    // user specific
    function getPendingRewards(address _user) external view returns (uint256 reward);

    function getUserInfo(address _user) external view returns (SharedDataTypes.FlatPoolStakerUser memory);

    function setMainnetAddress(address _user, string calldata _receiver) external;

    /* control functions */
    function init(address _newRouter, address _accessToken) external;

    function setPoolData(SharedDataTypes.PoolInputData calldata _inputData) external;

    function withdrawTokens(address _tokenAddress, uint256 _amount) external;

    function setStakingWindow(uint256 _startBlock, uint256 _endBlock) external;
}

// contracts/interfaces/pools/IUZV1PayableRewardPool.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {IUZV1RewardPool} from "./IUZV1RewardPool.sol";

interface IUZV1PayableRewardPool is IUZV1RewardPool {
    /* view functions */
    function getPurchaseableTokens(address _user)
        external
        view
        returns (uint256);

    function getTotalPriceForPurchaseableTokens(
        address _user
    ) external view returns (uint256);

    function getPurchasedAllocationOfUser(address _user)
        external
        view
        returns (uint256);

    function getPaymentAddress()
        external
        view
        returns (address);

    /* control functions */
    function setMainnet(bool _isMainnet) external;
    
    function setPaymentAddress(address _receiver) external;

    function setPaymentToken(address _token, uint256 _pricePerReward) external;

    function setPaymentWindow(uint256 _startBlock, uint256 _endBlock) external;

    function setDistributionWindow(uint256 _startBlock, uint256 _endBlock)
        external;
}

// contracts/libraries/SharedDataTypes.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SharedDataTypes {
    // general staker user information
    struct StakerUser {
        // snapshotted stakes of the user per token (token => block.number => stakedAmount)
        mapping(address => mapping(uint256 => uint256)) stakedAmountSnapshots;
        // snapshotted stakes of the user per token keys (token => block.number[])
        mapping(address => uint256[]) stakedAmountKeys;
        // current stakes of the user per token
        mapping(address => uint256) stakedAmount;
        // snapshotted total staked amount of tokens (block.number => totalStakedAmount)
        mapping(uint256 => uint256) totalStakedAmountSnapshots;
        // snapshotted total staked amount of tokens keys (block.number[])
        uint256[] totalStakedAmountKeys;
        // current total staked amount of tokens
        uint256 totalStakedAmount;
        // total amount of holder tokens
        uint256 holderTokens;
    }

    // information for stakeable tokens
    struct StakeableToken {
        // snapshotted total value locked (TVL) (block.number => totalValueLocked)
        mapping(uint256 => uint256) totalValueLockedSnapshots;
        // snapshotted total value locked (TVL) keys (block.number[])
        uint256[] totalValueLockedKeys;
        // current total value locked (TVL)
        uint256 totalValueLocked;
        uint256 weight;
        bool active;
    }

    // POOL DATA

    // data object for a user stake on a pool
    struct PoolStakerUser {
        // saved / withdrawn rewards of user
        uint256 totalSavedRewards;
        // total purchased allocation
        uint256 totalPurchasedAllocation;
        // total distributed allocation
        uint256 totalDistributedAllocation;
        // mainnet address, if necessary
        string mainnetAddress;
    }

    // flat data type of stake for UI
    struct FlatPoolStakerUser {
        address[] tokens;
        uint256[] amounts;
        uint256 pendingRewards;
        uint256 totalPurchasedAllocation;
        uint256 totalDistributedAllocation;
        uint256 totalSavedRewards;
        uint256 totalStakedAmount;
    }

    // UI information for pool
    // data will be fetched via github token repository
    // blockchain / cAddress being the most relevant values
    // for fetching the correct token data
    struct PoolInfo {
        // token name
        string name;
        // name of blockchain, as written on github
        string blockchain;
        // tokens contract address on chain
        string cAddress;
    }

    // possible states of the reward pool
    enum PoolState {pending, staking, payment, distribution, retired, claimed, rejected, missed}

    // input data for new reward pools
    struct PoolInputData {
        // total rewards to distribute
        uint256 totalRewards;
        // start block for distribution
        uint256 startBlock;
        // end block for distribution
        uint256 endBlock;
        // pool type
        uint8 poolType;
        // erc token address
        address token;
        // information about the reward token
        PoolInfo tokenInfo;
    }

    struct PoolData {
        PoolState state;
        // pool information for the ui
        PoolInfo info;
        // start block of staking rewards
        uint256 startBlock;
        // end block of staking rewards
        uint256 endBlock;
        // total rewards for allocation
        uint256 totalRewards;
        // rewards per block
        uint256 rewardsPerBlock;
        // price of a single reward token
        uint256 rewardTokenPrice;
        // type of the pool
        uint8 poolType;
        // address of payment token
        address paymentToken;
        // address of reward token
        address token;
    }
}

// contracts/membership/UZV1ProAccess.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {Context} from "@openzeppelin/contracts/GSN/Context.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title UZProAccess
 * @author Unizen
 * @notice Simple abstract class to add easy checks
 * for pro membership access token
 **/
abstract contract UZV1ProAccess is Context {
    // internal address of owner
    address internal _owner;
    // internal storage of the erc721 token
    IERC721 internal _membershipToken;

    /* === CONSTRUCTOR === */
    constructor(address _token) {
        _setMembershipToken(_token);
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /* === VIEW FUNCTIONS === */
    function owner() public view returns (address) {
        return _owner;
    }

    function membershipToken() public view returns (address) {
        return address(_membershipToken);
    }

    /* === CONTROL FUNCTIONS === */
    /**
     * @dev  Allows the owner of the contract, to update
     * the used membership token
     * @param _newToken address of the new erc721 token
     **/
    function setMembershipToken(address _newToken) public onlyOwner {
        _setMembershipToken(_newToken);
    }

    function _setMembershipToken(address _newToken) internal {
        if (_newToken == address(0) && address(_membershipToken) == address(0))
            return;

        require(_newToken != address(_membershipToken), "SAME_ADDRESS");
        _membershipToken = IERC721(_newToken);
        emit MembershipTokenUpdated(_newToken);
    }

    /**
     * @dev  Renounce ownership and leave contract without
     * active owner. onlyOwner functions cannot be accessed
     * anymore, after calling this function.
     **/
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev  Transfers the contract ownership to a new
     * user or contract
     * @param _newOwner address of the new contract token
     **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    /* === INTERNAL FUNCTIONS === */

    /**
     * @dev  Internal function that checks if the users has any
     * membership tokens. Reverts, if none is found.
     * @param _user address of user to check
     **/
    function _checkPro(address _user) internal view {
        if (address(_membershipToken) != address(0)) {
            require(
                _membershipToken.balanceOf(_user) > 0,
                "FORBIDDEN: PRO_MEMBER"
            );
        }
    }

    /* === MODIFIERS === */
    modifier onlyPro(address _user) {
        _checkPro(_user);
        _;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner(), "FORBIDDEN: OWNER");
        _;
    }

    /* === EVENTS === */
    event MembershipTokenUpdated(address _newTokenAddress);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

