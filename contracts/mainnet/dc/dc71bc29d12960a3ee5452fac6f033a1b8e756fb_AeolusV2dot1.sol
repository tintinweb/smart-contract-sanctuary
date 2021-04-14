/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// File: contracts/math/SafeMath.sol

pragma solidity <0.6 >=0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  /*@CTK SafeMath_mul
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a * b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  /*@CTK SafeMath_div
    @tag spec
    @pre b != 0
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a / b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  /*@CTK SafeMath_sub
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a - b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  /*@CTK SafeMath_add
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a + b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/ownership/Ownable.sol

pragma solidity <6.0 >=0.4.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/token/IERC20Basic.sol

pragma solidity <0.6 >=0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract IERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/IERC20.sol

pragma solidity <0.6 >=0.4.21;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 is IERC20Basic {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/IMintableToken.sol

pragma solidity <0.6 >=0.4.24;


contract IMintableToken is IERC20 {
    function mint(address, uint) external returns (bool);
    function burn(uint) external returns (bool);

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
}

// File: contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/token/SafeERC20.sol

pragma solidity ^0.5.0;




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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/uniswapv2/IRouter.sol

pragma solidity >=0.5.0 <0.8.0;

interface IRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// File: contracts/AeolusV2dot1.sol

pragma solidity <0.6 >=0.4.24;







// Aeolus is the master of Cyclone tokens. He can distribute CYC and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CYC is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract AeolusV2dot1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CYCs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * accCYCPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. Update accCYCPerShare and lastRewardBlock
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }


    // Address of LP token contract.
    IERC20 public lpToken;
    // Accumulated CYCs per share, times 1e12. See below.
    uint256 public accCYCPerShare;
    // Last block reward block height
    uint256 public lastRewardBlock;
    // Reward per block
    uint256 public rewardPerBlock;
    // Reward to distribute
    uint256 public rewardToDistribute;
    // Entrance Fee Rate
    uint256 public entranceFeeRate;

    IERC20 public wrappedCoin;
    IRouter public router;
    // The Cyclone TOKEN
    IMintableToken public cycToken;

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;

    event RewardAdded(uint256 amount, bool isBlockReward);
    event Deposit(address indexed user, uint256 amount, uint256 fee);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(IMintableToken _cycToken, IERC20 _lpToken, address _router, IERC20 _wrappedCoin) public {
        cycToken = _cycToken;
        lastRewardBlock = block.number;
        lpToken = _lpToken;
        router = IRouter(_router);
        wrappedCoin = _wrappedCoin;
        require(_lpToken.approve(_router, uint256(-1)), "failed to approve router");
        require(_wrappedCoin.approve(_router, uint256(-1)), "failed to approve router");
    }

    function setEntranceFeeRate(uint256 _entranceFeeRate) public onlyOwner {
        require(_entranceFeeRate < 10000, "invalid entrance fee rate");
        entranceFeeRate = _entranceFeeRate;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        updateBlockReward();
        rewardPerBlock = _rewardPerBlock;
    }

    function rewardPending() internal view returns (uint256) {
        uint256 reward = block.number.sub(lastRewardBlock).mul(rewardPerBlock);
        uint256 cycBalance = cycToken.balanceOf(address(this)).sub(rewardToDistribute);
        if (cycBalance < reward) {
            return cycBalance;
        }
        return reward;
    }

    // View function to see pending reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 acps = accCYCPerShare;
        if (rewardPerBlock > 0) {
            uint256 lpSupply = lpToken.balanceOf(address(this));
            if (block.number > lastRewardBlock && lpSupply > 0) {
                acps = acps.add(rewardPending().mul(1e12).div(lpSupply));
            }
        }

        return user.amount.mul(acps).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables to be up-to-date.
    function updateBlockReward() public {
        if (block.number <= lastRewardBlock || rewardPerBlock == 0) {
            return;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this));
        uint256 reward = rewardPending();
        if (lpSupply == 0 || reward == 0) {
            lastRewardBlock = block.number;
            return;
        }
        rewardToDistribute = rewardToDistribute.add(reward);
        emit RewardAdded(reward, true);
        lastRewardBlock = block.number;
        accCYCPerShare = accCYCPerShare.add(reward.mul(1e12).div(lpSupply));
    }

    // Deposit LP tokens to Aeolus for CYC allocation.
    function deposit(uint256 _amount) public {
        updateBlockReward();
        UserInfo storage user = userInfo[msg.sender];
        uint256 originAmount = user.amount;
        uint256 acps = accCYCPerShare;
        if (originAmount > 0) {
            uint256 pending = originAmount.mul(acps).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeCYCTransfer(msg.sender, pending);
            }
        }
        uint256 feeInCYC = 0;
        if (_amount > 0) {
            lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 entranceFee = _amount.mul(entranceFeeRate).div(10000);
            if (entranceFee > 0) {
                IERC20 wct = wrappedCoin;
                (uint256 wcAmount, uint256 cycAmount) = router.removeLiquidity(address(wct), address(cycToken), entranceFee, 0, 0, address(this), block.timestamp.mul(2));
                if (wcAmount > 0) {
                    address[] memory path = new address[](2);
                    path[0] = address(wct);
                    path[1] = address(cycToken);
                    uint256[] memory amounts = router.swapExactTokensForTokens(wcAmount, 0, path, address(this), block.timestamp.mul(2));
                    feeInCYC = cycAmount.add(amounts[1]);
                } else {
                    feeInCYC = cycAmount;
                }
                if (feeInCYC > 0) {
                    require(cycToken.burn(feeInCYC), "failed to burn cyc token");
                }
                _amount = _amount.sub(entranceFee);
            }
            user.amount = originAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(acps).div(1e12);
        emit Deposit(msg.sender, _amount, feeInCYC);
    }

    // Withdraw LP tokens from Aeolus.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 originAmount = user.amount;
        require(originAmount >= _amount, "withdraw: not good");
        updateBlockReward();
        uint256 acps = accCYCPerShare;
        uint256 pending = originAmount.mul(acps).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeCYCTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = originAmount.sub(_amount);
            lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(acps).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    // Safe CYC transfer function, just in case if rounding error causes pool to not have enough CYCs.
    function safeCYCTransfer(address _to, uint256 _amount) internal {
        IMintableToken token = cycToken;
        uint256 cycBalance = token.balanceOf(address(this));
        if (_amount > cycBalance) {
            _amount = cycBalance;
        }
        rewardToDistribute = rewardToDistribute.sub(_amount);
        require(token.transfer(_to, _amount), "failed to transfer cyc token");
    }
}