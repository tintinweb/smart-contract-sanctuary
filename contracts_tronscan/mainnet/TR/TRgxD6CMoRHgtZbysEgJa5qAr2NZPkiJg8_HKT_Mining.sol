//SourceUnit: HKT_Mining.sol

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "./router.sol";

import "./tool.sol";

interface HKT721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function cardIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface Refer {
    function bondUserInvitor(address addr_, address invitor_) external;

    function checkUserInvitor(address addr_) external view returns (address);

    function isRefer(address addr_) external view returns (bool);
}



interface ClaimHKT {
    function addAmount(address addr_, uint amount_) external;
}


contract HKT_Mining is Ownable, ERC721Holder {
    address public pair;
    IPancakeRouter02 public router;
    IERC20 public HKT;
    IERC20 public U;
    HKT721 public NFT;
    Refer public refer;
    address public claim;
    uint public constant acc = 1e10;
    uint public constant dailyOut = 275e18;
    uint public rate;//每秒产量速率
    uint public debt;
    uint public totalPower;//总算力 
    uint public lastTime;//上次领取时间
    uint public startTime;//挖矿开始时间
    address public stage;
    address public fund;
    uint public coinAmount;//可支持销毁挖矿的币数量
    uint public userAmount;//有效玩家数量
    string[] public coinList;//支持销毁挖矿列表
    address public nftPool;
    address[] public  path = new address[](2);
    address public burnAddress;
    uint[] public cycle = [15 days,130 days, 15 days];//销毁挖矿和续期有效时期，卡槽有效期,冷却期
    uint public swapAmount;//准备回购的数量
    address public HKT_pair;
    address public U_pair;
    uint public totalCliamed;//总领取量
    address public tec;
    uint public stakeMode = 1;
    uint public toClaimRate = 30;//多少比例会放到缓释池子，百分比
    uint public deadLine;
    uint public repairCost = 1;
    uint public food = 1000;//猫粮卡的卡牌ID
    uint public fristRewDays = 3;//每日头矿查看往期的最多天数
    uint[] public rewardLimit = [5000e6 ,10000e6];//每日头矿分界线
    uint[] public rewardRate = [15, 35, 50];//每日头矿每个矿池的奖励比例
    uint[] public coinRate = [1e6, 1e18];//销毁挖矿比例模式下的比例
    uint[] public renewCard = [1000, 1000, 1000, 1000];//维修卡槽需要的卡牌
    uint[] public renewPower = [2000e6, 10000e6, 50000e6];//维修卡槽的算力界限
    uint[] public miningRate = [50, 2, 2, 44, 2];//销毁挖矿进来的u用涂的比例，回购销毁，回购给游戏公会，回购给nft挖矿，留在合约，转给技术

    event Stake(address indexed sender_, address indexed coin_, uint indexed slot_, uint amount_);
    event Claim(address indexed sender_, uint indexed amount_);
    event Renew(address indexed sender_, uint indexed pool_);
    event Repair(address indexed sender_, uint indexed pool_);
    mapping(uint => mapping(address => mapping(uint => uint))) public userReward;//截止日期=>地址=>三个池子
    mapping(uint => mapping(uint => uint)) public rewardPool;//截止日期=>三个池子=>池子总量
    struct UserInfo {
        uint total;
        uint claimed;
        bool frist;
        uint fristRew;
        uint fristClaimed;
        uint referClaimed;
    }


    struct SlotInfo {
        bool status;
        uint power;
        uint stakeTime;
        uint endTime;
        uint claimTime;
        uint debt;
        uint deadTime;
    }

    mapping(address => UserInfo)public userInfo;
    mapping(address => mapping(uint => SlotInfo))public slotInfo;
    mapping(uint => address)public coinID; 
    mapping(uint => uint)public safePool;

    constructor(){
        rate = dailyOut / 1 days;

    }
    function setRewardLimit(uint[]  memory limit_) external onlyOwner{
        rewardLimit = limit_;
    }
    
    function setFood(uint food_) public onlyOwner{
        food = food_;
    }
    function changeFristRewDays(uint day_) public onlyOwner{
        fristRewDays = day_;
    }
    
    function changeRepairCost(uint cost_) external onlyOwner{
        repairCost = cost_;
    }
    
    function setRewardRate(uint[] calldata rewardRate_) external onlyOwner {
        rewardRate = rewardRate_;
    }

    //添加可以用于销毁挖矿的币
    function addCoinID(address coin_) public onlyOwner {
        coinID[coinAmount] = coin_;
        coinAmount += 1;
        coinList.push(IERC20(coin_).symbol());
    }

    function setCoinId(uint ID_, address coin_) public onlyOwner {
        coinID[ID_] = coin_;
        coinList[ID_] = IERC20(coin_).symbol();
    }
    //更改存入模式 1用固定比例，2用sunswap实时价格比例
    function changeStakeMode(uint mode_) external onlyOwner {
        stakeMode = mode_;
    }

    function setCoinRate(uint[] calldata rate_) public onlyOwner {
        coinRate = rate_;
    }

    function setCycle(uint[] memory cycle_) external onlyOwner {
        cycle = cycle_;
    }

    function setRouter(address router_) public onlyOwner {
        router = IPancakeRouter02(router_);
        IERC20(path[0]).approve(router_,1e25);
    }

    function setToken(address HKT_, address U_) public onlyOwner {
        HKT = IERC20(HKT_);
        U = IERC20(U_);
        path[1] = HKT_;
        path[0] = U_;
    }
    //设置续费算力标准
    function setRenewPower(uint[] memory power) public onlyOwner {
        renewPower = power;
    }
    //设置缓释池比例
    function setToClaimRate(uint com_) external onlyOwner {
        toClaimRate = com_;
    }
    //设置地址
    function setAddress(address fund_, address stage_, address nftPool_, address HKT721_, address burn_, address tec_, address refer_, address claim_,address pair_) public onlyOwner {
        fund = fund_;
        stage = stage_;
        nftPool = nftPool_;
        NFT = HKT721(HKT721_);
        burnAddress = burn_;
        tec = tec_;
        refer = Refer(refer_);
        claim = claim_;
        pair = pair_;

    }
    //设置续费需要的卡牌ID
    function setRenewCard(uint[] calldata cardId_) public onlyOwner {
        renewCard = cardId_;
    }
    //流动性挖矿核心代码，用每秒币的产量除以总算力更改的中间时间，得到每秒，每1点算力可以得到的币，再用用户的算力乘以这个累计上来的值，就等于用户本次的奖励
    function coutingDebt() public view returns (uint){
        if (totalPower > 0) {
            uint temp = (rate * 85 / 100) * (block.timestamp - lastTime) * acc / totalPower;
            return temp + debt;
        } else {
            return 0 + debt;
        }
    }
    //根据玩家质押的token地址，算出质押总共的算力，如果使用比例模式，从闪兑拿价格再加上与u的数量，得算力，如果用sunswap模式，用getTokenPirce拿到
    //Token价格，乘以数量拿到总价格，再附加上等价的u，就是总算力
    function coutingPower(uint amount_, address token_) public view returns (uint){
        if (startTime == 0) {
            return 0;
        }

        uint decimal = IERC20(token_).decimals();
        uint uAmount;
        uint _total;
        if (stakeMode == 1) {
            uAmount = amount_ * (10 ** (18 - decimal)) * coinRate[0] / coinRate[1];
            _total = uAmount * 2;
        } else {
            uint p = getTokenPrice(token_);
            uAmount = p * amount_ / 1e18;
            _total = uAmount * 2;
        }

        return _total;

    }

    //计算单个卡槽销毁挖矿收益
    function calculateRewards(address addr_, uint slot_) public view returns (uint){
        SlotInfo storage slot = slotInfo[addr_][slot_];
        uint tempDebt;
        uint rewards;
        if (!slotInfo[addr_][slot_].status) {
            return 0;
        }
        if (block.timestamp > slot.endTime && slot.claimTime < slot.endTime) {
            tempDebt = (rate * 85 * 60 / 10000) * (slot.endTime - slot.claimTime) * acc / totalPower;
            rewards = tempDebt * slot.power / acc;
        } else if (block.timestamp < slot.endTime) {
            tempDebt = coutingDebt();
            rewards = slot.power * (tempDebt - slot.debt) / acc;
        }
        return rewards;

    }
    //通过用户数量，算出手续费
    function checkPoundage(uint amount_) public view returns (uint rew_, uint burn_, uint pool_){
        if (userAmount <= 500) {
            rew_ = amount_ * 2 / 10;
            burn_ = amount_ / 2;
            pool_ = amount_ * 3 / 10;
        } else if (userAmount > 500 && userAmount <= 2000) {
            rew_ = amount_ * 3 / 10;
            burn_ = amount_ * 45 / 100;
            pool_ = amount_ * 25 / 100;
        } else if (userAmount > 2000 && userAmount <= 5000) {
            rew_ = amount_ * 5 / 10;
            burn_ = amount_ * 35 / 100;
            pool_ = amount_ * 15 / 100;
        } else if (userAmount > 5000) {
            rew_ = amount_ * 99 / 100;
            burn_ = 0;
            pool_ = amount_ / 100;
        }
    }
    //前端展示用
    function checkRate() public view returns (uint){
        uint out;
        if (userAmount <= 500) {
            out = 20;
        } else if (userAmount > 500 && userAmount <= 2000) {
            out = 30;
        } else if (userAmount > 2000 && userAmount <= 5000) {
            out = 50;
        } else if (userAmount > 5000) {
            out = 99;
        }
        return out;
    }
    //计算所有卡槽收益
    function calculateAll(address addr_) public view returns (uint){
        uint tempAmount;
        for (uint i = 0; i < 10; i++) {
            if (slotInfo[addr_][i].status) {
                tempAmount += calculateRewards(addr_, i);
            } else {
                continue;
            }
        }
        (uint out_,,) = checkPoundage(tempAmount);
        uint rew = out_ * 9 / 10;
        return rew;

    }
    //领取所有卡槽收益，如果有卡槽过期且超过了冷却期，会自动将这部分算力从全局中删除，并且更新总算力更改时间，将收益分别转到销毁，NFT挖矿池，缓释池和用户
    function claimRewards() external {
        if (block.timestamp >= deadLine) {
            deadLine = (86400 - block.timestamp % 86400) + block.timestamp - 28800;
            //刷新截止时间

        }
        require(userInfo[_msgSender()].total > 0, 'no stake');
        uint tempAmount;
        uint tempDebt = coutingDebt();
        for (uint i = 0; i < 10; i++) {
            if (slotInfo[_msgSender()][i].status ) {
                if ( block.timestamp <= slotInfo[_msgSender()][i].deadTime){//跳过过期卡槽的奖励
                    tempAmount += calculateRewards(_msgSender(), i);
                    slotInfo[_msgSender()][i].claimTime = block.timestamp;
                    slotInfo[_msgSender()][i].debt = tempDebt;
                }//如果算力或者卡槽过期，就关闭该卡槽
                if (slotInfo[_msgSender()][i].claimTime >= slotInfo[_msgSender()][i].endTime + cycle[2] || block.timestamp > slotInfo[_msgSender()][i].deadTime + cycle[2]) {
                    slotInfo[_msgSender()][i].status = false;
                    uint tempPow = slotInfo[_msgSender()][i].power;
                    userInfo[_msgSender()].total -= tempPow;
                    debt = coutingDebt();
                    totalPower -= tempPow;
                    lastTime = block.timestamp;
                }
            } else {
                continue;
            }
        }
        if (userInfo[_msgSender()].total == 0) {
            userInfo[_msgSender()].frist = false;
            userAmount --;
        }
        require(tempAmount > 0, 'no amount');
        (uint rew,uint burn,uint pool) = checkPoundage(tempAmount);
        uint newRew = rew * 9 / 10;//实际奖励
        uint toClaimAmount = newRew * toClaimRate / 100;//缓释池奖励
        uint fristRew = rew - newRew;//推荐人奖励
        address temp = refer.checkUserInvitor(_msgSender());
        uint selfPower = userInfo[msg.sender].total;//自己的算力
        uint upPower = userInfo[temp].total;//邀请人的算力
        if (upPower < selfPower && selfPower != 0){
            fristRew = fristRew * upPower / selfPower;//计算烧伤
        }
        userInfo[temp].fristRew += fristRew;
        HKT.transfer(_msgSender(), newRew - toClaimAmount );//转给用户
        HKT.transfer(claim, toClaimAmount);//转给缓释池合约
        HKT.transfer(burnAddress, burn);//销毁
        HKT.transfer(nftPool, pool);//转给nft挖矿
        ClaimHKT(claim).addAmount(_msgSender(), toClaimAmount);//更新缓释池数量和时间
        userInfo[_msgSender()].claimed += newRew - toClaimAmount;
        totalCliamed += newRew - toClaimAmount;
        emit Claim(_msgSender(), newRew - toClaimAmount);
    }
    //判断用户应该质押哪个卡槽，用循环跑用户卡槽，遇到第一个空卡槽就break并返回该卡槽号
    function checkSlotNum(address addr_) public view returns (uint){
        uint cc = 99;
        for (uint i = 0; i < 10; i++) {
            if (!slotInfo[addr_][i].status) {
                cc = i;
                break;
            } else {
                continue;
            }
        }
        return cc;
    }
    //返回长度为10的卡槽数组，1代表该索引的卡槽已被质押
    function checkUserSlot(address addr_) public view returns (uint[10] memory out_){
        for (uint i = 0; i < 10; i++) {
            if (slotInfo[addr_][i].status) {
                out_[i] = 1;
            }
        }
    }

    //从sunswap取到HKT的价格
    function getTokenPrice(address addr_) public view returns (uint) {
        address[] memory list = new address[](2);
        list[0] = addr_;
        list[1] = path[0];
        uint deci = IERC20(addr_).decimals();
        uint[] memory price = router.getAmountsOut(10**deci,list);
        return price[1];
        // return 1e6;
    }

    function getHktPrice() public view returns (uint){
        uint a = IERC20(path[0]).balanceOf(pair);
        uint b = IERC20(path[1]).balanceOf(pair);
        uint price = a * 1e18 / b;
        return price;
        // return 1e6;
    }
    //得到不同模式下，应该需要质押多少u
    function coutingUAmount(uint amount_, address token_) public view returns (uint) {
        uint decimal = IERC20(token_).decimals();
        uint uAmount;
        if (stakeMode == 1) {
            uAmount = amount_ * (10 ** (18 - decimal)) * coinRate[0] / coinRate[1];
        } else {
            uint p = getTokenPrice(token_);
            uAmount = p * amount_ / 10**(decimal);
        }
        return uAmount;
    }
    //维修卡槽
    function repair(uint slot_) external {
        require(slotInfo[_msgSender()][slot_].status, 'no use');
        uint need = repairCost;
        uint card = coutingRepair(_msgSender(), slot_);
        uint cardNum = coutingCard(_msgSender(), card);
        require(cardNum >= need, 'not enough amount');
        uint tokenId;
        uint cardId;
        uint k = NFT.balanceOf(_msgSender());
        uint amount;
        for (uint i = 0; i < k; i++) {//找出用户的第一张需要卡，取到tokenId，并转给合约
            tokenId = NFT.tokenOfOwnerByIndex(_msgSender(), i - amount);
            cardId = NFT.cardIdMap(tokenId);
            if (cardId == card) {
                NFT.safeTransferFrom(_msgSender(), address(this), tokenId);
                amount ++;
                if (amount == need){
                    break;
                }
            }
        }
        slotInfo[_msgSender()][slot_].deadTime += cycle[1];
        emit Repair(_msgSender(), slot_);
    }

    function stake(uint coinID_, uint amount_, uint slot_, address invitor_) public {
        if (refer.checkUserInvitor(_msgSender()) == address(0)) {
            bool temp = refer.isRefer(invitor_);
            require(temp || invitor_ == stage, 'wrong invitor');
            refer.bondUserInvitor(_msgSender(), invitor_);
        }
        uint deci = IERC20(coinID[coinID_]).decimals();
        require(amount_ >= 10**deci, 'amount must be more than 1');
        require(!slotInfo[_msgSender()][slot_].status, 'staked');
        require(coinID[coinID_] != address(0), 'wrong ID');
        require(slot_ < 10, 'wrong slot');
        require(amount_ % 10**deci == 0, 'must be int');
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        if (!userInfo[_msgSender()].frist) {
            userInfo[_msgSender()].frist = true;
            userAmount += 1;
        }
        uint uAmount = coutingUAmount(amount_, coinID[coinID_]);
        IERC20(coinID[coinID_]).transferFrom(_msgSender(), burnAddress, amount_);
        U.transferFrom(_msgSender(), address(this), uAmount * (100 - miningRate[4]) / 100);
        //转给合约
        U.transferFrom(_msgSender(), tec, uAmount * miningRate[4] / 100);
        // 转给技术
        if (swapAmount != 0) {
                router.swapExactTokensForTokens(swapAmount * miningRate[0], 0, path, burnAddress, block.timestamp + 720);
            //回购销毁
                router.swapExactTokensForTokens(swapAmount * miningRate[1], 0, path, fund, block.timestamp + 720);
            //回购给游戏公会
                router.swapExactTokensForTokens(swapAmount * miningRate[2], 0, path, nftPool, block.timestamp + 720);
            //回购给NFT矿池
        }
        swapAmount = uAmount;
        //这一次转进来的u用于下一次质押时回购
        uint tempPow = coutingPower(amount_, coinID[coinID_]);
        uint tempDebt = coutingDebt();
        if (block.timestamp >= deadLine) {
            deadLine = (86400 - block.timestamp % 86400) + block.timestamp - 28800;
            //刷新截止时间

        }
        if (tempPow >= rewardLimit[1]) {
            userReward[deadLine][_msgSender()][3] += tempPow;
            rewardPool[deadLine][3] += tempPow;
        } else if (tempPow >= rewardLimit[0]) {
            userReward[deadLine][_msgSender()][2] += tempPow;
            rewardPool[deadLine][2] += tempPow;
        } else {
            userReward[deadLine][_msgSender()][1] += tempPow;
            rewardPool[deadLine][1] += tempPow;
        }
        debt = tempDebt;
        totalPower += tempPow;
        lastTime = block.timestamp;
        userInfo[_msgSender()].total += tempPow;
        slotInfo[_msgSender()][slot_] = SlotInfo({
        status : true,
        power : tempPow,
        stakeTime : block.timestamp,
        endTime : block.timestamp + cycle[0],
        claimTime : block.timestamp,
        debt : tempDebt,
        deadTime : block.timestamp + cycle[1]
        });
        emit Stake(_msgSender(), coinID[coinID_], slot_, amount_);
    }

    function claimReferReward() external {
        require(userInfo[_msgSender()].fristRew > 0, 'no reward');
        uint rew = userInfo[_msgSender()].fristRew;
        uint toClaimAmount = rew * toClaimRate / 100;
        HKT.transfer(_msgSender(), rew - toClaimAmount);
        HKT.transfer(claim, toClaimAmount);//进入缓释池
        ClaimHKT(claim).addAmount(_msgSender(), toClaimAmount);
        userInfo[_msgSender()].referClaimed += rew - toClaimAmount;
        userInfo[_msgSender()].fristRew = 0 ;
        totalCliamed += rew - toClaimAmount;
        emit Claim(_msgSender(), rew - toClaimAmount);
    }

    function coutingFristReward(address addr_) external view returns (uint){
        if (deadLine == 0) {
            return 0;
        }
        uint times = deadLine - 1 days;
        uint rew;
        uint _rate = dailyOut * 85 * 20 / 10000;
        for (uint i = 0; i < fristRewDays; i++) {

            for (uint k = 1; k <= 3; k++) {
                if (userReward[times][addr_][k] == 0) {
                    continue;
                } else {
                    rew += userReward[times][addr_][k] * _rate * rewardRate[k - 1] / 100 / rewardPool[times][k];
                }
            }
            times = times - 1 days;
        }
        if (rew == 0){
            return 0;
        }
        return (rew *  toClaimRate / 100);
    }

    function claimFristReward() public {
        uint times = deadLine - 1 days;
        uint rew;
        uint _rate = dailyOut * 85 * 20 / 10000;
        uint tempPow;
        require(deadLine != 0,'no reward');
        for (uint i = 0; i < fristRewDays; i++) {

            for (uint k = 1; k <= 3; k++) {
                if (userReward[times][_msgSender()][k] == 0) {
                    continue;
                } else {
                    rew += userReward[times][_msgSender()][k] * _rate * rewardRate[k - 1] / 100 / rewardPool[times][k];
                    tempPow += userReward[times][_msgSender()][k];
                    userReward[times][_msgSender()][k] = 0;
                }
            }
            times = deadLine - 1 days;
        }
        require(rew > 0, 'no reward');
        uint toClaimAmount = rew * toClaimRate / 100;
        HKT.transfer(_msgSender(), rew - toClaimAmount);
        HKT.transfer(claim, toClaimAmount);
        address temp = refer.checkUserInvitor(_msgSender());
        ClaimHKT(claim).addAmount(_msgSender(), toClaimAmount);
        userInfo[_msgSender()].fristClaimed += rew - toClaimAmount;
        emit Claim(_msgSender(), rew - toClaimAmount);
        if (userInfo[temp].total < tempPow){
            rew = rew * userInfo[temp].total / tempPow;
        }
        userInfo[temp].fristRew += rew;

    }



    //读取用户卡牌数量
    function coutingCard(address addr_, uint card) public view returns (uint){
        uint k = NFT.balanceOf(addr_);
        uint tokenId;
        uint cardId;
        uint out;
        if (k == 0) {
            return 0;
        }
        for (uint i = 0; i < k; i++) {
            tokenId = NFT.tokenOfOwnerByIndex(addr_, i);
            cardId = NFT.cardIdMap(tokenId);
            if (cardId == card) {
                out ++;
            }
        }

        return out;
    }
    //通过用户的算力，判断续费应该用哪张卡牌
    function coutingRepair(address addr_, uint slot_) public view returns (uint out) {
        if (slotInfo[addr_][slot_].power > renewPower[2]) {
            out = renewCard[3];
        } else if (slotInfo[addr_][slot_].power > renewPower[1]) {
            out = renewCard[2];
        } else if (slotInfo[addr_][slot_].power > renewPower[0]) {
            out = renewCard[1];
        } else {
            out = renewCard[0];
        }
    }

    //续费卡槽，首先判断这个卡槽的算力需要什么卡牌续费，然后读取用户是否有这张卡牌，然后交易，增加卡槽时间
    function renew(uint slot_) public {
        require(slotInfo[_msgSender()][slot_].power > 0, 'no power');
        require(slotInfo[_msgSender()][slot_].status, 'no use');
        require(slotInfo[_msgSender()][slot_].endTime + cycle[2] > block.timestamp , 'overdue');
        uint need = 1;
        uint catFood = coutingCard(_msgSender(), food);
        require(catFood >= need, 'not enough amount');
        uint tokenId;
        uint cardId;
        uint k = NFT.balanceOf(_msgSender());
        uint amount;
        for (uint i = 0; i < k; i++) {
            tokenId = NFT.tokenOfOwnerByIndex(_msgSender(), i - amount);
            cardId = NFT.cardIdMap(tokenId);
            if (cardId == food) {
                NFT.safeTransferFrom(_msgSender(), address(this), tokenId);
                break;
            }
        }
        slotInfo[_msgSender()][slot_].endTime += cycle[0];
        emit Renew(_msgSender(), slot_);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

    function changeUserTime(uint endTime_, address addr_, uint slot_) external onlyOwner {
        slotInfo[addr_][slot_].endTime = endTime_;
    }
    //返回用户价值
    function checkUserValue(address addr_) external view returns (uint){
        return userInfo[addr_].total;
    }

    function checkCoinInfo(uint ID_) external view returns (string memory, uint){
        return (IERC20(coinID[ID_]).symbol(), IERC20(coinID[ID_]).decimals());
    }

    function checkCoinList() external view returns (string[] memory){
        return coinList;
    }

}

//SourceUnit: router.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

//SourceUnit: tool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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