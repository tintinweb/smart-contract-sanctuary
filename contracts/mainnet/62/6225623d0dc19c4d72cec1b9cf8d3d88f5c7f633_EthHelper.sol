/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract EthHelper {
	function hasCode(address addr) external view returns (bool) {
      uint256 size;
      assembly { size := extcodesize(addr) }
      return size > 0;
	}

	function codeSize(address addr) external view returns (uint256) {
      uint256 size;
      assembly { size := extcodesize(addr) }
      return size;
	}

	function code(address addr) external view returns (bytes memory) {
      return addr.code;
	}

	function codeHash(address addr) external view returns (bytes32) {
      return addr.codehash;
	}

	function balance(address addr) external view returns (uint256) {
      return addr.balance;
	}

	function txOrigin() external view returns (address) {
      return tx.origin;
	}

	function txGasPrice() external view returns (uint256) {
      return tx.gasprice;
	}

	function chainId() external view returns (uint256) {
		return block.chainid;
	}

	function blockCoinbase() external view returns (address) {
		return block.coinbase;
	}

	function blockDifficulty() external view returns (uint256) {
		return block.difficulty;
	}

	function blockGaslimit() external view returns (uint256) {
		return block.gaslimit;
	}

	function blockNumber() external view returns (uint256) {
		return block.number;
	}

	function blockTimestamp() external view returns (uint256) {
		return block.timestamp;
	}

	function blockHashAt(uint256 blockNumber) external view returns (bytes32) {
		uint256 blocksAgo = block.number - blockNumber;
		require(blocksAgo > 0 && blocksAgo <= 256, "EthHelper#blockHashAt: Invalid blockNumber value");
		return blockhash(blockNumber);
	}

	function blockHashFrom(uint256 blocksAgo) external view returns (bytes32) {
		require(blocksAgo > 0 && blocksAgo <= 256, "EthHelper#blockHashFrom: Invalid blocksAgo value");
		return blockhash(block.number - blocksAgo);
	}

	function gasleft() external view returns (uint256) {
		// Note: does not correct for 63/64ths rule, only useful as an approximation
		return gasleft();
	}

	function not(bool a) external pure returns (bool) {
		return !a;
	}

	function and(bool a, bool b) external pure returns (bool) {
		return a && b;
	}

	function or(bool a, bool b) external pure returns (bool) {
		return a || b;
	}

	function add(uint256 a, uint256 b) external pure returns (uint256) {
		return a + b;
	}

	function sub(uint256 a, uint256 b) external pure returns (uint256) {
		return a - b;
	}

	function mul(uint256 a, uint256 b) external pure returns (uint256) {
		return a * b;
	}

	function div(uint256 a, uint256 b) external pure returns (uint256) {
		return a / b;
	}

	function mod(uint256 a, uint256 b) external pure returns (uint256) {
		return a % b;
	}

	function exp(uint256 a, uint256 b) external pure returns (uint256) {
		return a ** b;
	}

	function addmod(uint256 x, uint256 y, uint256 k) external pure returns (uint256) {
		return addmod(x, y, k);
	}

	function mulmod(uint256 x, uint256 y, uint256 k) external pure returns (uint256) {
		return mulmod(x, y, k);
	}

	function and(uint256 a, uint256 b) external pure returns (uint256) {
		return a & b;
	}

	function or(uint256 a, uint256 b) external pure returns (uint256) {
		return a | b;
	}

	function xor(uint256 a, uint256 b) external pure returns (uint256) {
		return a ^ b;
	}

	function bitwiseNot(uint256 a) external pure returns (uint256) {
		return ~a;
	}

	function shl(uint256 a, uint256 b) external pure returns (uint256) {
		return a << b;
	}

	function shr(uint256 a, uint256 b) external pure returns (uint256) {
		return a >> b;
	}

	function lt(uint256 a, uint256 b) external pure returns (bool) {
		return a < b;
	}

	function lte(uint256 a, uint256 b) external pure returns (bool) {
		return a <= b;
	}

	function gt(uint256 a, uint256 b) external pure returns (bool) {
		return a > b;
	}

	function gte(uint256 a, uint256 b) external pure returns (bool) {
		return a >= b;
	}

	function eq(uint256 a, uint256 b) external pure returns (bool) {
		return a == b;
	}

	function ne(uint256 a, uint256 b) external pure returns (bool) {
		return a != b;
	}

	function and(bytes32 a, bytes32 b) external pure returns (bytes32) {
		return a & b;
	}

	function or(bytes32 a, bytes32 b) external pure returns (bytes32) {
		return a | b;
	}

	function xor(bytes32 a, bytes32 b) external pure returns (bytes32) {
		return a ^ b;
	}

	function bitwiseNot(bytes32 a) external pure returns (bytes32) {
		return ~a;
	}

	function shl(bytes32 a, uint256 b) external pure returns (bytes32) {
		return a << b;
	}

	function shr(bytes32 a, uint256 b) external pure returns (bytes32) {
		return a >> b;
	}

	function lt(bytes32 a, bytes32 b) external pure returns (bool) {
		return a < b;
	}

	function lte(bytes32 a, bytes32 b) external pure returns (bool) {
		return a <= b;
	}

	function gt(bytes32 a, bytes32 b) external pure returns (bool) {
		return a > b;
	}

	function gte(bytes32 a, bytes32 b) external pure returns (bool) {
		return a >= b;
	}

	function eq(bytes32 a, bytes32 b) external pure returns (bool) {
		return a == b;
	}

	function ne(bytes32 a, bytes32 b) external pure returns (bool) {
		return a != b;
	}

	function lt(address a, address b) external pure returns (bool) {
		return a < b;
	}

	function lte(address a, address b) external pure returns (bool) {
		return a <= b;
	}

	function gt(address a, address b) external pure returns (bool) {
		return a > b;
	}

	function gte(address a, address b) external pure returns (bool) {
		return a >= b;
	}

	function eq(address a, address b) external pure returns (bool) {
		return a == b;
	}

	function ne(address a, address b) external pure returns (bool) {
		return a != b;
	}

	function isCaller(address addr) external view returns (bool) {
		return msg.sender == addr;
	}

	function eq(bytes calldata a, bytes calldata b) external pure returns (bool) {
		return keccak256(a) == keccak256(b);
	}

	function ne(bytes calldata a, bytes calldata b) external pure returns (bool) {
		return keccak256(a) != keccak256(b);
	}

	function eq(string calldata a, string calldata b) external pure returns (bool) {
		return keccak256(bytes(a)) == keccak256(bytes(b));
	}

	function ne(string calldata a, string calldata b) external pure returns (bool) {
		return keccak256(bytes(a)) != keccak256(bytes(b));
	}

	function keccak256(bytes calldata data) external pure returns (bytes32) {
		return keccak256(data);
	}

	function ripemd160(bytes calldata data) external pure returns (bytes32) {
		return ripemd160(data);
	}

	function sha256(bytes calldata data) external pure returns (bytes32) {
		return sha256(data);
	}

	function ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external pure returns (address) {
		return ecrecover(hash, v, r, s);
	}
}