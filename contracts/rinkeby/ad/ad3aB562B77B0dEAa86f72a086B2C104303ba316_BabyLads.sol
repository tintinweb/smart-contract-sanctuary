// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./library/Base64.sol";

// Baby Lads are inspired by Lanton @ Larva Lads

contract BabyLads is ERC721, Ownable {
    constructor() ERC721("BabyLads", "BL") Ownable() {}

    mapping(uint256 => address) private ladDNA;

    uint256 private maxSupply = 6969;
    uint256 private _counter = 1;

    struct Layers {
        uint256 baseColor;
        uint256 bodyType;
        uint256 glasses;
        uint256 hat;
        uint256 accessory;
    }

    string[8] private baseColors = [
        "#AE8B61",
        "#DBB181",
        "#E8AA96",
        "#FFC2C2",
        "#EECFA0",
        "#C9CDAF",
        "#D5C6E1",
        "#EAD9D9"
    ];
    string[7] private types = [
        '<path fill="#000" d="M264 256h12v4h-12zm-4-4h4v4h-4z"/>',
        '<path fill="#000" d="M264 256h12v4h-12zm-4 4h4v4h-4z"/>',
        '<path fill="#72985E" d="M228 268h4v20h-4zm-4 4h4v16h-4zm-4 4h4v12h-4zm-4 4h4v8h-4zm16 0h16v8h-16zm8-20h8v20h-8zm-8 4h8v16h-8zm16-40h20v64h-20zm20 0h16v52h-16zm0 52h4v8h-4zm4 0h4v8h-4zm-4 8h4v4h-4zm-12-72h12v4h-12zm4 4h12v4h-12zm-8 4h24v4h-24z"/><path fill="#000" d="M264 256h12v4h-12zm4-12h8v4h-8zm12-8h4v4h-4z"/><path fill="red" d="M276 236h4v4h-4z"/><path fill="#000" d="M261 236h4v4h-4z"/><path fill="red" d="M257 236h4v4h-4z"/><path fill="#445B38" d="M224 272h4v16h-4zm20 12h4v4h-4zm8-12h32v4h-32zm5-40h8v4h-8zm0 8h4v4h-4zm19 0h4v4h-4zm-12 20h4v4h-4zm12-28h8v4h-8zm-20 44h20v4h-20zm-24-12h4v24h-4zm8-4h4v28h-4zm-24 20h4v8h-4z"/>',
        '<path fill="#C8FBFB" d="M228 268h4v20h-4zm-4 4h4v16h-4zm-4 4h4v12h-4zm-4 4h4v8h-4zm16 0h16v8h-16zm8-20h8v20h-8zm-8 4h8v16h-8zm16-40h20v64h-20zm20 0h16v52h-16zm0 52h4v8h-4zm4 0h4v8h-4zm-4 8h4v4h-4zm-12-72h12v4h-12zm4 4h12v4h-12zm-8 4h24v4h-24z"/><path fill="#9BE0E0" d="M224 272h4v16h-4zm20 12h4v4h-4zm8-12h32v4h-32z"/><path fill="#000" d="M261 260h19v4h-19z"/><path fill="#75BDBD" d="M257 232h4v4h-4z"/><path fill="#000" d="M261 232h4v4h-4zm19 0h4v4h-4z"/><path fill="#75BDBD" d="M276 232h4v4h-4z"/><path fill="#000" d="M276 236h4v4h-4z"/><path fill="#75BDBD" d="M280 236h4v4h-4z"/><path fill="#000" d="M257 236h4v4h-4z"/><path fill="#75BDBD" d="M261 236h4v4h-4z"/><path fill="#9BE0E0" d="M256 276h20v4h-20zm-24-12h4v24h-4zm36-20h4v12h-4zm-28 16h4v28h-4zm-24 20h4v8h-4z"/>',
        '<path fill="#564635" d="M228 268h4v20h-4zm-4 4h4v16h-4zm-4 4h4v12h-4zm-4 4h4v8h-4zm16 0h16v8h-16zm8-20h8v20h-8zm-8 4h8v16h-8zm16-40h20v64h-20zm20 0h16v52h-16zm0 52h4v8h-4zm4 0h4v8h-4zm-4 8h4v4h-4zm-12-72h12v4h-12zm4 4h12v4h-12zm-8 4h24v4h-24z"/><path fill="#342A20" d="M224 272h4v16h-4zm20 12h4v4h-4zm8-12h32v4h-32z"/><path fill="#8A7F72" d="M280 256h4v8h-4zm-24 0h4v8h-4zm4-4h4v4h-4zm-4-4h4v4h-4zm-4-16h4v16h-4zm4 0h28v16h-28zm4-8h20v4h-20zm-4 4h28v4h-28zm8 24h16v4h-16zm16-4h4v4h-4zm-20 0h20v4h-20zm0 8h20v8h-20zm0 8h20v4h-20z"/><path fill="#534C44" d="M257 232h8v4h-8zm19 0h8v4h-8z"/><path fill="#000" d="M276 236h4v4h-4z"/><path fill="#A0978C" d="M280 236h4v4h-4z"/><path fill="#000" d="M257 236h4v4h-4z"/><path fill="#A0978C" d="M261 236h4v4h-4z"/><path fill="#342A20" d="M256 276h20v4h-20zm-24-12h4v24h-4zm8-4h4v28h-4zm-24 20h4v8h-4z"/><path fill="#000" d="M264 256h12v4h-12zm8-12h4v4h-4zm-8 0h4v4h-4z"/>',
        ''
    ];
    string[9] private glasses = [
        '<path fill="#EEE" d="M244 228h44v4h-44zm12 12h32v4h-32zm-4-8h4v12h-4zm32 0h4v8h-4zm-16 0h4v8h-4z"/><path fill="#2C82FD" d="M256 232h12v8h-12z"/><path fill="#FD2C2C" d="M272 232h12v8h-12z"/>',
        '<path fill="#000" d="M276 236h4v4h-4z"/><path fill="#F3322C" d="M244 236h4v4h-4zm0-4h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm0 4h4v4h-4zm0 4h4v4h-4zm0-12h4v4h-4zm4-4h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm-8 16h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm0-16h4v4h-4zm0 4h4v4h-4z"/><path fill="#fff" d="M256 228h6v12h-6zm24 0h6v12h-6z"/><path fill="#000" d="M262 228h6v12h-6zm24 0h6v12h-6z"/><path fill="#F3322C" d="M268 232h4v4h-4zm0 4h4v4h-4zm4-4h4v4h-4zm4-8h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm-12 4h4v4h-4zm0 4h4v4h-4zm0 4h4v4h-4zm0 4h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4-16h4v4h-4zm0 4h4v4h-4zm0 4h4v4h-4zm0 4h4v4h-4zm0 4h4v4h-4zm-40-16h4v4h-4z"/>',
        '<path fill="#000" d="M248 232h44v4h-44zm4 4h16v4h-16zm4 4h4v4h-4zm4 0h4v4h-4zm20 0h8v4h-8zm-4-4h16v4h-16z"/>',
        '<path fill="#000" d="M248 230h36v2h-36zm0 10h36v2h-36zm0-8h9v4h-9zm0 4h9v4h-9zm17-4h11v8h-11z"/>',
        '<path fill="#000" d="M248 232h36v4h-36zm28 4h4v4h-4zm4 0h4v4h-4zm0 4h4v4h-4zm-4 0h4v4h-4zm-20-4h4v4h-4zm0 4h4v4h-4zm4-4h4v4h-4zm0 4h4v4h-4z"/>',
        '<path fill="#000" d="M248 228h36v4h-36zm8 4h-4v4h4zm0 4h-4v4h4zm4 4h-4v4h4zm4 0h-4v4h4zm4-4h-4v4h4zm0-4h-4v4h4z"/><path fill="#523211" d="M264 232h-8v4h8z"/><path fill="#C06A14" d="M264 236h-8v4h8z"/><path fill="#523211" d="M284 232h-8v4h8z"/><path fill="#C06A14" d="M284 236h-8v4h8z"/><path fill="#000" d="M276 232h-4v4h4zm0 4h-4v4h4zm12-4h-4v4h4zm0 4h-4v4h4zm-4 4h-8v4h8z"/>',
        '<path fill="#000" d="M248 228h36v4h-36zm4 4h14v4h-14zm0 4h14v4h-14zm3 4h8v4h-8z"/>',
        '<path fill="#000" d="M252 224h36v4h-36zm0 20h36v4h-36zm-4-4h4v4h-4zm0-12h4v4h-4z"/><path fill="#828282" d="M248 232h4v8h-4zm4-4h4v4h-4zm0 12h4v4h-4zm32 0h4v4h-4zm0-12h4v4h-4z"/><path fill="#ABABAB" d="M256 228h28v4h-28zm-4 4h4v8h-4zm4 8h28v4h-28z"/><path fill="#000" d="M288 228h4v16h-4zm-20 16h8v4h-8zm-12-12h28v8h-28z"/><path fill="#ABABAB" d="M284 232h4v8h-4z"/>',
        ''
    ];
    string[5] private accessory = [
        '<path fill="#FFD422" d="M244 240h4v4h-4z"/>',
        '<path fill="#4F4F4F" d="M276 256h24v4h-24z"/><path fill="#0038FF" d="M300 256h4v4h-4z"/><path fill="#000" d="M304 256h4v4h-4zm-28-4h28v4h-28zm0 8h28v4h-28z"/>',
        '<path fill="#D1CBCB" d="M276 256h24v4h-24z"/><path fill="#E38800" d="M300 256h4v4h-4z"/><path fill="#000" d="M304 256h4v4h-4z"/><path fill="#9BAFB9" d="M304 229h4v20h-4z"/><path fill="#000" d="M276 252h28v4h-28zm0 8h28v4h-28z"/>',
        '<path fill="#000" d="M272 260h4v4h-4zm8 0h4v4h-4zm-4-4h4v4h-4z"/><path fill="#7A4714" d="M276 260h4v4h-4zm4 4h4v4h-4zm4 4h4v4h-4zm16 0h4v4h-4z"/><path fill="#56310B" d="M300 272h4v4h-4zm-4-4h4v4h-4z"/><path fill="#9BAFB9" d="M301 253h4v5h-4zm0-9h4v5h-4zm-4-8h12v4h-12zm4-4h4v4h-4z"/><path fill="#56310B" d="M304 268h4v4h-4z"/><path fill="#7A4714" d="M288 272h12v4h-12zm8-8h12v4h-12z"/><path fill="#000" d="M276 264h4v4h-4zm4 4h4v4h-4zm8 8h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4-4h4v4h-4zm4-4h4v4h-4zm0-4h4v4h-4zm-12-4h16v4h-16zm-12 12h4v4h-4zm0-8h4v4h-4zm4 4h4v4h-4zm4 0h4v4h-4zm0-4h4v4h-4zm0-4h4v4h-4z"/>',
        ''
    ];
    string[14] private hats = [
        '<path fill="#000" d="M288 216h4v8h-4zm-48 0h4v8h-4zm4-4h4v4h-4z"/><path fill="#C34512" d="M244 216h44v8h-44zm4-4h36v4h-36z"/><path fill="#88300D" d="M244 216h44v4h-44zm0 4h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4z"/><path fill="#C34512" d="M251 208h29v4h-29z"/><path fill="#000" d="M284 212h4v4h-4zm-4-4h4v4h-4zm-33 0h4v4h-4zm4-4h29v4h-29z"/>',
        '<path fill="#000" d="M244 220h52v4h-52zm12-4h4v4h-4zm4-4h32v4h-32z"/><path fill="#2F2F2F" d="M260 216h32v4h-32z"/><path fill="#474747" d="M248 208h36v4h-36zm4-4h28v4h-28zm-4 8h12v4h-12zm0 4h8v4h-8z"/><path fill="#000" d="M292 216h4v4h-4zm-8-8h4v4h-4zm-4-4h4v4h-4zm-36 4h4v12h-4zm4-4h4v4h-4z"/><path fill="#2F2F2F" d="M252 204h4v4h-4zm-4 4h4v4h-4z"/><path fill="#000" d="M252 200h28v4h-28z"/>',
        '<path fill="#000" d="M244 224h44v4h-44zm0-4h4v4h-4zm0-4h4v4h-4zm0-4h4v4h-4zm4-4h4v4h-4z"/><path fill="#434343" d="M248 212h36v12h-36zm4-4h28v4h-28z"/><path fill="#585858" d="M256 212h4v4h-4zm-4 4h4v4h-4z"/><path fill="#000" d="M280 208h4v4h-4zm4 0h4v16h-4zm-32-4h28v4h-28z"/>',
        '<path fill="#000" d="M248 220h4v4h-4z"/><path fill="#142771" d="M244 220h4v4h-4z"/><path fill="#193BC1" d="M248 220h4v4h-4z"/><path fill="#16309A" d="M252 220h16v4h-16zm16 4h8v4h-8zm8-4h4v4h-4zm-24-12h32v4h-32z"/><path fill="#193BC1" d="M252 212h32v4h-32zm-4 4h36v4h-36zm20 4h8v4h-8z"/><path fill="#16309A" d="M248 212h4v4h-4zm-4 4h4v4h-4z"/><path fill="#193BC1" d="M240 220h4v4h-4z"/><path fill="#142771" d="M240 224h4v4h-4zm-4 4h4v4h-4z"/><path fill="#193BC1" d="M236 220h4v4h-4z"/><path fill="#16309A" d="M236 224h4v4h-4z"/><path fill="#193BC1" d="M232 232h4v4h-4z"/><path fill="#16309A" d="M232 220h4v4h-4z"/><path fill="#193BC1" d="M232 224h4v4h-4zm0 4h4v4h-4zm-4-8h4v4h-4z"/><path fill="#16309A" d="M284 212h4v8h-4zm-4 8h8v4h-8z"/>',
        '<path fill="#000" d="M248 220h4v4h-4z"/><path fill="#6E4212" d="M232 220h68v4h-68zm-4-4h76v4h-76zm20-8h36v4h-36zm0-4h36v4h-36zm0-4h36v4h-36zm4-4h10v4h-10zm18 0h10v4h-10z"/><path fill="#462909" d="M244 212h44v4h-44z"/><path fill="#6E4212" d="M228 212h4v4h-4zm72 0h4v4h-4z"/>',
        '<path fill="#000" d="M240 224h4v4h-4zm0-8h48v4h-48zm4 4h32v4h-32zm0-8h48v4h-48zm4-4h36v4h-36zm4-4h4v4h-4zm20 0h4v4h-4zm8 0h4v4h-4zm8 20h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm0-4h8v4h-8zm-24-16h8v4h-8zm8 0h8v4h-8zm-20 20h4v4h-4zm4 0h4v4h-4zm8 0h4v4h-4zm12 0h4v8h-4zm-16 4h4v4h-4z"/>',
        '<path fill="#35291C" d="M236 224h60v4h-60zm4-4h52v4h-52zm10-8h32v4h-32zm4-4h24v4h-24zm0-4h24v4h-24zm4-4h16v4h-16z"/><path fill="#000" d="M245 216h42v4h-42z"/>',
        '<path fill="#E0E817" d="M252 220h28v4h-28zm4-4h20v4h-20zm4-8h12v8h-12z"/><path fill="#35BB00" d="M252 224h28v4h-28z"/><path fill="#05B" d="M244 220h8v4h-8zm0-4h12v4h-12zm4-4h12v4h-12zm4-4h8v4h-8z"/><path fill="#D00808" d="M280 220h8v4h-8zm-4-4h12v4h-12zm-4-4h12v4h-12zm0-4h8v4h-8z"/><path fill="#000" d="M264 204h4v4h-4z"/><path fill="#05B" d="M260 200h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm-16 0h4v4h-4z"/>',
        '<path fill="#000" d="M280 224h4v4h-4z"/><path fill="#000" d="M280 224h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm0-4h4v4h-4zm-4-4h4v4h-4zm4-8h4v8h-4zm-48 0h4v8h-4zm4-4h16v4h-16zm28 0h16v4h-16zm-12-4h12v4h-12zm16 16h4v4h-4zm-8 0h4v4h-4zm-8 0h4v4h-4zm16 8h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm-4-4h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm0-4h4v4h-4zm8 0h4v4h-4z"/><path fill="#fff" d="M248 216h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4z"/><path fill="#222B41" d="M256 220h32v4h-32zm4-16h12v4h-12zm-16 4h44v8h-44z"/><path fill="#FFD200" d="M264 208h4v4h-4z"/>',
        '<path fill="#000" d="M236 220h60v4h-60zm4-4h52v4h-52zm4-8h44v4h-44zm0-4h44v4h-44zm0-4h44v4h-44zm0-4h44v4h-44zm0-4h44v4h-44zm0-4h44v4h-44zm0-4h44v4h-44zm4-4h36v4h-36z"/><path fill="#D71B1B" d="M244 212h44v4h-44z"/>',
        '<path fill="#7618AE" d="M244 220h56v4h-56zm0-4h48v4h-48zm0-4h40v4h-40zm4-4h36v4h-36zm4-4h28v4h-28z"/><path fill="#A956D7" d="M272 208h4v4h-4zm4 4h4v4h-4z"/>',
        '<path fill="#000" d="M252 216h4v4h-4zm-12 28h4v4h-4zm-4 0h4v4h-4zm4-4h4v4h-4zm-4 0h4v4h-4zm-4-4h4v4h-4zm0-28h4v4h-4zm0-4h4v4h-4zm0-4h4v4h-4zm12-4h4v4h-4zm4 0h4v4h-4zm0 4h4v4h-4zm-4 0h4v4h-4zm-8 4h20v4h-20zm36-8h8v4h-8zm8 0h4v4h-4zm8 4h4v4h-4zm8 8h4v4h-4zm-16-4h12v4h-12zm12-4h8v4h-8zm-12 8h12v4h-12zm0 4h12v4h-12zm0 4h12v4h-12zm4 4h4v4h-4zm4 0h4v24h-4zm-24-24h8v4h-8zm-12 4h20v4h-20zm4 4h16v4h-16zm12 4h4v4h-4zm4-8h4v16h-4zm4 0h4v20h-4zm-40 8h20v4h-20zm0 8h16v4h-16zm-4-4h20v4h-20zm8 24h4v4h-4zm-8-4h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm-4-4h4v4h-4zm0-4h4v4h-4zm-4 0h4v4h-4zm-4 0h4v4h-4zm12 0h4v8h-4z"/><path fill="#E8AA96" d="M256 212h12v4h-12z"/><path fill="#000" d="M256 216h4v4h-4zm-4-4h4v4h-4zm16 0h4v4h-4zm4 4h4v4h-4zm-28 8h8v20h-8zm-12-4h24v4h-24zm32 0h8v4h-8zm-4-4h8v4h-8z"/><path fill="#000" d="M252 212h16v4h-16zm4-4h12v4h-12zm12 4h4v4h-4zm4 4h4v4h-4zm4 4h4v4h-4zm4 0h4v4h-4zm-16 4h4v4h-4zm28 4h4v8h-4zm0-24h4v20h-4z"/>',
        '<path fill="#000" d="M244 220h44v4h-44zm0-4h4v4h-4zm-4-4h4v4h-4zm0-16h4v4h-4zm4-4h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 4h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4zm4 0h4v4h-4z"/><path fill="#425E29" d="M248 216h36v4h-36zm-4-4h48v4h-48zm-4-4h52v4h-52zm0-4h48v4h-48zm0-4h36v4h-36zm36-8h4v4h-4z"/><path fill="#2A381F" d="M276 196h4v4h-4z"/><path fill="#161615" d="M280 216h4v4h-4z"/><path fill="#2A381F" d="M252 212h28v4h-28z"/><path fill="#425E29" d="M244 196h16v4h-16z"/><path fill="#000" d="M272 192h4v4h-4zm4-4h4v4h-4zm4 4h4v4h-4zm-4 8h12v4h-12zm-40 8h4v4h-4zm0-4h4v4h-4zm0-4h4v4h-4zm52 4h4v4h-4zm4 4h4v8h-4zm-8 8h8v4h-8z"/>',
        ''
    ];

    string[6] private typesNames = [
        "Smile",
        "Frown",
        "Zombie",
        "Alien",
        "Ape",
        "Normal"
    ];
    string[9] private glassesNames = [
        "3D Glasses",
        "Noun Bans",
        "Cool Shades",
        "Mask",
        "Regular Glasses",
        "Gradient Shades",
        "Eye Patch",
        "VR",
        "None"
    ];
    string[5] private accessoriesNames = [
        "Gold Earring",
        "Vape",
        "Cigarette",
        "Pipe",
        "None"
    ];
    string[14] private hatsNames = [
        "Knitted",
        "Cap Forward",
        "Do-rag",
        "Bandana",
        "Cowboy",
        "Bead Hair",
        "Fedora",
        "Beanie",
        "Police Hat",
        "Top Hat",
        "Cap",
        "Messy Hair",
        "Beret",
        "None"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBaseColor(uint256 tokenId) internal pure returns (uint256) {
        uint256 rn1 = random(string(abi.encodePacked("BASE COLOR", toString(tokenId))));
        uint256 rn2 = rn1 % 79;
        uint256 res = 0;

        if (rn2 >= 10 && rn2 < 20) {
            res = 1;
        }
        if (rn2 >= 20 && rn2 < 30) {
            res = 2;
        }
        if (rn2 >= 30 && rn2 < 40) {
            res = 3;
        }
        if (rn2 >= 40 && rn2 < 50) {
            res = 4;
        }
        if (rn2 >= 50 && rn2 < 60) {
            res = 5;
        }
        if (rn2 >= 60 && rn2 < 70) {
            res = 6;
        }
        if (rn2 >= 70) {
            res = 7;
        }

        return res;
    }

    function getBodyType(uint256 tokenId) internal pure returns (uint256) {
        uint256 rn1 = random(string(abi.encodePacked("BODY TYPE", toString(tokenId))));
        uint256 rn2 = rn1 % 170;
        uint256 res = 0;

        if (rn2 >= 46 && rn2 < 64) {
            res = 1;
        }
        if (rn2 >= 64 && rn2 < 81) {
            res = 2;
        }
        if (rn2 >= 81 && rn2 < 85) {
            res = 3;
        }
        if (rn2 == 85) {
            res = 4;
        }
        if (rn2 >= 86 && rn2 < 88) {
            res = 5;
        }
        if (rn2 >= 88) {
            res = 6;
        }

        return res;
    }

    function getGlass(uint256 tokenId) internal pure returns (uint256) {
        uint256 rn1 = random(string(abi.encodePacked("GLASSES", toString(tokenId))));
        uint256 rn2 = rn1 % 500;
        uint256 res = 0;

        if (rn2 >= 41 && rn2 < 81) {
            res = 1;
        }
        if (rn2 >= 81 && rn2 < 121) {
            res = 2;
        }
        if (rn2 >= 121 && rn2 < 161) {
            res = 3;
        }
        if (rn2 >= 161 && rn2 < 201) {
            res = 4;
        }
        if (rn2 >= 201 && rn2 < 261) {
            res = 5;
        }
        if (rn2 >= 261 && rn2 < 281) {
            res = 6;
        }
        if (rn2 >= 281) {
            res = 7;
        }

        return res;
    }

    function getAccessory(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("ACCESSORY", toString(tokenId))));

        uint256 rn1 = rand % 120;
        uint256 res = 0;

        if (rn1 >= 10 && rn1 < 20) {
            res = 1;
        }
        if (rn1 >= 20 && rn1 < 30) {
            res = 2;
        }
        if (rn1 >= 30 && rn1 < 40) {
            res = 3;
        }
        if (rn1 >= 40) {
            res = 4;
        }

        return res;
    }

    function getHat(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("HATS", toString(tokenId))));

        uint256 rn1 = rand % 240;
        uint256 res = 0;

        if (rn1 >= 10 && rn1 < 20) {
            res = 1;
        }
        if (rn1 >= 20 && rn1 < 30) {
            res = 2;
        }
        if (rn1 >= 30 && rn1 < 40) {
            res = 3;
        }
        if (rn1 >= 40 && rn1 < 50) {
            res = 4;
        }
        if (rn1 >= 50 && rn1 < 60) {
            res = 5;
        }
        if (rn1 >= 60 && rn1 < 70) {
            res = 6;
        }
        if (rn1 >= 70 && rn1 < 80) {
            res = 7;
        }
        if (rn1 >= 80 && rn1 < 90) {
            res = 8;
        }
        if (rn1 >= 90 && rn1 < 100) {
            res = 9;
        }
        if (rn1 >= 100 && rn1 < 110) {
            res = 10;
        }
        if (rn1 >= 110 && rn1 < 120) {
            res = 11;
        }
        if (rn1 >= 120 && rn1 < 130) {
            res = 12;
        }
        if (rn1 >= 130) {
            res = 13;
        }

        return res;
    }

    function pluck(uint256 tokenId) internal view returns (Layers memory) {
        Layers memory layers;

        layers.baseColor = getBaseColor(tokenId);
        layers.bodyType = getBodyType(tokenId);
        layers.glasses = getGlass(tokenId);
        layers.accessory = getAccessory(tokenId);
        layers.hat = getHat(tokenId);

        return layers;
    }

    function getSVG(Layers memory _lad) internal view returns (string memory) {
        string[9] memory ladLayers;

        ladLayers[
            0
        ] = '<svg id="pic" viewBox="0 0 512 512" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg"><rect width="512" height="512" fill="#638596"/>';
        ladLayers[1] = '<path fill="';
        ladLayers[2] = baseColors[_lad.baseColor];
        ladLayers[
            3
        ] = '" d="M228 268h4v20h-4zm-4 4h4v16h-4zm-4 4h4v12h-4zm-4 4h4v8h-4zm24-20h8v28h-8zm-8 4h8v24h-8zm16-40h20v64h-20zm20 0h16v52h-16zm0 52h4v8h-4zm4 0h4v8h-4zm-4 8h4v4h-4zm-12-72h12v4h-12zm4 4h12v4h-12zm-8 4h24v4h-24z"/> <path fill="#000" d="M212 288h64v4h-64zm0-8h4v8h-4zm64-4h4v8h-4zm4 0h4v4h-4zm-56-8h4v4h-4zm4-4h4v4h-4zm4-4h8v4h-8zm-12 12h4v4h-4zm-4 4h4v4h-4zm28-52h4v32h-4zm4-4h4v4h-4zm8-4h4v4h-4zm20 4h8v4h-8zm-24-8h4v8h-4zm4-4h12v4h-12zm12 4h4v4h-4zm4 4h4v4h-4zm12 8h4v52h-4zm-44 32h8v4h-8zm24 0h12v4h-12zm4-12h8v4h-8zm8-8h4v4h-4zm-19 0h4v4h-4zm15 48h4v4h-4z"/><path fill="#000" fill-opacity=".2" d="M280 236h4v4h-4zm-19 0h4v4h-4z"/><path fill="#000" fill-opacity=".4" d="M224 272h4v16h-4zm20 12h4v4h-4zm8-12h32v4h-32zm5-40h8v4h-8zm19 0h8v4h-8zm-20 44h20v4h-20zm-24-12h4v24h-4zm8-4h4v28h-4zm-24 20h4v8h-4z"/>';
        ladLayers[4] = types[_lad.bodyType];
        ladLayers[5] = glasses[_lad.glasses];
        ladLayers[6] = accessory[_lad.accessory];
        ladLayers[7] = hats[_lad.hat];
        ladLayers[
            8
        ] = "<style>#pic{shape-rendering: crispedges;}</style></svg>";

        string memory res = string(
            abi.encodePacked(
                ladLayers[0],
                ladLayers[1],
                ladLayers[2],
                ladLayers[3],
                ladLayers[4],
                ladLayers[5],
                ladLayers[6],
                ladLayers[7],
                ladLayers[8]
            )
        );

        return res;
    }

    function getTraits(Layers memory _lad)
        public
        view
        returns (string memory)
    {
        string[20] memory parts;

        parts[0] = ', "attributes": [{"trait_type": "Type","value": "';

        if (_lad.bodyType == 3) {
            parts[1] = 'Zombie"}, {"trait_type": "Mouth","value": "Zombie"},';
        }
        if (_lad.bodyType == 4) {
            parts[2] = 'Alien"}, {"trait_type": "Mouth","value": "Alien"},';
        }
        if (_lad.bodyType == 5) {
            parts[3] = 'Ape"}, {"trait_type": "Mouth","value": "Ape"},';
        }
        if (_lad.bodyType < 3 || _lad.bodyType > 5) {
            parts[4] = 'Normal"}, {"trait_type": "Mouth","value": "';
            parts[5] = typesNames[_lad.bodyType];
            parts[6] = '"},';
        }

        parts[7] = ' {"trait_type": "Glass","value": "';
        parts[8] = glassesNames[_lad.glasses];

        parts[9] = '"}, {"trait_type": "Hat","value": "';
        parts[10] = hatsNames[_lad.hat];

        parts[11] = '"}, {"trait_type": "Accessory","value": "';
        parts[12] = accessoriesNames[_lad.accessory];
        parts[13] = '"}], ';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[8],
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13]
            )
        );

        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        Layers memory lad = pluck(tokenId);
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Baby Lad #',
                        toString(tokenId),
                        '", "description": "Baby Lads are looking for the parents. Where could they be?"',
                        getTraits(lad),
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(getSVG(lad))),
                        '"}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));

        return json;
    }

    function adopt(uint256 _amount) public {
        uint256 currentSupply = current();

        require(_amount > 0 && _amount <= 10, "Invalid amount");
        require(currentSupply < 4000, "All baby lads have been adopted");
        require(currentSupply + _amount <= 6969, "Amount exceeds max supply");

        for (uint256 i = 0; i < _amount; i++) {
            address user = msg.sender;

            _safeMint(user, _counter);

            increment();
        }
    }

    function current() internal view returns (uint256) {
        return _counter;
    }

    function increment() internal {
        _counter += 1;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

pragma solidity ^0.8.6;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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