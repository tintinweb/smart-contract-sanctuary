// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "../libs/fota/Auth.sol";
import "../libs/zeppelin/token/BEP20/IBEP20.sol";
import "../interfaces/IFOTAToken.sol";
import "../interfaces/ILPToken.sol";

contract FarmEarth is Auth {
  struct Farmer {
    uint fotaDeposited;
    uint lpDeposited;
    uint point;
    uint lastDateClaimed;
  }
  mapping (address => Farmer) public farmers;
  IFOTAToken public fotaToken;
  ILPToken public lpToken;
  uint public startTime;
  uint public totalFotaDeposited;
  uint public totalLPDeposited;
  uint public totalPoint;
  uint public totalEarned;
  uint public totalRewarded;
  uint public rewardingDays;
  uint public lpBonus;
  uint constant secondInADay = 86400; // 24 * 60 * 60
  uint constant decimal18 = 1e18;
  uint constant decimal9 = 1e9;

  mapping(uint => uint) dailyReward;
  mapping(uint => uint) dailyClaimed;
  mapping (address => mapping (uint => bool)) public checkin;
  mapping(uint => bool) missProcessed;

  event FOTADeposited(address indexed farmer, uint amount, uint point);
  event LPDeposited(address indexed farmer, uint amount, uint point);
  event RewardingDaysUpdated(uint rewardingDays);
  event LPBonusRateUpdated(uint rate);
  event FOTAFunded(uint amount, uint timestamp);
  event Claimed(address indexed farmer, uint day, uint amount, uint timestamp);
  event Missed(address indexed farmer, uint day, uint amount);
  event Withdrew(address indexed farmer, uint fotaDeposited, uint lpDeposited, uint timestamp);

  modifier initStartTime() {
    require(startTime > 0, "Please init startTime");
    _;
  }

  function initialize(address _mainAdmin) override public initializer {
    super.initialize(_mainAdmin);
    fotaToken = IFOTAToken(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4);
    lpToken = ILPToken(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4); // TODO
    rewardingDays = 14;
    lpBonus = 25e17;
  }

  function depositFOTA(uint _amount) external initStartTime {
    _takeFundFOTA(_amount);
    Farmer storage farmer = farmers[msg.sender];
    farmer.fotaDeposited += _amount;
    farmer.point += _amount;
    totalPoint += _amount;
    _checkin();
    emit FOTADeposited(msg.sender, _amount, _amount);
  }

  function depositLP(uint _amount) external initStartTime {
    uint point = _getPointWhenDepositViaLP(_amount);
    Farmer storage farmer = farmers[msg.sender];
    farmer.lpDeposited += _amount;
    farmer.point += point;
    totalPoint += point;
    _checkin();
    emit LPDeposited(msg.sender, _amount, point);
  }

  function claim() external {
    uint dayPassed = _checkin();
    uint dateToClaim = dayPassed - 1;
    if (checkin[msg.sender][dateToClaim]) {
      bool notClaimYet = farmers[msg.sender].lastDateClaimed < dateToClaim;
      if (notClaimYet) {
        _claim(dateToClaim);
      }
    } else {
      uint reward = farmers[msg.sender].point * dailyReward[dateToClaim] / totalPoint;
      emit Missed(msg.sender, dateToClaim, reward);
    }
    if (!missProcessed[dayPassed]) {
      missProcessed[dayPassed] = true;
      uint missedYesterday = dailyReward[dateToClaim] - dailyClaimed[dateToClaim];
      if (missedYesterday > 0) {
        _fundFOTA(missedYesterday, dayPassed);
      }
    }
  }

  function withdraw() external {
    require(farmers[msg.sender].fotaDeposited > 0 && farmers[msg.sender].lpDeposited > 0, "404");
    _checkClaim();
    uint fotaDeposited = farmers[msg.sender].fotaDeposited;
    uint lpDeposited = farmers[msg.sender].lpDeposited;
    farmers[msg.sender].fotaDeposited = 0;
    farmers[msg.sender].lpDeposited = 0;
    farmers[msg.sender].point = 0;
    farmers[msg.sender].lastDateClaimed = 0;
    if (fotaDeposited > 0) {
      fotaToken.transfer(msg.sender, fotaDeposited);
    }
    if (lpDeposited > 0) {
      lpToken.transfer(msg.sender, lpDeposited);
    }
    emit Withdrew(msg.sender, fotaDeposited, lpDeposited, block.timestamp);
  }

  function fundFOTA(uint _amount) external initStartTime {
    _takeFundFOTA(_amount);
    uint dayPassed = getDaysPassed();
    _fundFOTA(_amount, dayPassed);
  }

  function getDaysPassed() public view returns (uint) {
    uint timePassed = block.timestamp - startTime;
    return timePassed / secondInADay;
  }

  // PRIVATE FUNCTIONS
  function _checkClaim() private {
    uint dayPassed = getDaysPassed();
    uint dateToClaim = dayPassed - 1;
    if (checkin[msg.sender][dateToClaim] && farmers[msg.sender].lastDateClaimed < dateToClaim) {
      _claim(dateToClaim);
    }
  }
  function _claim(uint _dateToClaim) private {
    uint reward = farmers[msg.sender].point * dailyReward[_dateToClaim] / totalPoint;
    dailyClaimed[_dateToClaim] = reward;
    farmers[msg.sender].lastDateClaimed = _dateToClaim;
    fotaToken.transfer(msg.sender, reward);
    emit Claimed(msg.sender, _dateToClaim, reward, block.timestamp);
  }
  function _fundFOTA(uint _amount, uint _dayPassed) private {
    uint restAmount = _amount;
    uint eachDayAmount = _amount / rewardingDays;
    for(uint i = 0; i < rewardingDays - 1; i++) {
      dailyReward[_dayPassed + i] = eachDayAmount;
      restAmount -= eachDayAmount;
    }
    dailyReward[_dayPassed + rewardingDays - 1] = restAmount;
    emit FOTAFunded(_amount, block.timestamp);
  }

  function _getPointWhenDepositViaLP(uint _lpAmount) private view returns (uint) {
    (uint reserve0, uint reserve1) = lpToken.getReserves();
    uint rateInDecimal18 = reserve1 * decimal18 / reserve0;
    // n = _lpAmount / _sqrt(rate)
    // lpBonus / decimal18 = 2.5
    // sqrt(1e18) = 1e9
    return _lpAmount * lpBonus / decimal18 / _sqrt(rateInDecimal18) / decimal9;
  }

  function _takeFundFOTA(uint _amount) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "FarmEarth: please approve fota first");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "FarmEarth: insufficient balance");
    require(fotaToken.transferFrom(msg.sender, address(this), _amount), "FarmEarth: transfer fota failed");
  }

  function _calculateUserTodayReward() private view returns (uint) {
    uint dayPassed = getDaysPassed();
    return farmers[msg.sender].point * dailyReward[dayPassed - 1] / totalPoint;
  }

  function _sqrt(uint x) private pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }
  function _checkin() private  returns (uint) {
    uint dayPassed = getDaysPassed();
    checkin[msg.sender][dayPassed] = true;
    return dayPassed;
  }

  // ADMIN FUNCTIONS
  function start(uint _startTime) external onlyMainAdmin {
    require(startTime == 0, "FarmEarth: startTime had been initialized");
    require(_startTime >= 0 && _startTime < block.timestamp - secondInADay, "FarmEarth: must be earlier yesterday");
    startTime = _startTime;
  }

  function updateRewardingDays(uint _days) external onlyMainAdmin {
    require(_days > 0, "FarmEarth: days invalid");
    rewardingDays = _days;
    emit RewardingDaysUpdated(_days);
  }

  function updateLPBonusRate(uint _rate) external onlyMainAdmin {
    require(_rate > 0, "FarmEarth: rate invalid");
    lpBonus = _rate;
    emit LPBonusRateUpdated(_rate);
  }

  // TODO for testing purpose
  function setContracts(address _fota, address _lp) external onlyMainAdmin {
    fotaToken = IFOTAToken(_fota);
    lpToken = ILPToken(_lp);
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface IFOTAToken is IBEP20 {
  function releaseGameAllocation(address _gamerAddress, uint _amount) external returns (bool);
  function releasePrivateSaleAllocation(address _buyerAddress, uint _amount) external returns (bool);
  function releaseSeedSaleAllocation(address _buyerAddress, uint _amount) external returns (bool);
  function releaseStrategicSaleAllocation(address _buyerAddress, uint _amount) external returns (bool);
  function burn(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface ILPToken is IBEP20 {
  function getReserves() external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address public mainAdmin;
  address public contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event ContractAdminUpdated(address indexed _newOwner);

  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
    contractAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(_isContractAdmin() || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function updateContractAdmin(address _newAdmin) onlyMainAdmin external {
    require(_newAdmin != address(0x0));
    contractAdmin = _newAdmin;
    emit ContractAdminUpdated(_newAdmin);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function _isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}