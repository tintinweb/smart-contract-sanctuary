pragma solidity ^0.4.23;

/*
 * 以太坊上的去中心化竞猜合约
 * @Author Leo Ning <windywany@gmail.com>
 * @Data 2018-07-06
 */
contract TrustBet {
    address     public owner;//合约所有者
    bool        public stop      = false;//是否停止竞猜
    uint8       public winTeam   = 3;//比赛结果：3未开奖；0:1队胜；1:2队胜；2:2队平
    uint256     public stopWithdrawBlock = 0;//停止提现区块
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
    }

    // 开奖（发起人调用），team=0时1队赢，team=1时2队赢,team=2时2队打平
    function lottery(uint8 team) public owned {
        //已经停止竞猜且team正确才能开奖
        require(stop && team < 3);
        //赢的队伍
        winTeam = team;
        //130000个区块之后停止提现(大概开奖后15天内)
        stopWithdrawBlock = block.number + 130000;
    }

    //竞猜，team=0时1队赢，team=1时2队赢,team=2时打平
    function bet(uint8 team) public payable {
        //未停止竞猜且team正确
        require(!stop && team < 3 && msg.value >= 0.01 ether);
        //用户竞猜总额
        stakes[team][msg.sender] += msg.value;
        //队伍竞猜总额
        teamStakes[team] += msg.value;
    }

    //提取奖金
    function withdraw() public returns (uint256) {
        //开奖26000个区块内一定要提现且要猜中
        require(stopWithdrawBlock>=block.number && stakes[winTeam][msg.sender]>0);
        //竞猜金额
        uint256 myStake = stakes[winTeam][msg.sender];
        //钱分完了，不能再分喽，如果你有GAS，你可以无限次调用此方法
        stakes[winTeam][msg.sender] = 0;
        //计算奖金
        uint256 win = myStake * (teamStakes[0] + teamStakes[1] + teamStakes[2]) / teamStakes[winTeam];
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
        require(winTeam < 3 && stopWithdrawBlock<block.number && address(this).balance>0);
        owner.transfer(address(this).balance);
    }
}