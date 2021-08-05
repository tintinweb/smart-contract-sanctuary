/**
 *Submitted for verification at Etherscan.io on 2020-07-09
*/

pragma solidity ^0.6.1;

interface MinereumContract {
  function transfer(address _to, uint256 _value) external;
}

interface External1 {
  function mintNewCoins(uint256 _amount) external;
  function setStakingOwner() external;
}

interface Genesis {
	function isAnyGenesisAddress ( address _address ) external view returns ( bool success );
	function isGenesisAddressLevel1 ( address _address ) external view returns ( bool success );
	function isGenesisAddressLevel2 ( address _address ) external view returns ( bool success );
	function isGenesisAddressLevel3 ( address _address ) external view returns ( bool success );
}

interface PublicCalls {
	function stakeBalances ( address ) external view returns ( uint256 );
}

contract MinereumStaking
{
	
uint256[] public mnePerDay = new uint256[](365);
uint256[] public maxInterestRate = new uint256[](365);

address[] public participatedAddress;
address[] public bonusAddress;

mapping (address => uint256[]) public daysParticipated;
mapping (address => uint256[]) public mneSentPerDay;
mapping (address => uint256[]) public Bonus;
mapping (address => uint256[]) public BonusDay;
mapping (address => address[]) public BonusFrom;
mapping (address => uint256[]) public BonusAmount;
mapping (address => uint256) public AddressBonus;
mapping (address => bool[]) public StakingPaid;
mapping (address => bool) public BonusPaid;
uint256 public startDate = 1594512000;
uint256 public contingency = 0;
uint256 public overallMNEStaking = 0;
uint256 public overallBonus = 0;
uint256 public referralRate = 25;
uint256 public referrerRateNormal = 30;
uint256 public referrerRateLevel2 = 40;
uint256 public referrerRateLevel3 = 50;
uint256 public referrerRateShare = 60;
uint256 public newStakingCoins;
uint256 public newBonusCoins;
uint256 public paidStakingCoins;
MinereumContract public mneContract;
External1 public external1;
Genesis public gn;
PublicCalls public pc;
address public updaterAddress = 0x0000000000000000000000000000000000000000;
bool public blockPayouts = false;
bool public blockStaking = false;

constructor() public
{
	setUpdater();
	mneContract = MinereumContract(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
	//external1 = External1(0x0000000000000000000000000000000000000000);
	//external1.setStakingOwner();
	gn = Genesis(0xa6be27538A28114Fe03EB7ADE9AdfE53164f2a4c);
	pc = PublicCalls(0x90E340e2d11E6Eb1D99E34D122D6fE0fEF3213fd);
}

function updateStartDate(uint _startDate) public
{
	if (msg.sender == updaterAddress)
	{
		startDate = _startDate;		
	}
	else
	{
		revert();
	}
}

function updateVars(bool _blockPayouts, bool _blockStaking, uint256 _referralRate, uint256 _referrerRateNormal, uint256 _referrerRateLevel2, uint256 _referrerRateLevel3, uint256 _referrerRateShare, uint256 _contingency) public
{
	if (msg.sender == updaterAddress)
	{
		blockPayouts = _blockPayouts;
		blockStaking = _blockStaking;
		referralRate = _referralRate;
		referrerRateNormal = _referrerRateNormal;
		referrerRateLevel2 = _referrerRateLevel2;
		referrerRateLevel3 = _referrerRateLevel3;
		referrerRateShare = _referrerRateShare;
		contingency = _contingency;
	}
	else
	{
		revert();
	}
}
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
function updateExternal1(address _address) public {if (tx.origin == updaterAddress) {external1 = External1(_address); external1.setStakingOwner(); } else revert();}
function updateGenesis(address _address) public {if (tx.origin == updaterAddress) {gn = Genesis(_address); } else revert();}
function updatePublicCalls(address _address) public {if (tx.origin == updaterAddress) {pc = PublicCalls(_address); } else revert();}
function updateMneContract(address _address) public {if (tx.origin == updaterAddress) {mneContract = MinereumContract(_address); } else revert();}

function daysParticipatedGet(address _address) public view returns (uint256[] memory) { return daysParticipated[_address]; }
function mneSentPerDayGet(address _address) public view returns (uint256[] memory) { return mneSentPerDay[_address]; }
function BonusGet(address _address) public view returns (uint256[] memory) { return Bonus[_address]; }
function BonusDayGet(address _address) public view returns (uint256[] memory) { return BonusDay[_address]; }
function BonusFromGet(address _address) public view returns (address[] memory) { return BonusFrom[_address]; }
function BonusAmountGet(address _address) public view returns (uint256[] memory) { return BonusAmount[_address]; }
function AddressBonusGet(address _address) public view returns (uint256) { return AddressBonus[_address]; }
function StakingPaidGet(address _address) public view returns (bool[] memory) { return StakingPaid[_address]; }
function BonusPaidGet(address _address) public view returns (bool) { return BonusPaid[_address]; }

function daysParticipatedGetAt(address _address, uint i) public view returns (uint256) { return daysParticipated[_address][i]; }
function mneSentPerDayGetAt(address _address, uint i) public view returns (uint256) { return mneSentPerDay[_address][i]; }
function BonusGetAt(address _address, uint i) public view returns (uint256) { return Bonus[_address][i]; }
function BonusDayGetAt(address _address, uint i) public view returns (uint256) { return BonusDay[_address][i]; }
function BonusFromGetAt(address _address, uint i) public view returns (address) { return BonusFrom[_address][i]; }
function BonusAmountGetAt(address _address, uint i) public view returns (uint256) { return BonusAmount[_address][i]; }
function StakingPaidGetAt(address _address, uint i) public view returns (bool) { return StakingPaid[_address][i]; }

function daysParticipatedLength(address _address) public view returns (uint256) { return daysParticipated[_address].length; }
function mneSentPerDayLength(address _address) public view returns (uint256) { return mneSentPerDay[_address].length; }
function BonusLength(address _address) public view returns (uint256) { return Bonus[_address].length; }
function BonusDayLength(address _address) public view returns (uint256) { return BonusDay[_address].length; }
function BonusFromLength(address _address) public view returns (uint256) { return BonusFrom[_address].length; }
function BonusAmountLength(address _address) public view returns (uint256) { return BonusAmount[_address].length; }
function StakingPaidLength(address _address) public view returns (uint256) { return StakingPaid[_address].length; }
function mnePerDayLength() public view returns (uint256) { return mnePerDay.length; }
function maxInterestRateLength() public view returns (uint256) { return maxInterestRate.length; }
function participatedAddressLength() public view returns (uint256) { return participatedAddress.length; }
function bonusAddressLength() public view returns (uint256) { return bonusAddress.length; }

function GetCurrentDay() public view returns (uint256)
{
	uint currentPeriod;
	
	if (block.timestamp < startDate)	
		currentPeriod = 0;
	else
		currentPeriod = (block.timestamp - startDate) / 86400;
	
	
	return currentPeriod;
}

function TransferAllFundsOut(address _address, uint256 _amount) public
{		
	if (msg.sender == updaterAddress)
	{
		mneContract.transfer(_address, _amount); //in case of migration to another contract	
	}
	else
	{
		revert();
	}
}
	
function startStaking(address _sender, uint256 _amountToStake, address[] memory _addressList, uint256[] memory uintList) public {
	if (blockStaking) revert('not active'); //in case of migration to another contract
	
	if (msg.sender != address(mneContract)) revert();
	
	uint currentPeriod;
	
	if (block.timestamp < startDate)	
		currentPeriod = 0;
	else
		currentPeriod = (block.timestamp - startDate) / 86400;
	
	if (currentPeriod > 364) revert('invalid period');
	
	mnePerDay[currentPeriod] += _amountToStake;
	
	if (daysParticipated[_sender].length > 0)
	{
	    if (daysParticipated[_sender][daysParticipated[_sender].length -1] == currentPeriod)
	    {
	        mneSentPerDay[_sender][daysParticipated[_sender].length -1] += _amountToStake;
	    }
	    else
	    {
	        daysParticipated[_sender].push(currentPeriod);
    	    mneSentPerDay[_sender].push(_amountToStake);
    	    StakingPaid[_sender].push(false);       
	    }
	}
	else
	{
	    participatedAddress.push(_sender);
	    daysParticipated[_sender].push(currentPeriod);
	    mneSentPerDay[_sender].push(_amountToStake);
	    StakingPaid[_sender].push(false);   
	}
	
	overallMNEStaking += _amountToStake;
	
	if (_addressList.length > 1)
	{
		if (_sender == _addressList[1] || _addressList[1] == address(this) || _addressList[1] == address(mneContract)) revert('invalid referal');
		
		uint bonusAmountReferral = _amountToStake * referralRate / 100;	

		uint referrerRateFinal;
		
		if (pc.stakeBalances(_addressList[1]) > 0)
			referrerRateFinal = referrerRateShare;
		else if (!gn.isAnyGenesisAddress(_addressList[1]))
			referrerRateFinal = referrerRateNormal;
		else if (gn.isGenesisAddressLevel1(_addressList[1]))		
			referrerRateFinal = referrerRateNormal;
		else if (gn.isGenesisAddressLevel2(_addressList[1]))		
			referrerRateFinal = referrerRateLevel2;
		else if (gn.isGenesisAddressLevel3(_addressList[1]))		
			referrerRateFinal = referrerRateLevel3;
		
		uint bonusAmountReferrer = _amountToStake * referrerRateFinal / 100;
		
		BonusDay[_sender].push(currentPeriod);
		BonusFrom[_sender].push(_addressList[1]);
		BonusAmount[_sender].push(bonusAmountReferral);
		BonusPaid[_sender] = false;
		
		if (AddressBonus[_sender] == 0)
			bonusAddress.push(_sender);
		
		AddressBonus[_sender] += bonusAmountReferral;
		
		BonusDay[_addressList[1]].push(currentPeriod);
		BonusFrom[_addressList[1]].push(_sender);
		BonusAmount[_addressList[1]].push(bonusAmountReferrer);
		BonusPaid[_addressList[1]] = false;
		
		if (AddressBonus[_addressList[1]] == 0)
			bonusAddress.push(_addressList[1]);
	
		AddressBonus[_addressList[1]] += bonusAmountReferrer;
		
		overallBonus += bonusAmountReferral + bonusAmountReferrer;
	}	
}

function PayoutAllStaking(address _address) public {
	uint i = 0;
	while (i < StakingPaid[msg.sender].length)
	{
		PayoutStaking(i, _address);
		i++;
	}
}

function PayoutStaking(uint i, address _address) public {
	if (blockPayouts) revert('payouts blocked'); //in case of migration to another contract
	
	if (daysParticipated[msg.sender].length == 0) revert('No Staking');
	
	if (block.timestamp >= startDate + (daysParticipated[msg.sender][0] * 86400) + 31556926 + contingency)
	{
		if (StakingPaid[msg.sender][i]) revert('Stake already paid');
		
		uint interestRateToPay = mneSentPerDay[msg.sender][i] * maxInterestRate[daysParticipated[msg.sender][i]] * 1000000000000000 / mnePerDay[daysParticipated[msg.sender][i]];
		uint coinsToMint = mneSentPerDay[msg.sender][i] * interestRateToPay / 1000000000000000 / 100;
		uint amountToPay = mneSentPerDay[msg.sender][i] + coinsToMint;
		
		external1.mintNewCoins(coinsToMint);
		
		if (_address != 0x0000000000000000000000000000000000000000)			
			mneContract.transfer(_address, amountToPay);
		else
			mneContract.transfer(msg.sender, amountToPay);
		
		newStakingCoins += coinsToMint;
		paidStakingCoins += amountToPay;
		StakingPaid[msg.sender][i] = true;
	}
	else
	{
		revert('Payout Date Not Valid');
	}
}

function AmountMNESent(address _address, bool _excludeCurrent, bool _currentOnly) public view returns (uint256)
{
	if (mneSentPerDay[_address].length == 0) return 0;
	
	uint currentDay = GetCurrentDay();
	
	if (_currentOnly)
	{
		uint lasti = daysParticipated[_address][daysParticipated[_address].length - 1];
		if (lasti == currentDay)
			return mneSentPerDay[_address][lasti];
	}
	else
	{
		uint j = 0;
		uint finalAmount = 0;
		while (j < mneSentPerDay[_address].length)
		{
			if ((daysParticipated[_address][j] == currentDay) && _excludeCurrent) continue;
			
			finalAmount += mneSentPerDay[_address][j];
			
			j++;
		}
		return finalAmount;
	}	
	return 0;
}

function AmountToPayStaking(address _address, bool _checkID, uint i, bool _excludeCurrent, bool _currentOnly) public view returns (uint256)
{
	if (daysParticipated[_address].length == 0) return 0;
	
	uint currentDay = GetCurrentDay();
	if (_currentOnly)
	{
		uint lasti = daysParticipated[_address][daysParticipated[_address].length - 1];
		if (lasti == currentDay)
		{			
			uint interestRateToPay = mneSentPerDay[_address][lasti] * maxInterestRate[daysParticipated[_address][lasti]] * 1000000000000000 / mnePerDay[daysParticipated[_address][lasti]];
			uint coinsToMint = mneSentPerDay[_address][lasti] * interestRateToPay / 1000000000000000 / 100;
			uint amountToPay = mneSentPerDay[_address][lasti] + coinsToMint;
			return amountToPay;				
		}
		else
		{
			return 0;
		}
	}	
	else if (_checkID)
	{
		uint interestRateToPay = mneSentPerDay[_address][i] * maxInterestRate[daysParticipated[_address][i]] * 1000000000000000 / mnePerDay[daysParticipated[_address][i]];
		uint coinsToMint = mneSentPerDay[_address][i] * interestRateToPay / 1000000000000000 / 100;
		uint amountToPay = mneSentPerDay[_address][i] + coinsToMint;
		return amountToPay;
	}
	else
	{
		uint j = 0;
		uint finalAmount = 0;
		while (j < mneSentPerDay[_address].length)
		{
			if ((daysParticipated[_address][j] == currentDay) && _excludeCurrent) continue;
			if (!StakingPaid[_address][j])
			{
				uint interestRateToPay = mneSentPerDay[_address][j] * maxInterestRate[daysParticipated[_address][j]] * 1000000000000000 / mnePerDay[daysParticipated[_address][j]];
				uint coinsToMint = mneSentPerDay[_address][j] * interestRateToPay / 1000000000000000 / 100;
				uint amountToPay = mneSentPerDay[_address][j] + coinsToMint;
				finalAmount += amountToPay;
			}
			j++;
		}
		return finalAmount;
	}	
}

function AmountToPayBonus(address _address) public view returns (uint256)
{
	if (BonusPaid[_address])
		return 0;
	else
		return AddressBonus[_address];
}

function DateStakingPayoutPossible(address _address) public view returns (uint256)
{
	if (daysParticipated[_address].length == 0)
		return 0;
	else
		return startDate + (daysParticipated[_address][0] * 86400) + 31556926 + contingency;
}

function DateBonusPayoutPossible(address _address) public view returns (uint256)
{
	if (BonusDay[_address].length == 0)
		return 0;
	else
		return startDate + (BonusDay[_address][0] * 86400) + 31556926 + contingency;
}

function PayoutBonus(address _address) public {
	if (blockPayouts) revert('payouts blocked'); //in case of migration to another contract
	
	if (BonusDay[msg.sender].length == 0) revert('No Bonus');
	
	if (block.timestamp >= startDate + (BonusDay[msg.sender][0] * 86400) + 31556926 + contingency)
	{
		if (BonusPaid[msg.sender]) revert('Bonus already paid');
		
		external1.mintNewCoins(AddressBonus[msg.sender]);
		
		if (_address != 0x0000000000000000000000000000000000000000)			
			mneContract.transfer(_address, AddressBonus[msg.sender]);
		else
			mneContract.transfer(msg.sender, AddressBonus[msg.sender]);
		
		newBonusCoins += AddressBonus[msg.sender];
		BonusPaid[msg.sender] = true;
	}
	else
	{
		revert('Payout Date Not Valid');
	}
}

function FillMaxInterestRate1() public
{	
	maxInterestRate[0] = 1000;
	maxInterestRate[1] = 990;
	maxInterestRate[2] = 980;
	maxInterestRate[3] = 970;
	maxInterestRate[4] = 960;
	maxInterestRate[5] = 950;
	maxInterestRate[6] = 941;
	maxInterestRate[7] = 932;
	maxInterestRate[8] = 922;
	maxInterestRate[9] = 913;
	maxInterestRate[10] = 904;
	maxInterestRate[11] = 895;
	maxInterestRate[12] = 886;
	maxInterestRate[13] = 877;
	maxInterestRate[14] = 868;
	maxInterestRate[15] = 860;
	maxInterestRate[16] = 851;
	maxInterestRate[17] = 842;
	maxInterestRate[18] = 834;
	maxInterestRate[19] = 826;
	maxInterestRate[20] = 817;
	maxInterestRate[21] = 809;
	maxInterestRate[22] = 801;
	maxInterestRate[23] = 793;
	maxInterestRate[24] = 785;
	maxInterestRate[25] = 777;
	maxInterestRate[26] = 770;
	maxInterestRate[27] = 762;
	maxInterestRate[28] = 754;
	maxInterestRate[29] = 747;
	maxInterestRate[30] = 739;
	maxInterestRate[31] = 732;
	maxInterestRate[32] = 724;
	maxInterestRate[33] = 717;
	maxInterestRate[34] = 710;
	maxInterestRate[35] = 703;
	maxInterestRate[36] = 696;
	maxInterestRate[37] = 689;
	maxInterestRate[38] = 682;
	maxInterestRate[39] = 675;
	maxInterestRate[40] = 668;
	maxInterestRate[41] = 662;
	maxInterestRate[42] = 655;
	maxInterestRate[43] = 649;
	maxInterestRate[44] = 642;
	maxInterestRate[45] = 636;
	maxInterestRate[46] = 629;
	maxInterestRate[47] = 623;
	maxInterestRate[48] = 617;
	maxInterestRate[49] = 611;
	maxInterestRate[50] = 605;
	maxInterestRate[51] = 598;
	maxInterestRate[52] = 592;
	maxInterestRate[53] = 587;
	maxInterestRate[54] = 581;
	maxInterestRate[55] = 575;
	maxInterestRate[56] = 569;
	maxInterestRate[57] = 563;
	maxInterestRate[58] = 558;
	maxInterestRate[59] = 552;
	maxInterestRate[60] = 547;
	maxInterestRate[61] = 541;
	maxInterestRate[62] = 536;
	maxInterestRate[63] = 530;
	maxInterestRate[64] = 525;
	maxInterestRate[65] = 520;
	maxInterestRate[66] = 515;
	maxInterestRate[67] = 509;
	maxInterestRate[68] = 504;
	maxInterestRate[69] = 499;
	maxInterestRate[70] = 494;
	maxInterestRate[71] = 489;
	maxInterestRate[72] = 484;
	maxInterestRate[73] = 480;
	maxInterestRate[74] = 475;
	maxInterestRate[75] = 470;
	maxInterestRate[76] = 465;
	maxInterestRate[77] = 461;
	maxInterestRate[78] = 456;
	maxInterestRate[79] = 452;
	maxInterestRate[80] = 447;
	maxInterestRate[81] = 443;
	maxInterestRate[82] = 438;
	maxInterestRate[83] = 434;
	maxInterestRate[84] = 429;
	maxInterestRate[85] = 425;
	maxInterestRate[86] = 421;
	maxInterestRate[87] = 417;
	maxInterestRate[88] = 412;
	maxInterestRate[89] = 408;
	maxInterestRate[90] = 404;
	maxInterestRate[91] = 400;
	maxInterestRate[92] = 396;
	maxInterestRate[93] = 392;
	maxInterestRate[94] = 388;
	maxInterestRate[95] = 384;
	maxInterestRate[96] = 381;
	maxInterestRate[97] = 377;
	maxInterestRate[98] = 373;
	maxInterestRate[99] = 369;
	maxInterestRate[100] = 366;
	maxInterestRate[101] = 362;
	maxInterestRate[102] = 358;
	maxInterestRate[103] = 355;
	maxInterestRate[104] = 351;
	maxInterestRate[105] = 348;
	maxInterestRate[106] = 344;
	maxInterestRate[107] = 341;
	maxInterestRate[108] = 337;
	maxInterestRate[109] = 334;
	maxInterestRate[110] = 331;
	maxInterestRate[111] = 327;
	maxInterestRate[112] = 324;
	maxInterestRate[113] = 321;
	maxInterestRate[114] = 317;
	maxInterestRate[115] = 314;
	maxInterestRate[116] = 311;
	maxInterestRate[117] = 308;
	maxInterestRate[118] = 305;
	maxInterestRate[119] = 302;
	maxInterestRate[120] = 299;
	maxInterestRate[121] = 296;
	maxInterestRate[122] = 293;
	maxInterestRate[123] = 290;
	maxInterestRate[124] = 287;
	maxInterestRate[125] = 284;
	maxInterestRate[126] = 281;
	maxInterestRate[127] = 279;
	maxInterestRate[128] = 276;
	maxInterestRate[129] = 273;
	maxInterestRate[130] = 270;
	maxInterestRate[131] = 268;
	maxInterestRate[132] = 265;
	maxInterestRate[133] = 262;
	maxInterestRate[134] = 260;
	maxInterestRate[135] = 257;
	maxInterestRate[136] = 254;
	maxInterestRate[137] = 252;
	maxInterestRate[138] = 249;
	maxInterestRate[139] = 247;
	maxInterestRate[140] = 244;
	maxInterestRate[141] = 242;
	maxInterestRate[142] = 239;
	maxInterestRate[143] = 237;
	maxInterestRate[144] = 235;
	maxInterestRate[145] = 232;
	maxInterestRate[146] = 230;
	maxInterestRate[147] = 228;
	maxInterestRate[148] = 225;
	maxInterestRate[149] = 223;
	maxInterestRate[150] = 221;
	maxInterestRate[151] = 219;
	maxInterestRate[152] = 217;
	maxInterestRate[153] = 214;
	maxInterestRate[154] = 212;
	maxInterestRate[155] = 210;
	maxInterestRate[156] = 208;
	maxInterestRate[157] = 206;
	maxInterestRate[158] = 204;
	maxInterestRate[159] = 202;
	maxInterestRate[160] = 200;
	maxInterestRate[161] = 198;
	maxInterestRate[162] = 196;
	maxInterestRate[163] = 194;
	maxInterestRate[164] = 192;
	maxInterestRate[165] = 190;
	maxInterestRate[166] = 188;
	maxInterestRate[167] = 186;
	maxInterestRate[168] = 184;
	maxInterestRate[169] = 182;
	maxInterestRate[170] = 181;
	maxInterestRate[171] = 179;
	maxInterestRate[172] = 177;
	maxInterestRate[173] = 175;
	maxInterestRate[174] = 173;
	maxInterestRate[175] = 172;
	maxInterestRate[176] = 170;
	maxInterestRate[177] = 168;
	maxInterestRate[178] = 167;
	maxInterestRate[179] = 165;
	maxInterestRate[180] = 163;
	maxInterestRate[181] = 162;
	maxInterestRate[182] = 160;	
}

function FillMaxInterestRate2() public
{
	maxInterestRate[183] = 158;
	maxInterestRate[184] = 157;
	maxInterestRate[185] = 155;
	maxInterestRate[186] = 154;
	maxInterestRate[187] = 152;
	maxInterestRate[188] = 151;
	maxInterestRate[189] = 149;
	maxInterestRate[190] = 148;
	maxInterestRate[191] = 146;
	maxInterestRate[192] = 145;
	maxInterestRate[193] = 143;
	maxInterestRate[194] = 142;
	maxInterestRate[195] = 140;
	maxInterestRate[196] = 139;
	maxInterestRate[197] = 138;
	maxInterestRate[198] = 136;
	maxInterestRate[199] = 135;
	maxInterestRate[200] = 133;
	maxInterestRate[201] = 132;
	maxInterestRate[202] = 131;
	maxInterestRate[203] = 130;
	maxInterestRate[204] = 128;
	maxInterestRate[205] = 127;
	maxInterestRate[206] = 126;
	maxInterestRate[207] = 124;
	maxInterestRate[208] = 123;
	maxInterestRate[209] = 122;
	maxInterestRate[210] = 121;
	maxInterestRate[211] = 119;
	maxInterestRate[212] = 118;
	maxInterestRate[213] = 117;
	maxInterestRate[214] = 116;
	maxInterestRate[215] = 115;
	maxInterestRate[216] = 114;
	maxInterestRate[217] = 112;
	maxInterestRate[218] = 111;
	maxInterestRate[219] = 110;
	maxInterestRate[220] = 109;
	maxInterestRate[221] = 108;
	maxInterestRate[222] = 107;
	maxInterestRate[223] = 106;
	maxInterestRate[224] = 105;
	maxInterestRate[225] = 104;
	maxInterestRate[226] = 103;
	maxInterestRate[227] = 102;
	maxInterestRate[228] = 101;
	maxInterestRate[229] = 100;
	maxInterestRate[230] = 99;
	maxInterestRate[231] = 98;
	maxInterestRate[232] = 97;
	maxInterestRate[233] = 96;
	maxInterestRate[234] = 95;
	maxInterestRate[235] = 94;
	maxInterestRate[236] = 93;
	maxInterestRate[237] = 92;
	maxInterestRate[238] = 91;
	maxInterestRate[239] = 90;
	maxInterestRate[240] = 89;
	maxInterestRate[241] = 88;
	maxInterestRate[242] = 87;
	maxInterestRate[243] = 86;
	maxInterestRate[244] = 86;
	maxInterestRate[245] = 85;
	maxInterestRate[246] = 84;
	maxInterestRate[247] = 83;
	maxInterestRate[248] = 82;
	maxInterestRate[249] = 81;
	maxInterestRate[250] = 81;
	maxInterestRate[251] = 80;
	maxInterestRate[252] = 79;
	maxInterestRate[253] = 78;
	maxInterestRate[254] = 77;
	maxInterestRate[255] = 77;
	maxInterestRate[256] = 76;
	maxInterestRate[257] = 75;
	maxInterestRate[258] = 74;
	maxInterestRate[259] = 74;
	maxInterestRate[260] = 73;
	maxInterestRate[261] = 72;
	maxInterestRate[262] = 71;
	maxInterestRate[263] = 71;
	maxInterestRate[264] = 70;
	maxInterestRate[265] = 69;
	maxInterestRate[266] = 69;
	maxInterestRate[267] = 68;
	maxInterestRate[268] = 67;
	maxInterestRate[269] = 66;
	maxInterestRate[270] = 66;
	maxInterestRate[271] = 65;
	maxInterestRate[272] = 64;
	maxInterestRate[273] = 64;
	maxInterestRate[274] = 63;
	maxInterestRate[275] = 63;
	maxInterestRate[276] = 62;
	maxInterestRate[277] = 61;
	maxInterestRate[278] = 61;
	maxInterestRate[279] = 60;
	maxInterestRate[280] = 59;
	maxInterestRate[281] = 59;
	maxInterestRate[282] = 58;
	maxInterestRate[283] = 58;
	maxInterestRate[284] = 57;
	maxInterestRate[285] = 57;
	maxInterestRate[286] = 56;
	maxInterestRate[287] = 55;
	maxInterestRate[288] = 55;
	maxInterestRate[289] = 54;
	maxInterestRate[290] = 54;
	maxInterestRate[291] = 53;
	maxInterestRate[292] = 53;
	maxInterestRate[293] = 52;
	maxInterestRate[294] = 52;
	maxInterestRate[295] = 51;
	maxInterestRate[296] = 51;
	maxInterestRate[297] = 50;
	maxInterestRate[298] = 50;
	maxInterestRate[299] = 49;
	maxInterestRate[300] = 49;
	maxInterestRate[301] = 48;
	maxInterestRate[302] = 48;
	maxInterestRate[303] = 47;
	maxInterestRate[304] = 47;
	maxInterestRate[305] = 46;
	maxInterestRate[306] = 46;
	maxInterestRate[307] = 45;
	maxInterestRate[308] = 45;
	maxInterestRate[309] = 44;
	maxInterestRate[310] = 44;
	maxInterestRate[311] = 43;
	maxInterestRate[312] = 43;
	maxInterestRate[313] = 43;
	maxInterestRate[314] = 42;
	maxInterestRate[315] = 42;
	maxInterestRate[316] = 41;
	maxInterestRate[317] = 41;
	maxInterestRate[318] = 40;
	maxInterestRate[319] = 40;
	maxInterestRate[320] = 40;
	maxInterestRate[321] = 39;
	maxInterestRate[322] = 39;
	maxInterestRate[323] = 38;
	maxInterestRate[324] = 38;
	maxInterestRate[325] = 38;
	maxInterestRate[326] = 37;
	maxInterestRate[327] = 37;
	maxInterestRate[328] = 37;
	maxInterestRate[329] = 36;
	maxInterestRate[330] = 36;
	maxInterestRate[331] = 35;
	maxInterestRate[332] = 35;
	maxInterestRate[333] = 35;
	maxInterestRate[334] = 34;
	maxInterestRate[335] = 34;
	maxInterestRate[336] = 34;
	maxInterestRate[337] = 33;
	maxInterestRate[338] = 33;
	maxInterestRate[339] = 33;
	maxInterestRate[340] = 32;
	maxInterestRate[341] = 32;
	maxInterestRate[342] = 32;
	maxInterestRate[343] = 31;
	maxInterestRate[344] = 31;
	maxInterestRate[345] = 31;
	maxInterestRate[346] = 30;
	maxInterestRate[347] = 30;
	maxInterestRate[348] = 30;
	maxInterestRate[349] = 29;
	maxInterestRate[350] = 29;
	maxInterestRate[351] = 29;
	maxInterestRate[352] = 29;
	maxInterestRate[353] = 28;
	maxInterestRate[354] = 28;
	maxInterestRate[355] = 28;
	maxInterestRate[356] = 27;
	maxInterestRate[357] = 27;
	maxInterestRate[358] = 27;
	maxInterestRate[359] = 27;
	maxInterestRate[360] = 26;
	maxInterestRate[361] = 26;
	maxInterestRate[362] = 26;
	maxInterestRate[363] = 26;
	maxInterestRate[364] = 25;
}
}