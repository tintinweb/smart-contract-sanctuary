// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OnChainSands is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint private constant maxTokensPerTransaction = 30;
    uint256 private tokenPrice = 30000000000000000; //0.03 ETH
    uint256 private constant nftsNumber = 5000;
    uint256 private constant nftsPublicNumber = 4950;
    
    constructor() ERC721("OnChain Sands", "SND") {
        _tokenIdCounter.increment();
    }
    

     function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "000000";
        }
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }
    
    
    
    function getFarObject(uint256 num) internal pure returns (string memory) {
        string[4] memory far;
        
        far[0] ='M431.741,537.724 371.85,467.096 321.582,517.364 254.859,442.361 160.11,537.109';
        far[1] ='M191,556l219-2l-99-117L191,556z';
        far[2] ='M244,557 238,488 248,488 238,413 298,398 296,389 424,407 401,484 391,487 383,555';
        far[3] ='M209,511c0-0,36-8,36-8 s10-1,11-1s17-15,17-16s0-6,0-6l19-0v-6h9l1-6h4v-1 h67v2h5v4c0,0,11-1,11,0s0,8,0,8h20v6l18,18h7v10v70H209 L209,511z';

        return far[num-1];
    }
    
    function getSun(uint256 num) internal pure returns (string memory) {
        uint256 suns;
        uint256 suns_m;

        suns_m = 650299126634312082;
        suns = 709260192684279125512259162535278106613289157619291124044823099706295099;
        if (num >= 8) {
            suns = num == 8 ? suns_m : suns_m / 1000000000;
        } else {
            if (num > 0)
                suns = suns / (1000 ** (num*3));
        }

        string memory output = string(abi.encodePacked('cx="',toString((suns/1000000)%1000),'" cy="',toString((suns/1000)%1000),  '" r="',toString(suns%1000),'"'));
        
        return output;
    }
