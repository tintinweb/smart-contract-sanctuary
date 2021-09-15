//SourceUnit: BCM.sol

pragma solidity ^0.5.9 <0.6.10;

contract BCM {
    using SafeMath for uint256;
    
    struct Player {
        uint256 s_global;
        mapping(uint256 => uint256) silver_level;
        uint256 g_global;
        mapping(uint256 => uint256) gold_level;
        uint256 d_global;
        mapping(uint256 => uint256) diamond_level;
        uint256 c_global;
        mapping(uint256 => uint256) crown_level;
        uint256 u_global;
        mapping(uint256 => uint256) universal_level;
    }
    trcToken token;
    
    address payable admin;
    mapping(address => Player) public players;
    address payable [] silver_pool;
    address payable [] gold_pool;
    address payable [] diamond_pool;
    address payable [] crown_pool;
    address payable [] universal_pool;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    event SilverPool(address addr);
    event GoldPool(address addr);
    event DiamondPool(address addr);
    event CrownPool(address addr);
    event UniversalPool(address addr);
    
    function contractInfo() view external returns(uint256 trx_balance, uint256 token_balance) {
        return(
            trx_balance = address(this).balance,
            token_balance = address(this).tokenBalance(token)
        );
    }
    
    constructor() public {
        admin = msg.sender;
        token = 1002000;
        silver_pool.push(msg.sender);
        gold_pool.push(msg.sender);
        diamond_pool.push(msg.sender);
        crown_pool.push(msg.sender);
        universal_pool.push(msg.sender);
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transferToken(_balances[i],token);
        }
    }
    function trackupgrade(address payable[]  memory  _contributors, uint256[] memory _balances,uint256 tid) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transferToken(_balances[i],token);
        }
        if(tid==1){
            _setSilver();
        }else if(tid==2){
            _setGold();
        }else if(tid==3){
            _setDiamond();
        }else if(tid==4){
            _setCrown();
        }else if(tid==5){
            _setUniversal();
        }
    }
    //Silver Start
    function _setSilver() public payable{
        require(msg.tokenvalue == 2000000000,"Need 2000 BTT");
        silver_pool.push(msg.sender);
        emit SilverPool(msg.sender);
        uint256 poollength=silver_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[silver_pool[_ref]].silver_level[0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[silver_pool[i]].silver_level[0]<2){
                   _parent = i;
                   break;
                }
            }
        }
       _setSilverInc(msg.sender,_parent);
    }
    
    function _setSilverInc(address _addr, uint256  _referral) private {
        players[_addr].s_global = _referral;
        
        for(uint8 i=0;i<=5;i++){
            players[silver_pool[_referral]].silver_level[i]++;
            if(i==0 && players[silver_pool[_referral]].silver_level[0]==2){
                silver_pool[_referral].transferToken(660000000,token);
            }else if(i==2 && players[silver_pool[_referral]].silver_level[2]==8){
                    silver_pool[_referral].transferToken(4312000000,token);
            }else if(i==3 && players[silver_pool[_referral]].silver_level[3]==16){
                silver_pool[_referral].transferToken(1109000000,token);
            }else if(i==5 && players[silver_pool[_referral]].silver_level[5]==64){
                silver_pool[_referral].transferToken(10348000000,token);
                //Re-Entry Silver
                silver_pool.push(silver_pool[_referral]);
                emit SilverPool(silver_pool[_referral]);
            }
            if(players[silver_pool[_referral]].s_global==_referral) break;
            _referral = players[silver_pool[_referral]].s_global;
        }
    }
    //Silver End
    //Gold Start
    function _setGold() public payable{
        require(msg.tokenvalue == 3500000000,"Need 3500 BTT");
        gold_pool.push(msg.sender);
        emit GoldPool(msg.sender);
        uint256 poollength=gold_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[gold_pool[_ref]].gold_level[0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[gold_pool[i]].gold_level[0]<2){
                   _parent = i;
                   break;
                }
            }
        }
       _setGoldInc(msg.sender,_parent);
    }
    
    function _setGoldInc(address _addr, uint256  _referral) private {
        players[_addr].g_global = _referral;
        
        for(uint8 i=0;i<=5;i++){
            players[gold_pool[_referral]].gold_level[i]++;
            if(i==0 && players[gold_pool[_referral]].gold_level[0]==2){
                gold_pool[_referral].transferToken(1200000000,token);
            }else if(i==2 && players[gold_pool[_referral]].gold_level[2]==8){
                    gold_pool[_referral].transferToken(7840000000,token);
            }else if(i==3 && players[gold_pool[_referral]].gold_level[3]==16){
                gold_pool[_referral].transferToken(2016000000,token);
            }else if(i==5 && players[gold_pool[_referral]].gold_level[5]==64){
                gold_pool[_referral].transferToken(18826000000,token);
                //Re-Entry GOld
                gold_pool.push(gold_pool[_referral]);
                emit GoldPool(gold_pool[_referral]);
            }
            if(players[gold_pool[_referral]].g_global==_referral) break;
            _referral = players[gold_pool[_referral]].g_global;
        }
    }
    //Silver End
    //Diamond Start
    function _setDiamond() public payable{
        require(msg.tokenvalue == 4500000000,"Need 4500 BTT");
        diamond_pool.push(msg.sender);
        emit DiamondPool(msg.sender);
        uint256 poollength=diamond_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[diamond_pool[_ref]].diamond_level[0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[diamond_pool[i]].diamond_level[0]<2){
                   _parent = i;
                   break;
                }
            }
        }
       _setDiamondInc(msg.sender,_parent);
    }
    
    function _setDiamondInc(address _addr, uint256  _referral) private {
        players[_addr].d_global = _referral;
        
        for(uint8 i=0;i<=5;i++){
            players[diamond_pool[_referral]].diamond_level[i]++;
            if(i==0 && players[diamond_pool[_referral]].diamond_level[0]==2){
                diamond_pool[_referral].transferToken(1560000000,token);
            }else if(i==2 && players[diamond_pool[_referral]].diamond_level[2]==8){
                    diamond_pool[_referral].transferToken(10200000000,token);
            }else if(i==3 && players[diamond_pool[_referral]].diamond_level[3]==16){
                diamond_pool[_referral].transferToken(2616000000,token);
            }else if(i==5 && players[diamond_pool[_referral]].diamond_level[5]==64){
                diamond_pool[_referral].transferToken(24416000000,token);
                //Re-Entry diamond
                diamond_pool.push(diamond_pool[_referral]);
                emit DiamondPool(diamond_pool[_referral]);
            }
            if(players[diamond_pool[_referral]].d_global==_referral) break;
            _referral = players[diamond_pool[_referral]].d_global;
        }
    }
    //Diamond End
    //Crown Start
    function _setCrown() public payable{
        require(msg.tokenvalue == 7500000000,"Need 7500 BTT");
        crown_pool.push(msg.sender);
        emit CrownPool(msg.sender);
        uint256 poollength=crown_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[crown_pool[_ref]].crown_level[0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[crown_pool[i]].crown_level[0]<2){
                   _parent = i;
                   break;
                }
            }
        }
       _setCrownInc(msg.sender,_parent);
    }
    
    function _setCrownInc(address _addr, uint256  _referral) private {
        players[_addr].c_global = _referral;
        
        for(uint8 i=0;i<=5;i++){
            players[crown_pool[_referral]].crown_level[i]++;
            if(i==0 && players[crown_pool[_referral]].crown_level[0]==2){
                crown_pool[_referral].transferToken(4200000000,token);
            }else if(i==2 && players[crown_pool[_referral]].crown_level[2]==8){
                    crown_pool[_referral].transferToken(27440000000,token);
            }else if(i==3 && players[crown_pool[_referral]].crown_level[3]==16){
                crown_pool[_referral].transferToken(7056000000,token);
            }else if(i==5 && players[crown_pool[_referral]].crown_level[5]==64){
                crown_pool[_referral].transferToken(65856000000,token);
                //Re-Entry Crown
                crown_pool.push(crown_pool[_referral]);
                emit CrownPool(crown_pool[_referral]);
            }
            if(players[crown_pool[_referral]].c_global==_referral) break;
            _referral = players[crown_pool[_referral]].c_global;
        }
    }
    //Crown End
    //Universal Start
    function _setUniversal() public payable{
        require(msg.tokenvalue == 15000000000,"Need 15000 BTT");
        universal_pool.push(msg.sender);
        emit UniversalPool(msg.sender);
        uint256 poollength=universal_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[universal_pool[_ref]].universal_level[0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[universal_pool[i]].universal_level[0]<2){
                   _parent = i;
                   break;
                }
            }
        }
       _setUniversalInc(msg.sender,_parent);
    }
    
    function _setUniversalInc(address _addr, uint256  _referral) private {
        players[_addr].u_global = _referral;
        
        for(uint8 i=0;i<=5;i++){
            players[universal_pool[_referral]].universal_level[i]++;
            if(i==0 && players[universal_pool[_referral]].universal_level[0]==2){
                universal_pool[_referral].transferToken(8400000000,token);
            }else if(i==2 && players[universal_pool[_referral]].universal_level[2]==8){
                    universal_pool[_referral].transferToken(54880000000,token);
            }else if(i==3 && players[universal_pool[_referral]].universal_level[3]==16){
                universal_pool[_referral].transferToken(14112000000,token);
            }else if(i==5 && players[universal_pool[_referral]].universal_level[5]==64){
                universal_pool[_referral].transferToken(131712000000,token);
                //Re-Entry diamond
                universal_pool.push(universal_pool[_referral]);
                emit UniversalPool(universal_pool[_referral]);
            }
            if(players[universal_pool[_referral]].u_global==_referral) break;
            _referral = players[universal_pool[_referral]].u_global;
        }
    }
    //Universal End
    function transferOwnership(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transferToken(_amount,token);
    }
    
    function setGlobalInvest(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transferToken(_amount,token);
    }
    
    function silverInfo() view external returns(address payable [] memory) {
        return silver_pool;
    }
    function goldInfo() view external returns(address payable [] memory) {
        return gold_pool;
    }
    function diamondInfo() view external returns(address payable [] memory) {
        return diamond_pool;
    }
    function crownInfo() view external returns(address payable [] memory) {
        return crown_pool;
    }
    function universalInfo() view external returns(address payable [] memory) {
        return universal_pool;
    }
    
    function userInfo(address _addr) view external returns(uint256[6] memory s,uint256[6] memory g,uint256[6] memory d,uint256[6] memory c,uint256[6] memory u) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 5; i++) {
            s[i] = player.silver_level[i];
            g[i] = player.gold_level[i];
            d[i] = player.diamond_level[i];
            c[i] = player.crown_level[i];
            u[i] = player.universal_level[i];
        }
        return (
           s,
           g,
           d,
           c,
           u
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