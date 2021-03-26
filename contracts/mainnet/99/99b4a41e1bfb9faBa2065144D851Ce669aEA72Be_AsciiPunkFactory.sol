// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AsciiPunkFactory {
  uint256 private constant TOP_COUNT = 55;
  uint256 private constant EYE_COUNT = 48;
  uint256 private constant NOSE_COUNT = 9;
  uint256 private constant MOUTH_COUNT = 32;

  function draw(uint256 seed) public pure returns (string memory) {
    uint256 rand = uint256(keccak256(abi.encodePacked(seed)));

    string memory top = _chooseTop(rand);
    string memory eyes = _chooseEyes(rand);
    string memory mouth = _chooseMouth(rand);

    string memory chin = unicode"   │    │   \n" unicode"   └──┘ │   \n";
    string memory neck = unicode"     │  │   \n" unicode"     │  │   \n";

    return string(abi.encodePacked(top, eyes, mouth, chin, neck));
  }

  function _chooseTop(uint256 rand) internal pure returns (string memory) {
    string[TOP_COUNT] memory tops =
      [
        unicode"   ┌───┐    \n"
        unicode"   │   ┼┐   \n"
        unicode"   ├────┼┼  \n",
        unicode"   ┌┬┬┬┬┐   \n"
        unicode"   ╓┬┬┬┬╖   \n"
        unicode"   ╙┴┴┴┴╜   \n",
        unicode"   ╒════╕   \n"
        unicode"  ┌┴────┴┐  \n"
        unicode"  └┬────┬┘  \n",
        unicode"   ╒════╕   \n"
        unicode"   │□□□□│   \n"
        unicode"  └┬────┬┘  \n",
        unicode"   ╒════╕   \n"
        unicode"   │    │   \n"
        unicode" └─┬────┬─┘ \n",
        unicode"    ◙◙◙◙    \n"
        unicode"   ▄████▄   \n"
        unicode"   ┌────┐   \n",
        unicode"   ┌───┐    \n"
        unicode"┌──┤   └┐   \n"
        unicode"└──┼────┤   \n",
        unicode"    ┌───┐   \n"
        unicode"   ┌┘   ├──┐\n"
        unicode"   ├────┼──┘\n",
        unicode"   ┌────┐/  \n"
        unicode"┌──┴────┴──┐\n"
        unicode"└──┬────┬──┘\n",
        unicode"   ╒════╕   \n"
        unicode" ┌─┴────┴─┐ \n"
        unicode" └─┬────┬─┘ \n",
        unicode"  ┌──────┐  \n"
        unicode"  │▲▲▲▲▲▲│  \n"
        unicode"  └┬────┬┘  \n",
        unicode"  ┌┌────┐┐  \n"
        unicode"  ││┌──┐││  \n"
        unicode"  └┼┴──┴┼┘  \n",
        unicode"   ┌────┐   \n"
        unicode"  ┌┘─   │   \n"
        unicode"  └┌────┐   \n",
        unicode"            \n"
        unicode"   ┌┬┬┬┬┐   \n"
        unicode"   ├┴┴┴┴┤   \n",
        unicode"            \n"
        unicode"    ╓┬╥┐    \n"
        unicode"   ┌╨┴╨┴┐   \n",
        unicode"            \n"
        unicode"   ╒╦╦╦╦╕   \n"
        unicode"   ╞╩╩╩╩╡   \n",
        unicode"            \n"
        unicode"            \n"
        unicode"   ┌┼┼┼┼┐   \n",
        unicode"            \n"
        unicode"    ││││    \n"
        unicode"   ┌┼┼┼┼┐   \n",
        unicode"      ╔     \n"
        unicode"     ╔║     \n"
        unicode"   ┌─╫╫─┐   \n",
        unicode"            \n"
        unicode"    ║║║║    \n"
        unicode"   ┌╨╨╨╨┐   \n",
        unicode"            \n"
        unicode"   ▐▐▐▌▌▌   \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"   \\/////   \n"
        unicode"   ┌────┐   \n",
        unicode"    ┐ ┌     \n"
        unicode"   ┐││││┌   \n"
        unicode"   ┌────┐   \n",
        unicode"  ┌┐ ┐┌┐┌┐  \n"
        unicode"  └└┐││┌┘   \n"
        unicode"   ┌┴┴┴┴┐   \n",
        unicode"  ┐┐┐┐┐     \n"
        unicode"  └└└└└┐    \n"
        unicode"   └└└└└┐   \n",
        unicode"            \n"
        unicode"   ││││││   \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"    ╓╓╓╓    \n"
        unicode"   ┌╨╨╨╨┐   \n",
        unicode"    ╔╔╗╗╗   \n"
        unicode"   ╔╔╔╗╗╗╗  \n"
        unicode"  ╔╝╝║ ╚╚╗  \n",
        unicode"   ╔╔╔╔╔╗   \n"
        unicode"  ╔╔╔╔╔╗║╗  \n"
        unicode"  ╝║╨╨╨╨║╚  \n",
        unicode"   ╔╔═╔═╔   \n"
        unicode"   ╔╩╔╩╔╝   \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"     ///    \n"
        unicode"   ┌────┐   \n",
        unicode"     ╔╗╔╗   \n"
        unicode"    ╔╗╔╗╝   \n"
        unicode"   ┌╔╝╔╝┐   \n",
        unicode"     ╔╔╔╔╝  \n"
        unicode"    ╔╝╔╝    \n"
        unicode"   ┌╨╨╨─┐   \n",
        unicode"       ╔╗   \n"
        unicode"    ╔╔╔╗╝   \n"
        unicode"   ┌╚╚╝╝┐   \n",
        unicode"   ╔════╗   \n"
        unicode"  ╔╚╚╚╝╝╝╗  \n"
        unicode"  ╟┌────┐╢  \n",
        unicode"    ╔═╗     \n"
        unicode"    ╚╚╚╗    \n"
        unicode"   ┌────┐   \n",
        unicode"            \n"
        unicode"            \n"
        unicode"   ┌╨╨╨╨┐   \n",
        unicode"            \n"
        unicode"    ⌂⌂⌂⌂    \n"
        unicode"   ┌────┐   \n",
        unicode"   ┌────┐   \n"
        unicode"   │   /└┐  \n"
        unicode"   ├────┐/  \n",
        unicode"            \n"
        unicode"   ((((((   \n"
        unicode"   ┌────┐   \n",
        unicode"   ┌┌┌┌┌┐   \n"
        unicode"   ├┘┘┘┘┘   \n"
        unicode"   ┌────┐   \n",
        unicode"   «°┐      \n"
        unicode"    │╪╕     \n"
        unicode"   ┌└┼──┐   \n",
        unicode"  <° °>   § \n"
        unicode"   \\'/   /  \n"
        unicode"   {())}}   \n",
        unicode"   ██████   \n"
        unicode"  ██ ██ ██  \n"
        unicode" █ ██████ █ \n",
        unicode"    ████    \n"
        unicode"   ██◙◙██   \n"
        unicode"   ┌─▼▼─┐   \n",
        unicode"   ╓╖  ╓╖   \n"
        unicode"  °╜╚╗╔╝╙°  \n"
        unicode"   ┌─╨╨─┐   \n",
        unicode"   ± ±± ±   \n"
        unicode"   ◙◙◙◙◙◙   \n"
        unicode"   ┌────┐   \n",
        unicode"  ♫     ♪   \n"
        unicode"    ♪     ♫ \n"
        unicode" ♪ ┌────┐   \n",
        unicode"    /≡≡\\    \n"
        unicode"   /≡≡≡≡\\   \n"
        unicode"  /┌────┐\\  \n",
        unicode"            \n"
        unicode"   ♣♥♦♠♣♥   \n"
        unicode"   ┌────┐   \n",
        unicode"     [⌂]    \n"
        unicode"      │     \n"
        unicode"   ┌────┐   \n",
        unicode"  /\\/\\/\\/\\  \n"
        unicode"  \\\\/\\/\\//  \n"
        unicode"   ┌────┐   \n",
        unicode"    ↑↑↓↓    \n"
        unicode"   ←→←→AB   \n"
        unicode"   ┌────┐   \n",
        unicode"    ┌─┬┐    \n"
        unicode"   ┌┘┌┘└┐   \n"
        unicode"   ├─┴──┤   \n",
        unicode"    ☼  ☼    \n"
        unicode"     \\/     \n"
        unicode"   ┌────┐   \n"
      ];
    uint256 topId = rand % TOP_COUNT;
    return tops[topId];
  }

  function _chooseEyes(uint256 rand) internal pure returns (string memory) {
    string[EYE_COUNT] memory leftEyes =
      [
        unicode"◕",
        unicode"*",
        unicode"♥",
        unicode"X",
        unicode"⊙",
        unicode"˘",
        unicode"α",
        unicode"◉",
        unicode"☻",
        unicode"¬",
        unicode"^",
        unicode"═",
        unicode"┼",
        unicode"┬",
        unicode"■",
        unicode"─",
        unicode"û",
        unicode"╜",
        unicode"δ",
        unicode"│",
        unicode"┐",
        unicode"┌",
        unicode"┌",
        unicode"╤",
        unicode"/",
        unicode"\\",
        unicode"/",
        unicode"\\",
        unicode"╦",
        unicode"♥",
        unicode"♠",
        unicode"♦",
        unicode"╝",
        unicode"◄",
        unicode"►",
        unicode"◄",
        unicode"►",
        unicode"I",
        unicode"╚",
        unicode"╔",
        unicode"╙",
        unicode"╜",
        unicode"╓",
        unicode"╥",
        unicode"$",
        unicode"○",
        unicode"N",
        unicode"x"
      ];

    string[EYE_COUNT] memory rightEyes =
      [
        unicode"◕",
        unicode"*",
        unicode"♥",
        unicode"X",
        unicode"⊙",
        unicode"˘",
        unicode"α",
        unicode"◉",
        unicode"☻",
        unicode"¬",
        unicode"^",
        unicode"═",
        unicode"┼",
        unicode"┬",
        unicode"■",
        unicode"─",
        unicode"û",
        unicode"╜",
        unicode"δ",
        unicode"│",
        unicode"┐",
        unicode"┐",
        unicode"┌",
        unicode"╤",
        unicode"\\",
        unicode"/",
        unicode"/",
        unicode"\\",
        unicode"╦",
        unicode"♠",
        unicode"♣",
        unicode"♦",
        unicode"╝",
        unicode"►",
        unicode"◄",
        unicode"◄",
        unicode"◄",
        unicode"I",
        unicode"╚",
        unicode"╗",
        unicode"╜",
        unicode"╜",
        unicode"╓",
        unicode"╥",
        unicode"$",
        unicode"○",
        unicode"N",
        unicode"x"
      ];
    uint256 eyeId = rand % EYE_COUNT;

    string memory leftEye = leftEyes[eyeId];
    string memory rightEye = rightEyes[eyeId];
    string memory nose = _chooseNose(rand);

    string memory forehead = unicode"   │    ├┐  \n";
    string memory leftFace = unicode"   │";
    string memory rightFace = unicode" └│  \n";

    return
      string(
        abi.encodePacked(
          forehead,
          leftFace,
          leftEye,
          " ",
          rightEye,
          rightFace,
          nose
        )
      );
  }

  function _chooseMouth(uint256 rand) internal pure returns (string memory) {
    string[MOUTH_COUNT] memory mouths =
      [
        unicode"   │    │   \n"
        unicode"   │──  │   \n",
        unicode"   │    │   \n"
        unicode"   │δ   │   \n",
        unicode"   │    │   \n"
        unicode"   │─┬  │   \n",
        unicode"   │    │   \n"
        unicode"   │(─) │   \n",
        unicode"   │    │   \n"
        unicode"   │[─] │   \n",
        unicode"   │    │   \n"
        unicode"   │<─> │   \n",
        unicode"   │    │   \n"
        unicode"   │╙─  │   \n",
        unicode"   │    │   \n"
        unicode"   │─╜  │   \n",
        unicode"   │    │   \n"
        unicode"   │└─┘ │   \n",
        unicode"   │    │   \n"
        unicode"   │┌─┐ │   \n",
        unicode"   │    │   \n"
        unicode"   │╓─  │   \n",
        unicode"   │    │   \n"
        unicode"   │─╖  │   \n",
        unicode"   │    │   \n"
        unicode"   │┼─┼ │   \n",
        unicode"   │    │   \n"
        unicode"   │──┼ │   \n",
        unicode"   │    │   \n"
        unicode"   │«─» │   \n",
        unicode"   │    │   \n"
        unicode"   │──  │   \n",
        unicode" ∙ │    │   \n"
        unicode" ∙───   │   \n",
        unicode" ∙ │    │   \n"
        unicode" ∙───)  │   \n",
        unicode" ∙ │    │   \n"
        unicode" ∙───]  │   \n",
        unicode"   │⌐¬  │   \n"
        unicode" √────  │   \n",
        unicode"   │╓╖  │   \n"
        unicode"   │──  │   \n",
        unicode"   │~~  │   \n"
        unicode"   │/\\  │   \n",
        unicode"   │    │   \n"
        unicode"   │══  │   \n",
        unicode"   │    │   \n"
        unicode"   │▼▼  │   \n",
        unicode"   │⌐¬  │   \n"
        unicode"   │O   │   \n",
        unicode"   │    │   \n"
        unicode"   │O   │   \n",
        unicode" ∙ │⌐¬  │   \n"
        unicode" ∙───   │   \n",
        unicode" ∙ │⌐¬  │   \n"
        unicode" ∙───)  │   \n",
        unicode" ∙ │⌐¬  │   \n"
        unicode" ∙───]  │   \n",
        unicode"   │⌐¬  │   \n"
        unicode"   │──  │   \n",
        unicode"   │⌐-¬ │   \n"
        unicode"   │    │   \n",
        unicode"   │┌-┐ │   \n"
        unicode"   ││ │ │   \n"
      ];

    uint256 mouthId = rand % MOUTH_COUNT;

    return mouths[mouthId];
  }

  function _chooseNose(uint256 rand) internal pure returns (string memory) {
    string[NOSE_COUNT] memory noses =
      [
        unicode"└",
        unicode"╘",
        unicode"<",
        unicode"└",
        unicode"┌",
        unicode"^",
        unicode"└",
        unicode"┼",
        unicode"Γ"
      ];

    uint256 noseId = rand % NOSE_COUNT;
    string memory nose = noses[noseId];
    return string(abi.encodePacked(unicode"   │ ", nose, unicode"  └┘  \n"));
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}