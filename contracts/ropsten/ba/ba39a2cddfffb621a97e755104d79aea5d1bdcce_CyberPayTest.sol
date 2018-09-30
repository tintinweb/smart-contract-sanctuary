pragma solidity ^0.4.25;

//
//   ____             __                         ____                      
//  /\  _`\          /\ \                       /\  _`\                    
//  \ \ \/\_\  __  __\ \ \____     __   _ __    \ \ \L\ \ __     __  __    
//   \ \ \/_/_/\ \/\ \\ \ &#39;__`\  /&#39;__`\/\`&#39;__\   \ \ ,__/&#39;__`\  /\ \/\ \   
//    \ \ \L\ \ \ \_\ \\ \ \L\ \/\  __/\ \ \/     \ \ \/\ \L\.\_\ \ \_\ \  
//     \ \____/\/`____ \\ \_,__/\ \____\\ \_\      \ \_\ \__/.\_\\/`____ \ 
//      \/___/  `/___/> \\/___/  \/____/ \/_/       \/_/\/__/\/_/ `/___/> \
//                 /\___/                                            /\___/
//                 \/__/                                             \/__/ 
//
//  ETHEREUM SMART CONTRACT RESEARCH PROJECT
//
//  Make a payment to this address to become a participant. Once invested,
//  any following transactions of any amount will request dividend payout
//  for you and increase invested amount.
//
//  Easter Eggs:
//  1. VIP investors receive instant small bonus payments, when regular
//  investors make payments greater than 0.25 ETH (not subtracted from this
//  triggering investor&#39;s balance).
//      Top-1 investor receives payment on each 5-th transaction.
//      Top-2 investor receives payment on each 10-th transaction.
//      Top-3 investor receives payment on each 15-th transaction.
//  2. If a function "advertise" called by any ethereum address with supplied
//  referring address and at least 0.25 ETH, and referring address makes
//  payments, referrer address will receive referral bonuses.
//  E.g., in geth console you can do the following:
//
//  var abi = eth.contract(<cyberPayABI>);
//  var contract = abi.at("<cyberPayAddress>");
//  var calldata = contract.advertise.getData("<advertisingAddress>");
//  web3.eth.sendTransaction({from:"<yourAddress>", to:"<contractAddress>",
//      data: calldata, value: web3.toWei(0.25, "ether")});
//
//  Copypaste and insert your values instead "<>" placeholders, or watch the
//  discussion, maybe more convenient way will be found later.
//
//  Referring wallet will receive an advertisement payment of 0 ETH and your
//  supplied ETH value will be invested. PLEASE NOTE that 0.25 ETH threshold
//  may be changed - see "Read Contract" tab on etherscan.io.
//
//  Please do not send payments via contracts and other unusual ways -
//  these payments may be lost. Specify enough amount of gas (100000),
//  otherwise your transaction may fail.
//
//  Initial GAIN:                               4%
//  Project Fee:                                3% from payouts
//  Minimum investment:                         No limit
//  Other questions:                            apiman45445 at protonmail.com
//

