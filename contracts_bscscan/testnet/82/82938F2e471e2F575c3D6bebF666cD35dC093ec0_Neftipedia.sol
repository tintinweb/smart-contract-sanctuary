// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.4 <=0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155MintBurnPackedBalance.sol";

contract Neftipedia is ERC1155MintBurnPackedBalance {

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  /**
  ** @dev See {IERC721Metadata-name}.
  */
  function name() public override view virtual returns (string memory) {
    return _name;
  }

  /**
  ** @dev See {IERC721Metadata-symbol}.
  */
  function symbol() public override view virtual returns (string memory) {
    return _symbol;
  }

  /***********************************|
  |               ERC165              |
  |__________________________________*/
  /**
   * @notice Query if a contract implements an interface
   * @dev Parent contract inheriting multiple contracts with supportsInterface()
   *      need to implement an overriding supportsInterface() function specifying
   *      all inheriting contracts that have a supportsInterface() function.
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID)
    public view virtual
    override(
      ERC1155PackedBalance
    )
    returns (bool)
  { return super.supportsInterface(_interfaceID); }

  // fallback () external {
  //   revert("ERC1155MetaMintBurnPackedBalanceMock: INVALID_METHOD");
  // }

  /**
  ** @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
  */
  constructor (
    string memory name_,
    string memory symbol_,
    string memory baseMetadataURI_,
    address calcFeeExt_
  ) {
    _name = name_;
    _symbol = symbol_;
    _setBaseMetadataURI(baseMetadataURI_);

    // Reference of CalcFee Contract ?
    setCalcFeeExt(calcFeeExt_);
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/
  /**
   * @dev Mint _value of tokens of a given id
   * @param _to The address to mint tokens to.
   * @param _id token id to mint
   * @param _value The amount to be minted
   * @param _data Data to be passed if receiver is contract
   */
  function mint(address _to, uint256 _id, uint256 _value, bytes memory _data)
    public override payable
    { _mint(_to, _id, _value, _data); }
  
  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to The address to mint tokens to.
   * @param _ids Array of ids to mint
   * @param _values Array of amount of tokens to mint per id
   * @param _data Data to be passed if receiver is contract
   */
  function batchMint(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data)
    public override payable
    { _batchMint(_to, _ids, _values, _data); }

  /***********************************|
  |         Burning Functions         |
  |__________________________________*/
  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _id token id to burn
   * @param _value The amount to be burned
   */
  function burn(address _from, uint256 _id, uint256 _value)
    public override
    { _burn(_from, _id, _value); }

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _ids Array of token ids to burn
   * @param _values Array of the amount to be burned
   */
  function batchBurn(address _from, uint256[] memory _ids, uint256[] memory _values)
    public override
    { _batchBurn(_from, _ids, _values); }

  // WARNING: There are no handler in fallback function,
  //          If there are any incoming value directly to Smart Contract address
  //          consider apply as generous donation. And Thank you!
  receive () external payable /* nonReentrant */ {}
  fallback () external payable /* nonReentrant */ {}
}