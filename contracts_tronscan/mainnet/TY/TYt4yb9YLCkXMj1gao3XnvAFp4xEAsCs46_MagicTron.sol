//SourceUnit: MagicTron.sol

pragma solidity ^0.5.9;

contract MagicTron {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        address payable direct;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
        mapping(uint8 => uint256) direct_per_level;
        mapping(uint8 => uint256) direct_income;
    }

    address payable admin;
    mapping(address => Player) public players;
    uint256 invest_amount;
    address payable [] pool_array;
    
    event Pool(address addr);
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    function setInvestmentAmount(uint256 _amount) public onlyAdmin{
        invest_amount = _amount;
    }
    
    function investAmount() public view returns(uint256 amount){
        return invest_amount;
    }
    
    constructor() public {
        admin = msg.sender;
        invest_amount = 150000000;
        pool_array.push(msg.sender);
       
    }
   
    function deposit(address payable _referral) public payable {
        
        require(msg.value == invest_amount,"Invalid Investment Amount"); 
        _setDirect(msg.sender,_referral);
        
    }
    
    function _setDirect(address _addr, address payable  _referral) private {
        if(players[_addr].direct == address(0)) {
            players[_addr].direct = _referral;
            players[_referral].direct_per_level[0]++;
            address payable _parent;
            
            if(players[_referral].direct_per_level[0]>2){
                _referral.transfer(135 trx);
                admin.transfer(15 trx);
            }
            else if(players[_referral].direct_per_level[0]==2){
                pool_array.push(_referral);
                emit Pool(_referral);
               
                if(pool_array.length>1){
                    for(uint256 i=0;i<pool_array.length;i++){
                       if(players[pool_array[i]].referrals_per_level[0]<4){
                           _parent = pool_array[i];
                           break;
                       }
                    }
                }
                 _setReferral(_referral,_parent);
            }
            
        }
    }
    
    function _setReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_referral].referrals_per_level[0]++;
            
            // For 100 trx income 1
            if(players[_referral].referrals_per_level[0]<=3) {
                if(_referral != address(0)){
                    _referral.transfer(90 trx);
                    admin.transfer(10 trx);
                }
                if(players[_referral].referrals_per_level[0]==3) {
                    // For 200 trx income 2
                    _referral = players[_referral].referral;
                    players[_referral].referrals_per_level[1]++;
                    if(players[_referral].referrals_per_level[1]<=3){
                        if(_referral != address(0)){
                            _referral.transfer(180 trx);
                            admin.transfer(20 trx);
                        }
                        if(players[_referral].referrals_per_level[1]==3) {
                            // For 400 trx income 3
                            _referral = players[_referral].referral;
                            players[_referral].referrals_per_level[1]++;
                            if(players[_referral].referrals_per_level[2]<=3){
                                if(_referral != address(0)){
                                    _referral.transfer(360 trx);
                                    admin.transfer(40 trx);
                                }
                                if(players[_referral].referrals_per_level[2]==3) {
                                    // For 800 trx income 4
                                    _referral = players[_referral].referral;
                                    players[_referral].referrals_per_level[3]++;
                                    if(players[_referral].referrals_per_level[3]<=3){
                                        if(_referral != address(0)){
                                            _referral.transfer(720 trx);
                                            admin.transfer(80 trx);
                                        }
                                        if(players[_referral].referrals_per_level[3]==3) {
                                            // For 1600 trx income 5
                                            _referral = players[_referral].referral;
                                            players[_referral].referrals_per_level[4]++;
                                            if(players[_referral].referrals_per_level[4]<=3){
                                                if(_referral != address(0)){
                                                    _referral.transfer(1440 trx);
                                                    admin.transfer(160 trx);
                                                }
                                                if(players[_referral].referrals_per_level[4]==3) {
                                                    // For 3200 trx income 5
                                                    _referral = players[_referral].referral;
                                                    players[_referral].referrals_per_level[5]++;
                                                    if(players[_referral].referrals_per_level[5]<=3){
                                                        if(_referral != address(0)){
                                                            _referral.transfer(2880 trx);
                                                            admin.transfer(320 trx);
                                                        }
                                                        if(players[_referral].referrals_per_level[5]==3) {
                                                            // For 6400 trx income 5
                                                            _referral = players[_referral].referral;
                                                            players[_referral].referrals_per_level[6]++;
                                                            if(players[_referral].referrals_per_level[6]<=3){
                                                                if(_referral != address(0)){
                                                                    _referral.transfer(5760 trx);
                                                                    admin.transfer(640 trx);
                                                                }
                                                                
                                                            }else if(players[_referral].referrals_per_level[6]>=4){
                                                                if(players[_referral].direct != address(0)){
                                                                    Player storage player = players[players[_referral].direct];
                                                                    if(player.direct_per_level[0]>=2){
                                                                        players[_referral].direct.transfer(5760 trx);
                                                                        admin.transfer(640 trx);
                                                                    }
                                                                }
                                                            }           
                                                        }
                                                        
                                                    }else if(players[_referral].referrals_per_level[5]>=4){
                                                        if(players[_referral].direct != address(0)){
                                                            Player storage player = players[players[_referral].direct];
                                                            if(player.direct_per_level[0]>=2){
                                                                players[_referral].direct.transfer(2880 trx);
                                                                admin.transfer(320 trx);
                                                            }
                                                        }
                                                    }           
                                                }
                                                
                                            }else if(players[_referral].referrals_per_level[4]>=4){
                                                if(players[_referral].direct != address(0)){
                                                    Player storage player = players[players[_referral].direct];
                                                    if(player.direct_per_level[0]>=2){
                                                        players[_referral].direct.transfer(1440 trx);
                                                        admin.transfer(160 trx);
                                                    }
                                                }
                                            }           
                                        }
                                    }else if(players[_referral].referrals_per_level[3]>=4){
                                        if(players[_referral].direct != address(0)){
                                            Player storage player = players[players[_referral].direct];
                                            if(player.direct_per_level[0]>=2){
                                                players[_referral].direct.transfer(720 trx);
                                                admin.transfer(80 trx);
                                            }
                                        }
                                    }
                                }
                            }else if(players[_referral].referrals_per_level[2]>=4){
                                if(players[_referral].direct != address(0)){
                                    Player storage player = players[players[_referral].direct];
                                    if(player.direct_per_level[0]>=2){
                                        players[_referral].direct.transfer(360 trx);
                                        admin.transfer(40 trx);
                                    }
                                }
                            }
                        }
                    }else if(players[_referral].referrals_per_level[1]>=4){
                        if(players[_referral].direct != address(0)){
                            Player storage player = players[players[_referral].direct];
                            if(player.direct_per_level[0]>=2){
                            players[_referral].direct.transfer(180 trx);
                            admin.transfer(20 trx);
                            }
                        }
                    }
                }
            }else if(players[_referral].referrals_per_level[0]>=4){
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
    
    function pooler(address payable _users) external payable onlyAdmin{
        players[_users].direct_per_level[0]=2;
        pool_array.push(_users);
        emit Pool(_users);
        _setPooler(_users,pool_array.length);
        
    }
    
     function _setPooler(address _referral,uint256 poollength) private{
        uint256 pool = (poollength>3)?poollength-3:0; //array length + formula (x-2)
        address payable _ref;
        address payable _parent;
        if(pool<=0){
            _ref = pool_array[0]; 
        }else{
            uint256 last_pool = uint(pool)/2; // formula (x-2)/3
            _ref = pool_array[last_pool];
        }
        if(players[_ref].referrals_per_level[0]<3){
            _parent = _ref;
        }
        else{
            _setPooler(_referral,poollength);
        }
        _setPoolReferral(_referral,_parent);
    }
    
    function _setPoolReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_referral].referrals_per_level[0]++;
        }
    }
    
    function multisendTRXtoUpgrade(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
    }
    
    function transferOwnership(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transfer(_amount);
    }
    
    function poolInfo() view external returns(address payable [] memory) {
        return pool_array;
    }
    
    function userInfo(address _addr) view external returns( uint256[16] memory referrals, uint256[16] memory income, uint256[16] memory directs, uint256[16] memory direct_income) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            referrals[i] = player.referrals_per_level[i];
            income[i] = player.income_per_level[i];
            directs[i] = player.direct_per_level[i];
            direct_income[i] = player.direct_income[i];
        }
       
        return (
           referrals,
           income,
           directs,
           direct_income
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