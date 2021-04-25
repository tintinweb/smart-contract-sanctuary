pragma solidity 0.6.5;

import "./PROS.sol";
import "./SafeMath.sol";
import "./SafeMath64.sol";

contract Vesting {

  using SafeMath for uint256;
  using SafeMath64 for uint64;
  PROS public token;
  address public owner;

  uint constant internal SECONDS_PER_DAY = 1 days;

  event Allocated(address recipient, uint64 startTime, uint256 amount, uint64 vestingDuration, uint64 vestingPeriodInDays, uint _upfront);
  event TokensClaimed(address recipient, uint256 amountClaimed);

  struct Allocation {
    uint64 vestingDuration; 
    uint64 periodClaimed;  
    uint64 periodInDays; 
    uint64 startTime; 
    uint256 amount;
    uint256 totalClaimed;
  }
  mapping (address => Allocation) public tokenAllocations;

  modifier onlyOwner {
    require(msg.sender == owner, "unauthorized");
    _;
  }

  modifier nonZeroAddress(address x) {
    require(x != address(0), "token-zero-address");
    _;
  }

  constructor(address _token, address _owner) public
  nonZeroAddress(_token)
  nonZeroAddress(_owner)
  {
    token = PROS(_token);
    owner = _owner;
  }

  /// @dev Add a new token vesting for user `_recipient`. Only one vesting per user is allowed
  /// The amount of PROS tokens here need to be preapproved for transfer by this `Vesting` contract before this call
  /// @param _recipient Address array of the token recipient entitled to claim the vested funds
  /// @param _startTime Vesting start time array as seconds since unix epoch 
  /// @param _amount Total number of tokens array in vested
  /// @param _vestingDuration Number of Periods in array.
  /// @param _vestingPeriodInDays Array of Number of days in each Period
  /// @param _upFront array of Amount of tokens `_recipient[i]` will get  right away
  function addTokenVesting(address[] memory _recipient, uint64[] memory _startTime, uint256[] memory _amount, uint64[] memory _vestingDuration, uint64[] memory _vestingPeriodInDays, uint256[] memory _upFront) public 
  onlyOwner
  {

    require(_recipient.length == _startTime.length, "Different array length");
    require(_recipient.length == _amount.length, "Different array length");
    require(_recipient.length == _vestingDuration.length, "Different array length");
    require(_recipient.length == _vestingPeriodInDays.length, "Different array length");
    require(_recipient.length == _upFront.length, "Different array length");

    for(uint i=0;i<_recipient.length;i++) {
      require(tokenAllocations[_recipient[i]].startTime == 0, "token-user-grant-exists");
      require(_startTime[i] != 0, "should be positive");
      uint256 amountVestedPerPeriod = _amount[i].div(_vestingDuration[i]);
      require(amountVestedPerPeriod > 0, "0-amount-vested-per-period");

      // Transfer the vesting tokens under the control of the vesting contract
      token.transferFrom(owner, address(this), _amount[i].add(_upFront[i]));

      Allocation memory _allocation = Allocation({
        startTime: _startTime[i], 
        amount: _amount[i],
        vestingDuration: _vestingDuration[i],
        periodInDays: _vestingPeriodInDays[i],
        periodClaimed: 0,
        totalClaimed: 0
      });
      tokenAllocations[_recipient[i]] = _allocation;

      if(_upFront[i] > 0) {
        token.transfer(_recipient[i], _upFront[i]);
      }

      emit Allocated(_recipient[i], _startTime[i], _amount[i], _vestingDuration[i], _vestingPeriodInDays[i], _upFront[i]);
    }
  }

  /// @dev Allows a vesting recipient to claim their vested tokens. Errors if no tokens have vested
  /// It is advised recipients check they are entitled to claim via `calculateVestingClaim` before calling this
  function claimVestedTokens() public {
    uint64 periodVested;
    uint256 amountVested;
    (periodVested, amountVested) = calculateVestingClaim(msg.sender);
    require(amountVested > 0, "token-zero-amount-vested");

    Allocation storage _tokenAllocated = tokenAllocations[msg.sender];
    _tokenAllocated.periodClaimed = _tokenAllocated.periodClaimed.add(periodVested);
    _tokenAllocated.totalClaimed = _tokenAllocated.totalClaimed.add(amountVested);
    
    require(token.transfer(msg.sender, amountVested), "token-sender-transfer-failed");
    emit TokensClaimed(msg.sender, amountVested);
  }

  /// @dev Calculate the vested and unclaimed period and tokens available for `_recepient` to claim
  /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
  function calculateVestingClaim(address _recipient) public view returns (uint64, uint256) {
    Allocation memory _tokenAllocations = tokenAllocations[_recipient];

    // For vesting created with a future start date, that hasn't been reached, return 0, 0
    if (now < _tokenAllocations.startTime) {
      return (0, 0);
    }

    uint256 elapsedTime = now.sub(_tokenAllocations.startTime);
    uint64 elapsedDays = uint64(elapsedTime / SECONDS_PER_DAY);
    
    
    // If over vesting duration, all tokens vested
    if (elapsedDays >= _tokenAllocations.vestingDuration.mul(_tokenAllocations.periodInDays)) {
      uint256 remainingTokens = _tokenAllocations.amount.sub(_tokenAllocations.totalClaimed);
      return (_tokenAllocations.vestingDuration.sub(_tokenAllocations.periodClaimed), remainingTokens);
    } else {
      uint64 elapsedPeriod = elapsedDays.div(_tokenAllocations.periodInDays);
      uint64 periodVested = elapsedPeriod.sub(_tokenAllocations.periodClaimed);
      uint256 amountVestedPerPeriod = _tokenAllocations.amount.div(_tokenAllocations.vestingDuration);
      uint256 amountVested = uint(periodVested).mul(amountVestedPerPeriod);
      return (periodVested, amountVested);
    }
  }

  /// @dev Returns unclaimed allocation of user. 
  function unclaimedAllocation(address _user) external view returns(uint) {
    return tokenAllocations[_user].amount.sub(tokenAllocations[_user].totalClaimed);
  }
}