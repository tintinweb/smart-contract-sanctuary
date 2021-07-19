//SourceUnit: blackTron.sol

pragma solidity ^0.4.25;

contract blackTron {
    using SafeMath for uint256;
    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public totalRefDistributed;
    uint256 public totalInvested;
    uint256 private minDepositSize = 100000000; /* 100 TRX */
    uint256 private interestRateDivisor = 1000000000000;
    uint256 public devCommission = 50; /* 5% platform fee */
    uint256 public commissionDivisor = 1000;
    address private devAddress = msg.sender;
    uint private releaseTime = 1616173200; // MARCH 20 01:00, 2021 UTC

    address owner;
    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 payoutSum;
        address affFrom;
        uint256 tier;
    }
    struct Referral {
        address player_addr;
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
    }

    mapping(address => Referral) public referrals;
    mapping(address => Player) public players;

    constructor() public {
        owner = msg.sender;
    }

    function register(address _addr, address _affAddr) private {
        Player storage player = players[_addr];
        player.affFrom = _affAddr;
        player.tier = 0;
        setRefCount(_addr, _affAddr);
    }

    function setRefCount(address _addr, address _affAddr) private {
        Referral storage preferral = referrals[_addr];
        preferral.player_addr = _addr;
        address _affAddr2 = players[_affAddr].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        referrals[_affAddr].aff1sum = referrals[_affAddr].aff1sum.add(1);
        referrals[_affAddr2].aff2sum = referrals[_affAddr2].aff2sum.add(1);
        referrals[_affAddr3].aff3sum = referrals[_affAddr3].aff3sum.add(1);
    }
    
    function setTier(address _addr) private {
        Player storage player = players[_addr];
        if(player.trxDeposit > 5e9 && player.tier < 1) { player.tier = 1; player.time = now; }
        if(player.trxDeposit > 10e9 && player.tier < 2) { player.tier = 2; player.time = now; }
        if(player.trxDeposit > 20e9 && player.tier < 3) { player.tier = 3; player.time = now; }
        if(player.trxDeposit > 50e9 && player.tier < 4) { player.tier = 4; player.time = now; }
    }
    
    function getRate(uint256 _tier) internal pure returns (uint256) {
        uint256 _rate = 2314814;
        if(_tier == 1) { _rate = 1736111; }
        if(_tier == 2) { _rate = 1157407; }
        if(_tier == 3) { _rate = 694444; }
        if(_tier == 4) { _rate = 231482; }
        return _rate;
    }
    
    function getTimeLimit(uint256 _tier) internal pure returns(uint256) {
        uint256 timeLimit = 1296000;
        if(_tier == 1) timeLimit = 1728000;
        if(_tier == 2) timeLimit = 2592000;
        if(_tier == 3) timeLimit = 4320000;
        if(_tier == 4) timeLimit = 12960000;
        return timeLimit;
    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not launched yet!");
        require(msg.value >= minDepositSize);
        collect(msg.sender);
        uint256 depositAmount = msg.value;
        Player storage player = players[msg.sender];
        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if (_affAddr != address(0) && players[_affAddr].trxDeposit > 0) {
                register(msg.sender, _affAddr);
            } else {
                register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        setTier(msg.sender);
        distributeRef(msg.value, player.affFrom);
        totalInvested = totalInvested.add(depositAmount);
        uint256 devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        devAddress.transfer(devEarn);
    }

    function withdraw_referral() public {
        require(now >= releaseTime, "not launched yet!");
        require(players[msg.sender].affRewards > 0);
        transferReferral(msg.sender, players[msg.sender].affRewards);
    }

    function withdraw() public {
        require(now >= releaseTime, "not launched yet!");
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);
        transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

    function reinvest() public {
        require(now >= releaseTime, "not launched yet!");
        collect(msg.sender);
        Player storage player = players[msg.sender];
        uint256 depositAmount = player.interestProfit;
        require(address(this).balance >= depositAmount);
        player.interestProfit = 0;
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        setTier(msg.sender);
        distributeRef(depositAmount, player.affFrom);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        uint256 secPassed = now.sub(player.time);
        uint256 timeLimit = 1296000;
        if(player.tier == 1) timeLimit = 1728000;
        if(player.tier == 2) timeLimit = 2592000;
        if(player.tier == 3) timeLimit = 4320000;
        if(player.tier == 4) timeLimit = 12960000;
        uint256 _rate = getRate(player.tier);
        if (secPassed > timeLimit && player.time > 0) {
            secPassed = timeLimit;
            uint256 collectProfit = (player.trxDeposit.mul(secPassed.mul(_rate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        } else if (secPassed > 0 && player.time > 0) {
            collectProfit = (player.trxDeposit.mul(secPassed.mul(_rate))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }

    function transferReferral(address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 payout =
                    _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                players[_receiver].affRewards = players[_receiver]
                    .affRewards
                    .sub(payout);
                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                msg.sender.transfer(payout);
            }
        }
    }

    function transferPayout(address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                uint256 maxProfit = (player.trxDeposit.mul(300)).div(100);
                uint256 paid = player.payoutSum;
                if (paid > maxProfit) { player.trxDeposit = 0; }
                msg.sender.transfer(payout);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private {
        if(_affFrom == address(0)) _affFrom = owner;
        address _affAddr2 = players[_affFrom].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        if(_affAddr2 == address(0)) _affAddr2 = owner;
        if(_affAddr3 == address(0)) _affAddr3 = owner;
        uint256 refTrx = (_trx.mul(8)).div(100);
        totalRefDistributed = totalRefDistributed.add(refTrx);
        players[_affFrom].affRewards = players[_affFrom].affRewards.add(refTrx);
        refTrx = (_trx.mul(5)).div(100);
        totalRefDistributed = totalRefDistributed.add(refTrx);
        players[_affAddr2].affRewards = players[_affAddr2].affRewards.add(refTrx);
        refTrx = (_trx.mul(2)).div(100);
        totalRefDistributed = totalRefDistributed.add(refTrx);
        players[_affAddr3].affRewards = players[_affAddr3].affRewards.add(refTrx);
    }

    function getProfit(address _addr) public view returns (uint256) {
        address playerAddress = _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0, "player time is 0");
        uint256 secPassed = now.sub(player.time);
        uint256 timeLimit = getTimeLimit(player.tier);
        uint256 _rate = getRate(player.tier);
        if (secPassed > 0) {
            if (secPassed > timeLimit) {
                secPassed = timeLimit;
                uint256 collectProfit = (player.trxDeposit.mul(secPassed.mul(_rate))).div(interestRateDivisor);
            } else {
                collectProfit = (player.trxDeposit.mul(secPassed.mul(_rate))).div(interestRateDivisor);
            }
        }
        return collectProfit.add(player.interestProfit);
    }
    
    function getRemainingTime(address _addr) internal view returns(uint256) {
        Player storage player = players[_addr];
        uint256 secPassed = now.sub(player.time);
        uint256 timeLimit = getTimeLimit(player.tier);
        if (secPassed > 0) {
            if (secPassed > timeLimit) {
                secPassed = timeLimit;
            }
        }
        timeLimit = timeLimit - secPassed;
        return timeLimit;
    }

    function getContractInfo() public view returns (
        uint256 total_users,
        uint256 total_invested,
        uint256 total_withdrawn,
        uint256 total_referrals,
        uint256 contract_balance,
        uint256 contract_launchdate
    ) {
        total_users = totalPlayers;
        total_invested = totalInvested;
        total_withdrawn = totalPayout;
        total_referrals = totalRefDistributed;
        contract_balance = address(this).balance;
        contract_launchdate = releaseTime;
        return (
            total_users,
            total_invested,
            total_withdrawn,
            total_referrals,
            contract_balance,
            contract_launchdate
        );
    }
    
    function getUserInfo(address _addr) public view returns (
        uint256 total_deposit,
        uint256 remaining_time,
        uint256 withdrawable,
        uint256 withdrawn,
        uint256 ref_rewards,
        uint256 referrals1,
        uint256 referrals2,
        uint256 referrals3,
        uint256 tier
    ) {
        
        Player storage player = players[_addr];
        
        if(player.time != 0) {
            total_deposit = player.trxDeposit;
            remaining_time = getRemainingTime(_addr);
            withdrawable = getProfit(_addr);
            withdrawn = player.payoutSum;
            ref_rewards = player.affRewards;
            referrals1 = referrals[_addr].aff1sum;
            referrals2 = referrals[_addr].aff2sum;
            referrals3 = referrals[_addr].aff3sum;
            tier = player.tier;
        }
        return (
            total_deposit,
            remaining_time,
            withdrawable,
            withdrawn,
            ref_rewards,
            referrals1,
            referrals2,
            referrals3,
            tier
        );
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