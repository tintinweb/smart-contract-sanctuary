// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../address/FROAddressesProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "../interfaces/ITokenDescriptor.sol";
import "../interfaces/IStatus.sol";
import './FROSvg.sol';

contract FROTokenDescriptor is ITokenDescriptor, FROAddressesProxy, Ownable {
    /**
     * tokenId
     * prefix 1
     * character digit 2-3
     * weapon digit 4-5
     * color  digit 6-7
     * serial digit 8-10
     * e.g.) 1010101001
     */

    using Strings for uint256;

    // string[32] positions = ["0","10","20","30","40","50","60","70","80","90","100","110","120","130","140","150","160","170","180","190","200","210","220","230","240","250","260","270","280","290","300","310"];
    string[7] attributes = ["hp", "at", "df", "it", "sp", "color", "weapon"];
    string[6] colorName = ["red","green","yellow","blue","white","black"];
    string[10] weaponName = ["axe","glove","sword","katana","blade","lance","wand","rod","dagger","shuriken"];

    //mapping(x => mapping(y => rgb))
    // mapping(uint => mapping(uint => string)) weaponPixels;

    constructor(address registry_) FROAddressesProxy(registry_) {}

    // mapping(uint => mapping(uint => string)) basePixels;

    // function setPixels(ITokenDescriptor.Pixel[] memory _pixels) external {
    //     for(uint16 i = 0; i < _pixels.length; i++){
    //         basePixels[_pixels[i].x][_pixels[i].y] = _pixels[i].rgb;
    //     }
    // }

    // function setWeaponPixels(ITokenDescriptor.Pixel[] memory _pixels) external {
    //     for(uint16 i = 0; i < _pixels.length; i++){
    //         weaponPixels[_pixels[i].x][_pixels[i].y] = _pixels[i].rgb;
    //     }
    // }

    function _generateName(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "CryptoFrontier Character #",
                    tokenId.toString()
                )
            );
    }

    function _generateDescription(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "CryptoFrontier Character #",
                    tokenId.toString(),
                    '\\n\\nCryptoFrontier is the Full On-chained Game by FrontierDAO.\\n\\nFull On-chained Game is the game where all the data of the game is stored on-chain. Not only the NFTs, but also characters status, skills, battle results and even the battle logic are recorded on-chain.',
                    '\\nhttps://medium.com/@yamapyblack/full-on-chained-game-by-frontierdao-b8e50549811d'
                )
            );
    }

    function _generateAttributes(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        IStatus status = IStatus(
            registry.getRegistry("FROStatus")
        );

        IStatus.Status memory st = status.getStatus(tokenId);

        string[7] memory values = [
            st.hp.toString(),
            st.at.toString(),
            st.df.toString(),
            st.it.toString(),
            st.sp.toString(),
            colorName[status.color(tokenId) - 1],
            weaponName[status.weapon(tokenId) - 1]
        ];

        return _buildAttributes(attributes, values);
    }

    function _buildAttributes(
        string[7] memory trait_types,
        string[7] memory values
    ) private pure returns (string memory) {
        string memory ret = "[";

        for (uint8 i = 0; i < values.length; i++) {

            if(i == 0){
                ret = string(
                    abi.encodePacked(
                        ret,
                        '{"trait_type": "',
                        trait_types[i],
                        '","value": ',
                        values[i],
                        '}'
                    )
                );
            }else if(i < 5){
                ret = string(
                    abi.encodePacked(
                        ret,
                        ',',
                        '{"trait_type": "',
                        trait_types[i],
                        '","value": ',
                        values[i],
                        '}'
                    )
                );
            }else{
                ret = string(
                    abi.encodePacked(
                        ret,
                        ',',
                        '{"trait_type": "',
                        trait_types[i],
                        '","value": "',
                        values[i],
                        '"}'
                    )
                );
            }
        }

        return string(abi.encodePacked(ret, "]"));
    }

    function _generateImage(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        IStatus status = IStatus(
            registry.getRegistry("FROStatus")
        );

        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 320 320">',
                        "<style>.s{width:10px;height:10px;}",
                        _getColorStyle(status.color(tokenId)),
                        "</style>",
                        _basePixel1(),
                        _basePixel2(),
                        _basePixel3(),
                        FROSvg.weaponSvg(status.weapon(tokenId)),
                        // _pixelSvg(),
                        // _weaponPixel(tokenId),
                        "</svg>"
                    )
                )
            );
    }

    // function _concatSvgByPixel(string memory str, ITokenDescriptor.Pixel memory pixel) private view returns(string memory){        
    //     return string(
    //         abi.encodePacked(
    //             str, 
    //             '<rect x="',
    //             positions[pixel.x],
    //             '" y="',
    //             positions[pixel.y],
    //             '" class="s" fill="#',
    //             pixel.rgb,
    //             '"/>'
    //         )
    //     );
    // }

    function _basePixel1() private pure returns(string memory){
        return '<rect x="150" y="30" class="s" fill="#000"/><rect x="160" y="30" class="s" fill="#000"/><rect x="170" y="30" class="s" fill="#000"/><rect x="180" y="30" class="s" fill="#000"/><rect x="190" y="30" class="s" fill="#000"/><rect x="200" y="30" class="s" fill="#000"/><rect x="210" y="30" class="s" fill="#000"/><rect x="140" y="40" class="s" fill="#000"/><rect x="150" y="40" class="s" fill="#a43"/><rect x="160" y="40" class="s" fill="#621"/><rect x="170" y="40" class="s" fill="#621"/><rect x="180" y="40" class="s" fill="#a43"/><rect x="190" y="40" class="s" fill="#C84"/><rect x="200" y="40" class="s" fill="#a43"/><rect x="210" y="40" class="s" fill="#621"/><rect x="220" y="40" class="s" fill="#000"/><rect x="230" y="40" class="s" fill="#000"/><rect x="240" y="40" class="s" fill="#000"/><rect x="130" y="50" class="s" fill="#000"/><rect x="140" y="50" class="s" fill="#000"/><rect x="150" y="50" class="s" fill="#C84"/><rect x="160" y="50" class="s" fill="#621"/><rect x="170" y="50" class="s" fill="#621"/><rect x="180" y="50" class="s" fill="#000"/><rect x="190" y="50" class="s" fill="#a43"/><rect x="200" y="50" class="s" fill="#C84"/><rect x="210" y="50" class="s" fill="#C84"/><rect x="220" y="50" class="s" fill="#a43"/><rect x="230" y="50" class="s" fill="#a43"/><rect x="240" y="50" class="s" fill="#621"/><rect x="250" y="50" class="s" fill="#000"/><rect x="130" y="60" class="s" fill="#000"/><rect x="140" y="60" class="s" fill="#654"/><rect x="150" y="60" class="s" fill="#621"/><rect x="160" y="60" class="s" fill="#000"/><rect x="170" y="60" class="s" fill="#C84"/><rect x="180" y="60" class="s" fill="#a43"/><rect x="190" y="60" class="s" fill="#000"/><rect x="200" y="60" class="s" fill="#a43"/><rect x="210" y="60" class="s" fill="#621"/><rect x="220" y="60" class="s" fill="#621"/><rect x="230" y="60" class="s" fill="#621"/><rect x="240" y="60" class="s" fill="#a43"/><rect x="250" y="60" class="s" fill="#621"/><rect x="260" y="60" class="s" fill="#000"/><rect x="120" y="70" class="s" fill="#000"/><rect x="130" y="70" class="s" fill="#a43"/><rect x="140" y="70" class="s" fill="#654"/><rect x="150" y="70" class="s" fill="#000"/><rect x="160" y="70" class="s" fill="#000"/><rect x="170" y="70" class="s" fill="#a43"/><rect x="180" y="70" class="s" fill="#C84"/><rect x="190" y="70" class="s" fill="#000"/><rect x="200" y="70" class="s" fill="#621"/><rect x="210" y="70" class="s" fill="#a43"/><rect x="220" y="70" class="s" fill="#621"/><rect x="230" y="70" class="s" fill="#521"/><rect x="240" y="70" class="s" fill="#000"/><rect x="250" y="70" class="s" fill="#621"/><rect x="260" y="70" class="s" fill="#621"/><rect x="270" y="70" class="s" fill="#000"/><rect x="120" y="80" class="s" fill="#000"/><rect x="130" y="80" class="s" fill="#a43"/><rect x="140" y="80" class="s" fill="#654"/><rect x="150" y="80" class="s" fill="#000"/><rect x="160" y="80" class="s" fill="#000"/><rect x="170" y="80" class="s" fill="#a43"/><rect x="180" y="80" class="s" fill="#C84"/><rect x="190" y="80" class="s" fill="#000"/><rect x="200" y="80" class="s" fill="#621"/><rect x="210" y="80" class="s" fill="#a43"/><rect x="220" y="80" class="s" fill="#621"/><rect x="230" y="80" class="s" fill="#521"/><rect x="240" y="80" class="s" fill="#000"/><rect x="250" y="80" class="s" fill="#000"/><rect x="260" y="80" class="s" fill="#621"/><rect x="270" y="80" class="s" fill="#000"/><rect x="120" y="90" class="s" fill="#000"/><rect x="130" y="90" class="s" fill="#621"/><rect x="140" y="90" class="s" fill="#521"/><rect x="150" y="90" class="s" fill="#000"/><rect x="160" y="90" class="s" fill="#FC8"/><rect x="170" y="90" class="s" fill="#000"/><rect x="180" y="90" class="s" fill="#a43"/><rect x="190" y="90" class="s" fill="#a43"/><rect x="200" y="90" class="s" fill="#621"/><rect x="210" y="90" class="s" fill="#a43"/><rect x="220" y="90" class="s" fill="#621"/><rect x="230" y="90" class="s" fill="#521"/><rect x="240" y="90" class="s" fill="#621"/><rect x="250" y="90" class="s" fill="#a43"/><rect x="260" y="90" class="s" fill="#621"/><rect x="270" y="90" class="s" fill="#000"/><rect x="130" y="100" class="s" fill="#000"/><rect x="140" y="100" class="s" fill="#521"/><rect x="150" y="100" class="s" fill="#000"/><rect x="160" y="100" class="s" fill="#FC8"/><rect x="170" y="100" class="s" fill="#000"/><rect x="180" y="100" class="s" fill="#000"/><rect x="190" y="100" class="s" fill="#000"/><rect x="200" y="100" class="s" fill="#621"/><rect x="210" y="100" class="s" fill="#621"/><rect x="220" y="100" class="s" fill="#a43"/><rect x="230" y="100" class="s" fill="#621"/><rect x="240" y="100" class="s" fill="#521"/><rect x="250" y="100" class="s" fill="#621"/><rect x="260" y="100" class="s" fill="#000"/><rect x="140" y="110" class="s" fill="#000"/><rect x="150" y="110" class="s" fill="#000"/><rect x="160" y="110" class="s" fill="#FC8"/><rect x="180" y="110" class="s" fill="#FFF"/><rect x="190" y="110" class="s" fill="#000"/><rect x="200" y="110" class="s" fill="#621"/><rect x="210" y="110" class="s" fill="#000"/><rect x="220" y="110" class="s" fill="#a43"/><rect x="230" y="110" class="s" fill="#621"/><rect x="240" y="110" class="s" fill="#521"/><rect x="250" y="110" class="s" fill="#000"/><rect x="260" y="110" class="s" fill="#000"/><rect x="150" y="120" class="s" fill="#000"/><rect x="160" y="120" class="s" fill="#FC8"/><rect x="180" y="120" class="s" fill="#FFF"/><rect x="190" y="120" class="s" fill="#F93"/><rect x="200" y="120" class="s" fill="#000"/><rect x="210" y="120" class="s" fill="#DA6"/><rect x="220" y="120" class="s" fill="#000"/><rect x="230" y="120" class="s" fill="#a43"/><rect x="240" y="120" class="s" fill="#000"/><rect x="250" y="120" class="s" fill="#000"/><rect x="150" y="130" class="s" fill="#000"/><rect x="160" y="130" class="s" fill="#FC8"/><rect x="170" y="130" class="s" fill="#FC8"/><rect x="180" y="130" class="s" fill="#F93"/><rect x="190" y="130" class="s" fill="#F93"/><rect x="200" y="130" class="s" fill="#DA6"/><rect x="210" y="130" class="s" fill="#DA6"/><rect x="220" y="130" class="s" fill="#000"/><rect x="230" y="130" class="s" fill="#621"/><rect x="240" y="130" class="s" fill="#000"/><rect x="150" y="140" class="s" fill="#000"/><rect x="160" y="140" class="s" fill="#000"/><rect x="170" y="140" class="s" fill="#FC8"/><rect x="180" y="140" class="s" fill="#F93"/><rect x="190" y="140" class="s" fill="#000"/><rect x="200" y="140" class="s" fill="#000"/><rect x="210" y="140" class="s" fill="#000"/><rect x="220" y="140" class="s" fill="#000"/><rect x="230" y="140" class="s" fill="#000"/><rect x="250" y="140" class="s" fill="#000"/><rect x="260" y="140" class="s" fill="#000"/><rect x="150" y="150" class="s" fill="#000"/><rect x="170" y="150" class="s" fill="#000"/><rect x="180" y="150" class="s" fill="#000"/><rect x="190" y="150" class="s" fill="#000"/><rect x="200" y="150" class="s" fill="#FC8"/><rect x="210" y="150" class="s" fill="#FC8"/><rect x="220" y="150" class="s" fill="#F93"/><rect x="230" y="150" class="s" fill="#F93"/><rect x="240" y="150" class="s" fill="#000"/><rect x="250" y="150" class="s" fill="#000"/><rect x="260" y="150" class="s" fill="#DA6"/><rect x="270" y="150" class="s" fill="#000"/><rect x="130" y="160" class="s" fill="#F93"/><rect x="140" y="160" class="s" fill="#521"/><rect x="150" y="160" class="s" fill="#000"/><rect x="170" y="160" class="s" fill="#000"/><rect x="190" y="160" class="s" fill="#000"/><rect x="200" y="160" class="s" fill="#ECA"/><rect x="210" y="160" class="s" fill="#DA6"/><rect x="220" y="160" class="s" fill="#DA6"/><rect x="230" y="160" class="s" fill="#DA6"/><rect x="240" y="160" class="s" fill="#854"/><rect x="250" y="160" class="s" fill="#FFF"/><rect x="260" y="160" class="s" fill="#CB8"/><rect x="270" y="160" class="s" fill="#000"/><rect x="120" y="170" class="s" fill="#DA6"/><rect x="130" y="170" class="s" fill="#854"/><rect x="140" y="170" class="s" fill="#521"/><rect x="150" y="170" class="s" fill="#000"/><rect x="170" y="170" class="s" fill="#000"/><rect x="190" y="170" class="s" fill="#000"/><rect x="200" y="170" class="s" fill="#ECA"/><rect x="210" y="170" class="s" fill="#CB8"/><rect x="220" y="170" class="s" fill="#CB8"/><rect x="230" y="170" class="s" fill="#CB8"/><rect x="240" y="170" class="s" fill="#854"/><rect x="250" y="170" class="s" fill="#FFF"/><rect x="260" y="170" class="s" fill="#CB8"/><rect x="270" y="170" class="s" fill="#000"/><rect x="120" y="180" class="s" fill="#000"/><rect x="130" y="180" class="s" fill="#DA6"/><rect x="140" y="180" class="s" fill="#CB8"/><rect x="150" y="180" class="s" fill="#000"/><rect x="190" y="180" class="s" fill="#000"/><rect x="200" y="180" class="s" fill="#F93"/><rect x="210" y="180" class="s" fill="#F93"/><rect x="220" y="180" class="s" fill="#621"/><rect x="230" y="180" class="s" fill="#621"/><rect x="240" y="180" class="s" fill="#621"/><rect x="250" y="180" class="s" fill="#FFF"/>';
    }

    function _basePixel2() private pure returns(string memory){
        return '<rect x="260" y="180" class="s" fill="#DA6"/><rect x="270" y="180" class="s" fill="#000"/><rect x="130" y="190" class="s" fill="#000"/><rect x="140" y="190" class="s" fill="#000"/><rect x="150" y="190" class="s" fill="#000"/><rect x="160" y="190" class="s" fill="#000"/><rect x="200" y="190" class="s" fill="#000"/><rect x="210" y="190" class="s" fill="#000"/><rect x="220" y="190" class="s" fill="#000"/><rect x="230" y="190" class="s" fill="#000"/><rect x="240" y="190" class="s" fill="#DA6"/><rect x="250" y="190" class="s" fill="#DA6"/><rect x="260" y="190" class="s" fill="#000"/><rect x="160" y="200" class="s" fill="#000"/><rect x="240" y="200" class="s" fill="#000"/><rect x="250" y="200" class="s" fill="#000"/><rect x="150" y="210" class="s" fill="#000"/><rect x="250" y="210" class="s" fill="#000"/><rect x="150" y="220" class="s" fill="#000"/><rect x="160" y="220" class="s" fill="#FFF"/><rect x="170" y="220" class="s" fill="#DA6"/><rect x="250" y="220" class="s" fill="#000"/><rect x="130" y="230" class="s" fill="#000"/><rect x="140" y="230" class="s" fill="#000"/><rect x="180" y="230" class="s" fill="#000"/><rect x="190" y="230" class="s" fill="#000"/><rect x="200" y="230" class="s" fill="#000"/><rect x="210" y="230" class="s" fill="#DA6"/><rect x="240" y="230" class="s" fill="#DA6"/><rect x="250" y="230" class="s" fill="#CB8"/><rect x="260" y="230" class="s" fill="#000"/><rect x="130" y="240" class="s" fill="#000"/><rect x="140" y="240" class="s" fill="#000"/><rect x="150" y="240" class="s" fill="#000"/><rect x="160" y="240" class="s" fill="#000"/><rect x="180" y="240" class="s" fill="#000"/><rect x="190" y="240" class="s" fill="#000"/><rect x="210" y="240" class="s" fill="#000"/><rect x="220" y="240" class="s" fill="#DA6"/><rect x="230" y="240" class="s" fill="#CB8"/><rect x="240" y="240" class="s" fill="#FFF"/><rect x="250" y="240" class="s" fill="#DA6"/><rect x="260" y="240" class="s" fill="#000"/><rect x="120" y="250" class="s" fill="#000"/><rect x="170" y="250" class="s" fill="#000"/><rect x="190" y="250" class="s" fill="#000"/><rect x="200" y="250" class="s" fill="#000"/><rect x="210" y="250" class="s" fill="#000"/><rect x="270" y="250" class="s" fill="#000"/><rect x="120" y="260" class="s" fill="#000"/><rect x="170" y="260" class="s" fill="#000"/><rect x="190" y="260" class="s" fill="#000"/><rect x="200" y="260" class="s" fill="#000"/><rect x="210" y="260" class="s" fill="#000"/><rect x="270" y="260" class="s" fill="#000"/><rect x="120" y="270" class="s" fill="#000"/><rect x="130" y="270" class="s" fill="#000"/><rect x="140" y="270" class="s" fill="#000"/><rect x="150" y="270" class="s" fill="#000"/><rect x="160" y="270" class="s" fill="#000"/><rect x="170" y="270" class="s" fill="#000"/><rect x="180" y="270" class="s" fill="#000"/><rect x="190" y="270" class="s" fill="#000"/><rect x="200" y="270" class="s" fill="#000"/><rect x="210" y="270" class="s" fill="#000"/><rect x="220" y="270" class="s" fill="#000"/><rect x="230" y="270" class="s" fill="#000"/><rect x="250" y="270" class="s" fill="#000"/><rect x="260" y="270" class="s" fill="#000"/><rect x="270" y="270" class="s" fill="#000"/><rect x="190" y="280" class="s" fill="#000"/><rect x="200" y="280" class="s" fill="#000"/><rect x="210" y="280" class="s" fill="#000"/><rect x="280" y="280" class="s" fill="#000"/><rect x="220" y="290" class="s" fill="#000"/><rect x="230" y="290" class="s" fill="#000"/><rect x="240" y="290" class="s" fill="#000"/><rect x="250" y="290" class="s" fill="#000"/><rect x="260" y="290" class="s" fill="#000"/><rect x="270" y="290" class="s" fill="#000"/><rect x="280" y="290" class="s" fill="#000"/>';
    }

    function _basePixel3() private pure returns(string memory){
        return '<rect x="170" y="110" class="s c1"/><rect x="170" y="120" class="s c1"/><rect x="160" y="150" class="s c2"/><rect x="160" y="160" class="s c1"/><rect x="180" y="160" class="s c2"/><rect x="160" y="170" class="s c1"/><rect x="180" y="170" class="s c2"/><rect x="160" y="180" class="s c1"/><rect x="170" y="180" class="s c2"/><rect x="180" y="180" class="s c2"/><rect x="170" y="190" class="s c1"/><rect x="180" y="190" class="s c1"/><rect x="190" y="190" class="s c1"/><rect x="170" y="200" class="s c1"/><rect x="180" y="200" class="s c2"/><rect x="190" y="200" class="s c2"/><rect x="200" y="200" class="s c2"/><rect x="210" y="200" class="s c1"/><rect x="220" y="200" class="s c1"/><rect x="230" y="200" class="s c1"/><rect x="160" y="210" class="s c1"/><rect x="170" y="210" class="s c2"/><rect x="180" y="210" class="s c1"/><rect x="190" y="210" class="s c2"/><rect x="200" y="210" class="s c2"/><rect x="210" y="210" class="s c2"/><rect x="220" y="210" class="s c1"/><rect x="230" y="210" class="s c1"/><rect x="240" y="210" class="s c1"/><rect x="180" y="220" class="s c1"/><rect x="190" y="220" class="s c1"/><rect x="200" y="220" class="s c2"/><rect x="210" y="220" class="s c2"/><rect x="220" y="220" class="s c1"/><rect x="230" y="220" class="s c1"/><rect x="240" y="220" class="s c1"/><rect x="150" y="230" class="s c1"/><rect x="160" y="230" class="s c2"/><rect x="170" y="230" class="s c1"/><rect x="220" y="230" class="s c1"/><rect x="230" y="230" class="s c1"/><rect x="170" y="240" class="s c1"/><rect x="130" y="250" class="s c1"/><rect x="140" y="250" class="s c1"/><rect x="150" y="250" class="s c2"/><rect x="160" y="250" class="s c1"/><rect x="180" y="250" class="s c1"/><rect x="220" y="250" class="s c1"/><rect x="230" y="250" class="s c1"/><rect x="240" y="250" class="s c2"/><rect x="250" y="250" class="s c1"/><rect x="260" y="250" class="s c1"/><rect x="130" y="260" class="s c1"/><rect x="140" y="260" class="s c1"/><rect x="150" y="260" class="s c2"/><rect x="160" y="260" class="s c1"/><rect x="180" y="260" class="s c1"/><rect x="220" y="260" class="s c1"/><rect x="230" y="260" class="s c1"/><rect x="240" y="260" class="s c2"/><rect x="250" y="260" class="s c1"/><rect x="260" y="260" class="s c1"/><rect x="240" y="270" class="s c1"/><rect x="220" y="280" class="s c1"/><rect x="230" y="280" class="s c1"/><rect x="240" y="280" class="s c2"/><rect x="250" y="280" class="s c2"/><rect x="260" y="280" class="s c1"/><rect x="270" y="280" class="s c1"/>';
    }

    function _getColorStyle(uint tokenId) private view returns(string memory){
        uint8 color = IStatus(
            registry.getRegistry("FROStatus")
        ).color(tokenId);

        if(color == 1){
            return ".c1{fill:#911;}.c2{fill:#f78;}";

        }else if(color == 2){
            return ".c1{fill:#176;}.c2{fill:#1CA;}";

        }else if(color == 3){
            return ".c1{fill:#961;}.c2{fill:#fc2;}";

        }else if(color == 4){
            return ".c1{fill:#049;}.c2{fill:#08f;}";

        }else if(color == 5){
            return ".c1{fill:#888;}.c2{fill:#ddd;}";

        }else if(color == 6){
            return ".c1{fill:#718;}.c2{fill:#c6f;}";
        }
        return "";
    }

    // function _pixelSvg() private view returns(string memory){
    //     string memory ret = "";

    //     for(uint8 y = 0; y < 32; y++){
    //         for(uint8 x = 0; x < 32; x++){
    //             string memory rgb = weaponPixels[x][y];
    //             if(bytes(rgb).length > 0){
    //                 ret = _concatSvgByPixel(ret, ITokenDescriptor.Pixel(x,y,rgb));
    //             }
    //         }
    //     }

    //     return ret;
    // }

    function tokenURI(IERC721 token, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _generateName(tokenId),
                                '", "description":"',
                                _generateDescription(tokenId),
                                '", "attributes":',
                                _generateAttributes(tokenId),
                                ', "image": "data:image/svg+xml;base64,',
                                _generateImage(tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../interfaces/IAddresses.sol";

contract FROAddressesProxy {
    IAddresses public registry;

    constructor(address registry_){
        registry = IAddresses(registry_);
    }

    modifier onlyAddress(string memory _key) {
        registry.checkRegistory(_key, msg.sender);
        _;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenDescriptor {
    function tokenURI(IERC721 token, uint256 tokenId)
        external
        view
        returns (string memory);

    // struct Pixel {
    //     uint x;
    //     uint y;
    //     string rgb;
    // }    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStatus {
    struct Status {
        uint256 hp;
        uint256 at;
        uint256 df;
        uint256 it;
        uint256 sp;
    }

    function getStatus(uint256 tokenId)
        external
        view
        returns (IStatus.Status memory);

    // function setStatus(uint256 tokenId, IStatus.Status calldata status_) external;
    function setStatusByOwner(uint[] calldata _tokenIds, IStatus.Status[] calldata _status, uint8[] calldata _weapons, uint8[] calldata _colors) external;
    function color(uint256 _tokenId) external view returns(uint8);
    function weapon(uint256 _tokenId) external view returns(uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

library FROSvg {
    using Strings for uint256;

    function weaponSvg(uint8 weapon) external pure returns(string memory){

        if(weapon == 1){ // axe
            return '<style>.w1{fill:#333;}.w2{fill:#999;}.w3{fill:#000;}</style><rect x="20" y="60" class="s w2"/><rect x="30" y="60" class="s w2"/><rect x="50" y="60" class="s w2"/><rect x="60" y="60" class="s w2"/><rect x="70" y="60" class="s w2"/><rect x="80" y="60" class="s w2"/><rect x="20" y="70" class="s w2"/><rect x="30" y="70" class="s w1"/><rect x="40" y="70" class="s w1"/><rect x="50" y="70" class="s w1"/><rect x="60" y="70" class="s w1"/><rect x="70" y="70" class="s w1"/><rect x="80" y="70" class="s w1"/><rect x="90" y="70" class="s w2"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="70" y="80" class="s w1"/><rect x="80" y="80" class="s w1"/><rect x="90" y="80" class="s w2"/><rect x="20" y="90" class="s w2"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w1"/><rect x="50" y="90" class="s w1"/><rect x="60" y="90" class="s w1"/><rect x="80" y="90" class="s w1"/><rect x="90" y="90" class="s w2"/><rect x="20" y="100" class="s w2"/><rect x="30" y="100" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w1"/><rect x="70" y="100" class="s w1"/><rect x="90" y="100" class="s w2"/><rect x="20" y="110" class="s w2"/><rect x="30" y="110" class="s w1"/><rect x="40" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w1"/><rect x="80" y="110" class="s w1"/><rect x="20" y="120" class="s w2"/><rect x="30" y="120" class="s w1"/><rect x="40" y="120" class="s w1"/><rect x="50" y="120" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w1"/><rect x="90" y="120" class="s w1"/><rect x="30" y="130" class="s w2"/><rect x="40" y="130" class="s w2"/><rect x="50" y="130" class="s w2"/><rect x="60" y="130" class="s w2"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w1"/><rect x="110" y="140" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w1"/><rect x="120" y="150" class="s w1"/><rect x="130" y="150" class="s w3"/><rect x="140" y="150" class="s w3"/><rect x="110" y="160" class="s w1"/><rect x="120" y="160" class="s w1"/><rect x="110" y="170" class="s w3"/>';

        }else if(weapon == 2){ // glove
            return '<style>.w1{fill:#000;}.w2{fill:#43A;}.w3{fill:#53C;}</style><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w1"/><rect x="110" y="130" class="s w1"/><rect x="70" y="140" class="s w1"/><rect x="80" y="140" class="s w2"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w2"/><rect x="120" y="140" class="s w1"/><rect x="130" y="140" class="s w1"/><rect x="70" y="150" class="s w1"/><rect x="80" y="150" class="s w2"/><rect x="90" y="150" class="s w2"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w2"/><rect x="140" y="150" class="s w1"/><rect x="70" y="160" class="s w1"/><rect x="80" y="160" class="s w2"/><rect x="90" y="160" class="s w2"/><rect x="100" y="160" class="s w3"/><rect x="110" y="160" class="s w3"/><rect x="120" y="160" class="s w2"/><rect x="130" y="160" class="s w2"/><rect x="140" y="160" class="s w2"/><rect x="70" y="170" class="s w1"/><rect x="80" y="170" class="s w2"/><rect x="90" y="170" class="s w2"/><rect x="100" y="170" class="s w3"/><rect x="110" y="170" class="s w2"/><rect x="120" y="170" class="s w2"/><rect x="130" y="170" class="s w2"/><rect x="140" y="170" class="s w2"/><rect x="70" y="180" class="s w1"/><rect x="80" y="180" class="s w2"/><rect x="90" y="180" class="s w2"/><rect x="100" y="180" class="s w2"/><rect x="110" y="180" class="s w2"/><rect x="120" y="180" class="s w2"/><rect x="130" y="180" class="s w2"/><rect x="140" y="180" class="s w2"/><rect x="70" y="190" class="s w1"/><rect x="80" y="190" class="s w1"/><rect x="90" y="190" class="s w2"/><rect x="100" y="190" class="s w2"/><rect x="110" y="190" class="s w2"/><rect x="120" y="190" class="s w2"/><rect x="130" y="190" class="s w1"/><rect x="140" y="190" class="s w1"/><rect x="90" y="200" class="s w1"/><rect x="100" y="200" class="s w1"/><rect x="110" y="200" class="s w1"/><rect x="120" y="200" class="s w1"/>';

        }else if(weapon == 3){// sword
            return '<style>.w1{fill:#000;}.w2{fill:#36C;}</style><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="40" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w2"/><rect x="40" y="70" class="s w1"/><rect x="50" y="70" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w2"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w1"/><rect x="50" y="90" class="s w2"/><rect x="60" y="90" class="s w1"/><rect x="70" y="90" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w2"/><rect x="70" y="100" class="s w1"/><rect x="80" y="100" class="s w1"/><rect x="50" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w2"/><rect x="80" y="110" class="s w1"/><rect x="90" y="110" class="s w1"/><rect x="60" y="120" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w2"/><rect x="90" y="120" class="s w1"/><rect x="100" y="120" class="s w1"/><rect x="70" y="130" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w1"/><rect x="110" y="130" class="s w1"/><rect x="130" y="130" class="s w1"/><rect x="140" y="130" class="s w1"/><rect x="80" y="140" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w1"/><rect x="120" y="140" class="s w1"/><rect x="130" y="140" class="s w2"/><rect x="140" y="140" class="s w1"/><rect x="90" y="150" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w1"/><rect x="100" y="160" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="90" y="170" class="s w1"/><rect x="100" y="170" class="s w2"/><rect x="110" y="170" class="s w1"/><rect x="90" y="180" class="s w1"/><rect x="100" y="180" class="s w1"/>';

        }else if(weapon == 4){// katana
            return '<style>.w1{fill:#000;}.w2{fill:#BCC;}.w3{fill:#677;}</style><rect x="20" y="50" class="s w2"/><rect x="20" y="60" class="s w2"/><rect x="30" y="60" class="s w3"/><rect x="20" y="70" class="s w2"/><rect x="30" y="70" class="s w3"/><rect x="40" y="70" class="s w3"/><rect x="30" y="80" class="s w2"/><rect x="40" y="80" class="s w3"/><rect x="50" y="80" class="s w3"/><rect x="40" y="90" class="s w2"/><rect x="50" y="90" class="s w3"/><rect x="60" y="90" class="s w3"/><rect x="50" y="100" class="s w2"/><rect x="60" y="100" class="s w3"/><rect x="70" y="100" class="s w3"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w3"/><rect x="80" y="110" class="s w3"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w3"/><rect x="90" y="120" class="s w3"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w3"/><rect x="100" y="130" class="s w3"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w3"/><rect x="110" y="140" class="s w3"/><rect x="130" y="140" class="s w1"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w3"/><rect x="120" y="150" class="s w3"/><rect x="130" y="150" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="100" y="170" class="s w1"/><rect x="110" y="170" class="s w1"/>';

        }else if(weapon == 5){// blade
            return '<style>.w1{fill:#000;}.w2{fill:#812;}</style><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="40" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w2"/><rect x="40" y="70" class="s w2"/><rect x="50" y="70" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w2"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w2"/><rect x="60" y="80" class="s w1"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w2"/><rect x="50" y="90" class="s w1"/><rect x="60" y="90" class="s w2"/><rect x="70" y="90" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w2"/><rect x="60" y="100" class="s w1"/><rect x="70" y="100" class="s w2"/><rect x="80" y="100" class="s w1"/><rect x="50" y="110" class="s w1"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w1"/><rect x="80" y="110" class="s w2"/><rect x="90" y="110" class="s w1"/><rect x="60" y="120" class="s w1"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w1"/><rect x="90" y="120" class="s w2"/><rect x="100" y="120" class="s w1"/><rect x="70" y="130" class="s w1"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w2"/><rect x="110" y="130" class="s w1"/><rect x="130" y="130" class="s w1"/><rect x="140" y="130" class="s w1"/><rect x="80" y="140" class="s w1"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w1"/><rect x="110" y="140" class="s w2"/><rect x="120" y="140" class="s w1"/><rect x="130" y="140" class="s w2"/><rect x="140" y="140" class="s w1"/><rect x="90" y="150" class="s w1"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w1"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w1"/><rect x="100" y="160" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="90" y="170" class="s w1"/><rect x="100" y="170" class="s w2"/><rect x="110" y="170" class="s w1"/><rect x="90" y="180" class="s w1"/><rect x="100" y="180" class="s w1"/>';

        }else if(weapon == 6){// lance
            return '<style>.w1{fill:#034;}.w2{fill:#000;}.w3{fill:#C22;}</style><rect x="10" y="50" class="s w1"/><rect x="20" y="50" class="s w1"/><rect x="40" y="50" class="s w1"/><rect x="50" y="50" class="s w1"/><rect x="10" y="60" class="s w1"/><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="50" y="60" class="s w1"/><rect x="60" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w1"/><rect x="40" y="70" class="s w1"/><rect x="60" y="70" class="s w1"/><rect x="70" y="70" class="s w1"/><rect x="10" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="10" y="90" class="s w1"/><rect x="20" y="90" class="s w1"/><rect x="40" y="90" class="s w1"/><rect x="50" y="90" class="s w3"/><rect x="60" y="90" class="s w1"/><rect x="20" y="100" class="s w1"/><rect x="30" y="100" class="s w1"/><rect x="40" y="100" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w1"/><rect x="70" y="100" class="s w1"/><rect x="30" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w1"/><rect x="80" y="110" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w1"/><rect x="90" y="120" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="100" y="130" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w1"/><rect x="110" y="140" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w1"/><rect x="120" y="150" class="s w1"/><rect x="130" y="150" class="s w2"/><rect x="140" y="150" class="s w2"/><rect x="110" y="160" class="s w1"/><rect x="120" y="160" class="s w2"/><rect x="110" y="170" class="s w2"/>';

        }else if(weapon == 7){// wand
            return '<style>.w1{fill:#520;}.w2{fill:#C2E}</style><rect x="10" y="80" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w1"/><rect x="50" y="80" class="s w1"/><rect x="60" y="80" class="s w1"/><rect x="10" y="90" class="s w1"/><rect x="60" y="90" class="s w1"/><rect x="10" y="100" class="s w1"/><rect x="30" y="100" class="s w2"/><rect x="40" y="100" class="s w1"/><rect x="60" y="100" class="s w1"/><rect x="10" y="110" class="s w1"/><rect x="40" y="110" class="s w1"/><rect x="60" y="110" class="s w1"/><rect x="70" y="110" class="s w1"/><rect x="10" y="120" class="s w1"/><rect x="20" y="120" class="s w1"/><rect x="30" y="120" class="s w1"/><rect x="40" y="120" class="s w1"/><rect x="70" y="120" class="s w1"/><rect x="80" y="120" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w1"/><rect x="90" y="140" class="s w1"/><rect x="100" y="140" class="s w1"/><rect x="100" y="150" class="s w1"/><rect x="110" y="150" class="s w1"/><rect x="130" y="150" class="s" fill="#000"/><rect x="140" y="150" class="s" fill="#000"/><rect x="110" y="160" class="s w1"/><rect x="120" y="160" class="s" fill="#000"/><rect x="110" y="170" class="s" fill="#000"/>';
    
        }else if(weapon == 8){// rod
            return '<style>.w1{fill:#C22;}.w2{fill:#114;}.w3{fill:#000;}</style><rect x="20" y="60" class="s w1"/><rect x="30" y="60" class="s w1"/><rect x="40" y="60" class="s w1"/><rect x="50" y="60" class="s w1"/><rect x="20" y="70" class="s w1"/><rect x="30" y="70" class="s w1"/><rect x="40" y="70" class="s w1"/><rect x="50" y="70" class="s w1"/><rect x="20" y="80" class="s w1"/><rect x="30" y="80" class="s w1"/><rect x="40" y="80" class="s w2"/><rect x="50" y="80" class="s w2"/><rect x="20" y="90" class="s w1"/><rect x="30" y="90" class="s w1"/><rect x="40" y="90" class="s w2"/><rect x="50" y="90" class="s w2"/><rect x="60" y="90" class="s w2"/><rect x="50" y="100" class="s w2"/><rect x="60" y="100" class="s w2"/><rect x="70" y="100" class="s w2"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w2"/><rect x="80" y="110" class="s w2"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w2"/><rect x="90" y="120" class="s w2"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w2"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w2"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w3"/><rect x="140" y="150" class="s w3"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w3"/><rect x="110" y="170" class="s w3"/>';

        }else if(weapon == 9){// dagger
            return '<style>.w1{fill:#000;}.w2{fill:#E72;}</style><rect x="50" y="90" class="s w1"/><rect x="60" y="90" class="s w1"/><rect x="70" y="90" class="s w1"/><rect x="50" y="100" class="s w1"/><rect x="60" y="100" class="s w2"/><rect x="70" y="100" class="s w2"/><rect x="80" y="100" class="s w1"/><rect x="50" y="110" class="s w1"/><rect x="60" y="110" class="s w2"/><rect x="70" y="110" class="s w2"/><rect x="80" y="110" class="s w2"/><rect x="90" y="110" class="s w1"/><rect x="60" y="120" class="s w1"/><rect x="70" y="120" class="s w2"/><rect x="80" y="120" class="s w2"/><rect x="90" y="120" class="s w2"/><rect x="100" y="120" class="s w1"/><rect x="70" y="130" class="s w1"/><rect x="80" y="130" class="s w2"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w2"/><rect x="110" y="130" class="s w1"/><rect x="80" y="140" class="s w1"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w2"/><rect x="120" y="140" class="s w1"/><rect x="90" y="150" class="s w1"/><rect x="100" y="150" class="s w2"/><rect x="110" y="150" class="s w2"/><rect x="120" y="150" class="s w2"/><rect x="130" y="150" class="s w1"/><rect x="140" y="150" class="s w1"/><rect x="100" y="160" class="s w1"/><rect x="110" y="160" class="s w2"/><rect x="120" y="160" class="s w1"/><rect x="110" y="170" class="s w1"/>';

        }else if(weapon == 10){// shuriken
            return '<style>.w1{fill:#000;}.w2{fill:#19A;}</style><rect x="20" y="110" class="s w1"/><rect x="30" y="110" class="s w1"/><rect x="40" y="110" class="s w1"/><rect x="100" y="110" class="s w1"/><rect x="110" y="110" class="s w1"/><rect x="120" y="110" class="s w1"/><rect x="20" y="120" class="s w1"/><rect x="30" y="120" class="s w2"/><rect x="40" y="120" class="s w2"/><rect x="50" y="120" class="s w1"/><rect x="90" y="120" class="s w1"/><rect x="100" y="120" class="s w2"/><rect x="110" y="120" class="s w2"/><rect x="120" y="120" class="s w1"/><rect x="20" y="130" class="s w1"/><rect x="30" y="130" class="s w2"/><rect x="40" y="130" class="s w2"/><rect x="50" y="130" class="s w2"/><rect x="60" y="130" class="s w1"/><rect x="80" y="130" class="s w1"/><rect x="90" y="130" class="s w2"/><rect x="100" y="130" class="s w2"/><rect x="110" y="130" class="s w2"/><rect x="120" y="130" class="s w1"/><rect x="30" y="140" class="s w1"/><rect x="40" y="140" class="s w2"/><rect x="50" y="140" class="s w2"/><rect x="60" y="140" class="s w2"/><rect x="70" y="140" class="s w1"/><rect x="80" y="140" class="s w2"/><rect x="90" y="140" class="s w2"/><rect x="100" y="140" class="s w2"/><rect x="110" y="140" class="s w1"/><rect x="40" y="150" class="s w1"/><rect x="50" y="150" class="s w2"/><rect x="60" y="150" class="s w2"/><rect x="70" y="150" class="s w2"/><rect x="80" y="150" class="s w2"/><rect x="90" y="150" class="s w2"/><rect x="100" y="150" class="s w1"/><rect x="130" y="150" class="s w1"/><rect x="140" y="150" class="s w1"/><rect x="50" y="160" class="s w1"/><rect x="60" y="160" class="s w2"/><rect x="70" y="160" class="s w1"/><rect x="80" y="160" class="s w2"/><rect x="90" y="160" class="s w1"/><rect x="120" y="160" class="s w1"/><rect x="40" y="170" class="s w1"/><rect x="50" y="170" class="s w2"/><rect x="60" y="170" class="s w2"/><rect x="70" y="170" class="s w2"/><rect x="80" y="170" class="s w2"/><rect x="90" y="170" class="s w2"/><rect x="100" y="170" class="s w1"/><rect x="110" y="170" class="s w1"/><rect x="30" y="180" class="s w1"/><rect x="40" y="180" class="s w2"/><rect x="50" y="180" class="s w2"/><rect x="60" y="180" class="s w2"/><rect x="70" y="180" class="s w1"/><rect x="80" y="180" class="s w2"/><rect x="90" y="180" class="s w2"/><rect x="100" y="180" class="s w2"/><rect x="110" y="180" class="s w1"/><rect x="20" y="190" class="s w1"/><rect x="30" y="190" class="s w2"/><rect x="40" y="190" class="s w2"/><rect x="50" y="190" class="s w2"/><rect x="60" y="190" class="s w1"/><rect x="80" y="190" class="s w1"/><rect x="90" y="190" class="s w2"/><rect x="100" y="190" class="s w2"/><rect x="110" y="190" class="s w2"/><rect x="120" y="190" class="s w1"/><rect x="20" y="200" class="s w1"/><rect x="30" y="200" class="s w2"/><rect x="40" y="200" class="s w2"/><rect x="50" y="200" class="s w1"/><rect x="90" y="200" class="s w1"/><rect x="100" y="200" class="s w2"/><rect x="110" y="200" class="s w2"/><rect x="120" y="200" class="s w1"/><rect x="20" y="210" class="s w1"/><rect x="30" y="210" class="s w1"/><rect x="40" y="210" class="s w1"/><rect x="100" y="210" class="s w1"/><rect x="110" y="210" class="s w1"/><rect x="120" y="210" class="s w1"/>';
        }
        
        return "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAddresses {
    function setRegistry(string memory _key, address _addr) external;
    function getRegistry(string memory _key) external view returns (address);
    function checkRegistory(string memory _key, address _sender) external view;
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