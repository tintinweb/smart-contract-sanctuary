//SourceUnit: contract.sol


/*
███████╗███████╗███████╗████████╗██████╗░██╗░░██╗░░░░█████╗░░█████╗░███╗░░░███╗
╚════██║╚════██║╚════██║╚══██╔══╝██╔══██╗╚██╗██╔╝░░░██╔══██╗██╔══██╗████╗░████║
░░░░██╔╝░░░░██╔╝░░░░██╔╝░░░██║░░░██████╔╝░╚███╔╝░░░░██║░░╚═╝██║░░██║██╔████╔██║
░░░██╔╝░░░░██╔╝░░░░██╔╝░░░░██║░░░██╔══██╗░██╔██╗░░░░██║░░██╗██║░░██║██║╚██╔╝██║
░░██╔╝░░░░██╔╝░░░░██╔╝░░░░░██║░░░██║░░██║██╔╝╚██╗██╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
░░╚═╝░░░░░╚═╝░░░░░╚═╝░░░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.4.25;

contract _777trx {

    using SafeMath for uint;

    uint public GAME_START_TIME = 1594706400;
    uint public MINIMUM_DEPOSIT = 50000000;  // 50 TRX

    //income percent: 0.0054% per minute or 7.77% daily
    uint public RATE_PER_MINUTE = 54;

    uint ADMIN_PERCENT = 100;           // 10% in TRX
    uint REFERER_PERCENT = 50;          //  5% in TRX
    uint REFERER_2_PERCENT_POWER = 30;  //  3% in power
    uint REFERER_3_PERCENT_POWER = 20;  //  2% in power

    address public owner;

    uint public totalInvested = 0;
    uint public totalWithdrawn = 0;
    uint public totalPlayers = 0;

    struct Player {
        uint balance;
        uint last_payout;
        uint last_collect;
        uint power;
        uint power_by_refs;
        address referer;
        uint invested;
        uint withdrawn;
        uint earned_on_refs;
    }
    mapping(address => Player) public players;

    constructor() public {
      owner = msg.sender;
      registration(owner);
    }

    function isUserRegistered(address _address) public view returns (bool) {
        return players[_address].referer != address(0);
    }

    modifier _isUserRegistered() {
        require(isUserRegistered(msg.sender), "User is not registered");
        _;
    }

    modifier _isDepositAllowed() {
        require(now >= GAME_START_TIME, "The game has not started yet");
        _;
    }

    function earned(address _address) public view returns(uint) {
        Player player = players[_address];
        uint balance = player.balance;
        uint userRate = player.power.add(player.power_by_refs).mul(RATE_PER_MINUTE);
        uint minutesPassed = now.sub(player.last_collect).div(60);
        uint withdrawalAmount = userRate.mul(minutesPassed).add(balance);
        return withdrawalAmount;
    }

    function collect(address _address) private returns(uint) {
        uint value = earned(_address);
        players[_address].balance = value;
        players[_address].last_collect = now;
        return value;
    }

    function registration(address _referer) private {
        players[msg.sender].balance = 0;
        players[msg.sender].last_payout = 0;
        players[msg.sender].last_collect = now;
        players[msg.sender].power = 0;
        players[msg.sender].power_by_refs = 0;
        players[msg.sender].referer = _referer;
        players[msg.sender].withdrawn = 0;
        players[msg.sender].earned_on_refs = 0;
        totalPlayers += 1;
    }

    function distribute(address _referer1, uint value) private {
        address _referer2 = players[_referer1].referer;
        address _referer3 = players[_referer2].referer;
        owner.transfer(value.mul(ADMIN_PERCENT).div(1000));
        _referer1.transfer(value.mul(REFERER_PERCENT).div(1000));
        players[_referer1].earned_on_refs += value.mul(REFERER_PERCENT).div(1000);
        totalWithdrawn += ADMIN_PERCENT.add(REFERER_PERCENT).mul(value).div(1000);

        collect(_referer2);
        players[_referer2].power_by_refs = value.mul(REFERER_2_PERCENT_POWER).div(1000000000).add(players[_referer2].power_by_refs);
        collect(_referer3);
        players[_referer3].power_by_refs = value.mul(REFERER_3_PERCENT_POWER).div(1000000000).add(players[_referer3].power_by_refs);
    }

    function withdraw() _isUserRegistered public returns(bool) {
        uint payout = collect(msg.sender);
        players[msg.sender].last_payout = now;
        players[msg.sender].balance = 0;
        if (address(this).balance < payout) {
          payout = address(this).balance;
        }
        players[msg.sender].withdrawn += payout;
        totalWithdrawn += payout;
        msg.sender.transfer(payout);
        return true;
    }

    function () external payable {
        deposit(owner);
    }

    function deposit(address _referer) _isDepositAllowed public payable returns(bool) {
        uint value = msg.value;
        require(value >= MINIMUM_DEPOSIT, "Deposit is too small");

        if (isUserRegistered(msg.sender)) {
            _referer = players[msg.sender].referer;
            collect(msg.sender);
        } else {
            if (_referer == address(0) || _referer == msg.sender || !isUserRegistered(_referer)) {
                _referer = owner;
            }
            registration(_referer);
        }
        distribute(_referer, value);

        players[msg.sender].power = value.div(1000000).add(players[msg.sender].power);
        players[msg.sender].invested += value;
        totalInvested += value;
        return true;
    }

    function reinvest() _isUserRegistered public returns(bool) {
        uint value = collect(msg.sender);
        players[msg.sender].last_payout = now;
        players[msg.sender].balance = 0;
        players[msg.sender].power = value.div(1000000).add(players[msg.sender].power);

        distribute(players[msg.sender].referer, value);

        return true;
    }

}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

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