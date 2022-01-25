//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {IOKPCParts} from './interfaces/IOKPCParts.sol';

contract OKPCParts is IOKPCParts {
  // parts
  Color[6] public colors;
  Vector[8] public headbands;
  Vector[8] public speakers;
  bytes4[128] public words;

  uint256 public constant NUM_COLORS = 6;
  uint256 public constant NUM_SPEAKERS = 8;
  uint256 public constant NUM_HEADBANDS = 8;
  uint256 public constant NUM_WORDS = 128;

  constructor() {
    _initColors();
    _initHeadbands();
    _initSpeakers();
    _initWords();
  }

  function getColor(uint256 index) public view override returns (Color memory) {
    if (index > NUM_COLORS - 1) revert IndexOutOfBounds(index, NUM_COLORS - 1);
    return colors[index];
  }

  function getHeadband(uint256 index)
    public
    view
    override
    returns (Vector memory)
  {
    if (index > NUM_HEADBANDS - 1)
      revert IndexOutOfBounds(index, NUM_HEADBANDS - 1);
    return headbands[index];
  }

  function getSpeaker(uint256 index)
    public
    view
    override
    returns (Vector memory)
  {
    if (index > NUM_SPEAKERS - 1)
      revert IndexOutOfBounds(index, NUM_SPEAKERS - 1);
    return speakers[index];
  }

  function getWord(uint256 index) public view override returns (string memory) {
    if (index > NUM_WORDS - 1) revert IndexOutOfBounds(index, NUM_WORDS - 1);
    return _toString(words[index]);
  }

  function _initColors() internal {
    // gray
    colors[0] = Color(
      bytes6('CCCCCC'),
      bytes6('838383'),
      bytes6('4D4D4D'),
      'Gray'
    );
    // green
    colors[1] = Color(
      bytes6('54F8B5'),
      bytes6('00DC82'),
      bytes6('037245'),
      'Green'
    );
    // blue
    colors[2] = Color(
      bytes6('80B3FF'),
      bytes6('2E82FF'),
      bytes6('003D99'),
      'Blue'
    );
    // purple
    colors[3] = Color(
      bytes6('DF99FF'),
      bytes6('C13CFF'),
      bytes6('750DA5'),
      'Purple'
    );
    // yellow
    colors[4] = Color(
      bytes6('FBDA9D'),
      bytes6('F8B73E'),
      bytes6('795106'),
      'Yellow'
    );
    // pink
    colors[5] = Color(
      bytes6('FF99D8'),
      bytes6('FF44B7'),
      bytes6('99005E'),
      'Pink'
    );
  }

  function _initHeadbands() internal {
    headbands[0] = Vector(
      'M2 3H1V0H2V2H4V3H2ZM3 0H5H6V3H5V1H3V0ZM11 0H9V1H11V3H12V0H11ZM14 0H13V3H14H16H17V0H16V2H14V0ZM19 0H21V1H19V3H18V0H19ZM27 0H25H24V3H25V1H27V0ZM20 3V2H22V0H23V3H22H20ZM26 2V3H28H29V0H28V2H26ZM8 3H10V2H8V0H7V3H8Z',
      '0'
    );
    headbands[1] = Vector(
      'M11 1H12V0H11V1ZM11 2H10V1H11V2ZM13 2H11V3H13V2ZM14 1H13V2H14V1ZM16 1V0H14V1H16ZM17 2H16V1H17V2ZM19 2V3H17V2H19ZM19 1H20V2H19V1ZM19 1V0H18V1H19ZM0 1H1V2H0V1ZM1 2H2V3H1V2ZM3 1V0H1V1H3ZM4 2V1H3V2H4ZM5 2H4V3H5V2ZM6 1H5V2H6V1ZM8 1V0H6V1H8ZM8 2H9V1H8V2ZM8 2H7V3H8V2ZM24 1H25V2H24V1ZM22 1V0H24V1H22ZM22 2H21V1H22V2ZM22 2H23V3H22V2ZM26 2V3H25V2H26ZM27 1V2H26V1H27ZM29 1H27V0H29V1ZM29 2V1H30V2H29ZM29 2V3H28V2H29Z',
      '1'
    );
    headbands[2] = Vector(
      'M3 0H1V1H3V2H1V3H3V2H4V3H6V2H4V1H6V0H4V1H3V0ZM27 0H29V1H27V0ZM27 2V1H26V0H24V1H26V2H24V3H26V2H27ZM27 2H29V3H27V2ZM10 0H12V1H10V0ZM10 2V1H9V0H7V1H9V2H7V3H9V2H10ZM10 2H12V3H10V2ZM18 0H20V1H18V0ZM21 1H20V2H18V3H20V2H21V3H23V2H21V1ZM21 1V0H23V1H21ZM16 0H15V1H14V3H15V2H16V0Z',
      '2'
    );
    headbands[3] = Vector(
      'M1 3H2H3V2H2V1H4V3H5H7H8V1H10V3H11H14V2V1H16V2V3H19H20V1H22V3H23H25H26V1H28V2H27V3H28H29V0H28H26H25V2H23V0H22H20H19V2H17V1H18V0H12V1H13V2H11V0H10H8H7V2H5V0H4H2H1V3Z',
      '3'
    );
    headbands[4] = Vector(
      'M2 1H1V0H2V1ZM2 2V1H3V2H2ZM2 2V3H1V2H2ZM28 1H29V0H28V1ZM28 2V1H27V2H28ZM28 2H29V3H28V2ZM4 1H5V2H4V3H5V2H6V1H5V0H4V1ZM25 1H26V0H25V1ZM25 2V1H24V2H25ZM25 2H26V3H25V2ZM7 1H8V2H7V3H8V2H9V1H8V0H7V1ZM22 1H23V0H22V1ZM22 2V1H21V2H22ZM22 2H23V3H22V2ZM10 1H11V2H10V3H11V2H12V1H11V0H10V1ZM16 1H14V0H16V1ZM16 2V1H17V2H16ZM14 2H16V3H14V2ZM14 2V1H13V2H14ZM19 1H20V0H19V1ZM19 2V1H18V2H19ZM19 2H20V3H19V2Z',
      '4'
    );
    headbands[5] = Vector(
      'M1 1H10V0H1V1ZM12 1H13V2H14V3H16V2H17V1H18V0H16V1V2H14V1V0H12V1ZM11 3H1V2H11V3ZM29 1H20V0H29V1ZM19 3H29V2H19V3Z',
      '5'
    );
    headbands[6] = Vector(
      'M2 1H3V2H2V1ZM2 1H1V2H2V3H3V2H4V1H3V0H2V1ZM6 1H7V2H6V1ZM6 1H5V2H6V3H7V2H8V1H7V0H6V1ZM11 1H10V0H11V1ZM11 2V1H12V2H11ZM10 2H11V3H10V2ZM10 2V1H9V2H10ZM28 1H27V0H28V1ZM28 2V1H29V2H28ZM27 2H28V3H27V2ZM27 2V1H26V2H27ZM24 1H23V0H24V1ZM24 2V1H25V2H24ZM23 2H24V3H23V2ZM23 2V1H22V2H23ZM20 1H19V0H20V1ZM20 2V1H21V2H20ZM19 2H20V3H19V2ZM19 2V1H18V2H19ZM16 2H14V1H16V2ZM16 2V3H17V2H16ZM16 1V0H17V1H16ZM14 1H13V0H14V1ZM14 2V3H13V2H14Z',
      '6'
    );
    headbands[7] = Vector(
      'M10 0H14V1H13V2H17V1H16V0H20V1H18V2H19V3H11V2H12V1H10V0ZM3 2H5V3H1V2H2V1H1V0H9V1H8V2H10V3H6V2H7V1H3V2ZM25 2H27V1H23V2H24V3H20V2H22V1H21V0H29V1H28V2H29V3H25V2Z',
      '7'
    );
  }

  function _initSpeakers() internal {
    speakers[0] = Vector(
      'M1 1H0V2H1V3H2V2H1V1ZM1 5H0V6H1V7H2V6H1V5ZM0 9H1V10H0V9ZM1 10H2V11H1V10ZM1 13H0V14H1V15H2V14H1V13Z',
      '0'
    );
    speakers[1] = Vector(
      'M1 1L1 0H0V1H1ZM1 2H2V1H1V2ZM1 2H0V3H1V2ZM1 10L1 11H0V10H1ZM1 9H2V10H1L1 9ZM1 9H0V8H1L1 9ZM1 4L1 5H0V6H1L1 7H2L2 6H1L1 5H2L2 4H1ZM1 13L1 12H2L2 13H1ZM1 14L1 13H0V14H1ZM1 14H2L2 15H1L1 14Z',
      '1'
    );
    speakers[2] = Vector(
      'M0 2H1V3H2L2 1H1L1 0H0V2ZM1 5H2L2 7H1V6H0V4H1L1 5ZM2 14H1L1 15H0V13H1V12H2L2 14ZM2 10L2 8H1V9H0V11H1L1 10H2Z',
      '2'
    );
    speakers[3] = Vector(
      'M1 1L1 0H0V1H1ZM1 1H2V2V3H1H0V2H1V1ZM1 5L1 4H2V5H1ZM1 5L1 6H2V7H1H0V6V5H1ZM1 13H0V12H1H2V13V14H1L1 13ZM1 14L1 15H0V14H1ZM2 9V8H1H0V9V10H1V11H2V10H1V9H2Z',
      '3'
    );
    speakers[4] = Vector(
      'M2 0H1V1H0V2H1V3H2V0ZM2 5H1V4H0V7H1V6H2V5ZM2 9H1V8H0V11H1V10H2V9ZM0 13H1V12H2V15H1V14H0V13Z',
      '4'
    );
    speakers[5] = Vector(
      'M2 0V1V2V3H0V2H1V1V0H2ZM0 4V5V6V7H2V6H1L1 5H2V4H0ZM2 10V11H0V10H1V9H0V8H2V9V10ZM0 12V13H1V14V15H2V14L2 13V12H0Z',
      '5'
    );
    speakers[6] = Vector(
      'M0 0V1L2 1V0H0ZM1 3V2H2V3H1ZM2 5V4H0V5H2ZM1 11V10H2V11H1ZM2 13V12H0V13H2ZM2 15V14H1V15H2ZM2 7V6H1V7H2ZM0 8V9H2V8H0Z',
      '6'
    );
    speakers[7] = Vector(
      'M2 1V2V3H0V2L1 2V1H2ZM1 11V10H0V9H2L2 10V11H1ZM2 14V13H0V14H1V15H2V14ZM1 5V6H0V7H2L2 6V5H1Z',
      '7'
    );
  }

  function _initWords() internal {
    words[0] = bytes4('WAIT');
    words[1] = bytes4('OK');
    words[2] = bytes4('INFO');
    words[3] = bytes4('HELP');
    words[4] = bytes4('WARN');
    words[5] = bytes4('ERR');
    words[6] = bytes4('BAD');
    words[7] = bytes4('OKPC');
    words[8] = bytes4('RARE');
    words[9] = bytes4('200%');
    words[10] = bytes4('GATO');
    words[11] = bytes4('MAGE');
    words[12] = bytes4('OOF');
    words[13] = bytes4('FUN');
    words[14] = bytes4('OKPC');
    words[15] = bytes4('POLY');
    words[16] = bytes4('FANG');
    words[17] = bytes4('PAIN');
    words[18] = bytes4('BOOT');
    words[19] = bytes4('DRAW');
    words[20] = bytes4('MINT');
    words[21] = bytes4('WORM');
    words[22] = bytes4('OKPC');
    words[23] = bytes4('OKPC');
    words[24] = bytes4('OKPC');
    words[25] = bytes4('OKPC');
    words[26] = bytes4('BEAT');
    words[27] = bytes4('MIDI');
    words[28] = bytes4('UP');
    words[29] = bytes4('HUSH');
    words[30] = bytes4('ACK');
    words[31] = bytes4('MOON');
    words[32] = bytes4('OKPC');
    words[33] = bytes4('UFO');
    words[34] = bytes4('SEE');
    words[35] = bytes4('WHAT');
    words[36] = bytes4('TRIP');
    words[37] = bytes4('NICE');
    words[38] = bytes4('YUP');
    words[39] = bytes4('SEEN');
    words[40] = bytes4('CUTE');
    words[41] = bytes4('OHNO');
    words[42] = bytes4('GROW');
    words[43] = bytes4('SKY');
    words[44] = bytes4('OPEN');
    words[45] = bytes4('OKPC');
    words[46] = bytes4('OKPC');
    words[47] = bytes4('ESC');
    words[48] = bytes4('404');
    words[49] = bytes4('PSA');
    words[50] = bytes4('BGS');
    words[51] = bytes4('OKPC');
    words[52] = bytes4('OKPC');
    words[53] = bytes4('DEAD');
    words[54] = bytes4('SK8');
    words[55] = bytes4('OKPC');
    words[56] = bytes4('CT');
    words[57] = bytes4('3310');
    words[58] = bytes4('DAO');
    words[59] = bytes4('BRAP');
    words[60] = bytes4('OKPC');
    words[61] = bytes4('OKPC');
    words[62] = bytes4('LVL');
    words[63] = bytes4('GFX');
    words[64] = bytes4('5000');
    words[65] = bytes4('OKPC');
    words[66] = bytes4('OKPC');
    words[67] = bytes4('SWRD');
    words[68] = bytes4('MEME');
    words[69] = bytes4('OKPC');
    words[70] = bytes4('OKPC');
    words[71] = bytes4('LIFE');
    words[72] = bytes4('OKPC');
    words[73] = bytes4('OKPC');
    words[74] = bytes4('OKPC');
    words[75] = bytes4('OKPC');
    words[76] = bytes4('ROSE');
    words[77] = bytes4('ROBE');
    words[78] = bytes4('OKOK');
    words[79] = bytes4('MEOW');
    words[80] = bytes4('KING');
    words[81] = bytes4('WISE');
    words[82] = bytes4('ROZE');
    words[83] = bytes4('NOBU');
    words[84] = bytes4('OKPC');
    words[85] = bytes4('OKPC');
    words[86] = bytes4('OKPC');
    words[87] = bytes4('OKPC');
    words[88] = bytes4('SWIM');
    words[89] = bytes4('OKPC');
    words[90] = bytes4('OKPC');
    words[91] = bytes4('YUM');
    words[92] = bytes4('SNAP');
    words[93] = bytes4('SAND');
    words[94] = bytes4('FISH');
    words[95] = bytes4('CITY');
    words[96] = bytes4('VIBE');
    words[97] = bytes4('MAKE');
    words[98] = bytes4('OKPC');
    words[99] = bytes4('OKPC');
    words[100] = bytes4('OKPC');
    words[101] = bytes4('OKPC');
    words[102] = bytes4('OKPC');
    words[103] = bytes4('OKPC');
    words[104] = bytes4('OKPC');
    words[105] = bytes4('OKPC');
    words[106] = bytes4('OKPC');
    words[107] = bytes4('OKPC');
    words[108] = bytes4('LOUD');
    words[109] = bytes4('RISE');
    words[110] = bytes4('LOVE');
    words[111] = bytes4('OKPC');
    words[112] = bytes4('OKPC');
    words[113] = bytes4('OKPC');
    words[114] = bytes4('REKT');
    words[115] = bytes4('BEAR');
    words[116] = bytes4('CODA');
    words[117] = bytes4('OKPC');
    words[118] = bytes4('OKPC');
    words[119] = bytes4('FLY');
    words[120] = bytes4('ZKP');
    words[121] = bytes4('OKPC');
    words[122] = bytes4('OKPC');
    words[123] = bytes4('OKPC');
    words[124] = bytes4('OKPC');
    words[125] = bytes4('OKPC');
    words[126] = bytes4('OKPC');
    words[127] = bytes4('OKPC');
  }

  function _toString(bytes4 b) private pure returns (string memory) {
    uint256 numChars = 0;

    for (uint256 i = 0; i < 4; i++) {
      if (b[i] == bytes1(0)) break;
      numChars++;
    }

    bytes memory result = new bytes(numChars);
    for (uint256 i = 0; i < numChars; i++) result[i] = b[i];

    return string(abi.encodePacked(result));
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// TODO: rename from parts to something else?
interface IOKPCParts {
  // errors
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  // structures
  struct Color {
    bytes6 light;
    bytes6 regular;
    bytes6 dark;
    string name;
  }

  struct Vector {
    string data;
    string name;
  }

  // functions
  function getColor(uint256 index) external view returns (Color memory);

  function getHeadband(uint256 index) external view returns (Vector memory);

  function getSpeaker(uint256 index) external view returns (Vector memory);

  // TODO: rename from word to something else? The name of the OKPC?
  function getWord(uint256 index) external view returns (string memory);
}