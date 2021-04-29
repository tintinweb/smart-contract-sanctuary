/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// File: @axie/contract-library/contracts/access/HasAdmin.sol

pragma solidity ^0.5.2;


contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0));
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}

// File: @axie/contract-library/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.2;



contract Pausable is HasAdmin {
  event Paused();
  event Unpaused();

  bool public paused;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}

// File: contracts/chain/mainchain/PausableAdmin.sol

pragma solidity ^0.5.17;




contract PausableAdmin is HasAdmin {
  Pausable public gateway;

  constructor(Pausable _gateway) public {
    gateway = _gateway;
  }

  function pauseGateway() external onlyAdmin {
    gateway.pause();
  }

  function unpauseGateway() external onlyAdmin {
    gateway.unpause();
  }
}