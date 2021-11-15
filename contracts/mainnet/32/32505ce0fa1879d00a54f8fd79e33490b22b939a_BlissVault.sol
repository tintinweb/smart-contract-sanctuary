// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;


import "./lib/SafeMath.sol";
import "./token/ERC20/IERC20.sol";
import "./lib/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

// Bliss Vault distributes fees equally amongst staked pools
contract BlissVault is AccessControlUpgradeSafe {
  
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //
  event DepositRwardAdded( address indexed rewardToken, address indexed depositToken );
  event LPDeposit( address indexed lpTokenAddress, address indexed rewardTokenAddress, address indexed depositorAddress, uint256 amountDeposited );
  event LPWithdrawal( address indexed lpTokeAddress, address indexed rewardTokenAddress, address indexed depositorAddress, uint256 amountWithdrawn );
  event RewardWithdrawal( address indexed lpTokenAddress, address indexed rewardTokenAddress, address indexed depositorAddress, uint256 amountWithdrawn );

  struct Depositor {
    uint256 _currentDeposit;
    // DONE - Needs to be updated with the current value of RewardPool._totalRewardWithdrawn when a new deposit is made.
    uint256 _totalRewardWithdrawn;
  }

  struct RewardPool {
    bool _initialized;
    uint256 _rewardPoolRewardTokenAllocation;
    uint256 _totalRewardWithdrawn;
    // Contains the total of all depositor balances deposited.
    uint256 _totalDeposits;
    // Depositor address
    mapping( address => Depositor ) _depositorAddressForDepositor;
  }

  struct RewardPoolDistribution {
    bool _initialized;
    uint256 _rewardPoolDistributionTotalAllocation;
    // Total amount of reward token to 
    uint256 _totalRewardWithdrawn;
    // Total of all shares of splitting rewards between pools that receive this token as a reward.
    uint256 _totalPoolShares;
    // Pool deposit token address i.e VANA / BLISS
    mapping( address => RewardPool ) _depositTokenForRewardPool;
  }

  address[] public rewards;
  // Reward token address i.e WBTC
  mapping( address => RewardPoolDistribution ) public rewardTokenAddressForRewardPoolDistribution;

  address public devFeeRevenueSplitter;

  uint8 public debtPercentage;

  function initialize() external initializer {
    _addDevAddress(0x5acCa0ab24381eb55F9A15aB6261DF42033eE060);
    debtPercentage = 100; // 10% debt default
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!owner");
    _;
  }

  /**
   * @param _rewardTokenAddress - The contract address for the token paid out as rewards. This is used as the key to retrieve the RewardPoolDistribution for the return value.
   * @return RewardPoolDistribution defining how a token should and has been distributed.
   */
  function _getRewardPoolDistributionStorage( address _rewardTokenAddress ) internal view returns ( RewardPoolDistribution storage ) {
    return rewardTokenAddressForRewardPoolDistribution[_rewardTokenAddress];
  }

  /**
   * @param _rewardPoolDistribution - RewardPoolDistribution from which to retrieve the RewardPool for return.
   * @param _depositTokenAddress - Contract Address of the token accept for deposit to earn rewards that is used as the key for retrieving the RewardPool for return.
   * @return RewardPool defining the token accepted for deposit to earn rewards and 
   */
  function _getRewardPoolStorage( RewardPoolDistribution storage _rewardPoolDistribution, address _depositTokenAddress ) internal view returns ( RewardPool storage ) {
    return _rewardPoolDistribution._depositTokenForRewardPool[_depositTokenAddress];
  }

  /**
   * @param _rewardTokenAddress - Contract address of the reward token that will be distributed as claimable rewards.
   * @param _depositTokenAddress - Contract Address of the token accept for deposit to earn rewards that is used as the key for retrieving the RewardPool for return.
   * @return RewardPoolDistribution defining how a token should and has been distributed.
   * @return RewardPool defining the token accepted for deposit to earn rewards and distribution of those rewards across this RewardPool
   */
  function _getRewardPoolDistributionAndRewardPoolStorage( address _rewardTokenAddress, address _depositTokenAddress ) internal view returns ( RewardPoolDistribution storage, RewardPool storage ) {
    RewardPoolDistribution storage _rewardPoolDistribution = _getRewardPoolDistributionStorage( _rewardTokenAddress );
    RewardPool storage _rewardPool = _getRewardPoolStorage( _rewardPoolDistribution, _depositTokenAddress );
    return ( _rewardPoolDistribution, _rewardPool );
  }

  /**
   * @param _rewardPool - RewardPool from which to retrieve the Depositor for return.
   * @param _depositorAddress - User address that acts os the key for retrieving the Depositor for return.
   * @return Depositor representing the user that has deposited into the containing RewardPool.
   */
  function _getDepositorStorage( RewardPool storage _rewardPool, address _depositorAddress ) internal view returns ( Depositor storage ) {
    return _rewardPool._depositorAddressForDepositor[ _depositorAddress ];
  }

  /**
   * @param _rewardTokenAddress - The contract address for the token paid out as rewards. This is used as the key to retrieve the RewardPoolDistribution for the return value.
   * @param _depositTokenAddress - Contract Address of the token accept for deposit to earn rewards that is used as the key for retrieving the RewardPool for return.
   * @param _depositorAddress - User address that acts os the key for retrieving the Depositor for return.
   * @return RewardPoolDistribution defining how a token should and has been distributed.
   * @return RewardPool defining the deposits to earn rewards and reward distribution.
   * @return Depositor representing the user that has deposited into the containing RewardPool.
   */
  function _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( address _rewardTokenAddress, address _depositTokenAddress, address _depositorAddress ) internal view returns ( RewardPoolDistribution storage, RewardPool storage, Depositor storage ) {
    RewardPoolDistribution storage _rewardPoolDistribution = _getRewardPoolDistributionStorage( _rewardTokenAddress );
    RewardPool storage _rewardPool = _getRewardPoolStorage( _rewardPoolDistribution, _depositTokenAddress );
    Depositor storage _depositor = _getDepositorStorage( _rewardPool, _depositorAddress );
    return ( _rewardPoolDistribution, _rewardPool, _depositor );
  }

  function _calculatePercentageShare( uint256 _shares, uint256 _rewardDecimalsExponentiated, uint256 _totalShares ) internal pure returns ( uint256 ) {
    return _shares
      // Multiplying by 1 to the power the number of decimals for the reward token to avoid math underflow errors, i.e for WBTC this is 1e8;
      .mul( _rewardDecimalsExponentiated )
      // percentageOfTotal adds 2 zeroes to final result. This is done for greater granularity. This will be removed in later calculations.
      .percentageOfTotal( _totalShares );
  }

  function _getRewardTokenDecimals( address _rewardTokenAddress ) internal view returns ( uint256 ) {
    return IERC20( _rewardTokenAddress ).decimals();
  }

  function _getRewardTokenExponent( address _rewardTokenAddress, address _rewardPoolDepositTokenAddress ) internal view returns ( uint256 ) {
    uint256 _rewardTokenDecimalsExponent = _getRewardTokenDecimals( _rewardTokenAddress );

    if( _rewardPoolDepositTokenAddress == address(this)) {
      return _rewardTokenDecimalsExponent;
    } else {
      uint256 _depostTokenDecimalsExponent = _getRewardTokenDecimals( _rewardPoolDepositTokenAddress );
      return _rewardTokenDecimalsExponent < _depostTokenDecimalsExponent ? 10 ** (_depostTokenDecimalsExponent.sub( _rewardTokenDecimalsExponent )): 1;
    }
  }

  function _getRewardDueToDepositor(
    uint256 _totalRewardAvailable,
    uint256 _exponent,
    uint256 _totalDeposits, 
    uint256 _depositorCurrentDeposit, 
    uint256 _depositorTotalRewardWithdrawn
  ) internal pure returns ( uint256 ) {
    if( _totalDeposits == 0 ) {
      return 0;
    }

    // Once we know how much reward is available for the pool, split it based
    // on shares owned by the depositor
    uint256 _percentageOfShares = _calculatePercentageShare( _depositorCurrentDeposit, _exponent , _totalDeposits );

    _totalRewardAvailable = _totalRewardAvailable
      .add( _depositorTotalRewardWithdrawn )
      .mul( _percentageOfShares )
      .div( _exponent )
      .div( 100 ); // account for the extra 100 from the percentageOfTotal call

    return _totalRewardAvailable > _depositorTotalRewardWithdrawn ? _totalRewardAvailable.sub( _depositorTotalRewardWithdrawn ) : 0;
  }

  function _getRewardDueToRewardPool(
    uint256 _exponent,
    uint256 _depositorShares,
    address _rewardTokenAddress,
    uint256 _poolAllocation,
    uint256 _totalAllocation,
    uint256 _totalRewardWithdrawn
  ) internal view returns ( uint256 ) {
    if( _depositorShares == 0 ) {
      return 0;
    }

    uint256 _percentageOfAllocation = _calculatePercentageShare( _poolAllocation, _exponent , _totalAllocation );

    uint256 _rewardTokenBalance = IERC20( _rewardTokenAddress ).balanceOf( address( this ) );

    // We only calculate the pool share of the total reward distribution
    // Do not consider depositor share percentage in this math
    uint256 _baseReward = _rewardTokenBalance
      .add( _totalRewardWithdrawn )
      .mul( _percentageOfAllocation )
      .div( _exponent )
      .div( 100 ); // account for the extra 10000 from the percentageOfTotal call










    return _baseReward > _totalRewardWithdrawn ? _baseReward.sub( _totalRewardWithdrawn ) : 0;
  }

  function _calculateRewardWithdrawalForDepositor( 
    RewardPoolDistribution storage _rewardPoolDistribution,
    RewardPool storage _rewardPool,
    Depositor storage _depositor,
    uint256 _exponent,
    address _rewardTokenAddress
  ) internal view returns ( uint256 ) {








    uint256 _poolDebt = _rewardPool._totalRewardWithdrawn.percentageAmount( debtPercentage );

    uint256 _rewardTokenAmountAvailableForPool = _getRewardDueToRewardPool(
      _exponent,
      _depositor._currentDeposit,
      _rewardTokenAddress,
      _rewardPool._rewardPoolRewardTokenAllocation,
      _rewardPoolDistribution._rewardPoolDistributionTotalAllocation,
      _poolDebt
    );


    return _getRewardDueToDepositor(
      _rewardTokenAmountAvailableForPool,
      _exponent,
      _rewardPool._totalDeposits,
      _depositor._currentDeposit,
      _depositor._totalRewardWithdrawn
    );
  }

  // Need to convert to view function. Might require changing structs to a set of independent mappings.
  function getRewardDueToDepositor( address _rewardTokenAddress, address _depositTokenAddress, address _depositorAddress ) external view returns ( uint256 ) {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, _depositorAddress );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );

    return _calculateRewardWithdrawalForDepositor( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _rewardTokenAddress );
  }

  function getRewardPoolDistribution(address _rewardTokenAddress) external view returns (
    bool rewardPoolDistributionInitialized,
    uint256 rewardPoolDistributionTotalRewardWithdrawn,
    uint256 rewardPoolDistributionTotalPoolShares,
    uint256 rewardPoolDistributionTotalAllocation
  ) {
    RewardPoolDistribution storage _rewardPoolDistribution =
      _getRewardPoolDistributionStorage( _rewardTokenAddress );

    return (
      _rewardPoolDistribution._initialized,
      _rewardPoolDistribution._totalRewardWithdrawn,
      _rewardPoolDistribution._totalPoolShares,
      _rewardPoolDistribution._rewardPoolDistributionTotalAllocation
    );
  }

  function getRewardPool( 
    address _rewardTokenAddress,
    address _depositTokenAddress,
    address _depositorAddress 
  ) external view returns (
    bool rewardPoolInitialized,
    uint256 rewardPoolTotalWithdrawn,
    uint256 rewardPoolTotalDeposits,
    uint256 rewardPoolRewardTokenAllocation,
    uint256 depositorCurrentDeposits,
    uint256 depositorTotalRewardWithdrawn,
    uint256 vaultRewardTokenBalance,
    uint256 poolDebt
  ) {
    ( ,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, _depositorAddress );

    uint256 _vaultRewardTokenBalance = IERC20( _rewardTokenAddress ).balanceOf( address( this ) );
    uint256 _poolDebt = _rewardPool._totalRewardWithdrawn.percentageAmount( debtPercentage );

    return (
      _rewardPool._initialized,
      _rewardPool._totalRewardWithdrawn,
      _rewardPool._totalDeposits,
      _rewardPool._rewardPoolRewardTokenAllocation,
      _depositor._currentDeposit,
      _depositor._totalRewardWithdrawn,
      _vaultRewardTokenBalance,
      _poolDebt
    );
  }

  function _withdrawDeposit(
    address _depositorAddress,
    uint _amountToWithdraw,
    address _rewardTokenAddress,
    address _depositTokenAddress,
    bool _exitPool
  ) internal {
    ( RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, _depositorAddress );

    // If user is exiting pool set the amount withdrawn to current deposit
    _amountToWithdraw = _exitPool ? _depositor._currentDeposit : _amountToWithdraw;




    require( _amountToWithdraw != 0, "Cannot withdraw 0 amount");
    require( _depositor._currentDeposit >= _amountToWithdraw, "Cannot withdraw more than current deposit amount." );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );
    _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _depositTokenAddress, _rewardTokenAddress );

    _depositor._currentDeposit = _depositor._currentDeposit.sub( _amountToWithdraw );
    _rewardPool._totalDeposits = _rewardPool._totalDeposits.sub( _amountToWithdraw );
    _rewardPoolDistribution._totalPoolShares = _rewardPoolDistribution._totalPoolShares.sub( _amountToWithdraw );

    IERC20( _depositTokenAddress).safeTransfer( _depositorAddress, _amountToWithdraw );
  }

  // Withdraw less than LP total balance
  function withdrawDeposit( 
    address _rewardTokenAddress,
    address _depositTokenAddress,
    uint _amountToWithdraw
  ) external {
    _withdrawDeposit( msg.sender, _amountToWithdraw, _rewardTokenAddress, _depositTokenAddress, false );
  }

  // Exit pool entirely
  function withdrawDepositAndRewards( address _rewardTokenAddress, address _depositTokenAddress ) external {
    _withdrawDeposit( msg.sender, 0, _rewardTokenAddress, _depositTokenAddress, true );
  }

  // Withdraw rewards only
  function _withdrawRewards( 
    RewardPoolDistribution storage _rewardPoolDistribution,
    RewardPool storage _rewardPool,
    Depositor storage _depositor,
    uint256 _exponent,
    address _depositTokenAddress,
    address _rewardTokenAddress
    //address _depositorAddress
  ) internal returns ( 
    uint256
  ) {
    
    uint256 _rewardDue =  _calculateRewardWithdrawalForDepositor( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _rewardTokenAddress );

    require( _rewardPoolDistribution._initialized, "Reward pool distribution is currently not enabled." );

    if( _rewardDue > 0 ) {
      _depositor._totalRewardWithdrawn = _depositor._totalRewardWithdrawn.add( _rewardDue );
      _rewardPool._totalRewardWithdrawn = _rewardPool._totalRewardWithdrawn.add( _rewardDue );
      _rewardPoolDistribution._totalRewardWithdrawn = _rewardPoolDistribution._totalRewardWithdrawn.add( _rewardDue );
      IERC20( _rewardTokenAddress ).safeTransfer( msg.sender, _rewardDue );
      emit RewardWithdrawal( _depositTokenAddress, _rewardTokenAddress, msg.sender, _rewardDue );
    }
    return _rewardDue;
  }

  function withdrawRewards( 
    address _depositTokenAddress,
    address _rewardTokenAddress
  ) external returns ( uint256 ) {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, msg.sender );
    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );
    return _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _depositTokenAddress, _rewardTokenAddress );
  }

  function _deposit( address _depositTokenAddress, address _rewardTokenAddress, uint256 _amountToDeposit ) internal returns ( uint256 ) {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    )  = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, msg.sender );

    require( _rewardPool._initialized, "Deposits not enabled for this pool." );
    require( IERC20( _depositTokenAddress ).balanceOf( msg.sender ) >= _amountToDeposit, "Message sender does not have enough to deposit." );
    require( IERC20( _depositTokenAddress ).allowance( msg.sender, address( this ) ) >= _amountToDeposit, "Message sender has not approved sufficient allowance for this contract." );

    IERC20( _depositTokenAddress ).safeTransferFrom( msg.sender, address( this ), _amountToDeposit );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );
    _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _depositTokenAddress, _rewardTokenAddress );

    _depositor._currentDeposit = _depositor._currentDeposit.add( _amountToDeposit );
    _rewardPool._totalDeposits = _rewardPool._totalDeposits.add( _amountToDeposit );

    _rewardPoolDistribution._totalPoolShares = _rewardPoolDistribution._totalPoolShares.add( _amountToDeposit );


    return _depositor._currentDeposit;
  }

  function deposit( address _depositToken, address _rewardTokenAddress, uint256 _amountToDeposit ) external returns ( uint256 ) {
    return _deposit( _depositToken, _rewardTokenAddress, _amountToDeposit );
  }

  function _removeDev( address[] storage _values, address value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = devsIndex[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            address lastvalue = _values[lastIndex];

            // Move the last value to the index where the value to delete is
            _values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            devsIndex[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            _values.pop();

            // Delete the index for the deleted slot
            delete devsIndex[value];

            return true;
        } else {
            return false;
        }
  }

  function _getRewardPoolAndDepositorStorageFromDistribution( RewardPoolDistribution storage _rewardPoolDistribution, address _depositTokenAddress, address _depositorAddress ) internal view returns ( RewardPool storage, Depositor storage ) {
    RewardPool storage _rewardPool = _getRewardPoolStorage( _rewardPoolDistribution, _depositTokenAddress );
    Depositor storage _depositor = _getDepositorStorage( _rewardPool, _depositorAddress );
    return ( _rewardPool, _depositor );
  }

  address[] public devs;
  mapping( address => uint256 ) devsIndex;
  mapping( address => bool ) public activeDev;

  function changeDevAddress( address _newDevAddress ) external {
    require( activeDev[msg.sender] == true );
    _removeDev( devs, msg.sender );
    _addDevAddress( _newDevAddress );
    for( uint256 _iteration; rewards.length > _iteration; _iteration++ ) {
      (
        RewardPoolDistribution storage _rewardPoolDistribution,
        RewardPool storage _devRewardPool,
        Depositor storage _devDepositor
      ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( rewards[_iteration], address(this), msg.sender );

      uint256 _exponent = _getRewardTokenExponent( rewards[_iteration], address(this) );

      _devRewardPool._totalDeposits = _devRewardPool._totalDeposits.sub( _devDepositor._currentDeposit );
      _devDepositor._currentDeposit = 0;

      _addDevDepositor(
        _rewardPoolDistribution,
        _exponent
      );
    }
  }

  function _addDevAddress( address _newDev ) internal {
    devs.push(_newDev);
    devsIndex[_newDev] = devs.length;
    activeDev[_newDev] = true;
  }

  function withdrawDevRewards( 
    address _rewardTokenAddress
  ) external returns ( uint256 ) {
    require( activeDev[msg.sender] == true );
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, address(this), msg.sender );
    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, address(this) );
    return _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, address(this), _rewardTokenAddress );
  }

  function _addDevDepositor(
    RewardPoolDistribution storage _rewardPoolDistribution,
    uint256 _exponent
   ) internal {
     for( uint256 _iteration = 0; devs.length > _iteration; _iteration++ ) {
      (
        RewardPool storage _devRewardPool,
        Depositor storage _devDepositor
      )  = _getRewardPoolAndDepositorStorageFromDistribution( _rewardPoolDistribution, address(this) , devs[_iteration] );

      if( _devDepositor._currentDeposit > 0 ){
        break;
      } else {
        // _rewardPoolDistribution._totalPoolShares = _rewardPoolDistribution._totalPoolShares.add(_rewardPoolDistribution._totalPoolShares.percentageAmount( 100 ) );
        _devRewardPool._totalDeposits = 2 * (10 **_exponent);
        _devDepositor._currentDeposit = 1 * (10 **_exponent);

        _devRewardPool._initialized = true;
        _setPoolAllocation(_rewardPoolDistribution, _devRewardPool, 1);
        _rewardPoolDistribution._depositTokenForRewardPool[address(this)] = _devRewardPool;
      }
    }
   }

  function _enablePool( address _depositToken, address _rewardTokenAddress, bool _initializeRewardPool, bool _initializeRewardPoolDistribution, uint256 _rewardPoolRewardTokenAllocation ) internal {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool
    ) = _getRewardPoolDistributionAndRewardPoolStorage( _rewardTokenAddress, _depositToken);

    rewards.push( _rewardTokenAddress );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, address(this) );

    _addDevDepositor(
      _rewardPoolDistribution,
      _exponent
    );

    require( _rewardPool._initialized != _initializeRewardPool, "Pool is already set that way." );

    _rewardPool._initialized = _initializeRewardPool;
    _rewardPoolDistribution._initialized = _initializeRewardPoolDistribution;
    _setPoolAllocation(_rewardPoolDistribution, _rewardPool, _rewardPoolRewardTokenAllocation);
    _rewardPoolDistribution._depositTokenForRewardPool[_depositToken] = _rewardPool;
  }

  function setPoolAllocation( address _depositToken, address _rewardTokenAddress, uint256 _rewardPoolRewardTokenAllocation ) external onlyOwner() {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool
    ) = _getRewardPoolDistributionAndRewardPoolStorage( _rewardTokenAddress, _depositToken);
    _setPoolAllocation( _rewardPoolDistribution, _rewardPool, _rewardPoolRewardTokenAllocation );
  }

  function _setPoolAllocation(RewardPoolDistribution storage _rewardPoolDistribution, RewardPool storage _rewardPool, uint256 _rewardPoolRewardTokenAllocation) internal {
    _rewardPoolDistribution._rewardPoolDistributionTotalAllocation = _rewardPoolDistribution._rewardPoolDistributionTotalAllocation.sub( _rewardPool._rewardPoolRewardTokenAllocation );
    _rewardPoolDistribution._rewardPoolDistributionTotalAllocation = _rewardPoolDistribution._rewardPoolDistributionTotalAllocation.add( _rewardPoolRewardTokenAllocation );
    _rewardPool._rewardPoolRewardTokenAllocation = _rewardPoolRewardTokenAllocation;
  }

  function setDebtPercentage( uint256 _debtPercentage ) external onlyOwner() {
    require(_debtPercentage <= 1000, "Cannot set pool debt to more than 100 percent");
    debtPercentage = uint8(_debtPercentage);
  }

  function enablePool( address _depositToken, address _rewardTokenAddress, bool _initializeRewardPool, bool _initializeRewardPoolDistribution, uint256 _rewardPoolRewardTokenAllocation ) external onlyOwner() {
    _enablePool( _depositToken, _rewardTokenAddress, _initializeRewardPool, _initializeRewardPoolDistribution, _rewardPoolRewardTokenAllocation );
  }

  function enablePools(
      address[] calldata _depositTokens,
      address[] calldata _rewardTokenAddresses,
      bool[] calldata _rewardPoolInitializations,
      bool[] calldata _rewardPoolDistributionInitializations,
      uint256[] calldata _rewardPoolRewardTokenAllocation
  ) external onlyOwner() {
    require(
      _depositTokens.length > 0
      && _depositTokens.length == _rewardTokenAddresses.length
      && _depositTokens.length == _rewardPoolInitializations.length
      && _rewardTokenAddresses.length == _rewardPoolInitializations.length
      && _rewardPoolInitializations.length == _rewardPoolDistributionInitializations.length
      && _rewardPoolDistributionInitializations.length == _depositTokens.length
      && _rewardPoolDistributionInitializations.length == _rewardTokenAddresses.length
      , "There must be the same number of addresses for lp token, reward token, and initializations."
    );

    for( uint256 _iteration = 0; _depositTokens.length > _iteration; _iteration++ ) {
      _enablePool(
        _depositTokens[_iteration],
        _rewardTokenAddresses[_iteration],
        _rewardPoolInitializations[_iteration],
        _rewardPoolDistributionInitializations[_iteration],
        _rewardPoolRewardTokenAllocation[_iteration]
      );
    }
  }

  function _enableRewardPoolDistribution(address _rewardToken, bool _initialize) internal {
    RewardPoolDistribution storage _rewardPoolDistribution = _getRewardPoolDistributionStorage(_rewardToken);
    require( _rewardPoolDistribution._initialized != _initialize, "Pool is already set that way." );

    _rewardPoolDistribution._initialized = _initialize;
  }

  function enableRewardPoolDistribution( address _rewardToken, bool _initialize ) external onlyOwner() {
    _enableRewardPoolDistribution( _rewardToken, _initialize );
  }

  // One time function to pull funds from old Bliss vault
  function transferFundsFromOldVault( address _rewardTokenAddress, address _oldVault, uint256 _amount ) external onlyOwner() {
    IERC20( _rewardTokenAddress ).safeTransferFrom( _oldVault, address( this ), _amount );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    /**
     * Taken from Hypersonic https://github.com/M2629/HyperSonic/blob/main/Math.sol
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /*
     * Expects percentage to be trailed by 00,
    */
    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

    function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
        return mul( multiplier_, supply_ );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



import "../token/ERC20/IERC20.sol";
import "../lib/SafeMath.sol";
import "../utils/SafeAddress.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using SafeAddress for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library SafeAddress {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

