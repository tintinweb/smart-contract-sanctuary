/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.6.1;

interface MinereumContract {
  function transfer(address _to, uint256 _value) external;
}

interface MainStaking {
  function AddressBonus ( address ) external view returns ( uint256 );
  function AddressBonusGet ( address _address ) external view returns ( uint256 );
  function AmountMNESent ( address _address, bool _excludeCurrent, bool _currentOnly ) external view returns ( uint256 );
  function AmountToPayBonus ( address _address ) external view returns ( uint256 );
  function AmountToPayStaking ( address _address, bool _checkID, uint256 i, bool _excludeCurrent, bool _currentOnly ) external view returns ( uint256 );
  function Bonus ( address, uint256 ) external view returns ( uint256 );
  function BonusAmount ( address, uint256 ) external view returns ( uint256 );
  function BonusAmountGet ( address _address ) external view returns ( uint256[] memory);
  function BonusAmountGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BonusAmountLength ( address _address ) external view returns ( uint256 );
  function BonusDay ( address, uint256 ) external view returns ( uint256 );
  function BonusDayGet ( address _address ) external view returns ( uint256[] memory);
  function BonusDayGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BonusDayLength ( address _address ) external view returns ( uint256 );
  function BonusFrom ( address, uint256 ) external view returns ( address );
  function BonusFromGet ( address _address ) external view returns ( address[] memory);
  function BonusFromGetAt ( address _address, uint256 i ) external view returns ( address );
  function BonusFromLength ( address _address ) external view returns ( uint256 );
  function BonusGet ( address _address ) external view returns ( uint256[] memory);
  function BonusGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BonusLength ( address _address ) external view returns ( uint256 );
  function BonusPaid ( address ) external view returns ( bool );
  function BonusPaidGet ( address _address ) external view returns ( bool );
  function DateBonusPayoutPossible ( address _address ) external view returns ( uint256 );
  function DateStakingPayoutPossible ( address _address ) external view returns ( uint256 );
  function FillMaxInterestRate1 (  ) external;
  function FillMaxInterestRate2 (  ) external;
  function GetCurrentDay (  ) external view returns ( uint256 );
  function PayoutAllStaking ( address _address ) external;
  function PayoutBonus ( address _address ) external;
  function PayoutStaking ( uint256 i, address _address ) external;
  function StakingPaid ( address, uint256 ) external view returns ( bool );
  function StakingPaidGet ( address _address ) external view returns ( bool[] memory);
  function StakingPaidGetAt ( address _address, uint256 i ) external view returns ( bool );
  function StakingPaidLength ( address _address ) external view returns ( uint256 );
  function TransferAllFundsOut ( address _address, uint256 _amount ) external;
  function blockPayouts (  ) external view returns ( bool );
  function blockStaking (  ) external view returns ( bool );
  function bonusAddress ( uint256 ) external view returns ( address );
  function bonusAddressLength (  ) external view returns ( uint256 );
  function contingency (  ) external view returns ( uint256 );
  function daysParticipated ( address, uint256 ) external view returns ( uint256 );
  function daysParticipatedGet ( address _address ) external view returns ( uint256[] memory);
  function daysParticipatedGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function daysParticipatedLength ( address _address ) external view returns ( uint256 );
  function external1 (  ) external view returns ( address );
  function gn (  ) external view returns ( address );
  function maxInterestRate ( uint256 ) external view returns ( uint256 );
  function maxInterestRateLength (  ) external view returns ( uint256 );
  function mneContract (  ) external view returns ( address );
  function mnePerDay ( uint256 ) external view returns ( uint256 );
  function mnePerDayLength (  ) external view returns ( uint256 );
  function mneSentPerDay ( address, uint256 ) external view returns ( uint256 );
  function mneSentPerDayGet ( address _address ) external view returns ( uint256[] memory);
  function mneSentPerDayGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function mneSentPerDayLength ( address _address ) external view returns ( uint256 );
  function newBonusCoins (  ) external view returns ( uint256 );
  function newStakingCoins (  ) external view returns ( uint256 );
  function overallBonus (  ) external view returns ( uint256 );
  function overallMNEStaking (  ) external view returns ( uint256 );
  function paidStakingCoins (  ) external view returns ( uint256 );
  function participatedAddress ( uint256 ) external view returns ( address );
  function participatedAddressLength (  ) external view returns ( uint256 );
  function pc (  ) external view returns ( address );
  function referralRate (  ) external view returns ( uint256 );
  function referrerRateLevel2 (  ) external view returns ( uint256 );
  function referrerRateLevel3 (  ) external view returns ( uint256 );
  function referrerRateNormal (  ) external view returns ( uint256 );
  function referrerRateShare (  ) external view returns ( uint256 );
  function setUpdater (  ) external;
  function startDate (  ) external view returns ( uint256 );
  function startStaking ( address _sender, uint256 _amountToStake, address[] calldata _addressList, uint256[] calldata uintList) external;
  function updateExternal1 ( address _address ) external;
  function updateGenesis ( address _address ) external;
  function updateMneContract ( address _address ) external;
  function updatePublicCalls ( address _address ) external;
  function updateStartDate ( uint256 _startDate ) external;
  function updateVars ( bool _blockPayouts, bool _blockStaking, uint256 _referralRate, uint256 _referrerRateNormal, uint256 _referrerRateLevel2, uint256 _referrerRateLevel3, uint256 _referrerRateShare, uint256 _contingency ) external;
  function updaterAddress (  ) external view returns ( address );
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

contract MinereumStakingPayout
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
mapping (address => bool) public RealStakingPaid;
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
MainStaking public mainStk;
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
	mainStk = MainStaking(0xCb2Aee9A6dAC92c1076f642FE4f2c9bcFFc81D9e);
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
	return 0;
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
		
}

