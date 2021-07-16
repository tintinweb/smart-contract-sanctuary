//SourceUnit: RDFStaking.sol

/*
 * Recyfinance (RFD) Staking  - Stake RFD tokens and earn staking
 */

pragma solidity ^0.4.25;

interface TokenContract {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool success);

    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success);
}

contract RFDStaking {
    using SafeMath for uint256;

    address public tokenContractAddress;

    uint256 public totalPlayers;
    uint256 public totalPayout;
    uint256 public totalInvested;
    uint256 public netInvested;
    uint256 private minDepositSize1 = 1000000;
    uint256 private minDepositSize2 = 50000000;
    uint256 private minDepositSize3 = 200000000;
    uint256 private minDepositSize4 = 500000000;

    uint256 private interestRateDivisor = 1000000000000;

    uint256 private UnstakingTrxFee = 100000;

    uint256 public LoadedRewards = 180000000000;
    uint256 public AllowedRewards = 108000000000;

    uint256 public Aff = 15;
    uint256 public Aff1 = 5;
    uint256 public Aff1A = 2;
    uint256 public Aff1B = 3;
    uint256 public Aff2 = 3;
    uint256 public Aff3 = 2;
    uint256 public Aff4 = 1;
    uint256 public Aff5 = 1;
    uint256 public Aff6 = 1;
    uint256 public Aff7 = 1;
    uint256 public Aff8 = 1;
    uint256 public Interest;
    uint256 public Interest1 = 120;
    uint256 public Interest2 = 145;
    uint256 public Interest3 = 170;
    uint256 public Interest4 = 195;

    uint256 public MarketingFee1 = 1;
    uint256 public MarketingFee2 = 1;
    uint256 public MarketingFee3 = 1;
    uint256 public commissionDivisor = 100;
    uint256 public collectProfit;
    uint256 private minuteRate;
    uint256 private minuteRate1 = 347223;
    uint256 private minuteRate2 = 462963;
    uint256 private minuteRate3 = 578704;
    uint256 private minuteRate4 = 694445;
    uint256 private enablestaking = 1;
    address private marketing1 = msg.sender;
    address private marketing2 = msg.sender;
    address private marketing3 = msg.sender;

    address owner;
    struct Player {
        uint256 trxDeposit;
        uint256 time;
        uint256 interestProfit;
        uint256 affRewards;
        uint256 payoutSum;
        address affFrom;
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
    }

    mapping(address => Player) public players;

    constructor(address _tokenContractAddress, address _owner) public {
        tokenContractAddress = _tokenContractAddress;
        owner = _owner;
    }

    function register(address _addr, address _affAddr) private {
        Player storage player = players[_addr];

        player.affFrom = _affAddr;

        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;

        players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
        players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
        players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
        players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
        players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);
        players[_affAddr6].aff6sum = players[_affAddr6].aff6sum.add(1);
        players[_affAddr7].aff7sum = players[_affAddr7].aff7sum.add(1);
        players[_affAddr8].aff8sum = players[_affAddr8].aff8sum.add(1);
    }

    function deposit(address _affAddr, uint256 amount) public {
        require(enablestaking > 0);
        require(LoadedRewards > AllowedRewards);

        address self = address(this);

        require(amount >= minDepositSize1, "less than minimum");

        TokenContract tokencontract = TokenContract(tokenContractAddress);
        tokencontract.transferFrom(msg.sender, self, amount);
        uint256 depositAmount = amount;

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if (_affAddr != address(0) && players[_affAddr].trxDeposit > 0) {
                register(msg.sender, _affAddr);
            } else {
                register(msg.sender, marketing2);
            }
        }

        uint256 maxStkRewards = maxStakeRewards(msg.sender);
        uint256 earnedStkRewards = player.payoutSum;

        if (earnedStkRewards >= maxStkRewards) {
            player.time = now;
        } else {
            collect(msg.sender);
        }

        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(amount, player.affFrom);
        uint256 deductvalue = depositAmount;
        LoadedRewards = LoadedRewards.sub(deductvalue);

        totalInvested = totalInvested.add(depositAmount);
        netInvested = netInvested.add(depositAmount);
        uint256 marketing_Fees1 = depositAmount.mul(MarketingFee1).div(
            commissionDivisor
        );
        uint256 marketing_Fees2 = depositAmount.mul(MarketingFee2).div(
            commissionDivisor
        );
        uint256 marketing_Fees3 = depositAmount.mul(MarketingFee3).div(
            commissionDivisor
        );

        tokencontract.transfer(marketing1, marketing_Fees1);
        tokencontract.transfer(marketing2, marketing_Fees2);
        tokencontract.transfer(marketing3, marketing_Fees3);
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

    function withdrawMyInvestment() public payable {
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        Player storage player = players[msg.sender];
        require(msg.value == UnstakingTrxFee);
        uint256 unstakingTrx_Fees = msg.value.div(2);
        marketing1.transfer(unstakingTrx_Fees);
        marketing3.transfer(unstakingTrx_Fees);

        if (player.interestProfit > 0) {
            withdraw();
        }

        uint256 unstakingamount = 0;
        uint256 unstakingcharges = 0;
        uint256 contBal = tokencontract.balanceOf(address(this));
        require(
            contBal > player.trxDeposit,
            "Amount greater than the contract balance"
        );

        uint256 maxStRewards = maxStakeRewards(msg.sender);
        uint256 earnedStRewards = player.payoutSum;

        if (earnedStRewards <= maxStRewards) {
            unstakingamount = player.trxDeposit.mul(80).div(commissionDivisor);
            unstakingcharges = player.trxDeposit.mul(20).div(commissionDivisor);
            LoadedRewards = LoadedRewards.add(unstakingcharges);
        } else {
            unstakingamount = player.trxDeposit;
        }

        tokencontract.transfer(msg.sender, unstakingamount);
        player.time = 0;
        netInvested = netInvested.sub(player.trxDeposit);
        player.trxDeposit = 0;
        player.interestProfit = 0;
        player.payoutSum = 0;
    }

    function maxStakeRewards(address _addr) internal view returns (uint256) {
        address playerAddress = _addr;
        Player storage player = players[playerAddress];

        if (
            player.trxDeposit >= minDepositSize1 &&
            player.trxDeposit <= minDepositSize2
        ) {
            Interest = Interest1;
        }

        if (
            player.trxDeposit > minDepositSize2 &&
            player.trxDeposit <= minDepositSize3
        ) {
            Interest = Interest2;
        }

        if (
            player.trxDeposit > minDepositSize3 &&
            player.trxDeposit <= minDepositSize4
        ) {
            Interest = Interest3;
        }

        if (player.trxDeposit > minDepositSize4) {
            Interest = Interest4;
        }

        uint256 maxstakingrewards = (
            player.trxDeposit.mul(Interest).div(commissionDivisor)
        );

        return maxstakingrewards;
    }

    function reinvest() public {
        require(enablestaking > 0);
        require(LoadedRewards > AllowedRewards);
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        uint256 contBal = tokencontract.balanceOf(address(this));
        collect(msg.sender);
        Player storage player = players[msg.sender];
        uint256 depositAmount = player.interestProfit;
        require(contBal >= depositAmount);
        player.interestProfit = 0;
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        totalInvested = totalInvested.add(depositAmount);
        netInvested = netInvested.add(depositAmount);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        uint256 contBal = tokencontract.balanceOf(address(this));

        uint256 secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            if (
                player.trxDeposit >= minDepositSize1 &&
                player.trxDeposit <= minDepositSize2
            ) {
                minuteRate = minuteRate1;
                Interest = Interest1;
            }

            if (
                player.trxDeposit > minDepositSize2 &&
                player.trxDeposit <= minDepositSize3
            ) {
                minuteRate = minuteRate2;
                Interest = Interest2;
            }

            if (
                player.trxDeposit > minDepositSize3 &&
                player.trxDeposit <= minDepositSize4
            ) {
                minuteRate = minuteRate3;
                Interest = Interest3;
            }

            if (player.trxDeposit > minDepositSize4) {
                minuteRate = minuteRate4;
                Interest = Interest4;
            }

            uint256 collectProfitGross = (
                player.trxDeposit.mul(secPassed.mul(minuteRate))
            )
                .div(interestRateDivisor);

            uint256 maxprofit = (
                player.trxDeposit.mul(Interest).div(commissionDivisor)
            );
            uint256 collectProfitNet = collectProfitGross.add(
                player.interestProfit
            );
            uint256 amountpaid = player.payoutSum;
            uint256 sum = amountpaid.add(collectProfitNet);

            if (sum <= maxprofit) {
                collectProfit = collectProfitGross;
            } else {
                uint256 collectProfit_net = maxprofit.sub(amountpaid);

                if (collectProfit_net > 0) {
                    collectProfit = collectProfit_net;
                } else {
                    collectProfit = 0;
                }
            }

            if (collectProfit > contBal) {
                collectProfit = 0;
            }

            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
            LoadedRewards = LoadedRewards.sub(collectProfit);
        }
    }

    function transferPayout(address _receiver, uint256 _amount) internal {
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        uint256 contBal = tokencontract.balanceOf(address(this));

        if (_amount > 0 && _receiver != address(0)) {
            uint256 contractBalance = contBal;
            if (contractBalance > 0) {
                uint256 payout = _amount > contractBalance
                    ? contractBalance
                    : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                tokencontract.transfer(msg.sender, payout);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private {
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        uint256 _allaff = (_trx.mul(Aff)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr3 = players[players[_affAddr1].affFrom].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            if (players[_affAddr1].aff1sum <= 10) {
                _affRewards = (_trx.mul(Aff1A)).div(100);
            }
            if (
                players[_affAddr1].aff1sum > 10 &&
                players[_affAddr1].aff1sum <= 50
            ) {
                _affRewards = (_trx.mul(Aff1B)).div(100);
            }
            if (players[_affAddr1].aff1sum > 50) {
                _affRewards = (_trx.mul(Aff1)).div(100);
            }

            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(
                players[_affAddr1].affRewards
            );
            tokencontract.transfer(_affAddr1, _affRewards);
        }

        if (players[_affAddr1].affFrom != address(0)) {
            _affRewards = (_trx.mul(Aff2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[players[_affAddr1].affFrom].affRewards = _affRewards.add(
                players[players[_affAddr1].affFrom].affRewards
            );

            tokencontract.transfer(players[_affAddr1].affFrom, _affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(Aff3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(
                players[_affAddr3].affRewards
            );

            tokencontract.transfer(_affAddr3, _affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(Aff4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(
                players[_affAddr4].affRewards
            );

            tokencontract.transfer(_affAddr4, _affRewards);
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(Aff5)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(
                players[_affAddr5].affRewards
            );
            tokencontract.transfer(_affAddr5, _affRewards);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(Aff6)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(
                players[_affAddr6].affRewards
            );
            tokencontract.transfer(_affAddr6, _affRewards);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(Aff7)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(
                players[_affAddr7].affRewards
            );
            tokencontract.transfer(_affAddr7, _affRewards);
        }

        if (_affAddr8 != address(0)) {
            _affRewards = (_trx.mul(Aff8)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(
                players[_affAddr8].affRewards
            );
            tokencontract.transfer(_affAddr8, _affRewards);
        }

        if (_allaff > 0) {
            tokencontract.transfer(marketing2, _allaff);
        }
    }

    function getProfit(address _addr) public view returns (uint256) {
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        uint256 contBal = tokencontract.balanceOf(address(this));
        address playerAddress = _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0);
        uint256 secPassed = now.sub(player.time);

        if (
            player.trxDeposit >= minDepositSize1 &&
            player.trxDeposit <= minDepositSize2
        ) {
            minuteRate = minuteRate1;
            Interest = Interest1;
        }

        if (
            player.trxDeposit > minDepositSize2 &&
            player.trxDeposit <= minDepositSize3
        ) {
            minuteRate = minuteRate2;
            Interest = Interest2;
        }

        if (
            player.trxDeposit > minDepositSize3 &&
            player.trxDeposit <= minDepositSize4
        ) {
            minuteRate = minuteRate3;
            Interest = Interest3;
        }

        if (player.trxDeposit > minDepositSize4) {
            minuteRate = minuteRate4;
            Interest = Interest4;
        }

        if (secPassed > 0) {
            uint256 collectProfitGross = (
                player.trxDeposit.mul(secPassed.mul(minuteRate))
            )
                .div(interestRateDivisor);
            uint256 maxprofit = (
                player.trxDeposit.mul(Interest).div(commissionDivisor)
            );
            uint256 collectProfitNet = collectProfitGross.add(
                player.interestProfit
            );
            uint256 amountpaid = player.payoutSum;
            uint256 sum = amountpaid.add(collectProfitNet);

            if (sum <= maxprofit) {
                collectProfit = collectProfitGross;
            } else {
                uint256 collectProfit_net = maxprofit.sub(amountpaid);

                if (collectProfit_net > 0) {
                    collectProfit = collectProfit_net;
                } else {
                    collectProfit = 0;
                }
            }

            if (collectProfit > contBal) {
                collectProfit = 0;
            }
        }

        return collectProfit.add(player.interestProfit);
    }

    function updateMarketing1(address _address) public {
        require(msg.sender == owner);
        marketing1 = _address;
    }

    function updateMarketing2(address _address) public {
        require(msg.sender == owner);
        marketing2 = _address;
    }

    function updateMarketing3(address _address) public {
        require(msg.sender == owner);
        marketing3 = _address;
    }

    function setEnableStaking(uint256 _enablestaking) public {
        require(msg.sender == owner);
        enablestaking = _enablestaking;
    }

    function setUnstakingFee(uint256 _UnstakingFee) public {
        require(msg.sender == owner);
        require(_UnstakingFee <= 100e6);
        UnstakingTrxFee = _UnstakingFee;
    }

    function setAllowedRewards(uint256 _AllowedRewards) public {
        require(msg.sender == owner);
        AllowedRewards = _AllowedRewards;
    }

    function setMinuteRate1(uint256 _MinuteRate1) public {
        require(msg.sender == owner);
        minuteRate1 = _MinuteRate1;
    }

    function setMinuteRate2(uint256 _MinuteRate2) public {
        require(msg.sender == owner);
        minuteRate2 = _MinuteRate2;
    }

    function setMinuteRate3(uint256 _MinuteRate3) public {
        require(msg.sender == owner);
        minuteRate3 = _MinuteRate3;
    }

    function setMinuteRate4(uint256 _MinuteRate4) public {
        require(msg.sender == owner);
        minuteRate4 = _MinuteRate4;
    }

    function setInterest1(uint256 _Interest1) public {
        require(msg.sender == owner);
        Interest1 = _Interest1;
    }

    function setInterest2(uint256 _Interest2) public {
        require(msg.sender == owner);
        Interest2 = _Interest2;
    }

    function setInterest3(uint256 _Interest3) public {
        require(msg.sender == owner);
        Interest3 = _Interest3;
    }

    function setInterest4(uint256 _Interest4) public {
        require(msg.sender == owner);
        Interest4 = _Interest4;
    }

    function setOwner(address _address) public {
        require(msg.sender == owner);
        owner = _address;
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