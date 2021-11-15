// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IyVaultV2} from "../interfaces/IyVaultV2.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract YearnVaultAdapter is IVaultAdapter {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  IyVaultV2 public vault;

  /// @dev The address which has admin control over this contract.
  address public admin;

  /// @dev The decimals of the token.
  uint256 public decimals;

  constructor(IyVaultV2 _vault, address _admin) public {
    vault = _vault;
    admin = _admin;
    updateApproval();
    decimals = _vault.decimals();
  }

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "YearnVaultAdapter: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return IDetailedERC20(vault.token());
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {
    return _sharesToTokens(vault.balanceOf(address(this)));
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {
    vault.deposit(_amount);
  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override onlyAdmin {
    vault.withdraw(_tokensToShares(_amount),_recipient);
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    address _token = vault.token();
    IDetailedERC20(_token).safeApprove(address(vault), uint256(-1));
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.
  
  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(vault.pricePerShare()).div(10**decimals);
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(10**decimals).div(vault.pricePerShare());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.8.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logByte(byte p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(byte)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

library FixedPointMath {
  uint256 public constant DECIMALS = 18;
  uint256 public constant SCALAR = 10**DECIMALS;

  struct FixedDecimal {
    uint256 x;
  }

  function fromU256(uint256 value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require(value == 0 || (x = value * SCALAR) / SCALAR == value);
    return FixedDecimal(x);
  }

  function maximumValue() internal pure returns (FixedDecimal memory) {
    return FixedDecimal(uint256(-1));
  }

  function add(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require((x = self.x + value.x) >= self.x);
    return FixedDecimal(x);
  }

  function add(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    return add(self, fromU256(value));
  }

  function sub(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require((x = self.x - value.x) <= self.x);
    return FixedDecimal(x);
  }

  function sub(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    return sub(self, fromU256(value));
  }

  function mul(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require(value == 0 || (x = self.x * value) / value == self.x);
    return FixedDecimal(x);
  }

  function div(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    require(value != 0);
    return FixedDecimal(self.x / value);
  }

  function cmp(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (int256) {
    if (self.x < value.x) {
      return -1;
    }

    if (self.x > value.x) {
      return 1;
    }

    return 0;
  }

  function decode(FixedDecimal memory self) internal pure returns (uint256) {
    return self.x / SCALAR;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDetailedERC20.sol";

/// Interface for all Vault Adapter implementations.
interface IVaultAdapter {

  /// @dev Gets the token that the adapter accepts.
  function token() external view returns (IDetailedERC20);

  /// @dev The total value of the assets deposited into the vault.
  function totalValue() external view returns (uint256);

  /// @dev Deposits funds into the vault.
  ///
  /// @param _amount  the amount of funds to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Attempts to withdraw funds from the wrapped vault.
  ///
  /// The amount withdrawn to the recipient may be less than the amount requested.
  ///
  /// @param _recipient the recipient of the funds.
  /// @param _amount    the amount of funds to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;
}

pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IyVaultV2 is IERC20 {
    function token() external view returns (address);
    function deposit() external returns (uint);
    function deposit(uint) external returns (uint);
    function deposit(uint, address) external returns (uint);
    function withdraw() external returns (uint);
    function withdraw(uint) external returns (uint);
    function withdraw(uint, address) external returns (uint);
    function withdraw(uint, address, uint) external returns (uint);
    function permit(address, address, uint, uint, bytes32) external view returns (bool);
    function pricePerShare() external view returns (uint);
    
    function apiVersion() external view returns (string memory);
    function totalAssets() external view returns (uint);
    function maxAvailableShares() external view returns (uint);
    function debtOutstanding() external view returns (uint);
    function debtOutstanding(address strategy) external view returns (uint);
    function creditAvailable() external view returns (uint);
    function creditAvailable(address strategy) external view returns (uint);
    function availableDepositLimit() external view returns (uint);
    function expectedReturn() external view returns (uint);
    function expectedReturn(address strategy) external view returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function balanceOf(address owner) external view override returns (uint);
    function totalSupply() external view override returns (uint);
    function governance() external view returns (address);
    function management() external view returns (address);
    function guardian() external view returns (address);
    function guestList() external view returns (address);
    function strategies(address) external view returns (uint, uint, uint, uint, uint, uint, uint, uint);
    function withdrawalQueue(uint) external view returns (address);
    function emergencyShutdown() external view returns (bool);
    function depositLimit() external view returns (uint);
    function debtRatio() external view returns (uint);
    function totalDebt() external view returns (uint);
    function lastReport() external view returns (uint);
    function activation() external view returns (uint);
    function rewards() external view returns (address);
    function managementFee() external view returns (uint);
    function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IyVaultV2} from "../interfaces/IyVaultV2.sol";
import {YearnVaultAdapter} from "./YearnVaultAdapter.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract YearnVaultAdapterWithIndirection is YearnVaultAdapter {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using SafeERC20 for IDetailedERC20;
    using SafeERC20 for IyVaultV2;
    using SafeMath for uint256;

    constructor(IyVaultV2 _vault, address _admin) YearnVaultAdapter(_vault, _admin) public {
    }

    /// @dev Sends vault tokens to the recipient
    ///
    /// This function reverts if the caller is not the admin.
    ///
    /// @param _recipient the account to send the tokens to.
    /// @param _amount    the amount of tokens to send.
    function indirectWithdraw(address _recipient, uint256 _amount) external onlyAdmin {
        vault.safeTransfer(_recipient, _tokensToShares(_amount));
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC20Burnable.sol";
import {YearnVaultAdapterWithIndirection} from "./adapters/YearnVaultAdapterWithIndirection.sol";
import {VaultWithIndirection} from "./libraries/alchemist/VaultWithIndirection.sol";
import {ITransmuter} from "./interfaces/ITransmuter.sol";

// import "hardhat/console.sol";

//    ___    __        __                _               ___                              __         _ 
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)
//
// .___________..______           ___      .__   __.      _______..___  ___.  __    __  .___________. _______ .______
// |           ||   _  \         /   \     |  \ |  |     /       ||   \/   | |  |  |  | |           ||   ____||   _  \
// `---|  |----`|  |_)  |       /  ^  \    |   \|  |    |   (----`|  \  /  | |  |  |  | `---|  |----`|  |__   |  |_)  |
//     |  |     |      /       /  /_\  \   |  . `  |     \   \    |  |\/|  | |  |  |  |     |  |     |   __|  |      /
//     |  |     |  |\  \----. /  _____  \  |  |\   | .----)   |   |  |  |  | |  `--'  |     |  |     |  |____ |  |\  \----.
//     |__|     | _| `._____|/__/     \__\ |__| \__| |_______/    |__|  |__|  \______/      |__|     |_______|| _| `._____|
/**
 * @dev Implementation of the {IERC20Burnable} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20Burnable-approve}.
 */
contract TransmuterB is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Burnable;
    using Address for address;
    using VaultWithIndirection for VaultWithIndirection.Data;
    using VaultWithIndirection for VaultWithIndirection.List;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public TRANSMUTATION_PERIOD;

    address public alToken;
    address public token;

    mapping(address => uint256) public depositedAlTokens;
    mapping(address => uint256) public tokensInBucket;
    mapping(address => uint256) public realisedTokens;
    mapping(address => uint256) public lastDividendPoints;

    mapping(address => bool) public userIsKnown;
    mapping(uint256 => address) public userList;
    uint256 public nextUser;

    uint256 public totalSupplyAltokens;
    uint256 public buffer;
    uint256 public lastDepositBlock;

    ///@dev values needed to calculate the distribution of base asset in proportion for alTokens staked
    uint256 public pointMultiplier = 10e18;

    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    /// @dev alchemist addresses whitelisted
    mapping (address => bool) public whiteList;

    /// @dev The threshold above which excess funds will be deployed to yield farming activities
    uint256 public plantableThreshold = 5000000000000000000000000; // 5mm

    /// @dev The % margin to trigger planting or recalling of funds
    uint256 public plantableMargin = 5;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    /// @dev The address of the account which can perform emergency activities
    address public sentinel;

    /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
    /// from the active vault.
    bool public pause;

    /// @dev The address of the contract which will receive fees.
    address public rewards;

    /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
    /// deposits and withdraws. VaultWithIndirections before the last element are considered inactive and are expected to be cleared.
    VaultWithIndirection.List private _vaults;

    event GovernanceUpdated(
        address governance
    );

    event PendingGovernanceUpdated(
        address pendingGovernance
    );

    event SentinelUpdated(
        address sentinel
    );

    event TransmuterPeriodUpdated(
        uint256 newTransmutationPeriod
    );

    event TokenClaimed(
        address claimant,
        address token,
        uint256 amountClaimed
    );

    event AlUsdStaked(
        address staker,
        uint256 amountStaked
    );

    event AlUsdUnstaked(
        address staker,
        uint256 amountUnstaked
    );

    event Transmutation(
        address transmutedTo,
        uint256 amountTransmuted
    );

    event ForcedTransmutation(
        address transmutedBy,
        address transmutedTo,
        uint256 amountTransmuted
    );

    event Distribution(
        address origin,
        uint256 amount
    );

    event WhitelistSet(
        address whitelisted,
        bool state
    );

    event PlantableThresholdUpdated(
        uint256 plantableThreshold
    );
    
    event PlantableMarginUpdated(
        uint256 plantableMargin
    );

    event ActiveVaultUpdated(
        YearnVaultAdapterWithIndirection indexed adapter
    );

    event PauseUpdated(
        bool status
    );

    event FundsRecalled(
        uint256 indexed vaultId,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    event FundsHarvested(
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    event RewardsUpdated(
        address treasury
    );

    event MigrationComplete(
        address migrateTo,
        uint256 fundsMigrated
    );

    constructor(address _alToken, address _token, address _governance) public {
        require(_governance != ZERO_ADDRESS, "Transmuter: 0 gov");
        governance = _governance;
        alToken = _alToken;
        token = _token;
        TRANSMUTATION_PERIOD = 50;
    }

    ///@return displays the user's share of the pooled alTokens.
    function dividendsOwing(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(lastDividendPoints[account]);
        return depositedAlTokens[account].mul(newDividendPoints).div(pointMultiplier);
    }

    ///@dev modifier to fill the bucket and keep bookkeeping correct incase of increase/decrease in shares
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            tokensInBucket[account] = tokensInBucket[account].add(owing);
        }
        lastDividendPoints[account] = totalDividendPoints;
        _;
    }
    ///@dev modifier add users to userlist. Users are indexed in order to keep track of when a bond has been filled
    modifier checkIfNewUser() {
        if (!userIsKnown[msg.sender]) {
            userList[nextUser] = msg.sender;
            userIsKnown[msg.sender] = true;
            nextUser++;
        }
        _;
    }

    ///@dev run the phased distribution of the buffered funds
    modifier runPhasedDistribution() {
        uint256 _lastDepositBlock = lastDepositBlock;
        uint256 _currentBlock = block.number;
        uint256 _toDistribute = 0;
        uint256 _buffer = buffer;

        // check if there is something in bufffer
        if (_buffer > 0) {
            // NOTE: if last deposit was updated in the same block as the current call
            // then the below logic gates will fail

            //calculate diffrence in time
            uint256 deltaTime = _currentBlock.sub(_lastDepositBlock);

            // distribute all if bigger than timeframe
            if(deltaTime >= TRANSMUTATION_PERIOD) {
                _toDistribute = _buffer;
            } else {

                //needs to be bigger than 0 cuzz solidity no decimals
                if(_buffer.mul(deltaTime) > TRANSMUTATION_PERIOD)
                {
                    _toDistribute = _buffer.mul(deltaTime).div(TRANSMUTATION_PERIOD);
                }
            }

            // factually allocate if any needs distribution
            if(_toDistribute > 0){

                // remove from buffer
                buffer = _buffer.sub(_toDistribute);

                // increase the allocation
                increaseAllocations(_toDistribute);
            }
        }

        // current timeframe is now the last
        lastDepositBlock = _currentBlock;
        _;
    }

    /// @dev A modifier which checks if whitelisted for minting.
    modifier onlyWhitelisted() {
        require(whiteList[msg.sender], "Transmuter: !whitelisted");
        _;
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "Transmuter: !governance");
        _;
    }

    ///@dev set the TRANSMUTATION_PERIOD variable
    ///
    /// sets the length (in blocks) of one full distribution phase
    function setTransmutationPeriod(uint256 newTransmutationPeriod) public onlyGov() {
        TRANSMUTATION_PERIOD = newTransmutationPeriod;
        emit TransmuterPeriodUpdated(TRANSMUTATION_PERIOD);
    }

    ///@dev claims the base token after it has been transmuted
    ///
    ///This function reverts if there is no realisedToken balance
    function claim() public {
        address sender = msg.sender;
        require(realisedTokens[sender] > 0);
        uint256 value = realisedTokens[sender];
        realisedTokens[sender] = 0;
        ensureSufficientFundsExistLocally(value);
        IERC20Burnable(token).safeTransfer(sender, value);
        emit TokenClaimed(sender, token, value);
    }

    ///@dev Withdraws staked alTokens from the transmuter
    ///
    /// This function reverts if you try to draw more tokens than you deposited
    ///
    ///@param amount the amount of alTokens to unstake
    function unstake(uint256 amount) public updateAccount(msg.sender) {
        // by calling this function before transmuting you forfeit your gained allocation
        address sender = msg.sender;
        require(depositedAlTokens[sender] >= amount,"Transmuter: unstake amount exceeds deposited amount");
        depositedAlTokens[sender] = depositedAlTokens[sender].sub(amount);
        totalSupplyAltokens = totalSupplyAltokens.sub(amount);
        IERC20Burnable(alToken).safeTransfer(sender, amount);
        emit AlUsdUnstaked(sender, amount);
    }
    ///@dev Deposits alTokens into the transmuter 
    ///
    ///@param amount the amount of alTokens to stake
    function stake(uint256 amount)
        public
        runPhasedDistribution()
        updateAccount(msg.sender)
        checkIfNewUser()
    {
        require(!pause, "emergency pause enabled");

        // requires approval of AlToken first
        address sender = msg.sender;
        //require tokens transferred in;
        IERC20Burnable(alToken).safeTransferFrom(sender, address(this), amount);
        totalSupplyAltokens = totalSupplyAltokens.add(amount);
        depositedAlTokens[sender] = depositedAlTokens[sender].add(amount);
        emit AlUsdStaked(sender, amount);
    }
    /// @dev Converts the staked alTokens to the base tokens in amount of the sum of pendingdivs and tokensInBucket
    ///
    /// once the alToken has been converted, it is burned, and the base token becomes realisedTokens which can be recieved using claim()    
    ///
    /// reverts if there are no pendingdivs or tokensInBucket
    function transmute() public runPhasedDistribution() updateAccount(msg.sender) {
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[sender];
        uint256 diff;

        require(pendingz > 0, "need to have pending in bucket");

        tokensInBucket[sender] = 0;

        // check bucket overflow
        if (pendingz > depositedAlTokens[sender]) {
            diff = pendingz.sub(depositedAlTokens[sender]);

            // remove overflow
            pendingz = depositedAlTokens[sender];
        }

        // decrease altokens
        depositedAlTokens[sender] = depositedAlTokens[sender].sub(pendingz);

        // BURN ALTOKENS
        IERC20Burnable(alToken).burn(pendingz);

        // adjust total
        totalSupplyAltokens = totalSupplyAltokens.sub(pendingz);

        // reallocate overflow
        increaseAllocations(diff);

        // add payout
        realisedTokens[sender] = realisedTokens[sender].add(pendingz);

        emit Transmutation(sender, pendingz);
    }

    /// @dev Executes transmute() on another account that has had more base tokens allocated to it than alTokens staked.
    ///
    /// The caller of this function will have the surlus base tokens credited to their tokensInBucket balance, rewarding them for performing this action
    ///
    /// This function reverts if the address to transmute is not over-filled.
    ///
    /// @param toTransmute address of the account you will force transmute.
    function forceTransmute(address toTransmute)
        public
        runPhasedDistribution()
        updateAccount(msg.sender)
        updateAccount(toTransmute)
        checkIfNewUser()
    {
        //load into memory
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[toTransmute];
        // check restrictions
        require(
            pendingz > depositedAlTokens[toTransmute],
            "Transmuter: !overflow"
        );

        // empty bucket
        tokensInBucket[toTransmute] = 0;

        // calculaate diffrence
        uint256 diff = pendingz.sub(depositedAlTokens[toTransmute]);

        // remove overflow
        pendingz = depositedAlTokens[toTransmute];

        // decrease altokens
        depositedAlTokens[toTransmute] = 0;

        // BURN ALTOKENS
        IERC20Burnable(alToken).burn(pendingz);
        // adjust total
        totalSupplyAltokens = totalSupplyAltokens.sub(pendingz);

        // reallocate overflow
        tokensInBucket[sender] = tokensInBucket[sender].add(diff);

        // add payout
        realisedTokens[toTransmute] = realisedTokens[toTransmute].add(pendingz);

        uint256 value = realisedTokens[toTransmute];

        ensureSufficientFundsExistLocally(value);

        // force payout of realised tokens of the toTransmute address
        realisedTokens[toTransmute] = 0;
        IERC20Burnable(token).safeTransfer(toTransmute, value);
        emit ForcedTransmutation(sender, toTransmute, value);
    }

    /// @dev Transmutes and unstakes all alTokens
    ///
    /// This function combines the transmute and unstake functions for ease of use
    function exit() public {
        transmute();
        uint256 toWithdraw = depositedAlTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Transmutes and claims all converted base tokens.
    ///
    /// This function combines the transmute and claim functions while leaving your remaining alTokens staked.
    function transmuteAndClaim() public {
        transmute();
        claim();
    }

    /// @dev Transmutes, claims base tokens, and withdraws alTokens.
    ///
    /// This function helps users to exit the transmuter contract completely after converting their alTokens to the base pair.
    function transmuteClaimAndWithdraw() public {
        transmute();
        claim();
        uint256 toWithdraw = depositedAlTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Distributes the base token proportionally to all alToken stakers.
    ///
    /// This function is meant to be called by the Alchemist contract for when it is sending yield to the transmuter. 
    /// Anyone can call this and add funds, idk why they would do that though...
    ///
    /// @param origin the account that is sending the tokens to be distributed.
    /// @param amount the amount of base tokens to be distributed to the transmuter.
    function distribute(address origin, uint256 amount) public onlyWhitelisted() runPhasedDistribution() {
        require(!pause, "emergency pause enabled");
        IERC20Burnable(token).safeTransferFrom(origin, address(this), amount);
        buffer = buffer.add(amount);
        _plantOrRecallExcessFunds();
        emit Distribution(origin, amount);
    }

    /// @dev Allocates the incoming yield proportionally to all alToken stakers.
    ///
    /// @param amount the amount of base tokens to be distributed in the transmuter.
    function increaseAllocations(uint256 amount) internal {
        if(totalSupplyAltokens > 0 && amount > 0) {
            totalDividendPoints = totalDividendPoints.add(
                amount.mul(pointMultiplier).div(totalSupplyAltokens)
            );
            unclaimedDividends = unclaimedDividends.add(amount);
        } else {
            buffer = buffer.add(amount);
        }
    }

    /// @dev Gets the status of a user's staking position.
    ///
    /// The total amount allocated to a user is the sum of pendingdivs and inbucket.
    ///
    /// @param user the address of the user you wish to query.
    ///
    /// returns user status
    
    function userInfo(address user)
        public
        view
        returns (
            uint256 depositedAl,
            uint256 pendingdivs,
            uint256 inbucket,
            uint256 realised
        )
    {
        uint256 _depositedAl = depositedAlTokens[user];
        uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(TRANSMUTATION_PERIOD);
        if(block.number.sub(lastDepositBlock) > TRANSMUTATION_PERIOD){
            _toDistribute = buffer;
        }
        uint256 _pendingdivs = _toDistribute.mul(depositedAlTokens[user]).div(totalSupplyAltokens);
        uint256 _inbucket = tokensInBucket[user].add(dividendsOwing(user));
        uint256 _realised = realisedTokens[user];
        return (_depositedAl, _pendingdivs, _inbucket, _realised);
    }

    /// @dev Gets the status of multiple users in one call
    ///
    /// This function is used to query the contract to check for
    /// accounts that have overfilled positions in order to check 
    /// who can be force transmuted.
    ///
    /// @param from the first index of the userList
    /// @param to the last index of the userList
    ///
    /// returns the userList with their staking status in paginated form. 
    function getMultipleUserInfo(uint256 from, uint256 to)
        public
        view
        returns (address[] memory theUserList, uint256[] memory theUserData)
    {
        uint256 i = from;
        uint256 delta = to - from;
        address[] memory _theUserList = new address[](delta); //user
        uint256[] memory _theUserData = new uint256[](delta * 2); //deposited-bucket
        uint256 y = 0;
        uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(TRANSMUTATION_PERIOD);
        if(block.number.sub(lastDepositBlock) > TRANSMUTATION_PERIOD){
            _toDistribute = buffer;
        }
        for (uint256 x = 0; x < delta; x += 1) {
            _theUserList[x] = userList[i];
            _theUserData[y] = depositedAlTokens[userList[i]];
            _theUserData[y + 1] = dividendsOwing(userList[i]).add(tokensInBucket[userList[i]]).add(_toDistribute.mul(depositedAlTokens[userList[i]]).div(totalSupplyAltokens));
            y += 2;
            i += 1;
        }
        return (_theUserList, _theUserData);
    }

    /// @dev Gets info on the buffer
    ///
    /// This function is used to query the contract to get the
    /// latest state of the buffer
    ///
    /// @return _toDistribute the amount ready to be distributed
    /// @return _deltaBlocks the amount of time since the last phased distribution
    /// @return _buffer the amount in the buffer 
    function bufferInfo() public view returns (uint256 _toDistribute, uint256 _deltaBlocks, uint256 _buffer){
        _deltaBlocks = block.number.sub(lastDepositBlock);
        _buffer = buffer; 
        _toDistribute = _buffer.mul(_deltaBlocks).div(TRANSMUTATION_PERIOD);
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov() {
        require(_pendingGovernance != ZERO_ADDRESS, "Transmuter: 0 gov");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external  {
        require(msg.sender == pendingGovernance,"!pendingGovernance");
        address _pendingGovernance = pendingGovernance;
        governance = _pendingGovernance;

        emit GovernanceUpdated(_pendingGovernance);
    }

    /// @dev Sets the whitelist
    ///
    /// This function reverts if the caller is not governance
    ///
    /// @param _toWhitelist the account to mint tokens to.
    /// @param _state the whitelist state.
    function setWhitelist(address _toWhitelist, bool _state) external onlyGov() {
        whiteList[_toWhitelist] = _state;
        emit WhitelistSet(_toWhitelist, _state);
    }

    /// @dev Updates the active vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the new active vault.
    function setActiveVault(YearnVaultAdapterWithIndirection _adapter) external onlyGov() {
        require(_adapter != YearnVaultAdapterWithIndirection(ZERO_ADDRESS), "Transmuter: active vault address cannot be 0x0.");
        require(address(_adapter.token()) == token, "Transmuter.vault: token mismatch.");

        _vaults.push(VaultWithIndirection.Data({
            adapter: _adapter,
            totalDeposited: 0
        }));

        emit ActiveVaultUpdated(_adapter);
    }


    /// @dev Recalls funds from active vault if less than amt exist locally
    ///
    /// @param amt amount of funds that need to exist locally to fulfill pending request
    function ensureSufficientFundsExistLocally(uint256 amt) internal {
        uint256 currentBal = IERC20Burnable(token).balanceOf(address(this));
        if (currentBal < amt) {
            uint256 diff = amt - currentBal;
            // get enough funds from active vault to replenish local holdings & fulfill claim request
            _recallExcessFundsFromActiveVault(plantableThreshold.add(diff));
        }
    }

    /// @dev Recalls all planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    function recallAllFundsFromVault(uint256 _vaultId) external {
        require(pause && (msg.sender == governance || msg.sender == sentinel), "Transmuter: not paused, or not governance or sentinel");
        _recallAllFundsFromVault(_vaultId);
    }

    /// @dev Recalls all planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    function _recallAllFundsFromVault(uint256 _vaultId) internal {
        VaultWithIndirection.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdrawAll(address(this));
        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);
    }

    /// @dev Recalls planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    /// @param _amount the amount of funds to recall
    function recallFundsFromVault(uint256 _vaultId, uint256 _amount) external {
        require(pause && (msg.sender == governance || msg.sender == sentinel), "Transmuter: not paused, or not governance or sentinel");
        _recallFundsFromVault(_vaultId, _amount);
    }

    /// @dev Recalls planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    /// @param _amount the amount of funds to recall
    function _recallFundsFromVault(uint256 _vaultId, uint256 _amount) internal {
        VaultWithIndirection.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(address(this), _amount);
        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);
    }

    /// @dev Recalls planted funds from the active vault
    ///
    /// @param _amount the amount of funds to recall
    function _recallFundsFromActiveVault(uint256 _amount) internal {
        _recallFundsFromVault(_vaults.lastIndex(), _amount);
    }

    /// @dev Plants or recalls funds from the active vault
    ///
    /// This function plants excess funds in an external vault, or recalls them from the external vault
    /// Should only be called as part of distribute()
    function _plantOrRecallExcessFunds() internal {
        // check if the transmuter holds more funds than plantableThreshold
        uint256 bal = IERC20Burnable(token).balanceOf(address(this));
        uint256 marginVal = plantableThreshold.mul(plantableMargin).div(100);
        if (bal > plantableThreshold.add(marginVal)) {
            uint256 plantAmt = bal - plantableThreshold;
            // if total funds above threshold, send funds to vault
            VaultWithIndirection.Data storage _activeVault = _vaults.last();
            _activeVault.deposit(plantAmt);
        } else if (bal < plantableThreshold.sub(marginVal)) {
            // if total funds below threshold, recall funds from vault
            // first check that there are enough funds in vault
            uint256 harvestAmt = plantableThreshold - bal;
            _recallExcessFundsFromActiveVault(harvestAmt);
        }
    }

    /// @dev Recalls up to the harvestAmt from the active vault
    ///
    /// This function will recall less than harvestAmt if only less is available
    ///
    /// @param _recallAmt the amount to harvest from the active vault
    function _recallExcessFundsFromActiveVault(uint256 _recallAmt) internal {
        VaultWithIndirection.Data storage _activeVault = _vaults.last();
        uint256 activeVaultVal = _activeVault.totalValue();
        if (activeVaultVal < _recallAmt) {
            _recallAmt = activeVaultVal;
        }
        if (_recallAmt > 0) {
            _recallFundsFromActiveVault(_recallAmt);
        }
    }

    /// @dev Sets the address of the sentinel
    ///
    /// @param _sentinel address of the new sentinel
    function setSentinel(address _sentinel) external onlyGov() {
        require(_sentinel != ZERO_ADDRESS, "Transmuter: sentinel address cannot be 0x0.");
        sentinel = _sentinel;
        emit SentinelUpdated(_sentinel);
    }

    /// @dev Sets the threshold of total held funds above which excess funds will be planted in yield farms.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _plantableThreshold the new plantable threshold.
    function setPlantableThreshold(uint256 _plantableThreshold) external onlyGov() {
        plantableThreshold = _plantableThreshold;
        emit PlantableThresholdUpdated(_plantableThreshold);
    }

    /// @dev Sets the plantableThreshold margin for triggering the planting or recalling of funds on harvest
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _plantableMargin the new plantable margin.
    function setPlantableMargin(uint256 _plantableMargin) external onlyGov() {
        plantableMargin = _plantableMargin;
        emit PlantableMarginUpdated(_plantableMargin);
    }

    /// @dev Sets if the contract should enter emergency exit mode.
    ///
    /// There are 2 main reasons to pause:
    ///     1. Need to shut down deposits in case of an emergency in one of the vaults
    ///     2. Need to migrate to a new transmuter
    ///
    /// While the transmuter is paused, deposit() and distribute() are disabled
    ///
    /// @param _pause if the contract should enter emergency exit mode.
    function setPause(bool _pause) external {
        require(msg.sender == governance || msg.sender == sentinel, "!(gov || sentinel)");
        pause = _pause;
        emit PauseUpdated(_pause);
    }

    /// @dev Harvests yield from a vault.
    ///
    /// @param _vaultId the identifier of the vault to harvest from.
    ///
    /// @return the amount of funds that were harvested from the vault.
    function harvest(uint256 _vaultId) external returns (uint256, uint256) {

        VaultWithIndirection.Data storage _vault = _vaults.get(_vaultId);

        (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(rewards);

        emit FundsHarvested(_harvestedAmount, _decreasedValue);

        return (_harvestedAmount, _decreasedValue);
    }

    /// @dev Sets the rewards contract.
    ///
    /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
    ///
    /// @param _rewards the new rewards contract.
    function setRewards(address _rewards) external onlyGov() {
        // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_rewards != ZERO_ADDRESS, "Transmuter: rewards address cannot be 0x0.");

        rewards = _rewards;

        emit RewardsUpdated(_rewards);
    }

    /// @dev Migrates transmuter funds to a new transmuter
    ///
    /// @param migrateTo address of the new transmuter
    function migrateFunds(address migrateTo) external onlyGov() {
        require(migrateTo != address(0), "cannot migrate to 0x0");
        require(pause, "migrate: set emergency exit first");

        // leave enough funds to service any pending transmutations
        uint256 totalFunds = IERC20Burnable(token).balanceOf(address(this));
        uint256 migratableFunds = totalFunds.sub(totalSupplyAltokens, "not enough funds to service stakes");
        IERC20Burnable(token).approve(migrateTo, migratableFunds);
        ITransmuter(migrateTo).distribute(address(this), migratableFunds);
        emit MigrationComplete(migrateTo, migratableFunds);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

//import "hardhat/console.sol";

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {YearnVaultAdapterWithIndirection} from "../../adapters/YearnVaultAdapterWithIndirection.sol";
import "hardhat/console.sol";

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library VaultWithIndirection {
  using VaultWithIndirection for Data;
  using VaultWithIndirection for List;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  struct Data {
    YearnVaultAdapterWithIndirection adapter;
    uint256 totalDeposited;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets the total amount of assets deposited in the vault.
  ///
  /// @return the total assets.
  function totalValue(Data storage _self) internal view returns (uint256) {
    return _self.adapter.totalValue();
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token(Data storage _self) internal view returns (IDetailedERC20) {
    return IDetailedERC20(_self.adapter.token());
  }

  /// @dev Deposits funds from the caller into the vault.
  ///
  /// @param _amount the amount of funds to deposit.
  function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
    // Push the token that the vault accepts onto the stack to save gas.
    IDetailedERC20 _token = _self.token();

    _token.safeTransfer(address(_self.adapter), _amount);
    _self.adapter.deposit(_amount);
    _self.totalDeposited = _self.totalDeposited.add(_amount);

    return _amount;
  }

  /// @dev Deposits the entire token balance of the caller into the vault.
  function depositAll(Data storage _self) internal returns (uint256) {
    IDetailedERC20 _token = _self.token();
    return _self.deposit(_token.balanceOf(address(this)));
  }

  /// @dev Withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount);
    _self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function directWithdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.withdraw(_recipient, _amount);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function indirectWithdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.indirectWithdraw(_recipient, _amount);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Withdraw all the deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    return _self.withdraw(_recipient, _self.totalDeposited);
  }

  /// @dev Harvests yield from the vault.
  ///
  /// @param _recipient the account to withdraw the harvested yield to.
  function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    if (_self.totalValue() <= _self.totalDeposited) {
      return (0, 0);
    }
    uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);
    return _self.indirectWithdraw(_recipient, _withdrawAmount);
  }

  /// @dev Adds a element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Vault.List: empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface ITransmuter  {
  function distribute (address origin, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {CDP} from "./libraries/alchemist/CDP.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";
import {ITransmuter} from "./interfaces/ITransmuter.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";
import {IChainlink} from "./interfaces/IChainlink.sol";
import {IVaultAdapter} from "./interfaces/IVaultAdapter.sol";
import {Vault} from "./libraries/alchemist/Vault.sol";

import "hardhat/console.sol";

// ERC20,removing ERC20 from the alchemist
//    ___    __        __                _               ___                              __         _ 
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _   
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)  
//  
//      ___       __        ______  __    __   _______ .___  ___.  __       _______..___________.
//     /   \     |  |      /      ||  |  |  | |   ____||   \/   | |  |     /       ||           |
//    /  ^  \    |  |     |  ,----'|  |__|  | |  |__   |  \  /  | |  |    |   (----``---|  |----`
//   /  /_\  \   |  |     |  |     |   __   | |   __|  |  |\/|  | |  |     \   \        |  |     
//  /  _____  \  |  `----.|  `----.|  |  |  | |  |____ |  |  |  | |  | .----)   |       |  |     
// /__/     \__\ |_______| \______||__|  |__| |_______||__|  |__| |__| |_______/        |__|     
                                                                                              
contract Alchemist is  ReentrancyGuard {
  using CDP for CDP.Data;
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Vault for Vault.Data;
  using Vault for Vault.List;
  using SafeERC20 for IMintableERC20;
  using SafeMath for uint256;
  using Address for address;

  address public constant ZERO_ADDRESS = address(0);

  /// @dev Resolution for all fixed point numeric parameters which represent percents. The resolution allows for a
  /// granularity of 0.01% increments.
  uint256 public constant PERCENT_RESOLUTION = 10000;

  /// @dev The minimum value that the collateralization limit can be set to by the governance. This is a safety rail
  /// to prevent the collateralization from being set to a value which breaks the system.
  ///
  /// This value is equal to 100%.
  ///
  /// IMPORTANT: This constant is a raw FixedPointMath.FixedDecimal value and assumes a resolution of 64 bits. If the
  ///            resolution for the FixedPointMath library changes this constant must change as well.
  uint256 public constant MINIMUM_COLLATERALIZATION_LIMIT = 1000000000000000000;

  /// @dev The maximum value that the collateralization limit can be set to by the governance. This is a safety rail
  /// to prevent the collateralization from being set to a value which breaks the system.
  ///
  /// This value is equal to 400%.
  ///
  /// IMPORTANT: This constant is a raw FixedPointMath.FixedDecimal value and assumes a resolution of 64 bits. If the
  ///            resolution for the FixedPointMath library changes this constant must change as well.
  uint256 public constant MAXIMUM_COLLATERALIZATION_LIMIT = 4000000000000000000;

  event GovernanceUpdated(
    address governance
  );

  event PendingGovernanceUpdated(
    address pendingGovernance
  );

  event SentinelUpdated(
    address sentinel
  );

  event TransmuterUpdated(
    address transmuter
  );

  event RewardsUpdated(
    address treasury
  );

  event HarvestFeeUpdated(
    uint256 fee
  );

  event CollateralizationLimitUpdated(
    uint256 limit
  );

  event EmergencyExitUpdated(
    bool status
  );

  event ActiveVaultUpdated(
    IVaultAdapter indexed adapter
  );

  event FundsHarvested(
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  event FundsRecalled(
    uint256 indexed vaultId,
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  event FundsFlushed(
    uint256 amount
  );

  event TokensDeposited(
    address indexed account,
    uint256 amount
  );

  event TokensWithdrawn(
    address indexed account,
    uint256 requestedAmount,
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  event TokensRepaid(
    address indexed account,
    uint256 parentAmount,
    uint256 childAmount
  );

  event TokensLiquidated(
    address indexed account,
    uint256 requestedAmount,
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  /// @dev The token that this contract is using as the parent asset.
  IMintableERC20 public token;

   /// @dev The token that this contract is using as the child asset.
  IMintableERC20 public xtoken;

  /// @dev The address of the account which currently has administrative capabilities over this contract.
  address public governance;

  /// @dev The address of the pending governance.
  address public pendingGovernance;

  /// @dev The address of the account which can initiate an emergency withdraw of funds in a vault.
  address public sentinel;

  /// @dev The address of the contract which will transmute synthetic tokens back into native tokens.
  address public transmuter;

  /// @dev The address of the contract which will receive fees.
  address public rewards;

  /// @dev The percent of each profitable harvest that will go to the rewards contract.
  uint256 public harvestFee;

  /// @dev The total amount the native token deposited into the system that is owned by external users.
  uint256 public totalDeposited;

  /// @dev when movemetns are bigger than this number flush is activated.
  uint256 public flushActivator;

  /// @dev A flag indicating if the contract has been initialized yet.
  bool public initialized;

  /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
  /// from the active vault.
  bool public emergencyExit;

  /// @dev The context shared between the CDPs.
  CDP.Context private _ctx;

  /// @dev A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
  /// create a new address or set up a proxy contract that interfaces with this contract.
  mapping(address => CDP.Data) private _cdps;

  /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
  /// deposits and withdraws. Vaults before the last element are considered inactive and are expected to be cleared.
  Vault.List private _vaults;

  /// @dev The address of the link oracle.
  address public _linkGasOracle;

  /// @dev The minimum returned amount needed to be on peg according to the oracle.
  uint256 public pegMinimum;
  
  constructor(
    IMintableERC20 _token,
    IMintableERC20 _xtoken,
    address _governance,
    address _sentinel
  )
    public
    /*ERC20(
      string(abi.encodePacked("Alchemic ", _token.name())),
      string(abi.encodePacked("al", _token.symbol()))
    )*/
  {
    require(_governance != ZERO_ADDRESS, "Alchemist: governance address cannot be 0x0.");
    require(_sentinel != ZERO_ADDRESS, "Alchemist: sentinel address cannot be 0x0.");

    token = _token;
    xtoken = _xtoken;
    governance = _governance;
    sentinel = _sentinel;
    flushActivator = 100000 ether;// change for non 18 digit tokens

    //_setupDecimals(_token.decimals());
    uint256 COLL_LIMIT = MINIMUM_COLLATERALIZATION_LIMIT.mul(2);
    _ctx.collateralizationLimit = FixedPointMath.FixedDecimal(COLL_LIMIT);
    _ctx.accumulatedYieldWeight = FixedPointMath.FixedDecimal(0);
  }

  /// @dev Sets the pending governance.
  ///
  /// This function reverts if the new pending governance is the zero address or the caller is not the current
  /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
  /// privileged contract functionality.
  ///
  /// @param _pendingGovernance the new pending governance.
  function setPendingGovernance(address _pendingGovernance) external onlyGov {
    require(_pendingGovernance != ZERO_ADDRESS, "Alchemist: governance address cannot be 0x0.");

    pendingGovernance = _pendingGovernance;

    emit PendingGovernanceUpdated(_pendingGovernance);
  }

  /// @dev Accepts the role as governance.
  ///
  /// This function reverts if the caller is not the new pending governance.
  function acceptGovernance() external  {
    require(msg.sender == pendingGovernance,"sender is not pendingGovernance");
    address _pendingGovernance = pendingGovernance;
    governance = _pendingGovernance;

    emit GovernanceUpdated(_pendingGovernance);
  }

  function setSentinel(address _sentinel) external onlyGov {

    require(_sentinel != ZERO_ADDRESS, "Alchemist: sentinel address cannot be 0x0.");

    sentinel = _sentinel;

    emit SentinelUpdated(_sentinel);
  }

  /// @dev Sets the transmuter.
  ///
  /// This function reverts if the new transmuter is the zero address or the caller is not the current governance.
  ///
  /// @param _transmuter the new transmuter.
  function setTransmuter(address _transmuter) external onlyGov {

    // Check that the transmuter address is not the zero address. Setting the transmuter to the zero address would break
    // transfers to the address because of `safeTransfer` checks.
    require(_transmuter != ZERO_ADDRESS, "Alchemist: transmuter address cannot be 0x0.");

    transmuter = _transmuter;

    emit TransmuterUpdated(_transmuter);
  }
  /// @dev Sets the flushActivator.
  ///
  /// @param _flushActivator the new flushActivator.
  function setFlushActivator(uint256 _flushActivator) external onlyGov {
    flushActivator = _flushActivator;

  }

  /// @dev Sets the rewards contract.
  ///
  /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
  ///
  /// @param _rewards the new rewards contract.
  function setRewards(address _rewards) external onlyGov {

    // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
    // transfers to the address because of `safeTransfer` checks.
    require(_rewards != ZERO_ADDRESS, "Alchemist: rewards address cannot be 0x0.");

    rewards = _rewards;

    emit RewardsUpdated(_rewards);
  }

  /// @dev Sets the harvest fee.
  ///
  /// This function reverts if the caller is not the current governance.
  ///
  /// @param _harvestFee the new harvest fee.
  function setHarvestFee(uint256 _harvestFee) external onlyGov {

    // Check that the harvest fee is within the acceptable range. Setting the harvest fee greater than 100% could
    // potentially break internal logic when calculating the harvest fee.
    require(_harvestFee <= PERCENT_RESOLUTION, "Alchemist: harvest fee above maximum.");

    harvestFee = _harvestFee;

    emit HarvestFeeUpdated(_harvestFee);
  }

  /// @dev Sets the collateralization limit.
  ///
  /// This function reverts if the caller is not the current governance or if the collateralization limit is outside
  /// of the accepted bounds.
  ///
  /// @param _limit the new collateralization limit.
  function setCollateralizationLimit(uint256 _limit) external onlyGov {

    require(_limit >= MINIMUM_COLLATERALIZATION_LIMIT, "Alchemist: collateralization limit below minimum.");
    require(_limit <= MAXIMUM_COLLATERALIZATION_LIMIT, "Alchemist: collateralization limit above maximum.");

    _ctx.collateralizationLimit = FixedPointMath.FixedDecimal(_limit);

    emit CollateralizationLimitUpdated(_limit);
  }
  /// @dev Set oracle.
  function setOracleAddress(address Oracle, uint256 peg) external onlyGov {
    _linkGasOracle = Oracle;
    pegMinimum = peg;
  }
  /// @dev Sets if the contract should enter emergency exit mode.
  ///
  /// @param _emergencyExit if the contract should enter emergency exit mode.
  function setEmergencyExit(bool _emergencyExit) external {
    require(msg.sender == governance || msg.sender == sentinel, "");

    emergencyExit = _emergencyExit;

    emit EmergencyExitUpdated(_emergencyExit);
  }

  /// @dev Gets the collateralization limit.
  ///
  /// The collateralization limit is the minimum ratio of collateral to debt that is allowed by the system.
  ///
  /// @return the collateralization limit.
  function collateralizationLimit() external view returns (FixedPointMath.FixedDecimal memory) {
    return _ctx.collateralizationLimit;
  }

  /// @dev Initializes the contract.
  ///
  /// This function checks that the transmuter and rewards have been set and sets up the active vault.
  ///
  /// @param _adapter the vault adapter of the active vault.
  function initialize(IVaultAdapter _adapter) external onlyGov {

    require(!initialized, "Alchemist: already initialized");

    require(transmuter != ZERO_ADDRESS, "Alchemist: cannot initialize transmuter address to 0x0");
    require(rewards != ZERO_ADDRESS, "Alchemist: cannot initialize rewards address to 0x0");

    _updateActiveVault(_adapter);

    initialized = true;
  }

  /// @dev Migrates the system to a new vault.
  ///
  /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
  /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
  ///
  /// @param _adapter the adapter for the vault the system will migrate to.
  function migrate(IVaultAdapter _adapter) external expectInitialized onlyGov {

    _updateActiveVault(_adapter);
  }

  /// @dev Harvests yield from a vault.
  ///
  /// @param _vaultId the identifier of the vault to harvest from.
  ///
  /// @return the amount of funds that were harvested from the vault.
  function harvest(uint256 _vaultId) external expectInitialized returns (uint256, uint256) {

    Vault.Data storage _vault = _vaults.get(_vaultId);

    (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(address(this));

    if (_harvestedAmount > 0) {
      uint256 _feeAmount = _harvestedAmount.mul(harvestFee).div(PERCENT_RESOLUTION);
      uint256 _distributeAmount = _harvestedAmount.sub(_feeAmount);

      FixedPointMath.FixedDecimal memory _weight = FixedPointMath.fromU256(_distributeAmount).div(totalDeposited);
      _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(_weight);

      if (_feeAmount > 0) {
        token.safeTransfer(rewards, _feeAmount);
      }

      if (_distributeAmount > 0) {
        _distributeToTransmuter(_distributeAmount);
        
        // token.safeTransfer(transmuter, _distributeAmount); previous version call
      }
    }

    emit FundsHarvested(_harvestedAmount, _decreasedValue);

    return (_harvestedAmount, _decreasedValue);
  }

  /// @dev Recalls an amount of deposited funds from a vault to this contract.
  ///
  /// @param _vaultId the identifier of the recall funds from.
  ///
  /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
  function recall(uint256 _vaultId, uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {

    return _recallFunds(_vaultId, _amount);
  }

  /// @dev Recalls all the deposited funds from a vault to this contract.
  ///
  /// @param _vaultId the identifier of the recall funds from.
  ///
  /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
  function recallAll(uint256 _vaultId) external nonReentrant expectInitialized returns (uint256, uint256) {
    Vault.Data storage _vault = _vaults.get(_vaultId);
    return _recallFunds(_vaultId, _vault.totalDeposited);
  }

  /// @dev Flushes buffered tokens to the active vault.
  ///
  /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
  /// additional funds.
  ///
  /// @return the amount of tokens flushed to the active vault.
  function flush() external nonReentrant expectInitialized returns (uint256) {

    // Prevent flushing to the active vault when an emergency exit is enabled to prevent potential loss of funds if
    // the active vault is poisoned for any reason.
    require(!emergencyExit, "emergency pause enabled");

    return flushActiveVault();
  }

  /// @dev Internal function to flush buffered tokens to the active vault.
  ///
  /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
  /// additional funds.
  ///
  /// @return the amount of tokens flushed to the active vault.
  function flushActiveVault() internal returns (uint256) {

    Vault.Data storage _activeVault = _vaults.last();
    uint256 _depositedAmount = _activeVault.depositAll();

    emit FundsFlushed(_depositedAmount);

    return _depositedAmount;
  }

  /// @dev Deposits collateral into a CDP.
  ///
  /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
  /// additional funds.
  ///
  /// @param _amount the amount of collateral to deposit.
  function deposit(uint256 _amount) external nonReentrant noContractAllowed expectInitialized {

    require(!emergencyExit, "emergency pause enabled");
    
    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);

    token.safeTransferFrom(msg.sender, address(this), _amount);
    if(_amount >= flushActivator) {
      flushActiveVault();
    }
    totalDeposited = totalDeposited.add(_amount);

    _cdp.totalDeposited = _cdp.totalDeposited.add(_amount);
    _cdp.lastDeposit = block.number;

    emit TokensDeposited(msg.sender, _amount);
  }

  /// @dev Attempts to withdraw part of a CDP's collateral.
  ///
  /// This function reverts if a deposit into the CDP was made in the same block. This is to prevent flash loan attacks
  /// on other internal or external systems.
  ///
  /// @param _amount the amount of collateral to withdraw.
  function withdraw(uint256 _amount) external nonReentrant noContractAllowed expectInitialized returns (uint256, uint256) {

    CDP.Data storage _cdp = _cdps[msg.sender];
    require(block.number > _cdp.lastDeposit, "");

    _cdp.update(_ctx);

    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(msg.sender, _amount);

    _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue, "Exceeds withdrawable amount");
    _cdp.checkHealth(_ctx, "Action blocked: unhealthy collateralization ratio");
    if(_amount >= flushActivator) {
      flushActiveVault();
    }
    emit TokensWithdrawn(msg.sender, _amount, _withdrawnAmount, _decreasedValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Repays debt with the native and or synthetic token.
  ///
  /// An approval is required to transfer native tokens to the transmuter.
  function repay(uint256 _parentAmount, uint256 _childAmount) external nonReentrant noContractAllowed onLinkCheck expectInitialized {

    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);

    if (_parentAmount > 0) {
      token.safeTransferFrom(msg.sender, address(this), _parentAmount);
      _distributeToTransmuter(_parentAmount);
    }

    if (_childAmount > 0) {
      xtoken.burnFrom(msg.sender, _childAmount);
      //lower debt cause burn
      xtoken.lowerHasMinted(_childAmount);
    }

    uint256 _totalAmount = _parentAmount.add(_childAmount);
    _cdp.totalDebt = _cdp.totalDebt.sub(_totalAmount, "");

    emit TokensRepaid(msg.sender, _parentAmount, _childAmount);
  }

  /// @dev Attempts to liquidate part of a CDP's collateral to pay back its debt.
  ///
  /// @param _amount the amount of collateral to attempt to liquidate.
  function liquidate(uint256 _amount) external nonReentrant noContractAllowed onLinkCheck expectInitialized returns (uint256, uint256) {
    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);
    
    // don't attempt to liquidate more than is possible
    if(_amount > _cdp.totalDebt){
      _amount = _cdp.totalDebt;
    }
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(address(this), _amount);
    //changed to new transmuter compatibillity 
    _distributeToTransmuter(_withdrawnAmount);

    _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue, "");
    _cdp.totalDebt = _cdp.totalDebt.sub(_withdrawnAmount, "");
    emit TokensLiquidated(msg.sender, _amount, _withdrawnAmount, _decreasedValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Mints synthetic tokens by either claiming credit or increasing the debt.
  ///
  /// Claiming credit will take priority over increasing the debt.
  ///
  /// This function reverts if the debt is increased and the CDP health check fails.
  ///
  /// @param _amount the amount of alchemic tokens to borrow.
  function mint(uint256 _amount) external nonReentrant noContractAllowed onLinkCheck expectInitialized {

    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);

    uint256 _totalCredit = _cdp.totalCredit;

    if (_totalCredit < _amount) {
      uint256 _remainingAmount = _amount.sub(_totalCredit);
      _cdp.totalDebt = _cdp.totalDebt.add(_remainingAmount);
      _cdp.totalCredit = 0;

      _cdp.checkHealth(_ctx, "Alchemist: Loan-to-value ratio breached");
    } else {
      _cdp.totalCredit = _totalCredit.sub(_amount);
    }

    xtoken.mint(msg.sender, _amount);
    if(_amount >= flushActivator) {
      flushActiveVault();
    }
  }

  /// @dev Gets the number of vaults in the vault list.
  ///
  /// @return the vault count.
  function vaultCount() external view returns (uint256) {
    return _vaults.length();
  }

  /// @dev Get the adapter of a vault.
  ///
  /// @param _vaultId the identifier of the vault.
  ///
  /// @return the vault adapter.
  function getVaultAdapter(uint256 _vaultId) external view returns (IVaultAdapter) {
    Vault.Data storage _vault = _vaults.get(_vaultId);
    return _vault.adapter;
  }

  /// @dev Get the total amount of the parent asset that has been deposited into a vault.
  ///
  /// @param _vaultId the identifier of the vault.
  ///
  /// @return the total amount of deposited tokens.
  function getVaultTotalDeposited(uint256 _vaultId) external view returns (uint256) {
    Vault.Data storage _vault = _vaults.get(_vaultId);
    return _vault.totalDeposited;
  }

  /// @dev Get the total amount of collateral deposited into a CDP.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the deposited amount of tokens.
  function getCdpTotalDeposited(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.totalDeposited;
  }

  /// @dev Get the total amount of alchemic tokens borrowed from a CDP.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the borrowed amount of tokens.
  function getCdpTotalDebt(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.getUpdatedTotalDebt(_ctx);
  }

  /// @dev Get the total amount of credit that a CDP has.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the amount of credit.
  function getCdpTotalCredit(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.getUpdatedTotalCredit(_ctx);
  }

  /// @dev Gets the last recorded block of when a user made a deposit into their CDP.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the block number of the last deposit.
  function getCdpLastDeposit(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.lastDeposit;
  }
  /// @dev sends tokens to the transmuter
  ///
  /// benefit of great nation of transmuter
  function _distributeToTransmuter(uint256 amount) internal {
        token.approve(transmuter,amount);
        ITransmuter(transmuter).distribute(address(this),amount);
        // lower debt cause of 'burn'
        xtoken.lowerHasMinted(amount);
  } 
  /// @dev Checks that parent token is on peg.
  ///
  /// This is used over a modifier limit of pegged interactions.
  modifier onLinkCheck() {
    if(pegMinimum > 0 ){
      uint256 oracleAnswer = uint256(IChainlink(_linkGasOracle).latestAnswer());
      require(oracleAnswer > pegMinimum, "off peg limitation");
    }
    _;
  }
  /// @dev Checks that caller is not a eoa.
  ///
  /// This is used to prevent contracts from interacting.
  modifier noContractAllowed() {
            require(!address(msg.sender).isContract() && msg.sender == tx.origin, "Sorry we do not accept contract!");
        _;
    }
  /// @dev Checks that the contract is in an initialized state.
  ///
  /// This is used over a modifier to reduce the size of the contract
  modifier expectInitialized() {
    require(initialized, "Alchemist: not initialized.");
    _;
  }

  /// @dev Checks that the current message sender or caller is a specific address.
  ///
  /// @param _expectedCaller the expected caller.
  function _expectCaller(address _expectedCaller) internal {
    require(msg.sender == _expectedCaller, "");
  }

  /// @dev Checks that the current message sender or caller is the governance address.
  ///
  ///
  modifier onlyGov() {
    require(msg.sender == governance, "Alchemist: only governance.");
    _;
  }
  /// @dev Updates the active vault.
  ///
  /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
  /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
  ///
  /// @param _adapter the adapter for the new active vault.
  function _updateActiveVault(IVaultAdapter _adapter) internal {
    require(_adapter != IVaultAdapter(ZERO_ADDRESS), "Alchemist: active vault address cannot be 0x0.");
    require(_adapter.token() == token, "Alchemist: token mismatch.");

    _vaults.push(Vault.Data({
      adapter: _adapter,
      totalDeposited: 0
    }));

    emit ActiveVaultUpdated(_adapter);
  }

  /// @dev Recalls an amount of funds from a vault to this contract.
  ///
  /// @param _vaultId the identifier of the recall funds from.
  /// @param _amount  the amount of funds to recall from the vault.
  ///
  /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
  function _recallFunds(uint256 _vaultId, uint256 _amount) internal returns (uint256, uint256) {
    require(emergencyExit || msg.sender == governance || _vaultId != _vaults.lastIndex(), "Alchemist: not an emergency, not governance, and user does not have permission to recall funds from active vault");

    Vault.Data storage _vault = _vaults.get(_vaultId);
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(address(this), _amount);

    emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Attempts to withdraw funds from the active vault to the recipient.
  ///
  /// Funds will be first withdrawn from this contracts balance and then from the active vault. This function
  /// is different from `recallFunds` in that it reduces the total amount of deposited tokens by the decreased
  /// value of the vault.
  ///
  /// @param _recipient the account to withdraw the funds to.
  /// @param _amount    the amount of funds to withdraw.
  function _withdrawFundsTo(address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    // Pull the funds from the buffer.
    uint256 _bufferedAmount = Math.min(_amount, token.balanceOf(address(this)));

    if (_recipient != address(this)) {
      token.safeTransfer(_recipient, _bufferedAmount);
    }

    uint256 _totalWithdrawn = _bufferedAmount;
    uint256 _totalDecreasedValue = _bufferedAmount;

    uint256 _remainingAmount = _amount.sub(_bufferedAmount);

    // Pull the remaining funds from the active vault.
    if (_remainingAmount > 0) {
      Vault.Data storage _activeVault = _vaults.last();
      (uint256 _withdrawAmount, uint256 _decreasedValue) = _activeVault.withdraw(
        _recipient,
        _remainingAmount
      );

      _totalWithdrawn = _totalWithdrawn.add(_withdrawAmount);
      _totalDecreasedValue = _totalDecreasedValue.add(_decreasedValue);
    }

    totalDeposited = totalDeposited.sub(_totalDecreasedValue);

    return (_totalWithdrawn, _totalDecreasedValue);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import "hardhat/console.sol";

/// @title CDP
///
/// @dev A library which provides the CDP data struct and associated functions.
library CDP {
  using CDP for Data;
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  struct Context {
    FixedPointMath.FixedDecimal collateralizationLimit;
    FixedPointMath.FixedDecimal accumulatedYieldWeight;
  }

  struct Data {
    uint256 totalDeposited;
    uint256 totalDebt;
    uint256 totalCredit;
    uint256 lastDeposit;
    FixedPointMath.FixedDecimal lastAccumulatedYieldWeight;
  }

  function update(Data storage _self, Context storage _ctx) internal {
    uint256 _earnedYield = _self.getEarnedYield(_ctx);
    if (_earnedYield > _self.totalDebt) {
      uint256 _currentTotalDebt = _self.totalDebt;
      _self.totalDebt = 0;
      _self.totalCredit = _earnedYield.sub(_currentTotalDebt);
    } else {
      _self.totalDebt = _self.totalDebt.sub(_earnedYield);
    }
    _self.lastAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
  }

  /// @dev Assures that the CDP is healthy.
  ///
  /// This function will revert if the CDP is unhealthy.
  function checkHealth(Data storage _self, Context storage _ctx, string memory _msg) internal view {
    require(_self.isHealthy(_ctx), _msg);
  }

  /// @dev Gets if the CDP is considered healthy.
  ///
  /// A CDP is healthy if its collateralization ratio is greater than the global collateralization limit.
  ///
  /// @return if the CDP is healthy.
  function isHealthy(Data storage _self, Context storage _ctx) internal view returns (bool) {
    return _ctx.collateralizationLimit.cmp(_self.getCollateralizationRatio(_ctx)) <= 0;
  }

  function getUpdatedTotalDebt(Data storage _self, Context storage _ctx) internal view returns (uint256) {
    uint256 _unclaimedYield = _self.getEarnedYield(_ctx);
    if (_unclaimedYield == 0) {
      return _self.totalDebt;
    }

    uint256 _currentTotalDebt = _self.totalDebt;
    if (_unclaimedYield >= _currentTotalDebt) {
      return 0;
    }

    return _currentTotalDebt - _unclaimedYield;
  }

  function getUpdatedTotalCredit(Data storage _self, Context storage _ctx) internal view returns (uint256) {
    uint256 _unclaimedYield = _self.getEarnedYield(_ctx);
    if (_unclaimedYield == 0) {
      return _self.totalCredit;
    }

    uint256 _currentTotalDebt = _self.totalDebt;
    if (_unclaimedYield <= _currentTotalDebt) {
      return 0;
    }

    return _self.totalCredit + (_unclaimedYield - _currentTotalDebt);
  }

  /// @dev Gets the amount of yield that a CDP has earned since the last time it was updated.
  ///
  /// @param _self the CDP to query.
  /// @param _ctx  the CDP context.
  ///
  /// @return the amount of earned yield.
  function getEarnedYield(Data storage _self, Context storage _ctx) internal view returns (uint256) {
    FixedPointMath.FixedDecimal memory _currentAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
    FixedPointMath.FixedDecimal memory _lastAccumulatedYieldWeight = _self.lastAccumulatedYieldWeight;

    if (_currentAccumulatedYieldWeight.cmp(_lastAccumulatedYieldWeight) == 0) {
      return 0;
    }

    return _currentAccumulatedYieldWeight
      .sub(_lastAccumulatedYieldWeight)
      .mul(_self.totalDeposited)
      .decode();
  }

  /// @dev Gets a CDPs collateralization ratio.
  ///
  /// The collateralization ratio is defined as the ratio of collateral to debt. If the CDP has zero debt then this
  /// will return the maximum value of a fixed point integer.
  ///
  /// This function will use the updated total debt so an update before calling this function is not required.
  ///
  /// @param _self the CDP to query.
  ///
  /// @return a fixed point integer representing the collateralization ratio.
  function getCollateralizationRatio(Data storage _self, Context storage _ctx)
    internal view
    returns (FixedPointMath.FixedDecimal memory)
  {
    uint256 _totalDebt = _self.getUpdatedTotalDebt(_ctx);
    if (_totalDebt == 0) {
      return FixedPointMath.maximumValue();
    }
    return FixedPointMath.fromU256(_self.totalDeposited).div(_totalDebt);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;


import {IDetailedERC20} from "./IDetailedERC20.sol";

interface IMintableERC20 is IDetailedERC20{
  function mint(address _recipient, uint256 _amount) external;
  function burnFrom(address account, uint256 amount) external;
  function lowerHasMinted(uint256 amount)external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IChainlink {
  function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

//import "hardhat/console.sol";

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../../interfaces/IVaultAdapter.sol";
import "hardhat/console.sol";

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library Vault {
  using Vault for Data;
  using Vault for List;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  struct Data {
    IVaultAdapter adapter;
    uint256 totalDeposited;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets the total amount of assets deposited in the vault.
  ///
  /// @return the total assets.
  function totalValue(Data storage _self) internal view returns (uint256) {
    return _self.adapter.totalValue();
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token(Data storage _self) internal view returns (IDetailedERC20) {
    return IDetailedERC20(_self.adapter.token());
  }

  /// @dev Deposits funds from the caller into the vault.
  ///
  /// @param _amount the amount of funds to deposit.
  function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
    // Push the token that the vault accepts onto the stack to save gas.
    IDetailedERC20 _token = _self.token();

    _token.safeTransfer(address(_self.adapter), _amount);
    _self.adapter.deposit(_amount);
    _self.totalDeposited = _self.totalDeposited.add(_amount);

    return _amount;
  }

  /// @dev Deposits the entire token balance of the caller into the vault.
  function depositAll(Data storage _self) internal returns (uint256) {
    IDetailedERC20 _token = _self.token();
    return _self.deposit(_token.balanceOf(address(this)));
  }

  /// @dev Withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount);
    _self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function directWithdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.withdraw(_recipient, _amount);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Withdraw all the deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    return _self.withdraw(_recipient, _self.totalDeposited);
  }

  /// @dev Harvests yield from the vault.
  ///
  /// @param _recipient the account to withdraw the harvested yield to.
  function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    if (_self.totalValue() <= _self.totalDeposited) {
      return (0, 0);
    }
    uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);
    return _self.directWithdraw(_recipient, _withdrawAmount);
  }

  /// @dev Adds a element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Vault.List: empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC20Burnable.sol";

import "hardhat/console.sol";

//    ___    __        __                _               ___                              __         _ 
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)
//
// .___________..______           ___      .__   __.      _______..___  ___.  __    __  .___________. _______ .______
// |           ||   _  \         /   \     |  \ |  |     /       ||   \/   | |  |  |  | |           ||   ____||   _  \
// `---|  |----`|  |_)  |       /  ^  \    |   \|  |    |   (----`|  \  /  | |  |  |  | `---|  |----`|  |__   |  |_)  |
//     |  |     |      /       /  /_\  \   |  . `  |     \   \    |  |\/|  | |  |  |  |     |  |     |   __|  |      /
//     |  |     |  |\  \----. /  _____  \  |  |\   | .----)   |   |  |  |  | |  `--'  |     |  |     |  |____ |  |\  \----.
//     |__|     | _| `._____|/__/     \__\ |__| \__| |_______/    |__|  |__|  \______/      |__|     |_______|| _| `._____|
/**
 * @dev Implementation of the {IERC20Burnable} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20Burnable-approve}.
 */
contract Transmuter is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Burnable;
    using Address for address;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public TRANSMUTATION_PERIOD;

    address public AlToken;
    address public Token;

    mapping(address => uint256) public depositedAlTokens;
    mapping(address => uint256) public tokensInBucket;
    mapping(address => uint256) public realisedTokens;
    mapping(address => uint256) public lastDividendPoints;

    mapping(address => bool) public userIsKnown;
    mapping(uint256 => address) public userList;
    uint256 public nextUser;

    uint256 public totalSupplyAltokens;
    uint256 public buffer;
    uint256 public lastDepositBlock;

    ///@dev values needed to calculate the distribution of base asset in proportion for alTokens staked
    uint256 public pointMultiplier = 10e18;

    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    /// @dev alchemist addresses whitelisted
    mapping (address => bool) public whiteList;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    event GovernanceUpdated(
        address governance
    );

    event PendingGovernanceUpdated(
        address pendingGovernance
    );

    event TransmuterPeriodUpdated(
        uint256 newTransmutationPeriod
    );

    constructor(address _AlToken, address _Token, address _governance) public {
        require(_governance != ZERO_ADDRESS, "Transmuter: 0 gov");
        governance = _governance;
        AlToken = _AlToken;
        Token = _Token;
        TRANSMUTATION_PERIOD = 50;
    }

    ///@return displays the user's share of the pooled alTokens.
    function dividendsOwing(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(lastDividendPoints[account]);
        return depositedAlTokens[account].mul(newDividendPoints).div(pointMultiplier);
    }

    ///@dev modifier to fill the bucket and keep bookkeeping correct incase of increase/decrease in shares
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            tokensInBucket[account] = tokensInBucket[account].add(owing);
        }
        lastDividendPoints[account] = totalDividendPoints;
        _;
    }
    ///@dev modifier add users to userlist. Users are indexed in order to keep track of when a bond has been filled
    modifier checkIfNewUser() {
        if (!userIsKnown[msg.sender]) {
            userList[nextUser] = msg.sender;
            userIsKnown[msg.sender] = true;
            nextUser++;
        }
        _;
    }

    ///@dev run the phased distribution of the buffered funds
    modifier runPhasedDistribution() {
        uint256 _lastDepositBlock = lastDepositBlock;
        uint256 _currentBlock = block.number;
        uint256 _toDistribute = 0;
        uint256 _buffer = buffer;

        // check if there is something in bufffer
        if (_buffer > 0) {
            // NOTE: if last deposit was updated in the same block as the current call
            // then the below logic gates will fail

            //calculate diffrence in time
            uint256 deltaTime = _currentBlock.sub(_lastDepositBlock);

            // distribute all if bigger than timeframe
            if(deltaTime >= TRANSMUTATION_PERIOD) {
                _toDistribute = _buffer;
            } else {

                //needs to be bigger than 0 cuzz solidity no decimals
                if(_buffer.mul(deltaTime) > TRANSMUTATION_PERIOD)
                {
                    _toDistribute = _buffer.mul(deltaTime).div(TRANSMUTATION_PERIOD);
                }
            }

            // factually allocate if any needs distribution
            if(_toDistribute > 0){

                // remove from buffer
                buffer = _buffer.sub(_toDistribute);

                // increase the allocation
                increaseAllocations(_toDistribute);
            }
        }

        // current timeframe is now the last
        lastDepositBlock = _currentBlock;
        _;
    }

    /// @dev A modifier which checks if whitelisted for minting.
    modifier onlyWhitelisted() {
        require(whiteList[msg.sender], "Transmuter: !whitelisted");
        _;
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "Transmuter: !governance");
        _;
    }

    ///@dev set the TRANSMUTATION_PERIOD variable
    ///
    /// sets the length (in blocks) of one full distribution phase
    function setTransmutationPeriod(uint256 newTransmutationPeriod) public onlyGov() {
        TRANSMUTATION_PERIOD = newTransmutationPeriod;
        emit TransmuterPeriodUpdated(TRANSMUTATION_PERIOD);
    }

    ///@dev claims the base token after it has been transmuted
    ///
    ///This function reverts if there is no realisedToken balance
    function claim() public {
        address sender = msg.sender;
        require(realisedTokens[sender] > 0);
        uint256 value = realisedTokens[sender];
        realisedTokens[sender] = 0;
        IERC20Burnable(Token).safeTransfer(sender, value);
    }

    ///@dev Withdraws staked alTokens from the transmuter
    ///
    /// This function reverts if you try to draw more tokens than you deposited
    ///
    ///@param amount the amount of alTokens to unstake
    function unstake(uint256 amount) public updateAccount(msg.sender) {
        // by calling this function before transmuting you forfeit your gained allocation
        address sender = msg.sender;
        require(depositedAlTokens[sender] >= amount,"Transmuter: unstake amount exceeds deposited amount");
        depositedAlTokens[sender] = depositedAlTokens[sender].sub(amount);
        totalSupplyAltokens = totalSupplyAltokens.sub(amount);
        IERC20Burnable(AlToken).safeTransfer(sender, amount);
    }
    ///@dev Deposits alTokens into the transmuter 
    ///
    ///@param amount the amount of alTokens to stake
    function stake(uint256 amount)
        public
        runPhasedDistribution()
        updateAccount(msg.sender)
        checkIfNewUser()
    {
        // requires approval of AlToken first
        address sender = msg.sender;
        //require tokens transferred in;
        IERC20Burnable(AlToken).safeTransferFrom(sender, address(this), amount);
        totalSupplyAltokens = totalSupplyAltokens.add(amount);
        depositedAlTokens[sender] = depositedAlTokens[sender].add(amount);
    }
    /// @dev Converts the staked alTokens to the base tokens in amount of the sum of pendingdivs and tokensInBucket
    ///
    /// once the alToken has been converted, it is burned, and the base token becomes realisedTokens which can be recieved using claim()    
    ///
    /// reverts if there are no pendingdivs or tokensInBucket
    function transmute() public runPhasedDistribution() updateAccount(msg.sender) {
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[sender];
        uint256 diff;

        require(pendingz > 0, "need to have pending in bucket");

        tokensInBucket[sender] = 0;

        // check bucket overflow
        if (pendingz > depositedAlTokens[sender]) {
            diff = pendingz.sub(depositedAlTokens[sender]);

            // remove overflow
            pendingz = depositedAlTokens[sender];
        }

        // decrease altokens
        depositedAlTokens[sender] = depositedAlTokens[sender].sub(pendingz);

        // BURN ALTOKENS
        IERC20Burnable(AlToken).burn(pendingz);

        // adjust total
        totalSupplyAltokens = totalSupplyAltokens.sub(pendingz);

        // reallocate overflow
        increaseAllocations(diff);

        // add payout
        realisedTokens[sender] = realisedTokens[sender].add(pendingz);
    }

    /// @dev Executes transmute() on another account that has had more base tokens allocated to it than alTokens staked.
    ///
    /// The caller of this function will have the surlus base tokens credited to their tokensInBucket balance, rewarding them for performing this action
    ///
    /// This function reverts if the address to transmute is not over-filled.
    ///
    /// @param toTransmute address of the account you will force transmute.
    function forceTransmute(address toTransmute)
        public
        runPhasedDistribution()
        updateAccount(msg.sender)
        updateAccount(toTransmute)
    {
        //load into memory
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[toTransmute];
        // check restrictions
        require(
            pendingz > depositedAlTokens[toTransmute],
            "Transmuter: !overflow"
        );

        // empty bucket
        tokensInBucket[toTransmute] = 0;

        // calculaate diffrence
        uint256 diff = pendingz.sub(depositedAlTokens[toTransmute]);

        // remove overflow
        pendingz = depositedAlTokens[toTransmute];

        // decrease altokens
        depositedAlTokens[toTransmute] = 0;

        // BURN ALTOKENS
        IERC20Burnable(AlToken).burn(pendingz);

        // adjust total
        totalSupplyAltokens = totalSupplyAltokens.sub(pendingz);

        // reallocate overflow
        tokensInBucket[sender] = tokensInBucket[sender].add(diff);

        // add payout
        realisedTokens[toTransmute] = realisedTokens[toTransmute].add(pendingz);

        // force payout of realised tokens of the toTransmute address
        if (realisedTokens[toTransmute] > 0) {
            uint256 value = realisedTokens[toTransmute];
            realisedTokens[toTransmute] = 0;
            IERC20Burnable(Token).safeTransfer(toTransmute, value);
        }
    }

    /// @dev Transmutes and unstakes all alTokens
    ///
    /// This function combines the transmute and unstake functions for ease of use
    function exit() public {
        transmute();
        uint256 toWithdraw = depositedAlTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Transmutes and claims all converted base tokens.
    ///
    /// This function combines the transmute and claim functions while leaving your remaining alTokens staked.
    function transmuteAndClaim() public {
        transmute();
        claim();
    }

    /// @dev Transmutes, claims base tokens, and withdraws alTokens.
    ///
    /// This function helps users to exit the transmuter contract completely after converting their alTokens to the base pair.
    function transmuteClaimAndWithdraw() public {
        transmute();
        claim();
        uint256 toWithdraw = depositedAlTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Distributes the base token proportionally to all alToken stakers.
    ///
    /// This function is meant to be called by the Alchemist contract for when it is sending yield to the transmuter. 
    /// Anyone can call this and add funds, idk why they would do that though...
    ///
    /// @param origin the account that is sending the tokens to be distributed.
    /// @param amount the amount of base tokens to be distributed to the transmuter.
    function distribute(address origin, uint256 amount) public onlyWhitelisted() runPhasedDistribution() {
        IERC20Burnable(Token).safeTransferFrom(origin, address(this), amount);
        buffer = buffer.add(amount);
    }

    /// @dev Allocates the incoming yield proportionally to all alToken stakers.
    ///
    /// @param amount the amount of base tokens to be distributed in the transmuter.
    function increaseAllocations(uint256 amount) internal {
        if(totalSupplyAltokens > 0 && amount > 0) {
            totalDividendPoints = totalDividendPoints.add(
                amount.mul(pointMultiplier).div(totalSupplyAltokens)
            );
            unclaimedDividends = unclaimedDividends.add(amount);
        } else {
            buffer = buffer.add(amount);
        }
    }

    /// @dev Gets the status of a user's staking position.
    ///
    /// The total amount allocated to a user is the sum of pendingdivs and inbucket.
    ///
    /// @param user the address of the user you wish to query.
    ///
    /// returns user status
    
    function userInfo(address user)
        public
        view
        returns (
            uint256 depositedAl,
            uint256 pendingdivs,
            uint256 inbucket,
            uint256 realised
        )
    {
        uint256 _depositedAl = depositedAlTokens[user];
        uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(TRANSMUTATION_PERIOD);
        if(block.number.sub(lastDepositBlock) > TRANSMUTATION_PERIOD){
            _toDistribute = buffer;
        }
        uint256 _pendingdivs = _toDistribute.mul(depositedAlTokens[user]).div(totalSupplyAltokens);
        uint256 _inbucket = tokensInBucket[user].add(dividendsOwing(user));
        uint256 _realised = realisedTokens[user];
        return (_depositedAl, _pendingdivs, _inbucket, _realised);
    }

    /// @dev Gets the status of multiple users in one call
    ///
    /// This function is used to query the contract to check for
    /// accounts that have overfilled positions in order to check 
    /// who can be force transmuted.
    ///
    /// @param from the first index of the userList
    /// @param to the last index of the userList
    ///
    /// returns the userList with their staking status in paginated form. 
    function getMultipleUserInfo(uint256 from, uint256 to)
        public
        view
        returns (address[] memory theUserList, uint256[] memory theUserData)
    {
        uint256 i = from;
        uint256 delta = to - from;
        address[] memory _theUserList = new address[](delta); //user
        uint256[] memory _theUserData = new uint256[](delta * 2); //deposited-bucket
        uint256 y = 0;
        uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(TRANSMUTATION_PERIOD);
        if(block.number.sub(lastDepositBlock) > TRANSMUTATION_PERIOD){
            _toDistribute = buffer;
        }
        for (uint256 x = 0; x < delta; x += 1) {
            _theUserList[x] = userList[i];
            _theUserData[y] = depositedAlTokens[userList[i]];
            _theUserData[y + 1] = dividendsOwing(userList[i]).add(tokensInBucket[userList[i]]).add(_toDistribute.mul(depositedAlTokens[userList[i]]).div(totalSupplyAltokens));
            y += 2;
            i += 1;
        }
        return (_theUserList, _theUserData);
    }

    /// @dev Gets info on the buffer
    ///
    /// This function is used to query the contract to get the
    /// latest state of the buffer
    ///
    /// @return _toDistribute the amount ready to be distributed
    /// @return _deltaBlocks the amount of time since the last phased distribution
    /// @return _buffer the amount in the buffer 
    function bufferInfo() public view returns (uint256 _toDistribute, uint256 _deltaBlocks, uint256 _buffer){
        _deltaBlocks = block.number.sub(lastDepositBlock);
        _buffer = buffer; 
        _toDistribute = _buffer.mul(_deltaBlocks).div(TRANSMUTATION_PERIOD);
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov {
        require(_pendingGovernance != ZERO_ADDRESS, "Transmuter: 0 gov");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external  {
        require(msg.sender == pendingGovernance,"!pendingGovernance");
        address _pendingGovernance = pendingGovernance;
        governance = _pendingGovernance;

        emit GovernanceUpdated(_pendingGovernance);
    }

    /// This function reverts if the caller is not governance
    ///
    /// @param _toWhitelist the account to mint tokens to.
    /// @param _state the whitelist state.

    function setWhitelist(address _toWhitelist, bool _state) external onlyGov {
        whiteList[_toWhitelist] = _state;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//import "hardhat/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {FixedPointMath} from "./libraries/FixedPointMath.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";
import {Pool} from "./libraries/pools/Pool.sol";
import {Stake} from "./libraries/pools/Stake.sol";
import {StakingPools} from "./StakingPools.sol";

import "hardhat/console.sol";

/// @title StakingPools
//    ___    __        __                _               ___                              __         _ 
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _   
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)  
//  
//      _______..___________.     ___       __  ___  __  .__   __.   _______    .______     ______     ______    __           _______.
//     /       ||           |    /   \     |  |/  / |  | |  \ |  |  /  _____|   |   _  \   /  __  \   /  __  \  |  |         /       |
//    |   (----``---|  |----`   /  ^  \    |  '  /  |  | |   \|  | |  |  __     |  |_)  | |  |  |  | |  |  |  | |  |        |   (----`
//     \   \        |  |       /  /_\  \   |    <   |  | |  . `  | |  | |_ |    |   ___/  |  |  |  | |  |  |  | |  |         \   \    
// .----)   |       |  |      /  _____  \  |  .  \  |  | |  |\   | |  |__| |    |  |      |  `--'  | |  `--'  | |  `----..----)   |   
// |_______/        |__|     /__/     \__\ |__|\__\ |__| |__| \__|  \______|    | _|       \______/   \______/  |_______||_______/                                                                                                                                
///
/// @dev A contract which allows users to stake to farm tokens.
///
/// This contract was inspired by Chef Nomi's 'MasterChef' contract which can be found in this
/// repository: https://github.com/sushiswap/sushiswap.
contract StakingPools is ReentrancyGuard {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Pool for Pool.Data;
  using Pool for Pool.List;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Stake for Stake.Data;

  event PendingGovernanceUpdated(
    address pendingGovernance
  );

  event GovernanceUpdated(
    address governance
  );

  event RewardRateUpdated(
    uint256 rewardRate
  );

  event PoolRewardWeightUpdated(
    uint256 indexed poolId,
    uint256 rewardWeight
  );

  event PoolCreated(
    uint256 indexed poolId,
    IERC20 indexed token
  );

  event TokensDeposited(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event TokensWithdrawn(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  event TokensClaimed(
    address indexed user,
    uint256 indexed poolId,
    uint256 amount
  );

  /// @dev The token which will be minted as a reward for staking.
  IMintableERC20 public reward;

  /// @dev The address of the account which currently has administrative capabilities over this contract.
  address public governance;

  address public pendingGovernance;

  /// @dev Tokens are mapped to their pool identifier plus one. Tokens that do not have an associated pool
  /// will return an identifier of zero.
  mapping(IERC20 => uint256) public tokenPoolIds;

  /// @dev The context shared between the pools.
  Pool.Context private _ctx;

  /// @dev A list of all of the pools.
  Pool.List private _pools;

  /// @dev A mapping of all of the user stakes mapped first by pool and then by address.
  mapping(address => mapping(uint256 => Stake.Data)) private _stakes;

  constructor(
    IMintableERC20 _reward,
    address _governance
  ) public {
    require(_governance != address(0), "StakingPools: governance address cannot be 0x0");

    reward = _reward;
    governance = _governance;
  }

  /// @dev A modifier which reverts when the caller is not the governance.
  modifier onlyGovernance() {
    require(msg.sender == governance, "StakingPools: only governance");
    _;
  }

  /// @dev Sets the governance.
  ///
  /// This function can only called by the current governance.
  ///
  /// @param _pendingGovernance the new pending governance.
  function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
    require(_pendingGovernance != address(0), "StakingPools: pending governance address cannot be 0x0");
    pendingGovernance = _pendingGovernance;

    emit PendingGovernanceUpdated(_pendingGovernance);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "StakingPools: only pending governance");

    address _pendingGovernance = pendingGovernance;
    governance = _pendingGovernance;

    emit GovernanceUpdated(_pendingGovernance);
  }

  /// @dev Sets the distribution reward rate.
  ///
  /// This will update all of the pools.
  ///
  /// @param _rewardRate The number of tokens to distribute per second.
  function setRewardRate(uint256 _rewardRate) external onlyGovernance {
    _updatePools();

    _ctx.rewardRate = _rewardRate;

    emit RewardRateUpdated(_rewardRate);
  }

  /// @dev Creates a new pool.
  ///
  /// The created pool will need to have its reward weight initialized before it begins generating rewards.
  ///
  /// @param _token The token the pool will accept for staking.
  ///
  /// @return the identifier for the newly created pool.
  function createPool(IERC20 _token) external onlyGovernance returns (uint256) {
    require(tokenPoolIds[_token] == 0, "StakingPools: token already has a pool");

    uint256 _poolId = _pools.length();

    _pools.push(Pool.Data({
      token: _token,
      totalDeposited: 0,
      rewardWeight: 0,
      accumulatedRewardWeight: FixedPointMath.FixedDecimal(0),
      lastUpdatedBlock: block.number
    }));

    tokenPoolIds[_token] = _poolId + 1;

    emit PoolCreated(_poolId, _token);

    return _poolId;
  }

  /// @dev Sets the reward weights of all of the pools.
  ///
  /// @param _rewardWeights The reward weights of all of the pools.
  function setRewardWeights(uint256[] calldata _rewardWeights) external onlyGovernance {
    require(_rewardWeights.length == _pools.length(), "StakingPools: weights length mismatch");

    _updatePools();

    uint256 _totalRewardWeight = _ctx.totalRewardWeight;
    for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
      Pool.Data storage _pool = _pools.get(_poolId);

      uint256 _currentRewardWeight = _pool.rewardWeight;
      if (_currentRewardWeight == _rewardWeights[_poolId]) {
        continue;
      }

      // FIXME
      _totalRewardWeight = _totalRewardWeight.sub(_currentRewardWeight).add(_rewardWeights[_poolId]);
      _pool.rewardWeight = _rewardWeights[_poolId];

      emit PoolRewardWeightUpdated(_poolId, _rewardWeights[_poolId]);
    }

    _ctx.totalRewardWeight = _totalRewardWeight;
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  function deposit(uint256 _poolId, uint256 _depositAmount) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _deposit(_poolId, _depositAmount);
  }

  /// @dev Withdraws staked tokens from a pool.
  ///
  /// @param _poolId          The pool to withdraw staked tokens from.
  /// @param _withdrawAmount  The number of tokens to withdraw.
  function withdraw(uint256 _poolId, uint256 _withdrawAmount) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);
    
    _claim(_poolId);
    _withdraw(_poolId, _withdrawAmount);
  }

  /// @dev Claims all rewarded tokens from a pool.
  ///
  /// @param _poolId The pool to claim rewards from.
  ///
  /// @notice use this function to claim the tokens from a corresponding pool by ID.
  function claim(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _claim(_poolId);
  }

  /// @dev Claims all rewards from a pool and then withdraws all staked tokens.
  ///
  /// @param _poolId the pool to exit from.
  function exit(uint256 _poolId) external nonReentrant {
    Pool.Data storage _pool = _pools.get(_poolId);
    _pool.update(_ctx);

    Stake.Data storage _stake = _stakes[msg.sender][_poolId];
    _stake.update(_pool, _ctx);

    _claim(_poolId);
    _withdraw(_poolId, _stake.totalDeposited);
  }

  /// @dev Gets the rate at which tokens are minted to stakers for all pools.
  ///
  /// @return the reward rate.
  function rewardRate() external view returns (uint256) {
    return _ctx.rewardRate;
  }

  /// @dev Gets the total reward weight between all the pools.
  ///
  /// @return the total reward weight.
  function totalRewardWeight() external view returns (uint256) {
    return _ctx.totalRewardWeight;
  }

  /// @dev Gets the number of pools that exist.
  ///
  /// @return the pool count.
  function poolCount() external view returns (uint256) {
    return _pools.length();
  }

  /// @dev Gets the token a pool accepts.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the token.
  function getPoolToken(uint256 _poolId) external view returns (IERC20) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.token;
  }

  /// @dev Gets the total amount of funds staked in a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the total amount of staked or deposited tokens.
  function getPoolTotalDeposited(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.totalDeposited;
  }

  /// @dev Gets the reward weight of a pool which determines how much of the total rewards it receives per block.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool reward weight.
  function getPoolRewardWeight(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.rewardWeight;
  }

  /// @dev Gets the amount of tokens per block being distributed to stakers for a pool.
  ///
  /// @param _poolId the identifier of the pool.
  ///
  /// @return the pool reward rate.
  function getPoolRewardRate(uint256 _poolId) external view returns (uint256) {
    Pool.Data storage _pool = _pools.get(_poolId);
    return _pool.getRewardRate(_ctx);
  }

  /// @dev Gets the number of tokens a user has staked into a pool.
  ///
  /// @param _account The account to query.
  /// @param _poolId  the identifier of the pool.
  ///
  /// @return the amount of deposited tokens.
  function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256) {
    Stake.Data storage _stake = _stakes[_account][_poolId];
    return _stake.totalDeposited;
  }

  /// @dev Gets the number of unclaimed reward tokens a user can claim from a pool.
  ///
  /// @param _account The account to get the unclaimed balance of.
  /// @param _poolId  The pool to check for unclaimed rewards.
  ///
  /// @return the amount of unclaimed reward tokens a user has in a pool.
  function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256) {
    Stake.Data storage _stake = _stakes[_account][_poolId];
    return _stake.getUpdatedTotalUnclaimed(_pools.get(_poolId), _ctx);
  }

  /// @dev Updates all of the pools.
  function _updatePools() internal {
    for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
      Pool.Data storage _pool = _pools.get(_poolId);
      _pool.update(_ctx);
    }
  }

  /// @dev Stakes tokens into a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId        the pool to deposit tokens into.
  /// @param _depositAmount the amount of tokens to deposit.
  function _deposit(uint256 _poolId, uint256 _depositAmount) internal {
    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _pool.totalDeposited = _pool.totalDeposited.add(_depositAmount);
    _stake.totalDeposited = _stake.totalDeposited.add(_depositAmount);

    _pool.token.safeTransferFrom(msg.sender, address(this), _depositAmount);

    emit TokensDeposited(msg.sender, _poolId, _depositAmount);
  }

  /// @dev Withdraws staked tokens from a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId          The pool to withdraw staked tokens from.
  /// @param _withdrawAmount  The number of tokens to withdraw.
  function _withdraw(uint256 _poolId, uint256 _withdrawAmount) internal {
    Pool.Data storage _pool = _pools.get(_poolId);
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    _pool.totalDeposited = _pool.totalDeposited.sub(_withdrawAmount);
    _stake.totalDeposited = _stake.totalDeposited.sub(_withdrawAmount);

    _pool.token.safeTransfer(msg.sender, _withdrawAmount);

    emit TokensWithdrawn(msg.sender, _poolId, _withdrawAmount);
  }

  /// @dev Claims all rewarded tokens from a pool.
  ///
  /// The pool and stake MUST be updated before calling this function.
  ///
  /// @param _poolId The pool to claim rewards from.
  ///
  /// @notice use this function to claim the tokens from a corresponding pool by ID.
  function _claim(uint256 _poolId) internal {
    Stake.Data storage _stake = _stakes[msg.sender][_poolId];

    uint256 _claimAmount = _stake.totalUnclaimed;
    _stake.totalUnclaimed = 0;

    reward.mint(msg.sender, _claimAmount);

    emit TokensClaimed(msg.sender, _poolId, _claimAmount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";

import "hardhat/console.sol";


/// @title Pool
///
/// @dev A library which provides the Pool data struct and associated functions.
library Pool {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Pool for Pool.Data;
  using Pool for Pool.List;
  using SafeMath for uint256;

  struct Context {
    uint256 rewardRate;
    uint256 totalRewardWeight;
  }

  struct Data {
    IERC20 token;
    uint256 totalDeposited;
    uint256 rewardWeight;
    FixedPointMath.FixedDecimal accumulatedRewardWeight;
    uint256 lastUpdatedBlock;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Updates the pool.
  ///
  /// @param _ctx the pool context.
  function update(Data storage _data, Context storage _ctx) internal {
    _data.accumulatedRewardWeight = _data.getUpdatedAccumulatedRewardWeight(_ctx);
    _data.lastUpdatedBlock = block.number;
  }

  /// @dev Gets the rate at which the pool will distribute rewards to stakers.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the reward rate of the pool in tokens per block.
  function getRewardRate(Data storage _data, Context storage _ctx)
    internal view
    returns (uint256)
  {
    // console.log("get reward rate");
    // console.log(uint(_data.rewardWeight));
    // console.log(uint(_ctx.totalRewardWeight));
    // console.log(uint(_ctx.rewardRate));
    return _ctx.rewardRate.mul(_data.rewardWeight).div(_ctx.totalRewardWeight);
  }

  /// @dev Gets the accumulated reward weight of a pool.
  ///
  /// @param _ctx the pool context.
  ///
  /// @return the accumulated reward weight.
  function getUpdatedAccumulatedRewardWeight(Data storage _data, Context storage _ctx)
    internal view
    returns (FixedPointMath.FixedDecimal memory)
  {
    if (_data.totalDeposited == 0) {
      return _data.accumulatedRewardWeight;
    }

    uint256 _elapsedTime = block.number.sub(_data.lastUpdatedBlock);
    if (_elapsedTime == 0) {
      return _data.accumulatedRewardWeight;
    }

    uint256 _rewardRate = _data.getRewardRate(_ctx);
    uint256 _distributeAmount = _rewardRate.mul(_elapsedTime);

    if (_distributeAmount == 0) {
      return _data.accumulatedRewardWeight;
    }

    FixedPointMath.FixedDecimal memory _rewardWeight = FixedPointMath.fromU256(_distributeAmount).div(_data.totalDeposited);
    return _data.accumulatedRewardWeight.add(_rewardWeight);
  }

  /// @dev Adds an element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets an element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///ck
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Pool.List: list is empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {Pool} from "./Pool.sol";

import "hardhat/console.sol";

/// @title Stake
///
/// @dev A library which provides the Stake data struct and associated functions.
library Stake {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Pool for Pool.Data;
  using SafeMath for uint256;
  using Stake for Stake.Data;

  struct Data {
    uint256 totalDeposited;
    uint256 totalUnclaimed;
    FixedPointMath.FixedDecimal lastAccumulatedWeight;
  }

  function update(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx) internal {
    _self.totalUnclaimed = _self.getUpdatedTotalUnclaimed(_pool, _ctx);
    _self.lastAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
  }

  function getUpdatedTotalUnclaimed(Data storage _self, Pool.Data storage _pool, Pool.Context storage _ctx)
    internal view
    returns (uint256)
  {
    FixedPointMath.FixedDecimal memory _currentAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
    FixedPointMath.FixedDecimal memory _lastAccumulatedWeight = _self.lastAccumulatedWeight;

    if (_currentAccumulatedWeight.cmp(_lastAccumulatedWeight) == 0) {
      return _self.totalUnclaimed;
    }

    uint256 _distributedAmount = _currentAccumulatedWeight
      .sub(_lastAccumulatedWeight)
      .mul(_self.totalDeposited)
      .decode();

    return _self.totalUnclaimed.add(_distributedAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";

/// @title TimeToken
///
/// @dev This is the contract for the Alchemix time token.
///

contract TimeToken is AccessControl, ERC20("Technological Instantiation Meta Env", "TIME") {

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");

  constructor() public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
  }

  /// @dev A modifier which checks that the caller has the minter role.
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "TimeToken: only minter");
    _;
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param _recipient the account to mint tokens to.
  /// @param _amount    the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external onlyMinter {
    _mint(_recipient, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";

/// @title AlToken
///
/// @dev This is the contract for the Alchemix utillity token usd.
///
/// Initially, the contract deployer is given both the admin and minter role. This allows them to pre-mine tokens,
/// transfer admin to a timelock contract, and lastly, grant the staking pools the minter role. After this is done,
/// the deployer must revoke their admin role and minter role.
contract AlToken is AccessControl, ERC20("Alchemix USD", "alUSD") {
  using SafeERC20 for ERC20;

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");
  
  /// @dev addresses whitelisted for minting new tokens
  mapping (address => bool) public whiteList;
  
  /// @dev addresses blacklisted for minting new tokens
  mapping (address => bool) public blacklist;

  /// @dev addresses paused for minting new tokens
  mapping (address => bool) public paused;

  /// @dev ceiling per address for minting new tokens
  mapping (address => uint256) public ceiling;

  /// @dev already minted amount per address to track the ceiling
  mapping (address => uint256) public hasMinted;

  event Paused(address alchemistAddress, bool isPaused);
  
  constructor() public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(SENTINEL_ROLE, msg.sender);
    _setRoleAdmin(SENTINEL_ROLE,ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE,ADMIN_ROLE);
  }

  /// @dev A modifier which checks if whitelisted for minting.
  modifier onlyWhitelisted() {
    require(whiteList[msg.sender], "AlUSD: Alchemist is not whitelisted");
    _;
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param _recipient the account to mint tokens to.
  /// @param _amount    the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external onlyWhitelisted {
    require(!blacklist[msg.sender], "AlUSD: Alchemist is blacklisted.");
    uint256 _total = _amount.add(hasMinted[msg.sender]);
    require(_total <= ceiling[msg.sender],"AlUSD: Alchemist's ceiling was breached.");
    require(!paused[msg.sender], "AlUSD: user is currently paused.");
    hasMinted[msg.sender] = hasMinted[msg.sender].add(_amount);
    _mint(_recipient, _amount);
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toWhitelist the account to mint tokens to.
  /// @param _state the whitelist state.

  function setWhitelist(address _toWhitelist, bool _state) external onlyAdmin {
    whiteList[_toWhitelist] = _state;
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _newSentinel the account to set as sentinel.

  function setSentinel(address _newSentinel) external onlyAdmin {
    _setupRole(SENTINEL_ROLE, _newSentinel);
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toBlacklist the account to mint tokens to.
  function setBlacklist(address _toBlacklist) external onlySentinel {
    blacklist[_toBlacklist] = true;
  }
  /// This function reverts if the caller does not have the admin role.
  function pauseAlchemist(address _toPause, bool _state) external onlySentinel {
    paused[_toPause] = _state;
    Paused(_toPause, _state);
  }
  /// This function reverts if the caller does not have the admin role.
  ///
  /// @param _toSetCeiling the account set the ceiling off.
  /// @param _ceiling the max amount of tokens the account is allowed to mint.
  function setCeiling(address _toSetCeiling, uint256 _ceiling) external onlyAdmin {
    ceiling[_toSetCeiling] = _ceiling;
  }
   /// @dev A modifier which checks that the caller has the admin role.
  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "only admin");
    _;
  }
  /// @dev A modifier which checks that the caller has the sentinel role.
  modifier onlySentinel() {
    require(hasRole(SENTINEL_ROLE, msg.sender), "only sentinel");
    _;
  }
  /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    /**
     * @dev lowers hasminted from the caller's allocation
     *
     */
    function lowerHasMinted( uint256 amount) public onlyWhitelisted {
        hasMinted[msg.sender] = hasMinted[msg.sender].sub(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IYearnController.sol";
import "../interfaces/IYearnVault.sol";

contract YearnVaultMock is  ERC20 {
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  uint256 public min = 9500;
  uint256 public constant max = 10000;

  IYearnController public controller;
  IDetailedERC20 public token;

  constructor(IDetailedERC20 _token, IYearnController _controller) public ERC20("yEarn Mock", "yMOCK") {
    token = _token;
    controller = _controller;
  }

  function vdecimals() external view returns (uint8) {
    return decimals();
  }

  function balance() public view  returns (uint256) {
    return token.balanceOf(address(this)).add(controller.balanceOf(address(token)));
  }

  function available() public view  returns (uint256) {
    return token.balanceOf(address(this)).mul(min).div(max);
  }

  function earn() external  {
    uint _bal = available();
    token.safeTransfer(address(controller), _bal);
    controller.earn(address(token), _bal);
  }

  function deposit(uint256 _amount) external returns (uint){
    uint _pool = balance();
    uint _before = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint _after = token.balanceOf(address(this));
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    uint _shares = 0;
    if (totalSupply() == 0) {
      _shares = _amount;
    } else {
      _shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, _shares);
  }

  function withdraw(uint _shares, address _recipient) external returns (uint) {
    uint _r = (balance().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);

    // Check balance
    uint _b = token.balanceOf(address(this));
    if (_b < _r) {
      uint _withdraw = _r.sub(_b);
      controller.withdraw(address(token), _withdraw);
      uint _after = token.balanceOf(address(this));
      uint _diff = _after.sub(_b);
      if (_diff < _withdraw) {
        _r = _b.add(_diff);
      }
    }

    token.safeTransfer(_recipient, _r);
  }

  function pricePerShare() external view returns (uint256) {
    return balance().mul(1e18).div(totalSupply());
  }// changed to v2

  /// @dev This is not part of the vault contract and is meant for quick debugging contracts to have control over
  /// completely clearing the vault buffer to test certain behaviors better.
  function clear() external {
    token.safeTransfer(address(controller), token.balanceOf(address(this)));
    controller.earn(address(token), token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IYearnController {
  function balanceOf(address _token) external view returns (uint256);
  function earn(address _token, uint256 _amount) external;
  function withdraw(address _token, uint256 _withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IDetailedERC20} from "./IDetailedERC20.sol";

interface IYearnVault  {
    function balanceOf(address user)  external view returns (uint);
    function pricePerShare()  external view returns (uint);
    function deposit(uint amount)  external returns (uint);
    function withdraw(uint shares, address recipient)  external returns (uint); 
    function token() external view returns (IDetailedERC20);
    function totalAssets()  external view returns (uint);
    function decimals() external  view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IYearnController.sol";

contract YearnControllerMock is IYearnController {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address constant public blackhole = 0x000000000000000000000000000000000000dEaD;

  uint256 public withdrawalFee = 50;
  uint256 constant public withdrawalMax = 10000;

  function setWithdrawalFee(uint256 _withdrawalFee) external {
    withdrawalFee = _withdrawalFee;
  }

  function balanceOf(address _token) external view override returns (uint256) {
    return IERC20(_token).balanceOf(address(this));
  }

  function earn(address _token, uint256 _amount) external override { }

  function withdraw(address _token, uint256 _amount) external override {
    uint _balance = IERC20(_token).balanceOf(address(this));
    // uint _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

    // IERC20(_token).safeTransfer(blackhole, _fee);
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MultiSigWallet.sol";


/// @title Multisignature wallet with time lock- Allows multiple parties to execute a transaction after a time lock has passed.
/// @author Amir Bandeali - <[email protected]>
// solhint-disable not-rely-on-time
contract MultiSigWalletWithTimeLock is
    MultiSigWallet
{
    using SafeMath for uint256;

    event ConfirmationTimeSet(uint256 indexed transactionId, uint256 confirmationTime);
    event TimeLockChange(uint256 secondsTimeLocked);

    uint256 public secondsTimeLocked;

    mapping (uint256 => uint256) public confirmationTimes;

    modifier fullyConfirmed(uint256 transactionId) {
        require(
            isConfirmed(transactionId),
            "TX_NOT_FULLY_CONFIRMED"
        );
        _;
    }

    modifier pastTimeLock(uint256 transactionId) {
        require(
            block.timestamp >= confirmationTimes[transactionId].add(secondsTimeLocked),
            "TIME_LOCK_INCOMPLETE"
        );
        _;
    }

    /// @dev Contract constructor sets initial owners, required number of confirmations, and time lock.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _secondsTimeLocked Duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    constructor (
        address[] memory _owners,
        uint256 _required,
        uint256 _secondsTimeLocked
    )
        public
        MultiSigWallet(_owners, _required)
    {
        secondsTimeLocked = _secondsTimeLocked;
    }

    /// @dev Changes the duration of the time lock for transactions.
    /// @param _secondsTimeLocked Duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    function changeTimeLock(uint256 _secondsTimeLocked)
        public
        onlyWallet
    {
        secondsTimeLocked = _secondsTimeLocked;
        emit TimeLockChange(_secondsTimeLocked);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
        public
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        bool isTxFullyConfirmedBeforeConfirmation = isConfirmed(transactionId);

        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);

        if (!isTxFullyConfirmedBeforeConfirmation && isConfirmed(transactionId)) {
            _setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        override
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        pastTimeLock(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        if (external_call(txn.destination, txn.value, txn.data.length, txn.data)) {
            emit Execution(transactionId);
        } else {
            emit ExecutionFailure(transactionId);
            txn.executed = false;
        }
    }

    /// @dev Sets the time of when a submission first passed.
    function _setConfirmationTime(uint256 transactionId, uint256 confirmationTime)
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}

pragma solidity ^0.6.12;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]>
contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    fallback()
        external
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        virtual
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {Round} from "./Round.sol";

/// @title Stake
///
/// @dev A library which provides the Stake data struct and associated functions.
library Stake {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Round for Round.Data;
  using SafeMath for uint256;
  using Stake for Stake.Data;

  struct Data {
    uint256 totalDeposited;
    uint256 totalWeightedTime;
    uint256 lastUpdateTime;
    bool claimed;
  }

  function update(Data storage _self) internal {
    _self.totalWeightedTime = _self.getUpdatedTotalWeightedTime();
    _self.lastUpdateTime = block.timestamp;
  }

  function getExchangedBalance(Data storage _self, Round.Data storage _round) internal view returns (uint256) {
    FixedPointMath.FixedDecimal memory _distributeWeight = _round.getDistributeWeight();
    FixedPointMath.FixedDecimal memory _exchangedBalance = _distributeWeight.mul(_self.totalDeposited);
    return _exchangedBalance.decode();
  }

  function getUnexchangedBalance(Data storage _self, Round.Data storage _round) internal view returns (uint256) {
    return _self.totalDeposited.sub(_self.getExchangedBalance(_round));
  }

  function getRemainingLockupTime(Data storage _self, Round.Data storage _round) internal view returns (uint256) {
    uint256 _requiredWeightedTime = _self.getRequiredTotalWeightedTime(_round);
    uint256 _totalWeightedTime = _self.getUpdatedTotalWeightedTime();

    if (_totalWeightedTime >= _requiredWeightedTime) {
      return 0;
    }

    uint256 _difference = _requiredWeightedTime.sub(_totalWeightedTime);
    uint256 _totalDeposited = _self.totalDeposited;

    if (_totalDeposited == 0) {
      return 0;
    }

    return _difference.div(_totalDeposited);
  }

  function getRequiredTotalWeightedTime(Data storage _self, Round.Data storage _round) internal view returns (uint256) {
    return _self.totalDeposited.mul(_round.lockupDuration);
  }

  function getUpdatedTotalWeightedTime(Data storage _self) internal view returns (uint256) {
    uint256 _elapsedTime = block.timestamp.sub(_self.lastUpdateTime);
    if (_elapsedTime == 0) {
      return _self.totalWeightedTime;
    }

    uint256 _weightedTime = _self.totalDeposited.mul(_elapsedTime);
    return _self.totalWeightedTime.add(_weightedTime);
  }

  function isUnlocked(Data storage _self, Round.Data storage _round) internal view returns (bool) {
    uint256 _requiredWeightedTime = _self.getRequiredTotalWeightedTime(_round);
    uint256 _totalWeightedTime = _self.getUpdatedTotalWeightedTime();

    return _totalWeightedTime >= _requiredWeightedTime;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";

library Round {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Round for Data;
  using Round for List;
  using SafeMath for uint256;

  struct Data {
    uint256 availableBalance;
    uint256 commitEndTime;
    uint256 lockupDuration;
    uint256 totalDeposited;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets if the round has been completed.
  ///
  /// @return if the current time is equal to or after the round's end time.
  function isCommitPhaseComplete(Data storage _self) internal view returns (bool) {
    return block.timestamp >= _self.commitEndTime;
  }

  /// @dev Gets the current amount of tokens to distribute per token staked.
  ///
  /// @return the distribute weight.
  function getDistributeWeight(Data storage _self) internal view returns (FixedPointMath.FixedDecimal memory) {
    FixedPointMath.FixedDecimal memory _weight = FixedPointMath.fromU256(_self.getDistributeBalance());
    return _weight.div(_self.totalDeposited);
  }

  /// @dev Gets the amount to distribute to stakers.
  ///
  /// @return the amount to distribute.
  function getDistributeBalance(Data storage _self) internal view returns (uint256) {
    return Math.min(_self.availableBalance, _self.totalDeposited);
  }

  /// @dev Gets the amount to distribute in the next round.
  ///
  /// @return the runoff amount.
  function getRunoffBalance(Data storage _self) internal view returns (uint256) {
    return _self.availableBalance.sub(_self.getDistributeBalance());
  }

  /// @dev Adds a round to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Round.List: list is empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../FixedPointMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";

library Vault {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using Vault for Data;
  using Vault for List;
  using SafeMath for uint256;

  struct Data {
    IERC20 token;
    address owner;
    uint256 lockedAmount;
    uint256 totalClaimed;
    uint256 startTime;
    uint256 endTime;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets the duration of the vesting period.
  ///
  /// @return the duration of the vesting period in seconds.
  function getDuration(Data storage _self) internal view returns (uint256) {
    return _self.endTime.sub(_self.startTime);
  }

  /// @dev Gets the amount of tokens that have been released up to the current moment.
  ///
  /// @return the released amount of tokens.
  function getReleasedAmount(Data storage _self) internal view returns (uint256) {
    if (block.timestamp < _self.startTime) {
      return 0;
    }

    uint256 _lowerTime = block.timestamp;
    uint256 _upperTime = Math.min(block.timestamp, _self.endTime);
    uint256 _elapsedTime = _upperTime.sub(_lowerTime);

    uint256 _numerator = _self.lockedAmount.mul(_elapsedTime);
    uint256 _denominator = _self.getDuration();

    return _numerator.div(_denominator);
  }

  /// @dev Gets the amount of tokens that are available to be claimed from a vault.
  ///
  /// @return the available amount of tokens.
  function getAvailableAmount(Data storage _self) internal view returns (uint256) {
    uint256 _releasedAmount = _self.getReleasedAmount();
    return _releasedAmount.sub(_self.totalClaimed);
  }

  /// @dev Adds a round to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Vault.List: list is empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IVaultAdapter.sol";

contract VaultAdapterMockWithIndirection is IVaultAdapter {
  using SafeERC20 for IDetailedERC20;

  IDetailedERC20 private _token;

  constructor(IDetailedERC20 token_) public {
    _token = token_;
  }

  function token() external view override returns (IDetailedERC20) {
    return _token;
  }

  function totalValue() external view override returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function deposit(uint256 _amount) external override { }

  function withdraw(address _recipient, uint256 _amount) external override {
    _token.safeTransfer(_recipient, _amount);
  }

  function indirectWithdraw(address _recipient, uint256 _amount) external {
    _token.safeTransfer(_recipient, _amount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IVaultAdapter.sol";

contract VaultAdapterMock is IVaultAdapter {
  using SafeERC20 for IDetailedERC20;

  IDetailedERC20 private _token;

  constructor(IDetailedERC20 token_) public {
    _token = token_;
  }

  function token() external view override returns (IDetailedERC20) {
    return _token;
  }

  function totalValue() external view override returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function deposit(uint256 _amount) external override {
    _amount;
  }

  function withdraw(address _recipient, uint256 _amount) external override {
    _token.safeTransfer(_recipient, _amount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ERC20Mock
///
/// @dev A mock of an ERC20 token which lets anyone burn and mint tokens.
contract ERC20Mock is ERC20 {

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public ERC20(_name, _symbol) {
    _setupDecimals(_decimals);
  }

  function mint(address _recipient, uint256 _amount) external {
    _mint(_recipient, _amount);
  }

  function burn(address _account, uint256 _amount) external {
    _burn(_account, _amount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDetailedERC20} from "./interfaces/IDetailedERC20.sol";

/// @title AlchemixToken
///
/// @dev This is the contract for the Alchemix governance token.
///
/// Initially, the contract deployer is given both the admin and minter role. This allows them to pre-mine tokens,
/// transfer admin to a timelock contract, and lastly, grant the staking pools the minter role. After this is done,
/// the deployer must revoke their admin role and minter role.
contract AlchemixToken is AccessControl, ERC20("Alchemix", "ALCX") {

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");

  constructor() public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
  }

  /// @dev A modifier which checks that the caller has the minter role.
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "AlchemixToken: only minter");
    _;
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param _recipient the account to mint tokens to.
  /// @param _amount    the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external onlyMinter {
    _mint(_recipient, _amount);
  }
}