//this feature is just for fun, it's pointless.
 function getCamel(uint256 num) internal pure returns (string memory) {
        uint256[50] memory xtypes;
        uint256 pos;

        uint256 i;
        uint256 temp;
        uint256 sym;
        uint256 lines;

        xtypes[0] = 2750871777490806264085493004602956112481215626846361120;
// Elon Musk is a poser
        xtypes[1] = 24031940146303221873185246330856176777890234172085460524828847635091787832103;
        xtypes[2] = 4369554406778136407906521031351492442121714090311337998835645029932110349922;
        xtypes[3] = 35339669699060465125668189898147169548632576962648599291375229098669428362322;
        xtypes[4] = 672238645676028630017590070904525;

        xtypes[11] = 37599700675902714367317740679304042296080055052422520140113640294389393350439;
        xtypes[12] = 38087302781903350862724587794493881498317283716547227642212787098338845152311;
        xtypes[13] = 1114275929128553399568145623741250323077119217211655860047041411166003561237;
        xtypes[14] = 44483940829496349223937135327653774303045114145795750475934727822431742908025;
        xtypes[15] = 1301031010810467202189960410466201454370628906584976487492660977313;
        

        xtypes[21] = 24511554605809013553427690817438832449166603887000346203695542442847542862631;
        xtypes[22] = 24712231507965098789272277915974614596914779217528115716846960336470200999989;
        xtypes[23] = 31779261119830188930260713981005416210882557915559935577937916313743035255330;
        xtypes[24] = 30845749996097297930742408311135328346981512733480170301818670564314058110498;
        xtypes[25] = 4393324743237794958108912339045511528520735357988065415454558326487042311245;
        xtypes[26] = 4383618393247594429327385840719100733921976757672061077695343950821928420434;
        xtypes[27] = 28260977779972716408629221197954496518888178178346784762024000144425;
// I wrote that because I'm jealous of his billions
        xtypes[31] = 33981201337895841066299736423112852304759862823304893271895015697500599799591;
        xtypes[32] = 38092437674498035584450155165625035089506200894468052066380022772320589009972;
        xtypes[33] = 1002964437672768398493084675030519774534336229557529541653364574576256516854;
        xtypes[34] = 41202914189462662695915620887590875333337880836299726911136825280773640739640;
        xtypes[35] = 40993983140047288513282733679841254915488686784624912185639295148702690920129;
        xtypes[36] = 43462155136449166491448379421314888609432193428547199763947083681431896678423;
        xtypes[37] = 3091541931616987385254478349605488253295528003625843124585170727615066703541;
        xtypes[38] = 42893843881028951002600077923910138109116652418088673519145098082818520534773;
        xtypes[39] = 35790225028626312902234269550783631619805539570794490376389285434126321176320;
        xtypes[40] = 23946826271475684407;
// and the fact that he's sexy
        xtypes[41] = 32696238382569806469557342148762393436204618157687364688486249358066242446087;
        xtypes[42] = 30829847781535805781250327403060765435737126585110613555906562372477089399884;
        xtypes[43] = 2322370439730553613354915887410243625117939153279733562435129926126979548749;
        xtypes[44] = 3077242879332650009073929722759956366751482431073885344923252432370954176881;
        xtypes[45] = 35126784166904065671947169645446477285741344117817602589955598641710815590065;
        xtypes[46] = 2978473281905248387737881203435264718697731825484007630263831601596209749570;
        xtypes[47] = 542357;

        bytes memory buffer = new bytes(500);
        temp = xtypes[1];
        pos=0;
        for(lines=1;lines<=10;lines++) {
            if (xtypes[10*(num-1) + lines] == 0)
                break;
            temp = xtypes[10*(num-1) + lines];
            for(i=0;i<=50;i++) {
                if (temp==0)
                    break;
                sym = temp%32;
                temp /= 32;
                buffer[pos++] = bytes1(uint8((xtypes[0]/(128**sym))%128));
            }
        }
        
        bytes memory buffer2 = new bytes(pos);
        for(i=0;i<pos;i++)
            buffer2[i] = buffer[i];

        return string(buffer2);
    }
    // programmers are the coolest people.
    function getDune1(uint256 num) internal pure returns (string memory) {
        string[2] memory dune;
        
            dune[0] = 'M-68,1082l1157,6l-19-577c0,0-39-6-117-6 s-102,8-185,16s-118,8-183,8s-181-21-331-21s-286,42-286,42 L-68,1082z';
            dune[1] = 'M1089,1015l-1157,5l19-478c0,0,42-15,119-22 c77-6,173-8,255,0c82,9,159,12,225,12s188-14,338-14 s165,33,165,33L1089,1015z';

        return dune[num-1];
    }
    
    // and humble. 
    function getDune2(uint256 num) internal pure returns (string memory) {
        string[4] memory dune;
        
            dune[0] = 'M-39,1013l1181,40c0,0-18-502-77-485 c-185,52-250-23-416-5c-77,8-148,29-324-22S-61,574-61,614 L-39,1013z';
            dune[1] = 'M1140,1013l-1181,40c0,0-37-507,23-496c189,34,315-4,482,13 c77,8,205,51,391-21c170-66,270,61,273,69L1140,1013z';
            dune[2] = 'M-39,1016l1181,40c0,0-18-502-77-485 c-185,52-211-40-377-22c-77,8-203,37-380,25 c-182-12-327,14-330,22L-39,1016z';
            dune[3] = 'M1142,1016l-1181,40c0,0-66-554-9-530 c181,77,299,26,464,33c77,3,207,45,382,14 c180-32,327,14,330,22L1142,1016z';

        return dune[num-1];
    }
    
    
     function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        uint256[17] memory xtypes;
        string[5] memory colors;
        string[4] memory dune3;
        string[4] memory dune31;
        string[4] memory dune32;

        string[27] memory parts;
        uint256[12] memory params;
        string[6] memory obj1;
        string[6] memory obj2;

        uint256 pos;

        uint256 rand = random(string(abi.encodePacked('Sand',toString(tokenId))));

        params[0] = 1 + ((rand/10) % 5);// camel=
        params[1] = 1 + ((rand/1000) % 33); // pallette=
        params[2] = 1 + ((rand/10000) % 4); // dune main
        params[3] = 1 + ((rand/10000) % 2); // dune top
        params[4] = 1 + ((rand/100000) % 4); // dune bottom
        params[5] = 1 + ((rand/1000000000) % 4); // pyr=
        params[6] = 1 + ((rand/10000000000) % 5); // obj=
        params[7] = 1 + ((rand/100000000) % 5); // sun

        
        obj1[0] = 'M128,897c4,1,8,6,15,7 c8-5,15-11,20-17c0-2,1-5,1-6c0-0,0-0,0-0 c0-0,0-0,0-0c2-3,5-4,7-3c0-0,0-1,1-1 c-2-2-8-1-12,4c-3,5-6,6-6,6c-2,0-3,0-4,0 c-0-0-0-0-0-0c-0-2-3-4-6-4l-0-2l-3,1l0,2 c-2,1-3,4-2,7c0,0,0,0,0,0c-4,1-11,2-16,2 c-8-0-8,6-8,6l9-2C125,896,127,896,128,897z';
        obj1[1] = 'M177,903 214,864 186,888 177,872 181,892 167,904 160,889 168,880 158,885 140,842 152,878 134,874 154,884 164,915 171,915 175,905 190,903';
        obj1[2] = 'M173,924l-2-9l-8-4l-5-9 l-0,11l-7,3l-0,3l-16,13l2,3l6-0l10-0l2-2l3,1l7-1 l1-2l4-1l10,3L173,924z';
        obj1[3] = 'M102,924c42,0,79-13,96-32 l-1-10l-19-6l-9,4l-6-6l-20-11l-11,3l-1,37l-8,5l-6-2 l-8,2l-5,17C100,924,101,924,102,924z';
        obj1[4] = 'M196,909l-27-60l2-3l-2-2 l2-1l-7-3l0,6l-14,16l1,11l0-9l13-11l2,0l2,5 l-2,44l3-7l0,3l2-30l0,1c0,7,2,21,2,21 c0-0,0-9,0-14l13,34L196,909z';

        obj2[0] = 'M176,873c0,0-92,25-89,38 c3,13,43,1,56-8C157,895,176,873,176,873z';
        obj2[1] = 'M135,907 164,913 164,915 171,915 145,929 112,932 145,925 160,916 151,912 145,914 147,911';
        obj2[2] = 'M164,927 159,927 155,929 155,931 141,931 140,930 150,922 139,929 138,929 133,933 137,932 134,935 155,931 155,932 158,934 163,932 166,930';
        obj2[3] = 'M188,900l-14-21l-4,1 c0,0,7,19,7,20c-0,0-6,1-6,1l-18-6l-2-17l-3,13l-8-21 l-3,2l0,13l-43,12l-6,9l-43,6l-6,6l67,1l9-0 C142,922,170,913,188,900z';
        obj2[4]= 'M189,905 100,921 96,944 107,925 196,909';
