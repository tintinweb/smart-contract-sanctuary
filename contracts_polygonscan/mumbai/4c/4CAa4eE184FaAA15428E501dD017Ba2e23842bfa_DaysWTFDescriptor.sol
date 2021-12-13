// SPDX-License-Identifier: GPL-3.0

/// @title The Days.WTF NFT descriptor

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { IDaysWTFDescriptor } from './interfaces/IDaysWTFDescriptor.sol';
import { IOracle } from './interfaces/IOracle.sol';
import { IDaysWTFAuctionHouse } from './interfaces/IDaysWTFAuctionHouse.sol';
import { Base64 } from 'base64-sol/base64.sol';

//import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { IDaysWTFToken } from './interfaces/IDaysWTFToken.sol';

//import { DayLib } from './libs/DayLib.sol';

contract DaysWTFDescriptor is IDaysWTFDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Chainlink price feed
    IOracle public priceOracle;
    int256 public lastPrice;

    // converting Solidity timestamp to Day YMD format
    uint256 constant MIN_TIMESTAMP = 946684800; // 2000-01-01 00:00:00 UTC
    uint256 constant DAYS_IN_YEAR = 365;
    uint256 constant DAYS_IN_4_YEARS_WITH_LEAP_YEAR = DAYS_IN_YEAR * 4 + 1;
    uint256 constant DAYS_IN_100_YEARS = DAYS_IN_4_YEARS_WITH_LEAP_YEAR * 25 - 1;
    uint256 constant DAYS_IN_400_YEARS = DAYS_IN_100_YEARS * 4 + 1;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public isDataURIEnabled = true;

    // Base URI
    string public baseURI;

    /**
        @notice Constructor for the Days.WTF NFT descriptor contract.
        @param _priceOracle The oracle contract for the chainlink price feed.
        @param _lastPrice The last price from the chainlink price feed.
        @param _baseURI The base URI for the NFTs.
     */
    constructor(
        address _priceOracle,
        int256 _lastPrice,
        string memory _baseURI
    ) {
        priceOracle = IOracle(_priceOracle);
        lastPrice = _lastPrice;
        baseURI = _baseURI;
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID, construct a token URI for an official Days.WTF DAO day.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IDaysWTFToken.DayData memory data)
        external
        view
        override
        returns (string memory)
    {
        if (isDataURIEnabled) {
            return dataURI(tokenId, data);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
        @notice Sanitize input for JSON.
        @param _inp The input to sanitize.
        @return The sanitized input.
     */
    function sanitizeJson(bytes memory _inp) internal pure returns (string memory) {
        uint256 _inpLen = _inp.length;
        uint256 i;
        uint256 k;
        bytes1 char;

        for (; i < _inpLen; i++) {
            char = _inp[i];
            if (char == '"' || char == '\\') continue;
            if (i > k) _inp[k++] = char;
        }

        bytes memory output = new bytes(k);
        for (i = 0; i < k; i++) output[i] = _inp[i];

        return string(output);
    }

    /**
        @notice Sanitize input for SVG.
        @param _inp The input to sanitize.
        @return The sanitized input.
     */
    function sanitizeSvg(bytes memory _inp) internal pure returns (string memory) {
        uint256 _inpLen = _inp.length;
        uint256 i;
        uint256 k;
        bytes1 char;

        for (; i < _inpLen; i++) {
            char = _inp[i];
            if (char == '<') continue;
            if (i > k) _inp[k++] = char;
        }

        bytes memory output = new bytes(k);
        for (i = 0; i < k; i++) output[i] = _inp[i];

        return string(output);
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Days.WTF DAO day.
     */
    function dataURI(uint256 tokenId, IDaysWTFToken.DayData memory data) public pure override returns (string memory) {
        bytes memory date = bytes(dayIdToString(tokenId));
        bytes memory name = abi.encodePacked(data.name);
        IDaysWTFToken.DayLevel level = getDayLevel(tokenId);
        bytes memory levelTxt = dayLevelToBytes(level);

        // get description
        bytes memory description;
        if (keccak256('') != keccak256(name)) {
            description = abi.encodePacked(
                date,
                ' is a member of the TiTS DAO (Treasury in Time-Space).\r\n\r\n\\"',
                sanitizeJson(name),
                '\\"'
            );
        } else {
            description = abi.encodePacked(date, ' is a member of the TiTS DAO (Treasury in Time-Space).');
        }

        // get price change
        (, int16 change, uint232 random) = parseSeed(data.seed);
        bytes memory changeTxt;
        if (change != 0 && level == IDaysWTFToken.DayLevel.MONTH) {
            if (change > 0)
                changeTxt = abi.encodePacked(
                    ',{"trait_type":"Monthly Close","value":"Positive"},{"display_type":"boost_percentage","trait_type":"Market Change","value":',
                    change,
                    '}'
                );
            else
                changeTxt = abi.encodePacked(
                    ',{"trait_type":"Monthly Close","value":"Negative"},{"display_type":"boost_percentage","trait_type":"Market Change","value":',
                    change,
                    '}'
                );
        }

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            date,
                            '","description":"',
                            description,
                            '","external_url":"https://days.wtf/days/',
                            date,
                            '","attributes":[{"trait_type":"Type","value":"',
                            levelTxt,
                            '"}',
                            changeTxt,
                            '}],"image":"data:image/svg+xml;base64,',
                            generateSVGImage(date, bytes(sanitizeSvg(name)), level, levelTxt, change, random),
                            '"}'
                        )
                    )
                )
            );
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(
        bytes memory _date,
        bytes memory _name,
        IDaysWTFToken.DayLevel _level,
        bytes memory _levelTxt,
        int16 _change,
        uint232 // random seed
    ) public pure override returns (string memory) {
        bytes memory _type;
        bytes memory icon;
        bytes memory color;
        if (uint256(_level) > 0) _type = _levelTxt;

        if (_level == IDaysWTFToken.DayLevel.MILLENNIUM) {
            icon = '<svg opacity=".15" x="60" y="35" width="80" height="80" viewBox="0 0 32 32"><path d="M26.7 9.5a.5.5 0 0 0-.4-.3h-1a.5.5 0 0 0-.4.3l-.4 1.2a.5.5 0 0 0 0 .2v.8L20 1a.5.5 0 0 0-.5-.3H17a.5.5 0 0 0-.5.5V5h-1.3V1.3a.5.5 0 0 0-.5-.5H12a.5.5 0 0 0-.5.3L5.2 16a.5.5 0 0 0 0 .1.5.5 0 0 0 0 .2.5.5 0 0 0 .1.2.5.5 0 0 0 .1.1l1.8.8h-2a.5.5 0 0 0-.5.5v2.3a.5.5 0 0 0 .5.5h2.2l-1.9.8a.5.5 0 0 0-.3.6 11 11 0 0 0 3 4.9l-.4.4a.5.5 0 0 0 0 .7 13.3 13.3 0 0 0 8 3 12.7 12.7 0 0 0 7.6-2.8.5.5 0 0 0 0-.7l-.3-.5a11 11 0 0 0 3.2-5 .5.5 0 0 0-.3-.5l-1.7-.8h2a.5.5 0 0 0 .4-.5v-2.4a.5.5 0 0 0-.5-.5h-2l1.8-.8a.5.5 0 0 0 .3-.6l-.4-.8 1-.4a.5.5 0 0 0 .3-.5V11a.5.5 0 0 0 0-.2zm-1 .7h.2l.3.8v.3h-.8V11zM17 17a2.4 2.4 0 1 1-1.1-.3 2.4 2.4 0 0 1 1.1.3zm6.5 1.4v1.4h-4.3a3.3 3.3 0 0 0 0-1.4zm-5 2.8a3.4 3.4 0 0 0 .3-.4h2.7a6 6 0 0 1-1.4 2.4zm-7 2a5.8 5.8 0 0 1-1.3-2.4h2.7a3.4 3.4 0 0 0 .3.4zm-5-7.3c1.5-3.6 4-5.8 7-6.5l-.2 3.3a7 7 0 0 0-4 4.5l-2.9-1.3zm8.4-9.8h2l.7 8.3H14zm3.6 6.6-.3-3.3a8.6 8.6 0 0 1 3.2 1.4L19.2 13a6.8 6.8 0 0 0-.8-.4zm-7.5 3 2 1.7h-2.7a5.9 5.9 0 0 1 .7-1.7zm1.5 2.7a3.3 3.3 0 0 0 0 1.4H8.1v-1.4zm3.4-2.7a3.4 3.4 0 0 0-2.3.9l-2-1.6a5.9 5.9 0 0 1 1.4-1.1l-.1 1a.5.5 0 0 0 .5.5h4.7L17 16a3.4 3.4 0 0 0-1.2-.2zm2.7-.4a.5.5 0 0 0 .1-.4v-1a6 6 0 0 1 1.2 1l-1.4.5zm2.3-1a6.9 6.9 0 0 0-.8-.6l2-2.3a11 11 0 0 1 1.6 1.8zM19.2 1.9l4 9.3A9.8 9.8 0 0 0 18 8.3l-.3-2.7a.5.5 0 0 0-.3-.4V1.8zm-6.9 0h1.8v3.4a.5.5 0 0 0-.3.4l-.3 2.7a10 10 0 0 0-5.1 2.8zM5.8 18.4H7v1.4H5.8zm.5 4L9.2 21a6.9 6.9 0 0 0 1.6 2.8l-2 2.3a10 10 0 0 1-2.5-3.9zm9.5 7.8a12.3 12.3 0 0 1-7-2.5l5-5.8a3.4 3.4 0 0 0 4 0l4.7 6a11.8 11.8 0 0 1-6.7 2.3zm6.7-3.8L20.7 24a7 7 0 0 0 1.8-3l2.8 1.3a10 10 0 0 1-2.6 4.1zm3.3-6.6h-1.4v-1.4h1.4zm-.6-3.9-3.3 1.4a.5.5 0 0 0-.2.1h-.9l4.2-1.8zm-6.5 1.4a3.4 3.4 0 0 0-.7-.7l7.2-3a.5.5 0 0 0 .3-.5v-.8h.7V14z"/></svg>';
            color = '<stop offset="0" stop-color= "#da4453"/><stop offset="1" stop-color= "#89216b"/>';
        } else if (_level == IDaysWTFToken.DayLevel.CENTURY) {
            icon = '<svg opacity=".2" x="64" y="39" width="72" height="72" viewBox="0 0 100 100"><path d="M97.7 100H81.8c-.5 0-.9-.3-1.1-.7l-12-23.8c-.6-1.2-1.7-2.1-3-2.4s-2.6-.1-3.8.7c-1.9 1.3-2.4 4-1.3 6.1l1.1 2.1c6.5 10.9-1.5 17.6-1.6 17.7-.2.2-.5.3-.8.3H33c-.4 0-.8-.2-1.1-.6-.2-.4-.2-.9.1-1.2l1-1.5a25.3 25.3 0 0 0 3.2-22v-.1l-1.8-7.3c-1.8-8.3.2-16.9 5.4-23.7 5-6.5 12.5-10.4 20.6-10.8h1.3c1.4-.1 26.9-1.5 35.6 20.9 1 2.7 1.6 5.6 1.6 8.7a6 6 0 0 1-5.9 5.9h-.4c-1.9 0-3.5 1.6-3.5 3.5s1.6 3.5 3.5 3.5c3.5 0 6.3 2.8 6.3 6.3v17.3c0 .6-.5 1.1-1.2 1.1zm-15.2-2.4h14V81.5c0-2.2-1.8-3.9-3.9-3.9a6 6 0 0 1 0-11.8h.4c2 0 3.5-1.6 3.5-3.5a22 22 0 0 0-1.4-7.8C86.9 33.2 62.9 35 61.9 35.1h-1.3A24.7 24.7 0 0 0 41.8 45a26 26 0 0 0-4.9 21.7l1.7 7.2a28 28 0 0 1-3.3 23.7h23.8c1.2-1.2 5.6-6.3.8-14.4L58.7 81a7.1 7.1 0 0 1 2.1-9.2 6.8 6.8 0 0 1 5.7-1 6.8 6.8 0 0 1 4.5 3.6zm-74-7.8-.4-.1c-.3-.1-.5-.3-.7-.6a62 62 0 0 1 90.2-78.5c.3.2.4.5.5.8s0 .6-.2.9L84.5 32c-.4.5-1.1.7-1.7.3-.5-.4-.7-1.1-.3-1.7l12.7-18.8A59.6 59.6 0 0 0 9 87l20.4-10c.6-.3 1.3 0 1.6.5.3.6 0 1.3-.5 1.6L9 89.7l-.5.1z"/><path d="M29.9 79.3c-.4 0-.9-.2-1.1-.7A38.2 38.2 0 0 1 63 23.9c7.6 0 15 2.2 21.3 6.5.5.3.7 1 .4 1.6l-3.2 6c-.3.6-1 .8-1.6.5s-.8-1-.5-1.6l2.7-5a35.7 35.7 0 0 0-51.5 44.7l6.6-2.8c.6-.3 1.3 0 1.6.6s0 1.3-.6 1.6l-7.7 3.2-.6.1z"/></svg>';
            color = '<stop offset="0" stop-color="#4b6cb7"/><stop offset="1" stop-color="#182848"/>';
        } else if (_level == IDaysWTFToken.DayLevel.DECADE) {
            icon = '<svg opacity=".07" x="56" y="29" width="88" height="88" viewBox="0 0 100 100"><circle cx="27.8" cy="19.5" r="8.2"/><circle cx="50" cy="19.5" r="8.2"/><circle cx="72.2" cy="19.5" r="8.2"/><circle cx="27.8" cy="41" r="8.2"/><circle cx="50" cy="41" r="8.2"/><circle cx="72.2" cy="41" r="8.2"/><circle cx="27.8" cy="62.6" r="8.2"/><circle cx="50" cy="62.6" r="8.2"/><circle cx="72.2" cy="62.6" r="8.2"/><circle cx="50" cy="84" r="8.2"/></svg>';
            color = '<stop offset="0" stop-color="#e3230d"/><stop offset="1" stop-color="#f58719"/>';
        } else if (_level == IDaysWTFToken.DayLevel.LEAP) {
            icon = '<svg opacity=".07" x="53" y="26" width="94" height="94" viewBox="0 0 208 176"><path fill="#fff" d="M101 11a78 78 0 1 0 1 156 78 78 0 0 0-1-156zm0 145a67 67 0 1 1 1-134 67 67 0 0 1-1 134zm5-92V46h9l-14-17-13 17h9v18a26 26 0 0 0 0 50v17h-9l14 18 13-18h-9v-17a26 26 0 0 0 0-50z"/></svg>';
            color = '<stop offset="0" stop-color="#780206"/><stop offset="1" stop-color="#061161"/>';
        } else if (_level == IDaysWTFToken.DayLevel.YEAR) {
            icon = '<svg opacity=".1" x="50" y="20" width="100" height="100" viewBox="0 0 100 100"><path d="m49.2 29.7-18.4-5.4a.4.4 0 0 0-.4.2l-7 15.4-.1.1a12.3 12.3 0 0 0 6.5 15.8l-5 16.8H14.5a.4.4 0 0 0-.4.4.4.4 0 0 0 .3.4L36.2 80a.4.4 0 0 0 .4-.3.4.4 0 0 0-.1-.5L28 73.5l5-16.8a12.3 12.3 0 0 0 7.2-1A12.4 12.4 0 0 0 47 47l2.6-16.8a.4.4 0 0 0-.3-.5zm-5.4 16.7a9.2 9.2 0 0 1-5 6.4A9.1 9.1 0 0 1 26 41.9l.2-.7 6-13.1L46 32zM35 40c1.6 2.8 4.3 4.4 8.2 3.9l-.3 2.3a8.3 8.3 0 1 1-16.1-4 5.5 5.5 0 0 1 .2-.6l1.3-3c3.2-.4 5.9-.1 6.7 1.4zm50.3 39H75.1l-5-16.8a12.3 12.3 0 0 0 6.5-15.7v-.1l-7-15.4a.4.4 0 0 0-.4-.2l-18.4 5.4a.4.4 0 0 0-.3.4l2.6 16.8a12.4 12.4 0 0 0 6.7 8.7 12.2 12.2 0 0 0 7.3 1L72 80l-8.6 5.7a.4.4 0 0 0-.2.5.4.4 0 0 0 .5.2l21.8-6.5a.4.4 0 0 0 .3-.4.4.4 0 0 0-.5-.3zM61.2 59.3a9.2 9.2 0 0 1-5-6.4l-2.1-14.2 13.6-4 6 13.1.3.7a9.1 9.1 0 0 1-12.8 10.8zm11-3.9A8.3 8.3 0 0 1 57 52.7l-.3-2.4c3.8.5 6.6-1 8.2-3.9.8-1.5 3.5-1.7 6.7-1.4l1.3 3a6 6 0 0 1 .2.6 8.3 8.3 0 0 1-.8 6.7z"/></svg>';
            color = '<stop offset="0" stop-color="#40e0d0"/><stop offset="0.5" stop-color="#ff8c00"/><stop offset="1" stop-color="#ff0080"/>';
        } else if (_level == IDaysWTFToken.DayLevel.MONTH) {
            icon = '<svg opacity=".05" x="68" y="43" width="64" height="64" viewBox="0 0 448 512"><path d="M436 160H12a12 12 0 0 1-12-12v-36a48 48 0 0 1 48-48h48V12a12 12 0 0 1 12-12h40a12 12 0 0 1 12 12v52h128V12a12 12 0 0 1 12-12h40a12 12 0 0 1 12 12v52h48a48 48 0 0 1 48 48v36a12 12 0 0 1-12 12zM12 192h424a12 12 0 0 1 12 12v260a48 48 0 0 1-48 48H48a48 48 0 0 1-48-48V204a12 12 0 0 1 12-12zm333.3 96-28.2-28.5a12 12 0 0 0-17 0l-106 105.2-46-46.4a12 12 0 0 0-17 0l-28.3 28.1a12 12 0 0 0-.1 17l82.6 83.3a12 12 0 0 0 17 0l143-141.8a12 12 0 0 0 0-17z"/></svg>';

            if (_change > 0) color = '<stop offset="0" stop-color="#227e22"/><stop offset="1" stop-color="#63a211"/>';
            else if (_change < 0)
                color = '<stop offset="0" stop-color="#fbc2eb"/><stop offset="1" stop-color="#a18cd1"/>';
            else color = '<stop offset="0" stop-color="#f00000"/><stop offset="1" stop-color="#dc281e"/>';
        } else color = '<stop offset="0" stop-color="#8e9eab"/><stop offset="1" stop-color="#dbe4e6"/>';

        return
            Base64.encode(
                //string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" viewBox="0 0 200 200"><defs><linearGradient id="color" x1="0" y1="0" x2="1" y2="0">',
                    color,
                    '</linearGradient></defs><style type="text/css">tspan,.txt{font-family:"Open Sans",sans-serif;font-size:32px;font-weight:bold;fill:rgba(255,255,255,0.8)}.sm{font-size:15px;fill:rgba(255,255,255,0.5)}.txt{font-weight:normal;font-size:15px;color:rgba(255,255,255,0.6)}</style><g><rect width="200" height="200" fill="url(#color)"></rect>',
                    icon,
                    '<text y="145" transform="translate(100)"><tspan x="2" text-anchor="middle">',
                    _date,
                    '</tspan><tspan class="sm" x="0" text-anchor="middle" dy="20">',
                    _type,
                    '</tspan></text><foreignObject class="txt" x="15" y="40" width="170" height="65"><xhtml:div style="display:grid;place-items:center;height:100%;word-break:break-all;overflow:hidden"><xhtml:div style="text-align:center">',
                    _name,
                    '</xhtml:div></xhtml:div></foreignObject></g></svg>'
                )
                //)
            );
    }

    /**
        @notice Whether year is a leap year.
        @param year The year to check.
        @return Whether or not the year is a leap year.
    */
    function isLeapYear(uint256 year) public pure override returns (bool) {
        return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    }

    /**
        @notice Get the number of days in a month.
        @param year The year to check.
        @param month The month to check.
        @return The number of days in the month.
     */
    function getDaysInMonth(uint256 year, uint256 month) public pure returns (uint256) {
        if (month == 2) {
            if (isLeapYear(year)) return 29;
            else return 28;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
        else return 31;
    }

    /**
        @notice Check if a day is a valid day in a month and year.
        @param year The year to check.
        @param month The month to check.
        @param day The day to check.
        @return Whether or not the day is valid.
     */
    function isValidDay(
        uint256 year,
        uint256 month,
        uint256 day
    ) public pure override returns (bool) {
        if (!isValidYear(year) || !isValidMonth(month)) return false;
        return 1 <= day && day <= getDaysInMonth(year, month);
    }

    /**
        @notice Check if a month is a valid month.
        @param month The month to check.
        @return Whether or not the month is valid.
     */
    function isValidMonth(uint256 month) public pure override returns (bool) {
        return 1 <= month && month <= 12;
    }

    /**
        @notice Check if a year is a valid year.
        @dev -9999 to 9999 are valid
        @param year The year to check.
        @return Whether or not the year is valid.
     */
    function isValidYear(uint256 year) public pure override returns (bool) {
        return year <= 9999;
    }

    /**
        @notice Get the number of days in a year considering leap years.
        @param year The year to check.
        @return The number of days in the year.
     */
    function getDaysInYear(uint256 year) public pure override returns (uint256) {
        if (isLeapYear(year)) {
            return 366;
        }
        return 365;
    }

    /**
        @notice Convert a Solidity timestamp to Day.
        @dev Requires a valid day. Used only for determining actual Day during auction. Works for Timestamps after 2000-01-01 00:00:00 UTC.
        @param timestamp The timestamp to convert.
        @return The Day YMD format.
    */
    function timestampToDay(uint256 timestamp) public pure override returns (Day memory) {
        require(timestamp >= MIN_TIMESTAMP, 'Timestamp must be greater than or equal to 2000-01-01 00:00:00 UTC');

        uint256 _days = (timestamp - MIN_TIMESTAMP) / (24 * 60 * 60);

        uint256 year = 2000;
        uint256 month = 1;
        uint256 day = 1;
        uint256 res = 0;
        uint256 currentYearDays = 0;

        if (_days >= DAYS_IN_400_YEARS) {
            res = _days / DAYS_IN_400_YEARS;
            _days -= res * DAYS_IN_400_YEARS;
            year += 400 * res;
        }

        currentYearDays = getDaysInYear(year);
        if (_days >= currentYearDays) {
            _days -= currentYearDays;
            year++;
        }

        if (!isLeapYear(year) && _days >= DAYS_IN_100_YEARS) {
            res = _days / DAYS_IN_100_YEARS;
            _days -= res * DAYS_IN_100_YEARS;
            year += 100 * res;
        }

        if (_days >= DAYS_IN_4_YEARS_WITH_LEAP_YEAR) {
            res = _days / DAYS_IN_4_YEARS_WITH_LEAP_YEAR;
            _days -= res * DAYS_IN_4_YEARS_WITH_LEAP_YEAR;
            year += 4 * res;
        }

        currentYearDays = getDaysInYear(year);
        while (_days >= currentYearDays) {
            year++;
            _days -= currentYearDays;
            currentYearDays = getDaysInYear(year);
        }

        // get the month and day using binary search
        uint256[12] memory monthDaysCummulative;
        if (isLeapYear(year)) monthDaysCummulative = [uint256(31), 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366];
        else monthDaysCummulative = [uint256(31), 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];

        uint256 monthIndex = 0;
        uint256 monthStart = 0;
        uint256 monthEnd = 11;
        while (monthIndex < 12 && monthStart <= monthEnd) {
            monthIndex = (monthStart + monthEnd) / 2;
            if (
                _days < monthDaysCummulative[monthIndex] &&
                (monthIndex == 0 || _days >= monthDaysCummulative[monthIndex - 1])
            ) {
                break;
            } else if (_days < monthDaysCummulative[monthIndex]) {
                monthEnd = monthIndex - 1;
            } else {
                monthStart = monthIndex + 1;
            }
        }

        day = _days + 1;
        if (monthIndex > 0) day -= monthDaysCummulative[monthIndex - 1];
        month = monthIndex + 1;

        require(isValidDay(year, month, day), 'Invalid Day');

        return Day(uint16(year), uint8(month), uint8(day), false);
    }

    /**
        @notice Convert a Solidity timestamp to dayId.
        @dev Requires a valid day.
        @param timestamp The timestamp to convert.
        @return The dayId.
     */
    function timestampToDayId(uint256 timestamp) public pure override returns (uint256) {
        Day memory day = timestampToDay(timestamp);
        return dayToDayId(day);
    }

    /**
        @notice Convert YMD Date to uint256 dayId, where earlier dates are represented by smaller dayIds.
        @param _day The day to convert.
        @return The dayId.
    */
    function dayToDayId(Day memory _day) public pure override returns (uint256) {
        if (_day.negative)
            return uint256(uint40(bytes5(abi.encodePacked(false, uint16(9999) - _day.year, _day.month, _day.day))));
        else return uint256(uint40(bytes5(abi.encodePacked(true, _day.year, _day.month, _day.day))));
    }

    /**
        @notice Convert a dayId to a Day.
        @dev Requires a valid dayId.
        @param _dayId The dayId to convert.
        @return The day.
     */
    function dayIdToDay(uint256 _dayId) public pure override returns (Day memory) {
        uint256 year;
        uint256 month = uint256(uint8(_dayId >> 8));
        uint256 day = uint256(uint8(_dayId));
        bool negative;

        // if negative
        if (_dayId >> 32 == 0) {
            year = uint256(uint16(9999) - uint16(_dayId >> 16));
            negative = true;
        } else year = uint256(uint16(_dayId >> 16));

        require(isValidDay(year, month, day), 'Invalid Day');

        return Day(uint16(year), uint8(month), uint8(day), negative);
    }

    /**
        @notice Convert a dayId to string YYYY-MM-DD.
        @param day The day to convert.
        @return The string representation of the day.
     */
    function dayToString(Day memory day) public pure override returns (string memory) {
        bytes memory buffer;

        uint256 digits = 10;
        uint256 to = 0;
        if (day.negative) {
            to = 1;
            buffer = new bytes(11);
            buffer[0] = '-';
        } else {
            buffer = new bytes(10);
        }

        while (digits > 0) {
            digits--;
            if (digits == 7 || digits == 4) {
                buffer[digits + to] = '-';
            } else if (digits >= 8) {
                buffer[digits + to] = bytes1(uint8(48 + uint256(day.day % 10)));
                day.day /= 10;
            } else if (digits >= 5) {
                buffer[digits + to] = bytes1(uint8(48 + uint256(day.month % 10)));
                day.month /= 10;
            } else {
                buffer[digits + to] = bytes1(uint8(48 + uint256(day.year % 10)));
                day.year /= 10;
            }
        }

        return string(buffer);
    }

    /**
        @notice Parse a string YYYY-MM-DD to a day.
     */
    function stringToDay(string memory date) public pure override returns (Day memory) {
        // for return
        uint256 year;
        uint256 month;
        uint256 day;
        bool neagtive;

        // for parse
        bytes memory b = bytes(date);
        uint256 i;
        // if it starts with '-', it is neagtive
        if (b[0] == '-') {
            neagtive = true;
            i = 1;
        }
        // current parse length, to track number of digits
        uint256 current = 0;
        uint256 tmp;
        for (; i < b.length; i++) {
            tmp = uint256(uint8(b[i]));
            if (tmp >= 48 && tmp <= 57) {
                if (current < 4) year = year * 10 + tmp - 48;
                else if (current < 6) month = month * 10 + tmp - 48;
                else if (current < 8) day = day * 10 + tmp - 48;
                else break;
                current++;
            }
        }

        require(isValidDay(year, month, day), 'Invalid date');
        return Day(uint16(year), uint8(month), uint8(day), neagtive);
    }

    /**
        @notice Parse a string YYYY-MM-DD to a dayId.
     */
    function stringToDayId(string memory date) public pure override returns (uint256) {
        return dayToDayId(stringToDay(date));
    }

    /**
        @notice Convert a dayId to string YYYY-MM-DD.
        @param dayId The dayId to convert.
        @return The string representation of the day.
     */
    function dayIdToString(uint256 dayId) public pure override returns (string memory) {
        Day memory day = dayIdToDay(dayId);
        return dayToString(day);
    }

    /**
        @notice Get type of a given day.
        @param day The day to check.
        @return The type of the day: 0 - NORMAL, 1 - MONTH, 2 - YEAR, 3 - LEAP, 4 - DECADE, 5 - CENTURY, 6 - MILLENNIUM.
     */
    function getDayLevel(Day memory day) public pure override returns (IDaysWTFToken.DayLevel) {
        if (day.month == 1 && day.day == 1) {
            if (day.year % 1000 == 0) return IDaysWTFToken.DayLevel.MILLENNIUM;
            else if (day.year % 100 == 0) return IDaysWTFToken.DayLevel.CENTURY;
            else if (day.year % 10 == 0) return IDaysWTFToken.DayLevel.DECADE;
            else return IDaysWTFToken.DayLevel.YEAR;
        }
        if (day.day == 1) return IDaysWTFToken.DayLevel.MONTH;
        if (day.month == 2 && day.day == 29) return IDaysWTFToken.DayLevel.LEAP;
        return IDaysWTFToken.DayLevel.NORMAL;
    }

    /**
        @notice Get type of a gived dayId.
        @param dayId The dayId to check.
        @return The type of the day: 0 - NORMAL, 1 - MONTH, 2 - YEAR, 3 - LEAP, 4 - DECADE, 5 - CENTURY, 6 - MILLENNIUM.
     */
    function getDayLevel(uint256 dayId) public pure override returns (IDaysWTFToken.DayLevel) {
        Day memory day = dayIdToDay(dayId);
        return getDayLevel(day);
    }

    /**
        @notice Format dayLevel to string.
        @param _level The dayLevel to format.
        @return The string representation of the dayLevel.
     */
    function dayLevelToBytes(IDaysWTFToken.DayLevel _level) public pure override returns (bytes memory) {
        if (_level == IDaysWTFToken.DayLevel.MONTH) return 'month';
        if (_level == IDaysWTFToken.DayLevel.YEAR) return 'year';
        if (_level == IDaysWTFToken.DayLevel.LEAP) return 'leap';
        if (_level == IDaysWTFToken.DayLevel.DECADE) return 'decade';
        if (_level == IDaysWTFToken.DayLevel.CENTURY) return 'century';
        if (_level == IDaysWTFToken.DayLevel.MILLENNIUM) return 'millennium';
        return 'normal day';
    }

    /**
        @notice Get seed information for a given day.
     */
    function getSeed(uint256 dayId, IDaysWTFAuctionHouse.MintType _type) public view override returns (uint256) {
        // get pseudorandom seed
        uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), dayId)));

        // data format: 1 byte version, 2 byte price change, remaining bytes seed
        uint8 version = 1;
        int16 change;

        // query for monthly price if we freshly mint a month
        if (
            address(priceOracle) != address(0) &&
            getDayLevel(dayId) == IDaysWTFToken.DayLevel.MONTH &&
            _type == IDaysWTFAuctionHouse.MintType.TODAY
        ) {
            (, int256 price, , , ) = priceOracle.latestRoundData();
            int256 _change = (100 * price) / lastPrice - 100;
            if (_change > type(int16).max) change = type(int16).max;
            else change = int16(_change);
        }

        return uint256(bytes32(abi.encodePacked(version, change, pseudorandomness)));
    }

    /**
        @notice Parse info in seed.
        @param _seed The seed to parse.
        @return The parsed seed: 1 byte version, 2 byte price change, remaining random bytes.
     */
    function parseSeed(uint256 _seed)
        public
        pure
        returns (
            uint8,
            int16,
            uint232
        )
    {
        return (uint8(bytes1(bytes32(_seed))), int16(uint16(bytes2(bytes32(_seed << 8)))), uint232(_seed));
    }
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DaysWTFDescriptor

