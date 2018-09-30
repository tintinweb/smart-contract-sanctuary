pragma solidity ^0.4.25;

//
//   ____                                      ______                        __      
//  /\  _`\                                   /\__  _\                      /\ \__   
//  \ \,\L\_\  __  __  _____      __   _ __   \/_/\ \/ _ __   __  __    ____\ \ ,_\  
//   \/_\__ \ /\ \/\ \/\ &#39;__`\  /&#39;__`\/\`&#39;__\    \ \ \/\`&#39;__\/\ \/\ \  /&#39;,__\\ \ \/  
//     /\ \L\ \ \ \_\ \ \ \L\ \/\  __/\ \ \/      \ \ \ \ \/ \ \ \_\ \/\__, `\\ \ \_ 
//     \ `\____\ \____/\ \ ,__/\ \____\\ \_\       \ \_\ \_\  \ \____/\/\____/ \ \__\
//      \/_____/\/___/  \ \ \/  \/____/ \/_/        \/_/\/_/   \/___/  \/___/   \/__/
//                       \ \_\               
//                        \/_/                                                        
//
//  ETHEREUM PSEUDO-INVESTMENT SMART CONTRACT
//
//  Make a payment to this address to become a participant. Once invested,
//  any following transactions of any amount will request dividend payout
//  for you and increase invested amount.
//
//  Easter Eggs:
//  1. If a function "advertise" called by any ethereum address with supplied
//  referring address and at least 0.15 ETH, and referring address makes
//  payments in future, referrer address will receive 3% referral bonuses.
//  E.g., in geth console you can do the following:
//
//  var abi = eth.contract(<TrustABI>);
//  var contract = abi.at("<TrustAddress>");
//  var calldata = contract.advertise.getData("<TargetAddress>");
//  web3.eth.sendTransaction({from:"<YourAddress>", to:"<TrustAddress>",
//      data: calldata, value: web3.toWei(0.15, "ether"), gas:200000});
//
//  Copypaste and insert your values into "<>" placeholders.
//
//  Referring wallet will receive an advertisement payment of 1 WEI and your
//  supplied ETH value will be invested. PLEASE NOTE that 0.15 ETH price
//  may be changed - see "Read Contract" tab on etherscan.io.
//
//  2. Gold investor receive instant 3% bonus payments, when regular
//  investors make payments greater than 0.05 ETH on each N-th transaction.
//
//  3. Gold referrer will receive additional bonus in similar way as the gold
//  investor.
//
//  Please do not send payments via contracts and other unusual ways -
//  these payments may be lost. Recommended gas limit per transaction is
//  200000.
//
//  Initial GAIN:                               4%
//  Referral Bonus:                             3% from investments
//  Gold Bonus:                                 3% from every N-th investment
//  Project Fee:                                3% from dividends
//  Minimum investment:                         No limit
//  Other questions:                            apiman45445 at protonmail.com
//

