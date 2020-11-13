pragma solidity ^0.6.12;

import "./external/MixedPodInterface.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Implementer.sol";

contract MigrateV2ToV3 is OwnableUpgradeSafe, IERC777Recipient, IERC1820Implementer {

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  bytes32 constant private _ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH =
  0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  event ReceivedTokens(address token, address from, uint256 amount);

  IERC777 public poolDaiToken;
  IERC777 public poolUsdcToken;
  MixedPodInterface public poolDaiPod;
  MixedPodInterface public poolUsdcPod;
  IERC20 public v3Token;

  constructor (
    IERC777 _poolDaiToken,
    IERC777 _poolUsdcToken,
    MixedPodInterface _poolDaiPod,
    MixedPodInterface _poolUsdcPod,
    IERC20 _v3Token
  ) public {
    poolDaiToken = _poolDaiToken;
    poolUsdcToken = _poolUsdcToken;
    poolDaiPod = _poolDaiPod;
    poolUsdcPod = _poolUsdcPod;
    v3Token = _v3Token;

    // register interfaces
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

    __Ownable_init();
  }

  function tokensReceived(
    address,
    address from,
    address to,
    uint256 amount,
    bytes calldata,
    bytes calldata
  ) external override {
    require(to == address(this), "MigrateV2ToV3/only-tokens");

    if (msg.sender == address(poolDaiToken)) {
      v3Token.transfer(from, amount);
    } else if (msg.sender == address(poolUsdcToken)) {
      v3Token.transfer(from, amount * 1e12);
    } else if (msg.sender == address(poolDaiPod)) {
      uint256 collateral = poolDaiPod.tokenToCollateralValue(amount);
      v3Token.transfer(from, collateral);
    } else if (msg.sender == address(poolUsdcPod)) {
      uint256 collateral = poolUsdcPod.tokenToCollateralValue(amount);
      v3Token.transfer(from, collateral * 1e12);
    } else {
      revert("MigrateV2ToV3/unknown-token");
    }

    emit ReceivedTokens(msg.sender, from, amount);
  }

  function withdrawERC777(IERC777 token) external onlyOwner {
    uint256 amount = token.balanceOf(address(this));
    token.send(msg.sender, amount, "");
  }

  function withdrawERC20(IERC20 token) external onlyOwner {
    uint256 amount = token.balanceOf(address(this));
    token.transfer(msg.sender, amount);
  }

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external override view returns (bytes32) {
    if (account == address(this) && interfaceHash == TOKENS_RECIPIENT_INTERFACE_HASH) {
      return _ERC1820_ACCEPT_MAGIC;
    } else {
      return bytes32(0x00);
    }
  }
}
