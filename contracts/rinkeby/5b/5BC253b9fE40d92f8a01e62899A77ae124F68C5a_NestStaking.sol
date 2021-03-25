/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: contracts/lib/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: contracts/lib/ReentrancyGuard.sol


pragma solidity ^0.6.0;

/// @dev The non-empty constructor is conflict with upgrades-openzeppelin. 

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
contract ReentrancyGuard {
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

    // NOTE: _NOT_ENTERED is set to ZERO such that it needn't constructor
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    // constructor () internal {
    //     _status = _NOT_ENTERED;
    // }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
// File: contracts/iface/INestStaking.sol


pragma solidity ^0.6.12;


interface INestStaking {
    // Views

    /// @dev How many stakingToken (XToken) deposited into to this reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @return The total amount of XTokens deposited in this staking pool
    function totalStaked(address ntoken) external view returns (uint256);

    /// @dev How many stakingToken (XToken) deposited by the target account
    /// @param  ntoken The address of NToken
    /// @param  account The target account
    /// @return The total amount of XToken deposited in this staking pool
    function stakedBalanceOf(address ntoken, address account) external view returns (uint256);


    // Mutative
    /// @dev Stake/Deposit into the reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function stake(address ntoken, uint256 amount) external;

    function stakeFromNestPool(address ntoken, uint256 amount) external;

    /// @dev Withdraw from the reward pool (staking pool), get the original tokens back
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function unstake(address ntoken, uint256 amount) external;

    /// @dev Claim the reward the user earned
    /// @param ntoken The address of NToken
    /// @return The amount of ethers as rewards
    function claim(address ntoken) external returns (uint256);

    /// @dev Add ETH reward to the staking pool
    /// @param ntoken The address of NToken
    function addETHReward(address ntoken) external payable;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    function pause() external;

    function resume() external;

    //function setParams(uint8 dividendShareRate) external;

    /* ========== EVENTS ========== */

    // Events
    event RewardAdded(address ntoken, address sender, uint256 reward);
    event NTokenStaked(address ntoken, address indexed user, uint256 amount);
    event NTokenUnstaked(address ntoken, address indexed user, uint256 amount);
    event SavingWithdrawn(address ntoken, address indexed to, uint256 amount);
    event RewardClaimed(address ntoken, address indexed user, uint256 reward);

    event FlagSet(address gov, uint256 flag);
}
// File: contracts/lib/Address.sol


pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
// File: contracts/lib/SafeERC20.sol


pragma solidity 0.6.12;



library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/iface/INestPool.sol


pragma solidity ^0.6.12;


interface INestPool {

    // function getNTokenFromToken(address token) view external returns (address);
    // function setNTokenToToken(address token, address ntoken) external; 

    function addNest(address miner, uint256 amount) external;
    function addNToken(address contributor, address ntoken, uint256 amount) external;

    function depositEth(address miner) external payable;
    function depositNToken(address miner,  address from, address ntoken, uint256 amount) external;

    function freezeEth(address miner, uint256 ethAmount) external; 
    function unfreezeEth(address miner, uint256 ethAmount) external;

    function freezeNest(address miner, uint256 nestAmount) external;
    function unfreezeNest(address miner, uint256 nestAmount) external;

    function freezeToken(address miner, address token, uint256 tokenAmount) external; 
    function unfreezeToken(address miner, address token, uint256 tokenAmount) external;

    function freezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    function unfreezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;

    function getNTokenFromToken(address token) external view returns (address); 
    function setNTokenToToken(address token, address ntoken) external; 

    function withdrawEth(address miner, uint256 ethAmount) external;
    function withdrawToken(address miner, address token, uint256 tokenAmount) external;

    function withdrawNest(address miner, uint256 amount) external;
    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    // function withdrawNToken(address miner, address ntoken, uint256 amount) external;
    function withdrawNTokenAndTransfer(address miner, address ntoken, uint256 amount, address to) external;


    function balanceOfNestInPool(address miner) external view returns (uint256);
    function balanceOfEthInPool(address miner) external view returns (uint256);
    function balanceOfTokenInPool(address miner, address token)  external view returns (uint256);

    function addrOfNestToken() external view returns (address);
    function addrOfNestMining() external view returns (address);
    function addrOfNTokenController() external view returns (address);
    function addrOfNNRewardPool() external view returns (address);
    function addrOfNNToken() external view returns (address);
    function addrOfNestStaking() external view returns (address);
    function addrOfNestQuery() external view returns (address);
    function addrOfNestDAO() external view returns (address);

    function addressOfBurnedNest() external view returns (address);

    function setGovernance(address _gov) external; 
    function governance() external view returns(address);
    function initNestLedger(uint256 amount) external;
    function drainNest(address to, uint256 amount, address gov) external;

}
// File: contracts/lib/AddressPayable.sol


pragma solidity ^0.6.12;

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}
// File: contracts/lib/SafeMath.sol


pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}
// File: contracts/NestStaking.sol


pragma solidity ^0.6.12;








/// @title NestStaking
/// @author Inf Loop - <[email protected]>
/// @author Paradox  - <[email protected]>

contract NestStaking is INestStaking, ReentrancyGuard {

    using SafeMath for uint256;

    /* ========== STATE ============== */

    /// @dev  The flag of staking global state
    uint8 public flag;      // = 0: uninitialized
                            // = 1: active
                            // = 2: no staking
                            // = 3: paused 

    uint248 private _reserved1;

    uint8 constant STAKING_FLAG_UNINITIALIZED    = 0;
    uint8 constant STAKING_FLAG_ACTIVE           = 1;
    uint8 constant STAKING_FLAG_NO_STAKING       = 2;
    uint8 constant STAKING_FLAG_PAUSED           = 3;

    /// @dev The balance of savings w.r.t a ntoken(or nest-token)
    ///     _pending_saving_Amount: ntoken => saving amount
    //mapping(address => uint256) private _pending_saving_amount;

    /// @dev The per-ntoken-reward (ETH) w.r.t a ntoken(or nest-token)
    ///     _reward_per_ntoken_stored: ntoken => amount
    mapping(address => uint256) private _reward_per_ntoken_stored;

    // _reward_per_ntoken_claimed: (ntoken, acount, amount) => amount
    mapping(address => mapping(address => uint256)) _reward_per_ntoken_claimed;

    // ntoken => last reward 
    mapping(address => uint256) public lastRewardsTotal;

    // _ntoken_total: ntoken => amount
    mapping(address => uint256) _ntoken_staked_total;

    // _staked_balances: (ntoken, account) => amount
    mapping(address => mapping(address => uint256)) private _staked_balances;

    // rewardsTotal: (ntoken) => amount
    mapping(address => uint256) public rewardsTotal;
    
    // _rewards_balances: (ntoken, account) => amount
    mapping(address => mapping(address => uint256)) public rewardBalances;

    /* ========== PARAMETERS ============== */
    
    /// @dev The percentage of dividends 
    uint8 private _dividend_share; // = 100 as default;

    uint8 constant STAKING_DIVIDEND_SHARE_PRECENTAGE = 100;

    uint248 private _reserved2;

    /* ========== ADDRESSES ============== */

    address private C_NestToken;
    // address private C_NestPool;

    address private governance;

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {}

    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor() public { }

    /// @dev It is called by the proxy (open-zeppelin/upgrades), only ONCE!
    function initialize() external 
    {
        require(flag == STAKING_FLAG_UNINITIALIZED, "Nest:Stak:!flag");
        governance = msg.sender;
        _dividend_share = STAKING_DIVIDEND_SHARE_PRECENTAGE;
        flag = STAKING_FLAG_ACTIVE;
        // C_NestPool = NestPool;
        governance = msg.sender;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovOrBy(address _contract) 
    {
        require(msg.sender == governance || msg.sender == _contract, "Nest:Stak:!sender");
        _;
    }

    modifier whenActive() 
    {
        require(flag == STAKING_FLAG_ACTIVE, "Nest:Stak:!flag");
        _;
    }

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:Stak:!gov");
        _;
    }

    mapping(uint256 => mapping(address => bool)) private _status;

    modifier onlyOneBlock() {
        require(
            !_status[block.number][tx.origin],
            'Nest:Stak:!block'
        );
        require(
            !_status[block.number][msg.sender],
            'Nest:Stak:!block'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }

    /* ========== GOVERNANCE ========== */

    function loadContracts() override external 
    {
        // C_NestToken = INestPool(C_NestPool).addrOfNestToken();
    }

    // @dev To ensure that all of governance-addresses be consist with each other
    function loadGovernance() override external 
    { 
        // governance = INestPool(C_NestPool).governance();
    }

    /// @dev Stop service for emergency
    function pause() override external onlyGovernance
    {
        require(flag == STAKING_FLAG_ACTIVE, "Nest:Stak:!flag");
        flag = STAKING_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(STAKING_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() override external onlyGovernance
    {
        require(flag == STAKING_FLAG_PAUSED, "Nest:Stak:!flag");
        flag = STAKING_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(STAKING_FLAG_ACTIVE));
    }

    /*
   
    function setParams(uint8 dividendShareRate) override external onlyGovernance
    {
        if (dividendShareRate > 0 && dividendShareRate <= 100) {
            _dividend_share = dividendShareRate;
        }
    }
    */
    /* ========== VIEWS ========== */
    /*
    function totalSaving(address ntoken)
        external view returns (uint256) 
    {
       return  _pending_saving_amount[ntoken];
    }
    */
    function totalRewards(address ntoken)
        external view returns (uint256) 
    {
       return  rewardsTotal[ntoken];
    }

    function totalStaked(address ntoken) 
        external override view returns (uint256) 
    {
        return _ntoken_staked_total[ntoken];
    }

    function stakedBalanceOf(address ntoken, address account) 
        external override view returns (uint256) 
    {
        return _staked_balances[ntoken][account];
    }

    // CM: <tokenShare> = <OldTokenShare> + (<NewTokenShare> * _dividend_share% / <tokenAmount>) 
    function rewardPerToken(address ntoken) 
        public 
        view 
        returns (uint256) 
    {
        uint256 _total = _ntoken_staked_total[ntoken];
        if (_total == 0) {
            // use the old rewardPerTokenStored
            // if not, the new accrued amount will never be distributed to anyone
            return _reward_per_ntoken_stored[ntoken];
        }
        uint256 _rewardPerToken = _reward_per_ntoken_stored[ntoken].add(
                accrued(ntoken).mul(1e18).mul(_dividend_share).div(_total).div(100)
            );
        return _rewardPerToken;
    }

    // CM: <NewTokenShare> = <rewardToken blnc> - <last blnc>
    function accrued(address ntoken) 
        public 
        view 
        returns (uint256) 
    {
        // eth increment of eth since last update
        uint256 _newest = rewardsTotal[ntoken];
        // lastest must be larger than lastUpdate
        return _newest.sub(lastRewardsTotal[ntoken]); 
    }

    // CM: <user share> = [<tokenAmonut> * (<tokenShare> - <tokenShareCollected>) / 1e18] + <reward>
    function earned(address ntoken, address account) 
        public 
        view 
        returns (uint256) 
    {
        return _staked_balances[ntoken][account].mul(
                        rewardPerToken(ntoken).sub(_reward_per_ntoken_claimed[ntoken][account])
                    ).div(1e18).add(rewardBalances[ntoken][account]);
    }
    /*  // it is extra
    // calculate
    function _rewardPerTokenAndAccrued(address ntoken) 
        internal
        view 
        returns (uint256, uint256) 
    {
        uint256 _total = _ntoken_staked_total[ntoken];
        if (_total == 0) {
            // use the old rewardPerTokenStored, and accrued should be zero here
            // if not the new accrued amount will never be distributed to anyone
            return (_reward_per_ntoken_stored[ntoken], 0);
        }
        uint256 _accrued = accrued(ntoken);
        uint256 _rewardPerToken = _reward_per_ntoken_stored[ntoken].add(
                _accrued.mul(1e18).mul(_dividend_share).div(_total).div(100) 
            ); // 80% of accrued to NEST holders as dividend
        return (_rewardPerToken, _accrued);
    }
    */
    /* ========== STAK/UNSTAK/CLAIM ========== */

    modifier updateReward(address ntoken, address account) 
    {
        uint256 _total = _ntoken_staked_total[ntoken];
        uint256 _accrued = rewardsTotal[ntoken].sub(lastRewardsTotal[ntoken]);
        uint256 _rewardPerToken;      

        if (_total == 0) {
            // use the old rewardPerTokenStored, and accrued should be zero here
            // if not the new accrued amount will never be distributed to anyone
            _rewardPerToken = _reward_per_ntoken_stored[ntoken];
        } else {
            // 80% of accrued to NEST holders as dividend
            _rewardPerToken = _reward_per_ntoken_stored[ntoken].add(
                _accrued.mul(1e18).mul(_dividend_share).div(_total).div(100) 
            );
            // update _reward_per_ntoken_stored
            _reward_per_ntoken_stored[ntoken] = _rewardPerToken;
            lastRewardsTotal[ntoken] = rewardsTotal[ntoken];
            //uint256 _newSaving = _accrued.sub(_accrued.mul(_dividend_share).div(100)); // left 20%
            //_pending_saving_amount[ntoken] = _pending_saving_amount[ntoken].add(_newSaving);
        }

        uint256 _newEarned = _staked_balances[ntoken][account].mul(
                _rewardPerToken.sub(_reward_per_ntoken_claimed[ntoken][account])
            ).div(1e18);

        if (account != address(0)) { // Q: redundant
            rewardBalances[ntoken][account] = rewardBalances[ntoken][account].add(_newEarned);
            _reward_per_ntoken_claimed[ntoken][account] = _reward_per_ntoken_stored[ntoken];
        }
        _;
    }

    /// @notice Stake NTokens to get the dividends
    function stake(address ntoken, uint256 amount)
        external 
        override 
        nonReentrant 
        onlyOneBlock
        whenActive
        updateReward(ntoken, msg.sender) 
    {
        require(amount > 0, "Nest:Stak:!amount");
        _ntoken_staked_total[ntoken] = _ntoken_staked_total[ntoken].add(amount);
        _staked_balances[ntoken][msg.sender] = _staked_balances[ntoken][msg.sender].add(amount);
        //TransferHelper.safeTransferFrom(ntoken, msg.sender, address(this), amount);
        emit NTokenStaked(ntoken, msg.sender, amount);
        TransferHelper.safeTransferFrom(ntoken, msg.sender, address(this), amount);

    }

    /// @notice Stake NTokens to get the dividends
    function stakeFromNestPool(address ntoken, uint256 amount) 
        external 
        override 
        nonReentrant 
        onlyOneBlock
        whenActive
        updateReward(ntoken, msg.sender) 
    {
        // require(amount > 0, "Nest:Stak:!amount");
        // _ntoken_staked_total[ntoken] = _ntoken_staked_total[ntoken].add(amount);
        // _staked_balances[ntoken][msg.sender] = _staked_balances[ntoken][msg.sender].add(amount);
        // INestPool(C_NestPool).withdrawNTokenAndTransfer(msg.sender, ntoken, amount, address(this));
        // emit NTokenStaked(ntoken, msg.sender, amount);
    }

    /// @notice Unstake NTokens
    function unstake(address ntoken, uint256 amount) 
        public 
        override 
        nonReentrant 
        onlyOneBlock
        whenActive
        updateReward(ntoken, msg.sender)
    {
        require(amount > 0, "Nest:Stak:!amount");
        _ntoken_staked_total[ntoken] = _ntoken_staked_total[ntoken].sub(amount);
        _staked_balances[ntoken][msg.sender] = _staked_balances[ntoken][msg.sender].sub(amount);
        //TransferHelper.safeTransfer(ntoken, msg.sender, amount);
        emit NTokenUnstaked(ntoken, msg.sender, amount);
        TransferHelper.safeTransfer(ntoken, msg.sender, amount);

    }

    /// @notice Claim rewards
    function claim(address ntoken) 
        public 
        override 
        nonReentrant 
        whenActive
        updateReward(ntoken, msg.sender) 
        returns (uint256)
    {
        uint256 _reward = rewardBalances[ntoken][msg.sender];
        if (_reward > 0) {
            rewardBalances[ntoken][msg.sender] = 0;
            // WETH balance decreased after this
            //TransferHelper.safeTransferETH(msg.sender, _reward);
            // must refresh WETH balance record after updating WETH balance
            // or lastRewardsTotal could be less than the newest WETH balance in the next update
            uint256 _newTotal = rewardsTotal[ntoken].sub(_reward);
            lastRewardsTotal[ntoken] = _newTotal;
            rewardsTotal[ntoken] = _newTotal;         
           
            emit RewardClaimed(ntoken, msg.sender, _reward);

             TransferHelper.safeTransferETH(msg.sender, _reward);
        }
        return _reward;
    }

    /* ========== INTER-CALLS ========== */

    function addETHReward(address ntoken) 
        override 
        external 
        payable 
    {
        // NOTE: no need to update reward here
        // support for sending ETH for rewards
        rewardsTotal[ntoken] = rewardsTotal[ntoken].add(msg.value); 
    }

}