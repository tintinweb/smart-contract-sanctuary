/**
 *Submitted for verification at BscScan.com on 2021-09-02
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
        uint256[] amountDetail;
        uint256[] createDates;
        uint256 amountUSD;
        uint256 lastClaim;
        address topLead;
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

    uint256 public rewardPerBlock=320000000;
    
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;

    uint256 public startBlock=9796890;

    uint256 public bonusEndBlock=41332890;

    // Top Leader address for referral
    address public topLeaderAddress;
    
    IReferral public referral;
    // Referral commission rate: 20%.
    uint16 public referralCommissionRate = 2000;
    // Maximum referral commission rate: 25%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 2500;
    // daily reward: 1%.
    uint16 public dailyReward = 100;
    // contract length in day
    uint256 public contractLength = 0; 
    // top leader commission 10%
    uint16 public topLeaderRate = 10;
    uint16 public referral1Rate = 5;
    uint16 public referral2Rate = 3;
    uint16 public referral3Rate = 2;
    

    //all refer address
    mapping(address=>address) public refer;
    //all top leader
    mapping(address=>bool) public mapTopLeader;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        IBEP20 _salsa,
        IBEP20 _rewardToken,
        IReferral _referral
    ) public {
        salsa = _salsa;
        rewardToken = _rewardToken;
        referral = _referral;
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
    
    function getRefer(address _user) public view returns (address) {
        return refer[_user];
    }
    
    function getTopLead(address _user) public view returns (bool) {
        return mapTopLeader[_user];
    }
    
    //return totalAmountCanRemove
    function getTotalAmountCanRemove(address _user) public view returns (uint256){
        UserInfo storage user = userInfo[_user];
        uint256[] storage contractdate = user.createDates;
        uint256 totalAmount = 0;
        for(uint i=0; i<contractdate.length; i++){
            uint256 end = contractdate[i] + contractLength*86400;
            if(block.timestamp >= end){
                totalAmount = totalAmount + user.amountDetail[i];
            }
        }
        return totalAmount;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        // per daily
        uint256 rew = (user.amountUSD*(block.timestamp - user.lastClaim)*dailyReward)/8640000/1000000;
        return rew;
    }
    
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
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

    //find top leader if exist
    function getTopLeader(address _user) internal view returns (address) {
        address _refer = referral.getReferrer(_user);
        while(_refer != address(0)){
            if(mapTopLeader[_refer]){
                return _refer;
            }else{
                _refer = referral.getReferrer(_refer);
            }
        }
        return address(0);
    }


    function deposit(uint256 _amount, address _referrer, uint256 _tokenPrice) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        updatePool(0);
        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
            refer[msg.sender] = _referrer;
            address _topLeader = getTopLeader(msg.sender);
            if(_topLeader != address(0) && _topLeader != msg.sender){
                user.topLead = _topLeader;
            }
        }
        if (user.amount > 0) {
            uint256 pending = pendingReward(msg.sender)*10000000000;
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending.mul(8).div(10));
                payReferralCommission(msg.sender, pending);
                user.lastClaim = block.timestamp;
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            totalStakedAmount = totalStakedAmount.add(_amount);
            user.lastClaim = block.timestamp;
            user.amountDetail.push(_amount);
            user.createDates.push(block.timestamp);
            user.amountUSD = user.amountUSD.add(user.amount.mul(_tokenPrice));
        }
        user.rewardDebt = user.amount.mul(pool.accKiwiPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) public {
        if(_amount<=getTotalAmountCanRemove(msg.sender)){
            PoolInfo storage pool = poolInfo[0];
            UserInfo storage user = userInfo[msg.sender];
            require(user.amount >= _amount, "withdraw: not good");
            updatePool(0);
            uint256 pending = pendingReward(msg.sender)*10000000000;
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending.mul(8).div(10));
                payReferralCommission(msg.sender, pending);
                user.lastClaim = block.timestamp;
            }
            if(_amount > 0) {
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
                //remove amount in array
                uint256 removeAmount = 0;
                uint256 totalWasRemove = _amount;
                for(uint i=0; i<user.createDates.length; i++){
                    uint256 end = user.createDates[i] + contractLength*86400;
                    if(block.timestamp >= end && removeAmount<_amount && totalWasRemove>0){
                        totalWasRemove = totalWasRemove - user.amountDetail[i];
                        if(totalWasRemove>0){
                            //remove array
                            delete user.amountDetail[i];
                            delete user.createDates[i];
                            user.amountUSD = user.amountUSD * (1-user.amountDetail[i]/user.amount);
                            removeAmount = removeAmount + user.amountDetail[i];
                            user.amount = user.amount-user.amountDetail[i];
                        }else{
                            //update array
                            uint256 lastremove = _amount-removeAmount;
                            user.amountDetail[i] = user.amountDetail[i] - lastremove;
                            user.amountUSD = user.amountUSD * (1-lastremove/user.amount);
                            removeAmount = removeAmount + lastremove;
                            user.amount = user.amount-lastremove;
                        }
                    }
                }
                totalStakedAmount = totalStakedAmount.sub(_amount);
            }
            user.rewardDebt = user.amount.mul(pool.accKiwiPerShare).div(1e12);
    
            emit Withdraw(msg.sender, _amount);
        }
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
    
    // Update top leader rate
    function setTopLeaderRate(uint16 _topLeaderRate) public onlyOwner {
        topLeaderRate = _topLeaderRate;
    }
    
    // Update referral rate level 1
    function setReferral1Rate(uint16 _referral1Rate) public onlyOwner {
        referral1Rate = _referral1Rate;
    }
    
    // Update referral rate level 2
    function setReferral2Rate(uint16 _referral2Rate) public onlyOwner {
        referral2Rate = _referral2Rate;
    }
    
    // Update referral rate level 3
    function setReferral3Rate(uint16 _referral3Rate) public onlyOwner {
        referral3Rate = _referral3Rate;
    }
    

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }
    
    //update daily rewardToken
    function setDailyReward(uint16 _dailyReward) public onlyOwner{
        dailyReward = _dailyReward;
    }
    
    //update contractLength
    function setContractLength(uint16 _contractLength) public onlyOwner{
        contractLength = _contractLength;
    }
    
    //assign top leader
    function assignTopLeader(address _topLeader) public onlyOwner{
        mapTopLeader[_topLeader] = true;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        uint256 commissionAmount = _pending.mul(topLeaderRate).div(100);
        if(commissionAmount>0){
            //pay to top Leader
            address tpLeader = userInfo[_user].topLead;
            if(tpLeader != address(0)){
                rewardToken.safeTransfer(tpLeader, commissionAmount);
                emit ReferralCommissionPaid(_user, topLeaderAddress, commissionAmount);
            }
            
            if(address(referral) != address(0)){
                //pay to referral level 1
                address _referrallevel1 = refer[_user];
                //address _referrallevel1 = referral.getReferrer(_user);
                if(_referrallevel1 != address(0)){
                    uint256 commissionAmount1 = _pending.mul(referral1Rate).div(100);
                    rewardToken.safeTransfer(_referrallevel1, commissionAmount1);
                    emit ReferralCommissionPaid(_user, _referrallevel1, commissionAmount1);
                    
                    //pay to referral level 2
                    address _referrallevel2 = refer[_referrallevel1];
                    //address _referrallevel2 = referral.getReferrer(_referrallevel1);
                    if(_referrallevel2 != address(0)){
                        uint256 commissionAmount2 = _pending.mul(referral2Rate).div(100);
                        rewardToken.safeTransfer(_referrallevel2, commissionAmount2);
                        emit ReferralCommissionPaid(_user, _referrallevel2, commissionAmount2);
                        
                        //pay to referral level 3
                        address _referrallevel3 = refer[_referrallevel2];
                        //address _referrallevel3 = referral.getReferrer(_referrallevel2);
                        if(_referrallevel3 != address(0)){
                            uint256 commissionAmount3 = _pending.mul(referral3Rate).div(100);
                            rewardToken.safeTransfer(_referrallevel3, commissionAmount3);
                            emit ReferralCommissionPaid(_user, _referrallevel3, commissionAmount3);
                        }
                    }
                }
            }
        }
    }
    
}