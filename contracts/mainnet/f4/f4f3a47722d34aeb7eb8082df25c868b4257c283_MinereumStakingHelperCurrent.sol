/**
 *Submitted for verification at Etherscan.io on 2020-07-14
*/

pragma solidity ^0.6.1;

interface Staking {
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
  function startStaking ( address _sender, uint256 _amountToStake, address[] calldata _addressList, uint256[] calldata uintList ) external;
  function updateExternal1 ( address _address ) external;
  function updateGenesis ( address _address ) external;
  function updateMneContract ( address _address ) external;
  function updatePublicCalls ( address _address ) external;
  function updateStartDate ( uint256 _startDate ) external;
  function updateVars ( bool _blockPayouts, bool _blockStaking, uint256 _referralRate, uint256 _referrerRateNormal, uint256 _referrerRateLevel2, uint256 _referrerRateLevel3, uint256 _referrerRateShare, uint256 _contingency ) external;
  function updaterAddress (  ) external view returns ( address );
}


contract MinereumStakingHelperCurrent
{

Staking sk;

constructor() public
{
	sk = Staking(0xCb2Aee9A6dAC92c1076f642FE4f2c9bcFFc81D9e);
}


function AmountMNESentCurrent(address _address) public view returns (uint256)
{
	if (sk.mneSentPerDayLength(_address) == 0) return 0;
	
	uint currentDay = sk.GetCurrentDay();
	
	uint _currentDay = sk.daysParticipatedGetAt(_address, sk.daysParticipatedLength(_address) - 1);
	
	uint lasti = sk.daysParticipatedLength(_address) - 1;
	
	if (_currentDay == currentDay)
	{		
		return sk.mneSentPerDayGetAt(_address, lasti);
	}
	
	return 0;
}

function AmountToPayStakingCurrent(address _address) public view returns (uint256)
{
	if (sk.daysParticipatedLength(_address) == 0) return 0;
	
	uint currentDay = sk.GetCurrentDay();
	
	uint _currentDay = sk.daysParticipatedGetAt(_address, sk.daysParticipatedLength(_address) - 1);
	uint lasti = sk.daysParticipatedLength(_address) - 1;
	
	if (_currentDay == currentDay)
	{			
		uint interestRateToPay = sk.mneSentPerDayGetAt(_address, lasti) * sk.maxInterestRate(sk.daysParticipatedGetAt(_address, lasti)) * 1000000000000000 / sk.mnePerDay(sk.daysParticipatedGetAt(_address, lasti));
		uint coinsToMint = sk.mneSentPerDayGetAt(_address, lasti) * interestRateToPay / 1000000000000000 / 100;
		uint amountToPay = sk.mneSentPerDayGetAt(_address, lasti) + coinsToMint;
		return amountToPay;				
	}
	else
	{
		return 0;
	}		
}
}