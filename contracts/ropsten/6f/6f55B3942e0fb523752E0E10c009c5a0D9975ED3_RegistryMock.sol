// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/Curve/IRegistry.sol";

// solhint-disable func-name-mixedcase
contract RegistryMock is IRegistry {
  struct Pool {
    uint256 n;
    address[8] coins;
    address lp;
  }

  mapping(address => Pool) internal _pools;

  address[] internal _addedPools;

  function addPool(address pool, Pool memory data) external {
    _pools[pool] = data;
    _addedPools.push(pool);
  }

  function get_n_coins(address pool) external view override returns (uint256) {
    return _pools[pool].n;
  }

  function get_coins(address pool) external view override returns (address[8] memory) {
    return _pools[pool].coins;
  }

  function get_pool_from_lp_token(address lpToken) external view override returns (address pool) {
    for (uint256 i = 0; i < _addedPools.length; i++) {
      if (_pools[_addedPools[i]].lp == lpToken) pool = _addedPools[i];
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IRegistry {
  function get_n_coins(address pool) external view returns (uint256);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_pool_from_lp_token(address) external view returns (address);
}