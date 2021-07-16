//SourceUnit: RBRNBTT.sol

pragma solidity ^0.5.9 <0.6.10;

contract RBRNBTT {
    using SafeMath for uint256;
    
    struct Player {
        uint256 global;
        uint256 counter;
        mapping(uint256 => uint256) global_per_level;
    }
    
    trcToken token;
    address payable admin;
    mapping(address => Player) public players;
    address payable [] global_pool;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    uint256 invest_amount;
    event GlobalPool(address addr);
    
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
        invest_amount = 100000000;
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
    
    function multisendTokentoUpgrade(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        uint256 total = msg.tokenvalue;
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transferToken(_balances[i],token);
        }
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
        uint256 index;
        
        players[_addr].global = _referral;
        
        for(uint8 i=0;i<=14;i++){
            players[global_pool[_referral]].global_per_level[i]++;
            if(i==0 && players[global_pool[_referral]].global_per_level[0]==3){
                global_pool[_referral].transferToken(500000000,token);
            }else if(i==2 && players[global_pool[_referral]].global_per_level[2]>=15){
                index = players[global_pool[_referral]].global_per_level[2];
                if(index==15 || index==18 || index==21 || index==24 || index==27){
                    global_pool[_referral].transferToken(1000000000,token);
                }
            }else if(i==5 && players[global_pool[_referral]].global_per_level[5]>=162){
                index = players[global_pool[_referral]].global_per_level[5];
                if(index==162 || index==189 || index==216 || index==243 || index==270 || index==297 || index==324 || index==351 || index==378 || index==405 || index==432 || index==459 || index==486 || index==513 || index==540 || index==567 || index==594 || index==621 || index==648 || index==675 || index==702 || index==729){
                    global_pool[_referral].transferToken(4000000000,token);
                }
            }else if(i==9 && players[global_pool[_referral]].global_per_level[9]>=729){
                index = players[global_pool[_referral]].global_per_level[9];
                if(index%81==0){
                    global_pool[_referral].transferToken(20000000000,token);
                }
                if(index>=59049){
                    //re-entry
                }
            }
            if(players[global_pool[_referral]].global==_referral) break;
            _referral = players[global_pool[_referral]].global;
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
    
    function setInvestment(uint _amount) external onlyAdmin{
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