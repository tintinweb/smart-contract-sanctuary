//SourceUnit: criptoworlds.sol

pragma solidity =0.4.25;

library SafeMath { //We divide only by constans, no check requeries.

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

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

contract FutureContract {
    function doAction(address player, uint amount, uint8 action) external {}
}

contract TronWorlds {

    using SafeMath for uint256;

    uint constant NUMBER_OF_UNITS = 6;
    uint constant PERIOD = 60 minutes;

    //We have a public functions that return the whole arrays, no need to make them public.
    uint64[NUMBER_OF_UNITS] unitPrices = [500 trx, 100 trx, 1500 trx, 4000 trx, 10000 trx, 30000 trx];
    uint64[NUMBER_OF_UNITS] unitProfits = [0.69 trx, 0.13 trx, 2.1 trx, 5.7 trx, 14.6 trx, 45 trx];

    uint64[NUMBER_OF_UNITS] public newUnitPrices;
    uint64[NUMBER_OF_UNITS] public newUnitProfits;

    //We have a public function that return the whole game info.
    uint totalPlayers;
    uint totalUnits;
    uint totalPayout;
    uint doomsdayEndTime;

    address admin;
    address owner;

    //Future contract will let to buy military units, artefacts etc with game balance.
    FutureContract public futureContract;

    struct Player {
        uint withdrawableBalance;
        uint repurchaseBalance;
        uint time;
        uint32[NUMBER_OF_UNITS] units;
        address sponsor;
        uint ref_earnings;
        address[] referrals;
    }

    //We have a public function that return the whole player info.
    mapping(address => Player) players;

    modifier doomsdayCheck() {
        require(doomsdayEndTime < now, "It's Doomsday now, wait till it ends.");
        _;
    }
       
    function() external payable { } //future contracts can donate money to this contract to delay doomsday.
    
    constructor(address _owner, address _admin) public {
        owner = _owner;
        admin = _admin;
        doomsdayEndTime = now + PERIOD;
    }

    //admin gets 5% from any purchase.
    function changeAdmin(address _admin) external {
        require(msg.sender == owner);
        admin = _admin;
    }
    //admin can set new unit prices and profit, they will be applied only after next doomsday.
    function setNewUnitPrice(uint8 _type, uint64 _newUnitPrice) external {
        require(msg.sender == admin);
        require(_type < NUMBER_OF_UNITS && _newUnitPrice > 0 && _newUnitPrice < 100000000001);
        newUnitPrices[_type] = _newUnitPrice;
    }

    function setNewUnitProfit(uint8 _type, uint64 _newUnitProfit) external {
        require(msg.sender == admin);
        require(_type < NUMBER_OF_UNITS && _newUnitProfit > 0 && _newUnitProfit < 1000000001);
        newUnitProfits[_type] = _newUnitProfit;
    }
    //admin can set Future Contract. It's public information.
    function setFutureContract(address _contract) external {
        require(msg.sender == admin);
        futureContract = FutureContract(_contract);
    }
    //first time deposit function set up player and his sponsor.
    function firstDeposit(address sponsor) external payable doomsdayCheck() {
        require(msg.value > 0);
        Player storage player = players[msg.sender];
        require(player.time == 0);

        if(checkSponsor(sponsor)) {
            player.sponsor = sponsor;
            players[sponsor].referrals.push(msg.sender);
        }
        player.time = now;
        totalPlayers++;

        player.repurchaseBalance = player.repurchaseBalance.add(msg.value);
    }
    // only for existed players.
    function deposit() external payable doomsdayCheck() {
        require(msg.value > 0);
        Player storage player = players[msg.sender];
        require(player.time != 0);

        if (player.time < doomsdayEndTime - PERIOD) clearPlayer(player);
        player.repurchaseBalance = player.repurchaseBalance.add(msg.value);
    }

    function withdraw(uint amount) external doomsdayCheck() {
        require(amount > 0);

        Player storage player = players[msg.sender];
        checkPlayerProfit(player);

        require(amount <= player.withdrawableBalance);
        player.withdrawableBalance -= amount; //we explicitly checked the amount, no need for underflow check.

        uint contractBalance = address(this).balance;
        if (contractBalance > amount) {
            totalPayout += amount;
            msg.sender.transfer(amount);           
        }
        else { //if the contract have not enough money left then doomsday starts.
            totalUnits = 0;
            totalPayout = 0;
            for(uint i = 0; i < NUMBER_OF_UNITS; i++) { //setting new unit prices and profit.
                if(newUnitPrices[i] != 0) {
                    unitPrices[i] = newUnitPrices[i];
                    newUnitPrices[i] = 0;
                }
                if(newUnitProfits[i] != 0) {
                    unitProfits[i] = newUnitProfits[i];
                    newUnitProfits[i] = 0;
                }
            }
            doomsdayEndTime = now + 24 * PERIOD; //24 hours delay before new start.
            players[admin].repurchaseBalance = 0; //manually clear admin.
            players[admin].withdrawableBalance = 0;
            players[admin].units = [0,0,0,0,0,0];
            players[admin].time = doomsdayEndTime;
            msg.sender.transfer(contractBalance);
        }
    }

    function buyUnit(uint8 _type, uint16 amount) external doomsdayCheck() {
        require(_type < NUMBER_OF_UNITS && amount > 0 && amount < 10001);
   
        Player storage player = players[msg.sender];
        checkPlayerProfit(player);

        require(_type != 0 || player.sponsor != address(0), "You need to have a valid sponsor to buy this unit.");

        uint payment = unitPrices[_type] * amount; //both values are checked for maximum cap. Overflow is impossible.
        require(payment <= player.repurchaseBalance.add(player.withdrawableBalance), "You have insufficient funds, deposit more.");

        if (payment <= player.repurchaseBalance) {
            player.repurchaseBalance -=  payment; //explicit underflow checked.
        } else {
            player.withdrawableBalance = player.withdrawableBalance.add(player.repurchaseBalance).sub(payment);
            player.repurchaseBalance = 0;
        }
        uint devs = payment / 20;
        players[admin].withdrawableBalance = players[admin].withdrawableBalance.add(devs);
        if (checkSponsor(player.sponsor)) {
            players[player.sponsor].withdrawableBalance = players[player.sponsor].withdrawableBalance.add(devs);
            players[player.sponsor].ref_earnings += devs;
        }
        player.units[_type] += amount; //theoretically possible to owerflow if somebody buys more than 4 billions units. Don't buy that much.) Won't affect other players anyway.
        totalUnits += amount;
    }
    //only player himself can start this action, while the Future Contract is not set it will revert.
    function futureContractAction(uint amount, uint8 action) external doomsdayCheck() {
        require(amount > 0);
        require(futureContract != address(0));
        Player storage player = players[msg.sender];
        checkPlayerProfit(player);

        require(amount <= player.repurchaseBalance.add(player.withdrawableBalance), "You have insufficient funds, deposit more.");
        if (amount <= player.repurchaseBalance) {
            player.repurchaseBalance -= amount;
        } else {
            player.withdrawableBalance = player.withdrawableBalance.add(player.repurchaseBalance).sub(amount);
            player.repurchaseBalance = 0;
        }
        futureContract.doAction(msg.sender, amount, action);
    }

    function checkSponsor(address player) public view returns(bool) {
        if (player == address(0) || player == msg.sender) return false;
        uint units = 0;
        for(uint i = 0; i < NUMBER_OF_UNITS; i++) {
            units += players[player].units[i];
        }
        return (units != 0);
    }

    function checkPlayerProfit(Player storage player) internal {
        require(player.time > 0);
        if (player.time < doomsdayEndTime - PERIOD) {
            clearPlayer(player);
        }
        else {
            uint periods = (now - player.time) / PERIOD;
            if (periods > 0) {
                uint profitPerPeriod;
                for (uint i = 0; i < NUMBER_OF_UNITS; i++) {
                    profitPerPeriod = profitPerPeriod.add(unitProfits[i] * player.units[i]); //uint64 * uint32 is uint96 maximum.
                }
                uint profit = periods.mul(profitPerPeriod);
                player.repurchaseBalance = player.repurchaseBalance.add(profit / 2);
                player.withdrawableBalance = player.withdrawableBalance.add(profit / 2);
                player.time = player.time.add(periods.mul(PERIOD));
            }
        }
    }
    //clear player after doomsday.
    function clearPlayer(Player storage player) internal {
        player.repurchaseBalance = 0;
        player.withdrawableBalance = 0;
        player.units = [0,0,0,0,0,0];
        player.time = now;
    }

    function getGameInfo() external view returns(uint, uint, uint, uint, uint) {
        uint contractBalance = address(this).balance;
        return (contractBalance, totalPlayers, totalUnits, totalPayout, doomsdayEndTime);
    }

    function getPlayerInfo(address _player) external view returns(uint, uint, uint, uint, address, uint32[NUMBER_OF_UNITS]) {
        Player storage player = players[_player];
        return (player.withdrawableBalance, player.repurchaseBalance, player.time, player.ref_earnings, player.sponsor, player.units);
    }

    function getPlayerRefferalsList() external view returns(address[]) {
        return players[msg.sender].referrals;
    }

    function getUnitPrices() external view returns (uint64[NUMBER_OF_UNITS]) {
        return unitPrices;
    }

    function getUnitProfits() external view returns (uint64[NUMBER_OF_UNITS]) {
        return unitProfits;
    }
}