// Frank Herbert is a genius.
        dune3[0] = 'M789.651,612.665c-75.205-13.229-180.045,29.189-247.215,32.078c-67.168,2.892-214.902-55.596-254.981-57.02c-80.609-2.861-205.862,94.49-292.672,100.213c-15.255,1.007-30.625-0.204-46.191-2.981v364.425l1091.444-8.328V687.689C964.066,678.827,883.855,629.24,789.651,612.665z';
        dune3[1] = 'M-132,707c93-1,328-89,431-72 c102,17,188,72,270,68c81-4,199-87,275-85s268,142,268,142 v254H-98L-132,707z';
        dune3[2] = 'M1231.049,614.778c-106.1-3.109-270.963,102.704-385.223,108.925c-114.258,6.229-233.418-65.354-377.06-87.139c-99.948-15.158-239.281,33.44-328.552,36.751c-89.269,3.313-285.609-63.696-338.877-65.326c-107.132-3.277-14.89,534.698-14.89,534.698l1120.001-20.622C906.449,1122.064,1337.147,617.889,1231.049,614.778z';
        dune3[3] = 'M-47.384,729.587l16.5,334.482H1082.06l-7.499-400.48c0,0-143.994,46.509-293.986,48.009c-138.278,1.383-269.985-73.507-410.979-102.005S-47.384,729.587-47.384,729.587';

        dune31[0] =  'M730.696,695.521c-14.66-64.234,54.479-83.549,53.738-83.668c-74.773-10.486-176.365,30.068-241.998,32.891c-65.18,2.806-206.219-52.184-251.139-56.739c10.547,3.674,18.777,12.776,20.959,31.223c5.711,48.342-25.114,246.768-200.632,410.215l572.048,6.992h0.246c157.754-55.303,336.631-126.377,336.631-164.342C1020.549,804.177,747.467,768.968,730.696,695.521z';
        dune31[1] =  'M569,702 c-81,4-167-51-270-68c-90-14-282,51-391,68l-6,301l0,8h750 C841,871,874,687,868,644c-2-15-9-23-19-26c-1-0-2-0-3-0 C769,615,651,698,569,702z';
        dune31[2] =  'M390.417,731.489c-19.484-73.591,72.4-95.72,71.42-95.854c-99.376-12.017-234.395,34.446-321.621,37.682c-54.263,2.01-148.083-21.957-225.287-41.429c5.73,98.433,58.558,405.557,495.521,392.111c96.733-2.977,150.2,2.841,173.166,14.275c110.086-40.351,192.021-78.959,192.021-104.494C775.637,855.974,412.705,815.635,390.417,731.489z';
        dune31[3] =  'M1143.557,771.596C842.766,774.434,590.294,994.69,563.871,1018.5H281.277c219.414-27.692,269.289-134.762,270.71-200.116c1.5-68.996-181.491-76.496-295.484-116.994c-107.063-38.035,57.096-89.3,77.455-95.395C186.829,603.571-47.384,729.587-47.384,729.587l14.307,321.913l1176.634,27.58C1143.557,1079.08,1461.541,768.596,1143.557,771.596z';

        dune32[0] = 'M312.256,619.224c-2.186-18.486-10.448-27.592-21.027-31.25c-1.286-0.119-2.543-0.203-3.773-0.246c-80.611-2.863-205.862,94.489-292.671,100.211c-15.255,1.007-30.627-0.204-46.193-2.981v369.479H83.292C283.871,886.871,318.262,670.06,312.256,619.224z';
        dune32[1] = 'M296,634 c-104-14-335,72-428,73l33,306h296c150-49,320-113,320-147 c0-60-259-92-275-158C229,651,283,636,296,634z';
        dune32[2] = '';
        dune32[3] = '';

