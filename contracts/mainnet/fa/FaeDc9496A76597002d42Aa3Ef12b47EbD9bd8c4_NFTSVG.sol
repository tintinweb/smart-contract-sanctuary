// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library NFTSVG {
    using Strings for uint256;

    string constant ETH_COLOR_A = "#FFFFFF";
    string constant WBTC_COLOR_A = "#E2753B";
    string constant LINK_COLOR_A = "#376AFF";
    string constant DAI_COLOR_A = "#D1A663";
    string constant UNKNOWN_COLOR_A = "#52FFB2";

    string constant ETH_COLOR_B = "#FFFFFF";
    string constant WBTC_COLOR_B = "#E2923B";
    string constant LINK_COLOR_B = "#438BFF";
    string constant DAI_COLOR_B = "#D8A75B";
    string constant UNKNOWN_COLOR_B = "#52B4FF";

    string constant ETH_UNDERLYING_LOGO =
        '<path d="m68.86 132.9-7.7-13.4-7.73 13.4 7.72-3.66 7.71 3.65Zm-7.7 7.17-8.66-4.11 8.65 15.12 8.66-15.12-8.66 4.11Zm0-2.09-7.06-3.34 7.05-3.34 7.06 3.34-7.06 3.34Z" fill="#BBBBBB"/>';
    string constant WBTC_UNDERLYING_LOGO =
        '<path d="M52.79 153.08a16.29 16.29 0 1 1 0-32.58 16.29 16.29 0 0 1 0 32.58Zm0-31.31a15.01 15.01 0 1 0 .02 30.02 15.01 15.01 0 0 0-.02-30.02Zm8.55 5.65a12.66 12.66 0 0 0-17.09 0l-.91-.9a13.94 13.94 0 0 1 18.9 0l-.9.9Zm.83.81.9-.9v-.01a13.94 13.94 0 0 1 0 18.9l-.9-.9a12.66 12.66 0 0 0 0-17.09Zm-18.75 17.1a12.66 12.66 0 0 1 0-17.08l-.9-.9a13.94 13.94 0 0 0 0 18.9l.9-.92Zm.82.83a12.67 12.67 0 0 0 17.1 0l.9.9a13.94 13.94 0 0 1-18.9 0l.9-.9Zm14.2-12.35c-.18-1.87-1.8-2.5-3.83-2.69v-2.57h-1.57v2.52h-1.26v-2.52h-1.56v2.59h-3.2v1.68s1.17-.02 1.15 0c.43-.04.83.26.9.7v7.08c-.02.15-.09.29-.2.39a.55.55 0 0 1-.4.13c.02.02-1.15 0-1.15 0l-.3 1.88h3.17v2.63h1.57v-2.59h1.26v2.58h1.58v-2.6c2.66-.16 4.51-.81 4.74-3.3.2-2-.75-2.9-2.26-3.26.92-.45 1.49-1.29 1.36-2.66Zm-2.2 5.6c0 1.8-2.83 1.75-4.12 1.73h-.3v-3.47h.39c1.32-.04 4.02-.1 4.02 1.74Zm-4.16-3.32c1.08.02 3.42.06 3.42-1.58 0-1.67-2.26-1.61-3.37-1.58h-.32v3.16h.27Z" fill="#E2923B"/>';
    string constant LINK_UNDERLYING_LOGO =
        '<path d="m62.4 122 2.7-1.6L68 122l7.5 4.4 2.8 1.6v15l-2.8 1.6L68 149l-2.8 1.6-2.8-1.6-7.6-4.4-2.7-1.6v-15l2.7-1.6 7.6-4.4Zm-4.8 9.1v8.8l7.5 4.3 7.6-4.3V131l-7.6-4.3-7.5 4.3Z" fill="#3159CC"/>';
    string constant UNKNOWN_UNDERLYING_LOGO =
        '<path d="M46.8 119.5a16.3 16.3 0 1 1 0 32.6 16.3 16.3 0 0 1 0-32.6Zm0 20.6c-.5 0-.9.2-1.2.5a1.5 1.5 0 0 0 0 2.2 1.8 1.8 0 0 0 1.2.5c.4 0 .8-.2 1.1-.5.3-.3.5-.7.5-1.1 0-.4-.2-.8-.5-1.1-.3-.3-.7-.5-1.1-.5Zm.2-11.8c-.6 0-1.2 0-1.8.3-.5.2-1 .4-1.4.8-.4.3-.8.8-1 1.3a5 5 0 0 0-.5 1.5v.2l2.4.3.2-.8a2 2 0 0 1 2-1.4c.5 0 1 .2 1.4.6.3.3.5.8.5 1.3 0 .4-.1.8-.3 1l-.5.7-.2.1-1 1-.6.6a3.2 3.2 0 0 0-.6 1.4v1.7H48v-1.3l.2-.6.4-.5.7-.6a16.5 16.5 0 0 0 1.5-1.6l.4-1 .2-1a4 4 0 0 0-.4-1.8c-.2-.4-.5-.9-1-1.2l-1.3-.8-1.7-.2Z" fill="#383838"/>';

    string constant DAI_BASE_LOGO =
        '<path d="M254 135.7a16.3 16.3 0 1 0-32.6 0 16.3 16.3 0 0 0 32.6 0Zm-24 9V139l-.2-.1h-2.2c-.1 0-.2 0-.2-.2v-2h2.4l.2-.1v-2H227.6c-.1 0-.2 0-.2-.2v-1.8c0-.1 0-.2.2-.2h2.2c.1 0 .2 0 .2-.2V127c0-.2 0-.2.2-.2h7.6l1.6.1a10 10 0 0 1 5 2.6l1.1 1.4.8 1.5c0 .2.2.2.3.2h1.8c.3 0 .3 0 .3.3v1.6c0 .2 0 .2-.3.2H247l-.1.2v1.9c0 .1 0 .2.2.2h1.6v1.8c0 .2 0 .3-.2.3h-2l-.3.1a8.1 8.1 0 0 1-3.2 4l-.2.2-1 .5a11 11 0 0 1-4.8 1h-7Zm14-12.2v-.1a4 4 0 0 0-.4-.7l-.7-1-.5-.4a7.3 7.3 0 0 0-4.8-1.7h-5.4c-.2 0-.2 0-.2.2v3.6c0 .1 0 .2.2.2H244Zm-5.7 4.4h6.2c.1 0 .2 0 .2-.2v-2h-12.5l-.2.1v2h6.3Zm5.2 2h.5v.3a6.6 6.6 0 0 1-2.8 2.8 7.7 7.7 0 0 1-3 .8l-.8.1h-5.2c-.2 0-.2 0-.2-.2v-3.5c0-.2 0-.2.2-.2h11.3Z" fill="#E3A94D"/>';
    string constant UNKNOWN_BASE_LOGO =
        '<path d="M253.79 119.5a16.29 16.29 0 1 1 0 32.58 16.29 16.29 0 0 1 0-32.58Zm-.02 20.63c-.45 0-.84.16-1.16.48a1.52 1.52 0 0 0 .01 2.23 1.78 1.78 0 0 0 1.15.45c.45 0 .84-.16 1.16-.47.32-.31.48-.7.48-1.13 0-.44-.16-.8-.5-1.1-.32-.3-.7-.46-1.14-.46Zm.22-11.84c-.62 0-1.21.1-1.76.28a4.2 4.2 0 0 0-2.49 2.11 5 5 0 0 0-.48 1.47l-.04.28 2.52.22c.01-.27.07-.53.16-.8a2.02 2.02 0 0 1 1.93-1.33c.62 0 1.09.19 1.43.55.33.36.5.8.5 1.34 0 .4-.1.76-.28 1.04-.14.22-.3.42-.48.6l-.19.18-.92.88c-.26.25-.47.48-.64.7a3.18 3.18 0 0 0-.64 1.41c-.03.2-.06.41-.07.65v1.01h2.42v-.53c0-.3.02-.55.06-.76.04-.2.11-.4.21-.57.1-.18.24-.36.41-.53.18-.18.4-.39.67-.62.31-.27.6-.53.85-.79.25-.25.47-.51.65-.79.17-.27.31-.57.4-.9.1-.32.15-.7.15-1.14 0-.65-.12-1.21-.35-1.7-.23-.5-.55-.91-.95-1.25-.4-.33-.87-.58-1.4-.75a5.4 5.4 0 0 0-1.66-.26Z" fill="#383838"/>';

    string constant DAI_BASE_LOGO_SMALL =
        '<path d="M125 260a7 7 0 1 0-14 0 7 7 0 0 0 14 0Zm-10.3 3.9v-2.4l-.1-.1h-1v-.9h1v-.9h-1v-.9h1v-2.5H118.8a4.3 4.3 0 0 1 2.2 1l.5.7.3.6.1.1h.9V259.5h-.7v1h.7v.8h-.9l-.1.2a3.5 3.5 0 0 1-1.4 1.7h-.1l-.4.3a4.7 4.7 0 0 1-2.1.4h-3Zm6-5.3c0-.1 0-.2-.2-.3 0-.2-.2-.3-.3-.4l-.2-.2a3.1 3.1 0 0 0-2-.8h-2.4V258.6h5.1Zm-2.4 1.9h2.7v-.9h-5.4v.9h2.7Zm2.2.9h.2c-.3.6-.7 1-1.2 1.3l-.4.2-1 .2h-2.5V261.3h4.9Z" fill="#646464"/>';
    string constant UNKNOWN_BASE_LOGO_SMALL =
        '<path d="M118 253a7 7 0 1 1 0 14 7 7 0 0 1 0-14Zm0 8.87c-.2 0-.37.06-.5.2a.65.65 0 0 0 0 .96.76.76 0 0 0 .5.2c.18 0 .35-.07.49-.21.14-.13.2-.3.2-.48a.62.62 0 0 0-.2-.48.7.7 0 0 0-.5-.2Zm.09-5.1c-.27 0-.52.05-.76.13a1.8 1.8 0 0 0-1.07.9c-.1.2-.17.4-.2.64l-.02.12 1.08.1c0-.12.03-.24.07-.35a.87.87 0 0 1 .83-.57c.26 0 .47.07.61.23s.22.35.22.58c0 .17-.04.32-.12.45l-.2.25-.09.08-.4.38c-.1.1-.2.2-.27.3a1.37 1.37 0 0 0-.28.6l-.03.28V261.33h1.04v-.23c0-.13.01-.24.03-.32a.8.8 0 0 1 .1-.25c.03-.08.1-.15.17-.23a7.09 7.09 0 0 0 .65-.6l.28-.34c.07-.12.13-.25.17-.39.04-.14.06-.3.06-.5 0-.27-.05-.51-.15-.72-.1-.22-.23-.4-.4-.54a1.8 1.8 0 0 0-.6-.32 2.32 2.32 0 0 0-.72-.11Z" fill="#646464"/>';

    struct CreateSVGParams {
        string baseSymbol;
        string underlyingSymbol;
        bool isCall;
        bool isLong;
        string maturityString;
        string strikePriceString;
    }

    function buildSVG(CreateSVGParams memory _params)
        public
        pure
        returns (string memory)
    {
        string memory tokens = buildTokens(
            _params.baseSymbol,
            _params.underlyingSymbol
        );
        string memory svgText = buildText(
            _params.baseSymbol,
            _params.underlyingSymbol,
            _params.strikePriceString,
            _params.maturityString
        );
        string memory svgDefs = buildDefs(
            _params.underlyingSymbol,
            _params.baseSymbol,
            _params.isLong
        );
        string memory shortLongTag = buildShortLongTag(_params.isLong);

        return
            string(
                abi.encodePacked(
                    '<svg width="300" height="378" viewBox="0 0 300 378" fill="none" xmlns="http://www.w3.org/2000/svg">',
                    svgDefs,
                    '<g transform="translate(.5 .5)" fill="none" fill-rule="evenodd">',
                    tokens,
                    _params.isCall ? buildCallRectangle() : buildPutRectangle(),
                    shortLongTag,
                    svgText,
                    "</g>",
                    "</svg>"
                )
            );
    }

    function buildTokens(
        string memory baseSymbol,
        string memory underlyingSymbol
    ) internal pure returns (string memory) {
        string memory baseLogoSmall = getBaseLogoSmall(baseSymbol);
        string memory baseLogo = getBaseLogo(baseSymbol);
        string memory underlyingLogo = getUnderlyingLogo(underlyingSymbol);

        return
            string(
                abi.encodePacked(
                    '<path d="M103 0a25 25 0 0 1 17.7 7.3l24 24.1c8.1 8 19 12.6 30.5 12.6h95.2A30 30 0 0 1 300 69.4V348a30 30 0 0 1-30 30H30a30 30 0 0 1-30-30V30A30 30 0 0 1 30 0h73Z" fill="#000" fill-rule="nonzero"/>',
                    '<path d="M19.9 150 1.1 163H16l16.8-13h.5l-16.7 13h14.9l14.7-13h.5l-14.6 13H47l12.6-13h.5l-12.5 13h14.9L73 150h.5l-10.4 13H78l8.4-13h.5l-8.3 13h14.9l6.3-13h.5l-6.2 13H109l4.2-13h.5l-4.1 13h14.9l2.1-13h.5l-2 13H140v-13h.5v13h15l-2-13h.4l2.2 13H171l-4.2-13h.5l4.3 13h14.9l-6.3-13h.5l6.4 13H202l-8.4-13h.5l8.5 13h14.9L207 150h.5l10.5 13h15l-12.6-13h.5l12.6 13h15l-14.7-13h.5l14.7 13h15l-16.8-13h.5l16.8 13h15l-18.9-13h.5l19 13h14.8L274 150h.5l21 13h4.5v.3h-4l4 2.4v.3l-4.5-2.8h-15l14 9.7h5.5v.3h-5l5 3.4v.4l-5.6-3.8h-16.5l12.5 9.6h9.6v.3h-9.2l9.2 7v.7l-9.9-7.7h-18l10.9 9.6h17v.4h-16.6l11.3 9.9h-.9l-11.2-10H263l9.7 10h-.9l-9.6-10h-19.6l8 10h-.8l-8-10h-19.6l6.5 10h-.9l-6.4-10h-19.6l4.9 10h-.9l-4.8-10h-19.6l3.3 10h-.9l-3.2-10H161l1.7 10h-.9l-1.5-10h-19.6v10h-.9v-10h-19.5l-1.6 10h-.9l1.7-10H99.9l-3.2 10h-.9l3.3-10H79.5l-4.8 10h-.9l5-10H59l-6.4 10h-.9l6.5-10H38.7l-8 10h-.9l8.1-10H18.3l-9.6 10h-.8l9.7-10H0v-.3h17.9l9.4-9.6H9.2L0 191.3v-.7l8.5-7.5H0v-.3h8.9l10.9-9.6H3.3L0 175.7v-.5l2.6-2H0v-.3h3l12.6-9.7H.6l-.6.5v-.8h.5L19.4 150h.5Zm138.8 33.1h-18v9.6h19.5l-1.5-9.6Zm-18.8 0h-18l-1.6 9.6H140v-9.6Zm-93.9 0H28l-9.3 9.6h19.5l7.8-9.6Zm18.8 0h-18l-7.8 9.6h19.5l6.3-9.6Zm18.8 0h-18l-6.3 9.6H79l4.7-9.6Zm18.8 0H84.3l-4.6 9.6h19.5l3.2-9.6Zm18.7 0h-18l-3.1 9.6h19.5l1.6-9.6Zm56.3 0h-18l1.6 9.6h19.5l-3-9.6Zm18.8 0h-18l3.1 9.6H201l-4.7-9.6Zm18.8 0h-18l4.7 9.6h19.5l-6.2-9.6Zm18.8 0h-18l6.2 9.6h19.5l-7.7-9.6Zm18.7 0h-18l7.8 9.6H262l-9.4-9.6Zm18.8 0h-18l9.3 9.6h19.6l-10.9-9.6Zm6-10h-16.6l11 9.7h18l-12.5-9.6Zm-17.2 0h-16.5l9.3 9.7h18l-10.8-9.6Zm-17.2 0h-16.5l7.8 9.7h18l-9.3-9.6Zm-17.2 0h-16.5l6.3 9.7h18l-7.8-9.6Zm-17.1 0H192l4.7 9.7h18l-6.2-9.6Zm-17.2 0H175l3.2 9.7h18l-4.7-9.6Zm-17.1 0h-16.5l1.5 9.7h18l-3-9.6Zm-17.2 0h-16.5v9.7h18l-1.5-9.6Zm-17.2 0h-16.5l-1.5 9.7h18v-9.6Zm-17.1 0h-16.5l-3.1 9.7h18l1.6-9.6Zm-17.2 0H89.1l-4.6 9.7h18l3.1-9.6Zm-17.2 0H72l-6.2 9.7h18l4.7-9.6Zm-17.1 0H54.8l-7.8 9.7h18l6.3-9.6Zm-17.2 0H37.6l-9.3 9.7h18l7.8-9.6Zm-17.1 0H20.5l-11 9.7h18l9.5-9.6Zm243-9.8h-15l12.5 9.6h16.4l-14-9.7Zm-15.6 0h-15l11 9.6h16.4l-12.4-9.7Zm-15.6 0h-15l9.4 9.6h16.5l-10.9-9.7Zm-15.5 0h-15l7.8 9.6h16.5l-9.3-9.7Zm-15.6 0h-15l6.3 9.6h16.5l-7.8-9.7Zm-15.5 0h-15l4.7 9.6h16.5l-6.2-9.7Zm-15.6 0h-15l3.2 9.6h16.5l-4.7-9.7Zm-15.5 0h-15l1.6 9.6h16.5l-3.1-9.7Zm-15.6 0h-15v9.6H157l-1.5-9.7Zm-15.5 0h-15l-1.5 9.6h16.4v-9.7Zm-15.6 0h-15l-3 9.6h16.4l1.6-9.7Zm-15.5 0h-15l-4.6 9.6h16.4l3.2-9.7Zm-15.6 0h-15l-6.1 9.6h16.4l4.7-9.7Zm-15.5 0h-15l-7.8 9.6h16.5l6.3-9.7Zm-15.6 0h-15l-9.3 9.6h16.5l7.8-9.7Zm-15.5 0h-15l-10.9 9.6h16.5l9.4-9.7Zm-15.6 0h-15l-12.4 9.6h16.5l10.9-9.7ZM287.9 150l12.1 6.7v.4l-12.6-7.1h.5ZM6.5 150 0 154v-.3l6-3.7h.5Z" fill="url(#a)" opacity=".3"/>',
                    '<rect stroke="#2C2C2C" fill="#000" fill-rule="nonzero" x="18" y="208.5" width="264" height="99" rx="14"/>',
                    baseLogoSmall,
                    baseLogo,
                    '<path d="M53.1 26.6c2.5 0 4.4 1.9 4.4 4.7 0 3-2 4.8-4.4 4.8a3.6 3.6 0 0 1-2.8-1.3h-.1v4.5h-1.9V26.8h1.9v1.1a3.8 3.8 0 0 1 3-1.3Zm16.4 0c2.6 0 4.7 2 4.7 4.7v.7h-7.5c.3 1.5 1.4 2.4 2.8 2.4 1 0 1.6-.3 2-.6l.6-.7h2a4.9 4.9 0 0 1-4.6 3c-2.6 0-4.7-2-4.7-4.8 0-2.6 2-4.7 4.7-4.7Zm29.6 0c1 0 1.7.3 2.2.7l.7.6h.1v-1.1h1.9v9.1h-1.9v-1.2l-.8.7c-.5.4-1.2.7-2.2.7-2.4 0-4.3-1.9-4.3-4.8 0-2.8 2-4.7 4.3-4.7Zm-34.7 0v1.9h-1.1c-1.5 0-2.5 1-2.5 2.5v5h-2v-9.2h2V28l.6-.7c.4-.4 1-.7 2-.7h1Zm22 0c2 0 3.4 1.3 3.4 3.8V36h-1.9v-5.4c0-1.5-.7-2.2-2-2.2-1.2 0-2.3 1-2.3 2.6v5h-1.9v-5.4c0-1.5-.7-2.2-2-2.2-1.2 0-2.3 1-2.3 2.6v5h-1.9v-9.1h1.9V28l.7-.7c.4-.4 1-.7 2-.7 1.3 0 2 .4 2.4.8l.7.9.7-.9c.5-.4 1.3-.8 2.5-.8Zm7.1.2v9.1h-1.9v-9.1h1.9Zm-40.7 1.5c-1.5 0-2.6 1-2.6 3s1 3.1 2.6 3.1 2.7-1 2.7-3-1-3.1-2.7-3.1Zm46.7 0c-1.6 0-2.7 1-2.7 3s1 3.1 2.7 3.1c1.5 0 2.6-1 2.6-3s-1-3.1-2.6-3.1Zm-30 0c-1.3 0-2.4.8-2.7 2.1h5.4c-.2-1-1-2.1-2.7-2.1Zm23-5.1c.7 0 1.2.5 1.2 1.1 0 .6-.5 1.1-1.1 1.1-.7 0-1.2-.5-1.2-1.1 0-.6.5-1.1 1.2-1.1Z" fill="#FFF"/>',
                    '<path d="M29.6 26.7h7.8c.5 0 .7.5.5.9l-3.7 5c-.3.5 0 1 .4 1H38c.2 0 .3-.1.4-.3l3.7-5v-.7l-3.2-4.4a.5.5 0 0 0-.5-.2h-9.5c-.2 0-.4 0-.5.2l-3.2 4.4v.7l8 11c.2.3.7.3.9 0l1.6-2.3c.2-.1.2-.4 0-.6l-6.4-8.8c-.3-.4 0-.9.4-.9Z" fill="#5294FF"/>',
                    underlyingLogo,
                    '<path stroke="#4D4343" d="m154 148.5 6.5-26"/>',
                    '<path d="M139.5 36c8 8 19.7 14.6 31 14.6h95.6c14.5 0 26.3 7.6 28.4 21.3v271.7c0 16-12.9 28.9-28.7 28.9H34.2c-15.8 0-28.7-13-28.7-28.9V33.4A28 28 0 0 1 34.2 5.5h67c6.3 0 12.4 3.5 16.9 8l21.4 22.6Z" stroke="#FFF" opacity=".1"/>',
                    '<path d="M289.26 66.05c-57.44 0-104 46.56-104 104s46.56 104 104 104c3.63 0 7.2-.18 10.74-.55V66.6c-3.53-.36-7.11-.55-10.74-.55Z" fill="url(#b)" opacity=".31" />',
                    '<path d="M10.7 66A104 104 0 1 1 0 273.6V66.6c3.5-.4 7.1-.5 10.7-.5Z" fill="url(#c)" opacity=".3"/>'
                )
            );
    }

    function buildText(
        string memory baseSymbol,
        string memory underlyingSymbol,
        string memory strikePriceString,
        string memory maturityString
    ) internal pure returns (string memory) {
        bytes memory bufferA = abi.encodePacked(
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="gray">',
            '<tspan x="32.1" y="237">Type</tspan>',
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="gray">',
            '<tspan x="32.1" y="263">Strike price</tspan>',
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="gray">',
            '<tspan x="32.1" y="289">Maturity</tspan>',
            "</text>",
            '<text font-family="DMSans-Bold, DM Sans" font-size="24" font-weight="bold" fill="#FFF">',
            '<tspan style="direction:rtl" x="143" y="144">',
            underlyingSymbol,
            "</tspan>",
            "</text>"
        );

        bytes memory bufferB = abi.encodePacked(
            '<text font-family="DMSans-Bold, DM Sans" font-size="24" font-weight="bold" fill="#FFF">',
            '<tspan x="173.1" y="144">',
            baseSymbol,
            "</tspan>",
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#FFF">',
            '<tspan style="direction:rtl" x="265" y="263">',
            strikePriceString,
            "</tspan>",
            "</text>",
            '<text font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#FFF">',
            '<tspan style="direction:rtl" x="265" y="289">',
            maturityString,
            "</tspan>",
            "</text>"
        );

        return string(abi.encodePacked(bufferA, bufferB));
    }

    function buildDefs(
        string memory underlyingSymbol,
        string memory baseSymbol,
        bool isLong
    ) internal pure returns (string memory) {
        string memory baseGradient = buildBaseGradient(baseSymbol);
        string memory underlyingGradient = buildUnderlyingGradient(
            underlyingSymbol
        );
        string memory shortDefs = isLong ? "" : buildShortDefs();
        bytes memory whiteGradient = abi.encodePacked(
            '<linearGradient x1="50%" y1="0%" x2="50%" y2="90%" id="a">',
            '<stop stop-color="#FFF" stop-opacity="0" offset="0%"/>',
            '<stop stop-color="#FFF" offset="80%"/>',
            '<stop stop-color="#FFF" stop-opacity="0" offset="100%"/>',
            "</linearGradient>"
        );

        return
            string(
                abi.encodePacked(
                    "<defs>",
                    '<style type="text/css">@import url(https://fonts.googleapis.com/css?family=DM+Sans);',
                    "</style>",
                    whiteGradient,
                    underlyingGradient,
                    baseGradient,
                    shortDefs,
                    "</defs>"
                )
            );
    }

    function buildUnderlyingGradient(string memory underlyingSymbol)
        internal
        pure
        returns (string memory)
    {
        (
            string memory underlyingColorA,
            string memory underlyingColorB
        ) = getTokenColors(underlyingSymbol);

        return
            string(
                abi.encodePacked(
                    '<radialGradient cx="8%" cy="50%" fx="8%" fy="50%" r="90.6%" gradientTransform="matrix(0 .55164 -1 0 .6 .5)" id="c">',
                    '<stop stop-color="',
                    underlyingColorA,
                    '" offset="0%"/>',
                    '<stop stop-color="',
                    underlyingColorB,
                    '" stop-opacity="0" offset="100%"/>',
                    "</radialGradient>"
                )
            );
    }

    function buildBaseGradient(string memory baseSymbol)
        internal
        pure
        returns (string memory)
    {
        (string memory baseColorA, string memory baseColorB) = getTokenColors(
            baseSymbol
        );

        return
            string(
                abi.encodePacked(
                    '<radialGradient cx="100%" cy="50%" fx="100%" fy="50%" r="90.64%" gradientTransform="matrix(0 .55164 -1 0 1.5 -.05)" id="b">',
                    '<stop stop-color="',
                    baseColorA,
                    '" offset="0%"/>',
                    '<stop stop-color="',
                    baseColorB,
                    '" stop-opacity="0" offset="99.67%"/>',
                    "</radialGradient>"
                )
            );
    }

    function buildShortDefs() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<linearGradient x1="62.1%" y1="20.8%" x2="-29.2%" y2="25.7%" id="d">',
                    '<stop stop-color="#3E1808" offset="3%" />',
                    '<stop stop-color="#300427" offset="100%" />',
                    "</linearGradient>"
                )
            );
    }

    function buildCallRectangle() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect stroke="#2CE49A" fill="#051A12" fill-rule="nonzero" x="18" y="319.5" width="264" height="39" rx="14"/>',
                    '<path d="m111.6 332.2 5.2 5a.7.7 0 0 1 0 1.2l-.5.4c-.2.2-.3.2-.6.2-.2 0-.4 0-.5-.2l-3-3v9.4c0 .5-.4.8-.8.8h-.7c-.5 0-.8-.3-.8-.8v-9.4l-3 3c-.2.2-.4.2-.6.2-.3 0-.5 0-.6-.2l-.5-.4a.7.7 0 0 1 0-1.1l5.2-5 .6-.3c.2 0 .4 0 .6.2Z" fill="#2CE49A" fill-rule="nonzero"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#2CE49A">',
                    '<tspan x="121" y="344">Call Option</tspan>',
                    "</text>"
                )
            );
    }

    function buildPutRectangle() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect stroke="#EB4A97" fill="#2D0719" fill-rule="nonzero" x="18" y="319.5" width="264" height="39" rx="14"/>',
                    '<path d="m111.6 345.8 5.2-5a.7.7 0 0 0 0-1.2l-.5-.4a.8.8 0 0 0-.6-.2c-.2 0-.4 0-.5.2l-3 3v-9.4c0-.5-.4-.8-.8-.8h-.7c-.5 0-.8.3-.8.8v9.4l-3-3a.8.8 0 0 0-1.1 0l-.6.4a.7.7 0 0 0 0 1.1l5.2 5 .6.3c.2 0 .4 0 .6-.2Z" fill="#EB4A97"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#EB4A97">',
                    '<tspan x="122.7" y="344">Put Option</tspan>',
                    "</text>"
                )
            );
    }

    function buildShortLongTag(bool _isLong)
        internal
        pure
        returns (string memory)
    {
        return _isLong ? buildLongTag() : buildShortTag();
    }

    function buildLongTag() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect fill="#0C1E3C" fill-rule="nonzero" x="208" y="222" width="57" height="23" rx="6"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#5294FF">',
                    '<tspan x="221.1" y="238.5">Long</tspan>',
                    "</text>"
                )
            );
    }

    function buildShortTag() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect fill="url(#d)" fill-rule="nonzero" x="208" y="222" width="57" height="23" rx="6"/>',
                    '<text fill-rule="nonzero" font-family="DMSans-Medium, DM Sans" font-size="14" font-weight="400" fill="#ED6F64">',
                    '<tspan x="219.1" y="238.5">Short</tspan>',
                    "</text>"
                )
            );
    }

    function getUnderlyingLogo(string memory tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (
            hash == keccak256(abi.encodePacked("ETH")) ||
            hash == keccak256(abi.encodePacked("WETH"))
        ) {
            return ETH_UNDERLYING_LOGO;
        } else if (hash == keccak256(abi.encodePacked("LINK"))) {
            return LINK_UNDERLYING_LOGO;
        } else if (hash == keccak256(abi.encodePacked("WBTC"))) {
            return WBTC_UNDERLYING_LOGO;
        } else {
            return UNKNOWN_UNDERLYING_LOGO;
        }
    }

    function getBaseLogo(string memory tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (hash == keccak256(abi.encodePacked("DAI"))) {
            return DAI_BASE_LOGO;
        } else {
            return UNKNOWN_BASE_LOGO;
        }
    }

    function getBaseLogoSmall(string memory tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (hash == keccak256(abi.encodePacked("DAI"))) {
            return DAI_BASE_LOGO_SMALL;
        } else {
            return UNKNOWN_BASE_LOGO_SMALL;
        }
    }

    function getTokenColors(string memory tokenSymbol)
        internal
        pure
        returns (string memory, string memory)
    {
        bytes32 hash = keccak256(abi.encodePacked(tokenSymbol));

        if (
            hash == keccak256(abi.encodePacked("ETH")) ||
            hash == keccak256(abi.encodePacked("WETH"))
        ) {
            return (ETH_COLOR_A, ETH_COLOR_B);
        } else if (hash == keccak256(abi.encodePacked("LINK"))) {
            return (LINK_COLOR_A, LINK_COLOR_B);
        } else if (hash == keccak256(abi.encodePacked("WBTC"))) {
            return (WBTC_COLOR_A, WBTC_COLOR_B);
        } else if (hash == keccak256(abi.encodePacked("DAI"))) {
            return (DAI_COLOR_A, DAI_COLOR_B);
        } else {
            return (UNKNOWN_COLOR_A, UNKNOWN_COLOR_B);
        }
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