function PayoutAllStaking(address _address) public {
	uint i = 0;
	if (RealStakingPaid[msg.sender]) revert('Stake already paid');
	while (i < mainStk.StakingPaidLength(msg.sender))
	{
		PayoutStaking(i, _address);
		i++;
	}
}

function PayoutStaking(uint i, address _address) private {
	if (blockPayouts) revert('payouts blocked'); //in case of migration to another contract
	
	if (mainStk.daysParticipatedLength(msg.sender) == 0) revert('No Staking');
	
	if (block.timestamp >= mainStk.startDate() + (mainStk.daysParticipatedGetAt(msg.sender, 0) * 86400) + 31556926 + mainStk.contingency())
	{
		uint interestRateToPay = mainStk.mneSentPerDayGetAt(msg.sender,i) * mainStk.maxInterestRate(mainStk.daysParticipatedGetAt(msg.sender, i)) * 1000000000000000 / mainStk.mnePerDay(mainStk.daysParticipatedGetAt(msg.sender, i));
		uint coinsToMint = mainStk.mneSentPerDayGetAt(msg.sender, i) * interestRateToPay / 1000000000000000 / 100;
		uint amountToPay = mainStk.mneSentPerDay(msg.sender, i) + coinsToMint;
		
		if (_address != 0x0000000000000000000000000000000000000000)			
			mneContract.transfer(_address, amountToPay);
		else
			mneContract.transfer(msg.sender, amountToPay);
		
		newStakingCoins += coinsToMint;
		paidStakingCoins += amountToPay;
		RealStakingPaid[msg.sender] = true;
	}
	else
	{
		revert('Payout Date Not Valid');
	}
}
function AmountMNESent(address _address, bool _excludeCurrent, bool _currentOnly) public view returns (uint256)
{
	
	return 0;
}

function AmountToPayStaking(address _address, bool _checkID, uint i, bool _excludeCurrent, bool _currentOnly) public view returns (uint256)
{
	return 0;
}

function AmountToPayBonus(address _address) public view returns (uint256)
{
	
}

function DateStakingPayoutPossible(address _address) public view returns (uint256)
{
	
}

function DateBonusPayoutPossible(address _address) public view returns (uint256)
{
	return 0;
}

function PayoutBonus(address _address) public {
	
}
}