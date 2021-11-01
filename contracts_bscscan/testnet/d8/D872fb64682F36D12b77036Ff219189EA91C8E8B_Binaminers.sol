// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";
import "./BNBPool.sol";
import "./LCPool.sol";

contract Binaminers is Auth {
    address public developer;
    BNBPool public bnbPool;
    LCPool public lcPool;

    uint256 ONE_LUMMY_FARM_COIN = 1;

    struct Config {
        uint256 timeToFill;
        uint256 createNests;
        uint256 createLummies;
        uint256 createCoins;
        uint256 bnb;
        uint256 poolFee;
        uint256 referrerRewards;
        uint256 devFee;
        uint256 minDepositOnJoin;
        uint256 minDepositOnBuy;
        uint256 maxDeposit;
        bool maintenance;
    }

    struct Tokens {
        uint256 coinsPerBnb;
        uint256 nestPriceInCoinsOnJoin;
        uint256 lummyPriceInCoinsOnJoin;
        uint256 nestPriceInCoins;
        uint256 lummyPriceInCoins;
        uint256 burnNests;
        uint256 burnLummies;
    }

    Config public config = Config(
        10,     // timeToFill
        1,      // createNests
        1,      // createLummies
        1,      // createCoins
        1,      // bnb
        45,     // poolFee
        10,     // referrerRewards
        5,      // devFee
        1e17,   // minDepositOnJoin
        1e17,   // minDepositOnBuy
        5e18,   // maxDeposit
        false  // maintenance
    );

    Tokens public tokens = Tokens(
        5000,   // coinsPerBnb
        10,     // nestPriceInCoinsOnJoin
        10,     // lummyPriceInCoinsOnJoin
        20,     // nestPriceInCoins
        10,     // lummyPriceInCoins
        6,      // burnNests
        12      // burnLummies
    );

    struct Pool {
        uint256 nests;
        uint256 lummies;
        uint256 coins;
        uint256 claimed;
        uint256 players;
        address[] playerAddresses;
    }

    struct Player {
        bool isPlayer;
        uint256 investment;
        uint256 claimed;
        uint256 nests;
        uint256 lummies;
        uint256 greed;
        uint256 lastPickup;
        address referrer;
        address[] referrals;
        uint256 createdAt;
    }

    Pool public pool;
    mapping(address  => Player) public players;

    function me() external view returns (Player memory) {
        return players[msg.sender];
    }

    function currentTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    constructor(address _developer_) Auth(msg.sender) {
//        lcPool = new LCPool(msg.sender, _developer_);
//        bnbPool = new BNBPool(msg.sender, _developer_);
        developer = _developer_;
        // create player developer
    }

    function link(address _bnbPoolAddress_, address _lcPoolAddress_) external onlyOwner {
        bnbPool = BNBPool(_bnbPoolAddress_);
        lcPool = LCPool(_lcPoolAddress_);
    }

    function collected(Player memory player) internal view returns (uint256) {
        uint256 timeAgoLastPickup = currentTime() - player.lastPickup;
        uint256 maxCoins = player.lummies * ONE_LUMMY_FARM_COIN;
        uint256 coins = timeAgoLastPickup * maxCoins / config.timeToFill;

        if (coins > maxCoins) {
            return maxCoins;
        } else {
            return coins;
        }
    }

    function privateSale(address _player_, uint256 _nests_, uint256 _lummies_, uint256 _greed_, address _referrer_) external payable onlyAuthorized {
        uint256 bnb = msg.value;

        require(!players[_player_].isPlayer, 'PLAYER_EXISTS');
        require(!players[_referrer_].isPlayer, 'PLAYER_NOT_FOUND');

        players[_player_] = Player(true, msg.value, 0, _nests_, _lummies_, _greed_, 0, _referrer_, new address[](0), currentTime());
    }

    function join(address _referer_) public payable {
        uint256 bnb = msg.value;

        require(!config.maintenance, 'MAINTENANCE');
        require(!players[msg.sender].isPlayer, 'PLAYER_EXISTS');
        require(bnb >= config.minDepositOnJoin, 'MIN_DEPOSIT');
        require(bnb <= config.maxDeposit, 'MAX_DEPOSIT');

        if (!players[_referer_].isPlayer) {
            _referer_ = msg.sender;
        }

        uint256 freeTaxBnb = payInvestmentFees(msg.sender, _referer_, bnb);
        uint256 coins = bnb * tokens.coinsPerBnb;
        uint256 freeTaxCoins = freeTaxBnb * tokens.coinsPerBnb;

        uint256 nests = coins / tokens.nestPriceInCoinsOnJoin;
        uint256 lummies = freeTaxCoins / tokens.lummyPriceInCoinsOnJoin;

        Player memory newPlayer = Player(true, bnb, 0, nests, lummies, 0, currentTime(), _referer_, new address[](0), currentTime());
        players[msg.sender] = newPlayer;

        if (msg.sender != _referer_) {
            Player storage referrer = players[_referer_];
            referrer.referrals.push(msg.sender);
        }

        pool.nests += nests;
        pool.lummies += lummies;
        pool.players += 1;
        pool.playerAddresses.push(msg.sender);
    }

    function build() public payable {
        uint256 bnb = msg.value;

        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');
        require(bnb >= config.minDepositOnBuy, 'MIN_DEPOSIT');
        require(player.investment + bnb <= config.maxDeposit, 'MAX_DEPOSIT');

        uint256 freeTaxBnb = payInvestmentFees(msg.sender, player.referrer, bnb);
        uint256 coins = bnb * tokens.coinsPerBnb;
        uint256 freeTaxCoins = freeTaxBnb * tokens.coinsPerBnb;

        uint256 nests = coins / tokens.nestPriceInCoinsOnJoin;
        uint256 lummies = freeTaxCoins / tokens.lummyPriceInCoinsOnJoin;

        player.investment += bnb;
        player.nests += nests;
        player.lummies += lummies;

        pool.nests += nests;
        pool.lummies += lummies;
    }

    function reinvestLummies() public {
        require(!config.maintenance, 'MAINTENANCE');
        require(config.createNests > 0, 'DISABLED');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 coins = collected(player);
        uint256 lummies = coins / tokens.lummyPriceInCoins;

        if (player.lummies + lummies > player.nests) {
            lummies = player.nests - player.lummies;
        }

        pool.lummies += lummies;

        player.lummies += lummies;
        player.lastPickup = currentTime();
    }

    function reinvestNests() public {
        require(!config.maintenance, 'MAINTENANCE');
        require(config.createNests > 0, 'DISABLED');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 coins = collected(player);
        uint256 nests = coins / tokens.nestPriceInCoins;

        pool.nests += nests;

        player.nests += nests;
        player.lastPickup = currentTime();
    }

    function claim() public {
        require(!config.maintenance, 'MAINTENANCE');
        require(config.bnb > 0, 'DISABLED');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 coins = collected(player);
        uint256 burnedLummies = coins * tokens.burnLummies / 100;
        uint256 burnedNests = coins * tokens.burnNests / 100;

//        pool.claimed += bnbToClaim;
        pool.nests -= burnedNests;
        pool.lummies -= burnedLummies;

//        player.claimed += bnbToClaim;
        player.nests -= burnedNests;
        player.lummies -= burnedLummies;
        player.lastPickup = currentTime();

        bnbPool.transfer(msg.sender, coins / tokens.coinsPerBnb);
//        uint256 devFee = bnbToClaim * config.devFee / 100;
//        developer.transfer(devFee);
//        payable(msg.sender).transfer(bnbToClaim - devFee);
    }

//    function reward(address playerAddress, uint256 nests, uint256 lummies) external onlyOwner {
//        Player storage player = players[playerAddress];
//
//        if (player.isPlayer) {
//            player.nests += nests;
//            player.lummies += lummies;
//        } else {
//            players[playerAddress] = Player(true, 0, 0, nests, lummies, currentTime(), developer, new address[](0), currentTime());
//        }
//
//        pool.nests += nests;
//        pool.lummies += lummies;
//    }

    function payInvestmentFees(address playerAddress, address referrerAddress, uint256 bnb) internal returns(uint256) {
        uint256 devFee = bnb * config.devFee / 100;
//        developer.transfer(devFee);

        if (playerAddress == referrerAddress) {
            // players without referrer pays % to liquid pool
            bnbPool.deposit{ value: bnb - devFee }();

            uint256 poolFee = bnb * config.poolFee / 100;
            return bnb - devFee - poolFee;
        } else {
            Player storage referrer = players[referrerAddress];

            address referrerOfReferrerAddress = referrer.referrer;

            if (referrerAddress == referrerOfReferrerAddress) {
                // players with 1 level referrer pays 10% to referrer
                uint256 referrerRewards = bnb * config.referrerRewards / 100;

                bnbPool.deposit{ value: bnb - devFee - referrerRewards }();
                lcPool.deposit{ value: referrerRewards }(referrerAddress);

                return bnb - devFee - referrerRewards;
            } else {
                // players with 2 level referrer pays 5% to referrer and 5% to referrer of referrer
                uint256 referrerRewards = bnb * config.referrerRewards / 100;

                bnbPool.deposit{ value: bnb - devFee - referrerRewards }();
                lcPool.deposit{ value: referrerRewards / 2 }(referrerAddress);
                lcPool.deposit{ value: referrerRewards / 2 }(referrerOfReferrerAddress);

                return bnb - devFee - referrerRewards;
            }
        }
    }

    function adjustTokens(
        uint256 createNests,
        uint256 burnNests,
        uint256 createLummies,
        uint256 burnLummies,
        uint256 createCoins,
        uint256 bnb
    ) external onlyOwner {
        config.createNests = createNests;
        tokens.burnNests = burnNests;
        config.createLummies = createLummies;
        tokens.burnLummies = burnLummies;
        config.createCoins = createCoins;
        config.bnb = bnb;
    }

    function adjustConfig(
        uint256 timeToFill,
        uint256 poolFee,
        uint256 referrerRewards,
        uint256 devFee,
        uint256 minDepositOnJoin,
        uint256 minDepositOnBuy,
        uint256 maxDeposit
    ) external onlyOwner {
        config.timeToFill = timeToFill;
        config.poolFee = poolFee;
        config.referrerRewards = referrerRewards;
        config.devFee = devFee;
        config.minDepositOnJoin = minDepositOnJoin;
        config.minDepositOnBuy = minDepositOnBuy;
        config.maxDeposit = maxDeposit;
    }

    // **********************************************************************
    // Weekly events
    // **********************************************************************
//    function payCoins(address _player_, uint256 _coins_) external {
//        require(authorized[msg.sender], 'NOT_ALLOWED');
//        require(players[_player_].coins >= _coins_, 'INSUFFICIENT_MEDALS');
//
//        players[_player_].coins -= _coins_;
//    }

    // **********************************************************************
    // in case of new contract version or bug fixings,
    // nexts methods will needed to migrate data to new contract
    // **********************************************************************
    function setMaintenance(bool _maintenance_) external onlyOwner {
        config.maintenance = _maintenance_;
    }

//    function transfer() external onlyOwner {
//        payable(owner).transfer(address(this).balance);
//    }

    function getAllPlayers() external view onlyOwner returns(address[] memory) {
        return pool.playerAddresses;
    }

    function getPlayer(uint256 index) external view onlyOwner returns(address) {
        return pool.playerAddresses[index];
    }

    function countPlayers() external view onlyOwner returns(uint256) {
        return pool.playerAddresses.length;
    }
}