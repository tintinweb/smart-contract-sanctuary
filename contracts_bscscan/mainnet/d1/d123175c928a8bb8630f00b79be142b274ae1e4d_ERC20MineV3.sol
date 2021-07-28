/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// File: contracts/intf/IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

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

    function transferOwnership(address newOwner) external virtual onlyOwner {
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

// File: contracts/DODOToken/DODOMineV3/RewardVault.sol



interface IRewardVault {
    function reward(address to, uint256 amount) external;
    function withdrawLeftOver(address to, uint256 amount) external; 
    function syncValue() external;
    function _TOTAL_REWARD_() external view returns(uint256);
}

contract RewardVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public _REWARD_RESERVE_;
    uint256 public _TOTAL_REWARD_;
    address public _REWARD_TOKEN_;

    // ============ Event =============
    event DepositReward(uint256 totalReward, uint256 inputReward, uint256 rewardReserve);

    constructor(address _rewardToken) public {
        _REWARD_TOKEN_ = _rewardToken;
    }

    function reward(address to, uint256 amount) external onlyOwner {
        require(_REWARD_RESERVE_ >= amount, "VAULT_NOT_ENOUGH");
        _REWARD_RESERVE_ = _REWARD_RESERVE_.sub(amount);
        IERC20(_REWARD_TOKEN_).safeTransfer(to, amount);
    }

    function withdrawLeftOver(address to,uint256 amount) external onlyOwner {
        require(_REWARD_RESERVE_ >= amount, "VAULT_NOT_ENOUGH");
        _REWARD_RESERVE_ = _REWARD_RESERVE_.sub(amount);
        IERC20(_REWARD_TOKEN_).safeTransfer(to, amount);
    }

    function syncValue() external {
        uint256 rewardBalance = IERC20(_REWARD_TOKEN_).balanceOf(address(this));
        uint256 rewardInput = rewardBalance.sub(_REWARD_RESERVE_);

        _TOTAL_REWARD_ = _TOTAL_REWARD_.add(rewardInput);
        _REWARD_RESERVE_ = rewardBalance;

        emit DepositReward(_TOTAL_REWARD_, rewardInput, _REWARD_RESERVE_);
    }
}

// File: contracts/DODOToken/DODOMineV3/BaseMine.sol



