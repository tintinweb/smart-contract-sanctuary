/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.6.1;

interface MinereumContract {
  function transfer(address _to, uint256 _value) external;
}

interface External1 {
  function mintNewCoins(uint256 _amount) external;
  function setBondOwner() external;
}

interface Genesis {
	function availableBalanceOf ( address _address ) external view returns ( uint256 Balance );
}

interface MainBond {
  function BlockBonds (  ) external view returns ( bool );
  function BlockPayouts (  ) external view returns ( bool );
  function BondMNE ( address, uint256 ) external view returns ( uint256 );
  function BondMNEGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondPayoutsBondID ( address, uint256 ) external view returns ( uint256 );
  function BondPayoutsBondIDGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondPayoutsBondIDLength ( address _address ) external view returns ( uint256 );
  function BondPayoutsDate ( address, uint256 ) external view returns ( uint256 );
  function BondPayoutsDateGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondPayoutsMNE ( address, uint256 ) external view returns ( uint256 );
  function BondPayoutsMNEGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondPayoutsPaid ( address, uint256 ) external view returns ( bool );
  function BondPayoutsPaidDate ( address, uint256 ) external view returns ( uint256 );
  function BondPayoutsPaidDateGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondPayoutsPaidGetAt ( address _address, uint256 i ) external view returns ( bool );
  function BondStartDate ( address, uint256 ) external view returns ( uint256 );
  function BondStartDateGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondYearsType ( address, uint256 ) external view returns ( uint256 );
  function BondYearsTypeGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BondYearsTypeLength ( address _address ) external view returns ( uint256 );
  function BondYield ( address, uint256 ) external view returns ( uint256 );
  function BondYieldGetAt ( address _address, uint256 i ) external view returns ( uint256 );
  function BonusAmount ( address, uint256 ) external view returns ( uint256 );
  function BonusDay ( address, uint256 ) external view returns ( uint256 );
  function BonusDayLength ( address _address ) external view returns ( uint256 );
  function BonusFrom ( address, uint256 ) external view returns ( address );
  function BonusPaid ( address, uint256 ) external view returns ( bool );
  function BonusPaidDate ( address, uint256 ) external view returns ( uint256 );
  function BuildBond ( address _address, uint256 _bondID ) external;
  function FiveYearsBondBuiltCount (  ) external view returns ( uint256 );
  function FiveYearsBondCount (  ) external view returns ( uint256 );
  function FiveYearsYield (  ) external view returns ( uint256 );
  function GetBonds ( address _address ) external view returns ( uint256[] memory _BondIDs, uint256[] memory _BondYearsType, uint256[] memory _BondMNE, uint256[] memory _BondStartDate, uint256[] memory _BondYield );
  function GetPayouts ( address _address ) external view returns ( uint256[] memory _BondPayoutsBondID, uint256[] memory _BondPayoutsMNE, uint256[] memory _BondPayoutsDate, bool[] memory _BondPayoutsPaid, uint256[] memory _BondPayoutsPaidDate );
  function GetTotalBonds (  ) external view returns ( uint256 );
  function GetTotalMNE (  ) external view returns ( uint256 );
  function MNEFiveYearsBondsCount (  ) external view returns ( uint256 );
  function MNEOneYearBondsCount (  ) external view returns ( uint256 );
  function MNEThreeYearsBondsCount (  ) external view returns ( uint256 );
  function OneYearBondBuiltCount (  ) external view returns ( uint256 );
  function OneYearBondCount (  ) external view returns ( uint256 );
  function OneYearYield (  ) external view returns ( uint256 );
  function OpenBonusValue ( address _address ) external view returns ( uint256 );
  function PayoutAllValidBondPayouts ( address _address ) external;
  function PayoutBond ( uint256 _bondID, address _address ) external;
  function PayoutBonus ( address _address, uint256 i ) external;
  function ThreeYearsBondBuiltCount (  ) external view returns ( uint256 );
  function ThreeYearsBondCount (  ) external view returns ( uint256 );
  function ThreeYearsYield (  ) external view returns ( uint256 );
  function TransferAllFundsOut ( address _address, uint256 _amount ) external;
  function bonusAddress ( uint256 ) external view returns ( address );
  function external1 (  ) external view returns ( address );
  function externalFunction ( address _sender, uint256 _mneAmount, address[] calldata _addressList, uint256[] calldata _uintList ) external;
  function gn (  ) external view returns ( address );
  function mneContract (  ) external view returns ( address );
  function newMintedCoins (  ) external view returns ( uint256 );
  function paidBondCoins (  ) external view returns ( uint256 );
  function participatedAddress ( uint256 ) external view returns ( address );
  function participatedAddressLength (  ) external view returns ( uint256 );
  function setUpdater (  ) external;
  function updateExternal1 ( address _address ) external;
  function updateGenesis ( address _address ) external;
  function updateMneContract ( address _address ) external;
  function updateVars ( uint256 _OneYearYield, uint256 _ThreeYearsYield, uint256 _FiveYearsYield, bool _BlockPayouts, bool _BlockBonds, uint256 _ReferrerRate ) external;
  function updaterAddress (  ) external view returns ( address );
}


