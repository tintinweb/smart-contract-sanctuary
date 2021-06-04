/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/abstract/INXMMaster.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

contract INXMMaster {

  address public tokenAddress;

  address public owner;

  uint public pauseTime;

  function delegateCallBack(bytes32 myid) external;

  function masterInitialized() public view returns (bool);

  function isInternal(address _add) public view returns (bool);

  function isPause() public view returns (bool check);

  function isOwner(address _add) public view returns (bool);

  function isMember(address _add) public view returns (bool);

  function checkIsAuthToGoverned(address _add) public view returns (bool);

  function updatePauseTime(uint _time) public;

  function dAppLocker() public view returns (address _add);

  function dAppToken() public view returns (address _add);

  function getLatestAddress(bytes2 _contractName) public view returns (address payable contractAddress);
}

// File: contracts/abstract/Iupgradable.sol

pragma solidity ^0.5.0;


contract Iupgradable {

  INXMMaster public ms;
  address public nxMasterAddress;

  modifier onlyInternal {
    require(ms.isInternal(msg.sender));
    _;
  }

  modifier isMemberAndcheckPause {
    require(ms.isPause() == false && ms.isMember(msg.sender) == true);
    _;
  }

  modifier onlyOwner {
    require(ms.isOwner(msg.sender));
    _;
  }

  modifier checkPause {
    require(ms.isPause() == false);
    _;
  }

  modifier isMember {
    require(ms.isMember(msg.sender), "Not member");
    _;
  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public;

  /**
   * @dev change master address
   * @param _masterAddress is the new address
   */
  function changeMasterAddress(address _masterAddress) public {
    if (address(ms) != address(0)) {
      require(address(ms) == msg.sender, "Not master");
    }

    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

}

// File: contracts/modules/cover/QuotationData.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;



contract QuotationData is Iupgradable {
  using SafeMath for uint;

  enum HCIDStatus {NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover}

  enum CoverStatus {Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested}

  struct Cover {
    address payable memberAddress;
    bytes4 currencyCode;
    uint sumAssured;
    uint16 coverPeriod;
    uint validUntil;
    address scAddress;
    uint premiumNXM;
  }

  struct HoldCover {
    uint holdCoverId;
    address payable userAddress;
    address scAddress;
    bytes4 coverCurr;
    uint[] coverDetails;
    uint16 coverPeriod;
  }

  address public authQuoteEngine;

  mapping(bytes4 => uint) internal currencyCSA;
  mapping(address => uint[]) internal userCover;
  mapping(address => uint[]) public userHoldedCover;
  mapping(address => bool) public refundEligible;
  mapping(address => mapping(bytes4 => uint)) internal currencyCSAOfSCAdd;
  mapping(uint => uint8) public coverStatus;
  mapping(uint => uint) public holdedCoverIDStatus;
  mapping(uint => bool) public timestampRepeated;


  Cover[] internal allCovers;
  HoldCover[] internal allCoverHolded;

  uint public stlp;
  uint public stl;
  uint public pm;
  uint public minDays;
  uint public tokensRetained;
  address public kycAuthAddress;

  event CoverDetailsEvent(
    uint indexed cid,
    address scAdd,
    uint sumAssured,
    uint expiry,
    uint premium,
    uint premiumNXM,
    bytes4 curr
  );

  event CoverStatusEvent(uint indexed cid, uint8 statusNum);

  constructor(address _authQuoteAdd, address _kycAuthAdd) public {
    authQuoteEngine = _authQuoteAdd;
    kycAuthAddress = _kycAuthAdd;
    stlp = 90;
    stl = 100;
    pm = 30;
    minDays = 30;
    tokensRetained = 10;
    allCovers.push(Cover(address(0), "0x00", 0, 0, 0, address(0), 0));
    uint[] memory arr = new uint[](1);
    allCoverHolded.push(HoldCover(0, address(0), address(0), 0x00, arr, 0));

  }

  /// @dev Adds the amount in Total Sum Assured of a given currency of a given smart contract address.
  /// @param _add Smart Contract Address.
  /// @param _amount Amount to be added.
  function addInTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSAOfSCAdd[_add][_curr] = currencyCSAOfSCAdd[_add][_curr].add(_amount);
  }

  /// @dev Subtracts the amount from Total Sum Assured of a given currency and smart contract address.
  /// @param _add Smart Contract Address.
  /// @param _amount Amount to be subtracted.
  function subFromTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSAOfSCAdd[_add][_curr] = currencyCSAOfSCAdd[_add][_curr].sub(_amount);
  }

  /// @dev Subtracts the amount from Total Sum Assured of a given currency.
  /// @param _curr Currency Name.
  /// @param _amount Amount to be subtracted.
  function subFromTotalSumAssured(bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSA[_curr] = currencyCSA[_curr].sub(_amount);
  }

  /// @dev Adds the amount in Total Sum Assured of a given currency.
  /// @param _curr Currency Name.
  /// @param _amount Amount to be added.
  function addInTotalSumAssured(bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSA[_curr] = currencyCSA[_curr].add(_amount);
  }

  /// @dev sets bit for timestamp to avoid replay attacks.
  function setTimestampRepeated(uint _timestamp) external onlyInternal {
    timestampRepeated[_timestamp] = true;
  }

  /// @dev Creates a blank new cover.
  function addCover(
    uint16 _coverPeriod,
    uint _sumAssured,
    address payable _userAddress,
    bytes4 _currencyCode,
    address _scAddress,
    uint premium,
    uint premiumNXM
  )
  external
  onlyInternal
  {
    uint expiryDate = now.add(uint(_coverPeriod).mul(1 days));
    allCovers.push(Cover(_userAddress, _currencyCode,
      _sumAssured, _coverPeriod, expiryDate, _scAddress, premiumNXM));
    uint cid = allCovers.length.sub(1);
    userCover[_userAddress].push(cid);
    emit CoverDetailsEvent(cid, _scAddress, _sumAssured, expiryDate, premium, premiumNXM, _currencyCode);
  }

  /// @dev create holded cover which will process after verdict of KYC.
  function addHoldCover(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod
  )
  external
  onlyInternal
  {
    uint holdedCoverLen = allCoverHolded.length;
    holdedCoverIDStatus[holdedCoverLen] = uint(HCIDStatus.kycPending);
    allCoverHolded.push(HoldCover(holdedCoverLen, from, scAddress,
      coverCurr, coverDetails, coverPeriod));
    userHoldedCover[from].push(allCoverHolded.length.sub(1));

  }

  ///@dev sets refund eligible bit.
  ///@param _add user address.
  ///@param status indicates if user have pending kyc.
  function setRefundEligible(address _add, bool status) external onlyInternal {
    refundEligible[_add] = status;
  }

  /// @dev to set current status of particular holded coverID (1 for not completed KYC,
  /// 2 for KYC passed, 3 for failed KYC or full refunded,
  /// 4 for KYC completed but cover not processed)
  function setHoldedCoverIDStatus(uint holdedCoverID, uint status) external onlyInternal {
    holdedCoverIDStatus[holdedCoverID] = status;
  }

  /**
   * @dev to set address of kyc authentication
   * @param _add is the new address
   */
  function setKycAuthAddress(address _add) external onlyInternal {
    kycAuthAddress = _add;
  }

  /// @dev Changes authorised address for generating quote off chain.
  function changeAuthQuoteEngine(address _add) external onlyInternal {
    authQuoteEngine = _add;
  }

  /**
   * @dev Gets Uint Parameters of a code
   * @param code whose details we want
   * @return string value of the code
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
    codeVal = code;

    if (code == "STLP") {
      val = stlp;

    } else if (code == "STL") {

      val = stl;

    } else if (code == "PM") {

      val = pm;

    } else if (code == "QUOMIND") {

      val = minDays;

    } else if (code == "QUOTOK") {

      val = tokensRetained;

    }

  }

  /// @dev Gets Product details.
  /// @return  _minDays minimum cover period.
  /// @return  _PM Profit margin.
  /// @return  _STL short term Load.
  /// @return  _STLP short term load period.
  function getProductDetails()
  external
  view
  returns (
    uint _minDays,
    uint _pm,
    uint _stl,
    uint _stlp
  )
  {

    _minDays = minDays;
    _pm = pm;
    _stl = stl;
    _stlp = stlp;
  }

  /// @dev Gets total number covers created till date.
  function getCoverLength() external view returns (uint len) {
    return (allCovers.length);
  }

  /// @dev Gets Authorised Engine address.
  function getAuthQuoteEngine() external view returns (address _add) {
    _add = authQuoteEngine;
  }

  /// @dev Gets the Total Sum Assured amount of a given currency.
  function getTotalSumAssured(bytes4 _curr) external view returns (uint amount) {
    amount = currencyCSA[_curr];
  }

  /// @dev Gets all the Cover ids generated by a given address.
  /// @param _add User's address.
  /// @return allCover array of covers.
  function getAllCoversOfUser(address _add) external view returns (uint[] memory allCover) {
    return (userCover[_add]);
  }

  /// @dev Gets total number of covers generated by a given address
  function getUserCoverLength(address _add) external view returns (uint len) {
    len = userCover[_add].length;
  }

  /// @dev Gets the status of a given cover.
  function getCoverStatusNo(uint _cid) external view returns (uint8) {
    return coverStatus[_cid];
  }

  /// @dev Gets the Cover Period (in days) of a given cover.
  function getCoverPeriod(uint _cid) external view returns (uint32 cp) {
    cp = allCovers[_cid].coverPeriod;
  }

  /// @dev Gets the Sum Assured Amount of a given cover.
  function getCoverSumAssured(uint _cid) external view returns (uint sa) {
    sa = allCovers[_cid].sumAssured;
  }

  /// @dev Gets the Currency Name in which a given cover is assured.
  function getCurrencyOfCover(uint _cid) external view returns (bytes4 curr) {
    curr = allCovers[_cid].currencyCode;
  }

  /// @dev Gets the validity date (timestamp) of a given cover.
  function getValidityOfCover(uint _cid) external view returns (uint date) {
    date = allCovers[_cid].validUntil;
  }

  /// @dev Gets Smart contract address of cover.
  function getscAddressOfCover(uint _cid) external view returns (uint, address) {
    return (_cid, allCovers[_cid].scAddress);
  }

  /// @dev Gets the owner address of a given cover.
  function getCoverMemberAddress(uint _cid) external view returns (address payable _add) {
    _add = allCovers[_cid].memberAddress;
  }

  /// @dev Gets the premium amount of a given cover in NXM.
  function getCoverPremiumNXM(uint _cid) external view returns (uint _premiumNXM) {
    _premiumNXM = allCovers[_cid].premiumNXM;
  }

  /// @dev Provides the details of a cover Id
  /// @param _cid cover Id
  /// @return memberAddress cover user address.
  /// @return scAddress smart contract Address
  /// @return currencyCode currency of cover
  /// @return sumAssured sum assured of cover
  /// @return premiumNXM premium in NXM
  function getCoverDetailsByCoverID1(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    address _memberAddress,
    address _scAddress,
    bytes4 _currencyCode,
    uint _sumAssured,
    uint premiumNXM
  )
  {
    return (
    _cid,
    allCovers[_cid].memberAddress,
    allCovers[_cid].scAddress,
    allCovers[_cid].currencyCode,
    allCovers[_cid].sumAssured,
    allCovers[_cid].premiumNXM
    );
  }

  /// @dev Provides details of a cover Id
  /// @param _cid cover Id
  /// @return status status of cover.
  /// @return sumAssured Sum assurance of cover.
  /// @return coverPeriod Cover Period of cover (in days).
  /// @return validUntil is validity of cover.
  function getCoverDetailsByCoverID2(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil
  )
  {

    return (
    _cid,
    coverStatus[_cid],
    allCovers[_cid].sumAssured,
    allCovers[_cid].coverPeriod,
    allCovers[_cid].validUntil
    );
  }

  /// @dev Provides details of a holded cover Id
  /// @param _hcid holded cover Id
  /// @return scAddress SmartCover address of cover.
  /// @return coverCurr currency of cover.
  /// @return coverPeriod Cover Period of cover (in days).
  function getHoldedCoverDetailsByID1(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address scAddress,
    bytes4 coverCurr,
    uint16 coverPeriod
  )
  {
    return (
    _hcid,
    allCoverHolded[_hcid].scAddress,
    allCoverHolded[_hcid].coverCurr,
    allCoverHolded[_hcid].coverPeriod
    );
  }

  /// @dev Gets total number holded covers created till date.
  function getUserHoldedCoverLength(address _add) external view returns (uint) {
    return userHoldedCover[_add].length;
  }

  /// @dev Gets holded cover index by index of user holded covers.
  function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint) {
    return userHoldedCover[_add][index];
  }

  /// @dev Provides the details of a holded cover Id
  /// @param _hcid holded cover Id
  /// @return memberAddress holded cover user address.
  /// @return coverDetails array contains SA, Cover Currency Price,Price in NXM, Expiration time of Qoute.
  function getHoldedCoverDetailsByID2(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address payable memberAddress,
    uint[] memory coverDetails
  )
  {
    return (
    _hcid,
    allCoverHolded[_hcid].userAddress,
    allCoverHolded[_hcid].coverDetails
    );
  }

  /// @dev Gets the Total Sum Assured amount of a given currency and smart contract address.
  function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns (uint amount) {
    amount = currencyCSAOfSCAdd[_add][_curr];
  }

  //solhint-disable-next-line
  function changeDependentContractAddress() public {}

  /// @dev Changes the status of a given cover.
  /// @param _cid cover Id.
  /// @param _stat New status.
  function changeCoverStatusNo(uint _cid, uint8 _stat) public onlyInternal {
    coverStatus[_cid] = _stat;
    emit CoverStatusEvent(_cid, _stat);
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {

    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "STLP") {
      _changeSTLP(val);

    } else if (code == "STL") {

      _changeSTL(val);

    } else if (code == "PM") {

      _changePM(val);

    } else if (code == "QUOMIND") {

      _changeMinDays(val);

    } else if (code == "QUOTOK") {

      _setTokensRetained(val);

    } else {

      revert("Invalid param code");
    }

  }

  /// @dev Changes the existing Profit Margin value
  function _changePM(uint _pm) internal {
    pm = _pm;
  }

  /// @dev Changes the existing Short Term Load Period (STLP) value.
  function _changeSTLP(uint _stlp) internal {
    stlp = _stlp;
  }

  /// @dev Changes the existing Short Term Load (STL) value.
  function _changeSTL(uint _stl) internal {
    stl = _stl;
  }

  /// @dev Changes the existing Minimum cover period (in days)
  function _changeMinDays(uint _days) internal {
    minDays = _days;
  }

  /**
   * @dev to set the the amount of tokens retained
   * @param val is the amount retained
   */
  function _setTokensRetained(uint val) internal {
    tokensRetained = val;
  }
}