pragma solidity ^0.4.24;

/////設定管理者/////

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}    

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/////遊戲合約/////

contract game is owned{
    
//初始設定
    address public tokenAddress = 0xd58cb0c288358D139550fB39a6938Ec05C562f5a;
    
    mapping (address => uint) public readyTime;
    uint public amount = 100*100;  //*100為10^2，幣為兩位小數
    uint public cooldown = 300;  //冷卻時間(秒)

//管理權限
    function set_amount(uint new_amount)onlyOwner{
        amount = new_amount*100;
    }
    
    function set_address(address new_address)onlyOwner{
        tokenAddress = new_address;
    }
    
    function set_cooldown(uint new_cooldown)onlyOwner{
        cooldown = new_cooldown;
    }
    
    function withdraw(uint _amount)onlyOwner{
        require(ERC20Basic(tokenAddress).transfer(owner, _amount*100));
    }
    
//來猜拳!!! 
    function (){
        play_game(0);
    }
    
    function paper(){
        play_game(0);
    }
    
    function scissors(){
        play_game(1);
    }
    
    function stone(){
        play_game(2);
    }
    
    function play_game(uint8 mora) returns(bool win){
        require(readyTime[msg.sender] < now);
        uint8 com=uint8(uint(keccak256(block.difficulty, block.timestamp))%3);
        bool result = compare(mora, com);
        if (result == true){
            ERC20Basic(tokenAddress).transfer(msg.sender, amount);
        }
        return result;
    }
    
    function compare(uint8 player,uint computer) returns(bool win){
        // 0 => 布   1 => 剪刀   2 => 石頭
        bool result;
        if (player==0 && computer==2){  //布贏石頭
            result = true;
            
        }
        
        else if(player==2 && computer==0){ //石頭輸布(冷卻時間重置)
            result = false;
            readyTime[msg.sender] = now + cooldown;
        }
        
        else if(player == computer){ //平手
            result = false;
        }
        
        else{
            if (player > computer){ //玩家贏
                result = true;
            }
            else{ //玩家輸(冷卻時間重置)
                result = false;
                readyTime[msg.sender] = now + cooldown;
            }
        }
        return result;
    }
    
    
    function view_readyTime() view public returns(uint _readyTime){
        if (now >= readyTime[msg.sender]){
        return 0 ;
        }
        else{
        return readyTime[msg.sender]-now ;
        }
    }
    
}