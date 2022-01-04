// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import './Address.sol';
import './Strings.sol';
import './ERC165.sol';
import './IERC721.sol';
import './IERC721Receiver.sol';
import './IERC721Metadata.sol';
import './Ownable.sol';
import './base64.sol';
import './IGridGenerator.sol';
import './ITheme.sol';
import './IERC2981.sol';
import './IMint.sol';
import './ISpellsTypes.sol';
import './SpellsUtils.sol';

contract SpellsNFT is ERC165, IERC2981, IERC721, ISpellsTypes, IERC721Metadata, Ownable {
  using Address for address;
  using Strings for uint256;

  string public constant override name = "Spells NFT";
  string public constant override symbol = "SPELLS-NFT";
  string[] private PLAIN_TEXT = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
    "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
    "Y", "Z", "?"
  ];

  address public schellingContract;
  address public gridGenerator;

  bytes3 private defaultBackgroundColor;
  uint256 private defaultTheme;
  uint40 private reservationCounter;
  uint256 private reservationWindow; // in blocks
  uint256 private revealWindow; // in blocks
  address private royaltyAddress;
  uint256 private royaltyPercentage; // in basis points
  string private description;

  mapping(address => uint256) public override balanceOf;
  mapping(uint256 => Grid) public gridAt;
  mapping(address => mapping(address => bool)) private operatorApprovals;
  mapping(bytes32 => uint256) public reservationQueue;
  address[] public themes;
  mapping(uint256 => address) private tokenApprovals;
  mapping(uint256 => TokenDetails) public tokens;

  struct MintParams {
    uint64 bitboard;
    uint192 letters;
    uint80 path;
    uint16 theme;
    uint256 blockNumberSource;
    uint256 nonce;
    uint256 blockNumberSubmitted;
  }

  constructor(address _gridGenerator, address _startingTheme) {
    updateGridGenerator(_gridGenerator);
    addTheme(_startingTheme);
    updateDefaultBackgroundColor(0xFFF6D1);
    updateRoyalties(msg.sender, 1000);
    updateReservationWindow(180);
    updateRevealWindow(1800);
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(_exists(_tokenId), "TOKEN DOESN'T EXIST");
    require(msg.sender == ownerOf(_tokenId), "NOT AUTHED");
    _;
  }
  
  function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      _interfaceId == type(IERC721).interfaceId ||
      _interfaceId == type(IERC721Metadata).interfaceId ||
      _interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  // ADMIN \\

  function addTheme(address _theme) public onlyOwner {
    require(_theme != address(0));
    themes.push(_theme);
  }

  function updateDefaultBackgroundColor(bytes3 _bgColor) public onlyOwner {
    defaultBackgroundColor = _bgColor;
  }

  function updateDefaultTheme(uint16 _themeNo) public onlyOwner {
    defaultTheme = _themeNo;
  }
  
  function updateDescription(string calldata _newDescription) external onlyOwner {
    description = _newDescription;
  }

  function updateGridGenerator(address _gridGenerator) public onlyOwner {
    gridGenerator = _gridGenerator;
  }

  function updateReservationWindow(uint256 _newWindow) public onlyOwner {
    reservationWindow = _newWindow;
  }

  function updateRevealWindow(uint256 _newWindow) public onlyOwner {
    revealWindow = _newWindow;
  }

  function updateRoyalties(address _royaltyAddress, uint256 _royaltyPercentage) public onlyOwner {
    if(_royaltyAddress != address(0)){
      royaltyAddress = _royaltyAddress;
    }
    royaltyPercentage = _royaltyPercentage;
  }

  function updateSchellings(address _schellingContract) external onlyOwner {
    schellingContract = _schellingContract;
  }

  // 721 \\
  
  function approve(address _to, uint256 _tokenId) public override {
    address owner = ownerOf(_tokenId);
    require(_to != owner, "CAN'T APPROVE SELF");
    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "NOT AUTHED"
    );
    _approve(_to, _tokenId);
  }

  function burn(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
    _burn(_tokenId);
  }

  function contractURI() external view returns (string memory) {
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
        abi.encodePacked(
          '{'
            '"name": "', name, '",'
            '"description": "', unicode"**🅂🄿🄴🄻🄻🅂❏🄽🄵🅃**\\n\\n", description,
            '\\n\\n`.a work by outerpockets.`",'
            '"image": "https://www.spellsnft.com/spells-opensea.png",'
            '"external_link": "https://www.spellsnft.com",'
            '"seller_fee_basis_points": ', royaltyPercentage.toString(), ', '
            '"fee_recipient": "', uint256(uint160(royaltyAddress)).toHexString(20),'"'
          '}'
        ))
    ));
  }

  function getApproved(uint256 _tokenId) public view override returns (address) {
    require(_exists(_tokenId), "TOKEN DOESN'T EXIST");
    return tokenApprovals[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  function ownerOf(uint256 _tokenId) public view override returns (address) {
    address owner = tokens[_tokenId].owner;
    require(owner != address(0), "TOKEN DOESN'T EXIST");
    return owner;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
    return (
      royaltyAddress,
      _salePrice * royaltyPercentage / 10000
    );
  }

  function renderSvg(uint256 _tokenId) external view returns (string memory) {
    require(_exists(_tokenId), "TOKEN DOESN'T EXIST");
    TokenDetails memory tokenDetails = tokens[_tokenId];
    AuxiliaryDetails memory auxDetails;
    {
      uint256 shape = SpellsUtils.getShape(_tokenId);
      uint256 letterBlocks = SpellsUtils.getLetterBlocks(_tokenId);
      uint256 length = SpellsUtils.popCount(shape);
      auxDetails = AuxiliaryDetails(
        shape,
        letterBlocks,
        length
      );
    }
    return ITheme(themes[tokenDetails.theme]).renderSvg(_tokenId, tokenDetails, auxDetails);
  }
  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public override {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) public override {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "NOT AUTHED");
    _safeTransfer(_from, _to, _tokenId, _data);
  }

  function setApprovalForAll(address _operator, bool _approved) external override {
    require(_operator != msg.sender, "NOT AUTHED");
    operatorApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }
  
  function tokenURI(uint256 _tokenId) external view override returns (string memory) {
    require(_exists(_tokenId), "TOKEN DOESN'T EXIST");
    TokenDetails memory tokenDetails = tokens[_tokenId];
    AuxiliaryDetails memory auxDetails;
    {
      uint256 shape = SpellsUtils.getShape(_tokenId);
      uint256 letterBlocks = SpellsUtils.getLetterBlocks(_tokenId);
      uint256 length = SpellsUtils.popCount(shape);
      auxDetails = AuxiliaryDetails(
        shape,
        letterBlocks,
        length
      );
    }
    
    string memory attributes = string(abi.encodePacked(
      '"attributes":[',
        ITheme(themes[tokenDetails.theme]).extendedAttributes(_tokenId, tokenDetails, auxDetails),
        '{'
          '"trait_type": "Anagram",'
          '"value": "', SpellsUtils.renderText(
            SpellsUtils.sortLetters(tokenDetails.word, auxDetails.length), PLAIN_TEXT), '"'
        '},'
        '{'
          '"trait_type": "Length",'
          '"display_type": "number",'
          '"value": ', uint256(auxDetails.length).toString(), ','
          '"max_value": 24'
        '},'
        '{'
          '"trait_type": "Reserved At",'
          '"display_type": "number",'
          '"value": ', uint256(tokenDetails.reservationNumber).toString(),
        '},'
        '{'
          '"trait_type": "Shape",'
          '"value": "', SpellsUtils.getShapeString(auxDetails.shape), '"'
        '},'
        '{'
          '"trait_type": "Word",'
          '"value": "', SpellsUtils.renderText(tokenDetails.word, PLAIN_TEXT), '"'
        '}'
      '],'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(abi.encodePacked(
        '{'
          '"name":"',
          SpellsUtils.renderText(tokenDetails.word, ITheme(themes[tokenDetails.theme]).characterSet()), '",'
          '"background_color": "', SpellsUtils.toColorHexString(uint256(uint24(tokenDetails.backgroundColor))), '",',
          ITheme(themes[tokenDetails.theme]).extendedProperties(_tokenId, tokenDetails, auxDetails),
          attributes,
          '"external_url": "https://www.spellsnft.com/spell/', _tokenId.toString(), '"'
        '}'
      ))
    ));
  }
  
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public override {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "NOT AUTHED");
    _transfer(_from, _to, _tokenId);
  }
  
  function _approve(address _to, uint256 _tokenId) private {
    tokenApprovals[_tokenId] = _to;
    emit Approval(ownerOf(_tokenId), _to, _tokenId);
  }

  function _burn(uint256 _tokenId) private {
    address owner = ownerOf(_tokenId);
    _approve(address(0), _tokenId);
    balanceOf[owner]--;
    tokens[_tokenId].owner = address(0);
    emit Transfer(owner, address(0), _tokenId);
  }
  
  function _checkOnERC721Received(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (_to.isContract()) {
      try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory) {
        return false;
      }
    } else {
      return true;
    }
  }
  
  function _exists(uint256 _tokenId) private view returns (bool) {
    return tokens[_tokenId].owner != address(0);
  }
  
  function _isApprovedOrOwner(address _spender, uint256 _tokenId) private view returns (bool) {
    require(_exists(_tokenId), "TOKEN DOESN'T EXIST");
    address owner = ownerOf(_tokenId);
    return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
  }

  function _mint(uint256 _tokenId, TokenDetails memory _tokenDetails) private {
    tokens[_tokenId] = _tokenDetails;
    address owner = _tokenDetails.owner;
    balanceOf[owner]++;
    emit Transfer(address(0), owner, _tokenId);
  }
  
  function _safeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) private {
    _transfer(_from, _to, _tokenId);
    require(_checkOnERC721Received(_from, _to, _tokenId, _data), "INVALID RECEIVER");
  }
  
  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) private {
    require(ownerOf(_tokenId) == _from, "INVALID SENDER");
    require(_to != address(0), "INVALID RECEIVER");
    balanceOf[_from]--;
    balanceOf[_to]++;
    _approve(address(0), _tokenId);
    tokens[_tokenId].owner = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  // SPELLS LOGIC \\
  
  function auxiliaryDetails(uint256 _tokenId) external view returns (AuxiliaryDetails memory) {
    require(_exists(_tokenId), "TOKEN DOESN'T EXIST");
    uint256 shape = SpellsUtils.getShape(_tokenId);
    uint256 letterBlocks = SpellsUtils.getLetterBlocks(_tokenId);
    uint256 length = SpellsUtils.popCount(shape);
    return AuxiliaryDetails(
      shape,
      letterBlocks,
      length
    );
  }

  function mint(
    MintParams calldata _params
  ) external {
    uint256 reservationNumber = reservationQueue[keccak256(
      abi.encodePacked(
        keccak256(
          abi.encodePacked(
            _params.bitboard,
            _params.letters,
            _params.path,
            _params.nonce
          )
        ),
        msg.sender,
        _params.blockNumberSource,
        _params.blockNumberSubmitted
    ))];
    require(reservationNumber != 0, "RESERVATION NOT FOUND");
    uint256 length = SpellsUtils.popCount(_params.bitboard);
    require(length < 25 && length > 1, "SPELL IS INVALID LENGTH");
    require(_params.blockNumberSubmitted + revealWindow > block.number, "RESERVATION EXPIRED");

    Grid memory currGrid = gridAt[_params.blockNumberSource];
    Grid memory grid = SpellsUtils.generateSpellGrid(_params.bitboard, _params.letters, length);
    Grid memory maskGrid = SpellsUtils.generateSpellGrid(
      _params.bitboard,
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
      length
    );
    currGrid.top &= maskGrid.top;
    currGrid.bottom &= maskGrid.bottom;
    require(currGrid.top == grid.top, "TOP OF GRID DOES NOT MATCH");
    require(currGrid.bottom == grid.bottom, "BOTTOM OF GRID DOES NOT MATCH");

    SpellsUtils.verifyPath(_params.bitboard, _params.path, length);

    (
      uint256 normalizedBitboard,
      uint256 normalizedLetters,
      uint256 normalizedPath
    ) = SpellsUtils.normalize(_params.bitboard, _params.letters, _params.path, length);
    uint256 id = SpellsUtils.combineToId(normalizedBitboard, normalizedLetters);

    TokenDetails memory proposedTokenDetails = TokenDetails(
      msg.sender,
      uint80(normalizedPath),
      _params.theme,
      uint192(SpellsUtils.getWord(
        SpellsUtils.generateSpellGrid(normalizedBitboard, normalizedLetters, length),
        normalizedPath,
        length
      )),
      uint40(reservationNumber),
      defaultBackgroundColor
    );

    if (_params.theme < themes.length && _params.theme != 0) {
      try ITheme(themes[_params.theme]).canUseTheme(
        id,
        TokenDetails(address(0),0,0,0,0,bytes3(0)),
        proposedTokenDetails
      ) returns (bool canUse) {
        proposedTokenDetails.theme = canUse ? _params.theme : uint16(defaultTheme);
      } catch {
        proposedTokenDetails.theme = uint16(defaultTheme);
      }
    } else {
      proposedTokenDetails.theme = uint16(defaultTheme);
    }

    if (tokens[id].reservationNumber == 0) {
      _mint(id, proposedTokenDetails);
    } else if (reservationNumber < tokens[id].reservationNumber) {
      address prevOwner = tokens[id].owner;
      if (prevOwner != address(0)){
        _burn(id);
      }
      _mint(id, proposedTokenDetails);
      IMint(schellingContract).mint(prevOwner, id);
    } else {
      IMint(schellingContract).mint(msg.sender, id);
    }
  }

  function recolor(uint256 _tokenId, bytes3 _newBgColor) external onlyTokenOwner(_tokenId) {
    tokens[_tokenId].backgroundColor = _newBgColor;
  }

  function reconfigure(uint256 _tokenId, uint256 _newPath) external onlyTokenOwner(_tokenId) {
    uint256 bitboard = _tokenId >> 192;
    uint256 length = SpellsUtils.popCount(bitboard);
    SpellsUtils.verifyPath(bitboard, _newPath, length);
    uint80 newPath = uint80(SpellsUtils.cleanPath(
      _newPath,
      length
    ));
    tokens[_tokenId].path = newPath;
    tokens[_tokenId].word = uint192(
      SpellsUtils.getWord(
        SpellsUtils.generateSpellGrid(bitboard, uint192(_tokenId), length),
        newPath,
        length
      )
    );
  }

  function reserve(bytes32 _commit, uint256 _seenAt) external {
    require(block.number - _seenAt < reservationWindow, "RESERVED TOO LATE");
    reservationQueue[keccak256(abi.encodePacked(_commit, msg.sender, _seenAt, block.number))] = ++reservationCounter;
    if (gridAt[_seenAt].top == bytes32(0) && gridAt[_seenAt].bottom == bytes32(0)) {
      gridAt[_seenAt] = IGridGenerator(gridGenerator).viewGrid(_seenAt);
    }
  }

  function transmute(uint256 _tokenId, uint16 _newTheme) external onlyTokenOwner(_tokenId) {
    TokenDetails memory proposedTokenDetails = tokens[_tokenId];
    proposedTokenDetails.theme = _newTheme;
    require(ITheme(themes[_newTheme]).canUseTheme(
      _tokenId,
      tokens[_tokenId],
      proposedTokenDetails
    ), "CAN'T USE THEME");
    tokens[_tokenId] = proposedTokenDetails;
  }

  function viewGrid() public view returns (Grid memory) {
    return IGridGenerator(gridGenerator).viewGrid(block.number);
  }
}