contract BaseMine is InitializableOwnable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ============ Storage ============

    struct RewardTokenInfo {
        address rewardToken;
        uint256 startBlock;
        uint256 endBlock;
        address rewardVault;
        uint256 rewardPerBlock;
        uint256 accRewardPerShare;
        uint256 lastRewardBlock;
        uint256 workThroughReward;
        uint256 lastFlagBlock;
        mapping(address => uint256) userRewardPerSharePaid;
        mapping(address => uint256) userRewards;
    }

    RewardTokenInfo[] public rewardTokenInfos;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    // ============ Event =============

    event Claim(uint256 indexed i, address indexed user, uint256 reward);
    event UpdateReward(uint256 indexed i, uint256 rewardPerBlock);
    event UpdateEndBlock(uint256 indexed i, uint256 endBlock);
    event NewRewardToken(uint256 indexed i, address rewardToken);
    event RemoveRewardToken(address rewardToken);
    event WithdrawLeftOver(address owner, uint256 i);

    // ============ View  ============

    function getPendingReward(address user, uint256 i) public view returns (uint256) {
        require(i<rewardTokenInfos.length, "DODOMineV3: REWARD_ID_NOT_FOUND");
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        uint256 accRewardPerShare = rt.accRewardPerShare;
        if (rt.lastRewardBlock != block.number) {
            accRewardPerShare = _getAccRewardPerShare(i);
        }
        return
            DecimalMath.mulFloor(
                balanceOf(user), 
                accRewardPerShare.sub(rt.userRewardPerSharePaid[user])
            ).add(rt.userRewards[user]);
    }

    function getPendingRewardByToken(address user, address rewardToken) external view returns (uint256) {
        return getPendingReward(user, getIdByRewardToken(rewardToken));
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address user) public view returns (uint256) {
        return _balances[user];
    }

    function getRewardTokenById(uint256 i) external view returns (address) {
        require(i<rewardTokenInfos.length, "DODOMineV3: REWARD_ID_NOT_FOUND");
        RewardTokenInfo memory rt = rewardTokenInfos[i];
        return rt.rewardToken;
    }

    function getIdByRewardToken(address rewardToken) public view returns(uint256) {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (rewardToken == rewardTokenInfos[i].rewardToken) {
                return i;
            }
        }
        require(false, "DODOMineV3: TOKEN_NOT_FOUND");
    }

    function getRewardNum() external view returns(uint256) {
        return rewardTokenInfos.length;
    }

    function getVaultByRewardToken(address rewardToken) public view returns(address) {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (rewardToken == rewardTokenInfos[i].rewardToken) {
                return rewardTokenInfos[i].rewardVault;
            }
        }
        require(false, "DODOMineV3: TOKEN_NOT_FOUND");
    }

    function getVaultDebtByRewardToken(address rewardToken) public view returns(uint256) {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (rewardToken == rewardTokenInfos[i].rewardToken) {
                uint256 totalDepositReward = IRewardVault(rewardTokenInfos[i].rewardVault)._TOTAL_REWARD_();
                uint256 gap = rewardTokenInfos[i].endBlock.sub(rewardTokenInfos[i].lastFlagBlock);
                uint256 totalReward = rewardTokenInfos[i].workThroughReward.add(gap.mul(rewardTokenInfos[i].rewardPerBlock));
                if(totalDepositReward >= totalReward) {
                    return 0;
                }else {
                    return totalReward.sub(totalDepositReward);
                }
            }
        }
        require(false, "DODOMineV3: TOKEN_NOT_FOUND");
    }

    // ============ Claim ============

    function claimReward(uint256 i) public {
        require(i<rewardTokenInfos.length, "DODOMineV3: REWARD_ID_NOT_FOUND");
        _updateReward(msg.sender, i);
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        uint256 reward = rt.userRewards[msg.sender];
        if (reward > 0) {
            rt.userRewards[msg.sender] = 0;
            IRewardVault(rt.rewardVault).reward(msg.sender, reward);
            emit Claim(i, msg.sender, reward);
        }
    }

    function claimAllRewards() external {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            claimReward(i);
        }
    }

    // =============== Ownable  ================

    function addRewardToken(
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock
    ) external onlyOwner {
        require(rewardToken != address(0), "DODOMineV3: TOKEN_INVALID");
        require(startBlock > block.number, "DODOMineV3: START_BLOCK_INVALID");
        require(endBlock > startBlock, "DODOMineV3: DURATION_INVALID");

        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                rewardToken != rewardTokenInfos[i].rewardToken,
                "DODOMineV3: TOKEN_ALREADY_ADDED"
            );
        }

        RewardTokenInfo storage rt = rewardTokenInfos.push();
        rt.rewardToken = rewardToken;
        rt.startBlock = startBlock;
        rt.lastFlagBlock = startBlock;
        rt.endBlock = endBlock;
        rt.rewardPerBlock = rewardPerBlock;
        rt.rewardVault = address(new RewardVault(rewardToken));

        uint256 rewardAmount = rewardPerBlock.mul(endBlock.sub(startBlock));
        IERC20(rewardToken).safeTransfer(rt.rewardVault, rewardAmount);
        RewardVault(rt.rewardVault).syncValue();

        emit NewRewardToken(len, rewardToken);
    }

    function setEndBlock(uint256 i, uint256 newEndBlock)
        external
        onlyOwner
    {
        require(i < rewardTokenInfos.length, "DODOMineV3: REWARD_ID_NOT_FOUND");
        _updateReward(address(0), i);
        RewardTokenInfo storage rt = rewardTokenInfos[i];


        uint256 totalDepositReward = RewardVault(rt.rewardVault)._TOTAL_REWARD_();
        uint256 gap = newEndBlock.sub(rt.lastFlagBlock);
        uint256 totalReward = rt.workThroughReward.add(gap.mul(rt.rewardPerBlock));
        require(totalDepositReward >= totalReward, "DODOMineV3: REWARD_NOT_ENOUGH");

        require(block.number < newEndBlock, "DODOMineV3: END_BLOCK_INVALID");
        require(block.number > rt.startBlock, "DODOMineV3: NOT_START");
        require(block.number < rt.endBlock, "DODOMineV3: ALREADY_CLOSE");

        rt.endBlock = newEndBlock;
        emit UpdateEndBlock(i, newEndBlock);
    }

    function setReward(uint256 i, uint256 newRewardPerBlock)
        external
        onlyOwner
    {
        require(i < rewardTokenInfos.length, "DODOMineV3: REWARD_ID_NOT_FOUND");
        _updateReward(address(0), i);
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        
        require(block.number < rt.endBlock, "DODOMineV3: ALREADY_CLOSE");
        
        rt.workThroughReward = rt.workThroughReward.add((block.number.sub(rt.lastFlagBlock)).mul(rt.rewardPerBlock));
        rt.rewardPerBlock = newRewardPerBlock;
        rt.lastFlagBlock = block.number;

        uint256 totalDepositReward = RewardVault(rt.rewardVault)._TOTAL_REWARD_();
        uint256 gap = rt.endBlock.sub(block.number);
        uint256 totalReward = rt.workThroughReward.add(gap.mul(newRewardPerBlock));
        require(totalDepositReward >= totalReward, "DODOMineV3: REWARD_NOT_ENOUGH");

        emit UpdateReward(i, newRewardPerBlock);
    }

    function withdrawLeftOver(uint256 i, uint256 amount) external onlyOwner {
        require(i < rewardTokenInfos.length, "DODOMineV3: REWARD_ID_NOT_FOUND");
        
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        require(block.number > rt.endBlock, "DODOMineV3: MINING_NOT_FINISHED");

        IRewardVault(rt.rewardVault).withdrawLeftOver(msg.sender,amount);

        emit WithdrawLeftOver(msg.sender, i);
    }


    function directTransferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "DODOMineV3: ZERO_ADDRESS");
        emit OwnershipTransferred(_OWNER_, newOwner);
        _OWNER_ = newOwner;
    }

    // ============ Internal  ============

    function _updateReward(address user, uint256 i) internal {
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        if (rt.lastRewardBlock != block.number){
            rt.accRewardPerShare = _getAccRewardPerShare(i);
            rt.lastRewardBlock = block.number;
        }
        if (user != address(0)) {
            rt.userRewards[user] = getPendingReward(user, i);
            rt.userRewardPerSharePaid[user] = rt.accRewardPerShare;
        }
    }

    function _updateAllReward(address user) internal {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            _updateReward(user, i);
        }
    }

    function _getUnrewardBlockNum(uint256 i) internal view returns (uint256) {
        RewardTokenInfo memory rt = rewardTokenInfos[i];
        if (block.number < rt.startBlock || rt.lastRewardBlock > rt.endBlock) {
            return 0;
        }
        uint256 start = rt.lastRewardBlock < rt.startBlock ? rt.startBlock : rt.lastRewardBlock;
        uint256 end = rt.endBlock < block.number ? rt.endBlock : block.number;
        return end.sub(start);
    }

    function _getAccRewardPerShare(uint256 i) internal view returns (uint256) {
        RewardTokenInfo memory rt = rewardTokenInfos[i];
        if (totalSupply() == 0) {
            return rt.accRewardPerShare;
        }
        return
            rt.accRewardPerShare.add(
                DecimalMath.divFloor(_getUnrewardBlockNum(i).mul(rt.rewardPerBlock), totalSupply())
            );
    }

}

