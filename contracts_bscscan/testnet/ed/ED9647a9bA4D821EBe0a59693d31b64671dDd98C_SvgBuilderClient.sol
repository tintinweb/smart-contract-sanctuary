// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SvgBuilder.sol";
import "./interfaces/ISvgBuilderClient.sol";

contract SvgBuilderClient is ISvgBuilderClient{

    function buildSvg(uint256 tokenId, uint8 level, uint256 mintTimestamp, uint256 randomSeed, string memory memo) external pure returns (string memory){
        return SvgBuilder.buildSvg(tokenId, level, mintTimestamp, randomSeed, memo);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
pragma solidity 0.8.11;



interface ISvgBuilderClient{
    function buildSvg(uint256 tokenId, uint8 level, uint256 mintTimestamp, uint256 randomSeed, string memory memo) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

//From: https://etherscan.io/address/0x23d23d8f243e57d0b924bff3a3191078af325101#code
library TimeUtils {

    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint;

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    string constant ZERO = '0';
    string constant SPLIT = '-';

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTimeNoSecond(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }


    // YYYY-MM-DD HH:MM  2022-02-26 09:23(UTC)
    function timestampToDateTimeNoSecondUtc(uint timestamp) internal pure returns (string memory){
        (uint year, uint month,uint day,uint hour,uint minute) = timestampToDateTimeNoSecond(timestamp);


        string[9] memory parts;
        parts[0] = string(abi.encodePacked(year.toString(), '-'));
        if(month < 10){
            parts[1] = string(abi.encodePacked(ZERO, month.toString()));
        }else{
            parts[1] = month.toString();
        }
        parts[2] = '-';

        if(day < 10){
            parts[3] = string(abi.encodePacked(ZERO, day.toString()));
        }else{
            parts[3] = day.toString();
        }
        parts[4] = ' ';
        if(hour < 10){
            parts[5] = string(abi.encodePacked(ZERO, hour.toString()));
        }else{
            parts[5] = hour.toString();
        }
        parts[6] = ':';
        if(minute < 10){
            parts[7] = string(abi.encodePacked(ZERO, minute.toString()));
        }else{
            parts[7] = minute.toString();
        }
        parts[8] = '(UTC)';

        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./Base64.sol";
import "./TimeUtils.sol";

library SvgBuilder {

    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint16;
    using StringsUpgradeable for uint8;

    function buildSvg(uint256 tokenId, uint8 level, uint256 mintTimestamp, uint256 randomSeed, string memory memo)internal pure returns (string memory){
        bytes memory bytesStr = bytes(memo);
        bool hasMemo = false;
        if(bytesStr.length > 0){
            hasMemo = true;
        }

        string memory header = header();
        string memory randomCircle = randomCircle(randomSeed);
        string memory randomSymbol = randomSymbol(randomSeed, hasMemo);
        string memory nftProperty = nftProperty(tokenId, level, mintTimestamp);
        string memory nftMemo = nftMemo(memo);
        string memory frame = frame();
        string memory bottom = bottom(randomSeed);

        string memory output = string(abi.encodePacked(header, randomCircle, randomSymbol, nftProperty, nftMemo, frame, bottom));
        return output;
    }

    // header
    function header() internal pure returns (string memory){
        return '<svg width="350" height="350" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><defs><filter id="f" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur in="SourceGraphic" stdDeviation="42" /></filter></defs><rect width="350" height="350" fill="#000"/>';
    }

    // random circle
    function randomCircle(uint256 randomSeed) internal pure returns (string memory){
        string memory circle1 = randomOneCircle(randomSeed, 1);
        string memory circle2 = randomOneCircle(randomSeed, 2);
        string memory circle3 = randomOneCircle(randomSeed, 3);

        return string(abi.encodePacked(circle1, circle2, circle3));
    }

    function randomOneCircle(uint256 randomSeed, uint8 index) internal pure returns (string memory){
        uint16[3] memory circle; //cx cy r
        if(index == 1){
            circle[0] = uint16(randomSeed%90) + 36;
            circle[1] = uint16(randomSeed%90) + 36; //Todo more random
            circle[2] = uint16(randomSeed%50) + 125;
        }else if(index == 2){
            circle[0] = uint16(randomSeed%90) + 224;
            circle[1] = uint16(randomSeed%90) + 109;
            circle[2] = uint16(randomSeed%50) + 125;
        }else if(index == 3){
            circle[0] = uint16(randomSeed%90) + 60;
            circle[1] = uint16(randomSeed%90) + 224;
            circle[2] = uint16(randomSeed%50) + 125;
        }
        // 0-blue 1-red 2-yellow 3-purple
        string[3] memory color;
        if(randomSeed % 4 == 0){
            //Todo 里面也应该是乱序的，即有 3*4=12种可能
            color = ['#09957C', '#26EEE2', '#0D44D1'];
        }else if(randomSeed % 4 == 1){
            color = ['#CB09A0', '#820312', '#C10633'];
        }else if(randomSeed % 4 == 2){
            color = ['#CB09A0', '#820312', '#C10633'];
        }else if(randomSeed % 4 == 3){
            color = ['#4D3EFF', '#9506D8', '#760AE2'];
        }

        string[9] memory parts;
        parts[0] = '<circle cx="';
        parts[1] = circle[0].toString();
        parts[2] = '" cy="';
        parts[3] = circle[1].toString();
        parts[4] = '" r="';
        parts[5] = circle[2].toString();
        parts[6] = '" fill="';
        parts[7] = color[0]; //color
        parts[8] = '" style="filter: url(#f)"/>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        return output;
    }


    function randomSymbol(uint256 randomSeed, bool hasMemo) internal pure returns (string memory){
        string[4] memory parts;

        parts[0] = '<g fill="none" stroke="#fff" stroke-linejoin="round"';
        if(hasMemo){
            parts[1] = ' opacity="0.25">';
        }else{
            parts[1] = '>';
        }

        uint8 index = uint8(randomSeed%5);
        // 0-apx 1-bnb 2-eth 3-usdt 4-btc
        if(index == 0){
            parts[2] = '<g stroke-width="2.73438"><path d="M241.138 132.331C229.842 158.316 211.366 180.527 187.885 196.348C164.404 212.17 136.898 220.941 108.605 221.631C102.749 212.917 98.6651 203.133 96.5855 192.838C94.506 182.543 94.4717 171.939 96.4847 161.631C98.4977 151.323 102.519 141.513 108.318 132.761C114.117 124.009 121.58 116.487 130.283 110.623C138.985 104.76 148.755 100.67 159.036 98.5877C169.317 96.5053 179.906 96.471 190.2 98.4868C200.494 100.503 210.29 104.529 219.03 110.336C227.77 116.143 235.283 123.617 241.138 132.331Z"/><path d="M246.34 131.831V121.915C246.341 121.812 246.368 121.711 246.419 121.623C246.47 121.535 246.542 121.462 246.629 121.413L255.17 116.392C255.254 116.341 255.35 116.314 255.447 116.314C255.544 116.314 255.64 116.341 255.724 116.392C255.808 116.443 255.878 116.516 255.927 116.604C255.975 116.692 256 116.792 256 116.894V126.81C255.999 126.912 255.973 127.011 255.925 127.099C255.876 127.187 255.807 127.261 255.723 127.313L247.17 132.334C247.086 132.384 246.99 132.411 246.893 132.411C246.796 132.411 246.7 132.384 246.616 132.333C246.532 132.282 246.462 132.209 246.413 132.121C246.365 132.033 246.34 131.933 246.34 131.831Z" /><path d="M239.47 222.929C249.173 209.346 254.389 193.065 254.39 176.365C254.394 164.058 251.545 151.918 246.069 140.9C221.119 173.185 205.304 211.598 200.284 252.111C216.067 246.715 229.768 236.512 239.47 222.929Z" /></g>';
        }else if(index == 1){
            parts[2] = '<path stroke-width="2.73438" d="M125.641 175l-20.25 20.391L85 175l20.391-20.391L125.641 175zM175 125.641l34.875 34.875 20.391-20.391-34.875-34.734L175 85l-20.391 20.391-34.734 34.734 20.391 20.391L175 125.641zm69.609 28.968L224.359 175l20.391 20.391L265 175l-20.391-20.391zM175 224.359l-34.875-34.875-20.25 20.391 34.875 34.875L175 265l20.391-20.391 34.875-34.875-20.391-20.25L175 224.359zm0-28.968L195.391 175 175 154.609 154.609 175 175 195.391z"/>';
        }else if(index == 2){
            parts[2] = '<g stroke-width="2.6"><path d="M175.837 76l-.145 72.589-59.661 26.621L175.837 76z"/><path d="M175.692 148.589l-.138 63.115-59.523-36.494 59.661-26.621zm-.161 76.043l-.107 48.671L116 189.149l59.531 35.483z"/><path d="M175.837 76l-.145 72.589 59.546 26.874L175.837 76z"/><path d="M175.692 148.589l-.138 63.115 59.684-36.241-59.546-26.874zm-.161 76.042l-.107 48.671 59.783-83.901-59.676 35.23z"/></g>';
        }else if(index == 3){
            parts[2] = '<path d="M192.852 181.017c-.944 0-6.369.472-17.927.472-9.435 0-15.804-.236-18.162-.472-35.618-1.416-62.507-7.787-62.507-15.102 0-7.551 26.654-13.686 62.507-15.338v24.305c2.358.236 8.963.472 18.398.472 11.086 0 16.747-.472 17.691-.472v-24.305c35.853 1.652 62.507 7.787 62.507 15.338 0 7.315-26.654 13.686-62.507 15.102zm0-33.036v-21.709h50.005V93H106.993v33.272h50.005v21.709C116.428 149.869 86 157.892 86 167.567s30.428 17.698 70.998 19.586V257h36.089v-69.847c40.571-1.888 70.999-9.911 70.999-19.586-.236-9.675-30.664-17.698-71.234-19.586z" />';
        }else if(index == 4){
            parts[2] = '<path d="M198.14 170.325v-.431c23.889-3.914 35.834-15.797 35.834-35.651 0-12.896-5.03-22.054-15.09-27.477-7.65-4.128-18.21-6.688-31.68-7.677V79H172.67v19.608h-14.094V79h-14.551v19.608h-35.369l.099 17.162h18.937a5.34 5.34 0 0 1 3.775 1.564c1.001 1.002 1.564 2.36 1.564 3.776v102.965c0 1.416-.563 2.774-1.564 3.776a5.34 5.34 0 0 1-3.775 1.563h-19.07l-.149 21.234h35.519v19.898h14.534v-19.898h14.094v19.898h14.535v-20.412c15.255-1.106 27.443-4.085 36.563-8.938 11.872-6.296 17.809-17.35 17.809-33.164.033-21.545-14.429-34.114-43.387-37.707zm-39.365-54.555c18.057 0 48.311 0 48.311 21.806s-30.254 21.805-48.311 21.805V115.77zm0 112.227v-45.319c21.183 0 56.652 0 56.652 22.66s-35.469 22.659-56.652 22.659z" />';
        }

        parts[3] = '</g>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        return output;
    }

    function nftProperty(uint256 tokenId, uint8 level, uint256 mintTimestamp) internal pure returns (string memory){
        string[7] memory parts;
        parts[0] = '<g fill="white" font-family="Arial" text-anchor="middle" font-size="12px"><text x="50%" y="331"># ';
        parts[1] = tokenIdZeroPadding(tokenId);
        parts[2] = '</text><text x="50%" y="29">LV.';
        parts[3] = level.toString();
        parts[4] = '</text><text transform="rotate(90) translate(175, -335)" font-size="8px">';
        parts[5] = TimeUtils.timestampToDateTimeNoSecondUtc(mintTimestamp); //transfer
        parts[6] = '</text></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        return output;
    }

    function tokenIdZeroPadding(uint256 tokenId) internal pure returns (string memory){
        if(tokenId >= 1000000){
            return tokenId.toString();
        }else if(tokenId >= 100000){
            return string(abi.encodePacked('0', tokenId.toString()));
        }else if(tokenId >= 10000){
            return string(abi.encodePacked('00', tokenId.toString()));
        }else if(tokenId >= 1000){
            return string(abi.encodePacked('000', tokenId.toString()));
        }else if(tokenId >= 100){
            return string(abi.encodePacked('0000', tokenId.toString()));
        }else if(tokenId >= 10){
            return string(abi.encodePacked('00000', tokenId.toString()));
        }else{
            return string(abi.encodePacked('000000', tokenId.toString()));
        }
    }

    function nftMemo(string memory memo) internal pure returns (string memory){
        string[3] memory parts;
        parts[0] = '<text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="white" font-family="Arial" font-size="12px" transform="translate(0, -36)">';
        parts[1] = memo;
        parts[2] = '</text>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    function frame() internal pure returns (string memory){
        return '<g fill="none"><path d="M50.113 327.8L53 330.687l2.887-2.887L53 324.913l-2.887 2.887zm2.887.5h39.8v-1H53v1zm204.5-1h-.5v1h.5v-1zm40.887.5l-2.887-2.887-2.887 2.887 2.887 2.887 2.887-2.887zm-40.887.5h38v-1h-38v1z" fill="#fff"/><g stroke="#fff"><path transform="rotate(315 97.983 327.783)" d="M97.982 327.783h5.484v5.484h-5.484z"/><path transform="rotate(315 243.75 327.783)" d="M243.75 327.783h5.484v5.484h-5.484z"/><path d="M257.318 327.783l-8.978 8.729H101.695l-8.978-8.729 8.978-8.728H248.34l8.978 8.728zM81.281 30.711h77.207l-4.101-4.101H77.18l4.102 4.101zm195.797 0h-77.51l4.093-4.101h77.519l-4.102 4.101z"/></g><path d="M55.113 26.609L58 29.496l2.887-2.887L58 23.723l-2.887 2.887zm99.274.5a.5.5 0 1 0 0-1v1zm-96.387 0h96.387v-1H58v1zm145.947-1h-.5v1h.5v-1zm99.616.5l-2.887-2.887-2.887 2.887 2.887 2.887 2.887-2.887zm-99.616.5h96.729v-1h-96.729v1z" fill="#fff"/><mask id="A" maskUnits="userSpaceOnUse" x="147" y="26" width="61" height="15" mask-type="alpha"><path fill="#c4c4c4" d="M147.209 26.268h60.498v14.697h-60.498z"/></mask><g mask="url(#A)"><path d="M163.273 35.496h31.446" stroke="#fff"/><path d="M149.943 22.166l13.33 13.33m31.446 0l11.674-11.621" stroke="#fff" stroke-linecap="round"/></g><mask id="B" maskUnits="userSpaceOnUse" x="313" y="161" width="13" height="27" mask-type="alpha"><path transform="rotate(90 325.391 161.328)" fill="#c4c4c4" d="M325.391 161.328h25.977v11.963h-25.977z"/></mask><g mask="url(#B)"><path transform="rotate(45 325.635 165.088)" stroke="#fff" d="M325.635 165.088h13.672v13.672h-13.672z"/><path transform="rotate(45 325.635 170.067)" fill="#fff" d="M325.635 170.067h6.63v6.63h-6.63z"/></g><g fill="#fff"><path d="M320.947 169.702h-.5a.5.5 0 0 0 .846.361l-.346-.361zm0-56.225l-.353-.354-.147.146v.208h.5zm4.102-4.102h.5v-1.207l-.854.853.354.354zm0 56.396l.346.361.154-.147v-.214h-.5zm-3.602 3.931v-56.225h-1v56.225h1zm-.146-55.872l4.101-4.101-.707-.708-4.101 4.102.707.707zm3.248-4.455v56.396h1v-56.396h-1zm.154 56.035l-4.102 3.931.692.722 4.102-3.931-.692-.722zm-3.756 14.375h-.5a.5.5 0 0 1 .846-.361l-.346.361zm0 56.226l-.353.353-.147-.146v-.207h.5zm4.102 4.101h.5v1.207l-.854-.853.354-.354zm0-56.396l.346-.361.154.147v.214h-.5zm-3.602-3.931v56.226h-1v-56.226h1zm-.146 55.872l4.101 4.102-.707.707-4.101-4.102.707-.707zm3.248 4.455v-56.396h1v56.396h-1zm.154-56.035l-4.102-3.931.692-.722 4.102 3.931-.692.722z"/><path d="M325.049 50.775l-2.887 2.887 2.887 2.887 2.887-2.887-2.887-2.887zm-.5 2.887v112.109h1V53.662h-1zm1 130.567v-.5h-1v.5h1zm-.5 114.996l2.887-2.887-2.887-2.887-2.887 2.887 2.887 2.887zm-.5-114.996v112.109h1V184.229h-1z"/></g><mask id="C" maskUnits="userSpaceOnUse" x="23" y="161" width="13" height="27" mask-type="alpha"><path transform="matrix(0 1 1 0 23.9258 161.328)" fill="#c4c4c4" d="M0 0h25.977v11.963H0z"/></mask><g mask="url(#C)"><path transform="matrix(-.707107 .707107 .707107 .707107 23.6812 165.088)" stroke="#fff" d="M0 0h13.672v13.672H0z"/><path transform="matrix(-.707107 .707107 .707107 .707107 23.6812 170.067)" fill="#fff" d="M0 0h6.63v6.63H0z"/></g><g fill="#fff"><path d="M28.369 169.702h.5a.5.5 0 0 1-.846.361l.346-.361zm0-56.225l.354-.354.146.146v.208h-.5zm-4.101-4.102h-.5v-1.207l.853.853-.353.354zm0 56.396l-.346.361-.154-.147v-.214h.5zm3.601 3.931v-56.225h1v56.225h-1zm.146-55.872l-4.102-4.101.707-.708 4.102 4.102-.707.707zm-3.248-4.455v56.396h-1v-56.396h1zm-.154 56.035l4.102 3.931-.692.722-4.102-3.931.692-.722zm3.756 14.375h.5a.5.5 0 0 0-.846-.361l.346.361zm0 56.226l.354.353.146-.146v-.207h-.5zm-4.101 4.101h-.5v1.207l.853-.853-.353-.354zm0-56.396l-.346-.361-.154.147v.214h.5zm3.601-3.931v56.226h1v-56.226h-1zm.146 55.872l-4.102 4.102.707.707 4.102-4.102-.707-.707zm-3.248 4.455v-56.396h-1v56.396h1zm-.154-56.035l4.102-3.931-.692-.722-4.102 3.931.692.722z"/><path d="M24.268 50.775l2.887 2.887-2.887 2.887-2.887-2.887 2.887-2.887zm.5 2.887v112.109h-1V53.662h1zm-1 130.567v-.5h1v.5h-1zm.5 114.996l-2.887-2.887 2.887-2.887 2.887 2.887-2.887 2.887zm.5-114.996v112.109h-1V184.229h1z"/></g></g>';
    }

    function bottom(uint256 randomSeed) internal pure returns (string memory){
        string[2] memory parts;

        // <!-- pink: #FFA6DC, green: #A6FFD6, blue: #A6E7FF, yellow: #FFFAA6 -->
        //<!-- hollow => fill="none" -->
        uint8 index = uint8(randomSeed%8);
        if(index == 0){
            parts[0] = '<g stroke="#A6FFD6" fill="#A6FFD6">';
        }else if(index == 1){
            parts[0] = '<g stroke="#A6FFD6" fill="none">';
        }else if(index == 2){
            parts[0] = '<g stroke="#FFA6DC" fill="#FFA6DC">';
        }else if(index == 3){
            parts[0] = '<g stroke="#FFA6DC" fill="none">';
        }else if(index == 4){
            parts[0] = '<g stroke="#A6E7FF" fill="#A6E7FF">';
        }else if(index == 5){
            parts[0] = '<g stroke="#A6E7FF" fill="none"> ';
        }else if(index == 6){
            parts[0] = '<g stroke="#FFFAA6" fill="#FFFAA6">';
        }else if(index == 7){
            parts[0] = '<g stroke="#FFFAA6" fill="none">';
        }
        parts[1] = '<path d="M15.5 15.5h17v17h-17z"/><circle cx="326" cy="24" r="8.5"/><path d="M15.773 333.75L24 319.5l8.227 14.25H15.773z"/><path d="M325.596 329.247l-3.383 5.253h-4.253l5.871-8.389.205-.292-.21-.289-5.844-8.03h4.241l3.382 4.914.413.602.412-.603 3.349-4.913h4.237l-5.858 8.03-.211.289.206.293 5.885 8.388h-4.249l-3.351-5.251-.42-.657-.422.655z"/></g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        return output;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

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