// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.6;

import '../DS/DSMath.sol';

import '../interfaces/mcd/IManager.sol';
import '../interfaces/mcd/ISpotter.sol';
import '../interfaces/mcd/IVat.sol';

/// @title Getter contract for Vault info from Maker protocol
contract McdView is DSMath {
  address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
  address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
  address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;

  IManager public constant manager = IManager(MANAGER_ADDRESS);
  IVat public constant vat = IVat(VAT_ADDRESS);
  ISpotter public constant spotter = ISpotter(SPOTTER_ADDRESS);

  /// @notice Gets Vault info (collateral, debt)
  /// @param _vaultId Id of the Vault
  /// @param _ilk Ilk of the Vault
  function getVaultInfo(uint256 _vaultId, bytes32 _ilk) public view returns (uint256, uint256) {
    address urn = manager.urns(_vaultId);

    (uint256 collateral, uint256 debt) = vat.urns(_ilk, urn);
    (, uint256 rate, , , ) = vat.ilks(_ilk);

    return (collateral, rmul(debt, rate));
  }

  /// @notice Gets a price of the asset
  /// @param _ilk Ilk of the Vault
  function getPrice(bytes32 _ilk) public view returns (uint256) {
    (, uint256 mat) = spotter.ilks(_ilk);
    (, , uint256 spot, , ) = vat.ilks(_ilk);

    return rmul(rmul(spot, spotter.par()), mat);
  }

  /// @notice Gets Vaults ratio
  /// @param _vaultId Id of the Vault
  function getRatio(uint256 _vaultId) public view returns (uint256) {
    bytes32 ilk = manager.ilks(_vaultId);
    uint256 price = getPrice(ilk);

    (uint256 collateral, uint256 debt) = getVaultInfo(_vaultId, ilk);

    if (debt == 0) return 0;

    return rdiv(wmul(collateral, price), debt) / (10**18);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract DSMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, '');
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, '');
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, '');
  }

  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x / y;
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;

  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IManager {
  function last(address) public virtual returns (uint256);

  function cdpCan(
    address,
    uint256,
    address
  ) public view virtual returns (uint256);

  function ilks(uint256) public view virtual returns (bytes32);

  function owns(uint256) public view virtual returns (address);

  function urns(uint256) public view virtual returns (address);

  function vat() public view virtual returns (address);

  function open(bytes32, address) public virtual returns (uint256);

  function give(uint256, address) public virtual;

  function cdpAllow(
    uint256,
    address,
    uint256
  ) public virtual;

  function urnAllow(address, uint256) public virtual;

  function frob(
    uint256,
    int256,
    int256
  ) public virtual;

  function flux(
    uint256,
    address,
    uint256
  ) public virtual;

  function move(
    uint256,
    address,
    uint256
  ) public virtual;

  function exit(
    address,
    uint256,
    address,
    uint256
  ) public virtual;

  function quit(uint256, address) public virtual;

  function enter(address, uint256) public virtual;

  function shift(uint256, uint256) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './IPipInterface.sol';

abstract contract ISpotter {
  struct Ilk {
    IPipInterface pip;
    uint256 mat;
  }

  mapping(bytes32 => Ilk) public ilks;

  uint256 public par;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IVat {
  struct Urn {
    uint256 ink; // Locked Collateral  [wad]
    uint256 art; // Normalised Debt    [wad]
  }

  struct Ilk {
    uint256 Art; // Total Normalised Debt     [wad]
    uint256 rate; // Accumulated Rates         [ray]
    uint256 spot; // Price with Safety Margin  [ray]
    uint256 line; // Debt Ceiling              [rad]
    uint256 dust; // Urn Debt Floor            [rad]
  }

  mapping(bytes32 => mapping(address => Urn)) public urns;
  mapping(bytes32 => Ilk) public ilks;
  mapping(bytes32 => mapping(address => uint256)) public gem; // [wad]

  function can(address, address) public view virtual returns (uint256);

  function dai(address) public view virtual returns (uint256);

  function frob(
    bytes32,
    address,
    address,
    address,
    int256,
    int256
  ) public virtual;

  function hope(address) public virtual;

  function move(
    address,
    address,
    uint256
  ) public virtual;

  function fork(
    bytes32,
    address,
    address,
    int256,
    int256
  ) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IPipInterface {
  function read() public virtual returns (bytes32);
}

