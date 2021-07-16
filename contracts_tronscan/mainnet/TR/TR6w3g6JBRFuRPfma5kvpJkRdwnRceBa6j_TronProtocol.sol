//SourceUnit: TronProtocol.sol

pragma solidity  ^0.5.9 <0.6.10;

contract TronProtocol {
    
    event MultiSend(uint256 value , address indexed sender);
    event Pool100(address addr);
    
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
    }
    
    address payable admin;
    uint256 deposit_amount;
    uint256 global_amount;
    address payable [] pool_100;
    
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function setDepositAmount(uint256  _amount) external onlyAdmin{
        deposit_amount = _amount;
    }
    
    function setGlobalAmount(uint256  _amount) external onlyAdmin{
        global_amount = _amount;
    }
    
    function minDeposit() public view returns(uint256 amount){
       return deposit_amount;
    }
    
    function minGlobal() public view returns(uint256 amount){
       return global_amount;
    }
    
    constructor() public {
        admin = msg.sender;
        pool_100.push(msg.sender);
        deposit_amount = 190000000;
        global_amount = 200000000;
    }
    
    function deposit(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.value >= deposit_amount, "Invalid Amount");
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
        pool_100.push(msg.sender);
        emit Pool100(msg.sender);
        _setPool100(msg.sender,pool_100.length);
    }
    
    function globalDeposit(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.value >= global_amount, "Invalid Amount");
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
    }
    
    function _setPool100(address _addr,uint256 poollength) private{
        uint256 pool = poollength-2;
        address payable _ref;
        address payable _referral;
        if(pool<=0){
            _ref = pool_100[0]; 
        }else{
            uint256 last_pool = uint(pool)/2;
            _ref = pool_100[last_pool];
        }
        if(players[_ref].referrals_per_level[0]<2){
            _referral = _ref;
        }
        else{
            _setPool100(_addr,poollength);
        }
        _setReferral100(_addr,_referral);
    }
    
    function _setReferral100(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            uint256 j = 1;
            for(uint8 i = 0; i<10; i++) {
                j = j*2;
                players[_referral].referrals_per_level[i]++; 
                
                if(players[_referral].referrals_per_level[i]==j && players[_referral].income_per_level[i]==0){
                    players[_referral].income_per_level[i] = 90;
                    _referral.transfer(90 trx);
                }
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function pooler(address payable _users) external payable onlyAdmin{
        
        pool_100.push(_users);
        emit Pool100(_users);
        _setPooler(_users,pool_100.length);
        
    }
    
    function _setPooler(address _addr,uint256 poollength) private{
        uint256 pool = (poollength>2)?poollength-2:0;
        address payable _ref;
        address payable _referral;
        if(pool<=0){
            _ref = pool_100[0]; 
        }else{
            uint256 last_pool = uint(pool)/2;
            _ref = pool_100[last_pool];
        }
        if(players[_ref].referrals_per_level[0]<2){
            _referral = _ref;
        }
        else{
            _setPooler(_addr,poollength);
        }
        _setPoolReferral(_addr,_referral);
    }
    
    function _setPoolReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
           
            for(uint8 i = 0; i<=9; i++) {
                players[_referral].referrals_per_level[i]++; 
                _referral = players[_referral].referral;
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function poolInfo() view external returns(address payable [] memory pool100) {
        return (pool_100);
    }
    
    function userInfo(address _addr) view external returns( uint256[10] memory referrals, uint256[10] memory income) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 9; i++) {
            referrals[i] = player.referrals_per_level[i];
            income[i] = player.income_per_level[i];
        }
       
        return (
           referrals,
           income
        );
    }
    
    function transferOwnership(address payable new_owner,uint _amount) external onlyAdmin{
        new_owner.transfer(_amount);
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