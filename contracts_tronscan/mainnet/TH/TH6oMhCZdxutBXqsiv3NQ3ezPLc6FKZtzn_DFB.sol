//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


//SourceUnit: DFB.sol

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

contract DFB {
    using SafeMath for uint256; 
    IERC20 public usdt;
    address[2] public feeReceivers;
    address public defaultRefer;
    uint256 private startTime;
    uint256 private helpBalance; // help bal
    uint256 private totalUser; 
    uint256 private totalLeader;
    uint256 private totalManager;
    uint256 private bonusLeft = 500; 

    uint256 private timeStep = 1 days;
    uint256 private dayPerCycle = 14 days; 

    uint256 private feePercent = 150; 
    uint256 private fundPercent = 50;
    uint256 private ticketPercent = 200;
    uint256 private maxPerDayReward = 150;
    uint256 private minPerDayReward = 30;
    uint256 private bonusPercent = 500;
    uint256 private directRate = 500;
    uint256[4] private leaderRates = [100, 200, 300, 100];
    uint256[6] private managerRates0 = [200, 100, 50, 30, 20, 10];
    uint256 private managerRate1 = 5;
    uint256 private managerRate2 = 3;
    uint256 private baseDivider = 10000;

    uint256 private referDepth = 31;

    uint256 private ticketPrice = 1e6;
    uint256 private totalSupply; // total ticket
    uint256 private totalDestory; // ticket burned
    uint256[4] private helpOptions = [300e6, 500e6, 1000e6, 2000e6];

    struct OrderInfo {
        uint256 rate; 
        uint256 amount; 
        uint256 extra; 
        uint256 start;
        uint256 finish; 
        uint256 unfreeze; 
        uint256 withdrawn; 
    }

    struct UserInfo {
        OrderInfo[] orders;
        address referrer;
        uint256 level; // 0:beginner, 1: leader, 2: manager
        uint256 curCycle;
        uint256 curCycleStart; 
        uint256 maxInvest;
        uint256 totalInvest;
        uint256 capitalLeft;
        uint256 ticketBal;
        uint256 ticketUsed;
        uint256 directNum;
        uint256 teamNum;
        uint256 lastWithdraw;
    }

    struct RewardInfo{
        uint256 direct;
        uint256 totalDirect;
        uint256 leader;
        uint256 managerLeft;
        uint256 managerFreezed;
        uint256 managerRelease;
        uint256 team;
        uint256 fund; 
        uint256 extra;
        uint256 withdrawn;
    }

    struct FundPool {
        uint256 times;
        uint256 left; 
        uint256 total; 
        uint256 start; 
        uint256 orderNum; 
        uint256 amount; 
        uint256 curWithdrawn;
        uint256 status;
    }

    uint256 private fundInitTime = 2 days;
    uint256 private fundPerValue = 100e6;
    uint256 private fundPerTime = 15 seconds; 
    FundPool private fundPool; 

    mapping(uint256=>mapping(address=>uint256)) public userFundRank; // times=>user=>rank
    mapping (uint256=>mapping (uint256=>address)) public fundRankUser; // times=>rank=>user

    mapping(address=>UserInfo) private userInfo;
    mapping(address=>RewardInfo) private userRewardInfo;

    uint256[12] private balDown = [10e10, 20e10, 40e10, 60e10, 100e10, 150e10, 200e10, 250e10, 350e10, 500e10, 800e10, 1000e10]; 
    uint256[12] private balDownRate = [1000, 1500, 2000, 2500, 3500, 5000, 6000, 6500, 7000, 7500, 8000, 8000]; 
    uint256[12] private balRecover = [15e10, 30e10, 50e10, 80e10, 120e10, 150e10, 200e10, 250e10, 350e10, 500e10, 1000e10];
    mapping(uint256=>uint256) private balStatus;
    
    bool public isFreezeReward;
    uint256 public recoverTime;
    uint256 public freezeRewardTime;

    event StartHelp(address user, uint256 amount);
    event RecHelp(address user, uint256 amount);
    event WithdrawCapital(address user, uint256 amount);
    event BuyTicket(address user, uint256 price);

    constructor(address _usdtAddr, address _defaultRefer, address[2] memory _feeReceivers) public {
        usdt = IERC20(_usdtAddr);
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        defaultRefer = _defaultRefer;
    }

    receive() external payable{
    }

    function buyTicket(uint256 _amount) external {
        uint256 price = _amount.mul(ticketPrice);
        usdt.transferFrom(msg.sender, address(this), price);
        _mintTicket(msg.sender, _amount);
        emit BuyTicket(msg.sender, price);
    }

    function startHelp(address _referrer, uint256 _option) external {
        require(_isOptionOk(msg.sender, _option) == true, "option err");
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = helpOptions[_option];
        uint256 tickets = amount.mul(ticketPercent).div(baseDivider).div(1e6);
        require(user.ticketBal >= tickets, "insufficent tickets");
        _burnTicket(msg.sender, tickets);
        usdt.transferFrom(msg.sender, address(this), amount);
        _distributeHelp(amount);

        if(user.referrer == address(0)){
            require(_referrer != msg.sender && (userInfo[_referrer].maxInvest > 0 || _referrer == defaultRefer), "referrer invalid");
            user.referrer = _referrer;
            _updateLevel(msg.sender);
        }

        _updateReward(msg.sender, amount);

        uint256 extra;
        if (user.maxInvest == 0 && user.curCycleStart == 0) {
			user.lastWithdraw = block.timestamp;
            user.curCycleStart = block.timestamp;
			totalUser = totalUser.add(1);
            if(bonusLeft > 0){
                bonusLeft = bonusLeft.sub(1);
                extra = amount.mul(bonusPercent).div(baseDivider);
            }
		}

        if(user.curCycleStart.add(dayPerCycle) < block.timestamp){
            user.curCycle++;
            user.curCycleStart = block.timestamp;
        }

        uint256 finish = block.timestamp.add(dayPerCycle);
        user.orders.push(
            OrderInfo(
                getUserCurRate(msg.sender), 
                amount, 
                extra, 
                block.timestamp, 
                finish, 
                0,
                0
            )
        );

        if(amount > user.maxInvest){
            user.maxInvest = amount;
        }

        user.totalInvest = user.totalInvest.add(amount);
        user.capitalLeft = user.capitalLeft.add(amount);

        bool isUnfreezeCapital;
        if(user.curCycle > 0){
            for(uint256 i = 0; i < user.orders.length; i++){
                OrderInfo storage order = user.orders[i];
                if(
                    order.finish < block.timestamp && 
                    order.unfreeze == 0 && 
                    amount >= order.amount
                )
                {
                    order.unfreeze = 1;
                    isUnfreezeCapital = true;
                    break;
                }
            }
        }

        if(!isUnfreezeCapital){
            RewardInfo storage userReward = userRewardInfo[msg.sender];
            if(userReward.managerFreezed > 0){
                if(amount >= userReward.managerFreezed){
                    userReward.managerRelease = userReward.managerRelease.add(userReward.managerFreezed);
                    userReward.managerFreezed = 0;
                }else{
                    userReward.managerRelease = userReward.managerRelease.add(amount);
                    userReward.managerFreezed = userReward.managerFreezed.sub(amount);
                }
            }
        }

        _distributeFundPool();
        if(fundPool.status == 1){
            fundPool.orderNum++;
            fundPool.amount = fundPool.amount.add(amount);
            uint256 oldRank = userFundRank[fundPool.times][msg.sender];
            if(oldRank != 0){
                fundRankUser[fundPool.times][oldRank] = address(0);
            }
            userFundRank[fundPool.times][msg.sender] = fundPool.orderNum;
            fundRankUser[fundPool.times][fundPool.orderNum] = msg.sender;
        }

        helpBalance = helpBalance.add(amount);
        _balActived();
        if(isFreezeReward){
            _setFreezeReward();
        }

        emit StartHelp(msg.sender, amount);
    }

    function recHelp() external {
        _distributeFundPool();

        RewardInfo storage userReward = userRewardInfo[msg.sender];
        uint256 withdrawable = _getStaticRewards(msg.sender);
        withdrawable = withdrawable.add(_getReferRewards(msg.sender));
        
        if(userReward.extra > 0){
            withdrawable = withdrawable.add(userReward.extra);
        }

        if(helpBalance >= withdrawable){
            userReward.direct = 0;
            userReward.leader = 0;
            userReward.managerRelease = 0;
            userReward.extra = 0;
            if(helpBalance > withdrawable){
                helpBalance = helpBalance.sub(withdrawable);
            }else{
                helpBalance = 0;
            }
        }else{
            withdrawable = 0;
            if(fundPool.status == 0){
                fundPool.status = 1;
                fundPool.start = block.timestamp;
            }
        }

        if(userReward.fund > 0){
            withdrawable = withdrawable.add(userReward.fund);
            userReward.fund = 0;
        }

        userReward.withdrawn = userReward.withdrawn.add(withdrawable);

        userInfo[msg.sender].lastWithdraw = block.timestamp;

        usdt.transfer(msg.sender, withdrawable);

        _setFreezeReward();

        emit RecHelp(msg.sender, withdrawable);
    }

    function withdrawCapital() external {
        _distributeFundPool();

        UserInfo storage user = userInfo[msg.sender];
        uint256 withdrawable;
        for(uint256 i = 0; i < user.orders.length; i++){
            OrderInfo storage order = user.orders[i];
            if(order.unfreeze == 1 && order.withdrawn == 0){
                order.withdrawn = 1;
                withdrawable = withdrawable.add(order.amount);
                if(order.extra > 0){
                    userRewardInfo[msg.sender].extra = userRewardInfo[msg.sender].extra.add(order.extra);
                }

                _releaseManagerRewards(msg.sender, order.amount);
            }
        }

        if(helpBalance >= withdrawable){
            if(helpBalance > withdrawable){
                helpBalance = helpBalance.sub(withdrawable);
            }else{
                helpBalance = 0;
            }
            user.capitalLeft = user.capitalLeft.sub(withdrawable);
            usdt.transfer(msg.sender, withdrawable);
        }else{
            withdrawable = 0;
            if(fundPool.status == 0){
                fundPool.status = 1;
                fundPool.start = block.timestamp;
            }
        }
        
        _setFreezeReward();

        emit WithdrawCapital(msg.sender, withdrawable);
    }

    function distributeFundPool() external {
        _distributeFundPool();
    }

    function getMaxFreezing(address _user) public view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 maxFreezing;
        for(uint256 i = user.orders.length; i > 0; i--){
            OrderInfo storage order = user.orders[i - 1];
            if(order.finish > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function getCapitalInfo(address _user) public view returns(uint256, uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 freezing;
        uint256 unfreezed; 
        uint256 withdrawable;
        for(uint256 i = 0; i < user.orders.length; i++){
            OrderInfo storage order = user.orders[i];
            if(order.finish > block.timestamp){
                freezing = freezing.add(order.amount);
            }else{
                if(order.unfreeze == 0){
                    unfreezed = unfreezed.add(order.amount);
                }else{
                    if(order.withdrawn == 0){
                        withdrawable = withdrawable.add(order.amount);
                    }
                }
            }
        }
        return (freezing, unfreezed, withdrawable);
    }

    function getStaticRewards(address _user) external view returns(uint256) {
        return _getStaticRewards(_user);
    }

    function getReferRewards(address _user) external view returns(uint256) {
        return _getReferRewards(_user);
    }

    function getUserCurRate(address _user) public view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 curRate;
        uint256 orderRate = user.orders.length.mul(10);
        if(orderRate < maxPerDayReward){
            curRate = maxPerDayReward.sub(orderRate);
        }
        if(curRate < minPerDayReward){
            curRate = minPerDayReward;
        }
        return curRate;
    }

    function getUserReferrer(address _user) external view returns(address) {
        return userInfo[_user].referrer;
    }

    function getUserInfo(address _user) external view returns(uint256[13] memory) {
        UserInfo storage user = userInfo[_user];
        uint256[13] memory infos = [
            user.level,
            user.curCycle,
            user.curCycleStart,
            user.maxInvest,
            user.totalInvest,
            user.capitalLeft,
            user.ticketBal,
            user.ticketUsed,
            user.directNum,
            user.teamNum,
            user.lastWithdraw,
            _user.balance, // trx bal
            usdt.balanceOf(_user) // usdt bal
        ];
        return infos;
    }

    function getUserRewardInfo(address _user) external view returns(uint256[10] memory) {
        RewardInfo storage reward = userRewardInfo[_user];
        uint256[10] memory infos = [
            reward.direct,
            reward.totalDirect,
            reward.leader,
            reward.managerLeft,
            reward.managerFreezed,
            reward.managerRelease,
            reward.team,
            reward.fund,
            reward.extra,
            reward.withdrawn
        ];
        return infos;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return userInfo[_user].orders.length;
    }

    function getUserOrder(address _user, uint256 _index) external view returns(uint256[7] memory) {
        OrderInfo storage order = userInfo[_user].orders[_index];
        uint256[7] memory infos = [
            order.rate, 
            order.amount, 
            order.extra, 
            order.start, 
            order.finish, 
            order.unfreeze, 
            order.withdrawn
        ];
        return infos;
    }

    function getFundPool() external view returns(uint256[8] memory) {
        uint256[8] memory infos = [
            fundPool.times, 
            fundPool.left,
            fundPool.total,
            fundPool.start,
            fundPool.orderNum,
            fundPool.amount,
            fundPool.curWithdrawn,
            fundPool.status
        ];
        return infos;
    }

    function getSysInfo() external view returns(uint256[9] memory) {
        uint256[9] memory infos = [
            startTime,
            helpBalance,
            usdt.balanceOf(address(this)),
            totalUser,
            totalLeader,
            totalManager,
            bonusLeft,
            totalSupply,
            totalDestory
        ];
        return infos;
    }

    function getFundTimeLeft() public view returns(uint256) {
        uint256 totalTime = fundPool.start.add(fundPool.amount.div(fundPerValue).mul(fundPerTime)).add(fundInitTime);
        if(block.timestamp < totalTime){
            return totalTime.sub(block.timestamp);
        }
    }

    function getBalStatus() external view returns(uint256, uint256, uint256) {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]] == 1){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                return (balDown[i - 1], balDown[i - 1].sub(maxDown), balRecover[i - 1]);
            }
        }
    }

    function isOptionOk(address _user, uint256 _option) external view returns(bool) {
        return _isOptionOk(_user, _option);
    }

    function _isOptionOk(address _user, uint256 _option) private view returns(bool) {
        if(_option >= helpOptions.length){
            return false;
        }
        UserInfo storage user = userInfo[_user];
        if(user.maxInvest == 0 ){
            if(_option >= helpOptions.length.sub(1)){
                return false;
            }
        }else{
            if(helpOptions[_option] < user.maxInvest){
                return false;
            }else{
                if(user.maxInvest < helpOptions[helpOptions.length.sub(2)]){
                    if(_option >= helpOptions.length.sub(1)){
                        return false;
                    }
                }
            }
        }
        return true;
    }

    function _getStaticRewards(address _user) private view returns(uint256) {
        uint256 withdrawable;
        UserInfo storage user = userInfo[_user];
        (uint256 freezing, uint256 unfreezed, ) = getCapitalInfo(_user);
        uint256 capitalLeft = freezing.add(unfreezed);
        uint256 staticReward = _staticRewards(_user, user.lastWithdraw);
        uint256 referReward = _getReferRewards(_user);
        uint256 totalWithNow = staticReward.add(referReward).add(userRewardInfo[_user].withdrawn);
        if(isFreezeReward){
            if(capitalLeft > userRewardInfo[_user].withdrawn){
                if(capitalLeft >= totalWithNow){
                    withdrawable = staticReward;
                }else{
                    if(capitalLeft > userRewardInfo[_user].withdrawn.add(referReward)){
                        withdrawable = capitalLeft.sub(userRewardInfo[_user].withdrawn.add(referReward));
                    }
                }
            }
        }else{
            withdrawable = staticReward;
            if(recoverTime > freezeRewardTime && totalWithNow > capitalLeft && recoverTime > user.lastWithdraw){
                withdrawable = _staticRewards(_user, recoverTime);
            }
        }
        return withdrawable;
    }

    function _getReferRewards(address _user) private view returns(uint256) {
        RewardInfo storage userRewards = userRewardInfo[_user];
        uint256 withdrawable = userRewards.direct;
        withdrawable = withdrawable.add(userRewards.leader);
        withdrawable = withdrawable.add(userRewards.managerRelease);
        return withdrawable;
    }

    function _staticRewards(address _user, uint256 _lastWithdraw) private view returns(uint256 withdrawable) {
        UserInfo storage user = userInfo[_user];
        for(uint256 i = 0; i < user.orders.length; i++){
            OrderInfo storage order = user.orders[i];
            uint256 from = order.start > _lastWithdraw ? order.start : _lastWithdraw;
            uint256 to = block.timestamp > order.finish ? order.finish : block.timestamp;
            if(from < to){
                uint256 nowReward = order.amount.mul(order.rate).mul(to.sub(from)).div(timeStep).div(baseDivider);
                withdrawable = withdrawable.add(nowReward);
            }
        }
    }

    function _releaseManagerRewards(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(userInfo[upline].level >= 2){
                    uint256 newAmount = _amount;
                    if(upline != defaultRefer){
                        uint256 maxFreezing = getMaxFreezing(upline);
                        if(maxFreezing < _amount){
                            newAmount = maxFreezing;
                        }
                    }
                    uint256 managerReward;
                    if(i > 4 && i <= 10){
                        managerReward = newAmount.mul(managerRates0[i - 5]).div(baseDivider);
                    }else if(i > 10 && i <= 20){
                        managerReward = newAmount.mul(managerRate1).div(baseDivider);
                    }else if(i > 20){
                        managerReward = newAmount.mul(managerRate2).div(baseDivider);
                    }

                    if(userRewardInfo[upline].managerLeft < managerReward){
                        managerReward = userRewardInfo[upline].managerLeft;
                    }
                    userRewardInfo[upline].managerFreezed = userRewardInfo[upline].managerFreezed.add(managerReward); 
                    userRewardInfo[upline].managerLeft = userRewardInfo[upline].managerLeft.sub(managerReward);
                }
            }else{
                break;
            }
            upline = userInfo[upline].referrer;
        }

    }

    function _distributeFundPool() private {
        if(fundPool.status == 1 && getFundTimeLeft() == 0){
            for(uint256 i = fundPool.orderNum; i > 0; i--){
                address userAddr = fundRankUser[fundPool.times][i];
                if(userAddr != address(0)){
                    RewardInfo storage userReward = userRewardInfo[userAddr];
                    uint256 investCount = userInfo[userAddr].orders.length;
                    uint256 amount = userInfo[userAddr].orders[investCount.sub(1)].amount;
                    uint256 reward;
                    if(i == fundPool.orderNum){
                        reward = amount.mul(5);
                    }else{
                        reward = amount.mul(3);
                    }

                    if(reward < fundPool.left){
                        userReward.fund = userReward.fund.add(reward);
                        fundPool.left = fundPool.left.sub(reward);
                    }else{
                        userReward.fund = userReward.fund.add(fundPool.left);
                        fundPool.left = 0;
                    }
                }
            }
            _resetFundPool();
        }
    }

    function _resetFundPool() private {
        fundPool.times++;
        fundPool.left = 0;
        fundPool.start = 0;
        fundPool.orderNum = 0;
        fundPool.amount = 0;
        fundPool.curWithdrawn = 0;
        fundPool.status = 0;
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        if(user.referrer != address(0)){
            address upline = user.referrer;
            userInfo[upline].directNum = userInfo[upline].directNum.add(1);
            for(uint256 i = 0; i < referDepth; i++){
                if(upline != address(0)){
                    userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                    uint256 levelNow = _calcLevel(userInfo[upline].directNum, userInfo[upline].teamNum);
                    if(levelNow > userInfo[upline].level){
                        userInfo[upline].level = levelNow;
                        if(userInfo[upline].level == 1){
                            totalLeader = totalLeader.add(1);
                        }else if(userInfo[upline].level == 2){
                            totalLeader = totalLeader.sub(1);
                            totalManager = totalManager.add(1);
                        }
                    }
                    upline = userInfo[upline].referrer;
                }else{
                    break;
                }
            }
        }
    }

    function _calcLevel(
        uint256 _directNum, 
        uint256 _teamNum
    ) 
        private 
        pure 
        returns(
            uint256 levelNow
        ) 
    {
        if(_directNum >= 5 && _teamNum >= 50){
            levelNow = 1;
        }
        if(_directNum >= 10 && _teamNum >= 200){
            levelNow = 2;
        }
    }

    function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }
                
                RewardInfo storage upRewards = userRewardInfo[upline];
                uint256 reward;
                if(i == 0){
                    reward = newAmount.mul(directRate).div(baseDivider);
                    upRewards.direct = upRewards.direct.add(reward);
                    upRewards.totalDirect = upRewards.totalDirect.add(reward);
                }else if(i <= 4 && userInfo[upline].level > 0){
                    reward = newAmount.mul(leaderRates[i - 1]).div(baseDivider);
                    upRewards.leader = upRewards.leader.add(reward);
                }else{
                    if(i > 4 && i <= 10 && userInfo[upline].level > 1){
                        reward = newAmount.mul(managerRates0[i - 5]).div(baseDivider);
                    }
                    if(i > 10 && i <= 20 && userInfo[upline].level > 1){
                        reward = newAmount.mul(managerRate1).div(baseDivider);
                    }
                    if(i > 20 && userInfo[upline].level > 1) {
                        reward = newAmount.mul(managerRate2).div(baseDivider);
                    }
                    upRewards.managerLeft = upRewards.managerLeft.add(reward);
                }
                upRewards.team = upRewards.team.add(reward);
            }else{
                break;
            }
            upline = userInfo[upline].referrer;
        }
    }

    function _mintTicket(address _user, uint256 _amount) private {
        totalSupply = totalSupply.add(_amount);
        UserInfo storage user = userInfo[_user];
        user.ticketBal = user.ticketBal.add(_amount);
    }

    function _burnTicket(address _user, uint256 _amount) private {
        totalDestory = totalDestory.add(_amount);
        UserInfo storage user = userInfo[_user];
        user.ticketBal = user.ticketBal.sub(_amount);
        user.ticketUsed = user.ticketUsed.add(_amount);
    }

    function _distributeHelp(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercent).div(baseDivider);
        usdt.transfer(feeReceivers[0], fee.div(3));
        usdt.transfer(feeReceivers[1], fee.mul(2).div(3));
        uint256 fund = _amount.mul(fundPercent).div(baseDivider);
        fundPool.left = fundPool.left.add(fund);
        fundPool.total = fundPool.total.add(fund);
    }

    function _balActived() private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(helpBalance >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = 1;
                break;
            }
        }
    }

    function _setFreezeReward() private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]] == 1){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(helpBalance < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                    freezeRewardTime = block.timestamp;
                }else if(isFreezeReward && helpBalance >= balRecover[i - 1]){
                    isFreezeReward = false;
                    recoverTime = block.timestamp;
                }
                break;
            }
        }
    }
 
}



//SourceUnit: IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}