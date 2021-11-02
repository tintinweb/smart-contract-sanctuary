// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./core/ChainRunnersTypes.sol";

/*
               ::::                                                                                                                                                  :::#%=
               @*==+-                                                                                                                                               ++==*=.
               #+=#=++..                                                                                                                                        ..=*=*+-#:
                :=+++++++=====================================:    .===============================================. .=========================================++++++++=
                 .%-+%##+=--==================================+=..=+-=============================================-+*+======================================---+##+=#-.
                   [email protected]@%[email protected]@@%+++++++++++++++++++++++++++%#++++++%#+++#@@@#[email protected]@%[email protected]#+.=+*@*+*@@@@*+++++++++++++++++++++++%@@@#+++#@@+++=
                    -*-#%@@%%%=*%@%*++=++=+==+=++=++=+=++=++==#@%#%#+++=+=*@%*+=+==+=+++%*[email protected]%%#%#++++*@%#++=++=++=++=+=++=++=+=+*%%*==*%@@@*:%=
                     :@:[email protected]@@@@@*+++%@@*+===========+*=========#@@========+#%==========*@========##*#*+=======*@##*======#@#+=======*#*============+#%++#@@%#@@#++=.
                      .*+=%@%*%@%##[email protected]@%#=-==-=--==*%=========*%==--=--=-====--=--=-=##=--=-=--%%%%%+=-=--=-=*%=--=--=-=#%=--=----=#%=--=-=--=-+%#+==#%@@*#%@=++.
                        +%.#@@###%@@@@@%*---------#@%########@%*---------------------##---------------------##---------%%*[email protected]@#---------+#@=#@@#[email protected]@%*++-
                        .:*+*%@#+=*%@@@*=-------=#%#=-------=%*---------=*#*--------#+=--------===--------=#%*-------=#%*[email protected]%#--------=%@@%#*+=-+#%*+*:.
       ====================%*[email protected]@%#==+##%@*[email protected]#[email protected]@*-------=*@[email protected]@*[email protected][email protected]=--------*@@+-------+#@@%#==---+#@.*%====================
     :*=--==================-:=#@@%*===+*@%+=============%%%@=========*%@*[email protected]+=--=====+%@[email protected][email protected]========*%@@+======%%%**+=---=%@#=:-====================-#-
       +++**%@@@#*****************@#*=---=##%@@@@@@@@@@@@@#**@@@@****************%@@*[email protected]#***********#@************************************+=------=*@#*********************@#+=+:
        .-##=*@@%*----------------+%@%=---===+%@@@@@@@*+++---%#++----------------=*@@*+++=-----------=+#=------------------------------------------+%+--------------------+#@[email protected]
         :%:#%#####+=-=-*@@+--=-==-=*@=--=-==-=*@@#*[email protected][email protected]%===-==----+-==-==--+*+-==-==---=*@@@@@@%#===-=-=+%@%-==-=-==-#@%=-==-==--+#@@@@@@@@@@@@*+++
        =*=#@#=----==-=-=++=--=-==-=*@=--=-==-=*@@[email protected]===-=--=-*@@*[email protected]=--=-==--+#@-==-==---+%-==-==---=+++#@@@#--==-=-=++++-=--=-===#%[email protected]@@%.#*
        +#:@%*===================++%#=========%@%=========#%=========+#@%+=======#%==========*@#=========*%=========+*+%@@@+========+*[email protected]@%+**+================*%#*=+=
       *++#@*+=++++++*#%*+++++=+++*%%++++=++++%%*=+++++++##*=++++=++=%@@++++=++=+#%++++=++++#%@=+++++++=*#*+++++++=#%@@@@@*++=++++=#%@*[email protected]#*****=+++++++=+++++*%@@+:=+=
    :=*=#%#@@@@#%@@@%#@@#++++++++++%%*+++++++++++++++++**@*+++++++++*%#++++++++=*##++++++++*%@%+++++++++##+++++++++#%%%%%%++++**#@@@@@**+++++++++++++++++=*%@@@%#@@@@#%@@@%#@++*:.
    #*:@#=-+%#+:=*@*[email protected]%#++++++++#%@@#*++++++++++++++#%@#*++++++++*@@#[email protected]#++++++++*@@#+++++++++##*+++++++++++++++++###@@@@++*@@#+++++++++++++++++++*@@#=:+#%[email protected]*=-+%*[email protected]=
    ++=#%#+%@@%=#%@%#+%%#++++++*#@@@%###**************@@@++++++++**#@##*********#*********#@@#++++++***@#******%@%#*++**#@@@%##+==+++=*#**********%%*++++++++#%#=%@@%+*%@%*+%#*=*-
     .-*+===========*@@+++++*%%%@@@++***************+.%%*++++#%%%@@%=:=******************[email protected]@#+++*%%@#==+***--*@%*++*%@@*===+**=--   -************[email protected]%%#++++++#@@@*==========*+-
        =*******##.#%#++++*%@@@%+==+=             *#-%@%**%%###*====**-               [email protected]:*@@##@###*==+**-.-#[email protected]@#*@##*==+***=                     =+=##%@*+++++*%@@#.#%******:
               ++++%#+++*#@@@@+++==.              **[email protected]@@%+++++++===-                 -+++#@@+++++++==:  :+++%@@+++++++==:                          [email protected]%##[email protected]@%++++
             :%:*%%****%@@%+==*-                .%==*====**+...                      #*.#+==***....    #+=#%+==****:.                                ..-*=*%@%#++*#%@=+%.
            -+++#%+#%@@@#++===                  [email protected]*++===-                            #%++===           %#+++===                                          =+++%@%##**@@*[email protected]:
          .%-=%@##@@%*==++                                                                                                                                 .*==+#@@%*%@%=*=.
         .+++#@@@@@*++==.                                                                                                                                    -==++#@@@@@@=+%
       .=*=%@@%%%#=*=.                                                                                                                                          .*+=%@@@@%+-#.
       @[email protected]@@%:++++.                                                                                                                                              -+++**@@#+*=:
    .-+=*#%%++*::.                                                                                                                                                  :+**=#%@#==#
    #*:@*+++=:                                                                                                                                                          [email protected]*++=:
  :*-=*=++..                                                                                                                                                             .=*=#*.%=
 +#.=+++:                                                                                                                                                                   ++++:+#
*+=#-::                                                                                                                                                                      .::*+=*

*/

