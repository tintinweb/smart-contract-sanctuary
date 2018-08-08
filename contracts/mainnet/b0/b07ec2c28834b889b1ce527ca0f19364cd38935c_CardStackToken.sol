pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

interface ITokenLedger {
  function totalTokens() external view returns (uint256);
  function totalInCirculation() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function mintTokens(uint256 amount) external;
  function transfer(address sender, address reciever, uint256 amount) external;
  function creditAccount(address account, uint256 amount) external;
  function debitAccount(address account, uint256 amount) external;
  function addAdmin(address admin) external;
  function removeAdmin(address admin) external;
}

library CstLibrary {
  using SafeMath for uint256;

  function getTokenName(address _storage) public view returns(bytes32) {
    return ExternalStorage(_storage).getBytes32Value("cstTokenName");
  }

  function setTokenName(address _storage, bytes32 tokenName) public {
    ExternalStorage(_storage).setBytes32Value("cstTokenName", tokenName);
  }

  function getTokenSymbol(address _storage) public view returns(bytes32) {
    return ExternalStorage(_storage).getBytes32Value("cstTokenSymbol");
  }

  function setTokenSymbol(address _storage, bytes32 tokenName) public {
    ExternalStorage(_storage).setBytes32Value("cstTokenSymbol", tokenName);
  }

  function getBuyPrice(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstBuyPrice");
  }

  function setBuyPrice(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstBuyPrice", value);
  }

  function getCirculationCap(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstCirculationCap");
  }

  function setCirculationCap(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstCirculationCap", value);
  }

  function getBalanceLimit(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstBalanceLimit");
  }

  function setBalanceLimit(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstBalanceLimit", value);
  }

  function getFoundation(address _storage) public view returns(address) {
    return ExternalStorage(_storage).getAddressValue("cstFoundation");
  }

  function setFoundation(address _storage, address value) public {
    ExternalStorage(_storage).setAddressValue("cstFoundation", value);
  }

  function getAllowance(address _storage, address account, address spender) public view returns (uint256) {
    return ExternalStorage(_storage).getMultiLedgerValue("cstAllowance", account, spender);
  }

  function setAllowance(address _storage, address account, address spender, uint256 allowance) public {
    ExternalStorage(_storage).setMultiLedgerValue("cstAllowance", account, spender, allowance);
  }

  function getCustomBuyerLimit(address _storage, address buyer) public view returns (uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstCustomBuyerLimit", buyer);
  }

  function setCustomBuyerLimit(address _storage, address buyer, uint256 value) public {
    ExternalStorage(_storage).setLedgerValue("cstCustomBuyerLimit", buyer, value);
  }

  function getCustomBuyerForIndex(address _storage, uint256 index) public view returns (address) {
    return ExternalStorage(_storage).ledgerEntryForIndex(keccak256("cstCustomBuyerLimit"), index);
  }

  function getCustomBuyerMappingCount(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerCount("cstCustomBuyerLimit");
  }

  function getApprovedBuyer(address _storage, address buyer) public view returns (bool) {
    return ExternalStorage(_storage).getBooleanMapValue("cstApprovedBuyer", buyer);
  }

  function setApprovedBuyer(address _storage, address buyer, bool value) public {
    ExternalStorage(_storage).setBooleanMapValue("cstApprovedBuyer", buyer, value);
  }

  function getApprovedBuyerForIndex(address _storage, uint256 index) public view returns (address) {
    return ExternalStorage(_storage).booleanMapEntryForIndex(keccak256("cstApprovedBuyer"), index);
  }

  function getApprovedBuyerMappingCount(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getBooleanMapCount("cstApprovedBuyer");
  }

  function getTotalUnvestedAndUnreleasedTokens(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstUnvestedAndUnreleasedTokens");
  }

  function setTotalUnvestedAndUnreleasedTokens(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstUnvestedAndUnreleasedTokens", value);
  }

  function vestingMappingSize(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerCount("cstFullyVestedAmount");
  }

  function vestingBeneficiaryForIndex(address _storage, uint256 index) public view returns(address) {
    return ExternalStorage(_storage).ledgerEntryForIndex(keccak256("cstFullyVestedAmount"), index);
  }

  function releasableAmount(address _storage, address beneficiary) public view returns (uint256) {
    uint256 releasedAmount = getVestingReleasedAmount(_storage, beneficiary);
    return vestedAvailableAmount(_storage, beneficiary).sub(releasedAmount);
  }

  function vestedAvailableAmount(address _storage, address beneficiary) public view returns (uint256) {
    uint256 start = getVestingStart(_storage, beneficiary);
    uint256 fullyVestedAmount = getFullyVestedAmount(_storage, beneficiary);

    if (start == 0 || fullyVestedAmount == 0) {
      return 0;
    }

    uint256 duration = getVestingDuration(_storage, beneficiary);
    if (duration == 0) {
      return 0;
    }
    uint256 cliff = getVestingCliff(_storage, beneficiary);
    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);

    if (now < cliff || (revokeDate > 0 && revokeDate < cliff)) {
      return 0;
    } else if (revokeDate > 0 && revokeDate > cliff) {
      return fullyVestedAmount.mul(revokeDate.sub(start)).div(duration);
    } else if (now >= start.add(duration)) {
      return fullyVestedAmount;
    } else {
      return fullyVestedAmount.mul(now.sub(start)).div(duration);
    }
  }

  function vestedAmount(address _storage, address beneficiary) public view returns (uint256) {
    uint256 start = getVestingStart(_storage, beneficiary);
    uint256 fullyVestedAmount = getFullyVestedAmount(_storage, beneficiary);

    if (start == 0 || fullyVestedAmount == 0) {
      return 0;
    }

    uint256 duration = getVestingDuration(_storage, beneficiary);
    if (duration == 0) {
      return 0;
    }

    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);

    if (now <= start) {
      return 0;
    } else if (revokeDate > 0) {
      return fullyVestedAmount.mul(revokeDate.sub(start)).div(duration);
    } else if (now >= start.add(duration)) {
      return fullyVestedAmount;
    } else {
      return fullyVestedAmount.mul(now.sub(start)).div(duration);
    }
  }

  function canGrantVestedTokens(address _storage, address beneficiary) public view returns (bool) {
    uint256 existingFullyVestedAmount = getFullyVestedAmount(_storage, beneficiary);
    if (existingFullyVestedAmount == 0) {
      return true;
    }

    uint256 existingVestedAmount = vestedAvailableAmount(_storage, beneficiary);
    uint256 existingReleasedAmount = getVestingReleasedAmount(_storage, beneficiary);
    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);

    if (revokeDate > 0 ||
        (existingVestedAmount == existingFullyVestedAmount &&
        existingReleasedAmount == existingFullyVestedAmount)) {
      return true;
    }

    return false;
  }

  function canRevokeVesting(address _storage, address beneficiary) public view returns (bool) {
    bool isRevocable = getVestingRevocable(_storage, beneficiary);
    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);
    uint256 start = getVestingStart(_storage, beneficiary);
    uint256 duration = getVestingDuration(_storage, beneficiary);

    return start > 0 &&
           isRevocable &&
           revokeDate == 0 &&
           now < start.add(duration);
  }

  function revokeVesting(address _storage, address beneficiary) public {
    require(canRevokeVesting(_storage, beneficiary));

    uint256 totalUnvestedAndUnreleasedAmount = getTotalUnvestedAndUnreleasedTokens(_storage);
    uint256 unvestedAmount = getFullyVestedAmount(_storage, beneficiary).sub(vestedAvailableAmount(_storage, beneficiary));

    setVestingRevokeDate(_storage, beneficiary, now);
    setTotalUnvestedAndUnreleasedTokens(_storage, totalUnvestedAndUnreleasedAmount.sub(unvestedAmount));
  }

  function getVestingSchedule(address _storage, address _beneficiary) public
                                                                      view returns (uint256 startDate,
                                                                                        uint256 cliffDate,
                                                                                        uint256 durationSec,
                                                                                        uint256 fullyVestedAmount,
                                                                                        uint256 releasedAmount,
                                                                                        uint256 revokeDate,
                                                                                        bool isRevocable) {
    startDate         = getVestingStart(_storage, _beneficiary);
    cliffDate         = getVestingCliff(_storage, _beneficiary);
    durationSec       = getVestingDuration(_storage, _beneficiary);
    fullyVestedAmount = getFullyVestedAmount(_storage, _beneficiary);
    releasedAmount    = getVestingReleasedAmount(_storage, _beneficiary);
    revokeDate        = getVestingRevokeDate(_storage, _beneficiary);
    isRevocable       = getVestingRevocable(_storage, _beneficiary);
  }

  function setVestingSchedule(address _storage,
                              address beneficiary,
                              uint256 fullyVestedAmount,
                              uint256 startDate,
                              uint256 cliffDate,
                              uint256 duration,
                              bool isRevocable) public {
    require(canGrantVestedTokens(_storage, beneficiary));

    uint256 totalUnvestedAndUnreleasedAmount = getTotalUnvestedAndUnreleasedTokens(_storage);
    setTotalUnvestedAndUnreleasedTokens(_storage, totalUnvestedAndUnreleasedAmount.add(fullyVestedAmount));

    ExternalStorage(_storage).setLedgerValue("cstVestingStart", beneficiary, startDate);
    ExternalStorage(_storage).setLedgerValue("cstVestingCliff", beneficiary, cliffDate);
    ExternalStorage(_storage).setLedgerValue("cstVestingDuration", beneficiary, duration);
    ExternalStorage(_storage).setLedgerValue("cstFullyVestedAmount", beneficiary, fullyVestedAmount);
    ExternalStorage(_storage).setBooleanMapValue("cstVestingRevocable", beneficiary, isRevocable);

    setVestingRevokeDate(_storage, beneficiary, 0);
    setVestingReleasedAmount(_storage, beneficiary, 0);
  }

  function releaseVestedTokens(address _storage, address beneficiary) public {
    uint256 unreleased = releasableAmount(_storage, beneficiary);
    uint256 releasedAmount = getVestingReleasedAmount(_storage, beneficiary);
    uint256 totalUnvestedAndUnreleasedAmount = getTotalUnvestedAndUnreleasedTokens(_storage);

    releasedAmount = releasedAmount.add(unreleased);
    setVestingReleasedAmount(_storage, beneficiary, releasedAmount);
    setTotalUnvestedAndUnreleasedTokens(_storage, totalUnvestedAndUnreleasedAmount.sub(unreleased));
  }

  function getVestingStart(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingStart", beneficiary);
  }

  function getVestingCliff(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingCliff", beneficiary);
  }

  function getVestingDuration(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingDuration", beneficiary);
  }

  function getFullyVestedAmount(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstFullyVestedAmount", beneficiary);
  }

  function getVestingRevocable(address _storage, address beneficiary) public view returns(bool) {
    return ExternalStorage(_storage).getBooleanMapValue("cstVestingRevocable", beneficiary);
  }

  function setVestingReleasedAmount(address _storage, address beneficiary, uint256 value) public {
    ExternalStorage(_storage).setLedgerValue("cstVestingReleasedAmount", beneficiary, value);
  }

  function getVestingReleasedAmount(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingReleasedAmount", beneficiary);
  }

  function setVestingRevokeDate(address _storage, address beneficiary, uint256 value) public {
    ExternalStorage(_storage).setLedgerValue("cstVestingRevokeDate", beneficiary, value);
  }

  function getVestingRevokeDate(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingRevokeDate", beneficiary);
  }

  function getRewardsContractHash(address _storage) public view returns (bytes32) {
    return ExternalStorage(_storage).getBytes32Value("cstRewardsContractHash");
  }

  function setRewardsContractHash(address _storage, bytes32 rewardsContractHash) public {
    ExternalStorage(_storage).setBytes32Value("cstRewardsContractHash", rewardsContractHash);
  }

}

contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function totalSupply() public view returns (uint256);
  function balanceOf(address account) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract administratable is Ownable {
  using SafeMath for uint256;

  address[] public adminsForIndex;
  address[] public superAdminsForIndex;
  mapping (address => bool) public admins;
  mapping (address => bool) public superAdmins;
  mapping (address => bool) private processedAdmin;
  mapping (address => bool) private processedSuperAdmin;

  event AddAdmin(address indexed admin);
  event RemoveAdmin(address indexed admin);
  event AddSuperAdmin(address indexed admin);
  event RemoveSuperAdmin(address indexed admin);

  modifier onlyAdmins {
    if (msg.sender != owner && !superAdmins[msg.sender] && !admins[msg.sender]) revert();
    _;
  }

  modifier onlySuperAdmins {
    if (msg.sender != owner && !superAdmins[msg.sender]) revert();
    _;
  }

  function totalSuperAdminsMapping() public view returns (uint256) {
    return superAdminsForIndex.length;
  }

  function addSuperAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0));
    superAdmins[admin] = true;
    if (!processedSuperAdmin[admin]) {
      superAdminsForIndex.push(admin);
      processedSuperAdmin[admin] = true;
    }

    emit AddSuperAdmin(admin);
  }

  function removeSuperAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0));
    superAdmins[admin] = false;

    emit RemoveSuperAdmin(admin);
  }

  function totalAdminsMapping() public view returns (uint256) {
    return adminsForIndex.length;
  }

  function addAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0));
    admins[admin] = true;
    if (!processedAdmin[admin]) {
      adminsForIndex.push(admin);
      processedAdmin[admin] = true;
    }

    emit AddAdmin(admin);
  }

  function removeAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0));
    admins[admin] = false;

    emit RemoveAdmin(admin);
  }
}

