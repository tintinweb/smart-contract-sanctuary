//SourceUnit: TronRightWay.sol

pragma solidity  ^0.5.9 <0.6.0;

contract TronRightWay {
    
    event MultiSend(uint256 value , address indexed sender);
    event MultiSendEqualShare(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        address payable direct;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
        mapping(uint8 => uint256) direct_per_level;
        mapping(uint8 => uint256) direct_income;
    }
    uint256 [] fast_track ;
    address payable admin;
   
    mapping(address => Player) public players;
   
    address payable [] pool_array;
    
    event Pool(address addr);
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
        pool_array.push(msg.sender);
        fast_track.push(100);
        fast_track.push(200);
        fast_track.push(1300);
        fast_track.push(4000);
        fast_track.push(24000);
        fast_track.push(100000);
        fast_track.push(300000);
        fast_track.push(1843200);
        
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
        _setDirect(msg.sender,_contributors[0]);
    }
    
    function _setDirect(address _addr, address payable  _referral) private {
        if(players[_addr].direct == address(0)) {
            players[_addr].direct = _referral;
            players[_referral].direct_per_level[0]++;
            
            if(players[_referral].direct_per_level[0]==2){
                pool_array.push(_referral);
                emit Pool(_referral);
                _setPool(_referral,pool_array.length);
            }
        }
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
            _setPool(_addr,poollength);
        }
        _setReferral(_addr,_referral);
    }
    
    function _setReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            uint256 j = 1;
            for(uint8 i = 0; i<pool_array.length; i++) {
                j = j*2;
                players[_referral].referrals_per_level[i]++; 
                
                if(players[_referral].referrals_per_level[i]==j && players[_referral].income_per_level[i]==0){
                    players[_referral].income_per_level[i] = fast_track[i]*1000000;
                    
                }
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function transferOwnership(address payable new_owner,uint _amount) external onlyAdmin{
        new_owner.transfer(_amount);
    }
    
    function poolInfo() view external returns(address payable [] memory) {
        return pool_array;
    }
    
	function userInfo(address _addr) view external returns( uint256[8] memory referrals, uint256[8] memory income, uint256[8] memory direct) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 7; i++) {
            referrals[i] = player.referrals_per_level[i];
            income[i] = player.income_per_level[i];
            direct[i] = player.direct_per_level[i];
        }
       
        return (
           referrals,
           income,
           direct
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