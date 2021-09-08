// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC721.sol";


contract MarsColony is ERC721 {
  mapping (address => uint256[]) private _tokens;
  mapping (uint256 => uint256) private _tokenPositionsPlusOne;
  uint256[] private _allMintedTokens;

  address payable constant DAO = payable(0x97438E7A978A91dC281B834B62bb5737f629Aca9);
  uint constant PRICE = 0.001 ether;

  function tokensOf(address owner) public view virtual returns (uint256[] memory) {
    require(owner != address(0), "ERC721: tokens query for the zero address");
    return _tokens[owner];
  }

  function allMintedTokens() public view virtual returns (uint256[] memory) {
    return _allMintedTokens;
  }

  constructor () ERC721("MarsColony", "MC") { }

  function _baseURI() internal view virtual override returns (string memory) {
    return 'https://meta.marscolony.io/';
  }

  function getBoundaries(uint256 _tokenId) public pure returns (string[2] memory) {
    require(_tokenId != 0, 'Token id must be over zero');
    require(_tokenId <= 21000, 'Maximum token id is 21000');
    string[40] memory LATITUDES = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
      '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
      '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
      '31', '32', '33', '34', '35', '36', '37', '38', '39', '40'
    ];
    uint256 lat = (_tokenId - 1) / 150;
    uint256 long = (_tokenId - 1) % 150;
    return [LATITUDES[lat], LATITUDES[lat]];
  }

  function buy(uint256 _tokenId) public payable {
    require(msg.value == MarsColony.PRICE, 'Token cost is 0.01 ether');
    require(_tokenId != 0, 'Token id must be over zero');
    require(_tokenId <= 21000, 'Maximum token id is 21000');
    _safeMint(msg.sender, _tokenId);
  }

  // function buy5x5(uint256 _centerTokenId) public payable {
  //   require(msg.value == 25 * MarsColony.PRICE, '25 tokens cost is 0.25 ether');
  //   for (uint8 dr = 2-2; dr <= 2+2; dr++) {
  //     for (uint8 dphi = 2-2; dphi <= 2+2; dphi++) {
  //       _safeMint(msg.sender, _centerTokenId + dr * 1000 + dphi - 2002);
  //     }
  //   }
  // }

  // anyone can call, but withdraw only to DAO
  function withdraw() public {
    (bool success, ) = DAO.call{ value: address(this).balance }('');
    require(success, 'Transfer failed.');
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    super._transfer(from, to, tokenId);
    delete _tokens[from][_tokenPositionsPlusOne[tokenId] - 1];
    _tokens[to].push(tokenId);
    _tokenPositionsPlusOne[tokenId] = _tokens[to].length;
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    super._mint(to, tokenId);
    _allMintedTokens.push(tokenId);
    _tokens[msg.sender].push(tokenId);
    _tokenPositionsPlusOne[tokenId] = _tokens[msg.sender].length;
    // ^^^ here we store position of token in an array _tokens[msg.sender] to delete it later with less gas
  }
}