contract CstLedger is ITokenLedger, administratable {

  using SafeMath for uint256;

  uint256 private _totalInCirculation; // warning this does not take into account unvested nor vested-unreleased tokens into consideration
  uint256 private _totalTokens;
  mapping (address => uint256) private _balanceOf;
  mapping (address => bool) private accounts;
  address[] public accountForIndex;

  function totalTokens() external view returns (uint256) {
    return _totalTokens;
  }

  function totalInCirculation() external view returns (uint256) {
    return _totalInCirculation;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balanceOf[account];
  }

  function mintTokens(uint256 amount) external onlyAdmins {
    _totalTokens = _totalTokens.add(amount);
  }

  function ledgerCount() external view returns (uint256) {
    return accountForIndex.length;
  }

  function makeAccountIterable(address account) internal {
    if (!accounts[account]) {
      accountForIndex.push(account);
      accounts[account] = true;
    }
  }

  function transfer(address sender, address recipient, uint256 amount) external onlyAdmins {
    require(sender != address(0));
    require(recipient != address(0));
    require(_balanceOf[sender] >= amount);

    _balanceOf[sender] = _balanceOf[sender].sub(amount);
    _balanceOf[recipient] = _balanceOf[recipient].add(amount);
    makeAccountIterable(recipient);
  }

  function creditAccount(address account, uint256 amount) external onlyAdmins { // remove tokens
    require(account != address(0));
    require(_balanceOf[account] >= amount);

    _totalInCirculation = _totalInCirculation.sub(amount);
    _balanceOf[account] = _balanceOf[account].sub(amount);
  }

  function debitAccount(address account, uint256 amount) external onlyAdmins { // add tokens
    require(account != address(0));
    _totalInCirculation = _totalInCirculation.add(amount);
    _balanceOf[account] = _balanceOf[account].add(amount);
    makeAccountIterable(account);
  }
}

