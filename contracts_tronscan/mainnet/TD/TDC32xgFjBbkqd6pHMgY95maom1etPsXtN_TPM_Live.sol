//SourceUnit: TPM_Live.sol

pragma solidity ^0.5.9;

contract TPM_Live {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
    }

    address payable admin;
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        admin = msg.sender;
    }
   
    function multisendTRX(address payable _referral, address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            //require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        
        _setReferral(msg.sender,_referral);
        
    }
    
    function _setReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;

            for(uint8 i = 0; i <=15; i++) {
                players[_referral].referrals_per_level[i]++;
                
                if(i==0 && players[_referral].referrals_per_level[0]==2  && players[_referral].income_per_level[0]==0){
                    players[_referral].income_per_level[0] = 100;
                    _referral.transfer(100 trx);
                }
                if(i==2 && players[_referral].referrals_per_level[2]==8  && players[_referral].income_per_level[2]==0){
                    players[_referral].income_per_level[2] = 400;
                    _referral.transfer(400 trx);
                }
                if(i==5 && players[_referral].referrals_per_level[5]==64  && players[_referral].income_per_level[5]==0){
                    players[_referral].income_per_level[5] = 3000;
                   _referral.transfer(3000 trx);
                }
                if(i==9 &&  players[_referral].referrals_per_level[9]==1024  && players[_referral].income_per_level[9]==0){
                    players[_referral].income_per_level[9] = 14400;
                    _referral.transfer(14400 trx);
                }
                if(i==14 && players[_referral].referrals_per_level[14]==32768  && players[_referral].income_per_level[14]==0){
                    players[_referral].income_per_level[14] = 1280000;
                   _referral.transfer(1280000 trx);
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