contract ChainRunnersBaseRenderer is Ownable, ReentrancyGuard {
    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Buffer {
        string one;
        string two;
        string three;
        string four;
        string five;
        string six;
        string seven;
        string eight;
    }

    struct Color {
        string hexString;
        uint alpha;
        uint red;
        uint green;
        uint blue;
    }

    struct Layer {
        string name;
        bytes hexString;
    }

    uint256 public constant NUM_LAYERS = 13;
    uint256 public constant NUM_COLORS = 8;

    mapping(uint256 => Layer) [NUM_LAYERS] layers;

    /*
    This indexes into a race, then a layer index, then an array capturing the frequency each layer should be selected.
    Shout out to Anonymice for the rarity impl inspiration.
    */
    uint16[][NUM_LAYERS][3] TRAITS;

    constructor() {
        // Default
        TRAITS[0][0] = [35, 223, 223, 223, 357, 134, 26, 357, 313, 313, 313, 313, 223, 178, 223, 178, 357, 178, 44, 357, 44, 357, 357, 35, 35, 357, 44, 178, 357, 223, 357, 223, 223, 357, 178, 44, 357, 26, 223, 223, 223, 223, 178, 223, 387];
        TRAITS[0][1] = [954, 1258, 772, 772, 772, 772, 772, 772, 772, 772, 772, 772, 17, 8, 43];
        TRAITS[0][2] = [303, 303, 303, 303, 151, 30, 0, 0, 151, 151, 151, 151, 30, 303, 151, 30, 303, 303, 303, 303, 303, 303, 30, 151, 303, 303, 303, 303, 303, 303, 303, 303, 3066];
        TRAITS[0][3] = [588, 882, 1176, 294, 588, 588, 588, 882, 294, 882, 588, 882, 882, 886];
        TRAITS[0][4] = [0, 0, 0, 1250, 1250, 1250, 1250, 1250, 1250, 1250, 1250];
        TRAITS[0][5] = [149, 149, 149, 149, 149, 149, 149, 0, 0, 0, 0, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 0, 0, 0, 0, 149, 149, 149, 149, 149, 166];
        TRAITS[0][6] = [925, 555, 185, 555, 925, 925, 185, 1296, 1296, 1296, 1857];
        TRAITS[0][7] = [89, 89, 0, 89, 89, 267, 446, 8931];
        TRAITS[0][8] = [183, 274, 274, 18, 18, 27, 36, 9170];
        TRAITS[0][9] = [234, 234, 234, 234, 234, 234, 23, 234, 234, 234, 234, 117, 117, 117, 70, 163, 163, 187, 234, 234, 234, 187, 163, 163, 163, 163, 117, 23, 0, 234, 234, 93, 234, 234, 234, 234, 3525];
        TRAITS[0][10] = [271, 452, 271, 180, 90, 361, 180, 452, 90, 361, 271, 452, 90, 452, 452, 361, 180, 271, 406, 90, 180, 9, 271, 90, 361, 361, 180, 271, 361, 452, 361, 452, 918];
        TRAITS[0][11] = [19, 98, 197, 197, 177, 177, 138, 158, 138, 197, 197, 138, 158, 59, 158, 197, 98, 98, 19, 197, 197, 197, 197, 197, 98, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 19, 98, 98, 98, 98, 0, 197, 138, 59, 59, 197, 59, 19, 2993];
        TRAITS[0][12] = [966, 2898, 644, 16, 966, 322, 644, 322, 3222];

        // Skull
        TRAITS[1][0] = [35, 223, 223, 223, 357, 134, 26, 357, 313, 313, 313, 313, 223, 178, 223, 178, 357, 178, 44, 357, 44, 357, 357, 35, 35, 357, 44, 178, 357, 223, 357, 223, 223, 357, 178, 44, 357, 26, 223, 223, 223, 223, 178, 223, 387];
        TRAITS[1][1] = [954, 1258, 772, 772, 772, 772, 772, 772, 772, 772, 772, 772, 17, 8, 43];
        TRAITS[1][2] = [0, 0, 0, 0, 0, 99, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9901];
        TRAITS[1][3] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        TRAITS[1][4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        TRAITS[1][5] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2500, 2500, 2500, 2500, 0, 0, 0, 0, 0, 0];
        TRAITS[1][6] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        TRAITS[1][7] = [0, 0, 0, 0, 0, 909, 0, 9091];
        TRAITS[1][8] = [0, 0, 0, 0, 0, 0, 0, 10000];
        TRAITS[1][9] = [476, 476, 476, 0, 0, 0, 0, 0, 476, 0, 0, 476, 476, 0, 476, 0, 0, 476, 476, 476, 476, 476, 476, 476, 476, 476, 476, 476, 476, 0, 0, 476, 0, 0, 0, 0, 480];
        TRAITS[1][10] = [80, 0, 403, 241, 80, 0, 241, 0, 0, 80, 80, 80, 0, 0, 0, 0, 0, 80, 0, 0, 80, 80, 0, 80, 80, 80, 80, 80, 0, 0, 0, 0, 8075];
        TRAITS[1][11] = [52, 263, 526, 526, 0, 0, 368, 421, 0, 526, 526, 368, 421, 157, 421, 526, 0, 0, 52, 0, 52, 0, 52, 526, 263, 526, 52, 0, 52, 52, 52, 526, 526, 0, 0, 0, 52, 52, 0, 52, 263, 52, 0, 0, 0, 52, 52, 0, 0, 1593];
        TRAITS[1][12] = [714, 714, 714, 0, 714, 0, 0, 0, 7144];

        // Bot
        TRAITS[2][0] = [35, 223, 223, 223, 357, 134, 26, 357, 313, 313, 313, 313, 223, 178, 223, 178, 357, 178, 44, 357, 44, 357, 357, 35, 35, 357, 44, 178, 357, 223, 357, 223, 223, 357, 178, 44, 357, 26, 223, 223, 223, 223, 178, 223, 387];
        TRAITS[2][1] = [954, 1258, 772, 772, 772, 772, 772, 772, 772, 772, 772, 772, 17, 8, 43];
        TRAITS[2][2] = [303, 303, 303, 303, 151, 30, 0, 0, 151, 151, 151, 151, 30, 303, 151, 30, 303, 303, 303, 303, 303, 303, 30, 151, 303, 303, 303, 303, 303, 303, 303, 303, 3066];
        TRAITS[2][3] = [588, 882, 1176, 294, 588, 588, 588, 882, 294, 882, 588, 882, 882, 886];
        TRAITS[2][4] = [2500, 2500, 2500, 0, 0, 0, 0, 0, 0, 2500, 0];
        TRAITS[2][5] = [0, 0, 0, 0, 0, 0, 0, 2500, 2500, 2500, 2500, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        TRAITS[2][6] = [925, 555, 185, 555, 925, 925, 185, 1296, 1296, 1296, 1857];
        TRAITS[2][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        TRAITS[2][8] = [183, 274, 274, 18, 18, 27, 36, 9170];
        TRAITS[2][9] = [234, 234, 234, 234, 234, 234, 23, 234, 234, 234, 234, 117, 117, 117, 70, 163, 163, 187, 234, 234, 234, 187, 163, 163, 163, 163, 117, 23, 0, 234, 234, 93, 234, 234, 234, 234, 3525];
        TRAITS[2][10] = [285, 475, 285, 190, 95, 380, 190, 475, 95, 380, 285, 475, 95, 475, 475, 380, 190, 285, 0, 95, 190, 9, 285, 95, 285, 285, 380, 285, 380, 475, 285, 475, 966];
        TRAITS[2][11] = [19, 98, 197, 197, 177, 177, 138, 158, 138, 197, 197, 138, 158, 59, 158, 197, 98, 98, 19, 197, 197, 197, 197, 197, 98, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 19, 98, 98, 98, 98, 0, 197, 138, 59, 59, 197, 59, 19, 2993];
        TRAITS[2][12] = [966, 2898, 644, 16, 966, 322, 644, 322, 3222];
    }

    function addLayer(string memory name, bytes memory hexString, uint8 layerIndex, uint8 itemIndex) public onlyOwner {
        layers[layerIndex][itemIndex] = Layer(name, hexString);
    }

    function getLayer(uint8 layerIndex, uint8 itemIndex) public returns (Layer memory) {
        return layers[layerIndex][itemIndex];
    }

    /*
    Get race index.  Race index represents the "type" of base character:

    0 - Default, representing human and alien characters
    1 - Skull
    2 - Bot

    This allows skull/bot characters to have distinct trait distributions.
    */
    function getRaceIndex(uint16 _dna) public view returns (uint8) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < TRAITS[0][1].length; i++) {
            percentage = TRAITS[0][1][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                // TODO make sure these are final
                if (i == 1) {
                    // Bot
                    return 2;
                } else if (i > 11) {
                    // Skull
                    return 1;
                } else {
                    // Default
                    return 0;
                }
            }
            lowerBound += percentage;
        }
        revert();
    }

    function getLayerIndex(uint16 _dna, uint8 _index, uint16 _traitIndex) public view returns (uint) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < TRAITS[_traitIndex][_index].length; i++) {
            percentage = TRAITS[_traitIndex][_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        revert();
    }

    /*
    Generate base64 encoded tokenURI.

    All string constants are pre-base64 encoded to save gas.
    Input strings are padded with spacing/etc to ensure their length is a multiple of 3.
    This way the resulting base64 encoded string is a multiple of 4 and will not include any '=' padding characters,
    which allows these base64 string snippets to be concatenated with other snippets.
    */
    function tokenURI(uint256 tokenId, ChainRunnersTypes.ChainRunner memory runnerData) public view returns (string memory) {
        (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = getTokenData(runnerData.dna);
        string memory attributes;
        for (uint8 i = 0; i < numTokenLayers; i++) {
            attributes = string(abi.encodePacked(attributes,
                bytes(attributes).length == 0	? 'eyAg' : 'LCB7',
                'InRyYWl0X3R5cGUiOiAi', traitTypes[i],'IiwidmFsdWUiOiAi', tokenLayers[i].name, 'IiB9'
            ));
        }
        string[4] memory svgBuffers = tokenSVGBuffer(tokenLayers, tokenPalettes, numTokenLayers);
        return string(abi.encodePacked(
                'data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+',
                    svgBuffers[0], svgBuffers[1], svgBuffers[2], svgBuffers[3],
                    'PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4gIiwgImF0dHJpYnV0ZXMiOiBb',
                    attributes,
                    'XSwgICAibmFtZSI6IlJ1bm5lciAj',
                    Base64.encode(uintToByteString(tokenId, 6)),
                    'IiwgImRlc2NyaXB0aW9uIjogIkNoYWluIFJ1bm5lcnMgYXJlIE1ldGEgQ2l0eSByZW5lZ2FkZXMgMTAwJSBnZW5lcmF0ZWQgb24gY2hhaW4uIn0g'
            ));
    }

    function tokenSVG(uint256 _dna) public view returns (string memory) {
        (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = getTokenData(_dna);
        string[4] memory buffer256 = tokenSVGBuffer(tokenLayers, tokenPalettes, numTokenLayers);
        return string(abi.encodePacked(
                "PHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMiAzMicgeG1sbnM9J2h0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnJyBzaGFwZS1yZW5kZXJpbmc9J2NyaXNwRWRnZXMnIGhlaWdodD0nMTAwJScgd2lkdGg9JzEwMCUnICA+",
                buffer256[0], buffer256[1], buffer256[2], buffer256[3],
                "PHN0eWxlPnJlY3R7d2lkdGg6MXB4O2hlaWdodDoxcHg7fTwvc3R5bGU+PC9zdmc+"
            )
        );
    }

    function getTokenData(uint256 _dna) public view returns (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string [NUM_LAYERS] memory traitTypes) {
        uint16[NUM_LAYERS] memory dna = splitNumber(_dna);
        uint16 raceIndex = getRaceIndex(dna[1]);

        // TODO make sure to update end index with final weights
        bool hasFaceAcc = dna[7] < (10000 - TRAITS[raceIndex][7][7]);
        bool hasMask = dna[8] < (10000 - TRAITS[raceIndex][8][7]);
        bool hasHeadBelow = dna[9] < (10000 - TRAITS[raceIndex][9][36]);
        bool hasHeadAbove = dna[11] < (10000 - TRAITS[raceIndex][11][49]);
        bool useHeadAbove = (dna[0] % 2) > 0;
        for (uint8 i = 0; i < NUM_LAYERS; i ++) {
            Layer memory layer = layers[i][getLayerIndex(dna[i], i, raceIndex)];
            if (layer.hexString.length > 0) {
                /*
                These conditions help make sure layer selection meshes well visually.
                1. If mask, no face/eye acc/mouth acc
                2. If face acc, no mask/mouth acc/face
                3. If both head above & head below, randomly choose one
                */
                // TODO make sure these are final indexes
                if (((i == 2 || i == 12) && !hasMask && !hasFaceAcc) || (i == 7 && !hasMask) || (i == 10 && !hasMask) || (i < 2 || (i > 2 && i < 7) || i == 8 || i == 9 || i == 11)) {
                    if (hasHeadBelow && hasHeadAbove && (i == 9 && useHeadAbove) || (i == 11 && !useHeadAbove)) continue;
                    tokenLayers[numTokenLayers] = layer;
                    tokenPalettes[numTokenLayers] = palette(tokenLayers[numTokenLayers].hexString);
                    traitTypes[numTokenLayers] = [ "QmFja2dyb3VuZCAg","UmFjZSAg","RmFjZSAg","TW91dGgg","Tm9zZSAg","RWFyIEFjY2Vzc29yeSAg","RXllcyAg","RmFjZSBBY2Nlc3Nvcnkg","TWFzayAg","SGVhZCBCZWxvdyAg","RXllIEFjY2Vzc29yeSAg","SGVhZCBBYm92ZSAg","TW91dGggQWNjZXNzb3J5" ][i];
                    numTokenLayers++;
                }
            }
        }
        // TODO remove

        return (tokenLayers, tokenPalettes, numTokenLayers, traitTypes);
    }

    /*
    Generate svg rects, leaving un-concatenated to save a redundant concatenation in calling functions to reduce gas.
    Shout out to Blitmap for a lot of the inspiration for efficient rendering here.
    */
    function tokenSVGBuffer(Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers) public pure returns (string[4] memory) {
        // Base64 encoded lookups into x/y position strings from 010 to 310.
        string[32] memory lookup = ["MDAw","MDEw","MDIw","MDMw","MDQw","MDUw","MDYw","MDcw","MDgw","MDkw","MTAw","MTEw","MTIw","MTMw","MTQw","MTUw","MTYw","MTcw","MTgw","MTkw","MjAw","MjEw","MjIw","MjMw","MjQw","MjUw","MjYw","Mjcw","Mjgw","Mjkw","MzAw","MzEw"];
        SVGCursor memory cursor;

        /*
        Rather than concatenating the result string with itself over and over (e.g. result = abi.encodePacked(result, newString)),
        we fill up multiple levels of buffers.  This reduces redundant intermediate concatenations, performing O(log(n)) concats
        instead of O(n) concats.  Buffers beyond a length of about 12 start hitting stack too deep issues, so using a length of 8
        because the pixel math is convenient.
        */
        Buffer memory buffer4; // 4 pixels per slot, 32 total.  Struct is ever so slightly better for gas, so using when convenient.
        string[8] memory buffer32; // 32 pixels per slot, 256 total
        string[4] memory buffer256; // 256 pixels per slot, 1024 total
        uint8 buffer32count;
        uint8 buffer256count;
        for (uint k = 32; k < 416;) {
            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.one = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.two = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.three = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.four = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.five = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.six = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.seven = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.eight = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            buffer32[buffer32count++] = string(abi.encodePacked(buffer4.one, buffer4.two, buffer4.three, buffer4.four, buffer4.five, buffer4.six, buffer4.seven, buffer4.eight));
            cursor.x = 0;
            cursor.y += 1;
            if (buffer32count >= 8) {
                buffer256[buffer256count++] = string(abi.encodePacked(buffer32[0], buffer32[1], buffer32[2], buffer32[3], buffer32[4], buffer32[5], buffer32[6], buffer32[7]));
                buffer32count = 0;
            }
        }
        // At this point, buffer256 contains 4 strings or 256*4=1024=32x32 pixels
        return buffer256;
    }

    function palette(bytes memory data) internal pure returns (Color [NUM_COLORS] memory) {
        Color [NUM_COLORS] memory colors;
        for (uint16 i = 0; i < NUM_COLORS; i++) {
            // Even though this can be computed later from the RGBA values below, it saves gas to pre-compute it once upfront.
            colors[i].hexString = Base64.encode(bytes(abi.encodePacked(
                    byteToHexString(data[i*4]),
                    byteToHexString(data[i*4+1]),
                    byteToHexString(data[i*4+2])
                )));
            colors[i].red = byteToUint(data[i*4]);
            colors[i].green = byteToUint(data[i*4+1]);
            colors[i].blue = byteToUint(data[i*4+2]);
            colors[i].alpha = byteToUint(data[i*4+3]);
        }
        return colors;
    }

    function colorForIndex(Layer[NUM_LAYERS] memory tokenLayers, uint k, uint index, Color [NUM_COLORS][NUM_LAYERS] memory palettes, uint numTokenLayers) internal pure returns (string memory) {
        for (uint256 i = numTokenLayers-1; i >= 0; i--) {
            Color memory fg = palettes[i][colorIndex(tokenLayers[i].hexString, k, index)];
            // Since most layer pixels are transparent, performing this check first saves gas
            if (fg.alpha == 0) {
                continue;
            } else if (fg.alpha == 255) {
                return fg.hexString;
            } else {
                for (uint256 j = i-1; j >= 0; j--) {
                    Color memory bg = palettes[j][colorIndex(tokenLayers[j].hexString, k, index)];
                    /* As a simplification, blend with first non-transparent layer then stop.
                    We won't generally have overlapping semi-transparent pixels.
                    */
                    if (bg.alpha > 0) {
                        return Base64.encode(bytes(blendColors(fg, bg)));
                    }
                }
            }
        }
        return "000000";
    }

    /*
    Each color index is 3 bits (there are 8 colors, so 3 bits are needed to index into them).
    Since 3 bits doesn't divide cleanly into 8 bits (1 byte), we look up colors 24 bits (3 bytes) at a time.
    "k" is the starting byte index, and "index" is the color index within the 3 bytes starting at k.
    */
    function colorIndex(bytes memory data, uint k, uint index) internal pure returns (uint8) {
        if (index == 0) {
            return uint8(data[k]) >> 5;
        } else if (index == 1) {
            return (uint8(data[k]) >> 2) % 8;
        } else if (index == 2) {
            return((uint8(data[k]) % 4) * 2) + (uint8(data[k+1]) >> 7);
        } else if (index == 3) {
            return (uint8(data[k+1]) >> 4) % 8;
        } else if (index == 4) {
            return (uint8(data[k+1]) >> 1) % 8;
        } else if (index == 5) {
            return ((uint8(data[k+1]) % 2) * 4) + (uint8(data[k+2]) >> 6);
        } else if (index == 6) {
            return (uint8(data[k+2]) >> 3) % 8;
        } else {
            return uint8(data[k+2]) % 8;
        }
    }

    /*
    Create 4 svg rects, pre-base64 encoding the svg constants to save gas.
    */
    function pixel4(string[32] memory lookup, SVGCursor memory cursor) internal pure returns (string memory result) {
        return string(abi.encodePacked(
            "PHJlY3QgICBmaWxsPScj", cursor.color1, "JyAgeD0n", lookup[cursor.x], "JyAgeT0n", lookup[cursor.y],
            "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color2, "JyAgeD0n", lookup[cursor.x+1], "JyAgeT0n", lookup[cursor.y],
            "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color3, "JyAgeD0n", lookup[cursor.x+2], "JyAgeT0n", lookup[cursor.y],
            "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color4, "JyAgeD0n", lookup[cursor.x+3], "JyAgeT0n", lookup[cursor.y], "JyAgIC8+"
        ));
    }

    /*
    Blend colors, inspired by https://stackoverflow.com/a/12016968
    */
    function blendColors(Color memory fg, Color memory bg) internal pure returns (string memory) {
        uint alpha = uint16(fg.alpha + 1);
        uint inv_alpha = uint16(256 - fg.alpha);
        return uintToHexString6(uint24((alpha * fg.blue + inv_alpha * bg.blue) >> 8) + (uint24((alpha * fg.green + inv_alpha * bg.green) >> 8) << 8) + (uint24((alpha * fg.red + inv_alpha * bg.red) >> 8) << 16));
    }

    function splitNumber(uint256 _number) internal pure returns (uint16[NUM_LAYERS] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    function uintToHexDigit(uint8 d) public pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    /*
    Convert uint to hex string, padding to 6 hex nibbles
    */
    function uintToHexString6(uint a) public pure returns (string memory) {
        string memory str = uintToHexString2(a);
        if (bytes(str).length == 2) {
            return string(abi.encodePacked("0000", str));
        } else if (bytes(str).length == 3) {
            return string(abi.encodePacked("000", str));
        } else if (bytes(str).length == 4) {
            return string(abi.encodePacked("00", str));
        } else if (bytes(str).length == 5) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to hex string, padding to 2 hex nibbles
    */
    function uintToHexString2(uint a) public pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint a, uint fixedLen) internal pure returns (bytes memory _uintAsString) {
        uint j = a;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        while (j > len) {
            j = j-1;
            bstr[j] = bytes1(' ');
        }
        uint k = len;
        while (a != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(a - a / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }

    function byteToUint(bytes1 b) public pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) public pure returns (string memory) {
        return uintToHexString2(byteToUint(b));
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ChainRunnersTypes {
    struct ChainRunner {
        uint256 dna;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}