contract ExternalStorage is administratable {
  using SafeMath for uint256;

  mapping(bytes32 => address[]) public primaryLedgerEntryForIndex;
  mapping(bytes32 => mapping(address => address[])) public secondaryLedgerEntryForIndex;
  mapping(bytes32 => mapping(address => mapping(address => uint256))) private MultiLedgerStorage;
  mapping(bytes32 => mapping(address => bool)) private ledgerPrimaryEntries;
  mapping(bytes32 => mapping(address => mapping(address => bool))) private ledgerSecondaryEntries;

  function getMultiLedgerValue(string record, address primaryAddress, address secondaryAddress) external view returns (uint256) {
    return MultiLedgerStorage[keccak256(abi.encodePacked(record))][primaryAddress][secondaryAddress];
  }

  function primaryLedgerCount(string record) external view returns (uint256) {
    return primaryLedgerEntryForIndex[keccak256(abi.encodePacked(record))].length;
  }

  function secondaryLedgerCount(string record, address primaryAddress) external view returns (uint256) {
    return secondaryLedgerEntryForIndex[keccak256(abi.encodePacked(record))][primaryAddress].length;
  }

  function setMultiLedgerValue(string record, address primaryAddress, address secondaryAddress, uint256 value) external onlyAdmins {
    bytes32 hash = keccak256(abi.encodePacked(record));
    if (!ledgerSecondaryEntries[hash][primaryAddress][secondaryAddress]) {
      secondaryLedgerEntryForIndex[hash][primaryAddress].push(secondaryAddress);
      ledgerSecondaryEntries[hash][primaryAddress][secondaryAddress] = true;

      if (!ledgerPrimaryEntries[hash][primaryAddress]) {
        primaryLedgerEntryForIndex[hash].push(primaryAddress);
        ledgerPrimaryEntries[hash][primaryAddress] = true;
      }
    }

    MultiLedgerStorage[hash][primaryAddress][secondaryAddress] = value;
  }

  mapping(bytes32 => address[]) public ledgerEntryForIndex;
  mapping(bytes32 => mapping(address => uint256)) private LedgerStorage;
  mapping(bytes32 => mapping(address => bool)) private ledgerAccounts;

  function getLedgerValue(string record, address _address) external view returns (uint256) {
    return LedgerStorage[keccak256(abi.encodePacked(record))][_address];
  }

  function getLedgerCount(string record) external view returns (uint256) {
    return ledgerEntryForIndex[keccak256(abi.encodePacked(record))].length;
  }

  function setLedgerValue(string record, address _address, uint256 value) external onlyAdmins {
    bytes32 hash = keccak256(abi.encodePacked(record));
    if (!ledgerAccounts[hash][_address]) {
      ledgerEntryForIndex[hash].push(_address);
      ledgerAccounts[hash][_address] = true;
    }

    LedgerStorage[hash][_address] = value;
  }

  mapping(bytes32 => address[]) public booleanMapEntryForIndex;
  mapping(bytes32 => mapping(address => bool)) private BooleanMapStorage;
  mapping(bytes32 => mapping(address => bool)) private booleanMapAccounts;

  function getBooleanMapValue(string record, address _address) external view returns (bool) {
    return BooleanMapStorage[keccak256(abi.encodePacked(record))][_address];
  }

  function getBooleanMapCount(string record) external view returns (uint256) {
    return booleanMapEntryForIndex[keccak256(abi.encodePacked(record))].length;
  }

  function setBooleanMapValue(string record, address _address, bool value) external onlyAdmins {
    bytes32 hash = keccak256(abi.encodePacked(record));
    if (!booleanMapAccounts[hash][_address]) {
      booleanMapEntryForIndex[hash].push(_address);
      booleanMapAccounts[hash][_address] = true;
    }

    BooleanMapStorage[hash][_address] = value;
  }

  mapping(bytes32 => uint256) private UIntStorage;

  function getUIntValue(string record) external view returns (uint256) {
    return UIntStorage[keccak256(abi.encodePacked(record))];
  }

  function setUIntValue(string record, uint256 value) external onlyAdmins {
    UIntStorage[keccak256(abi.encodePacked(record))] = value;
  }

  mapping(bytes32 => bytes32) private Bytes32Storage;

  function getBytes32Value(string record) external view returns (bytes32) {
    return Bytes32Storage[keccak256(abi.encodePacked(record))];
  }

  function setBytes32Value(string record, bytes32 value) external onlyAdmins {
    Bytes32Storage[keccak256(abi.encodePacked(record))] = value;
  }

  mapping(bytes32 => address) private AddressStorage;

  function getAddressValue(string record) external view returns (address) {
    return AddressStorage[keccak256(abi.encodePacked(record))];
  }

  function setAddressValue(string record, address value) external onlyAdmins {
    AddressStorage[keccak256(abi.encodePacked(record))] = value;
  }

  mapping(bytes32 => bytes) private BytesStorage;

  function getBytesValue(string record) external view returns (bytes) {
    return BytesStorage[keccak256(abi.encodePacked(record))];
  }

  function setBytesValue(string record, bytes value) external onlyAdmins {
    BytesStorage[keccak256(abi.encodePacked(record))] = value;
  }

  mapping(bytes32 => bool) private BooleanStorage;

  function getBooleanValue(string record) external view returns (bool) {
    return BooleanStorage[keccak256(abi.encodePacked(record))];
  }

  function setBooleanValue(string record, bool value) external onlyAdmins {
    BooleanStorage[keccak256(abi.encodePacked(record))] = value;
  }

  mapping(bytes32 => int256) private IntStorage;

  function getIntValue(string record) external view returns (int256) {
    return IntStorage[keccak256(abi.encodePacked(record))];
  }

  function setIntValue(string record, int256 value) external onlyAdmins {
    IntStorage[keccak256(abi.encodePacked(record))] = value;
  }
}

contract configurable {
  function configureFromStorage() public returns (bool);
}

contract displayable {
  function bytes32ToString(bytes32 x) public pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
      if (x[j] != 0) {
        bytesString[charCount] = x[j];
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }
}

contract freezable is administratable {
  using SafeMath for uint256;

  bool public frozenToken;
  // TODO move this into external storage
  address[] public frozenAccountForIndex;
  mapping (address => bool) public frozenAccount;
  mapping (address => bool) private processedAccount;

  event FrozenFunds(address indexed target, bool frozen);
  event FrozenToken(bool frozen);

  modifier unlessFrozen {
    require(!frozenToken);
    require(!frozenAccount[msg.sender]);
    _;
  }

  function totalFrozenAccountsMapping() public view returns(uint256) {
    return frozenAccountForIndex.length;
  }

  function freezeAccount(address target, bool freeze) public onlySuperAdmins {
    frozenAccount[target] = freeze;
    if (!processedAccount[target]) {
      frozenAccountForIndex.push(target);
      processedAccount[target] = true;
    }
    emit FrozenFunds(target, freeze);
  }

  function freezeToken(bool freeze) public onlySuperAdmins {
    frozenToken = freeze;
    emit FrozenToken(frozenToken);
  }

}

contract IStorable {
  function getLedgerNameHash() external view returns (bytes32);
  function getStorageNameHash() external view returns (bytes32);
}

