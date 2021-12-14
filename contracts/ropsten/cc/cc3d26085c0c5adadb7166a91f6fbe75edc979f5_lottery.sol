/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract lottery{

    //--------结构体---------

    struct Player{
        address add;
        uint256 vote;
    }
    
    struct Winner{
        address add;
        uint256 bonus;
    }

    // ------状态变量--------

    address public creator;

    Winner[] public winners;
    Player[] public players;

    uint256 constant MINETH = 0.1 ether;

    // --------构造器---------

    // 设置管理员
    constructor() payable {
        creator = msg.sender;
    }

    // ---------事件----------  

    event logdraw(address sender, uint amount);
    event logWithdraw(address sender, uint amount);
    event received(address, uint);

    // --------修改器---------

    // 权限
    modifier onlyCreator(){
        require(msg.sender == creator,"Only creator can call");
        _;
   }
   // 开始
    modifier began(){
        require(winners.length > 0,"Not began");
        _;
   }
   // 新一局开始
    modifier started(){
        require(players.length > 0,"Not stared");
        _;
   }
   // 最小额度
   modifier gtEth(){
        require(msg.value >= MINETH,"Lower than the MINETH");
        _;
   }

    // ---------函数----------

    // 查询奖池余额
    function getBalance() public view returns(uint256){
        return address(this).balance / (10 ** 18);
    }

    // 查询当前全部玩家
    function getPlayers() public view returns(Player[] memory){
        return players;
    }

    // 查询全部赢家
    function getWinners() public view began returns(Winner[] memory){
        return winners;
    }

    // 开奖
    function draw() public onlyCreator started{
            
        uint256 money = address(this).balance * 9 / 10; 
        uint256 money2 = address(this).balance - money;

        // 开奖
        uint256 allVote = 0;
        for (uint256 i = 0; i < players.length; i++) {
            allVote += players[i].vote;
        }

        // 伪伪随机
        uint256 win = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%(allVote);

        allVote = 0;
        for (uint256 i = 0; i < players.length; i++) {
            // 找到中奖地址
            if (allVote <= win  &&  win < (allVote + players[i].vote)){
                Winner memory w = Winner(players[i].add,money);
                winners.push(w);
                break;
            }
            allVote += players[i].vote;
        }
        
        // 发送奖金
        payable(winners[winners.length - 1].add).transfer(money);
        payable(creator).transfer(money2);

        delete players;
    }
    
    // 撤销
    function withdraw() public onlyCreator started{
        // 如果发现 (0,0) 表示该期为撤销
        Winner memory w = Winner(address(0),0);
        winners.push(w);

        // 退款
        for (uint256 i = 0; i < players.length; i++ ){
            payable(players[i].add).transfer(players[i].vote * MINETH * 9 / 10);
        }

        uint256 money2 = address(this).balance;
        payable(creator).transfer(money2);

        delete players;
    }

    // 参加彩票
    function play(address _add, uint256 _val) internal{

        // 零头不参与计数
        uint256 vo = 0;
        vo = _val / MINETH;
        
        Player memory p = Player(_add,vo);
        players.push(p);
    }

    // payable
    receive() external payable {
        // 未达到门槛
        if(msg.value >= MINETH){
            play(msg.sender, msg.value);
        }
        emit received(msg.sender, msg.value);

    }

    fallback() external payable {}
}