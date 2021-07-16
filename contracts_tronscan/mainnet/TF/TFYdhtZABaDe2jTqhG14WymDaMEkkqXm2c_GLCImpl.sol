//SourceUnit: GLCImpl.sol

pragma solidity ^0.5.5;

import "./GLCStorage.sol";

contract GLCImpl is GLCStorage {

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4 id = bytes4(keccak256("transfer(address,uint256)"));
        // bool success = token.call(id, to, value);
        // require(success, 'TransferHelper: TRANSFER_FAILED');
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        // bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        // bool success = token.call(id, from, to, value);
        // require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }



    // 只有合约所有者可以调用
    modifier onlyOwner(){
        require(msg.sender == owner || msg.sender == ownerSender, "now owner");
        _;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function withdrawToken(uint256 _value, address _token, address _to) public onlyOwner {
        uint256 tba = IERC20(_token).balanceOf(address(this));
        require(tba >= _value, "not enough");
        safeTransfer(_token, _to, _value);
    }
    //定义事件
    event Invest(address indexed from, uint256 amount, address referCode);
    event UserWithdrawStaticA(address indexed from, uint256 amount);//GLC
    event UserWithdrawStaticB(address indexed from, uint256 amount);//FBB
    event UserWithdrawDy(address indexed from, uint256 amount);//GLC
    event UserWithdrawVip(address indexed from, uint256 amount);//GLC
    event UserWithdrawExit(address indexed from, uint256 amount, uint256 fee);//GLC
    event SetMinFBBWithdrawAmount(uint256 indexed amount);//GLC
    function invest(address _upAddr, uint256 _value) public {
        require(investPeriod < 6, "period end");
        //需要是1000的倍数
        require(_value.mod(GLC_MIN) == 0, "Invalid parameter v");
        //需要数量大于1000
        //需要计算glc flc各自余额是否足够
        uint256 flcAmount = _value;
        IERC20 glcToken = IERC20(glcAddr);
        IERC20 flcToken = IERC20(flcAddr);
        address from = msg.sender;
        require(_value >= GLC_MIN && glcToken.balanceOf(from) >= _value, "g not enough");
        require(flcToken.balanceOf(from) >= flcAmount, "f not enough");
        User memory user = userMap[from];
        //需要已经提现
        require(user.endTime == 0, "only once");
        //构建用户信息
        //        require(,"需要上级地址存在"); 暂时忽略这一步
        if (user.upAddr == address(0)) {
            require(_upAddr == firstAddress || userMap[_upAddr].upAddr != address(0), "invalid referrer");
            user.upAddr = _upAddr;
            userMap[user.upAddr].playerArr.push(from);
            userArr.push(from);
        }
        emit Invest(msg.sender, _value, user.upAddr);
        //
        user.investTime = now;
        user.endTime = now + OUT_DAYS;
        user.amount = flcAmount;
        user.isInvesting = true;
        user.staticRate = getPeriodRate(investPeriod);
        //转币/销毁
        safeTransferFrom(glcAddr, from, address(this), _value);
        safeTransferFrom(flcAddr, from, address(this), flcAmount);
        flcToken.burn(flcAmount);

        userMap[from] = user;

        //给上级加速
        if (_value >= GLC_SPEED && isUserValid(user.upAddr)) {
            //需要计算已获取多少静态，后面的
            User storage upUser = userMap[user.upAddr];
            (uint256 pAmount,uint256 glcAmount, uint256 pTime) = getUserCurStatic(user.upAddr);
            upUser.passBonus = pAmount;
            upUser.glcPassBonus = glcAmount;
            upUser.passTime = pTime;
            //修改结束时间，减少一天即可
            if (upUser.endTime - now > ONE_DAY) {
                upUser.endTime = upUser.endTime.sub(ONE_DAY);
            }
            upUser.recTime = upUser.recTime.add(ONE_DAY);
        }
        //10%进入奖金池子
        rewardsPool = rewardsPool.add(_value.div(10));

        //处理资金池子
        _processInvestAmount(_value);

    }
     function _invest(address _upAddr, uint256 _value, address _investor, uint256 _time) internal {
        require(investPeriod < 6, "period end");
        //需要是1000的倍数
        require(_value.mod(GLC_MIN) == 0, "Invalid parameter v");
        //需要数量大于1000
        //需要计算glc flc各自余额是否足够
        uint256 flcAmount = _value;
        address from = _investor;

        User memory user = userMap[from];
        //需要已经提现
        require(user.endTime == 0, "only once");
        //构建用户信息
        //        require(,"需要上级地址存在"); 暂时忽略这一步
        if (user.upAddr == address(0)) {
            require(_upAddr == firstAddress || userMap[_upAddr].upAddr != address(0), "invalid referrer");
            user.upAddr = _upAddr;
            userMap[user.upAddr].playerArr.push(from);
            userArr.push(from);
        }
        emit Invest(msg.sender, _value, user.upAddr);
        //
        user.investTime = _time;
        user.endTime = _time + OUT_DAYS;
        user.amount = flcAmount;
        user.isInvesting = true;
        user.staticRate = getPeriodRate(investPeriod);


        userMap[from] = user;

        //给上级加速
        if (_value >= GLC_SPEED && isUserValid(user.upAddr)) {
            //需要计算已获取多少静态，后面的
            User storage upUser = userMap[user.upAddr];
            (uint256 pAmount,uint256 glcAmount, uint256 pTime) = getUserCurStatic(user.upAddr);
            upUser.passBonus = pAmount;
            upUser.glcPassBonus = glcAmount;
            upUser.passTime = pTime;
            //修改结束时间，减少一天即可
            if (upUser.endTime - _time > ONE_DAY) {
                upUser.endTime = upUser.endTime.sub(ONE_DAY);
            }
            upUser.recTime = upUser.recTime.add(ONE_DAY);
        }
        //10%进入奖金池子
        rewardsPool = rewardsPool.add(_value.div(10));

        //处理资金池子
        _processInvestAmount(_value);

    }
    //给上级发放动态收益，质押和加速都需要给上级分
    //如果是质押的时候，需要给上一级增加一天时间
    //注意，这个发放推荐奖励是在下级提现静态的时候
    function executeRec(address userAddr, uint256 glcAmount) internal {
        address upAddr = userMap[userAddr].upAddr;
        for (uint i = 0; i < 2; i++) {
            if (upAddr == address(0)) {
                break;
            }

            User storage user = userMap[upAddr];

            if (!isUserValid(upAddr)) {
                upAddr = user.upAddr;
                continue;
            }
            upAddr = user.upAddr;
            //烧伤
            uint256 scBaseAmount = _calcDyBaseAmount(userMap[userAddr].amount, user.amount, glcAmount);
            //计算动态收益
            //计算结束时间
            uint256 glcDyAmount = 0;
            if (i == 0) {
                glcDyAmount = scBaseAmount.mul(10).div(userMap[userAddr].staticRate);
            } else {
                glcDyAmount = scBaseAmount.mul(5).div(userMap[userAddr].staticRate);
            }
            //修改用户信息
            user.glcDyBonus = user.glcDyBonus.add(glcDyAmount);
        }

    }

    //通过已经计算的静态收益，计算基数
    //入参，当前用户金额，上级金额，当前用户计算静态
    function _calcDyBaseAmount(uint256 baseInput, uint256 upInput, uint256 baseStatic) internal pure returns (uint256){
        if (baseInput <= upInput) {
            return baseStatic;
        }
        return baseStatic.mul(upInput).div(baseInput);
    }

    function _processInvestAmount(uint256 inputAmount) internal {
        uint256 remainAmount = getLimitAmount(investPeriod).sub(limitTotalMap[investPeriod]);
        if (remainAmount >= inputAmount) {
            limitTotalMap[investPeriod] = limitTotalMap[investPeriod].add(inputAmount);
            if (remainAmount == inputAmount) {
                investPeriod += 1;
            }
        } else {
            investPeriod += 1;
            limitTotalMap[investPeriod] = limitTotalMap[investPeriod].add(inputAmount.sub(remainAmount));
        }
    }

    //结算股东收益
    function settlementVip(address[] memory _addrArr, uint256[] memory _valueArr) public onlyOwner {
        require(_addrArr.length == _valueArr.length, " len ");
        uint256 total = 0;
        for (uint256 i = 0; i < _addrArr.length; i++) {
            userMap[_addrArr[i]].partnerBonus = userMap[_addrArr[i]].partnerBonus.add(_valueArr[i]);
            total = total.add(_valueArr[i]);
        }
        rewardsPool = rewardsPool.sub(total);
    }

    function _distributeVip(address[] memory arr, uint256 len, uint256 rate) internal returns (uint256){
        if (len == 0) {
            return 0;
        }
        uint256 total = rewardsPool.mul(rate).div(100);
        uint256 one = total / len;
        for (uint256 i = 0; i < len; i++) {
            userMap[arr[i]].partnerBonus = userMap[arr[i]].partnerBonus.add(one);
        }
        return total;
    }


    function withdrawBonus() public {
        address from = msg.sender;
        User storage user = userMap[from];
        (uint256 bonus,uint256 glcBonus,) = getUserCurStatic(from);
        require(glcBonus > 0, "wb not enough");
        require(glcBonus > user.glcWithdrawStaticBonus, "wb not enough 2");
        //两个代币一起
        _settlementStatic(from, glcBonus.sub(user.glcWithdrawStaticBonus));
    }

    function withdrawBonusFBB() public {
        address from = msg.sender;
        User storage user = userMap[from];
        (uint256 bonus,,) = getUserCurStatic(from);
        uint256 newBonus = bonus.sub(user.withdrawStaticBonus);
        uint256 allBonus = user.fbbReceivableBonus.add(newBonus);
        require(allBonus >= minFBBWithdrawAmount, "wb fbb not enough");
        safeTransfer(fbbAddr, from, allBonus);
        emit UserWithdrawStaticB(from, allBonus);
        //
        user.withdrawStaticBonus = user.withdrawStaticBonus.add(newBonus);
        //
        user.historyFbbStaticBonus = user.historyFbbStaticBonus.add(allBonus);
        user.fbbReceivableBonus = 0;
    }

    //提取动态收益
    function withdrawDy() public {
        address from = msg.sender;
        User storage user = userMap[from];

        //        if (user.flcDyBonus > user.historyFlcDyBonus) {
        //            uint256 outAmount = user.flcDyBonus.sub(user.historyFlcDyBonus);
        //            safeTransfer(flcAddr, from, outAmount);
        //            user.historyFlcDyBonus = user.historyFlcDyBonus.add(outAmount);
        //        }
        if (user.glcDyBonus > user.historyGlcDyBonus) {
            uint256 glcOutAmount = user.glcDyBonus.sub(user.historyGlcDyBonus);
            safeTransfer(glcAddr, from, glcOutAmount);
            user.historyGlcDyBonus = user.historyGlcDyBonus.add(glcOutAmount);
            emit UserWithdrawDy(from, glcOutAmount);
        }
        //        if (user.fbbDyBonus > user.historyFbbDyBonus) {
        //            uint256 fbbOutAmount = user.fbbDyBonus.sub(user.historyFbbDyBonus);
        //            safeTransfer(fbbAddr, from, fbbOutAmount);
        //            user.historyFbbDyBonus = user.historyFbbDyBonus.add(fbbOutAmount);
        //        }
    }
    //vip收益，只有glc
    function withdrawVip() public {
        address from = msg.sender;
        User storage user = userMap[from];
        require(user.partnerBonus > user.historyPartnerBonus, "wv not enough");
        uint256 outAmount = user.partnerBonus.sub(user.historyPartnerBonus);
        safeTransfer(glcAddr, from, outAmount);

        user.historyPartnerBonus = user.historyPartnerBonus.add(outAmount);
        emit UserWithdrawVip(from, outAmount);
    }

    //结算静态收益，并且给上级发放动态收益
    function _settlementStatic(address from, uint256 glcBonus) internal {
        safeTransfer(glcAddr, from, glcBonus);
        emit UserWithdrawStaticA(from, glcBonus);
        //
        userMap[from].glcWithdrawStaticBonus = userMap[from].glcWithdrawStaticBonus.add(glcBonus);
        //
        userMap[from].historyGlcStaticBonus = userMap[from].historyGlcStaticBonus.add(glcBonus);
        executeRec(from, glcBonus);
    }

    function withdrawExit() public {
        address from = msg.sender;
        User storage user = userMap[from];
        require(user.upAddr != address(0), "invalid user");
        require(user.isInvesting, "exited");

        //提取所有金额
        //本金
        uint256 baseAmount = user.amount;
        if (now >= user.endTime) {
            safeTransfer(glcAddr, from, baseAmount);
            emit UserWithdrawExit(from, baseAmount, 0);
        } else {
            uint fee = baseAmount.mul(30).div(100);
            safeTransfer(glcAddr, from, baseAmount.sub(fee));
            emit UserWithdrawExit(from, baseAmount, fee);
            rewardsPool = rewardsPool.add(fee);
        }
        //强制提取静态
        (uint256 bonus,uint256 glcBonus,) = getUserCurStatic(from);
        if (glcBonus > user.glcWithdrawStaticBonus) {
            _settlementStatic(from, glcBonus.sub(user.glcWithdrawStaticBonus));
        }

        if (bonus > user.withdrawStaticBonus) {
            user.fbbReceivableBonus = user.fbbReceivableBonus.add(bonus.sub(user.withdrawStaticBonus));
        }


        //修改用户信息，并清除部分信息
        user.isInvesting = false;
        //清空静态和单轮游戏相关信息
        user.investTime = 0;
        user.amount = 0;
        user.withdrawStaticBonus = 0;
        user.passBonus = 0;
        user.glcWithdrawStaticBonus = 0;
        user.glcPassBonus = 0;
        user.passTime = 0;
        user.recTime = 0;
        user.endTime = 0;
    }
    function setMinFBBWithdrawAmount(uint256 _v) public onlyOwner {
        minFBBWithdrawAmount = _v;
        emit SetMinFBBWithdrawAmount(_v);
    }
    //计算该用户当前是否出局
    function isUserValid(address _addr) public view returns (bool){
        User memory user = userMap[_addr];
        if (user.upAddr == address(0)) {
            return false;
        }
        if (!user.isInvesting) {
            return false;
        }
        return now < user.endTime;
    }

    //用户当前可获取的静态收益，该方法针对的是用户单个单的总收益，没有计算用户已经提取出去的,
    //返回的是当前可以获取到的静态，以及静态过去的时间 (如果已出局，后面的过去时间是0)
    //新增，静态fbb收益，静态glc收益，静态已过去天数
    function getUserCurStatic(address _addr) public view returns (uint256, uint256, uint256){
        //去掉上次扣除收益
        User memory user = userMap[_addr];
        if (user.upAddr == address(0)) {
            return (0, 0, 0);
        }
        if (!user.isInvesting) {
            return (0, 0, 0);
        }
        //总共收益
        //total fbb
        uint256 totalBonus = user.amount.mul(70).div(100);
        uint256 glcTotalBonus = user.amount.mul(user.staticRate).div(100);
        if (now > user.endTime) {
            return (totalBonus, glcTotalBonus, 0);
        }
        //剩余收益
        uint256 remaining = totalBonus.sub(user.passBonus);
        uint256 glcRemaining = glcTotalBonus.sub(user.glcPassBonus);
        //开始时间加最后的时间，获取天数
        uint256 lastTime = user.investTime.add(user.passTime);
        //计算当前每日平均收益
        //剩余天数
        uint256 remainDay = user.endTime.sub(user.investTime).div(ONE_DAY).sub(user.passTime.div(ONE_DAY));
        uint256 dayBonus = remaining.div(remainDay);
        uint256 glcDayBonus = glcRemaining.div(remainDay);

        //计算上次变动到现在的收益
        uint256 newDay = now.sub(lastTime).div(ONE_DAY);
        uint256 newBonus = dayBonus.mul(newDay);
        uint256 glcNewBonus = glcDayBonus.mul(newDay);
        //加上之前的收益
        return (user.passBonus.add(newBonus), user.glcPassBonus.add(glcNewBonus), user.passTime.add(newDay.mul(ONE_DAY)));
    }



    //获取团队人数数量
    function getTeamPlayerCount(address _addr) public view returns (uint256){
        User memory user = userMap[_addr];
        uint256 count = 0;
        if (user.playerArr.length > 0) {
            uint oneLen = user.playerArr.length;
            count = count.add(oneLen);
            for (uint256 i = 0; i < oneLen; i++) {
                count = count.add(userMap[user.playerArr[i]].playerArr.length);
            }
        }
        return count;
    }


    //获取获取团队的总有效质押数量
    function getGlobalAmount(address _addr) public view returns (uint256){
        //获取两代质押数
        User memory user = userMap[_addr];
        uint256 count = 0;
        if (user.playerArr.length > 0) {
            uint256 oneLen = user.playerArr.length;
            for (uint256 i = 0; i < oneLen; i++) {
                address oneAddr = user.playerArr[i];
                User memory oneUser = userMap[oneAddr];
                if (isUserValid(oneAddr)) {
                    count = count.add(oneUser.amount);

                }
                uint256 twoLen = oneUser.playerArr.length;
                if (twoLen > 0) {
                    for (uint256 k = 0; k < twoLen; k++) {
                        address twoAddr = oneUser.playerArr[k];
                        if (isUserValid(twoAddr)) {
                            count = count.add(userMap[twoAddr].amount);
                        }

                    }
                }
            }
        }
        return count;
    }

    //仅内部使用
    function _getLevel(uint256 userInvestAmount, uint256 tokenWeiCount) internal view returns (uint256){
        if (userInvestAmount < 10000 * ONE_TOKEN) {
            return 0;
        }
        uint256 count = tokenWeiCount / ONE_TOKEN;
        if (count >= 10000000) {
            return 3;
        }
        if (count >= 5000000) {
            return 2;
        }
        if (count >= 1000000) {
            return 1;
        }
        return 0;
    }

    function getLimitAmount(uint256 period) public view returns (uint256){
        if (period == 1) {
            return 5000000 * ONE_TOKEN;
        }
        if (period == 2) {
            return 2000000 * ONE_TOKEN;
        }
        if (period == 3) {
            return 1500000 * ONE_TOKEN;
        }
        if (period == 4) {
            return 1000000 * ONE_TOKEN;
        }
        if (period == 5) {
            return 500000 * ONE_TOKEN;
        }
        return 0;
    }

    function getPeriodRate(uint256 period) public pure returns (uint256){
        if (period == 1) {
            return 30;
        }
        if (period == 2) {
            return 26;
        }
        if (period == 3) {
            return 22;
        }
        if (period == 4) {
            return 18;
        }
        if (period == 5) {
            return 15;
        }
        return 0;

    }


    //查看用户静态收益信息，共4个返回值
    //质押GLC可领取，质押累计领取GLC，质押FBB可领取，质押累计领取FBB
    function showUserBonus(address _addr) public view returns (uint256, uint256, uint256, uint256){
        User memory user = userMap[_addr];
        if (user.upAddr == address(0)) {
            return (0, 0, 0, 0);
        }

        if (!user.isInvesting) {
            return (0, user.historyGlcStaticBonus, user.fbbReceivableBonus, user.historyFbbStaticBonus);
        }

        (uint256 bonus,uint256 glcBonus,) = getUserCurStatic(_addr);
        uint256 fbbBonus = bonus.sub(user.withdrawStaticBonus);
        glcBonus = glcBonus.sub(user.glcWithdrawStaticBonus);
        return (glcBonus, user.historyGlcStaticBonus, fbbBonus.add(user.fbbReceivableBonus), user.historyFbbStaticBonus);
    }
    //查看用户动态收益信息，共4个返回值
    //推广GLC可领取，推广GLC累积领取，,推广FBB可领取，推广FBB累计领取，,推广FLC可领取，推广FLC累计领取，股东加权GLC可领取，股东加权GLC累计领取
    function showUserBonusDy(address _addr) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        User memory user = userMap[_addr];
        if (user.upAddr == address(0)) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }
        return (user.glcDyBonus.sub(user.historyGlcDyBonus), user.historyGlcDyBonus, user.fbbDyBonus.sub(user.historyFbbDyBonus), user.historyFbbDyBonus, user.flcDyBonus.sub(user.historyFlcDyBonus), user.historyFlcDyBonus, user.partnerBonus.sub(user.historyPartnerBonus), user.historyPartnerBonus);
    }

    //获取用户质押状态信息，相关说明：返回的是质押结束时间，剩余时长展示时计算，已加速几天=> 使用  (推荐加速天数/(24*60*60)=n天)
    //是否平台用户（是否有质押过），是否可以进行质押(需要提现本金后可再次质押)，上家地址，质押金额，结束时间，当前vip等级，团队当前总业绩，推荐加速天数(秒值),团队数量(1-2层)
    function showUserInfo(address _addr) public view returns (bool, bool, address, uint256, uint256, uint256, uint256, uint256, uint256){
        User memory user = userMap[_addr];
        if (_addr != firstAddress && user.upAddr == address(0)) {
            return (false, true, address(0), 0, 0, 0, 0, 0, 0);
        }
        //获取vip等级，
        //获取团队数量
        uint256 teamCount = getTeamPlayerCount(_addr);
        uint256 amountCount = getGlobalAmount(_addr);
        uint256 level = _getLevel(user.amount, amountCount);
        //
        return (true, !user.isInvesting, user.upAddr, user.amount, user.endTime, level, amountCount, user.recTime, teamCount);
    }
    //获取当前周期信息
    //当前周期，当前周期已使用金额，当前周期总额，奖金池金额
    function showSysInfo() public view returns (uint256, uint256, uint256, uint256){
        // return (investPeriod, limitTotalMap[investPeriod], getLimitAmount(investPeriod), rewardsPool);
        return (investPeriod, limitTotalMap[investPeriod], getLimitAmount(investPeriod), rewardsPool);

    }

    function getUserLength() public view returns (uint256){
        return userArr.length;
    }

    //返回
    //自己地址，上级地址，投资金额，开始时间，结束时间；已出局的用户，金额/时间都是0，到时间未提出的，需要对比结束时间是否出局
    function getAllUser(uint256 _fromIndex, uint256 _length) public view returns (address[] memory, address[]memory, uint[]memory, uint[]memory, uint[]memory){
        require(_fromIndex + _length <= userArr.length, "out");
        address[] memory addrArr = new address[](_length);
        address[] memory upArr = new address[](_length);
        uint[] memory amountArr = new uint[](_length);
        uint[] memory beginArr = new uint[](_length);
        uint[] memory endArr = new uint[](_length);

        for (uint i = 0; i < _length; i++) {
            address addr = userArr[i + _fromIndex];
            User memory user = userMap[addr];
            addrArr[i] = addr;
            upArr[i] = user.upAddr;
            amountArr[i] = user.amount;
            beginArr[i] = user.investTime;
            endArr[i] = user.endTime;
        }

        return (addrArr, upArr, amountArr, beginArr, endArr);
    }
    function setGlcflcfbbAdds(address _glc, address _flc, address _fbb)public onlyOwner {
        glcAddr = _glc;
        flcAddr = _flc;
        fbbAddr = _fbb;
    }

    function setFirstAdd(address _add) public onlyOwner {
        firstAddress = _add;
    }
    

   function insertUser(address _addr,uint256 _value, address _upAddr,uint256 _investTime, uint256 _historyGlcStaticBonus, uint256 _historyFbbStaticBonus, uint256 _historyGlcDyBonus, uint256 _historyPartnerBonus)public onlyOwner{
   
       _invest(_upAddr,_value, _addr, _investTime);
       User storage user = userMap[_addr];
       user.historyGlcStaticBonus = _historyGlcStaticBonus;
       user.historyFbbStaticBonus = _historyFbbStaticBonus;
       user.historyGlcDyBonus = _historyGlcDyBonus;
       user.historyPartnerBonus = _historyPartnerBonus;
       
   }
    // function testSetDayTime(uint256 t) public onlyOwner{
    //     require(t > 0, "zero ");
    //     ONE_DAY = t;
    //     OUT_DAYS = t * 30;

    //     //
    //     uint256 len = userArr.length;
    //     for (uint256 i = 0; i < len; i++) {
    //         User storage user = userMap[userArr[i]];
    //         if (user.investTime != 0) {
    //             user.endTime = user.investTime + OUT_DAYS;
    //         }
    //     }

    // }
}


