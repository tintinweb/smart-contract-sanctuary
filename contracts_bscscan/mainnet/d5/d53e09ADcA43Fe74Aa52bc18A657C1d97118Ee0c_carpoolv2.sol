/**
 *Submitted for verification at BscScan.com on 2021-10-20
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

// MasterChef is the master of Car. He can make Car and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Car is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract carpoolv2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 tokenFees;
        uint256 haddraw;


        //
        // We do some fancy math here. Basically, any point in time, the amount of Cars
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCarPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCarPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        //uint256 allocPoint; // How many allocation points assigned to this pool. Cars to distribute per block.
        uint256 lastRewardBlock; // Last block number that Cars distribution occurs.
        uint256 accCarPerShare; // Accumulated Cars per share, times 1e12. See below.
        uint256 stakeall;
        uint256 lasttime;
    }
    // The Car TOKEN!
    IERC20 public car;
    // Dev address.
   // address public devaddr;
    // Block number when bonus Car period ends.
   // uint256 public bonusEndBlock;
    // Car tokens created per block.
    uint256 public carPerBlock;
    // Bonus muliplier for early car makers.
    //uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    //IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

   mapping(address => bool) public lpmap;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    //uint256 public totalAllocPoint = 0;
    // The block number when Car mining starts.
    uint256 public startBlock;

    address public owner;
    
    address public handling = 0xeB6559dA0FeF120e79D05ae086bbA2EAffcE53fA;
    
    IERC20 public usdt;
    bool public paused = false;

    uint256 starttime;
    uint256 oneweek= 1 weeks;
    //IERC20 public car;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetPause( bool paused);

    constructor(
        IERC20 _car,
        //IERC20 _usdt,
        //address _devaddr,
        uint256 _carPerBlock,
        uint256 _startBlock,
        uint256 _starttime
    ) public {
        car = _car;
       // usdt = _usdt;
       // devaddr = _devaddr;
        carPerBlock = _carPerBlock;
        //bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        starttime = _starttime;
        //car = _car;
        owner = msg.sender; 
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        //uint256 _allocPoint,
        address _lpToken
        //bool _withUpdate
    ) public onlyOwner {
        // if (_withUpdate) {
        //     massUpdatePools();
        // }
        require(lpmap[_lpToken] == false, "had added this lp token");
        require(_lpToken != address(car), "can not add GOOD token");
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        //totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                //allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCarPerShare: 0,
                stakeall:0,
                lasttime:0
            })
        );
        lpmap[_lpToken] = true;
    }



    // Return reward multiplier over the given _from to _to block.
     function getMultiplier(uint256 _from, uint256 _lasttime,uint256 _to)
        public
        view
        returns (uint256)
    {
            uint256 lastimewk= _lasttime.sub(starttime).div(oneweek);
            uint256 nowwk = block.timestamp.sub(starttime).div(oneweek);
            uint256 beforewk=((lastimewk+1).mul(oneweek).sub(_lasttime.sub(starttime))).div(3);
            uint256 lastdeepvale=carPerBlock.mul(9**lastimewk).div(10**lastimewk);

            uint256 deepvale=carPerBlock.mul(9**nowwk).div(10**nowwk);
            uint256 afterwk=(block.timestamp.sub(starttime).sub(oneweek.mul(nowwk))).div(3);
            if (lastimewk == nowwk ) {
                if (nowwk ==0 ) {
                return (_to.sub(_from)).mul(carPerBlock);
                } else {
                return (_to.sub(_from)).mul(deepvale);
                }
            } else {
                uint256  subwk=nowwk-lastimewk;
                if (subwk ==1) {
                    return beforewk.mul(lastdeepvale) +
                    (afterwk).mul(deepvale);
                } else {
                    uint256 all=0;
                    for(uint256 i=lastimewk;i<=nowwk;i++) {
                        if (i==lastimewk ) {
                            all=all.add(beforewk.mul(lastdeepvale));
                        } else if (i==nowwk ) {
                            all=all.add((afterwk).mul(deepvale));
                        } else {
                            all=all.add(oneweek.div(3).mul(carPerBlock).mul(9**i).div(10**i));
                        }
                    }
                    return all;
                }
            }
           // return _to.sub(_from);
    }

    
function getPoolUser(uint256 _pid,address _user) public view 
    returns(
        uint256 amount,
        uint256 haddraw
            ) { 
            amount = userInfo[_pid][_user].amount;
            haddraw = userInfo[_pid][_user].haddraw;
        }

    // View function to see pending Cars on frontend.
    function pendingCar(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCarPerShare = pool.accCarPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // uint256 multiplier =
            //     getMultiplier(pool.lastRewardBlock, block.number);
            uint256 carReward =getMultiplier(pool.lastRewardBlock,pool.lasttime, block.number);


            accCarPerShare = accCarPerShare.add(
                carReward.mul(1e12).div(lpSupply)
            );
        }
        //return user.amount.mul(accCarPerShare).div(1e12).sub(user.rewardDebt);
        uint256 userreward= user.amount.mul(accCarPerShare).div(1e12).sub(user.rewardDebt);
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
            pool.lasttime = block.timestamp;
            return;
        }
        //uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 carReward =getMultiplier(pool.lastRewardBlock,pool.lasttime, block.number);
        //car.mint(devaddr, carReward.div(10));
        //car.mint(address(this), carReward);
        pool.accCarPerShare = pool.accCarPerShare.add(
            carReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
        pool.lasttime = block.timestamp;

    }

    // Deposit LP tokens to MasterChef for Car allocation.
    function deposit(uint256 _pid, uint256 _amount) public  notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accCarPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            //safeCarTransfer(msg.sender, pending);
            //user.tokenFees
             //user.tokenFees+=pending;
             user.tokenFees=user.tokenFees.add(pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        pool.stakeall =pool.stakeall.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCarPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    //Withdraw LP token   sss
    function withdrawLP(uint256 _pid, uint256 _amount) public notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not car");
        require(_amount > 0, "withdraw: not car");

        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accCarPerShare).div(1e12).sub(
                user.rewardDebt
            );
        //safeCarTransfer(msg.sender, pending);
        //user.tokenFees+=pending;
        user.tokenFees = user.tokenFees.add(pending);
        //if (_amount > 0) {
         //  usdt.safeTransferFrom(msg.sender, handling, 10000000000000000000);
        safeCarTransfer(msg.sender, user.tokenFees);
        user.haddraw=user.haddraw.add(_amount);
        user.tokenFees =0;

        user.amount = user.amount.sub(_amount);
        pool.stakeall = pool.stakeall.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accCarPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawCarToken(uint256 _pid, uint256 _amount) public  notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accCarPerShare).div(1e12).sub(
                user.rewardDebt
            );
        uint256 allusertemp=pending.add(user.tokenFees);
        require(allusertemp >= _amount, "withdraw: not car");
        user.tokenFees=allusertemp.sub(_amount);

    //     uint256 tradfFee = 5;
    //    uint256 lirunFee = _amount.mul(tradfFee).div(100);
    //    safeCarTransfer(handling, lirunFee);
        //safeCarTransfer(msg.sender, _amount.sub(lirunFee));
       safeCarTransfer(msg.sender, _amount);
       user.haddraw=user.haddraw.add(_amount);
        //user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accCarPerShare).div(1e12);
       // pool.lpToken.safeTransfer(address(msg.sender), _amount);
       // emit WithdrawUToken(msg.sender, lpaddress, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // function emergencyWithdraw(uint256 _pid) public {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    //     emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    //     user.amount = 0;
    //     user.rewardDebt = 0;
    // }

    // Safe car transfer function, just in case if rounding error causes pool to not have enough Cars.
    function safeCarTransfer(address _to, uint256 _amount) internal {
        uint256 carBal = car.balanceOf(address(this));
        if (_amount > carBal) {
            car.transfer(_to, carBal);
        } else {
            car.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    // function dev(address _devaddr) public {
    //     require(msg.sender == devaddr, "dev: wut?");
    //     devaddr = _devaddr;
    // }


    function setcarPerBlock(uint256 _carPerBlock) public onlyOwner  {
        massUpdatePools();
        carPerBlock = _carPerBlock;
    }

    function setHandlingFee(address _handling) public onlyOwner  {
        handling = _handling;
    }
    
    // function setusdtToken(IERC20 _usdt) public onlyOwner  {
    //     usdt = _usdt;
    // }
    // function setcarToken(IERC20 _car) public onlyOwner  {
    //     car = _car;
    // }

    // function getTokens(IERC20 _car,uint256 _amount) public onlyOwner  {
    //     _car.transfer(msg.sender, _amount);
    // }
    function setStarttime(uint256 _starttime) public onlyOwner {
        starttime = _starttime;
    }

    function setPause() public onlyOwner {
        paused = !paused;
        emit SetPause(paused);

    }
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        require(starttime <= block.timestamp, "Mining has not start");

        _;
    }



    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
}