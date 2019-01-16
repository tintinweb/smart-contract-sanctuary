pragma solidity ^0.4.25;

//2018.11.06

/////設定管理者/////

contract owned {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner{
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
}

/////遊戲合約/////

contract game is owned{

//初始設定
    address public tokenAddress_GIC = 0xb1De50BFc89cCf7D6Df2bEDAD674306961559593;
    address public tokenAddress_Arina = 0xFe6c1821a26fDEA233D994736B7184Ab012A1f8a;

    mapping (address => uint) readyTime;
    uint public airdrop_GIC = 5*10**18 ;  //酷紅幣為18位小數
    uint public airdrop_Arina = 100*10**18 ;  //Arina幣為18位小數
    
    uint public total_airdrop_GIC = 21000000*10**18; //酷紅幣發送上限為2100萬顆
    uint public total_airdrop_Arina = 84000000*10**18; //Arina發送上限為8400萬顆
    
    uint public sent_times = 0; //發送次數(初始為零)
    uint public sent_limit = total_airdrop_GIC/airdrop_GIC; //發送幣上限次數(420萬次)

    uint public cooldown = 30;  //冷卻時間(秒)
    mapping (address => uint8) record; //紀錄輸贏及上次猜拳紀錄
    mapping (address => uint24[2])record_random;
    mapping (address => bool) initialization;
    
    event Play_game(address indexed from, uint8 record);
    //紀錄遊戲結果
    event Random(address indexed from, uint24 player, uint24 com);
    //記錄兩個亂數
    

//管理權限

    function set_address_GIC(address new_address)onlyOwner public{
        tokenAddress_GIC = new_address;
    }
    
    function set_address__Arina(address new_address)onlyOwner public{
        tokenAddress_Arina = new_address;
    }

    function set_cooldown(uint new_cooldown)onlyOwner public{
        cooldown = new_cooldown;
    }

    function withdraw_GIC(uint _amount)onlyOwner public{
        require(ERC20Basic(tokenAddress_GIC).transfer(owner, _amount*10**18));
    }
    
    function withdraw_Arina(uint _amount)onlyOwner public{
        require(ERC20Basic(tokenAddress_Arina).transfer(owner, _amount*10**18));
    }
    
    
    function withdraw_eth()onlyOwner public{
        owner.transfer(address(this).balance);
    }

//來猜拳!!!
    function ()public{
        play_game(0);
    }

    function play_paper()public{
        play_game(0);
    }

    function play_scissors()public{
        play_game(1);
    }

    function play_stone()public{
        play_game(2);
    }

    function play_game(uint8 player) internal{
        if (initialization[msg.sender] == false){
            initialization[msg.sender] = true;
        }
        
        require(readyTime[msg.sender] < block.timestamp);
        require(player <= 2);
        
        require(sent_times <= sent_limit);
        //檢查遊戲次數未小於限制次數

        uint8 comp=uint8(uint(keccak256(block.difficulty, block.timestamp))%3);
        uint8 result = compare(player, comp);
        
        uint8 _record = result * 9 + player * 3 + comp ;
        record[msg.sender] = _record;

        if (result == 2){ //玩家贏
            sent_times +=1 ;
            require(ERC20Basic(tokenAddress_GIC).transfer(msg.sender, airdrop_GIC));
            require(ERC20Basic(tokenAddress_Arina).transfer(msg.sender, airdrop_Arina));
        }
        else if(result == 1){ //平手
        
        }
        
        else if(result == 0){ //玩家輸
            readyTime[msg.sender] = block.timestamp + cooldown;
        }
        
        uint24 random_player = uint24(keccak256(msg.sender, block.difficulty, block.timestamp))%1000000;
        uint24 random_lottery = uint24(keccak256(block.timestamp, block.difficulty))%1000000;
        record_random[msg.sender][0] = random_player;
        record_random[msg.sender][1] = random_lottery;
        
        emit Play_game(msg.sender, _record);
        emit Random(msg.sender, random_player, random_lottery);
        
        //0-999999的亂數
        
        if (random_player == random_lottery){
            uint8 _level = level_judgment(msg.sender);
            uint _eth = eth_amount_judgment(_level);
            if (address(this).balance >= _eth){
                msg.sender.transfer(_eth);
            }
            else{
                msg.sender.transfer(address(this).balance);
            }
            
            //中獎的話傳送eth
        }
        
    }

//判斷用function

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

    function resolve(uint8 orig) internal pure returns(string result, string play, string comp){
        (uint8 _result, uint8 _play, uint8 _comp) = judge(orig);
        return(win(_result), mora(_play), mora(_comp));
    }

    function level_judgment(address _address) view public returns(uint8 _level){
        uint GIC_balance = ERC20Basic(tokenAddress_GIC).balanceOf(_address);
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
    
    function eth_amount_judgment(uint8 _level) pure public returns(uint _eth){
        if (_level == 1){
            return 1 ether;
        }
        else if (_level == 2){
            return 3 ether;
        }
        else if (_level == 3){
            return 5 ether;
        }
        else if (_level == 4){
            return 10 ether;
        }
        else if (_level == 5){
            return 20 ether;
        }
    }


//查詢

    function view_last_result(address _address) view public returns(string result, string player, string computer){
        if(initialization[_address] == false){
            return ("Not playing game yet"," "," ");
        }
        else{
            return resolve(record[_address]);
        }
    }
    function self_last_result() view public returns(string result, string player, string computer){
        return view_last_result(msg.sender);
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
        return view_readyTime(msg.sender);
    }
    
    
    function view_random(address _address) view public returns(uint24 random1, uint24 random2){
        return (record_random[_address][0],record_random[_address][1]);
    }
    function last_random() view public returns(uint24 random1, uint24 random2){
        return view_random(msg.sender);
    }

}