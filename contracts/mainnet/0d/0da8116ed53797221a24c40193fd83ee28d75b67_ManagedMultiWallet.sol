/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  The wallet allows depositing/withdrawing funds to/from internal keyed storage.
  For convenience keys in the storage are public "address"s, and access is controlled by
  ownership of a corresponding private key.

  Public APIs:
    * put(address): To deposit money into a wallet keyed by |pub|.
    * get(signature): To withdraw money from wallet |pub|,
      sign sender's (your) wallet address by the |pub|'s private key.
      Note that API expects r,s,v values (standard for 65 byte ecdsa secp256k1 signature).
    * OWNER ONLY: rem(address): Clear wallet by sending money to the owner.
*/
contract ManagedMultiWallet {
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    mapping(address => uint256) public wallets;
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function put(address _pub) external payable {
        wallets[_pub] += msg.value;
    }

    function peek(address _pub) external view returns (uint256) {
        return wallets[_pub];
    }

    // |r|, |s|, |v| are 32+32+1 bytes of 65 byte ecdsa secp256k1 signature
    // |v| must be 27 or 28 (0x1b or 0x1c)
    function get(
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external {
        require(_v == 27 || _v == 28);
        address signer = ecrecover(
            bytes32(uint256(uint160(msg.sender))),
            _v,
            _r,
            _s
        );
        require(signer != address(0) && wallets[signer] != 0);
        payable(msg.sender).transfer(wallets[signer]);
        wallets[signer] = 0;
    }

    function rem(address _pub) external onlyOwner {
        require(wallets[_pub] != 0);
        payable(owner).transfer(wallets[_pub]);
        wallets[_pub] = 0;
    }
}