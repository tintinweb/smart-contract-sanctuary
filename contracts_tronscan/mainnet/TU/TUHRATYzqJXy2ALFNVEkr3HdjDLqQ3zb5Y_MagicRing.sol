//SourceUnit: MagicRing.sol


pragma solidity  ^0.5.9 <0.6.10;

contract MagicRing {
    
    event MultiSend(uint256 value , address indexed sender);
    event Pool100(address addr);
    event Pool200(address addr);
    event Pool500(address addr);
    
    
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
        
        address payable referral200;
        mapping(uint8 => uint256) referrals200_per_level;
        mapping(uint8 => uint256) income200_per_level;
        
        address payable referral500;
        mapping(uint8 => uint256) referrals500_per_level;
        mapping(uint8 => uint256) income500_per_level;
    }
    
    address payable admin;
    
    address payable [] pool_100;
    address payable [] pool_200;
    address payable [] pool_500;
    
    
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
        pool_100.push(msg.sender);
        pool_200.push(msg.sender);
        pool_500.push(msg.sender);
       
    }
    
    function invest100() public payable {
        emit MultiSend(msg.value, msg.sender);
        pool_100.push(msg.sender);
        emit Pool100(msg.sender);
        _setPool100(msg.sender,pool_100.length);
    }
    
    function invest200() public payable {
        
        emit MultiSend(msg.value, msg.sender);
        pool_200.push(msg.sender);
        emit Pool200(msg.sender);
        _setPool200(msg.sender,pool_200.length);
    }
    
    function invest500() public payable {
        emit MultiSend(msg.value, msg.sender);
        pool_500.push(msg.sender);
        emit Pool500(msg.sender);
        _setPool500(msg.sender,pool_500.length);
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
    
    function _setPool200(address _addr,uint256 poollength) private{
        uint256 pool = poollength-2;
        address payable _ref;
        address payable _referral;
        if(pool<=0){
            _ref = pool_200[0]; 
        }else{
            uint256 last_pool = uint(pool)/2;
            _ref = pool_200[last_pool];
        }
        if(players[_ref].referrals200_per_level[0]<2){
            _referral = _ref;
        }
        else{
            _setPool200(_addr,poollength);
        }
        _setReferral200(_addr,_referral);
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
        if(players[_ref].referrals500_per_level[0]<2){
            _referral = _ref;
        }
        else{
            _setPool500(_addr,poollength);
        }
        _setReferral500(_addr,_referral);
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
                    admin.transfer(10 trx);
                }
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function _setReferral200(address _addr, address payable  _referral) private {
        if(players[_addr].referral200 == address(0)) {
            players[_addr].referral200 = _referral;
            uint256 j = 1;
            for(uint8 i = 0; i<10; i++) {
                j = j*2;
                players[_referral].referrals200_per_level[i]++; 
                
                if(players[_referral].referrals200_per_level[i]==j && players[_referral].income200_per_level[i]==0){
                    players[_referral].income200_per_level[i] = 180;
                    _referral.transfer(180 trx);
                    admin.transfer(20 trx);
                }
                _referral = players[_referral].referral200;
                
                if(_referral == address(0) && _referral == players[_referral].referral200) break;
                
            }
        }
    }
    
    function _setReferral500(address _addr, address payable  _referral) private {
        if(players[_addr].referral500 == address(0)) {
            players[_addr].referral500 = _referral;
            uint256 j = 1;
            for(uint8 i = 0; i<10; i++) {
                j = j*2;
                players[_referral].referrals500_per_level[i]++; 
                
                if(players[_referral].referrals500_per_level[i]==j && players[_referral].income500_per_level[i]==0){
                    players[_referral].income500_per_level[i] = 450;
                    _referral.transfer(450 trx);
                    admin.transfer(50 trx);
                    
                }
                _referral = players[_referral].referral500;
                
                if(_referral == address(0) && _referral == players[_referral].referral500) break;
                
            }
        }
    }
    
    function poolInfo100() view external returns(address payable [] memory pool100) {
        return (pool_100);
    }
    
    function poolInfo200() view external returns(address payable [] memory pool200) {
        return (pool_200);
    }
    
    function poolInfo500() view external returns(address payable [] memory pool300) {
        return (pool_500);
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