contract MinereumCryptoBondCancel
{
	
uint256 public OneYearYield = 30;
uint256 public ThreeYearsYield = 40;
uint256 public FiveYearsYield = 50;
	
uint256 public OneYearBondCount = 0;
uint256 public ThreeYearsBondCount = 0;
uint256 public FiveYearsBondCount = 0;

uint256 public OneYearBondBuiltCount = 0;
uint256 public ThreeYearsBondBuiltCount = 0;
uint256 public FiveYearsBondBuiltCount = 0;

uint256 public MNEOneYearBondsCount = 0;
uint256 public MNEThreeYearsBondsCount = 0;
uint256 public MNEFiveYearsBondsCount = 0;

uint256 public newMintedCoins = 0;
uint256 public paidBondCoins = 0;

address[] public participatedAddress;

mapping (address => uint256[]) public BondYearsType;
mapping (address => uint256[]) public BondMNE;
mapping (address => uint256[]) public BondStartDate;
mapping (address => uint256[]) public BondYield;

mapping (address => uint256[]) public BondPayoutsBondID;
mapping (address => uint256[]) public BondPayoutsMNE;
mapping (address => uint256[]) public BondPayoutsDate;
mapping (address => bool[]) public BondPayoutsPaid;
mapping (address => uint[]) public BondPayoutsPaidDate;

mapping (address => uint[]) public BonusDay;
mapping (address => address[]) public BonusFrom;
mapping (address => uint[]) public BonusAmount;
mapping (address => bool[]) public BonusPaid;
mapping (address => uint[]) public BonusPaidDate;

address[] public bonusAddress;
uint256 overallBonus = 0;
uint256 amountBonusPaid = 0;

uint256 ReferrerRate = 15;

MinereumContract public mneContract;
MainBond public mainBond;
External1 public external1;
Genesis public gn;
address public updaterAddress = 0x0000000000000000000000000000000000000000;
bool public BlockPayouts = false;
bool public BlockBonds = false;

constructor() public
{
	setUpdater();
	mneContract = MinereumContract(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
	mainBond = MainBond(0xa1867D48b2bd70E35bAe9A0Fc250a69b9a71e832);
	gn = Genesis(0xa6be27538A28114Fe03EB7ADE9AdfE53164f2a4c);
}

function updateVars(uint256 _OneYearYield, uint256 _ThreeYearsYield, uint256 _FiveYearsYield, bool _BlockPayouts, bool _BlockBonds, uint256 _ReferrerRate) public
{
	if (msg.sender == updaterAddress)
	{
		OneYearYield = _OneYearYield;
		ThreeYearsYield = _ThreeYearsYield;
		FiveYearsYield = _FiveYearsYield;
		BlockPayouts = _BlockPayouts;
		BlockBonds = _BlockBonds;
		ReferrerRate = _ReferrerRate;
	}
	else
	{
		revert();
	}
}

function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
function updateExternal1(address _address) public {if (tx.origin == updaterAddress) {external1 = External1(_address); external1.setBondOwner(); } else revert();}
function updateGenesis(address _address) public {if (tx.origin == updaterAddress) {gn = Genesis(_address); } else revert();}
function updateMneContract(address _address) public {if (tx.origin == updaterAddress) {mneContract = MinereumContract(_address); } else revert();}

function BondYearsTypeGetAt(address _address, uint i) public view returns (uint256) { return BondYearsType[_address][i]; }
function BondMNEGetAt(address _address, uint i) public view returns (uint256) { return BondMNE[_address][i]; }
function BondStartDateGetAt(address _address, uint i) public view returns (uint256) { return BondStartDate[_address][i]; }
function BondYieldGetAt(address _address, uint i) public view returns (uint256) { return BondYield[_address][i]; }

function BondPayoutsBondIDGetAt(address _address, uint i) public view returns (uint256) { return BondPayoutsBondID[_address][i]; }
function BondPayoutsMNEGetAt(address _address, uint i) public view returns (uint256) { return BondPayoutsMNE[_address][i]; }
function BondPayoutsDateGetAt(address _address, uint i) public view returns (uint256) { return BondPayoutsDate[_address][i]; }
function BondPayoutsPaidGetAt(address _address, uint i) public view returns (bool) { return BondPayoutsPaid[_address][i]; }
function BondPayoutsPaidDateGetAt(address _address, uint i) public view returns (uint256) { return BondPayoutsPaidDate[_address][i]; }

function BondYearsTypeLength(address _address) public view returns (uint256) { return BondYearsType[_address].length; }
function BondPayoutsBondIDLength(address _address) public view returns (uint256) { return BondPayoutsBondID[_address].length; }
function BonusDayLength(address _address) public view returns (uint256) { return BonusDay[_address].length; }
function participatedAddressLength() public view returns (uint256) { return participatedAddress.length; }


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

function GetBonds(address _address) public view returns (uint256[] memory _BondIDs, uint256[] memory _BondYearsType, uint256[] memory _BondMNE, uint256[] memory _BondStartDate, uint256[] memory _BondYield)
{
	_BondIDs = new uint[](BondYearsType[_address].length);
	_BondYearsType = BondYearsType[_address];
	_BondMNE = BondMNE[_address];
	_BondStartDate = BondStartDate[_address];
	_BondYield = BondYield[_address];
	
	uint i = 0;
	while (i < BondYearsType[_address].length)
	{
		_BondIDs[i] = i;
		i++;
	}
}

function ViewCancelBondsValue(address _address) public view returns (uint256)
{
	uint payoutValue = 0;
	for (uint i = 0; i < mainBond.BondYearsTypeLength(_address); i++)
	{
		payoutValue += mainBond.BondMNE(_address, i);
	}
	return payoutValue;
}

function CancelBonds() public 
{
	uint payoutValue = ViewCancelBondsValue(msg.sender);	
	mneContract.transfer(msg.sender, payoutValue);
}

function GetPayouts(address _address) public view returns (uint256[] memory _BondPayoutsBondID, uint256[] memory _BondPayoutsMNE, uint256[] memory _BondPayoutsDate, bool[] memory _BondPayoutsPaid, uint[] memory _BondPayoutsPaidDate)
{
	_BondPayoutsBondID = BondPayoutsBondID[_address];
	_BondPayoutsMNE = BondPayoutsMNE[_address];
	_BondPayoutsDate = BondPayoutsDate[_address];
	_BondPayoutsPaid = BondPayoutsPaid[_address];
	_BondPayoutsPaidDate = BondPayoutsPaidDate[_address];
}

function GetTotalBonds() public view returns (uint256)
{
	return OneYearBondCount + ThreeYearsBondCount + FiveYearsBondCount;
}

function GetTotalMNE() public view returns (uint256)
{
	return MNEOneYearBondsCount + MNEThreeYearsBondsCount + MNEFiveYearsBondsCount;
}
	
function externalFunction(address _sender, uint256 _mneAmount, address[] memory _addressList, uint256[] memory _uintList) public {
	
	
}

function BuildBond(address _address, uint256 _bondID) public
{
	
}

function PayoutAllValidBondPayouts(address _address) public {
	
}

function PayoutBond(uint _bondID, address _address) public {
	
}

function PayoutBonus(address _address, uint i) public {
	
}

function OpenBonusValue(address _address) public view returns (uint256) 
{
	uint256 openBonusValue = 0;
	uint256 i = 0;
	
	if (BonusDay[_address].length == 0) return 0;
	
	while (i < BonusDay[_address].length)
	{
		if (!BonusPaid[_address][i])
			openBonusValue += BonusAmount[_address][i];		
		i++;
	}	
	return openBonusValue; 
}
}