//SourceUnit: TronSuparSquire.sol

pragma solidity ^0.5.9;

contract TronSuparSquire {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
        address payable direct;
        mapping(uint8 => uint256) direct_per_level;
        address payable global;
        mapping(uint8 => uint256) global_per_level;
    }

    address payable admin;
    mapping(address => Player) public players;
    address payable [] pool_array;
    address payable [] global_pool;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    uint256 invest_amount;
    event Pool(address addr);
    event GlobalPool(address addr);
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        admin = msg.sender;
        invest_amount = 200000000;
        pool_array.push(msg.sender);
        global_pool.push(msg.sender);
    }
    function deposit(address payable _referral) public payable {
        require(msg.value == invest_amount,"Invalid Investment Amount"); 
        if(players[msg.sender].direct == address(0)) {
            players[msg.sender].direct = _referral;
            players[_referral].direct_per_level[0]++;
            if(players[_referral].direct_per_level[0]>2){
                _referral.transfer(100 trx);
            }else if(players[_referral].direct_per_level[0]==2){
                global_pool.push(_referral);
                emit GlobalPool(_referral);
                _setGlobalPool(_referral,global_pool.length);
                
            }
        }
        pool_array.push(msg.sender);
        emit Pool(msg.sender);
        _setPool(msg.sender,pool_array.length);
    }
    function _setPool(address _addr,uint256 poollength) private{
        uint256 pool = (poollength>2)?poollength-2:0;
        address payable _ref;
        address payable _referral;
        if(pool<=0){
            _ref = pool_array[0]; 
        }else{
            uint256 last_pool = uint(pool)/2;
            _ref = pool_array[last_pool];
        }
        if(players[_ref].referrals_per_level[0]<2){
            _referral = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
               if(players[pool_array[i]].referrals_per_level[0]<2){
                    _referral = _ref;
                    break;
                } 
            }
        }
        _setReferral(_addr,_referral);
    }
    
    function _setReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            for(uint8 i = 0; i <=15; i++) {
                players[_referral].referrals_per_level[i]++;
                
                if(i==2 && players[_referral].referrals_per_level[2]==8  && players[_referral].income_per_level[2]==0){
                    players[_referral].income_per_level[2] = 200;
                    _referral.transfer(200 trx);
                }
                if(i==5 && players[_referral].referrals_per_level[5]==64  && players[_referral].income_per_level[5]==0){
                    players[_referral].income_per_level[5] = 3000;
                   _referral.transfer(3000 trx);
                }
                if(i==9 &&  players[_referral].referrals_per_level[9]==1024  && players[_referral].income_per_level[9]==0){
                    players[_referral].income_per_level[9] = 23400;
                    _referral.transfer(23400 trx);
                }
                if(i==14 && players[_referral].referrals_per_level[14]==32768  && players[_referral].income_per_level[14]==0){
                    players[_referral].income_per_level[14] = 1566000;
                   _referral.transfer(1566000 trx);
                }
                
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    function _setGlobalPool(address _referral,uint256 poollength) private{
        uint256 pool = poollength-2; //array length + formula (x-2)
        address payable _ref;
        address payable _parent;
        if(pool<1){
            _ref = global_pool[0]; 
        }else{
            uint256 last_pool = uint(pool)/4; // formula (x-2)/3
            _ref = global_pool[last_pool];
        }
        if(players[_ref].global_per_level[0]<=3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[global_pool[i]].global_per_level[0]<=3){
                   _parent = global_pool[i];
                }
            }
        }
        _setGlobalReferral(_referral,_parent);
    }
    
    function _setGlobalReferral(address _addr, address payable  _referral) private {
        if(players[_addr].global == address(0)) {
            players[_addr].global = _referral;
            players[_referral].global_per_level[0]++;
            
            // For 100 trx income 1
            if(players[_referral].global_per_level[0]<=3) {
                if(_referral != address(0)){
                    _referral.transfer(90 trx);
                    admin.transfer(10 trx);
                }
                if(players[_referral].global_per_level[0]==3) {
                    // For 200 trx income 2
                    _referral = players[_referral].global;
                    players[_referral].global_per_level[1]++;
                    if(players[_referral].global_per_level[1]<=3){
                        if(_referral != address(0)){
                            _referral.transfer(180 trx);
                            admin.transfer(20 trx);
                        }
                        if(players[_referral].global_per_level[1]==3) {
                            // For 400 trx income 3
                            _referral = players[_referral].global;
                            players[_referral].global_per_level[2]++;
                            if(players[_referral].global_per_level[2]<=3){
                                if(_referral != address(0)){
                                    _referral.transfer(360 trx);
                                    admin.transfer(40 trx);
                                }
                                if(players[_referral].global_per_level[2]==3) {
                                    // For 800 trx income 4
                                    _referral = players[_referral].global;
                                    players[_referral].global_per_level[3]++;
                                    if(players[_referral].global_per_level[3]<=3){
                                        if(_referral != address(0)){
                                            _referral.transfer(720 trx);
                                            admin.transfer(80 trx);
                                        }
                                        if(players[_referral].global_per_level[3]==3) {
                                            // For 1600 trx income 5
                                            _referral = players[_referral].global;
                                            players[_referral].global_per_level[4]++;
                                            if(players[_referral].global_per_level[4]<=3){
                                                if(_referral != address(0)){
                                                    _referral.transfer(1440 trx);
                                                    admin.transfer(160 trx);
                                                }
                                                if(players[_referral].global_per_level[4]==3) {
                                                    // For 3200 trx income 6
                                                    _referral = players[_referral].global;
                                                    players[_referral].global_per_level[5]++;
                                                    if(players[_referral].global_per_level[5]<=3){
                                                        if(_referral != address(0)){
                                                            _referral.transfer(2880 trx);
                                                            admin.transfer(320 trx);
                                                        }
                                                        if(players[_referral].global_per_level[5]==3) {
                                                            // For 6400 trx income 7
                                                            _referral = players[_referral].global;
                                                            players[_referral].global_per_level[6]++;
                                                            if(players[_referral].global_per_level[6]<=3){
                                                                if(_referral != address(0)){
                                                                    _referral.transfer(5760 trx);
                                                                    admin.transfer(640 trx);
                                                                }
                                                                
                                                                
                                                            }else if(players[_referral].global_per_level[6]>=4){
                                                                if(players[_referral].direct != address(0)){
                                                                    Player storage player = players[players[_referral].direct];
                                                                    if(player.direct_per_level[0]>=2){
                                                                        players[_referral].direct.transfer(5760 trx);
                                                                        admin.transfer(640 trx);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        
                                                    }else if(players[_referral].global_per_level[5]>=4){
                                                        if(players[_referral].direct != address(0)){
                                                            Player storage player = players[players[_referral].direct];
                                                            if(player.direct_per_level[0]>=2){
                                                                players[_referral].direct.transfer(2880 trx);
                                                                admin.transfer(320 trx);
                                                            }
                                                        }
                                                    }
                                                }
                                            }else if(players[_referral].global_per_level[4]>=4){
                                                if(players[_referral].direct != address(0)){
                                                    Player storage player = players[players[_referral].direct];
                                                    if(player.direct_per_level[0]>=2){
                                                        players[_referral].direct.transfer(1440 trx);
                                                        admin.transfer(160 trx);
                                                    }
                                                }
                                            }           
                                        }
                                    }else if(players[_referral].global_per_level[3]>=4){
                                        if(players[_referral].direct != address(0)){
                                            Player storage player = players[players[_referral].direct];
                                            if(player.direct_per_level[0]>=2){
                                                players[_referral].direct.transfer(720 trx);
                                                admin.transfer(80 trx);
                                            }
                                        }
                                    }
                                }
                            }else if(players[_referral].global_per_level[2]>=4){
                                if(players[_referral].direct != address(0)){
                                    Player storage player = players[players[_referral].direct];
                                    if(player.direct_per_level[0]>=2){
                                        players[_referral].direct.transfer(360 trx);
                                        admin.transfer(40 trx);
                                    }
                                }
                            }
                        }
                    }else if(players[_referral].global_per_level[1]>=4){
                        if(players[_referral].direct != address(0)){
                            Player storage player = players[players[_referral].direct];
                            if(player.direct_per_level[0]>=2){
                            players[_referral].direct.transfer(180 trx);
                            admin.transfer(20 trx);
                            }
                        }
                    }
                }
            }else if(players[_referral].global_per_level[0]>=4){
                if(players[_referral].direct != address(0)){
                    Player storage player = players[players[_referral].direct];
                    if(player.direct_per_level[0]>=2){
                        players[_referral].direct.transfer(90 trx);
                        admin.transfer(10 trx);
                    }
                }
            }
        }
    }
    
    function transferOwnership(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transfer(_amount);
    }
    
    function poolInfo() view external returns(address payable [] memory) {
        return pool_array;
    }
    function globalInfo() view external returns(address payable [] memory) {
        return global_pool;
    }
    
    function userInfo(address _addr) view external returns( uint256[16] memory referrals,uint256[16] memory global, uint256[16] memory income) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            referrals[i] = player.referrals_per_level[i];
            global[i] = player.global_per_level[i];
            income[i] = player.income_per_level[i];
        }
       
        return (
           referrals,
           global,
           income
        );
    }
    
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}