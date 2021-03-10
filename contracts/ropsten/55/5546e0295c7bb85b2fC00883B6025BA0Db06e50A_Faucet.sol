/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// Sources flattened with hardhat v2.0.10 https://hardhat.org

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]

pragma solidity 0.6.12;

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}


// File contracts/interfaces/Allocatable.sol

pragma solidity 0.6.12;

interface Allocatable {
    function allocateTo(address, uint256) external;
}


// File contracts/interfaces/IBokky.sol

pragma solidity 0.6.12;

interface IBokky {
    function drip() external;
}


// File contracts/interfaces/IFauceteer.sol

pragma solidity 0.6.12;

interface IFauceteer {
  function drip(address token) external;
}


// File contracts/interfaces/IPoly.sol

pragma solidity 0.6.12;

interface IPoly {
  function getTokens(uint256 _amount) external returns (bool);
}


// File contracts/Faucet.sol

pragma solidity 0.6.12;

// import "hardhat/console.sol";





contract Faucet {
  using BoringERC20 for IERC20;

  address[] bokky;

  address[] compound;

  IFauceteer fauceteer;

  IERC20 sushi;

  constructor(
    address[] memory _bokky,
    address[] memory _compound,
    IFauceteer _fauceteer,
    IERC20 _sushi
  ) public {
    bokky = _bokky;
    compound = _compound;
    fauceteer = _fauceteer;
    sushi = _sushi;
  }

  function _dump(address token) private {
    uint256 balance = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransfer(msg.sender, balance);
  }

  function drip() public {
    uint256 id;

    assembly {
      id := chainid()
    }

    sushi.safeTransfer(msg.sender, sushi.balanceOf(address(this)) / 10000); // 0.01%

    for (uint256 i = 0; i < bokky.length; i++) {
      address b = bokky[i];
      IBokky(b).drip();
      _dump(b);
    }

    if (id == 3) {
      IPoly(0x96A62428509002a7aE5F6AD29E4750d852A3f3D7).getTokens(5000 * 1e18);
      _dump(0x96A62428509002a7aE5F6AD29E4750d852A3f3D7);
    }

    if (id == 3 || id == 42) {
      for (uint256 j = 0; j < compound.length; j++) {
        address c = compound[j];
        fauceteer.drip(c);
        _dump(c);
      }
    }

    if (id == 4 || id == 5) {
      for (uint256 k = 0; k < compound.length; k++) {
        address c = compound[k];
        Allocatable(c).allocateTo(
          msg.sender,
          1000 * (10**uint256(IERC20(c).safeDecimals()))
        );
      }
    }
  }
}