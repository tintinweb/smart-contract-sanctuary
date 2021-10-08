//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract LazyNFT is ERC721URIStorage, EIP712, AccessControl {
  using ECDSA for bytes32;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  mapping (address => uint256) pendingWithdrawals;

  constructor(address payable minter)
    ERC721("LazyNFT", "LAZ") 
    EIP712("LazyNFT-Voucher", "1") {
      _setupRole(MINTER_ROLE, minter);
    }

  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    uint256 tokenId;

    uint256 minPrice;

    string uri;
  }


  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher An NFTVoucher that describes the NFT to be redeemed.
  /// @param signature An EIP712 signature of the voucher, produced by the NFT creator.
  function redeem(address redeemer, NFTVoucher calldata voucher, bytes memory signature) public payable returns (uint256) {
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher, signature);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

    // first assign the token to the signer, to establish provenance on-chain
    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    
    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    // record payment to signer's withdrawal balance
    pendingWithdrawals[signer] += msg.value;

    return voucher.tokenId;
  }

  function withdraw() public {
    require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can withdraw");
    
    // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
    address payable receiver = payable(msg.sender);

    uint amount = pendingWithdrawals[receiver];
    // zero account before transfer to prevent re-entrancy attack
    pendingWithdrawals[receiver] = 0;
    receiver.transfer(amount);
  }

  function availableToWithdraw() public view returns (uint256) {
    return pendingWithdrawals[msg.sender];
  }

  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
      voucher.tokenId,
      voucher.minPrice,
      keccak256(bytes(voucher.uri))
    )));
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An NFTVoucher describing an unminted NFT.
  /// @param signature An EIP712 signature of the given voucher.
  function _verify(NFTVoucher calldata voucher, bytes memory signature) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return digest.toEthSignedMessageHash().recover(signature);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
  }
}