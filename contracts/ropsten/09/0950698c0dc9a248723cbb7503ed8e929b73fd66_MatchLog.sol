/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.5.15;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Addon {
  function addData(uint32 _supplyPointId, uint16 _yearMonth, uint64 _totalWh, bytes32 _hash)
    public {}

  function reviseData(uint32 _supplyPointId, uint16 _yearMonth, uint64 _totalWh, bytes32 _hash)
    public {}
}

 /**
  * @title MatchLog
  * @dev Record green power trading matching logs
  */
contract MatchLog is WhitelistAdminRole, Pausable {
  Addon addon;

  // supplyPointId => yearMonth => totalWh
  // supplyPointId is 1, 2, 3, etc
  // yearMonth is YYYYMM
  //   00001 represents 2000/01
  //   02012 represents 2020/12
  //   65512 represents 2655/12, the largest valid value
  // totalWh is a monthly summary value of each supply point
  // When addData has never been called, it is an empty data (0)
  // When a supply point doesn't use electricity for a month, it will be assigned 0
  mapping(uint32 => mapping(uint16 => uint64)) public data;

  uint64 public totalKwh;
  mapping(uint16 => uint64) public kwhForMonth;

  // for validation of matches, matches should be unique
  ////mapping(uint32 => bool) private validator;

  // Added include all api searching keys with indexing
  event Added (uint32 indexed supplyPointId, uint16 indexed yearMonth, uint64 totalWh, bytes32 hash);
  // Added Revised event
  event Revised (uint32 indexed supplyPointId, uint16 indexed yearMonth, uint64 totalWh, bytes32 hash);

  /**
    * @dev Add trading log
    */
  function addData(uint32 _supplyPointId, uint16 _yearMonth, uint64 _totalWh, bytes32 _hash)
    public onlyWhitelistAdmin whenNotPaused
  {
    // validation yearMonth
    uint16 year = _yearMonth / 100;
    uint16 month = _yearMonth % 100;
    require(1 <= month && month <= 12 && 20 <= year && year <= 99, "invalid yearMonth format");

    // _supplyPointId, _yearMonthに対してaddDataが呼ばれたことあるならerror
    require(data[_supplyPointId][_yearMonth] == 0, "data already exist");

    data[_supplyPointId][_yearMonth] = _totalWh;

    kwhForMonth[_yearMonth] += _totalWh;

    totalKwh += _totalWh;

    // call proxy contract for additional function
    if(address(addon) != address(0)) {
      addon.addData(_supplyPointId, _yearMonth, _totalWh, _hash);
    }

    ////emit Added(_supplyPointId, _yearMonth, _totalWh, _hash);
  }

  /**
    * @dev Revise trading log
    */
  function reviseData(uint32 _supplyPointId, uint16 _yearMonth, uint64 _totalWh, bytes32 _hash)
    public onlyWhitelistAdmin whenNotPaused
  {
    // validation yearMonth
    uint16 year = _yearMonth / 100;
    uint16 month = _yearMonth % 100;
    require(1 <= month && month <= 12 && 20 <= year && year <= 99, "invalid yearMonth format");

    // _supplyPointId, _yearMonthに対してaddDataが呼ばれたことないならerror
    require(data[_supplyPointId][_yearMonth] != 0, "no data exist");

    // prevTotalWhを計算
    uint64 prevTotalWh = data[_supplyPointId][_yearMonth];

    // data[_supplyPointId][_yearMonth]を修正
    data[_supplyPointId][_yearMonth] = _totalWh;
    // kwhForMonth[_yearMonth]を修正(prevTotalWh使用)
    kwhForMonth[_yearMonth] = kwhForMonth[_yearMonth] - prevTotalWh + _totalWh;
    // totalKwhを修正(prevTotalWh使用)
    totalKwh = totalKwh - prevTotalWh + _totalWh;

    // call proxy contract for additional function
    if(address(addon) != address(0)) {
      addon.reviseData(_supplyPointId, _yearMonth, _totalWh, _hash);
    }

    // call event
    ////emit Revised(_supplyPointId, _yearMonth, _totalWh, _hash);
  }

  /**
    * @dev Add trading logs
    */
  function addDatas(uint32[] memory _supplyPointId, uint16[] memory _yearMonth, uint64[] memory _totalWh, bytes32[] memory _hash)
    public onlyWhitelistAdmin whenNotPaused
  {
    for (uint256 i = 0; i < _supplyPointId.length; i++) {
      addData(_supplyPointId[i], _yearMonth[i], _totalWh[i], _hash[i]);
    }
  }

  /**
    * @dev Revise trading logs
    */
  function reviseDatas(uint32[] memory _supplyPointId, uint16[] memory _yearMonth, uint64[] memory _totalWh, bytes32[] memory _hash)
    public onlyWhitelistAdmin whenNotPaused
  {
    for (uint256 i = 0; i < _supplyPointId.length; i++) {
      reviseData(_supplyPointId[i], _yearMonth[i], _totalWh[i], _hash[i]);
    }
  }

  /**
   * @dev Add admin
   */
  function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
    super.addWhitelistAdmin(account);
  }

  /**
   * @dev Renounce admin
   */
  function renounceWhitelistAdmin() public {
    super.renounceWhitelistAdmin();
  }

  /**
   * @dev Check whether a account is a admin or not
   */
  function isWhitelistAdmin(address account) public view returns (bool) {
    return super.isWhitelistAdmin(account);
  }

  /**
   * @dev Called by a pauser to pause, triggers stopped state.
   */
  function pause() public onlyPauser whenNotPaused {
    return super.pause();
  }

  /**
    * @dev Called by a pauser to unpause, returns to normal state.
    */
  function unpause() public onlyPauser whenPaused {
    return super.unpause();
  }

  /**
    * @dev Check whether a account is a pauser or not
    */
  function isPauser(address account) public view returns (bool) {
    return super.isPauser(account);
  }

  /**
    * @dev Add pauser
    */
  function addPauser(address account) public onlyPauser {
    return super.addPauser(account);
  }

  /**
    * @dev Renounce pauser
    */
  function renouncePauser() public {
    return super.renouncePauser();
  }

  function upgradeAddon(address newAddonAddress) public onlyWhitelistAdmin {
    addon = Addon(newAddonAddress);
  }
}