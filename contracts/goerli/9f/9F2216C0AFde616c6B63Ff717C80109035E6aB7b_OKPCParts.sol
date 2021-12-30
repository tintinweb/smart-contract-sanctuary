//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCParts {
  struct Color {
    bytes8 light;
    bytes8 regular;
    bytes8 dark;
  }

  struct Parts {
    string hat;
    string borderLeft;
    string borderRight;
    Color color;
    bytes4 word;
  }

  error InvalidCharacter();
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  function getChar(string memory char) external view returns (string memory);

  function getColor(uint256 index) external view returns (Color memory);

  function getHat(uint256 index) external view returns (string memory);

  function getBorder(uint256 index) external view returns (string memory);

  function getWord(uint256 index) external view returns (bytes4);

  function getParts(uint256 tokenId) external view returns (Parts memory);
}

contract OKPCParts is IOKPCParts {
  // font
  mapping(string => string) public alphanum;

  // parts
  mapping(uint256 => Color) public colors;
  mapping(uint256 => string) public hats;
  mapping(uint256 => string) public borders;
  mapping(uint256 => bytes4) public words;

  uint256 public numColors;
  uint256 public numHats;
  uint256 public numBorders;
  uint256 public numWords;

  constructor() {
    _initAlphanum();
    _initColors();
    _initHats();
    _initBorders();
    _initWords();
  }

  function getChar(string memory char)
    public
    view
    override
    returns (string memory)
  {
    require(bytes(char).length == 1, 'input is not a single char');
    require(bytes(alphanum[char]).length != 0, 'char not found');
    return alphanum[char];
  }

  function getColor(uint256 index) public view override returns (Color memory) {
    if (index > numColors - 1) revert IndexOutOfBounds(index, numColors - 1);
    return colors[index];
  }

  function getHat(uint256 index) public view override returns (string memory) {
    if (index > numHats - 1) revert IndexOutOfBounds(index, numHats - 1);
    return hats[index];
  }

  function getBorder(uint256 index)
    public
    view
    override
    returns (string memory)
  {
    if (index > numBorders - 1) revert IndexOutOfBounds(index, numBorders - 1);
    return borders[index];
  }

  function getWord(uint256 index) public view override returns (bytes4) {
    if (index > numWords - 1) revert IndexOutOfBounds(index, numWords - 1);
    return words[index];
  }

  function getParts(uint256 tokenId)
    public
    view
    override
    returns (Parts memory)
  {
    Parts memory parts;

    parts.hat = getHat((tokenId + 1) % numHats);
    parts.borderLeft = getBorder((tokenId + 2) % numBorders);
    parts.borderRight = getBorder((tokenId + 2) % numBorders);
    parts.color = getColor((tokenId) % numColors);
    parts.word = getWord((tokenId + 4) % numWords);

    return parts;
  }

  function _initAlphanum() internal {
    alphanum['a'] = 'M2 0H1V1H0V2V3H1V2H2V3H3V2V1H2V0Z';
    alphanum['b'] = 'M2 0V1H3V2V3H2H1H0V2V1V0H1H2Z';
    alphanum['c'] = 'M2 1H1V2H2H3V3H2H1H0V2V1V0H1H2H3V1H2Z';
    alphanum['d'] = 'M2 1H1V2H2V3H1H0V2V1V0H1H2V1ZM2 1V2H3V1H2Z';
    alphanum['e'] = 'M1 0H2H3V1H2V2H3V3H2H1H0V2V1V0H1Z';
    alphanum['f'] = 'M1 0H2H3V1H2V2H1V3H0V2V1V0H1Z';
    alphanum['g'] = 'M2 1H1V2H2V1ZM3 2V1H2V0H1H0V1V2V3H1H2H3V2Z';
    alphanum['h'] = 'M3 0V1V2V3H2V2H1V3H0V2V1V0H1V1H2V0H3Z';
    alphanum['i'] = 'M3 1H2V2H3V3H2H1H0V2H1V1H0V0H1H2H3V1Z';
    alphanum['j'] = 'M3 0V1V2V3H2H1H0V2V1H1V2H2V1V0H3Z';
    alphanum['k'] = 'M1 0V1H2V2H1V3H0V2V1V0H1ZM2 2V3H3V2H2ZM2 1V0H3V1H2Z';
    alphanum['l'] = 'M1 0V1V2H2H3V3H2H1H0V2V1V0H1Z';
    alphanum['m'] = 'M0 0H1H2H3V1V2V3H2V2H1V3H0V2V1V0Z';
    alphanum['n'] = 'M0 0H1H2H3V1V2V3H2V2V1H1V2V3H0V2V1V0Z';
    alphanum['o'] = 'M0 0H1H2H3V1V2V3H2H1H0V2V1V0ZM1 1V2H2V1H1Z';
    alphanum['p'] = 'M0 0H1H2H3V1V2H2H1V3H0V2V1V0Z';
    alphanum['q'] = 'M0 0H1H2H3V1V2V3H2V2H1H0V1V0Z';
    alphanum['r'] = 'M0 0H1H2H3V1H2H1V2V3H0V2V1V0Z';
    alphanum['s'] = 'M3 1H2V2V3H1H0V2H1V1V0H2H3V1Z';
    alphanum['t'] = 'M1 0H2H3V1H2V2V3H1V2V1H0V0H1Z';
    alphanum['u'] = 'M1 0V1V2H2V1V0H3V1V2V3H2H1H0V2V1V0H1Z';
    alphanum['v'] = 'M1 0V1V2H0V1V0H1ZM2 2H1V3H2V2ZM2 2V1V0H3V1V2H2Z';
    alphanum['w'] = 'M1 0V1H2V0H3V1V2V3H2H1H0V2V1V0H1Z';
    alphanum['x'] = 'M1 1H0V0H1V1ZM2 1H1V2H0V3H1V2H2V3H3V2H2V1ZM2 1V0H3V1H2Z';
    alphanum['y'] = 'M1 1H0V0H1V1ZM2 1H1V2V3H2V2V1ZM2 1V0H3V1H2Z';
    alphanum['z'] = 'M1 1H0V0H1H2V1V2H3V3H2H1V2V1Z';
    alphanum['1'] = 'M1 1H0V0H1H2V1V2H3V3H2H1H0V2H1V1Z';
    alphanum['2'] = 'M1 1H0V0H1H2V1V2H3V3H2H1V2V1Z';
    alphanum['3'] = 'M1 1H0V0H1H2H3V1V2V3H2H1H0V2H1V1Z';
    alphanum['4'] = 'M1 0V1H2V0H3V1V2V3H2V2H1H0V1V0H1Z';
    alphanum['5'] = 'M3 1H2V2V3H1H0V2H1V1V0H2H3V1Z';
    alphanum['6'] = 'M1 0V1H2H3V2V3H2H1H0V2V1V0H1Z';
    alphanum['7'] = 'M1 1H0V0H1H2H3V1V2V3H2V2V1H1Z';
    alphanum['8'] = 'M3 0V1V2V3H2H1H0V2V1H1V0H2H3Z';
    alphanum['9'] = 'M0 0H1H2H3V1V2V3H2V2H1H0V1V0Z';
    alphanum['0'] = 'M0 0H1H2H3V1V2V3H2H1H0V2V1V0ZM1 1V2H2V1H1Z';
  }

  function _initColors() internal {
    // gray
    colors[0] = Color(
      bytes8('CCCCCCFF'),
      bytes8('838383FF'),
      bytes8('4D4D4DFF')
    );
    // green
    colors[1] = Color(
      bytes8('54F8B5FF'),
      bytes8('00DC82FF'),
      bytes8('037245FF')
    );
    // blue
    colors[2] = Color(
      bytes8('80B3FFFF'),
      bytes8('2E82FFFF'),
      bytes8('003D99FF')
    );
    // purple
    colors[3] = Color(
      bytes8('DF99FFFF'),
      bytes8('C13CFFFF'),
      bytes8('750DA5FF')
    );
    // orange
    colors[4] = Color(
      bytes8('FBDA9DFF'),
      bytes8('F8B73EFF'),
      bytes8('795106FF')
    );
    // pink
    colors[5] = Color(
      bytes8('FF99D8FF'),
      bytes8('FF44B7FF'),
      bytes8('99005EFF')
    );
    numColors = 6;
  }

  function _initHats() internal {
    // prettier-ignore
    hats[0] = 'M2 3H1V0H2V2H4V3H2ZM3 0H5H6V3H5V1H3V0ZM11 0H9V1H11V3H12V0H11ZM14 0H13V3H14H16H17V0H16V2H14V0ZM19 0H21V1H19V3H18V0H19ZM27 0H25H24V3H25V1H27V0ZM20 3V2H22V0H23V3H22H20ZM26 2V3H28H29V0H28V2H26ZM8 3H10V2H8V0H7V3H8Z';
    // prettier-ignore
    hats[1] = 'M11 1H12V0H11V1ZM11 2H10V1H11V2ZM13 2H11V3H13V2ZM14 1H13V2H14V1ZM16 1V0H14V1H16ZM17 2H16V1H17V2ZM19 2V3H17V2H19ZM19 1H20V2H19V1ZM19 1V0H18V1H19ZM0 1H1V2H0V1ZM1 2H2V3H1V2ZM3 1V0H1V1H3ZM4 2V1H3V2H4ZM5 2H4V3H5V2ZM6 1H5V2H6V1ZM8 1V0H6V1H8ZM8 2H9V1H8V2ZM8 2H7V3H8V2ZM24 1H25V2H24V1ZM22 1V0H24V1H22ZM22 2H21V1H22V2ZM22 2H23V3H22V2ZM26 2V3H25V2H26ZM27 1V2H26V1H27ZM29 1H27V0H29V1ZM29 2V1H30V2H29ZM29 2V3H28V2H29Z';
    // prettier-ignore
    hats[2] = 'M3 0H1V1H3V2H1V3H3V2H4V3H6V2H4V1H6V0H4V1H3V0ZM27 0H29V1H27V0ZM27 2V1H26V0H24V1H26V2H24V3H26V2H27ZM27 2H29V3H27V2ZM10 0H12V1H10V0ZM10 2V1H9V0H7V1H9V2H7V3H9V2H10ZM10 2H12V3H10V2ZM18 0H20V1H18V0ZM21 1H20V2H18V3H20V2H21V3H23V2H21V1ZM21 1V0H23V1H21ZM16 0H15V1H14V3H15V2H16V0Z';
    // prettier-ignore
    hats[3] = 'M1 3H2H3V2H2V1H4V3H5H7H8V1H10V3H11H14V2V1H16V2V3H19H20V1H22V3H23H25H26V1H28V2H27V3H28H29V0H28H26H25V2H23V0H22H20H19V2H17V1H18V0H12V1H13V2H11V0H10H8H7V2H5V0H4H2H1V3Z';
    // prettier-ignore
    hats[4] = 'M2 1H1V0H2V1ZM2 2V1H3V2H2ZM2 2V3H1V2H2ZM28 1H29V0H28V1ZM28 2V1H27V2H28ZM28 2H29V3H28V2ZM4 1H5V2H4V3H5V2H6V1H5V0H4V1ZM25 1H26V0H25V1ZM25 2V1H24V2H25ZM25 2H26V3H25V2ZM7 1H8V2H7V3H8V2H9V1H8V0H7V1ZM22 1H23V0H22V1ZM22 2V1H21V2H22ZM22 2H23V3H22V2ZM10 1H11V2H10V3H11V2H12V1H11V0H10V1ZM16 1H14V0H16V1ZM16 2V1H17V2H16ZM14 2H16V3H14V2ZM14 2V1H13V2H14ZM19 1H20V0H19V1ZM19 2V1H18V2H19ZM19 2H20V3H19V2Z';
    // prettier-ignore
    hats[5] = 'M1 1H10V0H1V1ZM12 1H13V2H14V3H16V2H17V1H18V0H16V1V2H14V1V0H12V1ZM11 3H1V2H11V3ZM29 1H20V0H29V1ZM19 3H29V2H19V3Z';
    // prettier-ignore
    hats[6] = 'M2 1H3V2H2V1ZM2 1H1V2H2V3H3V2H4V1H3V0H2V1ZM6 1H7V2H6V1ZM6 1H5V2H6V3H7V2H8V1H7V0H6V1ZM11 1H10V0H11V1ZM11 2V1H12V2H11ZM10 2H11V3H10V2ZM10 2V1H9V2H10ZM28 1H27V0H28V1ZM28 2V1H29V2H28ZM27 2H28V3H27V2ZM27 2V1H26V2H27ZM24 1H23V0H24V1ZM24 2V1H25V2H24ZM23 2H24V3H23V2ZM23 2V1H22V2H23ZM20 1H19V0H20V1ZM20 2V1H21V2H20ZM19 2H20V3H19V2ZM19 2V1H18V2H19ZM16 2H14V1H16V2ZM16 2V3H17V2H16ZM16 1V0H17V1H16ZM14 1H13V0H14V1ZM14 2V3H13V2H14Z';
    // prettier-ignore
    hats[7] = 'M10 0H14V1H13V2H17V1H16V0H20V1H18V2H19V3H11V2H12V1H10V0ZM3 2H5V3H1V2H2V1H1V0H9V1H8V2H10V3H6V2H7V1H3V2ZM25 2H27V1H23V2H24V3H20V2H22V1H21V0H29V1H28V2H29V3H25V2Z';
    numHats = 8;
  }

  function _initBorders() internal {
    // prettier-ignore
    borders[0] = 'M1 1H0V2H1V3H2V2H1V1ZM1 5H0V6H1V7H2V6H1V5ZM0 9H1V10H0V9ZM1 10H2V11H1V10ZM1 13H0V14H1V15H2V14H1V13Z';
    // prettier-ignore
    borders[1] = 'M1 1L1 0H0V1H1ZM1 2H2V1H1V2ZM1 2H0V3H1V2ZM1 10L1 11H0V10H1ZM1 9H2V10H1L1 9ZM1 9H0V8H1L1 9ZM1 4L1 5H0V6H1L1 7H2L2 6H1L1 5H2L2 4H1ZM1 13L1 12H2L2 13H1ZM1 14L1 13H0V14H1ZM1 14H2L2 15H1L1 14Z';
    // prettier-ignore
    borders[2] = 'M0 2H1V3H2L2 1H1L1 0H0V2ZM1 5H2L2 7H1V6H0V4H1L1 5ZM2 14H1L1 15H0V13H1V12H2L2 14ZM2 10L2 8H1V9H0V11H1L1 10H2Z';
    // prettier-ignore
    borders[3] = 'M1 1L1 0H0V1H1ZM1 1H2V2V3H1H0V2H1V1ZM1 5L1 4H2V5H1ZM1 5L1 6H2V7H1H0V6V5H1ZM1 13H0V12H1H2V13V14H1L1 13ZM1 14L1 15H0V14H1ZM2 9V8H1H0V9V10H1V11H2V10H1V9H2Z';
    // prettier-ignore
    borders[4] = 'M2 0H1V1H0V2H1V3H2V0ZM2 5H1V4H0V7H1V6H2V5ZM2 9H1V8H0V11H1V10H2V9ZM0 13H1V12H2V15H1V14H0V13Z';
    // prettier-ignore
    borders[5] = 'M2 0V1V2V3H0V2H1V1V0H2ZM0 4V5V6V7H2V6H1L1 5H2V4H0ZM2 10V11H0V10H1V9H0V8H2V9V10ZM0 12V13H1V14V15H2V14L2 13V12H0Z';
    // prettier-ignore
    borders[6] = 'M0 0V1L2 1V0H0ZM1 3V2H2V3H1ZM2 5V4H0V5H2ZM1 11V10H2V11H1ZM2 13V12H0V13H2ZM2 15V14H1V15H2ZM2 7V6H1V7H2ZM0 8V9H2V8H0Z';
    // prettier-ignore
    borders[7] = 'M2 1V2V3H0V2L1 2V1H2ZM1 11V10H0V9H2L2 10V11H1ZM2 14V13H0V14H1V15H2V14ZM1 5V6H0V7H2L2 6V5H1Z';
    numBorders = 8;
  }

  function _initWords() internal {
    words[0] = bytes4('0x00');
    words[1] = bytes4('1155');
    words[2] = bytes4('2021');
    words[3] = bytes4('404');
    words[4] = bytes4('4096');
    words[5] = bytes4('420');
    words[6] = bytes4('721');
    words[7] = bytes4('acab');
    words[8] = bytes4('art');
    words[9] = bytes4('bear');
    words[10] = bytes4('blit');
    words[11] = bytes4('boop');
    words[12] = bytes4('bots');
    words[13] = bytes4('bugs');
    words[14] = bytes4('bull');
    words[15] = bytes4('cc0');
    words[16] = bytes4('coin');
    words[17] = bytes4('dame');
    words[18] = bytes4('dao');
    words[19] = bytes4('dead');
    words[20] = bytes4('def');
    words[21] = bytes4('df');
    words[22] = bytes4('dom');
    words[23] = bytes4('draw');
    words[24] = bytes4('ens');
    words[25] = bytes4('eth');
    words[26] = bytes4('evm');
    words[27] = bytes4('felt');
    words[28] = bytes4('flip');
    words[29] = bytes4('fun');
    words[30] = bytes4('game');
    words[31] = bytes4('gato');
    words[32] = bytes4('gawd');
    words[33] = bytes4('gfx');
    words[34] = bytes4('gm');
    words[35] = bytes4('hack');
    words[36] = bytes4('hash');
    words[37] = bytes4('help');
    words[38] = bytes4('hold');
    words[39] = bytes4('hype');
    words[40] = bytes4('info');
    words[41] = bytes4('jstn');
    words[42] = bytes4('loot');
    words[43] = bytes4('meme');
    words[44] = bytes4('mike');
    words[45] = bytes4('mood');
    words[46] = bytes4('moon');
    words[47] = bytes4('nft');
    words[48] = bytes4('ngmi');
    words[49] = bytes4('noun');
    words[50] = bytes4('ok');
    words[51] = bytes4('okpc');
    words[52] = bytes4('pfp');
    words[53] = bytes4('pill');
    words[54] = bytes4('pixl');
    words[55] = bytes4('play');
    words[56] = bytes4('prty');
    words[57] = bytes4('punk');
    words[58] = bytes4('rare');
    words[59] = bytes4('rug');
    words[60] = bytes4('sign');
    words[61] = bytes4('sup');
    words[62] = bytes4('swap');
    words[63] = bytes4('toad');
    words[64] = bytes4('tx');
    words[65] = bytes4('uni');
    words[66] = bytes4('vibe');
    words[67] = bytes4('vtlk');
    words[68] = bytes4('wait');
    words[69] = bytes4('warn');
    words[70] = bytes4('web3');
    words[71] = bytes4('wgmi');
    words[72] = bytes4('worm');
    words[73] = bytes4('xqst');
    numWords = 74;
  }
}