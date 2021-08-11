/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-18
*/

// SPDX-License-Identifier: GPL-v3.0



pragma solidity >=0.4.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}




pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




pragma solidity ^0.6.2;


library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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




pragma solidity ^0.6.0;


library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}




pragma solidity >=0.4.0;

contract Context {

    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




pragma solidity >=0.4.0;


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.6.2;

interface IReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

// File: contracts/SmartChef.sol

pragma solidity >=0.6.2;





// import "@nomiclabs/buidler/console.sol";


contract SmartChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. KIWIs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that KIWIs distribution occurs.
        uint256 accKiwiPerShare; // Accumulated KIWIs per share, times 1e12. See below.
    }


    IBEP20 public salsa;
    IBEP20 public rewardToken;

    uint256 public totalStakedAmount;

    uint256 public rewardPerBlock;
    
    uint256 public rewardPerBlock1;
    
    uint256 public rewardPerBlock2;
    
    uint256 public rewardPerBlock3;
    
    //end contract for all address
    mapping(address=>uint256) public timeEndContract;
    
    //contract type for all address
    mapping(address=>uint16) public contractType;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;

    uint256 public startBlock;

    uint256 public bonusEndBlock;

    // Top Leader address for referral
    address public topLeaderAddress;
    
    // referral level 1
    address public referrallevel1;
    
    // referral level 2
    address public referrallevel2;
    
    // referral level 3
    address public referrallevel3;


    IReferral public referral;
    // Referral commission rate: 20%.
    uint16 public referralCommissionRate = 2000;
    // Maximum referral commission rate: 25%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 2500;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        IBEP20 _salsa,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _rewardPerBlock1,
        uint256 _rewardPerBlock2,
        uint256 _rewardPerBlock3,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        address _topLeaderAddress
    ) public {
        salsa = _salsa;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        rewardPerBlock1= _rewardPerBlock1;
        rewardPerBlock2= _rewardPerBlock2;
        rewardPerBlock3= _rewardPerBlock3;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        topLeaderAddress = _topLeaderAddress;
        totalStakedAmount = 0;
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _salsa,
            allocPoint: 4000,
            lastRewardBlock: startBlock,
            accKiwiPerShare: 0
        }));

        totalAllocPoint = 4000;

    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accKiwiPerShare = pool.accKiwiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint _reward = rewardPerBlock3;
            if(contractType[_user]==1){
                _reward = rewardPerBlock1;
            }else if(contractType[_user]==2){
                 _reward = rewardPerBlock2;
            }
            uint256 pizzaReward = multiplier.mul(_reward).mul(pool.allocPoint).div(totalAllocPoint);
            accKiwiPerShare = accKiwiPerShare.add(pizzaReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accKiwiPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 pizzaReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accKiwiPerShare = pool.accKiwiPerShare.add(pizzaReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }



    function deposit(uint256 _amount, address _referrer) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        updatePool(0);
        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accKiwiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending.mul(8).div(10));
                payReferralCommission(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            totalStakedAmount = totalStakedAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accKiwiPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }


    function withdraw(uint256 _amount) public {
        require (block.timestamp>=timeEndContract[msg.sender]);
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accKiwiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending.mul(8).div(10));
            payReferralCommission(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalStakedAmount = totalStakedAmount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accKiwiPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    function getTotalStakedAmount() public view returns (uint256){
        return totalStakedAmount;
    }


    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        totalStakedAmount = totalStakedAmount.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }


    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _rewardPerBlock) public onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }
    
    function updateRewardPerBlock1(uint256 _rewardPerBlock1) public onlyOwner {
        massUpdatePools();
        rewardPerBlock1 = _rewardPerBlock1;
    }
    
    function updateRewardPerBlock2(uint256 _rewardPerBlock2) public onlyOwner {
        massUpdatePools();
        rewardPerBlock2 = _rewardPerBlock2;
    }
    
    function updateRewardPerBlock3(uint256 _rewardPerBlock3) public onlyOwner {
        massUpdatePools();
        rewardPerBlock3 = _rewardPerBlock3;
    }
    
    // Update the given pool's WDEFI allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(_allocPoint);
        poolInfo[0].allocPoint = _allocPoint;
    }

    // Update the referral contract address by the owner
    function setReferralAddress(IReferral _referral) external onlyOwner {
        referral = _referral;
    }

    // Update Top Leader for referral
    function setTopLeaderAddress(address _topLeaderAddress) public onlyOwner {
        topLeaderAddress = _topLeaderAddress;
    }
    
    // Update referral level 1
    function setReferrallevel1(address _referrallevel1) public onlyOwner {
        referrallevel1 = _referrallevel1;
    }
    
    // Update referral level 2
    function setReferrallevel2(address _referrallevel2) public onlyOwner {
        referrallevel2 = _referrallevel2;
    }
    
    // Update referral level 3
    function setReferrallevel3(address _referrallevel3) public onlyOwner {
        referrallevel3 = _referrallevel3;
    }
    

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address _referrallevel1 = referral.getReferrer(_user);
            address _referrallevel2 = referral.getReferrer(_referrallevel1);
            address _referrallevel3 = referral.getReferrer(_referrallevel2);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(20000);

            if (_referrallevel1 != address(0) && commissionAmount > 0) {
                uint256 commissionAmount1 = _pending.mul(5).div(100);
                uint256 commissionAmount2 = _pending.mul(3).div(100);
                uint256 commissionAmount3 = _pending.mul(2).div(100);
                rewardToken.safeTransfer(_referrallevel1, commissionAmount1);
                rewardToken.safeTransfer(_referrallevel2, commissionAmount2);
                rewardToken.safeTransfer(_referrallevel3, commissionAmount3);
                rewardToken.safeTransfer(topLeaderAddress, commissionAmount);
                emit ReferralCommissionPaid(_user, _referrallevel1, commissionAmount1);
                emit ReferralCommissionPaid(_user, _referrallevel2, commissionAmount2);
                emit ReferralCommissionPaid(_user, _referrallevel3, commissionAmount3);
                emit ReferralCommissionPaid(_user, topLeaderAddress, commissionAmount);
            }
        }
    }
    
}