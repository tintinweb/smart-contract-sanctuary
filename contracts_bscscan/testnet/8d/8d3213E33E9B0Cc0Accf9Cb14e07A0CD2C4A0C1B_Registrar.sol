// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./lib/utils/Context.sol";

contract Registrar is Context {

  address[] private _contracts;
  address private _deployer;

  event SetContracts(address[] addresses);
  event SetContractByIndex(uint8 index, address contractAddressTo);

  /**
   * @dev Constructor that setup the owner of this contract.
   */
  constructor(address deployer_) {
    _deployer = deployer_;
  }

  /**
   * @dev Will have to integrate this with AccessControl
   */
  modifier onlyDeployer() {
      require(_deployer == _msgSender(), "Caller is not the deployer");
      _;
  }

  function getContracts() external view returns (address[] memory) {
    return _contracts;
  }

  function setContracts(address[] calldata _addresses) external onlyDeployer {
    _contracts = _addresses;
    emit SetContracts(_addresses);
  }

  function setContractByIndex(uint8 _index, address _address) external onlyDeployer {
    _contracts[_index] = _address;
    emit SetContractByIndex(_index, _address);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}