pragma solidity ^0.8.6;

import { IDaysWTFToken } from './IDaysWTFToken.sol';
import { IDaysWTFAuctionHouse } from './IDaysWTFAuctionHouse.sol';

interface IDaysWTFDescriptor {
    struct Day {
        uint16 year;
        uint8 month;
        uint8 day;
        bool negative;
    }

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IDaysWTFToken.DayData memory data) external view returns (string memory);

    function dataURI(uint256 tokenId, IDaysWTFToken.DayData memory data) external pure returns (string memory);

    function generateSVGImage(
        bytes memory _date,
        bytes memory _name,
        IDaysWTFToken.DayLevel _level,
        bytes memory _levelTxt,
        int16 _change,
        uint232 _random
    ) external pure returns (string memory);

    function isLeapYear(uint256 year) external pure returns (bool);

    function isValidDay(
        uint256 year,
        uint256 month,
        uint256 day
    ) external pure returns (bool);

    function isValidMonth(uint256 month) external pure returns (bool);

    function isValidYear(uint256 year) external pure returns (bool);

    function getDaysInYear(uint256 year) external pure returns (uint256);

    function timestampToDay(uint256 timestamp) external pure returns (Day memory);

    function timestampToDayId(uint256 timestamp) external pure returns (uint256);

    function dayToDayId(Day memory _day) external pure returns (uint256);

    function dayIdToDay(uint256 dayId) external pure returns (Day memory);

    function stringToDay(string memory date) external pure returns (Day memory);

    function stringToDayId(string memory date) external pure returns (uint256);

    function dayToString(Day memory day) external pure returns (string memory);

    function dayIdToString(uint256 dayId) external pure returns (string memory);

    function getDayLevel(Day memory day) external pure returns (IDaysWTFToken.DayLevel);

    function getDayLevel(uint256 dayId) external pure returns (IDaysWTFToken.DayLevel);

    function dayLevelToBytes(IDaysWTFToken.DayLevel level) external pure returns (bytes memory);

    function getSeed(uint256 dayId, IDaysWTFAuctionHouse.MintType _type) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Chainlink interface