contract CyberPayTest {
	// Generate public getters for game settings and stats
	address public master = msg.sender;
	uint256 public round = 0;
	uint256 public payoutFee;
	uint256 public vipBonus;
	uint256 public referralBonus;
	uint256 public investorGain;
	uint256 public vipThreshold;
	uint256 public minBonusTrigger;
	uint256 public investorCount;
	uint256 public constant avgMinedPerDay = 5900; 
    // Hide some data from public access to prevent manipulations
	mapping(uint256 => mapping(address => Investor)) private investors;
	mapping(uint256 => mapping(address => address)) private referrals;
	address[3] private vipBoard;
	uint256 private vipRoulett;
	bool private lastRound = false;

	struct Investor {
		uint256 deposit;
		uint256 block;
	}

	function globalReinitialization() private {
		payoutFee = 3;
		vipBonus = 5;
		referralBonus = 3;
		investorGain = 4;
		vipThreshold = 5;
		minBonusTrigger = 0.25 ether;
		investorCount = 0;
		vipBoard = [master, master, master];
		vipRoulett = vipThreshold * vipBoard.length;
	}

	constructor () public {
		globalReinitialization();
	}

	//
	// Administration
	//

	event LogMasterRetired(address, address, address);
	event LogPayoutFeeChanged(address, uint256, uint256);
	event LogVIPBonusChanged(address, uint256, uint256);
	event LogReferralBonusChanged(address, uint256, uint256);
	event LogSetInvestorGain(address, uint256, uint256);
	event LogSetVIPThreshold(address, uint256, uint256);
	event LogSetMinBonusTrigger(address, uint256, uint256);

	modifier asMaster {
		require(msg.sender == master, "unauthorized function call");
		_;
	}

	function retireMaster(address newMaster) public asMaster {
		emit LogMasterRetired(msg.sender, master, newMaster);
		master = newMaster;
	}

	function setPayoutFee(uint256 newPayoutFee) public asMaster {
		require((newPayoutFee > 0) && (newPayoutFee <= 10));
		emit LogPayoutFeeChanged(msg.sender, payoutFee, newPayoutFee);
		payoutFee = newPayoutFee;
	}

	function setVIPBonus(uint256 newVIPBonus) public asMaster {
		require((newVIPBonus > 0) && (newVIPBonus <= 10));
		emit LogVIPBonusChanged(msg.sender, vipBonus, newVIPBonus);
		vipBonus = newVIPBonus;
	}

	function setReferralBonus(uint256 newRefBonus) public asMaster {
		require((newRefBonus > 0) && (newRefBonus <= 10));
		emit LogReferralBonusChanged(msg.sender, referralBonus, newRefBonus);
		referralBonus = newRefBonus;
	}

	function setInvestorGain(uint256 newInvestorGain) public asMaster {
		require((newInvestorGain > 0) && (newInvestorGain <= 5));
		emit LogSetInvestorGain(msg.sender, investorGain, newInvestorGain);
		investorGain = newInvestorGain;
	}

	function setVIPThreshold(uint256 newVIPThreshold) public asMaster {
		require(newVIPThreshold > 0);
		emit LogSetVIPThreshold(msg.sender, vipThreshold, newVIPThreshold);
		vipThreshold = newVIPThreshold;
	}

	function setMinBonusTrigger(uint256 newMinBonusTrg) public asMaster {
		emit LogSetMinBonusTrigger(msg.sender, minBonusTrigger, newMinBonusTrg);
		minBonusTrigger = newMinBonusTrg;
	}

	//
	// Game logic
	//

	event LogReferralBonus(address, address, uint256);
	event LogAdvertisement(address, address, uint256);
	event LogPayoutError(address, address, string);
	event LogNewInvestor(address, uint256);
	event LogVIPBoardChange(address, uint256, address, uint256,
							address, uint256, address, uint256);

	function payoutBonuses() private {
		// VIP bonus payout, if any
		if (vipRoulett % vipThreshold == 0) {
			uint256 bonusAmount = (msg.value * vipBonus) / 100;
			uint256 vipIdx = vipRoulett / vipThreshold;
			if (vipBoard[vipIdx] == msg.sender) { // VIPs do not pay to itself
				emit LogPayoutError(msg.sender, vipBoard[vipIdx],
					"VIP triggered payout to itself, do nothing");
				return;
			}
			payoutBalanceCheck(vipBoard[vipIdx], bonusAmount);
		}
		vipRoulett--;
		if (vipRoulett == 0)
			vipRoulett = vipThreshold * vipBoard.length;
	}

	function payoutReferrer() private {
		uint256 bonusAmount = (msg.value * referralBonus) / 100;
		address referrer = referrals[round][msg.sender];
		emit LogReferralBonus(msg.sender, referrer, bonusAmount);
		payoutBalanceCheck(referrer, bonusAmount);
	}

	function payoutBalanceCheck(address to, uint256 value) private {
		if (value > address(this).balance) {
			if (lastRound)
				selfdestruct(master);
			else
				globalReinitialization();
			round++;
			return;
		}
		to.transfer(value);
	} 

	function payoutWithFee(uint256 value) private {
		// Transfer project fee and investor income
		uint256 feeAmount = (value * payoutFee) / 100;
		payoutBalanceCheck(master, feeAmount);
		payoutBalanceCheck(msg.sender, value - feeAmount);
	}

	event LogPayoutDivs(address, uint256, uint256, uint256, uint256);

	function processDividends() private {
		if (investors[round][msg.sender].deposit != 0) {
			// ((investorGain% from deposit) * minedBlocks) / avgMinedPerDay
			uint256 deposit = investors[round][msg.sender].deposit;
			uint256 previousBlock = investors[round][msg.sender].block;
			uint256 minedBlocks = block.number - previousBlock;
			uint256 dailyIncome = (deposit * investorGain) / 100;
			uint256 divsAmount = (dailyIncome * minedBlocks) / avgMinedPerDay;
			emit LogPayoutDivs(msg.sender, deposit, minedBlocks, dailyIncome, divsAmount);
			payoutWithFee(divsAmount);	
		}
		else if (msg.value != 0) {
			emit LogNewInvestor(msg.sender, ++investorCount);
		}
		investors[round][msg.sender].block = block.number;
		investors[round][msg.sender].deposit += msg.value;
	}

	function updateVIPBoard() private {
		uint256 candidateBalance = investors[round][msg.sender].deposit;
		uint8 changed = 0;
		for (uint8 idx = 0; idx < vipBoard.length; idx++) {
			address vipAddress = vipBoard[idx];
			uint256 vipBalance = investors[round][vipAddress].deposit;
			// Add candidate if greater balance and keep array sorted
			if (candidateBalance > vipBalance) {
				vipBoard[idx] = msg.sender;
				candidateBalance = vipBalance;
				changed |= 1;
			}
		}
		if (changed != 0)
			emit LogVIPBoardChange(msg.sender, msg.value,
				vipBoard[0], investors[round][vipBoard[0]].deposit,
				vipBoard[1], investors[round][vipBoard[1]].deposit,
				vipBoard[2], investors[round][vipBoard[2]].deposit);
	}

	function advertise(address targetAddress) external payable {
		// Any violation results in failed transaction
		if (msg.value < minBonusTrigger) {
			emit LogPayoutError(msg.sender, targetAddress,
				"Need more ETH to make an advertiement");
			revert();
		}
		if (investors[round][targetAddress].deposit != 0) {
			emit LogPayoutError(msg.sender, targetAddress,
				"Advertising address is already an investor");
			revert();
		}
		if (referrals[round][targetAddress] != 0) {
			emit LogPayoutError(msg.sender, targetAddress,
				"Address already advertised");
			revert();
		}
		emit LogAdvertisement(msg.sender, targetAddress, msg.value);
		targetAddress.transfer(0);
	}

	function () external payable {
		if (msg.value >= minBonusTrigger) {
			payoutBonuses();
			if (referrals[round][msg.sender] != 0)
				payoutReferrer();
		}
		processDividends();
		updateVIPBoard();
	} 
}