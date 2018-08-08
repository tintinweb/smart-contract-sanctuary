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
    address public tokenAddress = 0x7741074905402D41AaF64abBa5BbD3a1705e8Ff5;
    
    mapping (address => uint) readyTime;
    uint public amount = 1000*100;  //*100為10^2，幣為兩位小數
    uint public cooldown = 300;  //冷卻時間(秒)
    mapping (address => uint8) record_play;
    mapping (address => uint8) record_comp;

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
    
    function play_paper(){
        play_game(0);
    }
    
    function play_scissors(){
        play_game(1);
    }
    
    function play_stone(){
        play_game(2);
    }
    
    function play_game(uint8 play) returns(bool win){
        require(readyTime[msg.sender] < block.timestamp);
        uint8 comp=uint8(uint(keccak256(block.difficulty, block.timestamp))%3);
        
        record_play[msg.sender] = play;
        record_comp[msg.sender] = comp;
        
        bool result = compare(play, comp);
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
            readyTime[msg.sender] = block.timestamp + cooldown;
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
                readyTime[msg.sender] = block.timestamp + cooldown;
            }
        }
        return result;
    }
    
    
    
//查詢
    
    function judge(uint8 orig) view returns(string mora){
        // 0 => 布   1 => 剪刀   2 => 石頭
            if (orig == 0){
                return "paper";
            }
            else if (orig == 1){
                return "scissors";
            }
            else if (orig == 2){
                return "stone";
            }
            else {
                return "error";
            }
            
        }
    
    function view_readyTime(address _address) view public returns(uint _readyTime){
        if (block.timestamp >= readyTime[_address]){
        return 0 ;
        }
        else{
        return readyTime[_address] - block.timestamp ;
        }
    }
    
    function self_readyTime() view public returns(uint _readyTime){
        view_readyTime(msg.sender);
    }
    
    function last_result(address _address) view public returns(string player, string computer){
        return (judge(record_play[ _address]),
        judge(record_play[ _address]));
    }
        
    function self_last_result() view public returns(string player, string computer){
        last_result(msg.sender);
    }
    
}