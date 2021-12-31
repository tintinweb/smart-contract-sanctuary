// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "./INEFTiLicense.sol";
import "./ERC1155MintBurnPackedBalance.sol";

/** 8662deae */
contract Neftipedia is ERC1155MintBurnPackedBalance {
  bytes32 public version = keccak256("1.10.55");
  /** MultiTokens Info */
  string private _name;
  string private _symbol;
  address private _legalInfo;

  /** 5fff73ee */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /** 77bde41b */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~~~~~~~ ERC165 ~~~~~~~~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** 3986ebc7
   ** @notice Query if a contract implements an interface
   ** @dev Parent contract inheriting multiple contracts with supportsInterface()
   **      need to implement an overriding supportsInterface() function specifying
   **      all inheriting contracts that have a supportsInterface() function.
   ** @param _interfaceID The interface identifier, as specified in ERC-165
   ** @return `true` if the contract implements `_interfaceID`
   **/
  function supportsInterface(bytes4 _interfaceID)
    public
    view
    virtual
    override(ERC1155PackedBalance)
    returns (bool)
  {
    return super.supportsInterface(_interfaceID);
  }

  /**
   ** 1288e0ce
   ** @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   **/
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseMetadataURI_,
    address calcFeeExt_,
    address legalInfo_
  ) {
    _name = name_;
    _symbol = symbol_;
    _legalInfo = legalInfo_;
    _setBaseMetadataURI(baseMetadataURI_);
    setCalcFeeExt(calcFeeExt_);
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~~~~~~~ MINTING ~~~~~~~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** 7de1cf6
   ** @dev Mint _value of tokens of a given id
   ** @param _to The address to mint tokens to.
   ** @param _id token id to mint
   ** @param _value The amount to be minted
   ** @param _data Data to be passed if receiver is contract
   **/
  function mint(
    address _to,
    uint256 _id,
    uint256 _value,
    bytes memory _data
  ) public payable override {
    require(_to != address(0) && _value > 0, "ENEFTiMP.01.INVALID_ARGUMENTS");
    _mint(_to, _id, _value, _data);
  }

  /**
   ** 57392d88
   ** @dev Mint tokens for each ids in _ids
   ** @param _to The address to mint tokens to.
   ** @param _ids Array of ids to mint
   ** @param _values Array of amount of tokens to mint per id
   ** @param _data Data to be passed if receiver is contract
   **/
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _values,
    bytes memory _data
  ) public payable override {
    _batchMint(_to, _ids, _values, _data);
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~~~~~~~ BURNING ~~~~~~~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** ceb8d4bb
   ** @dev burn _value of tokens of a given token id
   ** @param _from The address to burn tokens from.
   ** @param _id token id to burn
   ** @param _value The amount to be burned
   **/
  function burn(
    address _from,
    uint256 _id,
    uint256 _value
  ) public override {
    _burn(_from, _id, _value);
  }

  /**
   ** e20954ea
   ** @dev burn _value of tokens of a given token id
   ** @param _from The address to burn tokens from.
   ** @param _ids Array of token ids to burn
   ** @param _values Array of the amount to be burned
   **/
  function batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _values
  ) public override {
    _batchBurn(_from, _ids, _values);
  }

  /**
   ** 1955f1b8
   ** @dev Show legal info
   ** @return (
   **    string title,
   **    string license,
   **    string version,
   **    string url
   ** )
   **/
  function legalInfo()
    public
    view
    returns (
      string memory _title,
      string memory _license,
      string memory _version,
      string memory _url
    )
  {
    (_title, _license, _version, _url) = INEFTiLicense(_legalInfo).legalInfo();
  }

  /**
   ** 31084f3e
   ** @dev Update legal info
   ** @param _newLegalInfo Updated info
   **/
  function updateLicense(address _newLegalInfo) public onlyOwner {
    _legalInfo = _newLegalInfo;
  }

  /*════════════════════════════oooooOooooo════════════════════════════╗
    ║█  (!) WARNING  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~█║
    ╚════════════════════════════════════════════════════════════════════╝
    ║  There are no handler in fallback function,                        ║
    ║  If there are any incoming value directly to Smart Contract, will  ║
    ║  considered as generous donation. And Thank you!                   ║
    ╚═══════════════════════════════════════════════════════════════════*/
  receive() external payable /* nonReentrant */
  {

  }

  fallback() external payable /* nonReentrant */
  {

  }
}

/**
 **    █▄░█ █▀▀ █▀▀ ▀█▀ █ █▀█ █▀▀ █▀▄ █ ▄▀█
 **    █░▀█ ██▄ █▀░ ░█░ █ █▀▀ ██▄ █▄▀ █ █▀█
 **    ____________________________________
 **    https://neftipedia.com
 **    [email protected]
 **/