pragma solidity ^0.4.23;

/*
 * 以太坊上的去中心化竞猜合约
 * @Author Leo Ning <windywany@gmail.com>
 * @Data 2018-07-06
 * @Version 1.0.0
 */
contract TrustBet {
    string      public matchInfo = &quot;2018 Russia World Cup Quarter-finals Sweden VS England  (Sat, 7/7, 10:00 AM)&quot;;//比赛信息
    address     public owner;//合约所有者
    bool        public stop     = false;//是否停止竞猜
    int8        public winTeam  = -1;//比赛结果：-1未开奖；0:1队胜；1:2队胜；2:2队平
    uint256     public stopWithdrawBlock = 0;//停止提现区块
    uint256     public stopBetBlock = 0;//停止竞猜区块
    mapping(uint8 => mapping(address=>uint256)) public stakes;//竞猜金额
    uint256[3] public teamStakes;//每队竞猜金额
    
    //只能合约所有者执行的方法
    modifier owned {
        require(owner == msg.sender);
        _;
    }

    //创建可信任竞猜合约
    constructor () public {
        owner = msg.sender;
    }

    //停止竞猜（发起人调用）
    function stopBet() public owned {
        stop = true;
        stopBetBlock = block.number;
    }

    // 开奖（发起人调用），team=0时1队赢，team=1时2队赢,team=2时2队打平
    function lottery(int8 team) public owned {
        //已经停止竞猜且team正确
        require(stop && (team == 0 || team == 1 || team == 2));
        //赢的队伍
        winTeam = team;
        //26000个区块之后停止提现(大概开奖后30天内)
        stopWithdrawBlock = block.number + 260000;
    }

    //竞猜， team=0时猜1队赢，team=1时猜2队赢,team=2时2队打平
    function bet(uint8 team) public payable {
        //未停止竞猜且team正确
        require(!stop && (team == 0 || team == 1 || team == 2) && msg.value >= 0.01 ether);
        //用户竞猜总额
        stakes[team][msg.sender] += msg.value;
        //队伍竞猜总额
        teamStakes[team] += msg.value;
    }

    //提取奖金
    function withdraw() public returns (uint256) {
        uint8 _win = uint8(winTeam);
        //开奖26000个区块内一定要提现且要猜中
        require(stopWithdrawBlock>=block.number && winTeam>=0 && stakes[_win][msg.sender]>0);
        //竞猜金额
        uint256 myStake = stakes[_win][msg.sender];
        //钱分完了，不能再分喽，如果你有GAS，你可以无限次调用此方法
        stakes[_win][msg.sender] = 0;
        //计算奖金
        uint256 win = myStake * (teamStakes[0] + teamStakes[1] + teamStakes[2]) / teamStakes[_win];
        //扣除百分之一的手续费后的金额
        uint256 amount = win - win * 1 / 100;
        //奖金要大小0（^_^）
        assert(amount > 0);
        //有余额才能分
        if(address(this).balance > amount){
            msg.sender.transfer(amount);
            return amount;
        }
        return 0;
    }

    //提取佣金
    function commission() public {
        //开奖26000个区块之后，竞猜发起人可以提取佣金
        require(stopWithdrawBlock<block.number && address(this).balance>0);
        owner.transfer(address(this).balance);
    }
}