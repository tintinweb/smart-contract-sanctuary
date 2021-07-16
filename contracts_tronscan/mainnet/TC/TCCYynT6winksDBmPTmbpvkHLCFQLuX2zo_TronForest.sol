//SourceUnit: TronForest.sol

pragma solidity 0.5.9;

contract TronForest {
	using SafeMath for uint256;

	uint256 TREES_STEP = 50000; // Increase price by 1TRX every
	uint256 OXYGEN_DIV = 1000000; // Multiplier for Oxygen

	uint256 next_auction = 1610236800;
	uint256 total_trees;
	uint256 total_withdrawn;
	uint256 days_running;

    address payable public _marketing;
	address payable public _project;

	struct Plot {
	    address payable owner;
	    uint256 trees;
	    uint256 current_price;
	    uint256 last_withdraw;
	}

	struct Player {
		address referrer;
		uint256 trees;
        uint256 last_withdraw;

        uint256 referrals;
		uint256 earnings_referral;
		uint256 earnings_auction;
		uint256 earnings_landowner;
		uint256 total_earnings_referral;
		uint256 total_earnings_auction;
		uint256 total_earnings_landowner;
		uint256 total_referral_bonus_trees;
		uint256 total_oxygen_from_land;
		uint256 total_withdrawn;

		uint256 oxygen;
		uint256 oxygen_sold;
	}

	struct ForAuction {
	    address player;
	    uint256 oxygen;
	}

	mapping(uint8 => Plot) plots;
	mapping(address => Player) players;
	ForAuction[] auctions;

	event PlotSold(uint8 plot_id, address owner, uint256 new_price);
	event TreesPlanted(uint8 plot_id, uint256 trees);
	event UpForAuction(uint256 oxygen, uint256 total);
	event NewDay();

	constructor(address payable marketing) public {
	    days_running = 0;
		_marketing = marketing;
		_project = msg.sender;

		for(uint8 i = 1; i <= 25; i++){
		    plots[i] = Plot(_project, 0, 100 trx, block.timestamp);
		}
	}

	function buyPlot(uint8 plot_id, address referrer) public payable {
	    if(next_auction < block.timestamp){ wrapUpDay(); }
    	require(plot_id >= 1 && plot_id <= 25, "Unknown Plot");
    	Plot storage plot = plots[plot_id];
        require(msg.value >= plot.current_price, "Not enough TRX");

        setAndPayReferral(msg.sender, referrer, msg.value);

        uint256 old_price = plot.current_price.mul(100).div(150);
        plot.owner.transfer(old_price);
        uint256 rest = plot.current_price - old_price;
        _project.transfer(rest.div(5));
        _marketing.transfer(rest.div(5));

        plot.owner = msg.sender;
        plot.current_price = plot.current_price.mul(150).div(100).ceil(1000000);

        emit PlotSold(plot_id, msg.sender, plot.current_price);
	}

	function plantTrees(uint8 plot_id, address referrer) public payable {
	    if(next_auction < block.timestamp){ wrapUpDay(); }
	    // require(block.timestamp > TREE_LAUNCH, "Planting trees is not online yet.");
	    require(plot_id >= 1 && plot_id <= 25, "Unknown Plot");
	    uint256 tree_price = currentTreePrice();
	    require(msg.value >= tree_price, "Not enough TRX");

	    uint256 trees = msg.value.div(tree_price);
        Player storage player = players[msg.sender];
	    Plot storage plot = plots[plot_id];

	    setAndPayReferral(msg.sender, referrer, msg.value);
	    rewardTreeBonus(referrer, trees);

	    _marketing.transfer(msg.value.mul(7).div(100));
	    _project.transfer(msg.value.mul(7).div(100));

	    wrapPlayerOxygen(player);

	    players[plot.owner].earnings_landowner += trees.mul(1 trx);
	    players[plot.owner].total_earnings_landowner += trees.mul(1 trx);

	    plot.trees += trees;
	    player.trees += trees;
	    total_trees += trees;

	    emit TreesPlanted(plot_id, trees);
	}

	function sellOxygen() public payable {
	    if(next_auction < block.timestamp){ wrapUpDay(); }
        Player storage player = players[msg.sender];

        wrapPlayerOxygen(player);
        wrapLandOwnerOxygen(msg.sender);
        uint256 oxygen = player.oxygen;

	    require(oxygen > 0, "No Oxygen for sale");

	    auctions.push(ForAuction({
	       player: msg.sender,
	       oxygen: oxygen
	    }));

	    player.oxygen_sold += oxygen;
	    player.oxygen = 0;

	    emit UpForAuction(oxygen, oxygenForSaleToday());
	}

	function withdraw() public payable {
	    if(next_auction < block.timestamp){ wrapUpDay(); }
	    Player storage player = players[msg.sender];
	    uint256 amount = player.earnings_auction + player.earnings_landowner + player.earnings_referral;
	    require(amount > 0, "Nothing to withdraw");
	    player.total_withdrawn += amount;
	    total_withdrawn += amount;
	    msg.sender.transfer(amount);
	    player.earnings_auction = 0;
	    player.earnings_referral = 0;
	    player.earnings_landowner = 0;
	}

	function wrapUpDay() public payable {
	    require(next_auction < block.timestamp, "Day is not over");

	    if(auctions.length > 0){
    	    uint256 pool = address(this).balance.mul(1).div(100);

    	    uint256 oxygen_for_sale;
    	    for(uint256 i = 0; i < auctions.length; i++){
    	        oxygen_for_sale += auctions[i].oxygen;
    	    }

    	    uint256 todays_price = pool.div(oxygen_for_sale);

    	    for(uint256 i = 0; i < auctions.length; i++){
    	        players[auctions[i].player].earnings_auction += auctions[i].oxygen.mul(todays_price);
    	        players[auctions[i].player].total_earnings_auction += auctions[i].oxygen.mul(todays_price);
    	    }

    	    delete auctions;
	    }
	    next_auction = next_auction + (60 * 60 * 24);
	    days_running += 1;

	    emit NewDay();
	}

	// Info

	function gameInfo() view external returns(uint256 _tree_price, uint256 _total_trees, uint256 _total_withdrawm, uint256 _next_auction, uint256 _oxygen_for_sale, uint256 _days_running){
	    return(currentTreePrice(), total_trees, total_withdrawn, next_auction, oxygenForSaleToday(), days_running);
	}

    function plotInfo() view external returns(address[] memory _owner, uint256[] memory _trees, uint256[] memory _current_price, uint256[] memory _last_withdraw) {
        address[] memory owner = new address[](25);
        uint256[] memory trees = new uint256[](25);
        uint256[] memory price = new uint256[](25);
        uint256[] memory lwith = new uint256[](25);

        for(uint8 i = 0; i <= 24; i++) {
          Plot storage plot = plots[(i+1)];
          owner[i] = plot.owner;
          trees[i] = plot.trees;
          price[i] = plot.current_price;
          lwith[i] = plot.last_withdraw;
        }
        return (owner, trees, price, lwith);
    }

    function playerInfo(address _player) view external returns(uint256 _trees, uint256 _land_trees, uint256 _oxygen_available, uint256 _oxygen_sold, uint256 _total_oxygen_from_land, uint256 _referrals){
        Player memory player = players[_player];
        uint256 oxygen_available = player.oxygen;
        uint256 land_trees;

        for(uint8 i = 1; i <= 25; i++){
            Plot memory plot = plots[i];
            if(plot.owner == _player){
                land_trees += plot.trees;
                oxygen_available += plot.trees.mul(OXYGEN_DIV).mul(block.timestamp - plot.last_withdraw).div(86400).div(100);
            }
        }

        oxygen_available += player.trees.mul(OXYGEN_DIV).mul(block.timestamp - player.last_withdraw).div(86400).div(10);

        return (
            player.trees, land_trees, oxygen_available, player.oxygen_sold, player.total_oxygen_from_land, player.referrals
        );
    }

    function playerWallet(address _player) view external returns(
        uint256 _total_earnings_referral, uint256 _total_earnings_auction, uint256 _total_earnings_landowner, uint256 _total_bonus_trees,
        uint256 _earnings_referral, uint256 _earnings_auction, uint256 _earnings_landowner, uint256 _available
    ){
        Player memory player = players[_player];
        return (
            player.total_earnings_referral, player.total_earnings_auction, player.total_earnings_landowner, player.total_referral_bonus_trees,
            player.earnings_referral, player.earnings_auction, player.earnings_landowner,
            (player.earnings_referral + player.earnings_auction + player.earnings_landowner)
        );
    }
    // Internal

    function wrapPlayerOxygen(Player storage player) private {
        player.oxygen += player.trees.mul(OXYGEN_DIV).mul(block.timestamp - player.last_withdraw).div(86400).div(10);
        player.last_withdraw = block.timestamp;
    }

    function wrapLandOwnerOxygen(address payable player) private {
        for(uint8 i = 1; i <= 25; i++){
            Plot memory plot = plots[i];
            if(plot.owner == player){
                uint256 oxygen = plot.trees.mul(OXYGEN_DIV).mul(block.timestamp - plot.last_withdraw).div(86400).div(100);
                players[player].oxygen += oxygen;
                players[player].total_oxygen_from_land += oxygen;
                plots[i].last_withdraw = block.timestamp;
            }
        }
    }

    function setAndPayReferral(address sender, address referrer, uint256 amount) private {
        Player storage player = players[sender];
        if(player.referrer == address(0)){
            player.referrer = referrer;
            players[player.referrer].referrals += 1;
        }
        players[player.referrer].earnings_referral += amount.mul(6).div(100);
        players[player.referrer].total_earnings_referral += amount.mul(6).div(100);
    }

    function rewardTreeBonus(address referrer, uint256 trees) private {
        uint256 bonus = trees.div(25);
        players[referrer].trees += bonus;
        players[referrer].total_referral_bonus_trees += bonus;
        total_trees += bonus;
    }

    function currentTreePrice() private view returns(uint256 value) {
        if(days_running <= 3){ return (6 + days_running).mul(1000000); }
        return 10 trx + total_trees.div(TREES_STEP).mul(1000000);
    }

    function oxygenForSaleToday() private view returns(uint256 value) {
        uint256 oxygen;
	    for(uint256 i = 0; i < auctions.length; i++){
	        oxygen += auctions[i].oxygen;
	    }
	    return oxygen;
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
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((a + b - 1) / b) * b;
    }
}