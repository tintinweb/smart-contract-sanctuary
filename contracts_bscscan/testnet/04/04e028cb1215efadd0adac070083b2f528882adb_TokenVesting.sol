/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-04
*/


pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;




contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin, "HasAdmin: not admin");
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0), "HasAdmin: new admin is the zero address");
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath: addition overflow");
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Since Solidity automatically asserts when dividing by 0,
    // but we only need it to revert.
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Same reason as `div`.
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }
}


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}



contract TokenVesting is HasAdmin {
  using SafeMath for uint256;

  /**
    * @dev a Chunk is a period of time in which the beneficiary can receive the same amount of token each time a followUpDuration passes,
    * starting from effectiveDate (in relative to startTime).
   */
  struct Chunk {
    uint32 effectiveDate; // Duration from startTime that the chunk becomes effective
    uint256 amountPerUnlock;
    uint32 followUps;
    uint32 followUpDuration;
  }

  struct BeneficiaryInfo {
    uint32 index; // Location of beneficiary in beneficiaryAddresses.
    Chunk[] chunks;
    uint256 claimedAmount;
  }

  event StartTimeSet(uint256 _startTime);
  event BeneficiaryAdded(address indexed _beneficiary, uint32 _index);
  event BeneficiaryRemoved(address indexed _beneficiary);
  event TokenClaimed(address indexed _beneficiary, uint256 _amount);

  IERC20 public token;
  uint256 public startTime;
  mapping(address => BeneficiaryInfo) public beneficiaries;

  address[] public beneficiaryAddresses;

//   constructor(IERC20 _token, uint256 _startTime) public {
//     token = _token;
//     editStartTime(_startTime);
//     // Add a dummy address so all beneficiary index will be positive.
//     beneficiaryAddresses.push(address(0));
//   }

  constructor() public {
    //token = _token;
    //editStartTime(_startTime);
    // Add a dummy address so all beneficiary index will be positive.
    beneficiaryAddresses.push(address(0));
  }


  function editStartTime(uint256 _newTime) public onlyAdmin {
    startTime = _newTime;
    emit StartTimeSet(startTime);
  }

  /**
   * @dev Function for admin to add another beneficiary, initiate with chunks.
  */
  function addBeneficiary(address _beneficiary, Chunk[] calldata _chunks) external onlyAdmin {
    require(beneficiaries[_beneficiary].index == 0, "TokenVesting: Beneficiary already existed");

    uint32 _index = uint32(beneficiaryAddresses.length);
    beneficiaries[_beneficiary].index = _index;
    addChunks(_beneficiary, _chunks);
    beneficiaryAddresses.push(_beneficiary);

    emit BeneficiaryAdded(_beneficiary, _index);
  }

  /**
   * @dev Function for admin to add more chunks for a specific beneficiary.
  */
  function addChunks(address _beneficiary, Chunk[] memory _chunks) public onlyAdmin {
    require(beneficiaries[_beneficiary].index > 0, "TokenVesting: Beneficiary not existed");

    Chunk[] storage _beneficiaryChunks = beneficiaries[_beneficiary].chunks;

    for (uint256 _i = 0; _i < _chunks.length; _i++) {
        _beneficiaryChunks.push(_chunks[_i]);
    }
  }

  /**
   * @dev Remove beneficiary, only used in rare cases that need some modifications.
  */
  function removeBeneficiary(address _beneficiary) external onlyAdmin {
    require(beneficiaries[_beneficiary].index > 0, "TokenVesting: Beneficiary not existed");

    uint32 _currentIndex = beneficiaries[_beneficiary].index;
    uint256 _lastIndex = beneficiaryAddresses.length.sub(1);

    // Replace by last item in array
    beneficiaryAddresses[_currentIndex] = beneficiaryAddresses[_lastIndex];
    beneficiaries[beneficiaryAddresses[_currentIndex]].index = _currentIndex;

    beneficiaryAddresses.pop();
    delete beneficiaries[_beneficiary];

    emit BeneficiaryRemoved(_beneficiary);
  }

  /**
   * @dev Remove beneficiary, only used in rare cases that need some modifications.
  */
  function getBeneficiaryList() external view returns (address[] memory) {
    return beneficiaryAddresses;
  }

  /**
   * @dev Query chunks of a beneficiary.
  */
  function beneficiaryChunks(address _beneficiary) external view returns (Chunk[] memory _chunks) {
    _chunks = beneficiaries[_beneficiary].chunks;
  }

  /**
   * @dev Query total allocated token, both unlocked and locked.
  */
  function totalAllocatedAmount(address _beneficiary) external view returns (uint256 _amount) {
    Chunk[] storage _chunks = beneficiaries[_beneficiary].chunks;

    for (uint256 _i = 0; _i < _chunks.length; _i++) {
      Chunk storage _chunk = _chunks[_i];
      _amount = _amount.add(_chunk.amountPerUnlock.mul(uint256(1).add(_chunk.followUps)));
    }
  }

  /**
   * @dev Query unlocked amount at the current time.
   * @return total unlocked amount so far and claimable amount.
  */
  function unlockedAmount(address _beneficiary) public view returns (uint256 _totalUnlocked, uint256 _claimable) {
    _totalUnlocked = unlockedAt(_beneficiary, block.timestamp);

    uint256 _claimedAmount = beneficiaries[_beneficiary].claimedAmount;
    _claimable = _totalUnlocked.sub(_claimedAmount);
  }

  /**
   * @dev Query unlocked amount at the specific timestamp.
   * @return total unlocked amount at that timestamp
  */
  function unlockedAt(address _beneficiary, uint256 _timestamp) public view returns (uint256 _totalUnlocked) {
    Chunk[] storage _chunks = beneficiaries[_beneficiary].chunks;

    for (uint256 _i = 0; _i < _chunks.length; _i++) {
      Chunk storage _chunk = _chunks[_i];

      if (startTime.add(_chunk.effectiveDate) <= _timestamp) {
        // Calculate how many follow-ups have occured
        uint256 followUps = 0;

        if (_chunk.followUpDuration > 0) {
          followUps = _timestamp.sub(startTime.add(_chunks[_i].effectiveDate)).div(_chunk.followUpDuration);
        }

        if (followUps > _chunk.followUps) {
          followUps = _chunk.followUps;
        }

        // There are (followUps + 1) unlocks have happened
        _totalUnlocked = _totalUnlocked.add(_chunk.amountPerUnlock.mul(followUps.add(1)));
      }
    }
  }

  /**
   * @dev Allows beneficiary to claim claimable tokens, can be called by anyone.
  */
  function claimToken(address _beneficiary) external {
    (uint256 _totalUnlocked, uint256 _claimable) = unlockedAmount(_beneficiary);
    require(_claimable > 0, "TokenVesting: No claimable amount");

    beneficiaries[_beneficiary].claimedAmount = _totalUnlocked;
    token.transfer(_beneficiary, _claimable);

    emit TokenClaimed(_beneficiary, _claimable);
  }
}