// His War of the Worlds is a masterpiece.

        xtypes[0] = 438473426514619468937593363674906600980101972218980261389738755026321310;
        xtypes[1] = 1528428735494740386746687706769036728542265312936553054402188188078571243;
        xtypes[2] = 1576159433658212066304323894815932062177799089437395523990699050641915806;
        xtypes[3] = 1638277479168345925933593678264841420808332802796276121428815506753716126;
        xtypes[4] = 1482277213785937432487838137602393875317079519468030334287176488800222955;
        xtypes[5] = 569254049910285240562266942057277174170434705955446158280559749706542294;
        xtypes[6] = 695961355261660318153968727586838433117983201812599465335857818068058111;
        xtypes[7] = 1499951127606893309180610179916526153806597374206025036948893607141571007;
        xtypes[8] = 1487975643258097207966143169235216509055880303550960490725369271497513569;
        xtypes[9] = 893871907223691020346594411790439061317907470229888515211998968157829111;
        xtypes[10] = 1456322660702981972363882139452691332072845879862426480408917545756655090;
        xtypes[11] = 1414100953265237643112910920600703942226523030837917351177428632577495874;
        xtypes[12] = 1412526850302830771701738382967853559447456676243931652623233627352724185;
        xtypes[13] = 956176030089680310714094738241368283497248873645169781803481032958345082;
        xtypes[14] = 407203048447432245888292259364249687668615656070679106091707478370827939;
        xtypes[15] = 720473443048720196433395035253138729115353664155452813862022957330631299;
        xtypes[16] = 1219326055746586710817491577091388615;
    
        pos = (params[1]-1) * 5;
        colors[0] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
    
        pos = (params[1]-1) * 5 + 1;
        colors[1] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[1]-1) * 5 + 2;
        colors[2] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[1]-1) * 5 + 3;
        colors[3] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[1]-1) * 5 + 4;
        colors[4] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
