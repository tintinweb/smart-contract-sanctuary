/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {
    // should be private
    uint256 public REFERRER_REWARDS = 10;
    uint256 public DEV_FEE = 5;
    uint256 public ROI_BASE = 10; // = 10;
    // should be private
    uint256 public MIN_DEPOSIT = 1e18 / 10;
    uint256 public MAX_DEPOSIT = 1e18 * 10;
    uint256 public TIME_TO_FILL_BARREL_IN_SECONDS = 60; // = 60 * 60 * 24; // 1 day

    address public owner;
    address payable public developer;

    function admin_config(
        uint256 _MIN_DEPOSIT_,
        uint256 _MAX_DEPOSIT_,
        uint256 _TIME_TO_FILL_BARREL_IN_SECONDS_
    ) public payable {
        require(msg.sender == owner, 'OPERATION_NOT_ALLOWED');
        MIN_DEPOSIT = _MIN_DEPOSIT_;
        MAX_DEPOSIT = _MAX_DEPOSIT_;
        TIME_TO_FILL_BARREL_IN_SECONDS = _TIME_TO_FILL_BARREL_IN_SECONDS_;
    }

    struct Pool {
        uint256 investment;
        uint256 reinvestment;
        uint256 withdrawals;
        uint256 players;
    }

    struct Player {
        bool isPlayer;
        address me;
        uint256 investment;
        uint256 reinvestment;
        uint256 withdrawals;
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

    function player() public view returns (Player memory) {
        Player memory _player = players[msg.sender];
        return _player;
    }

    function miningPowerPerSecond() public view returns (uint256) {
        Player memory _player = players[msg.sender];
        uint256 roi = _player.lummies / ROI_BASE;
        return roi / TIME_TO_FILL_BARREL_IN_SECONDS;
    }

    // should be private
    function collected() public view returns (uint256) {
        Player memory _player = players[msg.sender];
        uint256 _miningPowerPerSecond = miningPowerPerSecond();
        uint256 timeAgoLastPickup = currentTime() - _player.lastPickup;
        uint256 maxCollected = _miningPowerPerSecond * TIME_TO_FILL_BARREL_IN_SECONDS;
        uint256 _collected = _miningPowerPerSecond * timeAgoLastPickup;

        if (_collected > maxCollected * 2) {
            return 0;
        } else if (_collected > maxCollected) {
            return maxCollected - (_collected - maxCollected);
        } else {
            return _collected;
        }
    }

    function currentTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    constructor(address developerAddress) {
        owner = msg.sender;
        developer = payable(developerAddress); // change
    }

    function login() public view returns (bool) {
        Player memory _player = players[msg.sender];
        return _player.isPlayer;
    }

    function join(address _referer_) public payable {
        uint256 amount = msg.value;

        require(!players[msg.sender].isPlayer, 'PLAYER_EXISTS');
        require(amount >= MIN_DEPOSIT, 'MIN_DEPOSIT');
        require(amount <= MAX_DEPOSIT, 'MAX_DEPOSIT');

        if (!players[_referer_].isPlayer) {
            _referer_ = msg.sender;
        }

        uint256 devFee = amount * 5 / 100;
        uint256 freeTaxAmount = payInvestmentFees(msg.sender, _referer_, amount);

        Player memory newPlayer = Player(true, msg.sender, freeTaxAmount, 0, 0, amount, amount / 2,  0, 0, currentTime(), _referer_, new address[](0));
        players[msg.sender] = newPlayer;

        if (msg.sender != _referer_) {
            Player storage referrer = players[_referer_];
            referrer.referrals.push(msg.sender);
        }

        pool.players += 1;
        pool.investment += amount - devFee;
    }

    function buy() public payable {
        Player storage _player = players[msg.sender];
        uint256 amount = msg.value;

        require(_player.isPlayer, 'PLAYER_NOT_FOUND');
        require(amount >= MIN_DEPOSIT, 'MIN_DEPOSIT');
        require(amount <= MAX_DEPOSIT, 'MAX_DEPOSIT');

        uint256 devFee = amount * 5 / 100;
        uint256 freeTaxAmount = payInvestmentFees(msg.sender, _player.referrer, amount);

        _player.unclaimed += collected(); // should be before player.investment += freeAmount;
        _player.investment += freeTaxAmount;
        _player.nests += amount;
        _player.lastPickup = currentTime();

        pool.investment += amount - devFee;
    }

    function reinvest() public {
        Player storage _player = players[msg.sender];

        require(_player.isPlayer, 'PLAYER_NOT_FOUND');

        // player reinvests pays 5% to pool
        uint256 amount = collected() + _player.unclaimed + _player.unclaimedReferrals;
        uint256 poolFee = amount * 5 / 100;
        uint256 freeTaxAmount = amount - poolFee;

        _player.reinvestment += freeTaxAmount;
        if (_player.lummies + freeTaxAmount > _player.nests) {
            _player.lummies = _player.nests;
        } else {
            _player.lummies += freeTaxAmount;
        }
        _player.unclaimed = 0;
        _player.unclaimedReferrals = 0;
        _player.lastPickup = currentTime();

        pool.reinvestment += freeTaxAmount;
    }

    function claim() public {
        Player storage _player = players[msg.sender];

        require(_player.isPlayer, 'PLAYER_NOT_FOUND');

        uint256 amount = collected() + _player.unclaimed + _player.unclaimedReferrals;
        uint256 devFee = amount * 5 / 100;
        developer.transfer(devFee);

        uint256 freeTaxAmount = amount - devFee;

        _player.withdrawals += freeTaxAmount;
        _player.lummies -= freeTaxAmount;
        _player.unclaimed = 0;
        _player.unclaimedReferrals = 0;
        _player.lastPickup = currentTime();

        payable(msg.sender).transfer(freeTaxAmount);

        pool.withdrawals += freeTaxAmount;
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
}