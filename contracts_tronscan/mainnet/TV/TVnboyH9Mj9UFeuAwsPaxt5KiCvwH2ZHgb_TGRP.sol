//SourceUnit: TGRP.sol

pragma solidity ^0.5.9;

contract TGRP {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        address payable direct_addr;
        uint256 directs;
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
   
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances, address payable _sponsor) public payable {
        
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            //require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        Player storage player = players[_sponsor];
        Player storage myself = players[msg.sender];
        player.directs++;
        myself.direct_addr = _sponsor;
        if(player.directs==2){
            pool_array.push(_sponsor);
            emit Pool(_sponsor);
            _setPool(_sponsor);
        }
    }
    
    function _setPool(address _addr) private{
        uint256 pool = (pool_array.length>2)?pool_array.length-2:0;
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
            _setPool(_addr);
        }
        _setReferral(_addr,_referral);
    }
    
    function _setReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            for(uint8 i = 0; i <=15; i++) {
                players[_referral].referrals_per_level[i]++;
                
                if(i==0 && players[_referral].referrals_per_level[0]==2  && players[_referral].income_per_level[0]==0){
                    players[_referral].income_per_level[0] = 40;
                    _referral.transfer(40 trx);
                    if(players[_referral].direct_addr!=address(0)){
                        players[_referral].direct_addr.transfer(10 trx);
                    }
                }
                if(i==2 && players[_referral].referrals_per_level[2]==8  && players[_referral].income_per_level[2]==0){
                    players[_referral].income_per_level[2] = 120;
                    _referral.transfer(120 trx);
                    if(players[_referral].direct_addr!=address(0)){
                        players[_referral].direct_addr.transfer(30 trx);
                    }
                }
                if(i==5 && players[_referral].referrals_per_level[5]==64  && players[_referral].income_per_level[5]==0){
                    players[_referral].income_per_level[5] = 1840;
                    _referral.transfer(1840 trx);
                    if(players[_referral].direct_addr!=address(0)){
                        players[_referral].direct_addr.transfer(460 trx);
                    }
                }
                if(i==9 &&  players[_referral].referrals_per_level[9]==1024  && players[_referral].income_per_level[9]==0){
                    players[_referral].income_per_level[9] = 24000;
                    _referral.transfer(24000 trx);
                    if(players[_referral].direct_addr!=address(0)){
                        players[_referral].direct_addr.transfer(6000 trx);
                    }
                }
                if(i==14 && players[_referral].referrals_per_level[14]==32768  && players[_referral].income_per_level[14]==0){
                    players[_referral].income_per_level[14] = 1075400;
                    _referral.transfer(1075400 trx);
                    if(players[_referral].direct_addr!=address(0)){
                        players[_referral].direct_addr.transfer(268800 trx);
                    }
                }
                
                _referral = players[_referral].referral;
                
                if(_referral == address(0) && _referral == players[_referral].referral) break;
                
            }
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
    
    function userInfo(address _addr) view external returns( uint256[16] memory referrals, uint256[16] memory income) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            referrals[i] = player.referrals_per_level[i];
            income[i] = player.income_per_level[i];
        }
       
        return (
           referrals,
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