// Who's stronger, the camel or the Bedouin?        
        
        parts[0] = '<svg version="1.1" id="Layer_2" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 1000 1000" enable-background="new 0 0 1000 1000" xml:space="preserve"> <linearGradient id="mainGradient" gradientUnits="userSpaceOnUse" x1="-162.3992" y1="118.0994" x2="-162.3993" y2="1117.9104" gradientTransform="matrix(1 0 0 -1 662.3999 1118.0991)"> <stop offset="0.64" style="stop-color:#'; // 2
        parts[1] = '"/> <stop offset="1" style="stop-color:#'; // 3
        parts[2] = '"/> </linearGradient> <rect x="0.001" y="0.189" fill="url(#mainGradient)" width="1000" height="1000"/> <circle opacity="0.1" fill="#'; // 1
        parts[3] = string(abi.encodePacked('" cx="44" cy="823" r="99"/> <radialGradient id="sunGradient" ',getSun(params[7]*2-2),' gradientUnits="userSpaceOnUse"> <stop offset="0.7" style="stop-color:#')); // 1
        parts[4] = '"/> <stop offset="1" style="stop-color:#'; // 2
        parts[5] = string(abi.encodePacked('"/> </radialGradient> <circle opacity="0.8" fill="url(#sunGradient)" ',getSun(params[7]*2-2),'/>')); // 1
        parts[6] = ''; // 1
        parts[7] = ''; // 2
        parts[8] = ''; // 1
        parts[9] = ''; // 1
        parts[10] = ''; // 2
        parts[11] = ''; // 1
        parts[12] = ''; // 1
        parts[13] = ''; // 2
        parts[14] = '<g> <path opacity="0.11" fill="#'; // 1
        parts[15] = '" d="M668,423c0,0,313-0,303-28 c-10-28-397-48,15-46c301,2,196,46,460,43 c258-3,484-60,485-17c1,43-290,24-290,50s288,9,478,12 c189,3,341-83,535-26c194,56,322,32,517,5 c194-27,140,0,427,0c287,0,1180,0,1180,0v-31H3607c0,0-137-11-283-10 c-146,0-162,33-394-7c-232-41-312-43-420-24 c-107,18-255,68-395,74s-397,18-398,7c-1-10,447-26,446-65 c-1-38-176-42-391-25c-215,16-395-14-568-19 c-172-4-626-8-627,25s323,25,322,50c-0,9-593,3-593,3H-36v27 h478C442,421,553,423,668,423z"/> <path opacity="0.11" fill="#'; // 1
        parts[16] = '" d="M668,404c0,0,322,12,312-15 c-10-28-804-56,8-62c301-2,239,37,503,34 c258-3,565-42,569,1c2,29-381,32-417,61 c-23,18,273,12,470,7c189-5,513-94,714-52 c212,44,184,46,379,18c194-27,188,1,475,1c287,0,1096,0,1096,0 v-20c0,0-1102,0-1175,0s-137-13-284-13c-146,0-161,25-393-16 c-232-41-315-31-422-12c-107,18-250,68-389,74s-432,24-432,13 c0-13,458-25,473-71c12-37-172-54-387-38 c-215,16-395-14-568-19c-172-4-620,7-621,41 c-1,34,319,32,321,51c0,9-598-12-598-12H-36v27h478 C442,403,553,404,668,404z"/> <animateMotion path="M 0 0 L -3750 40 Z" dur="250s" repeatCount="indefinite" /> </g> <path opacity="0.25" fill="#'; // 5
        parts[17] = string(abi.encodePacked('" d="',getFarObject(params[5]),'"/> <path fill="#')); // 5
        parts[18] = string(abi.encodePacked('" d="',getDune1(params[3]),'"/> <g> <path fill="#')); // 4
        parts[19] = string(abi.encodePacked('" d="',getCamel(params[0]),'"/> <animateMotion path="m 0 0 h -5000" dur="2500s" repeatCount="indefinite" /> </g> <path fill="#')); // 4
        parts[20] = string(abi.encodePacked('" d="',getDune2(params[4]),'"/> <path fill="#')); // 2
        parts[21] = string(abi.encodePacked('" d="',dune3[params[2]-1],'"/> <linearGradient id="sandGradient" gradientUnits="userSpaceOnUse" x1="-1424" y1="658" x2="-456" y2="658" gradientTransform="matrix(1 0 0 1 1324.7998 158.1992)"> <stop offset="0" style="stop-color:#')); // 2
        parts[22] = '"/> <stop offset="0.8" style="stop-color:#'; // 3
        parts[23] = string(abi.encodePacked('"/> </linearGradient> <path opacity="0.35" fill="url(#sandGradient)" d="',dune31[params[2]-1],'"/> <path opacity="0.35" fill="#')); // 3
        parts[24] = string(abi.encodePacked('" d="',dune32[params[2]-1],'"/> <path opacity="0.1" fill="#')); // 3
        parts[25] = string(abi.encodePacked('" d="',obj2[params[6]-1],'"/> <path opacity="0.4" fill="#')); // 3
        parts[26] = string(abi.encodePacked('" d="',obj1[params[6]-1],'"/> </svg> '));

