// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';


contract Catoodles is ERC721, Ownable {

    struct Cat {
        uint8 background;
        uint8 bodyMark;
        uint8 outfit;
        uint8 eyes;
        uint8 mouths;
        uint8 accessories;
        uint8 hats;
        bool unique;
    }


    // COLORS
    string[] palette = ["9ecdee", "e6355c", "020202", "e9afee", "88bde2", "faf3ef", "9e655b", "fdf1b1", "81868b", "dcd8b0", "b1b3b5", "fbe671", "dac6ab", "72df87", "a2b4f9", "f3b2dd", "cef9ea", "ffffff", "f78bfc", "fb88fc", "fe77ff", "000000", "a72c2b", "94d7bd", "c75d69", "df6437", "f9d949", "846bf6", "67cbd5", "69b093", "834a48", "ee80c7", "e4815a", "894d4a", "c6967d", "af5f56", "5d3eeb", "f7cbe8", "ee7444", "f89ed9", "7bdab5", "f4e5b1", "3e8dd2", "46484c"];

    // BODY
    bytes public bodySVGData = bytes(hex"0424000a250a160b160b150a150a140b140b130a130a100b100b0b0c0b0c0c0d0c0d0d0e0d0e0e170e170d160d160b170b170c180c180d190d19101a101a17191719181818181917191725140209250916081608150915091408140813091309110a110a130b130b140a140a150b150b160a160a2512021a181a111b111b131d131d141b141b151d151d161b161b171917191917191725182518181802150b150d0d0d0d0b0a0b0a100b100b0a0c0a0c0c0e0c0e0e170e170d160d160a170a170c190c19101a101a0d180d180b");

    // BACKGROUNDS
    bytes[5] public backgroundsSVGData = [bytes(hex"0104100025000025002525"), bytes(hex"01040e0025000025002525"), bytes(hex"01040f0025000025002525"), bytes(hex"01040d0025000025002525"), bytes(hex"01040c0025000025002525")];
    uint16[] public backgroundsProbabilities = [50, 150, 200, 250, 350];
    string[5] public backgroundsNames = ["Water", "Lilac", "Pink", "Green", "Beige"];

    // BODY MARKS
    bytes[3] public bodyMarksSVGData = [bytes(hex"030a040d100d0f0e0f0e1110111013111311120f120f1006041010100f110f11111211121008040c130c120d120d140f140f150e150e13"), bytes(hex"0204030c150c140e140e150403191519141b141b15"), bytes(hex"00")];
    uint16[] public bodyMarksProbabilities = [50, 150, 800];
    string[3] public bodyMarksNames = ["Fighter", "Blush", "None"];

    // OUTFITS
    bytes[9] public outfitsSVGData = [bytes(hex"1f1c1b162516241524152512251224112411230a230a220b220b210a210a1f0e1f0e1e0a1e0a1d101d101e111e111d171d171e161e161f171f17250402091d091c181c181d08240d250d240a240a23112311241224122508240f200f1f121f121e151e151f141f142004240a1f0a1e0e1e0e1f041b0a250a240d240d2504241022102113211322041b081c081a091a091c041b0b1c0a1c0a1a0b1a041b0c1c0c1a0d1a0d1c041b0f1c0e1c0e1a0f1a041b101c101a111a111c041b131c121c121a131a041b141c141a151a151c041b171c161c161a171a041b181c181a191a191c04240a1c091c091a0a1a04240b1c0b1a0c1a0c1c04240e1c0d1c0d1a0e1a04240f1c0f1a101a101c0424121c111c111a121a0424131c131a141a141c0424161c151c151a161a0424171c171a181a181c04240c210c200e200e21042414231422162216230424101e101d111d111e0424161f161e171e171f0424152115201620162104240a220a210b210b2204241525152416241625"), bytes(hex"051e0111221121102110200f200f1f0e1f0e1e0d1e0d1d0c1d0c1c0b1c0b1b091b091a181a181c171c171d161d161e151e151f141f1420132013211221122204020a1a0a191719171a0402181c181a191a191c0402081b081a091a091b1c020a1c0a1b0b1b0b1d0d1d0d1f0f1f0f2111211123122312211421141f161f161d171d171e151e152013201322102210200e200e1e0c1e0c1c"), bytes(hex"0514290a250a1c0b1c0b1d0c1d0c1e0d1e0d1f0e1f0e200f200f21102110221122112312231224132413253a071222132213231423142415241525132513241224122311231122102210210f210f200e200e1f0d1f0d1e0c1e0c1d0b1d0b1c0a1c0a1a0b1a0b1b0c1b0c1c0d1c0d1d0e1d0e1e0f1e0f1f101f102011201121142114201520151f161f161e171e171c161c161d151d151e141e141f131f132012201029172516251624152415231423142213221321142114201520151f161f161e171e24020c1c0c1a0a1a0a190b190b1b0d1b0d1d0f1d0f1f111f1121132113231523152516251624142414221222121f141f141d161d161b171b171c151c151e131e13201020101e0e1e0e1c04021825172517241824"), bytes(hex"040c1a1525151f0d1f0d250a250a1c0c1c0c1d161d161c171c172504290e250e201420142508021525142514200e200e250d250d1f151f08020a1c0a1b0c1b0c1d161d161b181b181c"), bytes(hex"020c050a250a1c0d1c0d1d0f1d0f1e131e131d151d151c171c17250c020a1c0a1b0d1b0d1d151d151b171b171c131c131e0f1e0f1c"), bytes(hex"06082a102510201120111f121f1220132013251e050f1f0e1f0e1e0d1e0d1d0c1d0c1c0a1c0a1b0e1b0e1c0f1c0f1d101d101e111e111f101f10200e200e1f0d1f0d1e0c1e0c1d0a1d0a25102510210f211a051320131f121f121e131e131d141d141c151c151b171b171d161d161e151e151f141f1421132113251725171e161e161f151f15202a020f1b0a1b0a1a0e1a0e1c101c101e131e131c151c151a181a181b141b141d121d12201520151e171e171d161d161f141f14211321131f101f10210f210f1f0d1f0d1d0a1d0a1c0c1c0c1e0e1e0e201120111d0f1d04020b220b210e210e22042a0b210b200c200c21"), bytes(hex"020c2b0a250a1c0d1c0d1d0f1d0f1e131e131d151d151c171c17250c020a1c0a1b0d1b0d1d151d151b171b171c131c131e0f1e0f1c"), bytes(hex"0c0c011525151f0d1f0d250a250a1c0c1c0c1d161d161c171c17251602132011201121102110200f200f220e220e230f230f240e240e250d250d1f151f15251425142212221225132508291225112511211221122013201322122208020a1c0a1b0c1b0c1d161d161b171b171c06290f20102010220e220e230f2304021123102310221122040210251024112411250c0111201220122110211023112311240e240e250f250f22112204011323132214221423040113251324142414250429132413231423142404290f250f2410241025"), bytes(hex"00")];
    uint16[] public outfitsProbabilities = [10, 150, 150, 150, 200, 30, 150, 60, 100];
    string[9] public outfitsNames = ["Ugly Sweater", "Scarf", "Burrito", "Yellow Sweater", "WT-Shirt", "Office", "T-Shirt", "Pinky Sweatshirt", "None"];

    //// EYE
    bytes[16] public eyesSVGData = [bytes(hex"0204020e130e120f120f1304021813181219121913"), bytes(hex"0204020d130d120f120f1304021713171219121913"), bytes(hex"032002141712171215101510101210120e130e130f110f11110f110f120e120e110b110b100c100c120d120d1411141116131613181518151a171a171b161b1619141904110f120e120e110f1104151813181219121913"), bytes(hex"0204020f130e130e110f1104021813181119111913"), bytes(hex"03060217131711181118121912191308020c120c130d130d110f110f131013101204051812181119111912"), bytes(hex"0406020d140d120e120e130f130f14060217141712181218131913191404050e130e120f120f1304051813181219121913"), bytes(hex"032002171117121612161115111510121012111111111010101012111211110f110f120e120e110d110d100810080f1b0f1b101a101a1119111910181018121912191106051010111011110f110f1210120605181019101911171117121812"), bytes(hex"0406020d120d110e110e130f130f12060217121711181118131913191206050e110f110f120d120d130e130605181119111912171217131813"), bytes(hex"0406050f130f120e120e1110111013060518131812171217111911191304020e130e120f120f1304021713171218121813"), bytes(hex"0204020d140d120f120f1404021714171219121914"), bytes(hex"080c120e140e130d130d120c120c110e110e120f120f13101310140c1318141813171317121612161118111812191219131a131a140402111211111611161204020c12081208110c110c140d110d100e100e120f120f1311131111101110100f100f110c141711171018101812191219131b131b111a111a101910191108140c130c120d120d140f140f150e150e13081418131613161217121714191419151815"), bytes(hex"0210020f130e130e120d120d110c110c100b100b0f190f191011101111101110120f1204021812181119111912"), bytes(hex"0404020d110d100f100f110402161116101810181104110e130e120f120f1304111713171218121813"), bytes(hex"0406020f130e130e120c120c110f11060218131812161216111911191304050d130d120e120e1304051713171218121813"), bytes(hex"0404020d120d110f110f120402171217111911191204050e130e120f120f1304051813181219121913"), bytes(hex"060402121112101410141104020d120d110f110f12040217121711191119120405141213121311141104050e130e120f120f1304051813181219121913")];
    uint16[] public eyesProbabilities = [150, 60, 20, 100, 80, 100, 10, 135, 40, 100, 5, 20, 40, 30, 90, 20];
    string[16] public eyesNames = ["Dots", "Closed", "Pirate", "Vertical", "Wink", "Big And Shiny", "Deal With It", "Shiny", "Big Eyes", "Big Dots", "Heart Shaped", "Easy Pirate", "Brows Up", "Suspicious", "Brows", "Sophisticated"];

    //// MOUTHS
    bytes[11] public mouthsSVGData = [bytes(hex"0210021515141514141114111610161015121512131613161417141716111611171517082511161115121512141414141515151516"), bytes(hex"010c02121512161316131412141213151315141414141615161515"), bytes(hex"01080211141115121512131513151516151614"), bytes(hex"0104021214121315131514"), bytes(hex"0206251116111412141215141514161202111312131214101410161416141512151214151415131613161417141716161616171117"), bytes(hex"020402111411131613161404251215121413141315"), bytes(hex"05042613231314141414230407152214221414151404271322122212151315042816211521151516150c02161412141217111711151315131315131515171517171617"), bytes(hex"010602111411131213121515151514"), bytes(hex"010c02151316131614111411131213121611161115161516161516"), bytes(hex"010c02101410131113111513151313141314151615161317131714"), bytes(hex"01080211141113121312151515151316131614")];
    uint16[] public mouthsProbabilities = [20, 100, 130, 100, 126, 120, 4, 120, 50, 80, 150];
    string[11] public mouthsNames = ["Disappointed", "True Cat", "Sad", "Flat", "Joy", "Tongue", "Rainbow", "Hmm", "Chewk", "Meow", "Slight Smile"];

    //// ACCESSORIES
    bytes[7] public accessoriesSVGData = [bytes(hex"060406060f060e0c0e0c0f0807090e050e050d070d070c080c080d090d0a081d111c111c0f1d0f1d0e1f0e1f0f1e0f1e101d1008090811071107100510050f090f09100810060a1c0e1c0c1d0c1d0d1e0d1e0e04061a0f1a0e1d0e1d0f"), bytes(hex"04040b080d080c0a0c0a0d040b090f090e0b0e0b0f04070a0d0a0c0b0c0b0d04070b0f0b0e0c0e0c0f"), bytes(hex"0214050c0f090f090e070e070d060d060b050b05080608060a070a07090809080c090c090d0b0d0b0e0c0e14051b0e1a0e1a0d190d190c1a0c1a0b1b0b1b091c091c0a1d0a1d081e081e0b1d0b1d0c1c0c1c0d1b0d"), bytes(hex"0204010811080e0b0e0b11040b0a100910090f0a0f"), bytes(hex"010a05080d080c070c070a080a080b090b090f1a0f1a0d"), bytes(hex"010a01080d080c070c070a080a080b090b090f1a0f1a0d"), bytes(hex"00")];
    uint16[] public accessoriesProbabilities = [70, 200, 30, 200, 100, 100, 300];
    string[7] public accessoriesNames = ["Arrow", "Piercing", "Horns", "Flower", "Bandana Pure", "Bandana Pink", "None"];

    //// HATS
    bytes[9] public hatsSVGData = [bytes(hex"011801120c110c110b100b100a0f0a0f090e090e070f070f06110611071207120614061407150715091409140a130a130b120b"), bytes(hex"0a08050e0a0e0910091007130713091509150a041e0f0b0f0a120a120b0406120b120a140a140b040b110d100d100b110b040b120d120b130b130d041a110d110b120b120d041b1107110612061207041f0f090f0810081009041c120911091108120804201309130814081409"), bytes(hex"031421090f090e080e080d070d070b090b090c110c110d150d150c1b0c1b0b1d0b1d0d1c0d1c0e1b0e1b0f0c22110d110c0a0c0a0b0b0b0b0a190a190b1a0b1a0c150c150d14230c0a0c090d090d080e080e071107110812081209130913081408140716071608170817091809180a"), bytes(hex"03081b130f120f120e110e110c120c120a130a0c02120b12091409140e130e130a110a110c0f0c0f0d100d100b0624110b120b120c100c100d110d"), bytes(hex"07241a090e090a0a0a0a0b0b0b0b0c0c0c0c0d0d0d0d0c0e0c0e0b0f0b0f0a100a100b110b110c130c130b140b140a150a150b160b160c170c170d180d180c190c190b1a0b1a0a1b0a1b0e041a0910090f1b0f1b10040b090f090e1b0e1b0f041b090d080d080c090c041c0f0d0f0c100c100d0401140d140c150c150d041d1b0d1b0c1c0c1c0d"), bytes(hex"010c01110e110d100d100c110c110b120b120a130a13091409140e"), bytes(hex"040a05130f130e120e120d100d10091309130c140c140f040b12071206130613070419110811071207120804021209110911081208"), bytes(hex"040c16100d100c0f0c0f0a100a10091309130a140a140c130c130d04021109110712071209041712081207130713080418120b120a130a130b"), bytes(hex"00")];
    uint16[] public hatsProbabilities = [70, 105, 10, 120, 5, 120, 120, 30, 420];
    string[9] public hatsNames = ["Love", "Cupcake", "Hat", "Punk V", "Crown", "Punk", "Candle", "Apple", "None"];

    //// UNIQUE
    bytes public uniqueSVGData = bytes(hex"0f28000e200e1f0d1f0d1e0c1e0c1b0b1b0b170c170c160b160b140c140c130d130d120e120e061b061b151a151a161b161b171a171a181b181b1b1a1b1a201920191f181f181e171e171d0e1d0e1e0f1e0f2018011425142413241325112511241024102211221121122112201320131f141f14201520152116211622172217241624162514021c1a1b1a1b181a181a171b171b161a161a151b151b061c061c151d151d161c161c171d171d181c180c020b130d130d060e060e120c120c140a140a15081508160b1606020b1a0a1a0a18081808170b170402101810171317131806020e1a0d1a0d190c190c180e181802101e10200d200d1e0b1e0b1b0c1b0c1f0e1f0e210f210f1e0e1e0e1d171d171f191f19211a211a1b1b1b1b201820181e04030a170a160c160c17040317171716191619170802151915181618161a181a18181918191906041617161617161718181818170a04141914181518151a171a171c181c181b161b16190604131b131a141a141c151c151b04050c1a0c190d190d1a");
    uint16[] public uniqueProbability = [1, 999];
    uint uniqueTokenId = 0;

    constructor () ERC721("Catoodles", "CTDLS") {
    }

    function tokenURI(uint tokenId) public override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Cat memory cat;
        for (uint i = 1; i < 10000; i++) {
            uint seed = uint256(keccak256(abi.encode(i, tokenId)));
            cat = generateCat(tokenId, seed);
            if (!isContainsIncompatibleTraits(cat)) {
                break;
            }
        }

        bytes memory meta = abi.encodePacked(
            '{"name":"Catoodle #',
            Strings.toString(tokenId),
            '", "attributes":',
            getTraits(cat),
            ',"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(drawSVG(cat))), '"}'
        );
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(meta)));
    }

    function getTraits(Cat memory cat) internal view returns (bytes memory) {
        if (cat.unique) {
            return '[{"value": "Unique"}]';
        }
        return abi.encodePacked(
            abi.encodePacked(
                '[{"trait_type": "Background","value": "',
                backgroundsNames[cat.background],
                '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "Body Mark","value": "',
                bodyMarksNames[cat.bodyMark],
                '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "Outfit","value": "',
                outfitsNames[cat.outfit],
                '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "Eyes","value": "',
                eyesNames[cat.eyes],
                '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "Mouth","value": "',
                mouthsNames[cat.mouths],
                '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "Accessory","value": "',
                accessoriesNames[cat.accessories],
                '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "Hat","value": "',
                hatsNames[cat.hats],
                '"}]'
            )
        );
    }

    function isContainsIncompatibleTraits(Cat memory cat) internal pure returns (bool) {
        return
        // BIG HAT(2) OR CROWN(4) EXCLUDE ANY ACCESSORY(None 6)
        ((cat.hats == 2 || cat.hats == 4) && cat.accessories != 6) ||
        // BANDANA(4,5) EXCLUDE CANDLE(6), CROWN(4), DWIT(6)
        ((cat.accessories == 4 || cat.accessories == 5) && (cat.hats == 6 || cat.hats == 4 || cat.eyes == 6)) ||
        // HORNS(2) EXCLUDE CROWN(4)
        (cat.accessories == 2 && cat.hats == 4) ||
        // PIRATE EYES(2) ONLY WITH FLAT(3) OR RAINBOW MOUTH(6)
        (cat.eyes == 2 && cat.mouths != 3 && cat.mouths != 6) ||
        // MEOW MOUTH ONLY WITH DOTS(0) EYES, VERTICAL(3), DWIT(6), BROWS(14) AND SOPHISTICATED(15)
        (cat.mouths == 9 && cat.eyes != 0 && cat.eyes != 3 && cat.eyes != 6 && cat.eyes != 14 && cat.eyes != 15) ||
        // BLUSH EXCLUDE PINK BACKGROUND
        (cat.bodyMark == 1 && cat.background == 2) ||
        // WATER(0) EXCLUDE ACCESSORIES: HORNS(2), WHITE BANDANA(4); HATS: CANDLE(6), CUPCAKE(1)
        (cat.background == 0 && (cat.accessories == 2 || cat.accessories == 4 || cat.hats == 6 || cat.hats == 1)) ||
        // HEART EYES (10) EXCLUDE ANY BODY MARKS(NONE 2)
        (cat.eyes == 10 && cat.bodyMark != 2) ||
        // PINK BANDANA(5) EXСLUDE RED PUNK(5)
        (cat.accessories == 5 && cat.hats == 5) ||
        // PIRATE(2, 11 EASY) EXCLUDE CROWN(4) AND BANDANAS(4,5)
        ((cat.eyes == 2 || cat.eyes == 11) && (cat.hats == 4 || cat.accessories == 4 || cat.accessories == 5)) ||
        // ARROW(0) OR HORNS(2) EXCLUDE DWIT(6) AND PIRATE EASY(11);
        (cat.accessories == 0 || cat.accessories == 2) && (cat.eyes == 6 || cat.eyes == 11);
    }

    function generateCat(uint tokenId, uint seed) internal view returns (Cat memory cat) {
        if (tokenId == uniqueTokenId) {
            cat.unique = true;
            return cat;
        }
        cat.background = selectTraitValue(seed, "BACK", backgroundsProbabilities);
        cat.bodyMark = selectTraitValue(seed, "BODY MARK", bodyMarksProbabilities);
        cat.outfit = selectTraitValue(seed, "OUTFIT", outfitsProbabilities);
        cat.eyes = selectTraitValue(seed, "EYES", eyesProbabilities);
        cat.mouths = selectTraitValue(seed, "MOUTHS", mouthsProbabilities);
        cat.accessories = selectTraitValue(seed, "ACCESSORIES", accessoriesProbabilities);
        cat.hats = selectTraitValue(seed, "HATS", hatsProbabilities);
        return cat;
    }

    function drawSVG(Cat memory cat) public view returns (string memory) {
        string memory header = '<svg viewBox="0 0 37 37" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
        if (cat.unique) {
            return string(abi.encodePacked(
                    header,
                    uniqueSVGData,
                    "</svg>"
                ));
        }
        return string(abi.encodePacked(
                header,
                renderPaths(backgroundsSVGData[cat.background]),
                renderPaths(bodySVGData),
                renderPaths(bodyMarksSVGData[cat.bodyMark]),
                renderPaths(outfitsSVGData[cat.outfit]),
                renderPaths(eyesSVGData[cat.eyes]),
                renderPaths(mouthsSVGData[cat.mouths]),
                renderPaths(hatsSVGData[cat.hats]),
                renderPaths(accessoriesSVGData[cat.accessories]),
                "</svg>")
        );
    }

    function renderPaths(bytes storage svgData) internal view returns (string memory) {
        uint8 pathsCount = uint8(svgData[0]);
        if (pathsCount == 0) {
            return "";
        }
        uint32 index = 1;

        bytes memory renderedResult;
        for (uint16 path = 0; path < pathsCount; path++) {
            uint8 pointsCount = uint8(svgData[index++]);
            string memory color = palette[uint8(svgData[index++])];
            bytes memory renderedPath = abi.encodePacked('<path fill="#', color, '" d="M ');

            for (uint16 point = 0; point < pointsCount; point++) {
                if (point != 0) {
                    renderedPath = abi.encodePacked(renderedPath, ",");
                }
                renderedPath = abi.encodePacked(renderedPath, Strings.toString(uint8(svgData[index++])), " ", Strings.toString(uint8(svgData[index++])));
            }
            renderedPath = abi.encodePacked(renderedPath, "\"/>");
            renderedResult = abi.encodePacked(renderedResult, renderedPath);
        }
        return string(renderedResult);
    }

    function selectTraitValue(uint seed, string memory salt, uint16[] storage probs) internal view returns (uint8) {
        uint16 rand = uint16(random(string(abi.encodePacked(salt, seed))) % 1000);
        for (uint8 i = 0; i < probs.length; i++) {
            if (rand < probs[i]) {
                return i;
            } else {
                rand -= probs[i];
            }
        }
        return 0;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }


    uint public constant MAX_NFT_SUPPLY = 5000;
    uint public constant NFT_PRICE = 0.0069 ether;

    uint public maxFreeNFTPerWallet = 5;
    uint public maxNFTPerWallet = 100;
    uint public totalSupply;

    mapping(address => uint) public mintedNFTs;

    function mintPrice(uint amount) public view returns (uint) {
        if (totalSupply >= MAX_NFT_SUPPLY / 2) {
            return amount * NFT_PRICE;
        }
        uint minted = mintedNFTs[msg.sender];
        uint remainingFreeMints = maxFreeNFTPerWallet > minted ? maxFreeNFTPerWallet - minted : 0;
        if (remainingFreeMints >= amount) {
            return 0;
        } else {
            return (amount - remainingFreeMints) * NFT_PRICE;
        }
    }

    function mint(uint amount) external payable {
        require(amount > 0 && amount <= 10, "Amount of tokens must be positive");
        require(totalSupply + amount <= MAX_NFT_SUPPLY, "MAX_NFT_SUPPLY constraint violation");

        require(mintedNFTs[msg.sender] + amount <= maxNFTPerWallet, "maxNFTPerWallet constraint violation");
        require(mintPrice(amount) == msg.value, "Wrong ethers value.");

        mintedNFTs[msg.sender] += amount;

        uint startTokenId = totalSupply + 1;

        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            if (uniqueTokenId == 0) {
                uint val = selectTraitValue(startTokenId + i, "UNIQUE", uniqueProbability);
                if (val == 0) {
                    uniqueTokenId = startTokenId + i;
                }
            }
            _safeMint(msg.sender, startTokenId + i);
        }
    }

    function mintTEST(uint amount) external {
        for (uint i = 0; i < amount; i++) {
            if (uniqueTokenId == 0) {
                uint val = selectTraitValue(totalSupply + 1, "UNIQUE", uniqueProbability);
                if (val == 0) {
                    uniqueTokenId = totalSupply + 1;
                }
            }
            _mint(msg.sender, ++totalSupply);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}