contract upgradeable is administratable {
  address public predecessor;
  address public successor;
  bool public isTokenContract;
  string public version;

  event Upgraded(address indexed successor);
  event UpgradedFrom(address indexed predecessor);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  modifier unlessUpgraded() {
    if (msg.sender != successor && successor != address(0)) revert();
    _;
  }

  modifier isUpgraded() {
    if (successor == address(0)) revert();
    _;
  }

  modifier hasPredecessor() {
    if (predecessor == address(0)) revert();
    _;
  }

  function isDeprecated() public view returns (bool) {
    return successor != address(0);
  }

  function upgradeTo(address _successor, uint256 remainingContractBalance) public onlySuperAdmins unlessUpgraded returns (bool){
    require(_successor != address(0));
    successor = _successor;
    if (remainingContractBalance > 0) {
      emit Transfer(this, _successor, remainingContractBalance);
    }

    emit Upgraded(_successor);
    return true;
  }

  function upgradedFrom(address _predecessor) public onlySuperAdmins returns (bool) {
    require(_predecessor != address(0));

    predecessor = _predecessor;

    emit UpgradedFrom(_predecessor);

    // TODO refactor this into registry contract when ready for registry upgrade
    if (upgradeable(_predecessor).predecessor() != address(0)) {
      if (upgradeable(_predecessor).isTokenContract()) {
        emit Transfer(_predecessor, this, ERC20(_predecessor).balanceOf(_predecessor));
      }
    } else {
      emit Transfer(this, this, 0); // make etherscan see this as an ERC-20. lets remove in v3
    }

    return true;
  }
}

