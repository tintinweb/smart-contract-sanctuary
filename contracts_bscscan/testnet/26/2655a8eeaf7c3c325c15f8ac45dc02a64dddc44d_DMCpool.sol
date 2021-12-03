/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint amount) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// MasterChef is the master of Good. He can make Good and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Good is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract DMCpool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided. 只要小于总的就行的
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 tokenFees;
        uint256 allstake;
        uint256 bybamount;
        uint256 byballstake;

    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        IERC20 byblpToken; // Address of LP token contract.

        //uint256 allocPoint; // How many allocation points assigned to this pool. Goods to distribute per block.
        uint256 lastRewardBlock; // Last block number that Goods distribution occurs.
        uint256 accGoodPerShare; // Accumulated Goods per share, times 1e12. See below.
    }
    // The Good TOKEN!
    IERC20 public dmc;
    uint256 public dmcPerBlock;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public lpmap;
    uint256 public startBlock;
    address public owner;
    address public handling = 0x692b51EBD436830a0b1Cc9Bb9B50cf52Bb7eF878;
    IERC20 public BCG;
    IERC20 public BYB;

    bool public paused = false;
    //IERC20 public dmc;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetPause( bool paused);

    constructor() public {
        dmc = IERC20(0x5Ea003c9D99d8AacEe938F571C3e02f7A7ad4f4f);
        BCG = IERC20(0x8509a22B50bcD0527858468483d7451cA990E566);
        BYB = IERC20(0xdD3de8ecB957705bdD2761455C6CBfC993d4e7d2);
        dmcPerBlock = 190258751902590;
        startBlock = 0;      

        owner = msg.sender; 
        add(address(BCG), address(BYB));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        //uint256 _allocPoint,
        address _lpToken,
        address _byblpToken
        //bool _withUpdate
    ) public onlyOwner {
        // if (_withUpdate) {
        //     massUpdatePools();
        // }
        require(lpmap[_lpToken] == false, "had added this lp token");
        require(_lpToken != address(dmc), "can not add GOOD token");
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        //totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                byblpToken : IERC20(_byblpToken),
                //allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGoodPerShare: 0
            })
        );
        lpmap[_lpToken] = true;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
            return _to.sub(_from);
    }

    // View function to see pending Goods on frontend.
    function pendingGood(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGoodPerShare = pool.accGoodPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 dmcReward =
                multiplier.mul(dmcPerBlock);
            accGoodPerShare = accGoodPerShare.add(
                dmcReward.mul(1e12).div(lpSupply)
            );
        }
        //return user.amount.mul(accGoodPerShare).div(1e12).sub(user.rewardDebt);
        uint256 userreward= user.amount.mul(accGoodPerShare).div(1e12).sub(user.rewardDebt);
        return userreward.add(user.tokenFees);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 dmcReward =
            multiplier.mul(dmcPerBlock);
        //dmc.mint(devaddr, dmcReward.div(10));
        //dmc.mint(address(this), dmcReward);
        pool.accGoodPerShare = pool.accGoodPerShare.add(
            dmcReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    uint256 public multipl=8000;
    // Deposit LP tokens to MasterChef for Good allocation.
    function deposit(uint256 _pid, uint256 _bcgamount) public  notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accGoodPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            //safeGoodTransfer(msg.sender, pending);
            //user.tokenFees
             //user.tokenFees+=pending;
             user.tokenFees=user.tokenFees.add(pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _bcgamount
        );
        pool.byblpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _bcgamount.div(multipl)
        );

        user.amount = user.amount.add(_bcgamount.mul(98).div(100));
        user.allstake= user.allstake.add(_bcgamount.mul(98).div(100));
        user.bybamount =  user.bybamount .add(_bcgamount.div(multipl));
        user.byballstake = user.byballstake .add(_bcgamount.div(multipl));

        user.rewardDebt = user.amount.mul(pool.accGoodPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _bcgamount.mul(98).div(100));
    }

    // Withdraw LP tokens from MasterChef.
    //Withdraw LP token   sss
    function withdrawLP(uint256 _pid, uint256 _amount) public notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not dmc");
        require(_amount > 0, "withdraw: not dmc");

        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accGoodPerShare).div(1e12).sub(
                user.rewardDebt
            );
        //safeGoodTransfer(msg.sender, pending);
        //user.tokenFees+=pending;
        user.tokenFees = user.tokenFees.add(pending);
        //if (_amount > 0) {
        //BCG.safeTransferFrom(msg.sender, handling, 10000000000000000000);
          
        user.amount = user.amount.sub(_amount);
        user.allstake = user.allstake.sub(_amount);
        user.bybamount = user.bybamount.sub(_amount.div(multipl));
        user.byballstake = user.byballstake.sub(_amount.div(multipl));

        user.rewardDebt = user.amount.mul(pool.accGoodPerShare).div(1e12);

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.byblpToken.safeTransfer(address(msg.sender), _amount.div(multipl));

        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawGoodToken(uint256 _pid, uint256 _amount) public  notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accGoodPerShare).div(1e12).sub(
                user.rewardDebt
            );
        uint256 allusertemp=pending.add(user.tokenFees);
        require(allusertemp >= _amount, "withdraw: not dmc");
        user.tokenFees=allusertemp.sub(_amount);
       // uint256 tradfFee = 5;
       //uint256 lirunFee = _amount.mul(tradfFee).div(100);
        //safeGoodTransfer(handling, lirunFee);
        safeGoodTransfer(msg.sender, _amount);
        //user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGoodPerShare).div(1e12);
       // pool.lpToken.safeTransfer(address(msg.sender), _amount);
       // emit WithdrawUToken(msg.sender, lpaddress, _amount);
    }


    // Safe dmc transfer function, just in case if rounding error causes pool to not have enough Goods.
    function safeGoodTransfer(address _to, uint256 _amount) internal {
            dmc.mint(_to, _amount);
        // uint256 dmcBal = dmc.balanceOf(address(this));
        // if (_amount > dmcBal) {
        //     dmc.transfer(_to, dmcBal);
        // } else {
        //     dmc.transfer(_to, _amount);
        // }
    }

    // Update dev address by the previous dev.
    // function dev(address _devaddr) public {
    //     require(msg.sender == devaddr, "dev: wut?");
    //     devaddr = _devaddr;
    // }


    function setdmcPerBlock(uint256 _dmcPerBlock) public onlyOwner  {
        massUpdatePools();
        dmcPerBlock = _dmcPerBlock;
    }

    function setHandlingFee(address _handling) public onlyOwner  {
        handling = _handling;
    }


    function setPause() public onlyOwner {
        paused = !paused;
        emit SetPause(paused);

    }
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function CrossTransfer(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
   }

  function PayTransfer() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
  }
  

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
}