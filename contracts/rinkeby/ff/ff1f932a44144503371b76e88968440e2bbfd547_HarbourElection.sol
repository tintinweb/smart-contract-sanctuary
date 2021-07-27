/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

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
    require(b > 0, errorMessage);
    uint256 c = a / b;

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

abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      isAdmin(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

contract HarbourElection is AdminRole {
  using SafeMath for uint256;
  enum Vote {
    Null,
    Yes,
    No
  }

  IERC20 public voteToken;
  address payable private _creator;
  mapping(uint256 => mapping(address => Vote)) private _voteByProposalVoter;
  mapping(uint256 => address[]) private _voterListByProposal;
  mapping(uint256 => Vote) private _resultByProposal;

  constructor(address token) {
    _creator = payable(_msgSender());
    voteToken = IERC20(token);
  }

  function submitVote(uint256 proposalIndex, bool yes) public {
    Vote vote = yes ? Vote.Yes : Vote.No;
    Vote existing = _voteByProposalVoter[proposalIndex][msg.sender];
    if (existing != Vote.Null) {
      _voterListByProposal[proposalIndex].push(msg.sender);
    }
    _voteByProposalVoter[proposalIndex][msg.sender] = vote;
  }

  function processProposal(uint256 proposalIndex) public returns (bool) {
    uint256 count = _voterListByProposal[proposalIndex].length;
    uint256 yes = 0;
    uint256 no = 0;
    for (uint256 i = 0; i < count; i++) {
      address voter = _voterListByProposal[proposalIndex][i];
      Vote vote = _voteByProposalVoter[proposalIndex][voter];
      uint256 balance = voteToken.balanceOf(voter);
      if (balance > 0) {
        if (vote == Vote.Yes) {
          yes += balance;
        } else if (vote == Vote.No) {
          no += balance;
        }
      }
    }

    Vote result = yes > no ? Vote.Yes : Vote.No;
    _resultByProposal[proposalIndex] = result;
    return yes > no;
  }
}