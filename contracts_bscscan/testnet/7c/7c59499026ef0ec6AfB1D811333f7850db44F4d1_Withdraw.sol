/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// File: contracts/libs/zeppelin/token/BEP20/IBEP20.sol

pragma solidity 0.4.25;

contract IBEP20 {
    function totalSupply() public view returns (uint256);
    function decimals() public view returns (uint8);
    function symbol() public view returns (string memory);
    function name() public view returns (string memory);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function allowance(address _owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/zeppelin/token/BEP20/IGDP.sol

pragma solidity 0.4.25;


contract IGDP is IBEP20 {
  function burn(uint _amount) external;
  function releaseFarmAllocation(address _farmerAddress, uint256 _amount) external;
}

// File: contracts/libs/goldpegas/Context.sol

pragma solidity 0.4.25;

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
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/libs/goldpegas/Auth.sol

pragma solidity 0.4.25;


contract Auth is Context {

  address internal mainAdmin;
  address internal backupAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _mainAdmin,
    address _backupAdmin
  ) internal {
    mainAdmin = _mainAdmin;
    backupAdmin = _backupAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), 'onlyMainAdmin');
    _;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin(), 'onlyBackupAdmin');
    _;
  }

  function transferOwnership(address _newOwner) onlyBackupAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(_msgSender(), _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return _msgSender() == mainAdmin;
  }

  function isBackupAdmin() public view returns (bool) {
    return _msgSender() == backupAdmin;
  }
}

// File: contracts/Withdraw.sol

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;



contract Withdraw is Auth {

  IGDP public gdpToken;
  bool lCT = false;

  event Withdrew(address indexed user, uint amount, string destination, uint timestamp);
  event WithdrewCanceled(address indexed user, string id, uint timestamp);
  event Payout(address indexed user, uint amount, string id, uint timestamp);

  constructor (
    address _mainAdmin,
    address _backupAdmin
  )
  Auth(_mainAdmin, _backupAdmin)
  public {}

  function updateMainAdmin(address _admin) public {
    transferOwnership(_admin);
  }

  function updateBackupAdmin(address _backupAdmin) onlyBackupAdmin public {
    require(_backupAdmin != address(0x0), 'Invalid address');
    backupAdmin = _backupAdmin;
  }

  function uLT(bool _l) onlyMainAdmin public {
    lCT = _l;
  }

  function setToken(address _token) onlyMainAdmin public {
    require(_token != address(0x0), 'Invalid address');
    require(!lCT, 'Can not change token');
    gdpToken = IGDP(_token);
  }

  function withdraw(uint amount, string destination) public {
    emit Withdrew(msg.sender, amount, destination, now);
  }

  function cancelWithdraw(string id) public {
    emit WithdrewCanceled(msg.sender, id, now);
  }

  function payout(address[] _addresses, uint[] _amounts, string[] _ids) onlyMainAdmin public {
    require(_addresses.length == _amounts.length && _amounts.length == _ids.length, 'Data invalid');
    for (uint i = 0; i < _addresses.length; i++) {
      gdpToken.transfer(_addresses[i], _amounts[i]);
      emit Payout(_addresses[i], _amounts[i], _ids[i], now);
    }
  }
}