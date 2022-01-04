// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import './Ownable.sol';
import './Strings.sol';
import './ERC1155.sol';
import './base64.sol';
import './IERC2981.sol';
import './ISpells.sol';
import './SpellsUtils.sol';
import './ThemeBase.sol';

contract SchellingSpellsNFT is IERC2981, ERC1155, Ownable, ThemeBase {
  using Strings for uint256;

  string public constant name = "Schelling Spells";
  string public constant symbol = "SCHPELLS-NFT"; 
  address public immutable SPELLS_NFT;
  
  address private royaltyAddress;
  uint256 private royaltyPercentage; // in basis points
  string private description;

  modifier onlySpellsNft {
    require(msg.sender == SPELLS_NFT, "NOT AUTHED");
    _;
  }

  constructor(address _spellsNft) ERC1155("") {
    SPELLS_NFT = _spellsNft;
    updateRoyalties(msg.sender, 1000);
    SVG_COLORS = [
      // 0
      ['656565', '383838'],
      // 1
      ['9E9E9E', '606060'],
      // 2
      ['939393', '393939'],
      // 3
      ['8E8E8E', '424242'],
      // 4
      ['A8A8A8', '616161'],
      // 5
      ['D6D6D6', 'A4A4A4'],
      // 6
      ['393939', '262626'],
      // 7
      ['858585', '414141'],
      // 8
      ['FFFFFF', '000000']
    ];
  }
  
  function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155) returns (bool) {
    return
      _interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function contractURI() external view returns (string memory) {
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
        abi.encodePacked(
          '{'
            '"name": "', name, '",'
            '"description": "', unicode"**🅂🄲🄷🄴🄻🄻🄸🄽🄶⿻🅂🄿🄴🄻🄻🅂**\\n\\n", description,
            '\\n\\n`.a work by outerpockets.`",'
            '"image": "https://www.spellsnft.com/schellings-opensea.png",'
            '"external_link": "https://www.spellsnft.com",'
            '"seller_fee_basis_points": ', royaltyPercentage.toString(), ','
            '"fee_recipient": "', uint256(uint160(royaltyAddress)).toHexString(20), '"'
          '}'
        ))
    ));
  }

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    require(
        account == msg.sender,
        "NOT AUTHED"
    );
    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    require(
        account == msg.sender,
        "NOT AUTHED"
    );
    _burnBatch(account, ids, values);
  }

  function mint(address _to, uint256 _tokenId) external onlySpellsNft {
    _mint(_to, _tokenId, 1, "");
  }

  function renderSvg(uint256 _tokenId) external view returns (string memory) {
    require(ISpells(SPELLS_NFT).tokens(_tokenId).reservationNumber > 0);
    uint256 shape = SpellsUtils.getShape(_tokenId);
    uint256 letterBlocks = SpellsUtils.getLetterBlocks(_tokenId);
    uint256 length = SpellsUtils.popCount(shape);
    return _renderSvg(
      shape,
      letterBlocks,
      length
    );
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
    return (
      royaltyAddress,
      _salePrice * royaltyPercentage / 10000
    );
  }

  function updateRoyalties(address _royaltyAddress, uint256 _royaltyPercentage) public onlyOwner {
    if(_royaltyAddress != address(0)){
      royaltyAddress = _royaltyAddress;
    }
    royaltyPercentage = _royaltyPercentage;
  }

  function updateDescription(string calldata _newDescription) external onlyOwner {
    description = _newDescription;
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(ISpells(SPELLS_NFT).tokens(_tokenId).reservationNumber > 0);
    uint256 shape = SpellsUtils.getShape(_tokenId);
    uint256 letterBlocks = SpellsUtils.getLetterBlocks(_tokenId);
    uint256 length = SpellsUtils.popCount(shape);
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(abi.encodePacked(
            '{'
              '"name":"', SpellsUtils.renderText(
                SpellsUtils.sortLetters(SpellsUtils.getCharacters(letterBlocks, length), length), PLAIN_TEXT), '",'
              '"external_url":"https://www.spellsnft.com/schelling/', _tokenId.toString(), '",'
              '"description":"hey... i thought of [that](https://www.spellsnft.com/spell/',
                _tokenId.toString(), ')...'
                '\\n\\n```\\n',
                _renderUnicode(shape, letterBlocks, length),
                '\\n```",'
              '"image": "data:image/svg+xml;base64,',
                Base64.encode(
                  bytes(_renderSvg(
                    shape,
                    letterBlocks,
                    length
                  ))), '",'
              '"background_color": "F7F3EC"'
            '}'
        )))
    ));
  }
}