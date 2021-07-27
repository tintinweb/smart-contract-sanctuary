//SourceUnit: BMW.sol

pragma solidity ^0.5.9 <0.6.10;

contract BMW {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
    }

    address payable admin;
    mapping(address => Player) public players;
    address payable [] pool_array;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    event Pool(address addr);
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        admin = msg.sender;
        pool_array.push(msg.sender);
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
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
                
                if(i==0 && players[_referral].referrals_per_level[0]==2 && players[_referral].income_per_level[0]==0){
                    players[_referral].income_per_level[0] = 1;
                    _referral.transfer(1 trx);
                }
                if(i==2 && players[_referral].referrals_per_level[2]==8 && players[_referral].income_per_level[2]==0){
                    players[_referral].income_per_level[2] = 2;
                    _referral.transfer(2 trx);
                }
                if(i==5 && players[_referral].referrals_per_level[5]==64 && players[_referral].income_per_level[5]==0){
                    players[_referral].income_per_level[5] = 13;
                   _referral.transfer(13 trx);
                }
                if(i==9 &&  players[_referral].referrals_per_level[9]==1024 && players[_referral].income_per_level[9]==0){
                    players[_referral].income_per_level[9] = 40;
                    _referral.transfer(40 trx);
                }
                if(i==14 && players[_referral].referrals_per_level[14]==32768 && players[_referral].income_per_level[14]==0){
                    players[_referral].income_per_level[14] = 240;
                   _referral.transfer(240 trx);
                }
                
                _referral = players[_referral].referral;
                if(_referral == address(0) || _referral == players[_referral].referral) break;
                
            }
        }
    }
    
    function globalInfo() view external returns(address payable [] memory) {
        return pool_array;
    }
    
    function transferOwnership(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transfer(_amount);
    }
    
    function userInfo(address _addr) view external returns(uint256[16] memory incomeperlevel, uint256[16] memory refperlevel) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            incomeperlevel[i] = player.income_per_level[i];
            refperlevel[i] = player.referrals_per_level[i];
        }
        return (
           incomeperlevel,
           refperlevel
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