//SourceUnit: GLCStorage.sol

pragma solidity ^0.5.5;

contract IERC20 {

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns
    (uint256 remaining);

    function burn(uint256 amount) public;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract GLCStorage {
    using SafeMath for uint256;
    //质押量
    struct User {
        /**
        自己的地址
        上级地址
        质押量
        质押时间
        静态收益
        动态收益
        股东收益
        加速包前已过天数：  需要标记开始时间，才方便计算后面时间
        推荐天数：推荐1个加1
        加速包0：默认没有，1：15天，2:7天；重新质押需要重置该字段
        有效的：用于标记是否结束
        */
        address upAddr;
        uint256 investTime;//投资时间
        uint256 amount;//投资金额
        uint256 withdrawStaticBonus;//静态FBB，已提现的金额，  实际总额静态，通过计算得来
        uint256 glcWithdrawStaticBonus;//静态GLC，已提现的金额，  实际总额静态，通过计算得来
        uint256 fbbDyBonus;//动态收益，记录的是总收益
        uint256 glcDyBonus;//FLC动态
        uint256 flcDyBonus;//FLC动态
        uint256 partnerBonus;//股东收益，记录的是总收益
        uint256 passBonus;//当前质押已获取收益 --- 对应的是静态收益，静态收益几个公用一个字段去计算
        uint256 glcPassBonus;//当前质押已获取收益 --- 对应的是静态收益，静态收益几个公用一个字段去计算
        uint256 passTime;//当前质押已过去天数 --- 该字段可能无效
        uint256 recTime;//通过推荐增加的天数 --- 单位秒
        uint256 endTime;//结束时间 -- 每次时间变化都修改该值 -- 提现后，将该值修改成0
        bool isInvesting;//是否投资中

        address[] playerArr;

        //上面已提收益用来计算中途提现，中途加速后，每日收益不一样，
        //下面新字段，用于记录参与游戏以来，用户的提现过的收益
        uint256 historyFbbStaticBonus;//FBB
        uint256 historyGlcStaticBonus;//GLC
        uint256 historyGlcDyBonus;
        uint256 historyFlcDyBonus;
        uint256 historyFbbDyBonus;
        uint256 historyPartnerBonus;//股东收益

        uint256 staticRate;//订单静态比例
        uint256 fbbReceivableBonus;//fbb可以领取的收益，fbb要累计达到3500才可以领取
    }
    //主网正式币
    address glcAddr = address(0x41A9F0A58D0AD962BC077729DB9573EB53967D8A40);
    address flcAddr = address(0x413E58840A965B3E2802B1F88349CEB6FA5C4E04B7);
    address fbbAddr = address(0x41752EC5AE7F89C925A85AABF78B7DFE26F1F30E16);

// //测试网币
//      address glcAddr = address(0x41D8A797B25789BACA4CCFD77E6D67A4DD80D5258D);
//      address flcAddr = address(0x41302ECB10CD4FB2D9ADB4EC0BB67CB370E112CE1A);
//      address fbbAddr = address(0x419F3F42B0DF7B82DBE5386842D6CA1DC3E9DACF9D);

    uint256 tokenDecimals = 6;//默认两个币都是一样的精度

    uint256 GLC_MIN = 100 * 10 ** tokenDecimals;//代币精度6 需注意修改
    uint256 ONE_TOKEN = 1 * 10 ** tokenDecimals;//一个代币数量
    uint256 GLC_SPEED = 10000 * 10 ** tokenDecimals;//大于等于1w给上级加速一天
    uint256 ONE_DAY = 1 days;
    uint256 OUT_DAYS = 30 days;

    mapping(address => User) userMap;
    address[]userArr;//用户列表

    address public owner;
    address ownerSender;
    address public firstAddress = address(0x4194269A984F9C83D30BB62FFDD841FF6A08391418);
    uint256 rewardsPool;//奖金池

    //每个周期限额
    mapping(uint256 => uint256)limitTotalMap;
    uint256 investPeriod = 1;
    //fbb最小金额
    uint256 minFBBWithdrawAmount = 3500 * ONE_TOKEN;

    constructor() public {
        // owner = address(0x41CD2FFAE8845DA49C802EA7B193D271F80C2CF904);
        owner = msg.sender;
        ownerSender = msg.sender;
        User memory user = userMap[owner];
        userMap[owner] = user;
        userArr.push(firstAddress);
    }

}