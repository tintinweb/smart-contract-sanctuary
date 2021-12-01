// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
*/
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";



library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}





contract ChristmasPresents2021 is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for uint8;

    mapping(address => uint256) private mintCount;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply = 6000;
        // Allow for starting/pausing sale
    bool public hasSaleStarted = false;


   string[] private presentColors = ["527494", "003399", "83D0F5", "009FE3", "9E103F", "584998", "E2023F", "FF66D2","3D9941", "AAF2AD" , "951B81", "FBBA00", "3E3F92", "F0A3B7", "D1DD75", "CCCC33"];
   uint8[] private presentColorsWeights = [100,90,80,70,60,50,40,30,20,10,5,110,120,130,140,150];
   string[] private symbols = ["ffe300", "d4edf9", "55ff99", "ff5555","fffbba", "d0ffb7", "ffaaaa", "ffc0e4", "fbd6a3", "e6aff7", "dbfbf6", "ff817b", "cdcafa"];
   uint8[] private symbolsWeights = [100,70,30,3,100,70,80,60,50,40,50,120,90];
   string[] private backgrounds = ["fffbba", "d0ffb7", "ffaaaa", "ffc0e4", "fbd6a3", "e6aff7", "dbfbf6", "ff817b", "cdcafa"];
   uint8[] private backgroundsWeights = [100,70,80,60,50,40,20,110,90];
   string[] private ribbons = ["47ea31", "ff00ff", "ffd815", "ff6600", "31c5ea", "800080", "ff0000","0000ff"];
   uint8[] private ribbonsWeights = [100,70,80,60,50,40,20,30];
   string[] private patterTypes= [
                        '<path class="c" d="M 41,87 C 42,76 52,81 54,73 60,53 57,45 70,41 c 1,-0.3 0.8,-5 5.0,-5.3 5.2,0.55 2,6 3,6.5 5.3,2.5 7,4.7 7.4,8.5 0.3,4.7 -2,11 -2,25 -0,6 9,8 11,16 -19,2 -36,0 -53,-5 z"/><path class="c" d="m 60,96 12,1.47 c 0,0 4,4.7 -7,4 -4,-1 -7.8,-4 -4,-5.9 z"/>',
                  '<polygon class="c" points="47.7 40.6 24.7 45.5 31.9 23.1 47.7 40.6"/><polygon class="c" points="116.8 114.9 93.8 119.9 101 97.5 116.8 114.9"/>',
                  '<rect class="c" x="24.5" y="28.9" width="21.1" height="21.07"/><rect class="c" x="94.5" y="98.5" width="21.1" height="21.07"/>',
                  '<polygon class="c" points="55.4 61.3 40.7 59.1 30.5 70 28.1 55.3 14.6 49 27.8 42.1 29.6 27.4 40.2 37.8 54.9 35 48.2 48.3 55.4 61.3"/><polygon class="c" points="105.8 132.4 98.8 119.3 84 117.6 94.3 106.9 91.4 92.3 104.8 98.8 117.7 91.5 115.6 106.2 126.6 116.3 111.9 118.9 105.8 132.4"/>',
                  '<circle class="c" cx="35" cy="105" r="8.5"/><circle class="c" cx="105" cy="34.4" r="8.5"/>',
                  '<rect class="c" y="30.5" width="140" height="21.33"/><rect class="c" y="86.6" width="140" height="21.33"/>',
                  '<polygon class="c" points="52.6 0 52.6 140 31.3 140 31.3 0 52.6 0"/><polygon class="c" points="108.7 0 108.7 140 87.4 140 87.4 0 108.7 0"/>',
                  '<polygon class="c" points="49 44 56 42 49 38 54 28 43 30 43 19 34 26 29 20 28 28 17 25 22 37 14 42 19 44 14 51 27 50 29 63 35 57 38 61 41 52 54 54 49 44"/><polygon class="c" points="118 102 125 99 118 95 123 85 112 87 112 77 104 83 98 78 97 85 86 82 91 95 83 99 88 102 83 108 97 107 99 120 104 115 108 119 110 110 124 112 118 102"/>',
                  '<polygon class="c" points="62 40 83 45 52 14 22 45 41 41 22 62 41 56 22 80 46 67 46 92 48 92 56 92 58 92 59 67 83 80 61 55 83 62 62 40"/>',
                  '<path class="c" d="M123.6,93l-13,6.9c-2.3-3.2-6.6-5.3-11.5-5.3s-9.8,2.4-11.9,5.9l-13.3-7,.9,23.5,12.3-7.7c2,3.6,6.6,6.1,12,6.1s10-2.6,12-6.2l11.7,7.3Z"/><path class="c" d="M65.6,23.4,52.5,30.3C50.3,27.1,46,25,41,25s-9.7,2.4-11.8,5.9l-13.3-7,.9,23.5L29,39.7c2.1,3.6,6.7,6.1,12,6.1s10.1-2.6,12.1-6.2l11.6,7.3Z"/>',
                  '<path class="c" d="M24.5,74.3c-7.1-2.1-5.8-54.9,12.6-62.4,22.4-9.1,19.4,18.2,9.5,17.5C40,28.9,51.7,15.2,40.9,17,19.3,20.8,36.4,77.7,24.5,74.3Z"/><path class="c" d="M88.8,125.2c-6.3-2-5.1-52.8,11.3-60,19.8-8.7,17.1,17.5,8.4,16.8-5.9-.4,4.5-13.7-5.1-11.9C84.2,73.7,99.4,128.5,88.8,125.2Z"/>',
                  '<polygon class="c" points="-0,102 68,62 140,102 140,62 68,23 0,62"/>',
                  '<path class="c" d="M108.7,59.2c-.8-1.8-33.5-1.8-30.8-8.7S78,31.4,69.8,31s-10,8.5-8.2,19.5c1.4,8.3-30,6.9-30.8,8.7-1.7,3.5.7,10,4.6,11.7,6.5,2.7,33.5-19.4,20.9,9.4C52.2,89.7,40.6,88,38.8,95.4c-1.4,5.8,4.1,13.8,8.8,14,2.5.1,8.7-16.1,22.2-17.6,7.1-.7,19.6,17.7,22.2,17.6,4.6-.2,10.2-8.2,8.7-14C98.9,88,87.3,89.7,83.2,80.3c-12.6-28.8,14.4-6.7,20.9-9.4C108,69.2,110.4,62.7,108.7,59.2Z"/>',
                  '<path class="c" d="M -0.0,115.7 116,0.2 140,0 140,25 26,140 0,140 Z"/>',
                  '<path class="c" d="M 15.7,64 27,72 C 42,81 43,68 53,64 71,58 70,73 69,85 45,105 29,82 16,63 Z" /><path class="c" d="m 126,63 -15.8,8.8 C 95,81 93,67 84,64 66,57 67,72 69,85 92,105 113,81 127,63 Z"/>'
                  ];
   uint8[] private patternTypesWeights = [100,70,80,10,40,50,60,90,70,50,30,50,60,70,60];
   string[] private presentGeoms= [
                  '<path class="e" d="M128.2,171.1c54-4.8,142.2-11.4,195.6-6,8.1.8,49.8,15.8,49.2,51.6-1.2,70.2,15.6,103.8,4.2,157.2-4.9,22.7-35.9,25.6-63.6,25.8-61.2.5-70.5-15-124.8-1.8-13.3,3.2-31.2,9.3-48,.6-11.2-5.7-17-15.4-20.4-21.6-20.2-36.4-30.6-106.6-25.2-169.8C97,185.6,117.4,172.1,128.2,171.1Z"/><path class="f" d="M216.5,159.7c-11.2,9.9-3.8,28.3-4.7,36.3-9.6,84.3-4.2,131.3-6.1,195-.4,15.2,44.1,18.9,51.3,5.9,18.4-33.1-19.5-120.8,2.2-202.3,2-7.5,11-25.2,1.7-34.9S227.5,150,216.5,159.7Z"/><path class="f" d="M189.8,162.3l-42.7-13.6a16,16,0,0,1-11.1-17l1.5-14.8a16.2,16.2,0,0,1,17.9-14.3h0l1.5.2,35.6,7.4a16,16,0,0,1,7.9,4.2l6.3,6a16.1,16.1,0,0,1,4.9,12.6l-.8,14.9A16,16,0,0,1,194,163h-.2A13.4,13.4,0,0,1,189.8,162.3Z"/><path class="f" d="M326.9,165.6l-44.7-2.9a15.9,15.9,0,0,1-14.9-13.8l-2.1-14.7A16.3,16.3,0,0,1,279,115.9h1.5l36.4-1.4a16.1,16.1,0,0,1,8.6,2.1l7.6,4.4a15.6,15.6,0,0,1,7.8,10.9l2.8,14.7a16,16,0,0,1-12.6,18.8h-.2A13.5,13.5,0,0,1,326.9,165.6Z"/><ellipse class="f" cx="237.5" cy="143.3" rx="30.3" ry="26.7"/>',
                  '<path class="f" d="M245.2,162.7l-27.3-52.2a5.7,5.7,0,0,0-7.6-2.6h-.2a4.1,4.1,0,0,0-1.1.7l-18.3,15a5.8,5.8,0,0,0-1,8.1l1,1,45.6,37.1C241.2,173.9,248.2,168.3,245.2,162.7Z" transform="translate(4.1 4)"/><path class="f" d="M250.7,165,278,112.8a5.7,5.7,0,0,1,7.6-2.6h.2a4.1,4.1,0,0,1,1.1.7l18.4,15a6,6,0,0,1,.6,8.5h0l-.6.6-45.7,37.1C254.7,176.3,247.8,170.6,250.7,165Z" transform="translate(4.1 4)"/><path class="e" d="M135.8,228.6c5,35.8,31.1,171.5,44.6,177,9.3,3.8,46.7-2,54.6-2.6,33.1-2.7,75,2.6,97-2.6,12.9-4.5,27.2-122.4,26.2-190.2-2.1-26.4-5.5-37.3-9.6-39.2-11.4-12.2-129.8-2-148.8-7.2-22.3-4.9-33-11.3-44.8-7.2C129.6,159.6,132.9,207.5,135.8,228.6Z" transform="translate(4.1 4)"/><path class="f" d="M150.4,259.5c15.3,12.6,183.7-3,194.5-4,7.4-.7,15.4.4,17,2s4,16.6-5,22.5c-4.6,2.9-22,2.2-23.2,2.2-66,2.9-122.6,11-181.9,4-1.6.5-7.3,2.5-11.3-.5s-6.4-16.8-1.5-22.4S148.4,259.5,150.4,259.5Z" transform="translate(4.1 4)"/><path class="f" d="M232.4,403.4c-7.4-8.8-.3-19.1,1.7-69.5,3.8-95.3-9-141,1.7-159.9,3-5.3,25.3-6.1,25.5-3.6C264,209,263.4,335.7,251.2,397,250.5,400.4,237.8,409.9,232.4,403.4Z" transform="translate(4.1 4)"/>',
                  '<path class="f" d="M257.4,138.8c-9.7-21.3-39.8-76.5-80.4-47.4-52.3,35.3,76,123.4,91.4,98.8C275.8,182.3,264.1,153.6,257.4,138.8Zm-5.2,40.1c-32.7-4.4-80.6-57.4-60.3-69.2C226.7,89.6,258.7,174.5,252.2,178.9Z"/><path class="e" d="M193.4,199.8c106-7.7,158.9-11.5,182.4-14.4a76,76,0,0,1,30.4,1.6c21.4,5.8,46.8,23.5,52.8,48,9.2,37.2-28.3,81.6-65.6,91.2-25.2,6.5-36,9.6-88.8,9.2-14.6-.1-46,4.2-68.4,8.2-73.8,13.2-97.2,17.2-134.8,0-20.1-9.3-27.8-26.5-29.6-34.7-9.3-43.1,9.6-69.5,41-87.5C126.9,213.3,145.3,203.3,193.4,199.8Z"/><path class="f" d="M68.3,264.9c9.9-13.6,23.9,2.9,65.1.5,61.8-3.6,275-18.6,331.3-29.6,1.7,2.1,1.4,11.8-4.3,16-9.7,7.2-369.9,42.5-378.6,28.9C73.4,278,63.1,272.1,68.3,264.9Z"/><path class="f" d="M262.4,195.3c15.4,24.6,143.8-63.5,91.4-98.8-40.6-29.2-70.7,26.1-80.4,47.4C266.7,158.7,255,187.4,262.4,195.3Zm79.2-84.8c20.3,11.8-30.3,69.1-63,73.5C272.1,179.6,306.8,90.4,341.6,110.5Z"/><path class="f" d="M257.8,334.2c.2.9,4,8.5,4,8.5,9.1,4.9,26.8-.1,23.2-6.1-10.2-16.8-18.7-119.7-6.8-138.4a11.8,11.8,0,0,0-12.9-8.5c-4.8.6-11.1,3.6-11.5,4.1C239.9,212.1,250,302.6,257.8,334.2Z"/>',
                  '<path class="e" d="M397.2,304.7c11.8,78.7-62.7,132-137.9,144s-126.9-64.3-137.8-144c-10.2-74.4,62-150.2,137.8-144C332.1,166.7,384.9,223.1,397.2,304.7Z"/><path class="f" d="M118.7,315.5c5-6.6,6.9-7.1,7.1-7.2,13.4,8.9,20.5,18.1,27,18.8,42,5,230-28,243-42.9,6.2-7,4.6,13.8-3,20.2s-204.5,45.9-244.4,38.7c-14.1-1.6-30.2-26.6-29.7-27.6"/><path class="f" d="M172.5,98.7c-23.8,37.8,61.5,86.8,78.3,71.3C258.2,164.1,192.1,75.5,172.5,98.7Zm12.3,13c2.3-4.1,56.5,46.5,50.2,49.8-1.5.8-65.6-26.2-50.2-49.8"/><path class="f" d="M229.8,166.7c5.7,10.5,53.9,2.5,72.5-11.4,2.2-1.7,18.2-13.1,12.2-31.5C306.3,103.6,225.4,159.6,229.8,166.7Zm70.8-34.6h0c6.3,25.1-54.3,32.4-55.4,31.2-4.2-4.6,54.7-35.4,55.4-31.2"/><path class="f" d="M239.7,170.4c19.8,4.2,43.1-87.1,4.3-94.9C217.5,75.4,231.4,170.7,239.7,170.4Zm4.8-78.8h0c24.8,6.9,1.4,63.3-.1,63.6-6.1,1.5-4-65,.1-63.6"/><path class="f" d="M212.8,203.3c2.1,23.7-7.4,63.3-8.5,82.2-5,81.7,17.3,116.5,30.8,163,10.9,20.7,45.6,12.7,23.9-12.9-32.4-48.2-30.4-232.3-14.2-273.1C235.8,155.6,215.1,177.2,212.8,203.3Z"/>',
                  '<path class="f" d="M247.3,110c-10.9-12.2-40-56.3-60.8-37.8-28.2,51.9,69.2,78.7,78.3,71.3C272.2,137.6,255.6,119.4,247.3,110ZM198.8,85.2C206,74.7,255.3,131.7,249,135c-1.5.8-65.6-26.2-50.2-49.8"/><path class="f" d="M251.1,146.6c11.7,13,96-31.2,67.9-66.4-8.9-12.5-16-.7-23.7,6.1C282,98.2,239.9,137.3,251.1,146.6Zm57.2-54.3h0c13.5,22-42.1,47.2-43.5,46.4-5.4-3.1,41.5-50.2,43.5-46.4"/><path class="e" d="M155.4,159.9a29.8,29.8,0,0,0-12,31.2c8.7,22.5-62,189,33.8,212.5,78.1,17,170.8-20.6,173.6-22.4,48.7-33.7,8.5-138.1,6.2-208.5C368.4,127.6,181.4,142.9,155.4,159.9Z"/><path class="f" d="M123.4,284.3c-.7-18.3,163.9-14.4,228.3-32.4,3.7-1.1,14.3-4.2,21.3,1.1s4.1,13.8-2.7,20.2-231.9,22-245.7,25.5c-6.9,1.8-1-12.6-1.2-14.4"/><path class="f" d="M239.1,147.9c-11,32.2-21.8,195.7-15.1,247.7,2.8,23.6,53.1,34.4,40.4-4.8-25.5-51-19.6-131.1-1-193.3C283.2,122,247.5,137.4,239.1,147.9Z"/>'
                 ] ;
   uint8[] private presentGeomsWeights = [100,70,80,10,50];
   uint32[] private specialslist = [511 ,701 ,722 ,808 ,888 ,1075,1153,1175,1408,1430,1451,1516,1563,1843,1927,1956,1962,2013,2079,2309,2333,2349,2409,2427,2494,2510,2512,2518,2537,2617,2640,2685,2729,2753,2847,2911,2916,2965,2981,3001,3002,3056,3066,3070,3080,3111,3122,3136,3138,3158,3222,3249,3257,3277,3289,3361,3437,3604,3641,3655,3674,3682,3724,3739,3891,3939,3957,3977,3995,4013,4071,4136,4137,4197,4201,4208,4303,4305,4312,4320,4335,4340,4343,4356,4369,4446,4452,4486,4487,4521,4541,4560,4583,4604,4614,4634,4663,4668,4677,4706,4711,4734,4754,4784,4800,4825,4862,4971,5046,5059,5076,5080,5091,5101,5138,5167,5197,5206,5244,5279,5282,5287,5347,5371,5406,5436,5451,5475,5498,5518,5562,5570,5602,5607,5613,5624,5670,5694,5701,5726,5748,5761,5816,5851,5853,5873,5881,5895,5896,5902,5915,5935,5950,5954,5974,5987,5989];
   uint32[] private secondClean = [3319, 4369, 4486, 4825, 5138, 5562, 5581, 5602, 5964];
   uint32[] private thirdclean = [5562];

   string[] private santa = ['<circle style="fill:#e6e6e6" cx="45" cy="46" r="6"/> <path style="fill:#ff0000;stroke:#000000" d="M 50,43 C 86,17 91,34 95.6,61 82,57 65,58 53,60 57,56 61,50 64,45 L 50,47 50,43"/> <path style="fill:#cccccc;stroke:#000000" d="m 46,64 1.8,7.2 c 13.5,-2.8 24,-2.8 37.6,-2 3.6,0.8 7.7,1.6 11,1.8 2.8,-2.9 3,-4 3.7,-8 C 94,60 86,58 80,58 68,57 53.6,57 46,64 Z"/> <path style="fill:#cccccc;stroke:#000000;stroke-width:4" d="m 192,295 c -20,17 -17,30 1.7,43 -17,25.5 -3.9,35 20,44 -2,30.7 7.6,31 33,34 25,24 44,22 64,-0.9 26,-4.7 42,-7 35,-33 27,-7 32,-22 19,-44 23,-16 11,-30 -0.6,-41 -29,6.9 -85,17 -85.7,17 0,0 -40,-5 -87,-19 z" transform="scale(0.26458333)"/> <ellipse cx="66" cy="73" rx="1.7" ry="1"/> <ellipse cx="83" cy="73" rx="1.7" ry="1"/> <path style="fill:#808080;stroke:#000000" d="m 70,65 -0.2,5.5 c -3.9,-2.9 -10,-0.8 -14,-0.2 4.7,-2.2 9.8,-4.5 14,-5.4 z"/> <path style="fill:#808080;stroke:#000000" d="m 77,65.8 0.88,4.9 c 4.4,-2.2 8.8,-0.42 13.9,0.48 -5.5,-3.8 -8.4,-4 -14.8,-5.4 z"/> <path style="fill:#cccccc;stroke:#000000" d="m 74,80 c -1.4,13 -20,3.4 -24.6,-4.4 9.7,4.8 17.6,-1.1 24.6,4.4 z"/> <path style="fill:#cccccc;stroke:#000000" d="m 74,80 c 2.5,13 22,-0.71 24.6,-4.4 -9.2,5.5 -21.5,0 -24.6,4.4 z"/> <ellipse style="fill:#ff2a2a;stroke:#000000" cx="74" cy="77" rx="3.7" ry="2"/>'];
   
   struct Present { 
      string name;
      string description;
      string presentColor;
      string symbolColor;
      string background;
      string ribbonColor;
      uint256 patterNum;
      string patterType;
      uint256 geomNum;
      string presentGeom;
   }
  
  mapping (uint256 => Present) public presents;
    constructor() ERC721("Christmas Presents 2021", "PRESENT21") {
    }

    function randomNum(uint256 _mod, uint256 _seed) internal pure returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(_seed))) % _mod;
      return num;
    }
    
    function weightedRandom(uint8[] memory _arr,  uint256 _tokenId) internal pure returns(uint256) {
        
        uint256 weightSum;
        for (uint i = 0; i < _arr.length; i++) {
            weightSum += _arr[i];
        }

        uint256 arrSum;
        for (uint i = 0; i < _arr.length; i++) {
            uint256 randomVal = randomNum(weightSum, _tokenId);
            arrSum = arrSum + _arr[i];
            if (randomVal <= arrSum){
                return i;
            }
        }
        return 0;
    }

    function isSpecial (uint32[] memory _list, uint256 _tokenId) internal pure returns (bool){
      for (uint i; i < _list.length;i++){
          if (_list[i] == uint(_tokenId))
          return true;
      }
      return false;
  }
    
    function randomPresent(uint256 _tokenId) internal view returns (Present memory){
        uint256 supply = _tokenId;
        Present memory newPresent;
        newPresent.name = string(abi.encodePacked('ChristmasPresent #', uint256(supply).toString()));
        newPresent.description = "Mistery Christmas Present";


        if (isSpecial(specialslist,_tokenId)){
          supply = _tokenId + 9999;
        }
        if (isSpecial(secondClean,_tokenId)){
          supply = _tokenId * 2 + 888;
          newPresent.symbolColor = 'santa';
          newPresent.patterNum = 88;
          newPresent.patterType = santa[0];
                 } else {
        newPresent.symbolColor = symbols[weightedRandom(symbolsWeights,supply)];
        newPresent.patterNum = weightedRandom(patternTypesWeights,supply);
        newPresent.patterType = patterTypes[newPresent.patterNum];
                 }
        if (isSpecial(thirdclean,_tokenId)){
          supply = _tokenId * 5;
        }
        
        newPresent.presentColor = presentColors[weightedRandom(presentColorsWeights,supply)];

        newPresent.background = backgrounds[weightedRandom(backgroundsWeights,supply)];
        newPresent.ribbonColor = ribbons[weightedRandom(ribbonsWeights,supply)];

        newPresent.geomNum = weightedRandom(presentGeomsWeights,supply);
        newPresent.presentGeom = presentGeoms[newPresent.geomNum];
        return newPresent;
    }
    
    function mint() public {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < maxSupply, "error - max supply");
        if (msg.sender != owner()) {
            require(mintCount[msg.sender] < 3, "You can only claim three times");
        }
        //for (uint i = 0; i < 100; i++) {
          mintCount[msg.sender] = mintCount[msg.sender] + 1;
      //  presents[_tokenIdCounter.current()] = newPresent;
          _safeMint(msg.sender, _tokenIdCounter.current());
          _tokenIdCounter.increment();
        //}
    }
    
    //change to internal before publishing
  function buildImage(uint256 _tokenId) internal view returns(string memory) {
      Present memory currentPresent = randomPresent(_tokenId);
      return  string(abi.encodePacked('data:image/svg+xml;base64,',Base64.encode(bytes(
          abi.encodePacked(
              '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500"><defs><style>.b {fill: #',
              currentPresent.presentColor,
              ';}.c {fill: #',
              currentPresent.symbolColor,
              ';}.d {fill: #',
              currentPresent.background,
              ';}.e, .f {stroke: #1e1e1c;stroke-width: 5px;}.e {fill: url(#a);}.f {fill: #',
              currentPresent.ribbonColor,
              ';}</style><pattern id="a" width="125" height="125" patternUnits="userSpaceOnUse" viewBox="0 0 140 140"><rect class="b" width="140" height="140"/>',
              currentPresent.patterType,
              '</pattern></defs><rect class="d" width="500" height="500"/>',
              currentPresent.presentGeom,
              '</svg>'
              )))));
  }
  
  function buildMetadata(uint256 _tokenId) internal view returns(string memory) {
      Present memory currentPresent = randomPresent(_tokenId);
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentPresent.name,
                          '", "description":"', 
                          currentPresent.description,
                          '", "image": "', 
                          buildImage(_tokenId),
                          '", "attributes": [{"trait_type": "presentColor","value": "',
                          currentPresent.presentColor,
                          '"},{"trait_type": "symbolColor","value": "',
                          currentPresent.symbolColor,
                          '"},{"trait_type": "background","value": "',
                          currentPresent.background,
                          '"},{"trait_type": "ribbonColor","value": "',
                          currentPresent.ribbonColor,
                          '"},{"trait_type": "pattern","value": "',
                          currentPresent.patterNum.toString(),
                          '"},{"trait_type": "shape","value": "',
                          currentPresent.geomNum.toString(),
                          '"}]',
                          '}')))));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  }

    //only owner
    function setStartSale() public onlyOwner {
      hasSaleStarted = true;
    }
    //only owner
    function setPauseSale() public onlyOwner {
      hasSaleStarted = false;
    }
        //only owner
    function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
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






}