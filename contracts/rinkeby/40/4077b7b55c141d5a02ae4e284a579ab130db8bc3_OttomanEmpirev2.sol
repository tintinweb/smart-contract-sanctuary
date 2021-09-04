/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract OttomanEmpirev2 {

    string[] private Donanma_Gucu = [
        "Donanma Gucu:1",       // 0
        "Donanma Gucu:2",       // 1
        "Donanma Gucu:3",       // 2
        "Donanma Gucu:4",       // 3
        "Donanma Gucu:5",       // 4
        "Donanma Gucu:6",       // 5
        "Donanma Gucu:7",       // 6
        "Donanma Gucu:8",       // 7
        "Donanma Gucu:9",       // 8
        "Donanma Gucu:10",      // 9
        "Donanma Gucu:20",      // 10
        "Donanma Gucu:30",      // 11
        "Donanma Gucu:40",      // 12
        "Donanma Gucu:50",      // 13
        "Donanma Gucu:60",      // 14
        "Donanma Gucu:70",      // 15
        "Donanma Gucu:99",      // 16
        "Donanma Gucu:100"      // 17
    ];
    
    string[] private SuvariListesi = [
        "Suvari Gucu:1",          // 0
        "Suvari Gucu:2",          // 1
        "Suvari Gucu:3",          // 2
        "Suvari Gucu:4",          // 3
        "Suvari Gucu:5",          // 4
        "Suvari Gucu:6",          // 5
        "Suvari Gucu:7",          // 6
        "Suvari Gucu:8",          // 7
        "Suvari Gucu:9",          // 8
        "Suvari Gucu:10",         // 9
        "Suvari Gucu:20",         // 10
        "Suvari Gucu:30",         // 11
        "Suvari Gucu:40",         // 12
        "Suvari Gucu:99",         // 13
        "Suvari Gucu:100"         // 14
    ];
    
    string[] private PiyadeListesi = [
        "Piyade Gucu:1",         // 0
        "Piyade Gucu:2",         // 1
        "Piyade Gucu:3",         // 2
        "Piyade Gucu:4",         // 3
        "Piyade Gucu:5",         // 4
        "Piyade Gucu:6",         // 5
        "Piyade Gucu:7",         // 6
        "Piyade Gucu:8",         // 7
        "Piyade Gucu:9",         // 8
        "Piyade Gucu:10",        // 9
        "Piyade Gucu:20",        // 10
        "Piyade Gucu:30",        // 11
        "Piyade Gucu:40",        // 12
        "Piyade Gucu:99",        // 13
        "Piyade Gucu:100"        // 14
    ];
    
    string[] private PolitikListesi = [
        "Politik Gucu:1",          // 0
        "Politik Gucu:2",          // 1
        "Politik Gucu:3",          // 2
        "Politik Gucu:4",          // 3
        "Politik Gucu:5",          // 4
        "Politik Gucu:6",          // 5
        "Politik Gucu:7",          // 6
        "Politik Gucu:8",          // 7
        "Politik Gucu:9",          // 8
        "Politik Gucu:10",         // 9
        "Politik Gucu:20",         // 10
        "Politik Gucu:30",         // 11
        "Politik Gucu:40",         // 12
        "Politik Gucu:99",         // 13
        "Politik Gucu:100"         // 14
    ];
    
    string[] private EkonomikListe = [
        "Ekonomik Gucu:1",         // 0
        "Ekonomik Gucu:2",         // 1
        "Ekonomik Gucu:3",         // 2
        "Ekonomik Gucu:4",         // 3
        "Ekonomik Gucu:5",         // 4
        "Ekonomik Gucu:6",         // 5
        "Ekonomik Gucu:7",         // 6
        "Ekonomik Gucu:8",         // 7
        "Ekonomik Gucu:9",         // 8
        "Ekonomik Gucu:10",        // 9
        "Ekonomik Gucu:11",        // 10
        "Ekonomik Gucu:12",        // 11
        "Ekonomik Gucu:13",        // 12
        "Ekonomik Gucu:99",        // 13
        "Ekonomik Gucu:100"        // 14
    ];
    
    string[] private SavunmaListe = [
        "Savunma Gucu:1",       // 0
        "Savunma Gucu:2",       // 1
        "Savunma Gucu:3",       // 2
        "Savunma Gucu:4",       // 3
        "Savunma Gucu:5",       // 4
        "Savunma Gucu:6",       // 5
        "Savunma Gucu:7",       // 6
        "Savunma Gucu:8",       // 7
        "Savunma Gucu:9",       // 8
        "Savunma Gucu:10",      // 9
        "Savunma Gucu:10",      // 10
        "Savunma Gucu:12",      // 11
        "Savunma Gucu:13",      // 12
        "Savunma Gucu:99",      // 13
        "Savunma Gucu:100"      // 14
    ];
    
    string[] private SilahListe = [
        "Gurz",          // 0
        "Sesper",        // 1
        "Mizrak",        // 2
        "Kargi",         // 3
        "Cirit",         // 4
        "Kulunk",        // 5
        "Kilic",         // 6
        "Yatagan",       // 7
        "Pala",          // 8
        "Kama",          // 9
        "Hancer",        // 10
        "Teber",         // 11
        "Sasmir",        // 12
        "Ok-Yay"         // 13
    ];
    
    string[] private YuzukListe = [
        "Altin",           // 0
        "Gumus",           // 1
        "Bronz",           // 2
        "Platinyum",       // 3
        "Titanyum"         // 4
    ];
    
    string[] private EkstraGuc2 = [
     
        "+",                 // 1
        " ",                 // 2
        " ",                 // 3
        " ",                 // 4
        " ",                 // 5
        " ",                 // 6
        " ",                 // 7
        " ",                 // 8
        " ",                 // 9
        " ",                 // 10
        " ",                 // 11
        " ",                 // 12
        " ",                 // 13
        " ",                 // 14
        " ",                 // 15
        " ",                 // 16
        " "                  // 17

    ];
    
    string[] private EkstraGuc1 = [
        "+",                 // 1
        " ",                 // 2
        " ",                 // 3
        " ",                 // 4
        " ",                 // 5
        " ",                 // 6
        " ",                 // 7
        " ",                 // 8
        " ",                 // 9
        " ",                 // 10
        " ",                 // 11
        " ",                 // 12
        " ",                 // 13
        " ",                 // 14
        " ",                 // 15
        " ",                 // 16
        " "                  // 17
        
    ];
    
    
    string[] private Padisahliste = [
       "Osman Gazi (1299/1326)",                     // 1
        "Orhan Gazi (1326/1359)",                    // 2
        "I. Murad (1359/1389)",                      // 3
        "I. Bayezid / Yildirim Bayezid (1389/1402)", // 4
        "I. Mehmed (1413/1421)",                     // 5
        "II. Murad (1421/1451)",                     // 6
        "Fatih Sultan Mehmed (1451/1481)",           // 7
        "II. Bayezid (1481/1512)",                   // 8
        "Yavuz Sultan Selim (1512/1520)",            // 9
        "Kanuni Sultan Suleyman (1520/1566)",        // 10
        "II. Selim (1566/1574)",                     // 11
        "III. Murad (1574/1595)",                    // 12
        "III. Mehmed (1595/1603)",                   // 13
        "I. Ahmed (1603/1617)",                      // 14
        "I. Mustafa (1617/1618 / 1622/1623)",        // 15
        "Genc Osman (1618/1622)",                    // 16
        "IV. Murad (1623/1640)",                     // 17
        "Ibrahim (1640/1648)",                       // 18
        "IV. Mehmed (1648/1687)",                    // 19
        "II. Suleyman (1687/1691)",                  // 20
        "II. Ahmed (1691/1695",                      // 21
        "II. Mustafa (1695/1703)",                   // 22
        "III. Ahmed (1703/1730)",                    // 23
        "I. Mahmud (1730/1754)",                     // 24
        "III. Osman (1754/1757)",                    // 25
        "III. Mustafa (1757/1774)",                  // 26
        "I. Abdulhamid (1774/1789)",                 // 27
        "III. Selim (1789/1807)",                    // 28
        "IV. Mustafa (1807/1808)",                   // 29
        "II. Mahmud ( 1808/1839)",                   // 30
        "Abdulmecid (1839/1861 )",                   // 31
        "Abdulaziz (1861/1876)",                     // 32
        "V. Murad (30 Mayis 1876/31 Agustos 1876 )", // 33
        "II. Abdulhamid (1876/1909)",                // 34
        "Mehmed Resad ( 1909/1918)",                 // 35
        "Mehmed Vahdeddin (1918/1922)"               // 36
    ];
    
        string[] private Savasliste = [
        // <no name>            // 0
        "Savas Gucu:1",         // 1
        "Savas Gucu:2",         // 2
        "Savas Gucu:3",         // 3
        "Savas Gucu:4",         // 4
        "Savas Gucu:5",         // 5
        "Savas Gucu:6",         // 6
        "Savas Gucu:7",         // 7
        "Savas Gucu:8",         // 8
        "Savas Gucu:9",         // 9
        "Savas Gucu:10",        // 10
        "Savas Gucu:11",        // 11
        "Savas Gucu:12",        // 12
        "Savas Gucu:13",        // 13
        "Savas Gucu:14",        // 14
        "Savas Gucu:15",        // 15
        "Savas Gucu:16",        // 16
        "Savas Gucu:99",        // 17
        "Savas Gucu:100"        // 18
    ];
    
    
    string[] private EkstraGuc3 = [
        "+",                 // 1
        " ",                 // 2
        " ",                 // 3
        " ",                 // 4
        " ",                 // 5
        " ",                 // 6
        " ",                 // 7
        " ",                 // 8
        " ",                 // 9
        " ",                 // 10
        " ",                 // 11
        " ",                 // 12
        " ",                 // 13
        " ",                 // 14
        " ",                 // 15
        " ",                 // 16
        " "                  // 17
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function Savas_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "SAVAS GUCU", Savasliste);
    }
    
    function Osmanli_Donanma_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "DONANMA GUCU", Donanma_Gucu);
    }
    
    function Suvari_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "SUVARIGUCU", SuvariListesi);
    }
    
    function Piyade_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "PIYADE GUCU", PiyadeListesi);
    }
    
    function Politik_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "POLITIK GUCU", PolitikListesi);
    }

    function Ekonomik_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "EKONOMIK GUCU", EkonomikListe);
    }
    
    function Savunma_Gucu(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "SAVUNMA GUCU", SavunmaListe);
    }
    
    function Silah(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "SILAH", SilahListe);
    }
    
    function Yuzuk(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "YUZUK", YuzukListe);
    }
    
    function ___Padisah___(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "PADISAH", Padisahliste);
    }
    
    function pluckName(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", EkstraGuc2[rand % EkstraGuc2.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = EkstraGuc1[rand % EkstraGuc1.length];
            // name[1] = EkstraGuc3[rand % EkstraGuc3.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ',  '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', '" ', output));
            }
        }
        return output;
    }

    function pluck(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (uint256[5] memory) {
        uint256[5] memory components;
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        
        components[0] = rand % sourceArray.length;
        components[1] = 0;
        components[2] = 0;
        
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % EkstraGuc2.length) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % EkstraGuc1.length) + 1;
            components[3] = (rand % EkstraGuc3.length) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
    }
    
    
    
    // https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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