/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Binaminers {
    address public owner;
    address payable public developer;

    struct Config {
        uint256 timeToFill;
        uint256 createNests;
        uint256 burnNests;
        uint256 createLummies;
        uint256 burnLummies;
        uint256 bnb;
        uint256 poolFee;
        uint256 referrerRewards;
        uint256 devFee;
        uint256 minDepositOnJoin;
        uint256 minDepositOnBuy;
        uint256 maxDeposit;
        bool maintenance;
    }

    Config public config = Config(
        10,     // timeToFill
        4,      // createNests
        8,      // burnNests
        8,      // createLummies
        10,     // burnLummies
        10,     // bnb
        45,     // poolFee
        10,     // referrerRewards
        5,      // devFee
        1e17,   // minDepositOnJoin
        1e17,   // minDepositOnBuy
        5e18,   // maxDeposit
        false   // maintenance
    );

    struct Pool {
        uint256 nests;
        uint256 lummies;
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
        uint256 medals;
        uint256 rewards;
        uint256 lastPickup;
        address referrer;
        address[] referrals;
        uint256 createdAt;
    }

    Pool public pool;
    mapping(address  => Player) public players;

    function poolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function me() external view returns (Player memory) {
        return players[msg.sender];
    }

    function currentTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    constructor(address developerAddress) {
        owner = msg.sender;
        developer = payable(developerAddress);
    }

    function join(address _referer_) public payable {
        require(!config.maintenance, 'MAINTENANCE');
        require(!players[msg.sender].isPlayer, 'PLAYER_EXISTS');
        require(msg.value >= config.minDepositOnJoin, 'MIN_DEPOSIT');
        require(msg.value <= config.maxDeposit, 'MAX_DEPOSIT');

        if (!players[_referer_].isPlayer) {
            _referer_ = msg.sender;
        }

        uint256 freeTaxBnb = payInvestmentFees(msg.sender, _referer_, msg.value);

        Player memory newPlayer = Player(true, msg.value, 0, msg.value, freeTaxBnb, 0, 0, currentTime(), _referer_, new address[](0), currentTime());
        players[msg.sender] = newPlayer;

        if (msg.sender != _referer_) {
            Player storage referrer = players[_referer_];
            referrer.medals += 1e17;
            referrer.referrals.push(msg.sender);
        }

        pool.nests += msg.value;
        pool.lummies += freeTaxBnb;
        pool.players += 1;
        pool.playerAddresses.push(msg.sender);
    }

    function build() public payable {
        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');
        require(msg.value >= config.minDepositOnBuy, 'MIN_DEPOSIT');
        require(player.investment + msg.value <= config.maxDeposit, 'MAX_DEPOSIT');

        uint256 freeTaxBnb = payInvestmentFees(msg.sender, player.referrer, msg.value);

        player.investment += msg.value;
        player.nests += msg.value;
        player.lummies += freeTaxBnb;

        pool.nests += msg.value;
        pool.lummies += freeTaxBnb;
    }

    function reinvestLummies() public {
        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 power = player.lummies / config.timeToFill;
        uint256 timeAgoLastPickup = currentTime() - player.lastPickup;

        uint256 lummiesPerSecond = power * config.createLummies / 100;
        uint256 maxLummies = lummiesPerSecond * config.timeToFill;
        uint256 newLummies = lummiesPerSecond * timeAgoLastPickup;

        if (newLummies > maxLummies) {
            newLummies = maxLummies;
        }

        if (player.lummies + newLummies > player.nests) {
            newLummies = player.nests - player.lummies;
        }

        pool.lummies += newLummies;

        player.lummies += newLummies;
        player.lastPickup = currentTime();
    }

    function reinvestNests() public {
        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 power = player.lummies / config.timeToFill;
        uint256 timeAgoLastPickup = currentTime() - player.lastPickup;

        uint256 nestsPerSecond = power * config.createNests / 100;
        uint256 maxNests = nestsPerSecond * config.timeToFill;
        uint256 newNests = nestsPerSecond * timeAgoLastPickup;

        if (newNests > maxNests) {
            newNests = maxNests;
        }

        pool.nests += newNests;

        player.nests += newNests;
        player.lastPickup = currentTime();
    }

    function claimMedals() public {
        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 power = player.lummies / config.timeToFill;
        uint256 timeAgoLastPickup = currentTime() - player.lastPickup;

        uint256 medalsPerSecond = power * config.bnb / 100;
        uint256 maxMedals = medalsPerSecond * config.timeToFill;
        uint256 newMedals = medalsPerSecond * timeAgoLastPickup;

        if (newMedals > maxMedals) {
            newMedals = maxMedals;
        }

        player.medals += newMedals;
        player.lastPickup = currentTime();
    }

    function claimBnb() public {
        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 power = player.lummies / config.timeToFill;
        uint256 timeAgoLastPickup = currentTime() - player.lastPickup;

        uint256 bnbToClaim;
        uint256 burnedNests;
        uint256 burnedLummies;

        if (timeAgoLastPickup > config.timeToFill) {
            bnbToClaim = (power * config.bnb / 100) * config.timeToFill;
            burnedLummies = (power * config.burnLummies / 100) * config.timeToFill;
            burnedNests = (power * config.burnNests / 100) * config.timeToFill;
        } else {
            bnbToClaim = (power * config.bnb / 100) * timeAgoLastPickup;
            burnedLummies = (power * config.burnLummies / 100) * timeAgoLastPickup;
            burnedNests = (power * config.burnNests / 100) * timeAgoLastPickup;
        }

        pool.claimed += bnbToClaim;
        pool.nests -= burnedNests;
        pool.lummies -= burnedLummies;

        player.claimed += bnbToClaim;
        player.nests -= burnedNests;
        player.lummies -= burnedLummies;
        player.lastPickup = currentTime();

        uint256 devFee = bnbToClaim * config.devFee / 100;
        developer.transfer(devFee);
        payable(msg.sender).transfer(bnbToClaim - devFee);
    }

    function claimRewards() public {
        require(!config.maintenance, 'MAINTENANCE');

        Player storage player = players[msg.sender];

        require(player.isPlayer, 'PLAYER_NOT_FOUND');
        require(player.rewards > 0, 'NOT_ALLOWED');

        uint256 rewards = player.rewards;
        uint256 devFee = rewards * config.devFee / 100;
        uint256 freeTaxBnb = rewards - devFee;

        player.rewards = 0;
        player.claimed += freeTaxBnb;
        pool.claimed += rewards;

        developer.transfer(devFee);
        payable(msg.sender).transfer(freeTaxBnb);
    }

    function reward(address playerAddress, uint256 nests, uint256 lummies, uint256 medals, uint256 rewards) external onlyOwner {
        Player storage player = players[playerAddress];

        if (player.isPlayer) {
            player.nests += nests;
            player.lummies += lummies;
            player.medals += medals;
            player.rewards += rewards;
        } else {
            players[playerAddress] = Player(true, 0, 0, nests, lummies, medals, rewards, currentTime(), playerAddress, new address[](0), currentTime());
        }

        pool.nests += nests;
        pool.lummies += lummies;
    }

    function payInvestmentFees(address playerAddress, address referrerAddress, uint256 amount) internal returns(uint256) {
        uint256 devFee = amount * config.devFee / 100;
        developer.transfer(devFee);

        if (playerAddress == referrerAddress) {
            // players without referrer pays 20% to liquid pool
            uint256 poolFee = amount * config.poolFee / 100;
            return amount - devFee - poolFee;
        } else {
            Player storage referrer = players[referrerAddress];

            address referrerOfReferrerAddress = referrer.referrer;

            if (referrerAddress == referrerOfReferrerAddress) {
                // players with 1 level referrer pays 10% to referrer
                uint256 referrerFee = amount * config.referrerRewards / 100;
                referrer.rewards += referrerFee;
                return amount - devFee - referrerFee;
            } else {
                // players with 2 level referrer pays 5% to referrer and 5% to referrer of referrer
                Player storage referrerOfReferrer = players[referrerOfReferrerAddress];
                uint256 referrerFee = amount * config.referrerRewards / 100;
                referrer.rewards += referrerFee / 2;
                referrerOfReferrer.rewards += referrerFee / 2;
                return amount - devFee - referrerFee;
            }
        }
    }

    function adjustConfig(
        uint256 timeToFill,
        uint256 createNests,
        uint256 burnNests,
        uint256 createLummies,
        uint256 burnLummies,
        uint256 bnb,
        uint256 poolFee,
        uint256 referrerRewards,
        uint256 devFee,
        uint256 minDepositOnJoin,
        uint256 minDepositOnBuy,
        uint256 maxDeposit
    ) external onlyOwner {
        config.timeToFill = timeToFill;
        config.createNests = createNests;
        config.burnNests = burnNests;
        config.createLummies = createLummies;
        config.burnLummies = burnLummies;
        config.bnb = bnb;
        config.poolFee = poolFee;
        config.referrerRewards = referrerRewards;
        config.devFee = devFee;
        config.minDepositOnJoin = minDepositOnJoin;
        config.minDepositOnBuy = minDepositOnBuy;
        config.maxDeposit = maxDeposit;
    }

    // **********************************************************************
    // add liquidity from weekly events
    // **********************************************************************
    function deposit() external payable {}

    // **********************************************************************
    // in case of new contract version or bug fixings,
    // nexts methods will needed to migrate data to new contract
    // **********************************************************************
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_ALLOWED");
        _;
    }

    function setMaintenance(bool maintenance) public onlyOwner {
        config.maintenance = maintenance;
    }

    function transfer() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getAllPlayers() public view onlyOwner returns(address[] memory) {
        return pool.playerAddresses;
    }

    function getPlayer(uint256 index) public view onlyOwner returns(address) {
        return pool.playerAddresses[index];
    }

    function countPlayers() public view onlyOwner returns(uint256) {
        return pool.playerAddresses.length;
    }
}