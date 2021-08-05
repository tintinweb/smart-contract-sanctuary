/**
 *Submitted for verification at Etherscan.io on 2020-09-13
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

contract MinereumCryptoBond
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
External1 public external1;
Genesis public gn;
address public updaterAddress = 0x0000000000000000000000000000000000000000;
bool public BlockPayouts = false;
bool public BlockBonds = false;

constructor() public
{
	setUpdater();
	mneContract = MinereumContract(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
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
	
	if (msg.sender != address(mneContract)) revert();
	
	if (BlockBonds) revert('Bonds Blocked');	
	
	BondYearsType[_sender].push(_uintList[0]);
	BondMNE[_sender].push(_mneAmount);
	BondStartDate[_sender].push(now);

	if (BondYearsType[_sender].length == 0)	
		participatedAddress.push(_sender);
	
	if (_uintList[0] == 1)
	{
		BondYield[_sender].push(OneYearYield);
		
		OneYearBondCount++;
		MNEOneYearBondsCount += _mneAmount;
	}
	else if (_uintList[0] == 3)
	{
		BondYield[_sender].push(ThreeYearsYield);
		
		ThreeYearsBondCount++;
		MNEThreeYearsBondsCount += _mneAmount;
	}
	else if (_uintList[0] == 5)
	{
		BondYield[_sender].push(FiveYearsYield);
		
		FiveYearsBondCount++;
		MNEFiveYearsBondsCount += _mneAmount;
	}
	else
	{
		revert('invalid bond');
	}	
	
	
	if (_addressList.length > 1)
	{
		if (_sender == _addressList[1] || _addressList[1] == address(this) || _addressList[1] == address(mneContract)) revert('invalid referal');
		
		uint bonusAmountReferrer = _mneAmount * ReferrerRate / 100;
		
		BonusDay[_addressList[1]].push(now);
		BonusFrom[_addressList[1]].push(_sender);
		BonusAmount[_addressList[1]].push(bonusAmountReferrer);
		BonusPaid[_addressList[1]].push(false);
		BonusPaidDate[_addressList[1]].push(0);
		
		if (BonusDay[_addressList[1]].length == 0)
			bonusAddress.push(_addressList[1]);
	
		overallBonus += bonusAmountReferrer;
	}	
}

function BuildBond(address _address, uint256 _bondID) public
{
	if (_bondID + 1 > BondYearsType[_address].length) revert('invalid id');
	
	
	if (BondPayoutsBondID[_address].length > 0)
	{
		uint i = 0;	
		while (i < BondPayoutsBondID[_address].length)
		{
			if (BondPayoutsBondID[_address][i] == _bondID)
				revert('Bond already built');
			i++;
		}	
	}
	
	if (BondYearsType[_address][_bondID] == 1)
	{
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + 31556926);
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID]);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + 31556926);
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		OneYearBondBuiltCount++;
	}
	else if (BondYearsType[_address][_bondID] == 3)
	{
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + 31556926);
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 2));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 3));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID]);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 3));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		ThreeYearsBondBuiltCount++;
	}
	else if (BondYearsType[_address][_bondID] == 5)
	{
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + 31556926);
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 2));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 3));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 4));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID] * BondYield[_address][_bondID] / 100);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 5));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);		
		
		BondPayoutsBondID[_address].push(_bondID);
		BondPayoutsMNE[_address].push(BondMNE[_address][_bondID]);
		BondPayoutsDate[_address].push(BondStartDate[_address][_bondID] + (31556926 * 5));
		BondPayoutsPaid[_address].push(false);
		BondPayoutsPaidDate[_address].push(0);
		
		FiveYearsBondBuiltCount++;
	}
	else
	{
		revert('invalid bond');
	}
}

function PayoutAllValidBondPayouts(address _address) public {
	uint i = 0;
	while (i < BondPayoutsBondID[msg.sender].length)
	{
		if (now >= BondPayoutsDate[msg.sender][i] && !BondPayoutsPaid[msg.sender][i])
			PayoutBond(BondPayoutsBondID[msg.sender][i], _address);
		i++;
	}
}

function PayoutBond(uint _bondID, address _address) public {
	if (BlockPayouts) revert('payouts blocked'); //in case of migration to another contract
	
	if (BondPayoutsBondID[msg.sender].length == 0) revert('No Bonds Available');
	
	uint i = 0;
	uint payoutID = 323232323232;
	while (i < BondPayoutsBondID[msg.sender].length)
	{
		if (BondPayoutsBondID[msg.sender][i] == _bondID)
			payoutID = i;
		i++;
	}
	
	if (payoutID == 323232323232) revert('Bond ID not found');
	
	if (BondPayoutsPaid[msg.sender][payoutID]) revert('Bond already paid');
	
	if (block.timestamp < BondPayoutsDate[msg.sender][payoutID]) revert('Payout Date not reached yet');
	
	if (block.timestamp >= BondPayoutsDate[msg.sender][payoutID] && !BondPayoutsPaid[msg.sender][payoutID])
	{
		uint coinsToMint = 0;
		
		if (gn.availableBalanceOf(address(this)) < BondPayoutsMNE[msg.sender][payoutID])
		{
			coinsToMint = BondPayoutsMNE[msg.sender][payoutID] - gn.availableBalanceOf(address(this));
			external1.mintNewCoins(coinsToMint);
		}
		
		uint amountToPay = BondPayoutsMNE[msg.sender][payoutID];
		
		if (_address != 0x0000000000000000000000000000000000000000)			
			mneContract.transfer(_address, amountToPay);
		else
			mneContract.transfer(msg.sender, amountToPay);
		
		newMintedCoins += coinsToMint;
		paidBondCoins += amountToPay;
		
		BondPayoutsPaid[msg.sender][payoutID] = true;
		BondPayoutsPaidDate[msg.sender][payoutID] = now;
	}
	else
	{
		revert('Payout Date Not Valid');
	}
}

function PayoutBonus(address _address, uint i) public {
	if (i >= BonusAmount[msg.sender].length) revert('no bonus index found');	
	
	if (BonusAmount[msg.sender][i] > 0 && now >= (BonusDay[msg.sender][i] + 31556926) && !BonusPaid[msg.sender][i])
	{
		if (gn.availableBalanceOf(address(this)) < BonusAmount[msg.sender][i])
		{
			uint coinsToMint = BonusAmount[msg.sender][i] - gn.availableBalanceOf(address(this));
			external1.mintNewCoins(coinsToMint);
		}		
		
		if (_address != 0x0000000000000000000000000000000000000000)			
			mneContract.transfer(_address, BonusAmount[msg.sender][i]);
		else
			mneContract.transfer(msg.sender, BonusAmount[msg.sender][i]);	
		
		BonusPaidDate[msg.sender][i] = now;
		BonusPaid[msg.sender][i] = true;		
		amountBonusPaid += BonusAmount[msg.sender][i];		
	}
	else
	{
		revert('Invalid bonus payout');
	}
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