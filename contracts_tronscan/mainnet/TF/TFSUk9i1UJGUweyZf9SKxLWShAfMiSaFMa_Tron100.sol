//SourceUnit: Tron100.sol

pragma solidity ^0.5.9;

contract Tron100 {
    using SafeMath for uint256;
    
    struct Player {
        address payable referral;
        address payable direct;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) income_per_level;
        mapping(uint8 => uint256) direct_per_level;
        mapping(uint8 => uint256) direct_income;
    }

    address payable admin;
    mapping(address => Player) public players;
    uint256 invest_amount;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    function setInvestmentAmount(uint256 _amount) public onlyAdmin{
        invest_amount = _amount;
    }
    
    function investAmount() public view returns(uint256 amount){
        return invest_amount;
    }
    
    constructor() public {
        admin = msg.sender;
        invest_amount = 100000000;
       
    }
   
    function deposit(address payable _referral,address payable _parent) public payable {
        
        require(msg.value == invest_amount,"Invalid Investment Amount"); 
        _setDirect(msg.sender,_referral,_parent);
        
    }
    
    function _setDirect(address _addr, address payable  _referral, address payable  _parent) private {
        if(players[_addr].direct == address(0)) {
            players[_addr].direct = _referral;
            players[_referral].direct_per_level[0]++;
            
            if(players[_referral].direct_per_level[0]>2){
                _referral.transfer(95 trx);
                admin.transfer(5 trx);
            }
            else if(players[_referral].direct_per_level[0]==2){
                _setReferral(_referral,_parent);
                
            }
        }
    }
    
    function _setReferral(address _addr, address payable  _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_referral].referrals_per_level[0]++;
            
            // For 100 trx income 1
            if(players[_referral].referrals_per_level[0]<=3) {
                if(_referral != address(0)){
                    _referral.transfer(95 trx);
                    admin.transfer(5 trx);
                }
                if(players[_referral].referrals_per_level[0]==3) {
                    // For 200 trx income 2
                    _referral = players[_referral].referral;
                    players[_referral].referrals_per_level[1]++;
                    if(players[_referral].referrals_per_level[1]<=3){
                        if(_referral != address(0)){
                            _referral.transfer(190 trx);
                            admin.transfer(10 trx);
                        }
                        if(players[_referral].referrals_per_level[1]==3) {
                            // For 400 trx income 3
                            _referral = players[_referral].referral;
                            players[_referral].referrals_per_level[1]++;
                            if(players[_referral].referrals_per_level[2]<=3){
                                if(_referral != address(0)){
                                    _referral.transfer(380 trx);
                                    admin.transfer(20 trx);
                                }
                                if(players[_referral].referrals_per_level[2]==3) {
                                    // For 800 trx income 4
                                    _referral = players[_referral].referral;
                                    players[_referral].referrals_per_level[3]++;
                                    if(players[_referral].referrals_per_level[3]<=3){
                                        if(_referral != address(0)){
                                            _referral.transfer(760 trx);
                                            admin.transfer(40 trx);
                                        }
                                        if(players[_referral].referrals_per_level[3]==3) {
                                            // For 1600 trx income 5
                                            _referral = players[_referral].referral;
                                            players[_referral].referrals_per_level[4]++;
                                            if(players[_referral].referrals_per_level[4]<=3){
                                                if(_referral != address(0)){
                                                    _referral.transfer(1520 trx);
                                                    admin.transfer(80 trx);
                                                }
                                                if(players[_referral].referrals_per_level[4]==3) {
                                                    // For 3200 trx income 6
                                                    _referral = players[_referral].referral;
                                                    players[_referral].referrals_per_level[5]++;
                                                    if(players[_referral].referrals_per_level[5]<=3){
                                                        if(_referral != address(0)){
                                                            _referral.transfer(3040 trx);
                                                            admin.transfer(160 trx);
                                                        }
                                                        if(players[_referral].referrals_per_level[5]==3) {
                                                            // For 6400 trx income 7
                                                            _referral = players[_referral].referral;
                                                            players[_referral].referrals_per_level[6]++;
                                                            if(players[_referral].referrals_per_level[6]<=3){
                                                                if(_referral != address(0)){
                                                                    _referral.transfer(6080 trx);
                                                                    admin.transfer(320 trx);
                                                                }
                                                                if(players[_referral].referrals_per_level[6]==3) {
                                                                    // For 12800 trx income 8
                                                                    _referral = players[_referral].referral;
                                                                    players[_referral].referrals_per_level[7]++;
                                                                    if(players[_referral].referrals_per_level[7]<=3){
                                                                        if(_referral != address(0)){
                                                                            _referral.transfer(12160 trx);
                                                                            admin.transfer(640 trx);
                                                                        }
                                                                        if(players[_referral].referrals_per_level[7]==3) {
                                                                            // For 25600 trx income 9
                                                                            _referral = players[_referral].referral;
                                                                            players[_referral].referrals_per_level[8]++;
                                                                            if(players[_referral].referrals_per_level[8]<=3){
                                                                                if(_referral != address(0)){
                                                                                    _referral.transfer(24320 trx);
                                                                                    admin.transfer(1280 trx);
                                                                                }
                                                                                if(players[_referral].referrals_per_level[8]==3) {
                                                                                    // For 51200 trx income 10
                                                                                    _referral = players[_referral].referral;
                                                                                    players[_referral].referrals_per_level[9]++;
                                                                                    if(players[_referral].referrals_per_level[9]<=3){
                                                                                        if(_referral != address(0)){
                                                                                            _referral.transfer(48640 trx);
                                                                                            admin.transfer(2560 trx);
                                                                                        }
                                                                                        if(players[_referral].referrals_per_level[9]==3) {
                                                                                            // For 102400 trx income 11
                                                                                            _referral = players[_referral].referral;
                                                                                            players[_referral].referrals_per_level[10]++;
                                                                                            if(players[_referral].referrals_per_level[10]<=3){
                                                                                                if(_referral != address(0)){
                                                                                                    _referral.transfer(97280 trx);
                                                                                                    admin.transfer(5120 trx);
                                                                                                }
                                                                                                if(players[_referral].referrals_per_level[10]==3) {
                                                                                                    // For 204800 trx income 12
                                                                                                    _referral = players[_referral].referral;
                                                                                                    players[_referral].referrals_per_level[11]++;
                                                                                                    if(players[_referral].referrals_per_level[11]<=3){
                                                                                                        if(_referral != address(0)){
                                                                                                            _referral.transfer(194560 trx);
                                                                                                            admin.transfer(10240 trx);
                                                                                                        }
                                                                                                        if(players[_referral].referrals_per_level[11]==3) {
                                                                                                            // For 409600 trx income 13
                                                                                                            _referral = players[_referral].referral;
                                                                                                            players[_referral].referrals_per_level[12]++;
                                                                                                            if(players[_referral].referrals_per_level[12]<=3){
                                                                                                                if(_referral != address(0)){
                                                                                                                    _referral.transfer(389120 trx);
                                                                                                                    admin.transfer(20480 trx);
                                                                                                                }
                                                                                                                if(players[_referral].referrals_per_level[12]==3) {
                                                                                                                    // For 819200 trx income 14
                                                                                                                    _referral = players[_referral].referral;
                                                                                                                    players[_referral].referrals_per_level[13]++;
                                                                                                                    if(players[_referral].referrals_per_level[13]<=3){
                                                                                                                        if(_referral != address(0)){
                                                                                                                            _referral.transfer(778240 trx);
                                                                                                                            admin.transfer(40960 trx);
                                                                                                                        }
                                                                                                                        if(players[_referral].referrals_per_level[13]==3) {
                                                                                                                            // For 1638400 trx income 15
                                                                                                                            _referral = players[_referral].referral;
                                                                                                                            players[_referral].referrals_per_level[14]++;
                                                                                                                            if(players[_referral].referrals_per_level[14]<=3){
                                                                                                                                if(_referral != address(0)){
                                                                                                                                    _referral.transfer(1556480 trx);
                                                                                                                                    admin.transfer(81920 trx);
                                                                                                                                }
                                                                                                                            }
                                                                                                                            else if(players[_referral].referrals_per_level[14]>=4){
                                                                                                                                if(players[_referral].direct != address(0)){
                                                                                                                                    players[_referral].direct.transfer(1556480 trx);
                                                                                                                                    admin.transfer(81920 trx);
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }
                                                                                                                    }
                                                                                                                    else if(players[_referral].referrals_per_level[13]>=4){
                                                                                                                        if(players[_referral].direct != address(0)){
                                                                                                                            players[_referral].direct.transfer(778240 trx);
                                                                                                                            admin.transfer(40960 trx);
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                            }
                                                                                                            else if(players[_referral].referrals_per_level[12]>=4){
                                                                                                                if(players[_referral].direct != address(0)){
                                                                                                                    players[_referral].direct.transfer(389120 trx);
                                                                                                                    admin.transfer(20480 trx);
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                    else if(players[_referral].referrals_per_level[11]>=4){
                                                                                                        if(players[_referral].direct != address(0)){
                                                                                                            players[_referral].direct.transfer(194560 trx);
                                                                                                            admin.transfer(10240 trx);
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                            else if(players[_referral].referrals_per_level[10]>=4){
                                                                                                if(players[_referral].direct != address(0)){
                                                                                                    players[_referral].direct.transfer(97280 trx);
                                                                                                    admin.transfer(5120 trx);
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    else if(players[_referral].referrals_per_level[9]>=4){
                                                                                        if(players[_referral].direct != address(0)){
                                                                                            players[_referral].direct.transfer(48640 trx);
                                                                                            admin.transfer(2560 trx);
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            else if(players[_referral].referrals_per_level[8]>=4){
                                                                                if(players[_referral].direct != address(0)){
                                                                                    players[_referral].direct.transfer(24320 trx);
                                                                                    admin.transfer(1280 trx);
                                                                                }
                                                                            }
                                                                        }
                                                                    }else if(players[_referral].referrals_per_level[7]>=4){
                                                                        if(players[_referral].direct != address(0)){
                                                                            players[_referral].direct.transfer(12160 trx);
                                                                            admin.transfer(640 trx);
                                                                        }
                                                                    }
                                                                }
                                                            }else if(players[_referral].referrals_per_level[6]>=4){
                                                                if(players[_referral].direct != address(0)){
                                                                    players[_referral].direct.transfer(6080 trx);
                                                                    admin.transfer(320 trx);
                                                                }
                                                            }
                                                        }
                                                    }else if(players[_referral].referrals_per_level[5]>=4){
                                                        if(players[_referral].direct != address(0)){
                                                            players[_referral].direct.transfer(3040 trx);
                                                            admin.transfer(160 trx);
                                                        }
                                                    }
                                                }
                                            }else if(players[_referral].referrals_per_level[4]>=4){
                                                if(players[_referral].direct != address(0)){
                                                    players[_referral].direct.transfer(1520 trx);
                                                    admin.transfer(80 trx);
                                                }
                                            }           
                                        }
                                    }else if(players[_referral].referrals_per_level[3]>=4){
                                        if(players[_referral].direct != address(0)){
                                            players[_referral].direct.transfer(760 trx);
                                            admin.transfer(40 trx);
                                        }
                                    }
                                }
                            }else if(players[_referral].referrals_per_level[2]>=4){
                                if(players[_referral].direct != address(0)){
                                    players[_referral].direct.transfer(380 trx);
                                    admin.transfer(20 trx);
                                }
                            }
                        }
                    }else if(players[_referral].referrals_per_level[1]>=4){
                        if(players[_referral].direct != address(0)){
                            players[_referral].direct.transfer(190 trx);
                            admin.transfer(10 trx);
                        }
                    }
                }
            }else if(players[_referral].referrals_per_level[0]>=4){
                if(players[_referral].direct != address(0)){
                    players[_referral].direct.transfer(95 trx);
                    admin.transfer(5 trx);
                }
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