//SourceUnit: RT200.sol

pragma solidity 0.5.17;

contract RT200 {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable owner;
    
    mapping(address => Player) public players;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 balance) {
        return ( address(this).balance);
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
   
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit(address payable _referral) external payable {
        _setReferral(msg.sender, _referral);
        if(_referral!=address(0x0) && players[_referral].referrals_per_level[0]>1){
            _referralPayout(msg.sender);
        }
        emit Deposit(msg.sender, msg.value);
    }
    
    function _setReferral(address _addr, address payable _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            for(uint8 i = 0; i < 16; i++) {
                players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }
    
    function _referralPayout(address _addr) private {
        address payable ref = players[_addr].referral;
        for(uint8 i = 0; i < 16; i++) {
            if(ref != address(0x0)){
                uint256 bonus = (i==0)?45 trx:9 trx;
                ref.transfer(bonus);
                ref = players[ref].referral;
            }
        }
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }
    
    function referralInfo(address _referral) view external returns(uint256[16] memory referrals) {
        Player storage player = players[_referral];
        for(uint8 i = 0; i < 16; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        return (
            referrals
        );
    }
   
    function airDrop(address payable _dropper, uint _amount) external onlyOwner{
        _dropper.transfer(_amount);
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