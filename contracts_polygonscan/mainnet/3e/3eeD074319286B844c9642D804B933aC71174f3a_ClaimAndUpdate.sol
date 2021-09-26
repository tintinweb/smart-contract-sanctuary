// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../Dependencies/BaseMath.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/Ownable.sol";
import "../Dependencies/IERC20.sol";
import "../Interfaces/ITokenStaking.sol";
import "../Interfaces/ILQTYStaking.sol";
import "../utils/SafeToken.sol";


contract ClaimAndUpdate is ITokenStaking, Ownable, BaseMath {
    using SafeMath for uint;

    // --- Data ---
    string constant public NAME = "ClaimAndUpdate";
    address constant public GAS_TOKEN_ADDR = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    ILQTYStaking public PYQStaking;

    uint256 public PYQrewardUnit;

    address public PYQToken;
    address[] public feeTokens;
    mapping (address => uint256) public lastStakes;
    mapping (address => address) public feeTokenMap;

    mapping (address => bool) public isTM;  // is valid trove manager
    mapping (address => bool) public isBO;  // is valid borrower operation
    mapping (address => bool) public isAP;  // is valid active pool

    mapping (address => uint256) public feePerTokenStaked;
    mapping (address => mapping(address => uint256)) public snapshots;

    
    event StakerStakeUpdated(address user, uint newStake);
    
    // --- Functions ---

    function setAddresses
    (
        address _pyqStaking,
        address _pyqToken,
        address _borrowingFeeToken,
        address _redeemingFeeToken,
        address _troveManager,
        address _borrowerOperation,
        address _activePool
    )
        external
        onlyOwner
        override
    {
        PYQStaking = ILQTYStaking(_pyqStaking);
        PYQToken = _pyqToken;
        
        feeTokenMap[_pyqToken] = _pyqToken;
        feeTokens.push(_pyqToken);
        
        _addNewAsset(
            _borrowingFeeToken,
            _redeemingFeeToken,
            _troveManager,
            _borrowerOperation,
            _activePool
        );
    }


    function addNewAsset(
        address _borrowingFeeToken,
        address _redeemingFeeToken,
        address _troveManager,
        address _borrowerOperation,
        address _activePool
    )
        external
        onlyOwner
        override
    {
        _addNewAsset(
            _borrowingFeeToken,
            _redeemingFeeToken,
            _troveManager,
            _borrowerOperation,
            _activePool
        );
    }

    function _addNewAsset(
        address _borrowingFeeToken,
        address _redeemingFeeToken,
        address _troveManager,
        address _borrowerOperation,
        address _activePool
    ) internal {

        isTM[_troveManager] = true;
        isBO[_borrowerOperation] = true;
        isAP[_activePool] = true;

        feeTokenMap[_troveManager] = _redeemingFeeToken;
        feeTokenMap[_borrowerOperation] = _borrowingFeeToken;

        feeTokens.push(_redeemingFeeToken);
        feeTokens.push(_borrowingFeeToken);

        emit NewAssetTokenAddress(
            _troveManager, _borrowerOperation, _activePool, _redeemingFeeToken, _borrowingFeeToken
        );
    }

    function updatePYQReward(uint _pyqRewardUnit) external onlyOwner {
        PYQrewardUnit = _pyqRewardUnit;
    }

    function PYQRewardLeft() public view returns (uint256) {
        return IERC20(PYQToken).balanceOf(address(this));
    }

    function updateUserStake(address[] memory _users) external override {
        uint rewards;
        
        uint length = _users.length;
        for (uint i = 0; i < length; i++) {
            address user = _users[i];
            uint256 currentStake = _stakes(user);
            uint256 lastStake = lastStakes[user];
            if (currentStake != lastStake) {
                _claim(user);
                rewards = rewards.add(PYQrewardUnit);
            }
        }

        uint totalRewards = PYQRewardLeft();
        rewards = rewards < totalRewards ? rewards : totalRewards;
        
        if (rewards > 0) {
            SafeToken.safeTransfer(PYQToken, msg.sender, rewards);
        }      
    }
    
    function claim() external override {
        _claim(msg.sender);
    }

    function _claim(address _user) internal {
        uint256 currentStake = _stakes(_user);
        uint256 lastStake = lastStakes[_user];
        
        if (lastStake > 0) {
            _sendRewards(_user);
        }
        
        _updateUserSnapshots(_user); 
        
        if (currentStake != lastStake) {
            lastStakes[_user] = currentStake;
            emit StakerStakeUpdated(_user, currentStake);
        }     
    }

    function _sendRewards(address _user) internal {
        uint feeTokenCounts = feeTokens.length;
        for (uint i = 0 ; i < feeTokenCounts; i++) {
            address feeToken = feeTokens[i];
            uint tokenGain = _getPendingGain(feeToken, _user);
            _transferOut(feeToken, _user, tokenGain);
            emit StakingGainsWithdrawn(_user, feeToken, tokenGain);
        } 
    }

    function _updateUserSnapshots(address _user) internal {
        uint feeTokenCounts = feeTokens.length;
        for (uint i = 0 ; i < feeTokenCounts; i++) {
            address feeToken = feeTokens[i];
            uint256 newFeePerTokenStaked = feePerTokenStaked[feeToken];
            snapshots[_user][feeToken] = newFeePerTokenStaked;
            emit StakerSnapshotsUpdated(_user, feeToken, newFeePerTokenStaked);
        }
    }

    // --- Reward-per-unit-staked increase functions. Called by Liquity core contracts ---
    function increaseBorrowingFee(uint _fee) external override {

        _requireCallerIsValidBorrowerOperations();

        uint borrowingFeePerTokenStaked;
        uint totalTokenStaked = _totalLQTYStaked();
        address feeToken = feeTokenMap[msg.sender];
        
        if (totalTokenStaked > 0) {
            borrowingFeePerTokenStaked = _fee.mul(DECIMAL_PRECISION).div(totalTokenStaked);
        }

        uint newFeePerTokenStaked = feePerTokenStaked[feeToken].add(borrowingFeePerTokenStaked);
        feePerTokenStaked[feeToken] = newFeePerTokenStaked;

        emit TokenFeeUpdated(feeToken, _fee, newFeePerTokenStaked);
    }

    function increaseRedeemingFee(uint _fee) external override {
        _requireCallerIsValidTroveManager();

        uint redeemingFeePerTokenStaked;
        uint totalTokenStaked = _totalLQTYStaked();
        address feeToken = feeTokenMap[msg.sender];

        if (totalTokenStaked > 0) {
            redeemingFeePerTokenStaked = _fee.mul(DECIMAL_PRECISION).div(totalTokenStaked);
        }

        uint newFeePerTokenStaked = feePerTokenStaked[feeToken].add(redeemingFeePerTokenStaked);
        feePerTokenStaked[feeToken] = newFeePerTokenStaked;

        emit TokenFeeUpdated(feeToken, _fee, newFeePerTokenStaked);
    }

    function increaseTransferFee(uint _fee) external override {

        _requireCallerIsStakeToken();

        uint transferFeePerTokenStaked;
        uint totalTokenStaked = _totalLQTYStaked();
        address feeToken = feeTokenMap[msg.sender];

        if (totalTokenStaked > 0) {
            transferFeePerTokenStaked = _fee.mul(DECIMAL_PRECISION).div(totalTokenStaked);
        }

        uint newFeePerTokenStaked = feePerTokenStaked[feeToken].add(transferFeePerTokenStaked);
        feePerTokenStaked[feeToken] = newFeePerTokenStaked;

        emit TokenFeeUpdated(feeToken, _fee, newFeePerTokenStaked);
    }

    // --- Pending reward functions ---

    function getPendingGain(address _token, address _user) external view override returns (uint) {
        return _getPendingGain(_token, _user);
    }

    function _getPendingGain(address _token, address _user) internal view returns (uint) {
        uint currentStake = _stakes(_user);
        uint lastStake = lastStakes[_user];
        uint stake = currentStake < lastStake ? currentStake: lastStake;
        
        uint feePerTokenStakedSnapshot = snapshots[_user][_token];
        uint tokenGain = stake.mul(feePerTokenStaked[_token].sub(feePerTokenStakedSnapshot)).div(DECIMAL_PRECISION);
        return tokenGain;
    }

    function getFeeTokens() external view returns (address[] memory) {
        return feeTokens;
    }

    // --- PYQStaking view function --

    function _stakes(address _user) internal view returns (uint) {
        return PYQStaking.stakes(_user);
    }

    function _totalLQTYStaked() internal view returns (uint) {
        return PYQStaking.totalLQTYStaked();
    }

    // --- Internal helper functions ---

    function _transferOut(address _token, address _user, uint _amount) internal {
        if (_amount > 0) {
            if (_token == GAS_TOKEN_ADDR) {
                _sendETHToUser(_user, _amount);
            } else {
                SafeToken.safeTransfer(_token, _user, _amount);
            }
        }
    }

    function _sendETHToUser(address _user, uint _fee) internal {
        emit EtherSent(_user, _fee);
        (bool success, ) = payable(_user).call{value: _fee}("");
        require(success, "failed to send accumulated ETH fee");
    }

    // --- 'require' functions ---

    function _requireCallerIsValidBorrowerOperations() internal view {
        require(isBO[msg.sender], "caller is not valid borrowerOperation");
    }

    function _requireCallerIsValidTroveManager() internal view {
        require(isTM[msg.sender], "caller is not valid troveManager");
    }

    function _requireCallerIsValidActivePool() internal view {
        require(isAP[msg.sender], "caller is not valid ActivePool");
    }

    function _requireCallerIsStakeToken() internal view {
        require(msg.sender == PYQToken, "caller is not stake token");
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'amount must be non-zero');
    }

    function _requireUserHasStake(uint currentStake) internal pure {
        require(currentStake > 0, 'user must have a non-zero stake');
    }

    receive() external payable {
        _requireCallerIsValidActivePool();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "!safeTransferETH");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ITokenStaking {

    // --- Events --
    
    event StakeTokenAddress(address stakeTokenAddress);
    event StableTokenAddress(address stableTokenAddress);
    
    event NewAssetTokenAddress(
        address trovemanager, address borrowerOperation, 
        address activePool, address redeemingFeeToken, address borrowingFeeToken
    );

    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(address indexed staker, address indexed feeToken, uint gain);
    event totalTokenStakedUpdated(uint totalTokenStaked);
    event EtherSent(address account, uint amount);

    event TokenFeeUpdated(address indexed feeToken, uint fee, uint feePerTokenStaked);
    event StakerSnapshotsUpdated(address staker, address token, uint feePerTokenStaked);

    // --- Functions ---

    function setAddresses
    (
        address _pyqStaking,
        address _stakeToken,
        address _borrowingFeeToken,
        address _redeemingFeeToken, 
        address _troveManager,
        address _borrowerOperation,
        address _activaPool
    )  external ;

    function addNewAsset(
        address _borrowingFeeToken,
        address _redeemingFeeToken, 
        address _troveManager,
        address _borrowerOperation,
        address _activaPool
    ) external;


    function claim() external;
    function updateUserStake(address[] calldata _users) external;
    function increaseBorrowingFee(uint _fee) external; 
    function increaseRedeemingFee(uint _fee) external;  
    function increaseTransferFee(uint _fee) external;  
    function getPendingGain(address _token, address _user) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ILQTYStaking {
    function stakes(address _user) external view returns (uint);
    function totalLQTYStaked() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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
pragma solidity 0.6.11;


contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}