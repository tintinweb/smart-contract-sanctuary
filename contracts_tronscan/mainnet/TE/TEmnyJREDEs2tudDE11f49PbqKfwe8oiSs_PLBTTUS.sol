//SourceUnit: PLBTTUS.sol

pragma solidity ^0.5.9 <0.6.10;

contract PLBTTUS {
    using SafeMath for uint256;
    
    struct Player {
        uint256 global;
        uint256 counter;
        mapping(uint256 => uint256) global_per_level;
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
    }
    
    trcToken token;

    address payable admin;
    mapping(address => Player) public players;
    address payable [] global_pool;
    address payable [] pool_array;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    uint256 invest_amount;
    event GlobalPool(address addr);
    event Pool(address addr);
    
    function changeToken(trcToken _token) external onlyAdmin{
        token = _token;
    } 
    
    function contractInfo() view external returns(uint256 trx_balance, uint256 token_balance) {
        return(
            trx_balance = address(this).balance,
            token_balance = address(this).tokenBalance(token)
        );
    }
    
    constructor() public {
        admin = msg.sender;
        token = 1002000;
        invest_amount = 500000000;
        global_pool.push(msg.sender);
    }
    
    function multisendToken(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        uint256 total = msg.tokenvalue;
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transferToken(_balances[i],token);
        }
        global_pool.push(msg.sender);
        emit GlobalPool(msg.sender);
        _setGlobalPool(msg.sender,global_pool.length);
    }
    
    function _setGlobalPool(address _referral,uint256 poollength) private{
        uint256 pool = poollength-2; //array length + formula (x-2)
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            uint256 last_pool = uint256(pool)/3; // formula (x-2)/3
            _ref = last_pool;
        }
        if(players[global_pool[_ref]].global_per_level[0]<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[global_pool[i]].global_per_level[0]<3){
                   _parent = i;
                   break;
                }
            }
        }
        _setGlobalReferral(_referral,_parent);
    }
    
    function _setGlobalReferral(address _addr, uint256  _referral) private {
        players[_addr].global = _referral;
        
        for(uint8 i=0;i<=11;i++){
            players[global_pool[_referral]].global_per_level[i]++;
            if(i==0 && players[global_pool[_referral]].global_per_level[0]==3){
                global_pool[_referral].transferToken(427500000,token); //450 427.5 btt
            }else if(i==1 && players[global_pool[_referral]].global_per_level[1]==9){
                global_pool[_referral].transferToken(712500000,token);//750 712.5 btt
            }else if(i==2 && players[global_pool[_referral]].global_per_level[2]==27){
                global_pool[_referral].transferToken(855000000,token);//900 855 btt
            }else if(i==3 && players[global_pool[_referral]].global_per_level[3]==81){
                global_pool[_referral].transferToken(1045000000,token);//1100 1045 btt
            }else if(i==4 && players[global_pool[_referral]].global_per_level[4]==243){
                global_pool[_referral].transferToken(2280000000,token); //2400 2280 btt
            }else if(i==5 && players[global_pool[_referral]].global_per_level[4]==729){
                global_pool[_referral].transferToken(3420000000,token);//3600 3420 btt
            }else if(i==6 && players[global_pool[_referral]].global_per_level[6]==2187){
                global_pool[_referral].transferToken(5130000000,token); //5400 5130 btt
            }else if(i==7 && players[global_pool[_referral]].global_per_level[7]==6561){
                global_pool[_referral].transferToken(5890000000,token); //6200 5890 btt
            }else if(i==8 && players[global_pool[_referral]].global_per_level[8]==19683){
                global_pool[_referral].transferToken(14250000000,token);//15000 14250 btt
            }else if(i==9 && players[global_pool[_referral]].global_per_level[9]==59049){
                global_pool[_referral].transferToken(23750000000,token);//25000 23750 btt
            }else if(i==10 && players[global_pool[_referral]].global_per_level[10]==177147){
                global_pool[_referral].transferToken(28500000000,token);//30000 28500 btt
            }else if(i==11 && players[global_pool[_referral]].global_per_level[11]==531441){
                global_pool[_referral].transferToken(47500000000,token);//50000 47500 btt
            }
            if(players[global_pool[_referral]].global==_referral) break;
            _referral = players[global_pool[_referral]].global;
            
        }
            
    }
    function autoSpeedUpgrade() public payable {
        require(msg.tokenvalue == invest_amount,"Invalid Investment Amount"); 
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
                
                if(i==0 && players[_referral].referrals_per_level[0]==2  && players[_referral].income_per_level[0]==0){
                    players[_referral].income_per_level[2] = 500;
                    _referral.transferToken(475000000,token);//500 475 btt
                }
                if(i==2 && players[_referral].referrals_per_level[2]==8  && players[_referral].income_per_level[2]==0){
                    players[_referral].income_per_level[2] = 1000;
                    _referral.transferToken(950000000,token);//1000 950 btt
                }
                if(i==5 && players[_referral].referrals_per_level[5]==64  && players[_referral].income_per_level[5]==0){
                    players[_referral].income_per_level[5] = 6500; 
                   _referral.transferToken(6175000000,token);//6500 6175 btt
                }
                if(i==9 &&  players[_referral].referrals_per_level[9]==1024  && players[_referral].income_per_level[9]==0){
                    players[_referral].income_per_level[9] = 21000;
                    _referral.transferToken(19950000000,token);//21000 19950 btt
                }
                if(i==14 && players[_referral].referrals_per_level[14]==32768  && players[_referral].income_per_level[14]==0){
                    players[_referral].income_per_level[14] = 31000;
                   _referral.transferToken(29450000000,token);//31000 29450 btt
                }
                
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function tokenInfo() public payable returns(trcToken, uint256){
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }
    
    function transferTokenOwnership(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transferToken(_amount,token);
    }
    
    function setGlobalInvest(uint _amount) external onlyAdmin{
        invest_amount = _amount;
    }
    
    function globalInfo() view external returns(address payable [] memory) {
        return global_pool;
    }
    
    function userInfo(address _addr) view external returns(uint256[16] memory global) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            global[i] = player.global_per_level[i];
        }
       
        return (
           global
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