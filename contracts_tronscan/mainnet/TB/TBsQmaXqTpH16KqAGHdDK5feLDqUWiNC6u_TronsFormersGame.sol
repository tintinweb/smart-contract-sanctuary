//SourceUnit: tronsformersgame.sol

/***************************\
/*                         *\
/*                         *\
/*https://tronsformers.com *\
/*                         *\
/*                         *\
\***************************/


pragma solidity ^0.4.25;

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

contract TronsFormersGame {
   using SafeMath for uint256;

    uint constant COIN_PRICE = 40000;
    uint constant TYPES_PLANTATION = 6;
    uint constant PERIOD = 1 hours;

    uint[TYPES_PLANTATION] prices = [2400, 6000, 10250, 18000, 64000, 464000];
    uint[TYPES_PLANTATION] profit = [2, 6, 12, 24, 96, 768];
     
   
    uint public totalPlayers;
    uint public totalPlantation;
    uint public totalPayout;
    

    address owner;
    address manager1;
    address manager2;
    uint starting = now;

    struct Player {
        uint coinsForBuy;
        uint coinsForSale;
        uint time;
        uint[TYPES_PLANTATION] plantation;
    }

    mapping(address => Player) public players;

    constructor(address _manager1, address _manager2) public {
        owner = msg.sender;
        manager1 = _manager1;
        manager2 = _manager2;
    }

    function deposit() public payable {
        require(msg.value >= COIN_PRICE);

        Player storage player = players[msg.sender];
        player.coinsForBuy = player.coinsForBuy.add(msg.value.div(COIN_PRICE));

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
        }
    }

    function buy(uint _type, uint _number) public {
      
        require(_type < TYPES_PLANTATION && _number > 0);
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

        player.plantation[_type] = player.plantation[_type].add(_number);
        players[owner].coinsForSale = players[owner].coinsForSale.add( paymentCoins.mul(40).div(1000) );
        players[manager1].coinsForSale = players[manager1].coinsForSale.add( paymentCoins.mul(30).div(1000) );
        players[manager2].coinsForSale = players[manager2].coinsForSale.add( paymentCoins.mul(30).div(1000) );

        totalPlantation = totalPlantation.add(_number);
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
            for (uint i = 0; i < TYPES_PLANTATION; i++) {
                hourlyProfit = hourlyProfit.add( player.plantation[i].mul(profit[i]) );
            }
            uint collectCoins = hoursPassed.mul(hourlyProfit);
            player.coinsForBuy = player.coinsForBuy.add( collectCoins.div(2) );
            player.coinsForSale = player.coinsForSale.add( collectCoins.div(2) );
            player.time = player.time.add( hoursPassed.mul(PERIOD) );
        }
    }
     
    
     function coins(address _addr) public view returns(uint _CoinsForBuy,uint _CoinsForSale) {
        Player storage player = players[_addr];
        if(player.time > 0){
       

        uint hoursPassed = ( now.sub(player.time)).div(PERIOD);
        if (hoursPassed > 0) {
            uint hourlyProfit;
            for (uint i = 0; i < TYPES_PLANTATION; i++) {
                hourlyProfit = hourlyProfit.add( player.plantation[i].mul(profit[i]));
            }
            uint collectCoins = hoursPassed.mul(hourlyProfit);
            player.coinsForBuy = player.coinsForBuy.add( collectCoins.div(2) );
            player.coinsForSale = player.coinsForSale.add( collectCoins.div(2));
            return(player.coinsForBuy,player.coinsForSale);
        }
        else {
            return(player.coinsForBuy,player.coinsForSale);
        }
            
       }
    }

    function transfer(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                uint fee = ((payout * 10)/100);
                msg.sender.transfer(payout - fee);
                manager2.transfer(fee);
            }
        }
    }

    function plantationOf(address _addr) public view returns (uint[TYPES_PLANTATION]) {
        return players[_addr].plantation;
    }
    function profitPerhour() public view returns(uint){
        uint profits;
        for(uint i = 0 ; i < TYPES_PLANTATION ; i++){
            profits = profits.add( players[msg.sender].plantation[i].mul(profit[i]));
            
        }
        return profits;
        
        
    }
     function totalPlantation() public view returns(uint){
        uint plantation;
        for(uint i = 0 ; i < TYPES_PLANTATION ; i++){
            plantation = plantation.add( players[msg.sender].plantation[i]);
            
        }
        return plantation;
        
        
    }

   
    
   

}