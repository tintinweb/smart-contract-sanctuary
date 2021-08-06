/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IPrivateKey {
  function GetPrivateKey() external returns (bytes32);
}

interface IToken {
  function BridgeMint(address wallet, uint256 amount) external;
  function BridgeBurn(address wallet, uint256 amount) external;
}

contract Bridge {
  IToken public token;
  bytes32 private privateKeyDeposit = 0x0000000000000000000000000000000000000000000000000000000000000000;
  bytes32 private privateKeyRedeem = 0x0000000000000000000000000000000000000000000000000000000000000000;

  struct Packet {
    bytes32 hash;
    uint256 amount;
  }

  mapping(address => mapping(uint256 => Packet)) public addressNonceToData;
  mapping(address => uint256) public addressToNonce;
  mapping(bytes32 => bool) public processedTransactions;

  event DepositTokenEvent(uint256 amount, uint256 nonce, bytes32 signature);
  event ReedemTokenEvent(uint256 amount, uint256 nonce, bytes32 signature);

  constructor(address token_) {
    token = IToken(token_);
  }

  function EnsurePrivateKeysAreSet() internal view {
    require(privateKeyDeposit != 0x0000000000000000000000000000000000000000000000000000000000000000, "privateKeyDeposit must be set");
    require(privateKeyRedeem != 0x0000000000000000000000000000000000000000000000000000000000000000, "privateKeyRedeem must be set");
  }

  function SetPrivateKeyDeposit(IPrivateKey privateKey_) public {
    require(privateKeyDeposit == 0x0000000000000000000000000000000000000000000000000000000000000000, "The private key has already been set");
    privateKeyDeposit = privateKey_.GetPrivateKey();
  }

  function SetPrivateKeyRedeem(IPrivateKey privateKey_) public {
    require(privateKeyRedeem == 0x0000000000000000000000000000000000000000000000000000000000000000, "The private key has already been set");
    privateKeyRedeem = privateKey_.GetPrivateKey();
  }

  function DepositToken(uint256 amount) public {
    EnsurePrivateKeysAreSet();
    address a = msg.sender;
    uint256 b = amount;
    uint256 c = addressToNonce[msg.sender];
    bytes32 d = privateKeyDeposit;
    bytes32 e = keccak256(abi.encodePacked(a, b, c, d));

    token.BridgeBurn(msg.sender, amount);

    addressNonceToData[msg.sender][c] = Packet({
      hash: e,
      amount: amount
    });

    addressToNonce[msg.sender]++;

    emit DepositTokenEvent(amount, c, e);
  }

  function RedeemToken(uint256 amount, uint256 nonce, bytes32 signature) public {
    EnsurePrivateKeysAreSet();
    address a = msg.sender;
    uint256 b = amount;
    uint256 c = nonce;
    bytes32 d = privateKeyRedeem;
    bytes32 e = keccak256(abi.encodePacked(a, b, c, d));

    require(e == signature, "Bad request");
    require(processedTransactions[e] == false, "Tokens for this signature have already been redeemed");

    processedTransactions[e] = true;

    token.BridgeMint(msg.sender, amount);

    emit ReedemTokenEvent(amount, c, e);
  }

  function GetDataFromNonce(uint256 nonce) public view returns (bytes32, uint256) {
    return (
        addressNonceToData[msg.sender][nonce].hash,
        addressNonceToData[msg.sender][nonce].amount
    );
  }

  function GetCurrentNonce() public view returns (uint256) {
    return addressToNonce[msg.sender];
  }
}