// File: contracts/DODOToken/DODOMineV3/ERC20MineV3.sol




contract ERC20MineV3 is ReentrancyGuard, BaseMine {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ============ Storage ============

    address public _TOKEN_;

    function init(address owner, address token) external {
        super.initOwner(owner);
        _TOKEN_ = token;
    }

    // ============ Event  ============

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // ============ Deposit && Withdraw && Exit ============

    function deposit(uint256 amount) external preventReentrant {
        require(amount > 0, "DODOMineV3: CANNOT_DEPOSIT_ZERO");

        _updateAllReward(msg.sender);

        uint256 erc20OriginBalance = IERC20(_TOKEN_).balanceOf(address(this));
        IERC20(_TOKEN_).safeTransferFrom(msg.sender, address(this), amount);
        uint256 actualStakeAmount = IERC20(_TOKEN_).balanceOf(address(this)).sub(erc20OriginBalance);
        
        _totalSupply = _totalSupply.add(actualStakeAmount);
        _balances[msg.sender] = _balances[msg.sender].add(actualStakeAmount);

        emit Deposit(msg.sender, actualStakeAmount);
    }

    function withdraw(uint256 amount) external preventReentrant {
        require(amount > 0, "DODOMineV3: CANNOT_WITHDRAW_ZERO");

        _updateAllReward(msg.sender);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(_TOKEN_).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
}