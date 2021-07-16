//SourceUnit: TronRing.sol

pragma solidity  ^0.5.9;

contract TronRing {
    
    event MultiSend(uint256 value , address indexed sender);
    event Pool500(address addr);
    event Pool1000(address addr);
    
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
        
        address payable referral1000;
        mapping(uint8 => uint256) referrals1000_per_level;
        mapping(uint8 => uint256) income1000_per_level;
    }
    
    address payable admin;
    
    address payable [] pool_500;
    address payable [] pool_1000;
    
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
        pool_500.push(msg.sender);
        pool_1000.push(msg.sender);
    }
    
    function invest500(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
        pool_500.push(msg.sender);
        emit Pool500(msg.sender);
        _setPool500(msg.sender,pool_500.length);
    }
    
    function invest1000(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
        pool_1000.push(msg.sender);
        emit Pool1000(msg.sender);
        _setPool1000(msg.sender,pool_1000.length);
    }
    
    function _setPool500(address _addr,uint256 poollength) private{
        uint256 pool = poollength-2;
        address payable _ref;
        address payable _referral;
        if(pool<=0){
            _ref = pool_500[0]; 
        }else{
            uint256 last_pool = uint(pool)/2;
            _ref = pool_500[last_pool];
        }
        if(players[_ref].referrals_per_level[0]<2){
            _referral = _ref;
        }
        else{
            _setPool500(_addr,poollength);
        }
        _setReferral500(_addr,_referral);
    }
    
    function _setPool1000(address _addr,uint256 poollength) private{
        uint256 pool = poollength-2;
        address payable _ref;
        address payable _referral;
        if(pool<=0){
            _ref = pool_1000[0]; 
        }else{
            uint256 last_pool = uint(pool)/2;
            _ref = pool_1000[last_pool];
        }
        if(players[_ref].referrals1000_per_level[0]<2){
            _referral = _ref;
        }
        else{
            _setPool1000(_addr,poollength);
        }
        _setReferral1000(_addr,_referral);
    }
    
    function _setReferral500(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            uint256 j = 1;
            for(uint8 i = 0; i<10; i++) {
                j = j*2;
                players[_referral].referrals_per_level[i]++; 
                
                if(players[_referral].referrals_per_level[i]==j && players[_referral].income_per_level[i]==0){
                    players[_referral].income_per_level[i] = 220;
                    _referral.transfer(220 trx);
                }
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function _setReferral1000(address _addr, address payable  _referral) private {
        if(players[_addr].referral1000 == address(0)) {
            players[_addr].referral1000 = _referral;
            uint256 j = 1;
            for(uint8 i = 0; i<10; i++) {
                j = j*2;
                players[_referral].referrals1000_per_level[i]++; 
                
                if(players[_referral].referrals1000_per_level[i]==j && players[_referral].income1000_per_level[i]==0){
                    players[_referral].income1000_per_level[i] = 570;
                    _referral.transfer(570 trx);
                }
                _referral = players[_referral].referral1000;
                
                if(_referral == address(0) && _referral == players[_referral].referral1000) break;
                
            }
        }
    }
    
    function poolInfo() view external returns(address payable [] memory pool500,address payable [] memory pool1000) {
        return (pool_500, pool_1000);
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