contract CardStackToken is ERC20,
                           freezable,
                           displayable,
                           upgradeable,
                           configurable,
                           IStorable {

  using SafeMath for uint256;
  using CstLibrary for address;

  ITokenLedger public tokenLedger;
  string public storageName;
  string public ledgerName;
  address public externalStorage;
  address public registry;
  uint8 public constant decimals = 18;
  bool public isTokenContract = true;
  bool public haltPurchase;

  // This state is specific to the first version of the CST
  // token contract and the token generation event, and hence
  // there is no reason to persist in external storage for
  // future contracts.
  bool public allowTransfers;
  mapping (address => bool) public whitelistedTransferer;
  address[] public whitelistedTransfererForIndex;
  mapping (address => bool) private processedWhitelistedTransferer;
  uint256 public contributionMinimum;

  event Mint(uint256 amountMinted, uint256 totalTokens, uint256 circulationCap);
  event Approval(address indexed _owner,
                 address indexed _spender,
                 uint256 _value);
  event Transfer(address indexed _from,
                 address indexed _to,
                 uint256 _value);
  event WhiteList(address indexed buyer, uint256 holdCap);
  event ConfigChanged(uint256 buyPrice, uint256 circulationCap, uint256 balanceLimit);
  event VestedTokenGrant(address indexed beneficiary, uint256 startDate, uint256 cliffDate, uint256 durationSec, uint256 fullyVestedAmount, bool isRevocable);
  event VestedTokenRevocation(address indexed beneficiary);
  event VestedTokenRelease(address indexed beneficiary, uint256 amount);
  event StorageUpdated(address storageAddress, address ledgerAddress);
  event PurchaseHalted();
  event PurchaseResumed();

  modifier onlyFoundation {
    address foundation = externalStorage.getFoundation();
    require(foundation != address(0));
    if (msg.sender != owner && msg.sender != foundation) revert();
    _;
  }

  modifier initStorage {
    address ledgerAddress = Registry(registry).getStorage(ledgerName);
    address storageAddress = Registry(registry).getStorage(storageName);

    tokenLedger = ITokenLedger(ledgerAddress);
    externalStorage = storageAddress;
    _;
  }

  constructor(address _registry, string _storageName, string _ledgerName) public payable {
    isTokenContract = true;
    version = "2";
    require(_registry != address(0));
    storageName = _storageName;
    ledgerName = _ledgerName;
    registry = _registry;

    addSuperAdmin(registry);
  }

  /* This unnamed function is called whenever someone tries to send ether directly to the token contract */
  function () public {
    revert(); // Prevents accidental sending of ether
  }

  function getLedgerNameHash() external view returns (bytes32) {
    return keccak256(abi.encodePacked(ledgerName));
  }

  function getStorageNameHash() external view returns (bytes32) {
    return keccak256(abi.encodePacked(storageName));
  }

  function configure(bytes32 _tokenName,
                     bytes32 _tokenSymbol,
                     uint256 _buyPrice,
                     uint256 _circulationCap,
                     uint256 _balanceLimit,
                     address _foundation) public onlySuperAdmins initStorage returns (bool) {

    uint256 __buyPrice= externalStorage.getBuyPrice();
    if (__buyPrice> 0 && __buyPrice!= _buyPrice) {
      require(frozenToken);
    }

    externalStorage.setTokenName(_tokenName);
    externalStorage.setTokenSymbol(_tokenSymbol);
    externalStorage.setBuyPrice(_buyPrice);
    externalStorage.setCirculationCap(_circulationCap);
    externalStorage.setFoundation(_foundation);
    externalStorage.setBalanceLimit(_balanceLimit);

    emit ConfigChanged(_buyPrice, _circulationCap, _balanceLimit);

    return true;
  }

  function configureFromStorage() public onlySuperAdmins unlessUpgraded initStorage returns (bool) {
    freezeToken(true);
    return true;
  }

  function updateStorage(string newStorageName, string newLedgerName) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(frozenToken);

    storageName = newStorageName;
    ledgerName = newLedgerName;

    configureFromStorage();

    address ledgerAddress = Registry(registry).getStorage(ledgerName);
    address storageAddress = Registry(registry).getStorage(storageName);
    emit StorageUpdated(storageAddress, ledgerAddress);
    return true;
  }

  function name() public view unlessUpgraded returns(string) {
    return bytes32ToString(externalStorage.getTokenName());
  }

  function symbol() public view unlessUpgraded returns(string) {
    return bytes32ToString(externalStorage.getTokenSymbol());
  }

  function totalInCirculation() public view unlessUpgraded returns(uint256) {
    return tokenLedger.totalInCirculation().add(totalUnvestedAndUnreleasedTokens());
  }

  function cstBalanceLimit() public view unlessUpgraded returns(uint256) {
    return externalStorage.getBalanceLimit();
  }

  function buyPrice() public view unlessUpgraded returns(uint256) {
    return externalStorage.getBuyPrice();
  }

  function circulationCap() public view unlessUpgraded returns(uint256) {
    return externalStorage.getCirculationCap();
  }

  // intentionally allowing this to be visible if upgraded so foundation can
  // withdraw funds from contract that has a successor
  function foundation() public view returns(address) {
    return externalStorage.getFoundation();
  }

  function totalSupply() public view unlessUpgraded returns(uint256) {
    return tokenLedger.totalTokens();
  }

  function tokensAvailable() public view unlessUpgraded returns(uint256) {
    return totalSupply().sub(totalInCirculation());
  }

  function balanceOf(address account) public view unlessUpgraded returns (uint256) {
    address thisAddress = this;
    if (thisAddress == account) {
      return tokensAvailable();
    } else {
      return tokenLedger.balanceOf(account);
    }
  }

  function transfer(address recipient, uint256 amount) public unlessFrozen unlessUpgraded returns (bool) {
    require(allowTransfers || whitelistedTransferer[msg.sender]);
    require(amount > 0);
    require(!frozenAccount[recipient]);

    tokenLedger.transfer(msg.sender, recipient, amount);
    emit Transfer(msg.sender, recipient, amount);

    return true;
  }

  function mintTokens(uint256 mintedAmount) public onlySuperAdmins unlessUpgraded returns (bool) {
    uint256 _circulationCap = externalStorage.getCirculationCap();
    tokenLedger.mintTokens(mintedAmount);

    emit Mint(mintedAmount, tokenLedger.totalTokens(), _circulationCap);

    emit Transfer(address(0), this, mintedAmount);

    return true;
  }

  function grantTokens(address recipient, uint256 amount) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(amount <= tokensAvailable());
    require(!frozenAccount[recipient]);

    tokenLedger.debitAccount(recipient, amount);
    emit Transfer(this, recipient, amount);

    return true;
  }

  function setHaltPurchase(bool _haltPurchase) public onlySuperAdmins unlessUpgraded returns (bool) {
    haltPurchase = _haltPurchase;

    if (_haltPurchase) {
      emit PurchaseHalted();
    } else {
      emit PurchaseResumed();
    }
    return true;
  }

  function buy() external payable unlessFrozen unlessUpgraded returns (uint256) {
    require(!haltPurchase);
    require(externalStorage.getApprovedBuyer(msg.sender));

    uint256 _buyPriceTokensPerWei = externalStorage.getBuyPrice();
    uint256 _circulationCap = externalStorage.getCirculationCap();
    require(msg.value > 0);
    require(_buyPriceTokensPerWei > 0);
    require(_circulationCap > 0);

    uint256 amount = msg.value.mul(_buyPriceTokensPerWei);
    require(totalInCirculation().add(amount) <= _circulationCap);
    require(amount <= tokensAvailable());

    uint256 balanceLimit;
    uint256 buyerBalance = tokenLedger.balanceOf(msg.sender);
    uint256 customLimit = externalStorage.getCustomBuyerLimit(msg.sender);
    require(contributionMinimum == 0 || buyerBalance.add(amount) >= contributionMinimum);

    if (customLimit > 0) {
      balanceLimit = customLimit;
    } else {
      balanceLimit = externalStorage.getBalanceLimit();
    }

    require(balanceLimit > 0 && balanceLimit >= buyerBalance.add(amount));

    tokenLedger.debitAccount(msg.sender, amount);
    emit Transfer(this, msg.sender, amount);

    return amount;
  }

  // intentionally allowing this to be visible if upgraded so foundation can
  // withdraw funds from contract that has a successor
  function foundationWithdraw(uint256 amount) public onlyFoundation returns (bool) {
    /* UNTRUSTED */
    msg.sender.transfer(amount);

    return true;
  }

  function foundationDeposit() public payable unlessUpgraded returns (bool) {
    return true;
  }

  function allowance(address owner, address spender) public view unlessUpgraded returns (uint256) {
    return externalStorage.getAllowance(owner, spender);
  }

  function transferFrom(address from, address to, uint256 value) public unlessFrozen unlessUpgraded returns (bool) {
    require(allowTransfers);
    require(!frozenAccount[from]);
    require(!frozenAccount[to]);
    require(from != msg.sender);
    require(value > 0);

    uint256 allowanceValue = allowance(from, msg.sender);
    require(allowanceValue >= value);

    tokenLedger.transfer(from, to, value);
    externalStorage.setAllowance(from, msg.sender, allowanceValue.sub(value));

    emit Transfer(from, to, value);
    return true;
  }

  /* Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Please use `increaseApproval` or `decreaseApproval` instead.
   */
  function approve(address spender, uint256 value) public unlessFrozen unlessUpgraded returns (bool) {
    require(spender != address(0));
    require(!frozenAccount[spender]);
    require(msg.sender != spender);

    externalStorage.setAllowance(msg.sender, spender, value);

    emit Approval(msg.sender, spender, value);
    return true;
  }

  function increaseApproval(address spender, uint256 addedValue) public unlessFrozen unlessUpgraded returns (bool) {
    return approve(spender, externalStorage.getAllowance(msg.sender, spender).add(addedValue));
  }

  function decreaseApproval(address spender, uint256 subtractedValue) public unlessFrozen unlessUpgraded returns (bool) {
    uint256 oldValue = externalStorage.getAllowance(msg.sender, spender);

    if (subtractedValue > oldValue) {
      return approve(spender, 0);
    } else {
      return approve(spender, oldValue.sub(subtractedValue));
    }
  }

  function grantVestedTokens(address beneficiary,
                             uint256 fullyVestedAmount,
                             uint256 startDate, // 0 indicates start "now"
                             uint256 cliffSec,
                             uint256 durationSec,
                             bool isRevocable) public onlySuperAdmins unlessUpgraded returns(bool) {

    uint256 _circulationCap = externalStorage.getCirculationCap();

    require(beneficiary != address(0));
    require(!frozenAccount[beneficiary]);
    require(durationSec >= cliffSec);
    require(totalInCirculation().add(fullyVestedAmount) <= _circulationCap);
    require(fullyVestedAmount <= tokensAvailable());

    uint256 _now = now;
    if (startDate == 0) {
      startDate = _now;
    }

    uint256 cliffDate = startDate.add(cliffSec);

    externalStorage.setVestingSchedule(beneficiary,
                                       fullyVestedAmount,
                                       startDate,
                                       cliffDate,
                                       durationSec,
                                       isRevocable);

    emit VestedTokenGrant(beneficiary, startDate, cliffDate, durationSec, fullyVestedAmount, isRevocable);

    return true;
  }


  function revokeVesting(address beneficiary) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(beneficiary != address(0));
    externalStorage.revokeVesting(beneficiary);

    releaseVestedTokensForBeneficiary(beneficiary);

    emit VestedTokenRevocation(beneficiary);

    return true;
  }

  function releaseVestedTokens() public unlessFrozen unlessUpgraded returns (bool) {
    return releaseVestedTokensForBeneficiary(msg.sender);
  }

  function releaseVestedTokensForBeneficiary(address beneficiary) public unlessFrozen unlessUpgraded returns (bool) {
    require(beneficiary != address(0));
    require(!frozenAccount[beneficiary]);

    uint256 unreleased = releasableAmount(beneficiary);

    if (unreleased == 0) { return true; }

    externalStorage.releaseVestedTokens(beneficiary);

    tokenLedger.debitAccount(beneficiary, unreleased);
    emit Transfer(this, beneficiary, unreleased);

    emit VestedTokenRelease(beneficiary, unreleased);

    return true;
  }

  function releasableAmount(address beneficiary) public view unlessUpgraded returns (uint256) {
    return externalStorage.releasableAmount(beneficiary);
  }

  function totalUnvestedAndUnreleasedTokens() public view unlessUpgraded returns (uint256) {
    return externalStorage.getTotalUnvestedAndUnreleasedTokens();
  }

  function vestingMappingSize() public view unlessUpgraded returns (uint256) {
    return externalStorage.vestingMappingSize();
  }

  function vestingBeneficiaryForIndex(uint256 index) public view unlessUpgraded returns (address) {
    return externalStorage.vestingBeneficiaryForIndex(index);
  }

  function vestingSchedule(address _beneficiary) public
                                                 view unlessUpgraded returns (uint256 startDate,
                                                                              uint256 cliffDate,
                                                                              uint256 durationSec,
                                                                              uint256 fullyVestedAmount,
                                                                              uint256 vestedAmount,
                                                                              uint256 vestedAvailableAmount,
                                                                              uint256 releasedAmount,
                                                                              uint256 revokeDate,
                                                                              bool isRevocable) {
    (
      startDate,
      cliffDate,
      durationSec,
      fullyVestedAmount,
      releasedAmount,
      revokeDate,
      isRevocable
    ) =  externalStorage.getVestingSchedule(_beneficiary);

    vestedAmount = externalStorage.vestedAmount(_beneficiary);
    vestedAvailableAmount = externalStorage.vestedAvailableAmount(_beneficiary);
  }

  function totalCustomBuyersMapping() public view returns (uint256) {
    return externalStorage.getCustomBuyerMappingCount();
  }

  function customBuyerLimit(address buyer) public view returns (uint256) {
    return externalStorage.getCustomBuyerLimit(buyer);
  }

  function customBuyerForIndex(uint256 index) public view returns (address) {
    return externalStorage.getCustomBuyerForIndex(index);
  }

  function setCustomBuyer(address buyer, uint256 balanceLimit) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(buyer != address(0));
    externalStorage.setCustomBuyerLimit(buyer, balanceLimit);
    addBuyer(buyer);

    return true;
  }

  function setAllowTransfers(bool _allowTransfers) public onlySuperAdmins unlessUpgraded returns (bool) {
    allowTransfers = _allowTransfers;
    return true;
  }

  function setContributionMinimum(uint256 _contributionMinimum) public onlySuperAdmins unlessUpgraded returns (bool) {
    contributionMinimum = _contributionMinimum;
    return true;
  }

  function totalBuyersMapping() public view returns (uint256) {
    return externalStorage.getApprovedBuyerMappingCount();
  }

  function approvedBuyer(address buyer) public view returns (bool) {
    return externalStorage.getApprovedBuyer(buyer);
  }

  function approvedBuyerForIndex(uint256 index) public view returns (address) {
    return externalStorage.getApprovedBuyerForIndex(index);
  }

  function addBuyer(address buyer) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(buyer != address(0));
    externalStorage.setApprovedBuyer(buyer, true);

    uint256 balanceLimit = externalStorage.getCustomBuyerLimit(buyer);
    if (balanceLimit == 0) {
      balanceLimit = externalStorage.getBalanceLimit();
    }

    emit WhiteList(buyer, balanceLimit);

    return true;
  }

  function removeBuyer(address buyer) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(buyer != address(0));
    externalStorage.setApprovedBuyer(buyer, false);

    return true;
  }

  function totalTransferWhitelistMapping() public view returns (uint256) {
    return whitelistedTransfererForIndex.length;
  }

  function setWhitelistedTransferer(address transferer, bool _allowTransfers) public onlySuperAdmins unlessUpgraded returns (bool) {
    require(transferer != address(0));
    whitelistedTransferer[transferer] = _allowTransfers;
    if (!processedWhitelistedTransferer[transferer]) {
      whitelistedTransfererForIndex.push(transferer);
      processedWhitelistedTransferer[transferer] = true;
    }

    return true;
  }
}

