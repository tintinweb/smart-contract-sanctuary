// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library BubbleMaker {
    function getRandomHSL(uint256 uniqueRand)
        internal
        pure 
        returns (string memory)
    {
        uint256 random_1 = (uniqueRand / 10);
        uint256 random_2 = (uniqueRand / 15);
        uint256 random_3 = (uniqueRand / 20);
        return
            string(
                abi.encodePacked(
                    "hsl(",
                    toString(random(0, 360, random_1)),
                    ", ",
                    toString(random(50, 100, random_2)),
                    "%, ",
                    toString(random(50, 100, random_3)),
                    "%)"
                )
            );
    }

    function getTraits(
        string memory name,
        uint256 poured,
        uint256 fizz
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"name": "',
                    name,
                    '",',
                    '"description": "poppin",',
                    '"attributes":[',
                    traits(poured, fizz),
                    '], '
                )
            );
    }

    function traits(uint256 poured, uint256 fizz)
        internal
        view
        returns (string memory)
    {
        uint256 max = 25;
        uint256 ratio = (fizz * 100) / max;
        return
            string(
                abi.encodePacked(
                    "{",
                    '"display_type": "date",',
                    '"trait_type": "Poured on",',
                    '"value": "',
                    toString(poured),
                    '"',
                    "},",
                    "{",
                    '"display_type": "number",',
                    '"trait_type": "Days held",',
                    '"value": "',
                    toString(timeheld(poured)),
                    '"',
                    "},",
                    "{",
                    '"display_type": "boost_percentage",',
                    '"trait_type": "Fizz",',
                    '"value": "',
                    toString(ratio),
                    '"',
                    "}"
                )
            );
    }

    // RANDOM STUFF
    function random(
        uint256 min,
        uint256 max,
        uint256 seed
    ) public pure returns (uint256) {
        return min + (seed % (max - min + 1));
    }

    function shakeItUpThatllDO(uint256 tokenId) public view returns (uint256) {
        uint256 jeneral = gremblosCoolRandomFunctionThatIsBerryCoolAndGood(
            tokenId
        );
        return random(0, 25, jeneral);
    }

    function gremblosCoolRandomFunctionThatIsBerryCoolAndGood(uint256 tokenID)
        public
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, tokenID)
                )
            );
    }

    function biggerAndBetterThanGemblosBYAPPSUS(uint256 tokenId)
        public
        view
        returns (uint256[2] memory magicArray)
    {
        uint256 jeneral = gremblosCoolRandomFunctionThatIsBerryCoolAndGood(
            tokenId
        );
        uint256 fizz = random(0, 25, jeneral);
        return [jeneral, fizz];
    }

    function timeheld(uint256 date) internal view returns (uint256) {
        return (block.timestamp - date) / 86_4000;
    }

    function getFillHeight(uint256 poured)
        internal
        view
        returns (string memory)
    {
        uint256 holdtime = (block.timestamp - poured) / 86_4000;

        if (holdtime < 10) return "400";
        if (holdtime > 250) return "100";
        return toString(400 - holdtime);
    }

    function getBg(uint256 randSeed) internal pure returns (string memory) {
        uint256 uniqueNum = randSeed / 5;

        return
            string(
                abi.encodePacked(
                    '<rect x="0" y="0" width="600px" height="600px" fill="',
                    getRandomHSL(uniqueNum),
                    '" />'
                )
            );
    }

    function getGradient(uint256 randSeed)
        internal
        pure 
        returns (string memory)
    {
        uint256 random_1 = randSeed / 35;
        uint256 random_2 = randSeed / 45;
        uint256 random_3 = randSeed / 55;

        return
            string(
                abi.encodePacked(
                    '<linearGradient id="grad1" x1="0%" y1="0%" x2="0%" y2="100%">',
                    '<stop offset="0%" stop-color="',
                    getRandomHSL(random_1),
                    '" />',
                    '<stop offset="50%" stop-color="',
                    getRandomHSL(random_2),
                    '" />',
                    '<stop offset="100%" stop-color="',
                    getRandomHSL(random_3),
                    '" />',
                    "</linearGradient>"
                )
            );
    }

    function getClipPath(uint256 poured) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<clipPath id="liquid-top">',
                    '<use xlink:href="#waves" transform="translate(0,',
                    getFillHeight(poured),
                    ')"/>',
                    "</clipPath>"
                )
            );
    }

    function getTransform(uint256 poured)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(0,',
                    getFillHeight(poured),
                    ')">'
                )
            );
    }

    /**
     * @dev generate waves
     * NOTE: kinda broken random no allowing for new colors
     **/
    function getWaves(uint256 randSeed, uint256 poured)
        internal
        view
        returns (string memory)
    {
        uint256 randomNum = randSeed / 10;
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(0,',
                    getFillHeight(poured),
                    ')">',
                    '<g transform="translate(0,-20)">',
                    '<path id="waves" fill="',
                    getRandomHSL(randomNum),
                    '" d="M0 67C 273,183 822,-40 1920.00,106 V 600 H 0 V 67Z">',
                    '<animate repeatCount="indefinite" fill="',
                    getRandomHSL(randomNum),
                    '" attributeName="d" dur="10s" values=" M0 77 C 473,283 822,-40 1920,116 V 600 H 0 V 67 Z; M0 77 C 473,-40 1222,283 1920,136 V 600 H 0 V 67 Z; M0 77 C 973,260 1722,-53 1920,120 V 600 H 0 V 67 Z; M0 77 C 473,283 822,-40 1920,116 V 600 H 0 V 67 Z " >',
                    "</animate>",
                    "</path>",
                    "</g>",
                    '<use xlink:href="#waves" />',
                    "</g>"
                )
            );
    }

    function getScale(uint256 randSeed) internal pure returns (string memory) {
        uint256 randonNum_1 = randSeed / 30;
        uint256 randonNum_2 = randSeed / 35;
        return
            string(
                abi.encodePacked(
                    toString(random(1, 5, randonNum_1)),
                    ".",
                    toString(random(0, 99999999, randonNum_2))
                )
            );
    }

    function getDuration(uint256 randSeed)
        internal
        pure
        returns (string memory)
    {
        uint256 randonNum_1 = randSeed / 30;
        uint256 randonNum_2 = randSeed / 35;
        return
            string(
                abi.encodePacked(
                    toString(random(1, 5, randonNum_1) + 1),
                    ".",
                    toString(random(0, 99999999, randonNum_2))
                )
            );
    }

    function getStartTime(uint256 randSeed)
        internal
        pure
        returns (string memory)
    {
        uint256 randomNum_1 = randSeed / 20;
        uint256 randomNum_2 = randSeed / 25;
        return
            string(
                abi.encodePacked(
                    toString(random(0, 2, randomNum_1)),
                    ".",
                    toString(random(0, 99999999, randomNum_2))
                )
            );
    }

    function getPathFromList(uint256 randSeed)
        internal
        pure
        returns (string memory)
    {
        uint256 randomNum = randSeed / 15;
        string[10] memory paths = [
            "m 0 600 q 52 -162 0 -300 q -87 -143 0 -300",
            "m 0 600 q 258 -162 0 -300 q -254 -136 0 -300",
            "m 0 600 q 37 -157 0 -300 q -33 -180 0 -300",
            "m 0 600 q 190 -145 0 -300 q -101 -39 0 -300",
            "m 0 600 q 431 -148 0 -300 q -327 -200 0 -300",
            "m 0 600 q -191 -169 0 -300 q 166 -136 0 -300",
            "m 0 600 q -55 -164 0 -300 q 66 -151 0 -300",
            "m 0 600 q -276 -162 0 -300 q 302 -148 0 -300",
            "m 0 600 q -43 -174 0 -300 q 42 -180 0 -300",
            "m 0 600 q -191 -232 0 -300 q 234 -102 0 -300"
        ];
        return paths[random(0, 9, randomNum)];
    }

    /**
     * set postition of bubble
     */
    function getTransformTranslateX(uint256 randSeed)
        public
        pure
        returns (string memory)
    {
        uint256 randomNum = randSeed / 10;
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(',
                    toString(random(0, 600, randomNum)),
                    " ",
                    toString(0),
                    ')">'
                )
            );
    }

    function makeBubbles(uint256 num, uint256 seed)
        public
        view
        returns (string memory)
    {
        string memory out;

        uint256 randomNum = (gremblosCoolRandomFunctionThatIsBerryCoolAndGood(seed)) / (10 * num);

        string memory bubNum = toString(num);
        string memory scale = getScale(randomNum);
        string memory duration = getDuration(randomNum);

        out = string(
            abi.encodePacked(
                '<g transform="translate(0, 0)">',
                getTransformTranslateX(randomNum),
                '<animateMotion path="',
                getPathFromList(randomNum),
                '" start="',
                getStartTime(randomNum),
                's" dur="',
                duration,
                's" repeatCount="indefinite" />',
                '<g transform="scale(',
                scale,
                ')">',
                '<path transform="translate(2 -1)" d="m-1.85-8.8c.4 0 .7-.3.7-.7v-3c0-.4-.3-.7-.7-.7c-.4 0-.7.3-.7.7v3c0 .4.3.7.7.7zm7.2 3.7c.2 0 .35-.05.5-.2l2.6-2.6c.3-.3.3-.75 0-1c-.3-.3-.75-.3-1 0l-2.6 2.6c-.3.3-.3.75 0 1c.1.1.3.2.5.2zm-16.05-.25c.15.15.35.2.5.2c.2 0 .35-.05.5-.2c.3-.3.3-.75 0-1l-2.55-2.6c-.3-.3-.75-.3-1 0c-.3.3-.3.75 0 1l2.55 2.6zm8.3 16.4c-.4 0-.7.3-.7.7v3c0 .4.3.7.7.7s.7-.3.7-.7v-3c0-.4-.3-.7-.7-.7zm-7.7-3.45-2.6 2.6c-.3.3-.3.75 0 1c.15.15.35.2.5.2c.2 0 .35-.05.5-.2l2.6-2.6c.3-.3.3-.75 0-1c-.3-.3-.75-.3-1 0zm16.55 0c-.3-.3-.75-.3-1 0c-.3.3-.3.75 0 1l2.6 2.6c.15.15.35.2.5.2c.2 0 .35-.05.5-.2c.3-.3.3-.75 0-1l-2.6-2.6zm-18.5-6.4c0-.4-.3-.7-.7-.7h-3.3c-.4 0-.7.3-.7.7c0 .4.3.7.7.7h3.25c.4 0 .75-.3.75-.7zm23.85-.75h-3.85c-.4 0-.7.3-.7.7c0 .4.3.7.7.7h3.85c.4 0 .7-.3.7-.7c0-.35-.3-.7-.7-.7z" fill="#ffffff00">',
                '<set attributeName="fill" to="#ffffff30" begin="',
                bubNum,
                '.mouseover" />',
                '<animate attributeName="fill" values="#ffffff30;#ffffff00" dur="0.25s" fill="freeze" begin="',
                bubNum,
                '.mouseover"/>',
                '<animateTransform attributeName="transform" type="scale" from="1 1" to="2 2" begin="',
                bubNum,
                '.mouseover" dur="0.25s" fill="freeze">',
                "</animateTransform>",
                "</path>",
                '<circle id="',
                bubNum,
                '" r="10" fill="#ffffff30" stroke-width="0.25px" stroke="#ffffff66" >',
                '<set attributeName="fill" to="#ffffff00" begin="',
                bubNum,
                '.mouseover" />',
                '<set attributeName="stroke" to="#ffffff00" begin="',
                bubNum,
                '.mouseover" />',
                '<set attributeName="pointer-events" to="none" begin="',
                bubNum,
                '.mouseover" />',
                "</circle>",
                "</g>",
                "</g>",
                "</g>"
            )
        );
        return out;
    }

    function makeSVG(
        uint256 poured,
        uint256 fizz,
        uint256 seed
    ) public view returns (string memory) {
        string memory start = string(
            abi.encodePacked(
                '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 600 600" preserveAspectRatio="xMaxYMid  slice" >',
                "<defs>",
                '<path id="waves" fill="url(#grad1)" d=" M0 67 C 273,183 822,-40 1920.00,106 V 600 H 0 V 67Z" >',
                '<animate repeatCount="indefinite" fill="url(#grad1)" attributeName="d" dur="10s" values=" M0 77 C 473,283 822,-40 1920,116 V 600 H 0 V 67 Z; M0 77 C 473,-40 1222,283 1920,136 V 600 H 0 V 67 Z; M0 77 C 973,260 1722,-53 1920,120 V 600 H 0 V 67 Z; M0 77 C 473,283 822,-40 1920,116 V 600 H 0 V 67 Z " >',
                "</animate>",
                "</path>",
                "</defs>",
                getBg(seed),
                getGradient(seed),
                getClipPath(poured),
                getWaves(seed, poured),
                '<g id="bubbleGroup" clip-path="url(#liquid-top)">'
            )
        );

        uint256 bubNum = fizz;
        if (bubNum > 0) {
            for (uint256 i = 1; i < bubNum; i++) {
                start = string(abi.encodePacked(start, makeBubbles(i, seed)));
            }
        }
        return string(abi.encodePacked(start, "</g>", "</svg>"));
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
}