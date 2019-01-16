pragma solidity ^0.4.24;

contract Lottery{
    //管理员
  address public manager;
  //彩民
  address[] public players;
  //中奖人
  address public winner;
  //第几期
  uint256 public round;
  
  constructor() public{
      manager = msg.sender;
  }
  
    //彩民参与进来
    function play()public payable{
        //1.投钱,判断投的钱是否满足投注规则
        require(msg.value == 1 ether);
        //2.判断通过,把这个人添加到彩民池
        players.push(msg.sender);
    }
    
    function getBalance()public view returns (uint256){
        return address(this).balance;
    }
    
    //开奖函数,由管理员来执行
    function draw()onlyManager public {
        require(players.length != 0);
        uint256 res = uint256(sha256(abi.encodePacked(block.difficulty,now,players.length)));
        uint256 index = res % players.length;
        winner = players[index];
        winner.transfer(address(this).balance);
        round++;
        delete players;
    }
    //修饰器,限定只有管理员来执行开奖
    modifier onlyManager(){
        require (msg.sender == manager);
        _;
    }
    
    //退奖函数,只有管理员才可以执行
    function drawback()onlyManager public{
        require (players.length != 0);
        for (uint256 i=0;i<players.length;i++){
            players[i].transfer(1 ether);
        }
        round++;
        delete players;
    }
    
    //获取所有玩家
    function getPlayers()public view returns(address[]){
        return players;
    }
    
    //获取所有玩家
    function getPlayerCount()public view returns(uint256){
        return players.length;
    }
}