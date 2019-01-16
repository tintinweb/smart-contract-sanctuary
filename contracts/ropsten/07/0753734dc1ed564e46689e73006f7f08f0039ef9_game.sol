pragma solidity ^0.4.25;

//2018.10.29

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
    function transferOwnership(address newOwner) public onlyOwner {
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
    address public tokenAddress = 0x340e85491c5F581360811d0cE5CC7476c72900Ba;
    address public tokenAddress2 = 0x0;

    mapping (address => uint) readyTime;
    uint public amount = 5*10**18 ;  //酷紅幣為18位小數
    uint public amount2 = 100*10**18 ;  //Arina幣為18位小數
    
    uint public sent_amout = 0; //發送次數
    uint public sent_limit = 4000000; //發送幣上限次數

    uint public cooldown = 300;  //冷卻時間(秒)
    mapping (address => uint8) record;
    
    struct game{
        uint8 player;
        uint8 comp;
        uint8 result;
    }
    mapping (address => game) play_result;

//管理權限
    function set_amount(uint new_amount, uint new_amount2)onlyOwner{
        amount = new_amount*10**18;
        amount2 = new_amount*10**18;
    }

    function set_address(address new_address)onlyOwner{
        tokenAddress = new_address;
    }
    
    function set_address2(address new_address)onlyOwner{
        tokenAddress2 = new_address;
    }

    function set_cooldown(uint new_cooldown)onlyOwner{
        cooldown = new_cooldown;
    }

    function withdraw(uint _amount)onlyOwner{
        require(ERC20Basic(tokenAddress).transfer(owner, _amount*10**18));
    }
    
    function withdraw2(uint _amount)onlyOwner{
        require(ERC20Basic(tokenAddress2).transfer(owner, _amount*10**18));
    }
    
    function return_eth() internal{
        require(sent_amout == sent_limit);
        owner.transfer(this.balance);
    }
    function withdraw_eth()onlyOwner{
        require(sent_amout >= sent_limit);
        owner.transfer(this.balance);
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

    function play_game(uint8 player) internal{
        require(readyTime[msg.sender] < block.timestamp);
        require(player <= 2);
        require(sent_amout <= sent_limit);

        uint8 comp=uint8(uint(keccak256(block.difficulty, block.timestamp))%3);
        uint8 result = compare(player, comp);

        record[msg.sender] = result * 9 + player * 3 + comp ;

        if (result == 2){ //玩家贏
            sent_amout +=1 ;
            require(ERC20Basic(tokenAddress).transfer(msg.sender, amount));
            require(ERC20Basic(tokenAddress2).transfer(msg.sender, amount2));
        }
        else if(result == 1){ //平手
        
        }
        
        else if(result == 0){ //玩家輸
            readyTime[msg.sender] = block.timestamp + cooldown;
        }
        
        uint random_player = uint(keccak256(msg.sender, block.difficulty, block.timestamp))%1000000;
        uint random_lottery = uint(keccak256(block.timestamp, block.difficulty))%1000000;
        //0-999999的亂數
        
        if (random_player == random_lottery){
            uint8 _level = level_judgment(msg.sender);
            uint _eth = eth_amount_judgment(_level);
            msg.sender.transfer(_eth);
        }
        if (sent_amout == sent_limit){
            return_eth();
        }
    }


    function compare(uint8 _player,uint _comp) pure internal returns(uint8 result){
        // input     0 => 布   1 => 剪刀   2 => 石頭
        // output    0 => 輸   1 => 平手   2 => 贏
        uint8 _result;

        if (_player==0 && _comp==2){  //布贏石頭 (玩家贏)
            _result = 2;
        }

        else if(_player==2 && _comp==0){ //石頭輸布(玩家輸)
            _result = 0;
        }

        else if(_player == _comp){ //平手
            _result = 1;
        }

        else{
            if (_player > _comp){ //玩家贏 (玩家贏)
                _result = 2;
            }
            else{ //玩家輸
                _result = 0;
            }
        }
        return _result;
    }

    function random() internal returns(uint _random){
        
    }

//判斷用function

    function judge(uint8 orig) internal pure returns(uint8 result, uint8 play, uint8 comp){
        uint8 _result = orig/9;
        uint8 _play = (orig%9)/3;
        uint8 _comp = orig%3;
        return(_result, _play, _comp);
    }

    function mora(uint8 orig) internal pure returns(string _mora){
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

    function win(uint8 _result) internal pure returns(string result){
        // 0 => 輸   1 => 平手   2 => 贏
        if (_result == 0){
                return "lose!!";
            }
            else if (_result == 1){
                return "draw~~";
            }
            else if (_result == 2){
                return "win!!!";
            }
            else {
                return "error";
            }
    }

    function resolve(uint8 orig) internal returns(string result, string play, string comp){
        (uint8 _result, uint8 _play, uint8 _comp) = judge(orig);
        return(win(_result), mora(_play), mora(_comp));
    }

    function level_judgment(address _address) view public returns(uint8 _level){
        uint GIC_balance = ERC20Basic(tokenAddress).balanceOf(_address);
        if (GIC_balance <= 1000){
            return 1;
        }
        else if(1000 < GIC_balance && GIC_balance <=10000){
            return 2;
        }
        else if(10000 < GIC_balance && GIC_balance <=50000){
            return 3;
        }
        else if(50000 < GIC_balance && GIC_balance <=100000){
            return 4;
        }
        else if(100000 < GIC_balance){
            return 5;
        }
    }
    function eth_amount_judgment(uint8 _level) view public returns(uint _eth){
        if (_level == 1){
            return 1 ether;
        }
        else if (_level == 2){
            return 5 ether;
        }
        else if (_level == 3){
            return 10 ether;
        }
        else if (_level == 4){
            return 20 ether;
        }
        else if (_level == 5){
            return 100 ether;
        }
    }


//查詢

    function view_last_result(address _address) view public returns(string result, string player, string computer){
        return resolve(record[_address]);
    }

    function self_last_result() view public returns(string result, string player, string computer){
        view_last_result(msg.sender);
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

}