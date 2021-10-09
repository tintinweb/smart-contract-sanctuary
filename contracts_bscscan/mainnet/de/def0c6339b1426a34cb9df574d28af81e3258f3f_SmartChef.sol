/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-04
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

pragma solidity >=0.5.16;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IReferralUpgrade {
    
    function getTopLeaderByUser(address _user) external view returns (address);

    function getLeaderByUser(address _user) external view returns (address);
    
    function updateSales(address _user,uint256 _amount) external;
}

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

contract SmartChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    //info for each depo
    struct DepoDetail{
        uint256 id;
        uint256 amount;
        uint256 amountUSD;
        uint256 createDates;
        uint256 typeContract;
    }
    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 amountUSD6;
        uint256 dailyReward6;
        uint256 amountUSD12;
        uint256 dailyReward12; 
        DepoDetail[] depoDetail;
        uint256 lastClaim;
        address topLead;
        address lead;
        uint256 totalSales;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;  
        address lp;
        IBEP20 rewardToken;
        uint256 totalStaked;
        uint256 totalStakedUSD;
        uint256 lastTimeReward;
    }


    IBEP20 public salsa;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;

    IReferral public referral;
    IReferralUpgrade public referralUpgrade;
    // Referral commission rate: 20%.
    uint256 public referralCommissionRate = 2000;
    // Maximum referral commission rate: 25%.
    uint256 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 2500;
    // daily reward: 1%.
    uint256 public dailyReward6 = 50;
    uint256 public dailyReward12 = 70;
    // contract length in day
    uint256 public contractLength6 = 180; 
    uint256 public contractLength12 = 360; 
    // top leader commission 10%
    uint256 public topLeaderRate = 5;
    uint256 public leaderRate = 5;
    uint256 public referral1Rate = 5;
    uint256 public referral2Rate = 3;
    uint256 public referral3Rate = 2;
    
   
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        IBEP20 _lpToken,
        address _lp,
        IBEP20 _rewardToken,
        IReferral _referral,
        IReferralUpgrade _referralUpgrade
    ) public {
        referral = _referral;
        referralUpgrade = _referralUpgrade;
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lp: _lp,
            totalStaked: 0,
            totalStakedUSD: 0,
            lastTimeReward:0,
            rewardToken:_rewardToken
        }));

    }

    function stopReward(uint256 _pid) public onlyOwner {
        poolInfo[_pid].lastTimeReward = block.timestamp;
    }
    
    function getUserInfo(address _user) public view  returns  (UserInfo memory){
        UserInfo storage user = userInfo[_user];
        return user;
    }
    
    function getDepoDetail(address _user) public view  returns  (DepoDetail[] memory){
        UserInfo storage user = userInfo[_user];
        return user.depoDetail;
    }

    //return totalAmountCanRemove
    function getTotalAmountCanRemove(address _user) public view returns (uint256){
        UserInfo storage user = userInfo[_user];
        DepoDetail[] storage depoDetails = user.depoDetail;
        uint256 totalAmount = 0;
        for(uint i=0; i<depoDetails.length; i++){
            DepoDetail storage dp = depoDetails[i];
            uint256 contractLength = contractLength12;
            if(dp.typeContract==1){
                contractLength = contractLength6;
            }
            uint256 end = depoDetails[i].createDates + contractLength*86400;
            if(block.timestamp >= end){
                totalAmount = totalAmount + depoDetails[i].amount;
            }
        }
        return totalAmount;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(uint256 _pid,address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        PoolInfo storage pool = poolInfo[_pid];
        // per daily
        uint256 rew = 0;
        if(pool.lastTimeReward==0){
            rew = ((user.amountUSD6*(block.timestamp - user.lastClaim)*user.dailyReward6)+(user.amountUSD12*(block.timestamp - user.lastClaim)*user.dailyReward12))/8640000/1000000;
        }else{
            rew = ((user.amountUSD6*(pool.lastTimeReward - user.lastClaim)*user.dailyReward6)+(user.amountUSD12*(pool.lastTimeReward - user.lastClaim)*user.dailyReward12))/8640000/1000000;
        }
        
        return rew;
    }
    
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    
    function getLPPrice(address lp) public view returns (uint256){
        uint256 totalSupply = IPancakePair(lp).totalSupply();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(lp).getReserves();
        uint256 price = reserve1*2/totalSupply; 
        return price;
    }


    function deposit(uint256 _pid,uint256 _amount, address _referrer, uint256 _type) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];

        if (address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
            UserInfo storage userRef = userInfo[_referrer];
            address _topLeader = userRef.topLead;
            if(_topLeader == address(0)){
                //lookup upline for top leader
                _topLeader = referralUpgrade.getTopLeaderByUser(msg.sender);
                if(_topLeader != address(0) && msg.sender != _topLeader){
                    //save top leader for upline
                    userRef.topLead = _topLeader;
                }
            }
            address _leader = userRef.lead;
            if(_leader == address(0)){
                //lookup upline for leader
                _leader = referralUpgrade.getLeaderByUser(msg.sender);
                if(_leader != address(0) && msg.sender != _leader){
                    //save top leader for upline
                    userRef.lead = _leader;
                }
            }
            user.lead = _leader;
        }
        if (user.amount > 0) {
            //uint256 pending = pendingReward(_pid,msg.sender)*10000000000;
            uint256 pending = pendingReward(_pid,msg.sender);
            //uint256 pending = 10;
            if(pending > 0) {
                uint256 pendingUser = pendingReward(_pid,msg.sender)*8/10;
                pool.rewardToken.transfer(address(msg.sender), pendingUser);
                payReferralCommission(pool.rewardToken,msg.sender, pending);
                user.lastClaim = block.timestamp;
                user.dailyReward6 = dailyReward6;
                user.dailyReward12 = dailyReward12;
            }
        }
        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            //IPancakePair(pool.lp).transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalStaked = pool.totalStaked.add(_amount);
            uint256 _tokenPrice = getLPPrice(pool.lp);
            pool.totalStakedUSD = pool.totalStakedUSD.add(_amount*_tokenPrice);
            referralUpgrade.updateSales(address(msg.sender),_amount*_tokenPrice);
            user.lastClaim = block.timestamp;
            DepoDetail storage dp;
            dp.amount=_amount;
            dp.amountUSD=_amount*_tokenPrice;
            dp.createDates=block.timestamp;
            dp.typeContract=_type;
            user.depoDetail.push(dp);
            if(_type == 1)
                user.amountUSD6 = user.amountUSD6.add(user.amount*_tokenPrice);
            else
                user.amountUSD12 = user.amountUSD12.add(user.amount*_tokenPrice);
            if(user.dailyReward6==0)
                user.dailyReward6 = dailyReward6;
            if(user.dailyReward12==0)
                user.dailyReward12 = dailyReward12;
        }
        emit Deposit(msg.sender, _amount);
    }
    
    function withdraw(uint256 _pid,uint256 _amount) public {
        if(_amount<=getTotalAmountCanRemove(msg.sender)){
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[msg.sender];
            require(user.amount >= _amount, "withdraw: not good");
            //uint256 pending = pendingReward(_pid,msg.sender)*10000000000;
            uint256 pending = pendingReward(_pid,msg.sender);
            if(pending > 0) {
                uint256 pendingUser = pendingReward(_pid,msg.sender)*8/10;
                pool.rewardToken.transfer(address(msg.sender), pendingUser);
                payReferralCommission(pool.rewardToken,msg.sender, pending);
                user.lastClaim = block.timestamp;
                user.dailyReward6 = dailyReward6;
                user.dailyReward12 = dailyReward12;
            }
            if(_amount > 0) {
                pool.lpToken.transfer(address(msg.sender), _amount);
                //remove amount in array
                uint256 removeAmount = 0;
                uint256 removeAmountUSD = 0;
                uint256 totalWasRemove = _amount;
                DepoDetail[] storage dp = user.depoDetail;
                for(uint i=0; i<dp.length; i++){
                    DepoDetail storage detail = dp[i];
                    uint256 contractLength = contractLength12;
                    if(detail.typeContract==1){
                        contractLength = contractLength6;
                    }
                    uint256 end = detail.createDates + contractLength*86400;
                    if(block.timestamp >= end && removeAmount<_amount && totalWasRemove>0){
                        totalWasRemove = totalWasRemove - detail.amount;
                        if(totalWasRemove>=0){
                            removeAmountUSD = removeAmountUSD + detail.amountUSD;
                            if(detail.typeContract==1)
                                user.amountUSD6 = user.amountUSD6 - detail.amountUSD;
                            else
                                user.amountUSD12 = user.amountUSD12 - detail.amountUSD;
                            removeAmount = removeAmount + detail.amount;
                            user.amount = user.amount-detail.amount;
                            //remove array
                            delete dp[i];
                        }else{
                            //update array
                            uint256 lastremove = _amount-removeAmount;
                            uint256 lastremoveUSD = lastremove/detail.amount*detail.amountUSD;
                            removeAmountUSD = removeAmountUSD + lastremoveUSD;
                            detail.amount = detail.amount - lastremove;
                            if(detail.typeContract==1)
                                user.amountUSD6 = user.amountUSD6 - lastremoveUSD;
                            else
                                user.amountUSD12 = user.amountUSD12  - lastremoveUSD;
                            removeAmount = removeAmount + lastremove;
                            user.amount = user.amount-lastremove;
                        }
                    }
                }
                pool.totalStaked = pool.totalStaked.sub(_amount);
                pool.totalStakedUSD = pool.totalStakedUSD.sub(removeAmountUSD);
            }
    
            emit Withdraw(msg.sender, _amount);
        }
    }

    function getTotalStakedAmount(uint256 pid) public view returns (uint256){
        return poolInfo[pid].totalStaked;
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        pool.totalStaked = pool.totalStaked.sub(user.amount);
        user.amount = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }


    function emergencyRewardWithdraw(uint256 _pid,uint256 _amount) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(_amount < pool.rewardToken.balanceOf(address(this)), 'not enough token');
        pool.rewardToken.transfer(address(msg.sender), _amount);
    }

    // Update the referral contract address by the owner
    function setReferralAddress(IReferral _referral) external onlyOwner {
        referral = _referral;
    }

    
    // Update top leader rate
    function setTopLeaderRate(uint256 _topLeaderRate) public onlyOwner {
        topLeaderRate = _topLeaderRate;
    }
    
    // Update leader rate
    function setLeaderRate(uint256 _leaderRate) public onlyOwner {
        leaderRate = _leaderRate;
    }
    
    // Update referral rate level 1
    function setReferral1Rate(uint256 _referral1Rate) public onlyOwner {
        referral1Rate = _referral1Rate;
    }
    
    // Update referral rate level 2
    function setReferral2Rate(uint256 _referral2Rate) public onlyOwner {
        referral2Rate = _referral2Rate;
    }
    
    // Update referral rate level 3
    function setReferral3Rate(uint256 _referral3Rate) public onlyOwner {
        referral3Rate = _referral3Rate;
    }
    

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint256 _referralCommissionRate) external onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }
    
    //update daily rewardToken
    function setDailyReward6(uint256 _dailyReward6) public onlyOwner{
        dailyReward6 = _dailyReward6;
    }
    
    function setDailyReward12(uint256 _dailyReward12) public onlyOwner{
        dailyReward12 = _dailyReward12;
    }
    
    //update contractLength
    function setContractLength6(uint256 _contractLength6) public onlyOwner{
        contractLength6 = _contractLength6;
    }
    
    function setContractLength12(uint16 _contractLength12) public onlyOwner{
        contractLength12 = _contractLength12;
    }
    
    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(IBEP20 _rewardToken,address _user, uint256 _pending) internal {
        uint256 commissionAmount = _pending*topLeaderRate/100;
        UserInfo storage user = userInfo[_user];
        if(commissionAmount>0){
            //pay to top Leader
            address tpLeader = user.topLead;
            if(tpLeader != address(0)){
                _rewardToken.transfer(tpLeader, commissionAmount);
                emit ReferralCommissionPaid(_user, tpLeader, commissionAmount);
            }
            
            //pay to Leader
            uint256 commissionAmountLead = _pending*leaderRate/100;
            address lowlead = user.lead;
            if(lowlead != address(0)){
                _rewardToken.transfer(lowlead, commissionAmountLead);
                emit ReferralCommissionPaid(_user, lowlead, commissionAmountLead);
            }
            
            if(address(referral) != address(0)){
                //pay to referral level 1
                //address _referrallevel1 = refer[_user];
                address _referrallevel1 = referral.getReferrer(_user);
                if(_referrallevel1 != address(0)){
                    uint256 commissionAmount1 = _pending.mul(referral1Rate).div(100);
                    _rewardToken.transfer(_referrallevel1, commissionAmount1);
                    emit ReferralCommissionPaid(_user, _referrallevel1, commissionAmount1);
                    
                    //pay to referral level 2
                    //address _referrallevel2 = refer[_referrallevel1];
                    address _referrallevel2 = referral.getReferrer(_referrallevel1);
                    if(_referrallevel2 != address(0)){
                        uint256 commissionAmount2 = _pending.mul(referral2Rate).div(100);
                        _rewardToken.transfer(_referrallevel2, commissionAmount2);
                        emit ReferralCommissionPaid(_user, _referrallevel2, commissionAmount2);
                        
                        //pay to referral level 3
                        //address _referrallevel3 = refer[_referrallevel2];
                        address _referrallevel3 = referral.getReferrer(_referrallevel2);
                        if(_referrallevel3 != address(0)){
                            uint256 commissionAmount3 = _pending.mul(referral3Rate).div(100);
                            _rewardToken.transfer(_referrallevel3, commissionAmount3);
                            emit ReferralCommissionPaid(_user, _referrallevel3, commissionAmount3);
                        }
                    }
                }
            }
        }
    }
    
}