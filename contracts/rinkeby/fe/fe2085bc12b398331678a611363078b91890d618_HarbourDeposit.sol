/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface IERC677Receiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external;
}

abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _admins.add(_msgSender());
    emit AdminAdded(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      _admins.has(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function addAdmin(address account) public onlyAdmin {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function renounceAdmin() public onlyAdmin {
    _admins.remove(_msgSender());
    emit AdminRemoved(_msgSender());
  }
}

abstract contract CreatorWithdraw is Context, AdminRole {
  address payable private _creator;

  constructor() {
    _creator = payable(_msgSender());
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {
    // thank you
  }

  function withdraw(address erc20, uint256 amount) public onlyAdmin {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else if (erc20 != address(this)) {
      IERC20(erc20).transfer(_creator, amount);
    }
  }
}

contract HarbourDeposit is IERC677Receiver, AdminRole, CreatorWithdraw {
  using SafeMath for uint256;

  event Deposit(
    uint256 indexed depositId,
    address indexed from,
    IERC20 indexed coin,
    uint256 value
  );
  event Refund(
    uint256 indexed depositId,
    address indexed from,
    IERC20 indexed coin,
    uint256 value
  );
  event Consume(
    uint256 indexed depositId,
    address indexed from,
    IERC20 indexed coin,
    uint256 value
  );

  struct UserDeposit {
    address sender;
    IERC20 coin;
    uint256 value;
  }

  uint256 private _depositCount;
  mapping(uint256 => UserDeposit) private _deposits;

  function _createDeposit(
    address sender,
    IERC20 coin,
    uint256 value
  ) internal returns (uint256) {
    uint256 depositId = _depositCount++;
    _deposits[depositId] = UserDeposit(sender, coin, value);
    emit Deposit(depositId, sender, coin, value);
    return depositId;
  }

  function _removeDeposit(
    uint256 depositId,
    address sender,
    IERC20 coin,
    uint256 value
  ) internal {
    UserDeposit storage found = _deposits[depositId];
    require(found.sender == sender, 'sender_mismatch');
    require(found.coin == coin, 'coin_mismatch');
    require(found.value == value, 'value_mismatch');
    delete _deposits[depositId];
  }

  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory
  ) public {
    _createDeposit(sender, IERC20(_msgSender()), value);
  }

  function deposit(IERC20 coin, uint256 value) public returns (uint256) {
    bool success = coin.transferFrom(_msgSender(), address(this), value);
    require(success, 'erc20_transfer_failed');
    return _createDeposit(_msgSender(), coin, value);
  }

  function refund(
    uint256 depositId,
    address sender,
    IERC20 coin,
    uint256 value
  ) public onlyAdmin returns (bool) {
    _removeDeposit(depositId, sender, coin, value);
    coin.transfer(sender, value);
    emit Refund(depositId, sender, coin, value);
    return true;
  }

  function consume(
    uint256 depositId,
    address sender,
    IERC20 coin,
    uint256 value
  ) public onlyAdmin returns (bool) {
    _removeDeposit(depositId, sender, coin, value);
    coin.transfer(_msgSender(), value);
    emit Consume(depositId, sender, coin, value);
    return true;
  }
}