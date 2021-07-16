//SourceUnit: tboxLP.sol

pragma solidity 0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

contract TBoxLP {

    IERC20 public _tbox = IERC20(0xB1Beec2B96c420B9507745a2D3ED912B9258aEC8);

    uint256 public startTime = block.timestamp;
    uint8[] private year_bonus;
    uint8[] private ref_bonus;

    uint256 private total_deposited;
    uint256 private total_withdraw;

    struct User {
        uint256 id;
        uint256 level;
        address upline;

        uint256 matchBonus;

        uint256 validFlag;
        uint256[]  depositTimes;
        uint256[] depositAmounts;

        uint256 totalPayouts;

        uint256 total_downline_num;
        uint256 total_downline_deposit;
    }

    mapping(address => User) private users;
    mapping(uint => address) public id2Address;
    uint256 private lastUserId = 2;
    
    using SafeMath for uint256;

    constructor(address addr) public {
        year_bonus.push(17);
        year_bonus.push(14);
        year_bonus.push(10);
       
        ref_bonus.push(30);
       
        ref_bonus.push(10);
       
        ref_bonus.push(7);
        ref_bonus.push(7);
        ref_bonus.push(7);
        
        ref_bonus.push(5);
        ref_bonus.push(5);
        ref_bonus.push(5);
        ref_bonus.push(5);
        ref_bonus.push(5);
      
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);
        ref_bonus.push(3);

        User memory user = User({
            id: 1,
            level: 0,
            upline: address(0),
            matchBonus: 0,
            
            validFlag: 0,
            depositTimes: new uint256[](0),
            depositAmounts: new uint256[](0),
            totalPayouts: 0,

            total_downline_num: 0,
            total_downline_deposit: 0
        });

        users[addr] = user;
        id2Address[1] = addr;
    }

    function Deposit(address referrerAddress, uint256 value) external {
        if (!isUserExists(msg.sender)) {
            require(isUserExists(referrerAddress), "referrer not exists");
            _register(referrerAddress);
        }
        require (value % 100*10**6 == 0 && value >= 100*10**6);
        _deposit(value);
    }

    function _register(address referrer) private {
        User memory user = User({
            id: lastUserId,
            level: 0,
            upline: referrer,
            matchBonus: 0,
            
            validFlag: 0,
            depositTimes: new uint256[](0),
            depositAmounts: new uint256[](0),
            totalPayouts: 0,

            total_downline_num: 0,
            total_downline_deposit: 0
        });

        users[msg.sender] = user;
        id2Address[lastUserId] = msg.sender;  
        lastUserId++;

        for(uint8 i = 1; i < 21; i++) {
            if(referrer == address(0)) break;
            users[referrer].total_downline_num++;
            referrer = users[referrer].upline;
        }
    }
    
    function _deposit(uint256 value) private {
        users[msg.sender].level = users[msg.sender].level.add(value.div(100000000));
        users[msg.sender].depositTimes.push(block.timestamp);
        users[msg.sender].depositAmounts.push(value);
        _tbox.transferFrom(msg.sender, address(this), value);
        total_deposited += value;

        _downLineDeposits(msg.sender, value);
    }

    function _downLineDeposits(address _addr, uint256 _amount) private {
      address _upline = users[_addr].upline;
      for(uint8 i = 0; i < 20; i++) {
          if(_upline == address(0)) break;

          users[_upline].total_downline_deposit = users[_upline].total_downline_deposit.add(_amount);
          _upline = users[_upline].upline;
      }
    }

    function Redeem() external {      
        uint256 payouts = 0;
        uint256 depositAmount = 0;
        for(uint256 i = users[msg.sender].validFlag; i < users[msg.sender].depositTimes.length; i++) {
            uint256 payout = _calPayout(msg.sender, i);
            users[msg.sender].depositTimes[i] = block.timestamp;
            payouts += payout;
            depositAmount += users[msg.sender].depositAmounts[i];
        }
        _refPayout(msg.sender, payouts);
        _downLineRedeem(msg.sender, depositAmount);

        users[msg.sender].validFlag = users[msg.sender].depositTimes.length;
        users[msg.sender].level = users[msg.sender].level.sub(depositAmount.div(100000000));

        payouts += users[msg.sender].matchBonus;
        users[msg.sender].totalPayouts += payouts;

        total_withdraw += payouts;
        total_deposited -= depositAmount;

        payouts += depositAmount;
        users[msg.sender].matchBonus = 0; 
        _tbox.transfer(msg.sender, payouts);
    }

    function _downLineRedeem(address _addr, uint256 _amount) private {
      address _upline = users[_addr].upline;
      for(uint8 i = 0; i < 20; i++) {
          if(_upline == address(0)) break;

          users[_upline].total_downline_deposit = users[_upline].total_downline_deposit.sub(_amount);
          _upline = users[_upline].upline;
      }
    }

    function _calPayout(address addr, uint256 idx) private view returns(uint256 payout) {

        uint256 idxDepositAmount = users[addr].depositAmounts[idx];
        uint256 idxDepositTime = users[addr].depositTimes[idx];

        if (block.timestamp < startTime + 365 days) {
            payout = idxDepositAmount * ((block.timestamp - idxDepositTime) / 1 days) * 17 / 10000;
        }else if (block.timestamp < startTime + 730 days){
            
            if (idxDepositTime < startTime + 365 days) {
                payout = idxDepositAmount * ((startTime + 365 days - idxDepositTime) / 1 days) * 17 / 10000;
                payout += idxDepositAmount * ((block.timestamp - startTime - 365 days) / 1 days) * 14 / 10000;
            } else {
                payout = idxDepositAmount * ((block.timestamp - idxDepositTime) / 1 days) * 14 / 10000;
            }

        }else{

            if (idxDepositTime < startTime + 365 days) {
                payout = idxDepositAmount * ((startTime + 365 days - idxDepositTime) / 1 days) * 17 / 10000;
                payout += idxDepositAmount * 365 * 14 / 10000;
                payout += idxDepositAmount * ((block.timestamp - startTime - 730 days) / 1 days) * 10 / 10000;

            } else if (idxDepositTime < startTime + 730 days){
                payout = idxDepositAmount * ((startTime + 730 days - idxDepositTime) / 1 days) * 14 / 10000;
                payout += idxDepositAmount * ((block.timestamp - startTime - 730 days) / 1 days) * 10 / 10000;
            } else {
                payout = idxDepositAmount * ((block.timestamp - idxDepositTime) / 1 days) * 10 / 10000;
            }

        }
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < 21; i++) {

            if(up == address(0)) break;

            if(users[up].level >= i+1) {
                uint256 bonus = _amount * ref_bonus[i] / 100;
                users[up].matchBonus += bonus;
            }

            up = users[up].upline;
        }
    }

    function withdraw() external {
        uint256 payouts = 0;
        for(uint256 i = users[msg.sender].validFlag; i < users[msg.sender].depositTimes.length; i++) {
            uint256 payout = _calPayout(msg.sender, i);
            users[msg.sender].depositTimes[i] = block.timestamp;
            payouts += payout;
        }
        _refPayout(msg.sender, payouts);

        payouts += users[msg.sender].matchBonus;
        users[msg.sender].totalPayouts += payouts;
        users[msg.sender].matchBonus = 0;
        _tbox.transfer(msg.sender, payouts);
        total_withdraw += payouts;
    }
    
    function isUserExists(address _addr) public view returns (bool) {
        return (users[_addr].id != 0);
    }

    function userInfo(address _addr) view external returns(uint256 id, uint256 level, address upline, uint256 matchBonus, uint256 totalPayouts, uint256 totalDownlineNum, uint256 totalDownlineDeposit) {
        return (users[_addr].id, users[_addr].level, users[_addr].upline, users[_addr].matchBonus, users[_addr].totalPayouts, users[_addr].total_downline_num, users[_addr].total_downline_deposit);
    }

    function userBonusInfo(address _addr) public view returns (uint256 deposit, uint256 dayBonus, uint256 payouts) {
        for(uint256 i = users[_addr].validFlag; i < users[_addr].depositTimes.length; i++) {
            deposit += users[_addr].depositAmounts[i];
            payouts += _calPayout(_addr, i);
        }

        if (block.timestamp < startTime + 365 days){
            dayBonus = deposit * 17 / 10000;
        }else if (block.timestamp < startTime + 730 days){
            dayBonus = deposit * 14 / 10000;
        }else{
            dayBonus = deposit * 10 / 10000;
        }
    }

    function contractInfo() public view returns(uint256 totalDeposited, uint256 totalWithdraw, uint256 balance, uint256 addressNum){
        return (total_deposited, total_withdraw, _tbox.balanceOf(address(this)), lastUserId-1);
    }
}