contract Registry is administratable, upgradeable {
  using SafeMath for uint256;

  bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
  bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
  bytes32 constant BARE_DOMAIN_NAMEHASH = 0x794941fae74d6435d1b29ee1c08cc39941ba78470872e6afd0693c7eeb63025c; // namehash for "cardstack.eth"

  mapping(bytes32 => address) public storageForHash;
  mapping(bytes32 => address) public contractForHash;
  mapping(bytes32 => bytes32) public hashForNamehash;
  mapping(bytes32 => bytes32) public namehashForHash;
  string[] public contractNameForIndex;

  event ContractRegistered(address indexed _contract, string _name, bytes32 namehash);
  event ContractUpgraded(address indexed successor, address indexed predecessor, string name, bytes32 namehash);
  event StorageAdded(address indexed storageAddress, string name);
  event StorageRemoved(address indexed storageAddress, string name);
  event AddrChanged(bytes32 indexed node, address a);

  function() public {
    revert();
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == ADDR_INTERFACE_ID ||
           interfaceId == INTERFACE_META_ID;
  }

  function addr(bytes32 node) public view returns (address) {
    return contractForHash[hashForNamehash[node]];
  }

  function getContractHash(string name) public view unlessUpgraded returns (bytes32) {
    return keccak256(abi.encodePacked(name));
  }

  function numContracts() public view returns(uint256) {
    return contractNameForIndex.length;
  }

  function setNamehash(string contractName, bytes32 namehash) external onlySuperAdmins unlessUpgraded returns (bool) {
    require(namehash != 0x0);

    bytes32 hash = keccak256(abi.encodePacked(contractName));
    address contractAddress = contractForHash[hash];

    require(contractAddress != 0x0);
    require(hashForNamehash[namehash] == 0x0);

    hashForNamehash[namehash] = hash;
    namehashForHash[hash] = namehash;

    emit AddrChanged(namehash, contractAddress);
  }

  function register(string name, address contractAddress, bytes32 namehash) external onlySuperAdmins unlessUpgraded returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(name));
    require(bytes(name).length > 0);
    require(contractAddress != 0x0);
    require(contractForHash[hash] == 0x0);
    require(hashForNamehash[namehash] == 0x0);

    contractNameForIndex.push(name);
    contractForHash[hash] = contractAddress;

    if (namehash != 0x0) {
      hashForNamehash[namehash] = hash;
      namehashForHash[hash] = namehash;
    }

    address storageAddress = storageForHash[IStorable(contractAddress).getStorageNameHash()];
    address ledgerAddress = storageForHash[IStorable(contractAddress).getLedgerNameHash()];

    if (storageAddress != 0x0) {
      ExternalStorage(storageAddress).addAdmin(contractAddress);
    }
    if (ledgerAddress != 0x0) {
      CstLedger(ledgerAddress).addAdmin(contractAddress);
    }

    configurable(contractAddress).configureFromStorage();

    emit ContractRegistered(contractAddress, name, namehash);

    if (namehash != 0x0) {
      emit AddrChanged(namehash, contractAddress);
    }

    return true;
  }

  function upgradeContract(string name, address successor) external onlySuperAdmins unlessUpgraded returns (bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(name));
    require(successor != 0x0);
    require(contractForHash[hash] != 0x0);

    address predecessor = contractForHash[hash];
    require(freezable(predecessor).frozenToken());

    contractForHash[hash] = successor;

    uint256 remainingContractBalance;
    // we need https://github.com/ethereum/EIPs/issues/165
    // to be able to see if a contract is ERC20 or not...
    if (hash == keccak256("cst")) {
      remainingContractBalance = ERC20(predecessor).balanceOf(predecessor);
    }

    upgradeable(predecessor).upgradeTo(successor,
                                       remainingContractBalance);
    upgradeable(successor).upgradedFrom(predecessor);

    address successorStorageAddress = storageForHash[IStorable(successor).getStorageNameHash()];
    address successorLedgerAddress = storageForHash[IStorable(successor).getLedgerNameHash()];
    address predecessorStorageAddress = storageForHash[IStorable(predecessor).getStorageNameHash()];
    address predecessorLedgerAddress = storageForHash[IStorable(predecessor).getLedgerNameHash()];

    if (successorStorageAddress != 0x0) {
      ExternalStorage(successorStorageAddress).addAdmin(successor);
    }
    if (predecessorStorageAddress != 0x0) {
      ExternalStorage(predecessorStorageAddress).removeAdmin(predecessor);
    }

    if (successorLedgerAddress != 0x0) {
      CstLedger(successorLedgerAddress).addAdmin(successor);
    }
    if (predecessorLedgerAddress != 0x0) {
      CstLedger(predecessorLedgerAddress).removeAdmin(predecessor);
    }

    configurable(successor).configureFromStorage();

    if (hashForNamehash[BARE_DOMAIN_NAMEHASH] == hash) {
      emit AddrChanged(BARE_DOMAIN_NAMEHASH, successor);
    }
    if (namehashForHash[hash] != 0x0 && namehashForHash[hash] != BARE_DOMAIN_NAMEHASH) {
      emit AddrChanged(namehashForHash[hash], successor);
    }

    emit ContractUpgraded(successor, predecessor, name, namehashForHash[hash]);
    return hash;
  }

  function addStorage(string name, address storageAddress) external onlySuperAdmins unlessUpgraded {
    require(storageAddress != address(0));
    bytes32 hash = keccak256(abi.encodePacked(name));
    storageForHash[hash] = storageAddress;

    emit StorageAdded(storageAddress, name);
  }

  function getStorage(string name) public view unlessUpgraded returns (address) {
    return storageForHash[keccak256(abi.encodePacked(name))];
  }

  function removeStorage(string name) public onlySuperAdmins unlessUpgraded {
    address storageAddress = storageForHash[keccak256(abi.encodePacked(name))];
    delete storageForHash[keccak256(abi.encodePacked(name))];

    emit StorageRemoved(storageAddress, name);
  }
}