interface IOracle {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Days.WTF Auction Houses

import { IDaysWTFToken } from './IDaysWTFToken.sol';

pragma solidity ^0.8.6;

interface IDaysWTFAuctionHouse {
    struct Bid {
        address payable bidder;
        address payable referral;
        uint256 amount;
        uint256 past;
    }

    struct Auction {
        // ID for the Days.WTF (ERC721 token ID)
        uint256 dayId;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // Whether or not the auction has been settled
        bool settled;
        Bid bidderFirst;
        Bid bidderSecond;
        Bid bidderThird;
    }

    enum MintType {
        AIRDROP,
        PAST,
        TODAY
    }

    event AirdropMinted(uint256 indexed dayId, address to, uint256 level);

    event AuctionCreated(uint256 indexed dayId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed dayId, address sender, uint256 value);

    event AuctionSettled(uint256 indexed dayId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(
        uint256 dayId,
        uint256 pastDayTimestamp,
        address _referral
    ) external payable;

    function pause() external;

    function unpause() external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IDaysWTFDescriptor } from './IDaysWTFDescriptor.sol';
import { IDaysWTFAuctionHouse } from './IDaysWTFAuctionHouse.sol';

//import { INounsSeeder } from './INounsSeeder.sol';

interface IDaysWTFToken is IERC721 {
    struct DayData {
        bytes32 name;
        string url;
        string hash;
        uint256 seed;
    }