// Stronger is the earthworm.

        string memory output = string(abi.encodePacked(parts[0],colors[1],parts[1],colors[2],parts[2]));
        output = string(abi.encodePacked(output,colors[0],parts[3],colors[0],parts[4],colors[1] ));
         
        output = string(abi.encodePacked(output,parts[5],colors[0],parts[6],colors[0] ));
         
        output = string(abi.encodePacked(output,parts[7],colors[1],parts[8],colors[0]));
         
        output = string(abi.encodePacked(output,parts[9],colors[0],parts[10],colors[1] ));
        output = string(abi.encodePacked(output,parts[11],colors[0],parts[12],colors[0]));
        output = string(abi.encodePacked(output,parts[13],colors[1],parts[14],colors[0] ));
        output = string(abi.encodePacked(output,parts[15],colors[0],parts[16],colors[4]));
        output = string(abi.encodePacked(output,parts[17],colors[4],parts[18],colors[3] ));
        output = string(abi.encodePacked(output,parts[19],colors[3],parts[20],colors[1]));
        
        output = string(abi.encodePacked(output,parts[21],colors[1],parts[22],colors[2]));
        output = string(abi.encodePacked(output,parts[23],colors[2],parts[24],colors[2]));
        output = string(abi.encodePacked(output,parts[25],colors[2],parts[26]));

// please don't scold me for the quality of my code, I've been programming in PHP for 10 years
        
        string[11] memory aparts;
        aparts[0] = '[{ "trait_type": "Main", "value": "';
        aparts[1] = toString(params[0]);
        aparts[2] = '" }, { "trait_type": "Palette", "value": "';
        aparts[3] = toString(params[1]);
        aparts[4] = '" }, { "trait_type": "Near Object", "value": "';
        aparts[5] = toString(params[6]);
        aparts[6] = '" }, { "trait_type": "Far Object", "value": "';
        aparts[7] = toString(params[5]);
        aparts[8] = '" }, { "trait_type": "Sun", "value": "';
        aparts[9] = toString(params[7]);
        aparts[10] = '" }]';
// they're going to make me squeeze Doom into the next collection
// help...
        string memory strparams = string(abi.encodePacked(aparts[0], aparts[1], aparts[2], aparts[3], aparts[4], aparts[5]));
        strparams = string(abi.encodePacked(strparams, aparts[6], aparts[7], aparts[8], aparts[9], aparts[10]));

// they made me write this code

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "OnChain Sands", "description": "Beautiful views, completely generated OnChain","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function claimdQw4w9WgXcQ() public  {
        require(_tokenIdCounter.current() <= 500, "Tokens number to mint exceeds number of public tokens");
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    }
    // why are you reading this? is there something between us?
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

// they won't fall for it a second time
    function buySands(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

