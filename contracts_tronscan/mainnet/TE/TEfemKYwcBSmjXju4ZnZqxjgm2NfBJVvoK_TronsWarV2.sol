//SourceUnit: TronWarV2.sol

pragma solidity ^0.4.23;

contract TronsWarV2 {

    using SafeMath for uint256;

    uint constant WARCOIN_PRICE = 10; 
    uint constant TYPES_OPTIONS = 18; 
    uint constant PERIOD = 1 minutes;

    uint[TYPES_OPTIONS] prices = [7500000, 14900000, 22200000,
                                    29350000, 36400000, 43500000,
                                    50200000, 57000000, 63700000,
                                    70400000, 76900000, 83500000,
                                    96900000, 103000000, 685000000,
                                    2050000000, 2725000000, 3390000000
                                    ];
    uint[TYPES_OPTIONS] profits = [84, 167, 250, 
                                    334, 417, 500,
                                    584, 667, 750,
                                    834, 917, 1000,
                                    1167, 1250, 8334,
                                    25000, 33334, 41667
                                    ]; 
    
    uint public totalPlayers; 
    uint public totalOptions;
    uint public totalPayout; 
    bool public bringOutStateWarTokens;

    address marketingOne;
    address marketingTwo;
    address marketingThree;
    address support; 
    address gameDevelopment;

    struct Player {
        uint warCoinsForBuy;
        uint warCoinsForSale; 
        uint time;
        uint[TYPES_OPTIONS] options;
        address referrer; 
        uint totalInvested; 
        uint totalProfit; 
        uint referrerProfit; 
        uint warToken;
    }

    mapping(address => Player) public players;
    mapping(address => bool) public transferWarTokens;

    event Deposit(address indexed from, address indexed referredBy, uint256 value);
    event Purchase(address indexed from, uint256 coinsSpent, uint256 unitType, uint256 number);
    event transferToken(address indexed from, uint256 value);

    constructor (address _marketingOne, address _marketingTwo, address _marketingThree, address _support, address _gameDevelopment) public {
        marketingOne = _marketingOne;
        marketingTwo = _marketingTwo;
        marketingThree=_marketingThree;
        support=_support;
        gameDevelopment=_gameDevelopment;

        players[_marketingOne].referrer=_support;
        players[_marketingTwo].referrer=_support;
        players[_marketingThree].referrer=_support;
        players[_support].referrer=_support;
        players[_gameDevelopment].referrer=_support;
        bringOutStateWarTokens = false;
    }

    function deposit(address _referredBy) public payable {
        require(msg.value >= WARCOIN_PRICE);
        Player storage player = players[msg.sender];

         if (player.time == 0) {
          if (_referredBy != address(0) && players[_referredBy].time > 0 && _referredBy != msg.sender  ) {
            player.referrer = _referredBy;
          } else {
            player.referrer = support;
          }
          player.time = now;           
        }
        else
        {
          collect(msg.sender);
        }

        player.warCoinsForBuy = player.warCoinsForBuy.add(msg.value.div(WARCOIN_PRICE));

        player.warToken = player.warToken.add(msg.value*2);
        transferWarTokens[msg.sender] = false;

        totalPlayers++;

        player.totalInvested = player.totalInvested.add(msg.value);
        emit Deposit(msg.sender,_referredBy, msg.value);
    }

    function buy(uint _type, uint _number) public {
       require(_type >= 0 && _type < TYPES_OPTIONS && _number > 0);
        collect(msg.sender);

        uint paymentWars = prices[_type].mul(_number);
        Player storage player = players[msg.sender];

        require(paymentWars <= player.warCoinsForBuy.add(player.warCoinsForSale));

        if (paymentWars <= player.warCoinsForBuy) {
            player.warCoinsForBuy = player.warCoinsForBuy.sub(paymentWars);
        } else {
            player.warCoinsForSale = player.warCoinsForSale.add(player.warCoinsForBuy).sub(paymentWars);
            player.warCoinsForBuy = 0;   
        }

        if (player.referrer != msg.sender && players[player.referrer].time > 0) {
            players[player.referrer].warCoinsForBuy = players[player.referrer].warCoinsForBuy.add(paymentWars.mul(20).div(1000));
            players[player.referrer].referrerProfit = players[player.referrer].referrerProfit.add(paymentWars.mul(20).div(1000));       
        } else {
            players[support].warCoinsForSale = players[support].warCoinsForSale.add(paymentWars.mul(20).div(1000));
        }
        
        player.options[_type] = player.options[_type].add(_number);
        players[marketingOne].warCoinsForSale = players[marketingOne].warCoinsForSale.add( paymentWars.mul(20).div(1000));
        players[marketingTwo].warCoinsForSale = players[marketingTwo].warCoinsForSale.add( paymentWars.mul(20).div(1000));
        players[marketingThree].warCoinsForSale = players[marketingThree].warCoinsForSale.add( paymentWars.mul(20).div(1000));
        players[gameDevelopment].warCoinsForSale = players[gameDevelopment].warCoinsForSale.add( paymentWars.mul(20).div(1000));

        totalOptions = totalOptions.add(_number);

        emit Purchase(msg.sender,  paymentWars, _number, _type);
    }

    function withdraw(uint _warCoins) public {
        require(_warCoins > 0);
        Player storage player = players[msg.sender];
		    require (player.time > 0);

        collect(msg.sender);
        require(_warCoins <= player.warCoinsForSale);

        player.warCoinsForSale = player.warCoinsForSale.sub(_warCoins);
        transfer(msg.sender, _warCoins.mul(WARCOIN_PRICE));   
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        require(player.time > 0);
        uint minutesPassed = (now.sub(player.time)).div(PERIOD);
        if (minutesPassed > 0) {
            uint minuteProfit;
            for (uint i = 0; i < TYPES_OPTIONS; i++) {
                minuteProfit = minuteProfit.add( player.options[i].mul(profits[i]) );
            }
            uint collectWars = minutesPassed.mul(minuteProfit);
            if(collectWars > 0){
                player.warCoinsForBuy = player.warCoinsForBuy.add( collectWars.div(2) );
                player.warCoinsForSale = player.warCoinsForSale.add( collectWars.div(2) );
                player.time = now;
            }
        }
    }

    function getCollectProfit(address _addr) internal view returns(uint) {	
      Player storage player = players[_addr];
      uint collectWars;
      if (player.time > 0) {
        uint minutesPassed = (now.sub(player.time)).div(PERIOD);
        if (minutesPassed > 0) {
          uint minuteProfit;
          for (uint i = 0; i < TYPES_OPTIONS; i++) {
            minuteProfit = minuteProfit.add( player.options[i].mul(profits[i]) );
          }
          collectWars = minutesPassed.mul(minuteProfit);
        }
      }
      return collectWars;
	  }

    function transfer(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                players[_receiver].totalProfit = players[_receiver].totalProfit.add(payout);

                msg.sender.transfer(payout);
            }
        }
    }

    function transferWarToken(uint _amount) public returns(uint){
        uint feedback;
        require(bringOutStateWarTokens == true);
        require(transferWarTokens[msg.sender] == false );
        require (_amount > 0 && msg.sender != address(0)); 
        Player storage player = players[msg.sender];
        require(player.warToken > 0);

        if(player.warToken > _amount){
            player.warToken = player.warToken.sub(_amount);
            feedback=_amount;
        }else{
            feedback = player.warToken;
            player.warToken = 0;
            transferWarTokens[msg.sender] = true;
        }
        return feedback;
    }
    
    function allowTransferWarTokens(address add_1,address add_2 , bool state) public {
        require(add_1!= address(0) && add_2!= address(0));
        require(add_1 == marketingOne && add_2 == marketingTwo);
        bringOutStateWarTokens = state;
    }

    function calculateProfitRegular(address _addr) public view returns (uint sumProfitBuy, uint sumProfitSale) {
        Player storage player = players[_addr];

        sumProfitBuy = player.warCoinsForBuy;
        sumProfitSale = player.warCoinsForSale;

        require(player.time > 0);
        uint collectCoins = getCollectProfit(_addr);
        if(collectCoins > 0){
            sumProfitBuy = player.warCoinsForBuy.add(collectCoins.div(2));
            sumProfitSale = player.warCoinsForSale.add(collectCoins.div(2));
        }
    }
    
    function optionsOf(address _addr) public view returns (uint[TYPES_OPTIONS]) {
      return players[_addr].options;
    }

    function warTokensOf(address _addr) public view returns (uint) {
       return players[_addr].warToken;
    }

    function pricesOf() public view returns (uint[TYPES_OPTIONS]) {
      return prices;
    }
    
    function profitsOf() public view returns (uint[TYPES_OPTIONS]) {
      return profits;
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
        require(a >= b);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}