    enum DayLevel {
        NORMAL,
        MONTH,
        YEAR,
        LEAP,
        DECADE,
        CENTURY,
        MILLENNIUM
    }

    event DayDataChanged(uint256 indexed tokenId, string data, string value);

    event DayMinted(uint256 indexed tokenId);

    event DayBurned(uint256 indexed tokenId);

    event FoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(IDaysWTFDescriptor descriptor);

    event DescriptorLocked();

    function getFoundersDAO() external view returns (address);

    function timestampToDayId(uint256 timestamp) external view returns (uint256);

    function stringToDayId(string memory dayString) external view returns (uint256);

    function getDayLevel(uint256 dayId) external view returns (uint256);

    function mint(uint256 _timestamp, IDaysWTFAuctionHouse.MintType _type) external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setFoundersDAO(address foundersDAO) external;

    function getDescriptor() external view returns (IDaysWTFDescriptor);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(IDaysWTFDescriptor _descriptor) external;

    function lockDescriptor() external;

    function getDayName(uint256 dayId) external view returns (string memory);

    function getDayUrl(uint256 dayId) external view returns (string memory);

    function getDayHash(uint256 dayId) external view returns (string memory);

    function getDaySeed(uint256 dayId) external view returns (uint256);

    function getDayData(uint256 dayId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256
        );

    function changeDayName(uint256 dayId, string memory newName) external;

    function changeDayUrl(uint256 dayId, string memory newUrl) external;

    function changeDayHash(uint256 dayId, string memory newHash) external;

    function exists(uint256 tokenId) external view returns (bool);
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