contract SuperTrust {
	// Generate public view getters for game settings and stats
	address public admin = msg.sender;
	uint256 public round = 0;
	uint256 public payoutFee;
	uint256 public goldBonus;
	uint256 public referralBonus;
	uint256 public investorGain;
	uint256 public bonusInterval;
	uint256 public bonusThreshold;
	uint256 public advPrice;
	uint256 public investorCount;
	uint256 public avgMinedPerDay;
	uint256 public collectedFee = 0;
	bool public lastRound = false; 
    // Hide some data from public access to prevent manipulations
	mapping(uint256 => mapping(address => Investor)) private investors;
	mapping(uint256 => mapping(address => address)) private referrals;
	address[2] private board;
	uint256 private roulett;

	struct Investor {
		uint256 deposit;
		uint256 block;
		uint256 refBalance;
		bool banned;
	}

	function globalReinitialization() private {
		payoutFee = 3;
		goldBonus = 3;
		referralBonus = 3;
		investorGain = 4;
		bonusInterval = 5;
		bonusThreshold = 0.05 ether;
		advPrice = 0.15 ether;
		investorCount = 0;
		avgMinedPerDay = 5900;
		board = [admin, admin];
		roulett = bonusInterval * board.length;
	}

	constructor () public {
		globalReinitialization();
	}

	//
	// Administration
	//

	event LogAdminRetired(address, address, address);
	event LogPayoutFeeChanged(address, uint256, uint256);
	event LogGoldBonusChanged(address, uint256, uint256);
	event LogReferralBonusChanged(address, uint256, uint256);
	event LogInvestorGainChanged(address, uint256, uint256);
	event LogBonusIntervalChanged(address, uint256, uint256);
	event LogBonusThresholdChanged(address, uint256, uint256);
	event LogAdvPriceChanged(address, uint256, uint256);
	event LogAvgMinedPerDayChanged(address, uint256, uint256);
	event LogReferrerBanned(address, address, string);

	modifier asAdmin {
		require(msg.sender == admin, "unauthorized function call");
		_;
	}

	function retireAdmin(address newAdmin) public asAdmin {
		emit LogAdminRetired(msg.sender, admin, newAdmin);
		admin = newAdmin;
	}

	function setPayoutFee(uint256 newValue) public asAdmin {
		// Administrator cannot withdraw all money at any time.
		require((newValue > 0) && (newValue <= 10));
		emit LogPayoutFeeChanged(msg.sender, payoutFee, newValue);
		payoutFee = newValue;
	}

	function setGoldBonus(uint256 newValue) public asAdmin {
		require((newValue > 0) && (newValue <= 10));
		emit LogGoldBonusChanged(msg.sender, goldBonus, newValue);
		goldBonus = newValue;
	}

	function setReferralBonus(uint256 newValue) public asAdmin {
		require((newValue > 0) && (newValue <= 10));
		emit LogReferralBonusChanged(msg.sender, referralBonus, newValue);
		referralBonus = newValue;
	}

	function setInvestorGain(uint256 newValue) public asAdmin {
		require((newValue > 0) && (newValue <= 5));
		emit LogInvestorGainChanged(msg.sender, investorGain, newValue);
		investorGain = newValue;
	}

	function setBonusInterval(uint256 newValue) public asAdmin {
		require(newValue > 0);
		emit LogBonusIntervalChanged(msg.sender, bonusInterval, newValue);
		bonusInterval = newValue;
		roulett = bonusInterval * board.length;
	}

	function setBonusThreshold(uint256 newValue) public asAdmin {
		emit LogBonusThresholdChanged(msg.sender, bonusThreshold, newValue);
		bonusThreshold = newValue;
	}

	function setAdvPrice(uint256 newValue) public asAdmin {
		emit LogAdvPriceChanged(msg.sender, advPrice, newValue);
		advPrice = newValue;
	}

	function setAvgMinedPerDay(uint256 newValue) public asAdmin {
		require(newValue >= 4000);
		emit LogAvgMinedPerDayChanged(msg.sender, avgMinedPerDay, newValue);
		avgMinedPerDay = newValue;
	}

	function collectFee(uint256 percent) public asAdmin {
		require(percent <= 100);
		uint256 amount = (collectedFee * percent) / 100;
		require(amount <= collectedFee);
		collectedFee -= amount;
		admin.transfer(amount);
	}

	function banReferrer(address target) public asAdmin {
		require(target != admin);
		emit LogReferrerBanned(msg.sender, target, "Violating referrer banned");
		investors[round][target].banned = true;
		board[1] = admin; // refBonus of admin is always zero
	}

	function unbanReferrer(address target) public asAdmin {
		require(target != admin);
		emit LogReferrerBanned(msg.sender, target, "Referrer unbanned");
		investors[round][target].banned = false;
	}

	//
	// Game logic
	//

	event LogGoldBonus(address, address, uint256);
	event LogReferralBonus(address, address, uint256);
	event LogAdvertisement(address, address, uint256);
	event LogNewInvestor(address, uint256);
	event LogRoundEnd(address, uint256, uint256, uint256);
	event LogBoardChange(address, uint256, string);

	function payoutBonuses() private {
		// GOLD bonus payout, if any
		roulett--;
		if (roulett % bonusInterval == 0) {
			uint256 bonusAmount = (msg.value * goldBonus) / 100;
			uint256 winnIdx = roulett / bonusInterval;
			if ((board[winnIdx] != msg.sender) && (board[winnIdx] != admin)) {
				// Payouts to itself are not applicable, admin has its own reward
				emit LogGoldBonus(msg.sender, board[winnIdx], bonusAmount);
				payoutBalanceCheck(board[winnIdx], bonusAmount);
			}
		}
		if (roulett == 0)
			roulett = bonusInterval * board.length;
	}

	function payoutReferrer() private {
		uint256 bonusAmount = (msg.value * referralBonus) / 100;
		address referrer = referrals[round][msg.sender];
		if (!investors[round][referrer].banned) {
			if (referrer != admin)
				investors[round][referrer].refBalance += bonusAmount;
			emit LogReferralBonus(msg.sender, referrer, bonusAmount);
			updateGoldReferrer(referrer);
			payoutBalanceCheck(referrer, bonusAmount);
		}
	}

	function payoutBalanceCheck(address to, uint256 value) private {
		if (to == admin) {
			collectedFee += value;
			return;
		}
		if (value > (address(this).balance - 0.01 ether)) {
			if (lastRound)
				selfdestruct(admin);
			emit LogRoundEnd(msg.sender, value, address(this).balance, round);
			globalReinitialization();
			round++;
			return;
		}
		to.transfer(value);
	}

	function processDividends() private {
		if (investors[round][msg.sender].deposit != 0) {
			// ((investorGain% from deposit) * minedBlocks) / avgMinedPerDay
			uint256 deposit = investors[round][msg.sender].deposit;
			uint256 previousBlock = investors[round][msg.sender].block;
			uint256 minedBlocks = block.number - previousBlock;
			uint256 dailyIncome = (deposit * investorGain) / 100;
			uint256 divsAmount = (dailyIncome * minedBlocks) / avgMinedPerDay;
			collectedFee += (divsAmount * payoutFee) / 100;
			payoutBalanceCheck(msg.sender, divsAmount);	
		}
		else if (msg.value != 0) {
			emit LogNewInvestor(msg.sender, ++investorCount);
		}
		investors[round][msg.sender].block = block.number;
		investors[round][msg.sender].deposit += msg.value;
	}

	function updateGoldInvestor(address candidate) private {
		uint256 candidateDeposit = investors[round][candidate].deposit;
		if (candidateDeposit > investors[round][board[0]].deposit) {
			board[0] = candidate;
			emit LogBoardChange(candidate, candidateDeposit,
				"Congrats! New Gold Investor!");
		}
	}

	function updateGoldReferrer(address candidate) private {
		// Admin can refer participants, but will not be the gold referrer.
		if ((candidate != admin) && (!investors[round][candidate].banned)) {
			uint256 candidateRefBalance = investors[round][candidate].refBalance;
			uint256 goldReferrerBalance = investors[round][board[1]].refBalance;
			if (candidateRefBalance > goldReferrerBalance) {
				board[1] = candidate;
				emit LogBoardChange(candidate, candidateRefBalance,
					"Congrats! New Gold Referrer!");
			}
		}
	}

	function regularPayment() private {
		if (msg.value >= bonusThreshold) {
			payoutBonuses();
			if (referrals[round][msg.sender] != 0)
				payoutReferrer();
		}
		processDividends();
		updateGoldInvestor(msg.sender);
	}

	function advertise(address targetAddress) external payable {
		// Any violation results in failed transaction
		if (investors[round][msg.sender].banned)
			revert("You are violating the rules and banned");
		if ((msg.sender != admin) && (msg.value < advPrice))
			revert("Need more ETH to make an advertiement");
		if (investors[round][targetAddress].deposit != 0)
			revert("Advertising address is already an investor");
		if (referrals[round][targetAddress] != 0)
			revert("Address already advertised");

		emit LogAdvertisement(msg.sender, targetAddress, msg.value);
		referrals[round][targetAddress] = msg.sender;
		targetAddress.transfer(1 wei);
		regularPayment();
	}

	function () external payable {
		regularPayment();
	} 
}