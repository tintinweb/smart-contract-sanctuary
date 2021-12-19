/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
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

  function withdrawToken(address erc721, uint256 tokenId) public onlyAdmin {
    IERC721(erc721).transferFrom(address(this), _creator, tokenId);
  }
}

contract HarbourRedeem is AdminRole, CreatorWithdraw, IERC721Receiver {
  address public immutable BURN = 0x000000000000000000000000000000000000dEaD;

  struct DestToken {
    bool isValid;
    bool burn;
    address from;
    address contractAddr;
    uint256 tokenId;
  }
  mapping(address => mapping(uint256 => DestToken)) public tokenMap;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  event SetRedeem(
    address indexed contractAddr,
    uint256 indexed tokenId,
    address destContract,
    uint256 destTokenId
  );
  event Redeem(
    address indexed contractAddr,
    uint256 indexed tokenId,
    address indexed owner,
    address destContract,
    uint256 newTokenId,
    bytes data
  );

  function setRedeem(
    bool burn,
    address contractAddr,
    uint256 tokenId,
    address destContract,
    uint256 destTokenId
  ) external onlyAdmin {
    tokenMap[contractAddr][tokenId] = DestToken(
      true,
      burn,
      _msgSender(),
      destContract,
      destTokenId
    );
    emit SetRedeem(contractAddr, tokenId, destContract, destTokenId);
  }

  function getRedeem(address contractAddr, uint256 tokenId)
    external
    view
    returns (
      bool isValid,
      address destContract,
      uint256 destTokenId
    )
  {
    DestToken storage dest = tokenMap[contractAddr][tokenId];
    return (dest.isValid, dest.contractAddr, dest.tokenId);
  }

  function redeem(
    address contractAddr,
    uint256 tokenId,
    bytes memory data
  ) external returns (address newContract, uint256 newTokenId) {
    require(
      IERC721(contractAddr).ownerOf(tokenId) == _msgSender(),
      'not_owner'
    );
    return _redeem(contractAddr, _msgSender(), _msgSender(), tokenId, data);
  }

  function _redeem(
    address contractAddr,
    address tokenOwner,
    address sender,
    uint256 tokenId,
    bytes memory data
  ) internal returns (address newContract, uint256 newTokenId) {
    DestToken storage dest = tokenMap[contractAddr][tokenId];
    require(dest.isValid, 'not_valid');
    if (dest.burn) {
      IERC721(contractAddr).burn(tokenId);
    } else {
      IERC721(contractAddr).transferFrom(tokenOwner, BURN, tokenId);
    }

    if (dest.contractAddr != address(0)) {
      IERC721(dest.contractAddr).transferFrom(dest.from, sender, dest.tokenId);
      emit Redeem(
        contractAddr,
        tokenId,
        sender,
        dest.contractAddr,
        dest.tokenId,
        data
      );
    } else {
      emit Redeem(contractAddr, tokenId, sender, address(0), 0, data);
    }
    return (dest.contractAddr, dest.tokenId);
  }

  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory data
  ) external virtual override returns (bytes4) {
    _redeem(_msgSender(), address(this), from, tokenId, data);
    return this.onERC721Received.selector;
  }
}