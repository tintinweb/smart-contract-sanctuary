// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IRandomizer {
    function getRandomNumber(uint256 upperLimit, uint256 idForUniquenessInBlock) external view returns (uint256);
}

interface IN is IERC721 {
    function getFirst(uint256 tokenId) external view returns (uint256);

    function getSecond(uint256 tokenId) external view returns (uint256);

    function getThird(uint256 tokenId) external view returns (uint256);

    function getFourth(uint256 tokenId) external view returns (uint256);

    function getFifth(uint256 tokenId) external view returns (uint256);

    function getSixth(uint256 tokenId) external view returns (uint256);

    function getSeventh(uint256 tokenId) external view returns (uint256);

    function getEight(uint256 tokenId) external view returns (uint256);
}

interface IPunk {
    function balanceOf(address wallet) external view returns (uint256);
}

/*
    https://twitter.com/_n_collective

    Numbers are the basis of the entire universe, the base layer of perceived reality. The rest is but a mere expression of those.
    Numbers are all around us, have always been, will always be.

    And God said, let there be Code; and there was Code. You may argue that I’m on mushrooms now but if our base reality itself is
    an expression of an underlying algorithm, wouldn't the n be just another loop of algorithmic reality creation; layer on top of layer, infinite, inception?
    And so, as the Big Bang is a symbolic manifestation of the creation of our reality, the @the_n_project_ is just another
     Big Bang of an alternate reality — the metaverse.

    Pythagorean Masks are the first of the creations of the @_n_Collective.
    The Collective settled on Masks as a design choice in order to amplify the idea that the individual who wears them shall hide
    his identity for that the Collective can shine. The Collective are the Mask holders, the Mask wearers;
    it represents your belonging to a community, the Collective, with the potential to shape reality in unprecedented ways.

    He who wears the Pythagorean Mask oaths to the Collective honest loyalty, for what is to come is beyond our scope of understanding.

    Welcome to the n Collective.
*/
contract PythagoreanMasks is ERC721, Ownable, ReentrancyGuard, ERC721Holder {
    IN public constant n = IN(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6);
    IPunk public constant punk = IPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IRandomizer public constant randomizer = IRandomizer(0x498Ed28C41Eec6732A455158692760c7a3743ECB);

    uint256 public constant RESERVED_N_TOKENS_TO_MINT = 4005;
    uint256 public constant RESERVED_PUNK_TOKENS_TO_MINT = 1001;
    uint256 public constant RESERVED_TEAM_TOKENS_TO_MINT = 879;
    uint256 public constant RESERVED_OPEN_TOKENS_TO_MINT = 3003;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MINT_FEE = 0.0369258147 ether;

    mapping(address => uint256) public nHoldersMintedByAddress;
    uint256 public totalNHoldersMinted;
    mapping(address => uint256) public punkHoldersMintedByAddress;
    uint256 public totalPunkHoldersMinted;
    uint256 public totalTeamMinted;
    uint256 public totalOpenMinted;
    uint256 public totalSupply;
    bool public _finishInitialization;
    uint256 public endMintingPeriodDateAndTime;
    uint256 public nextVestingPeriodDataAndTime;

    string[15] private _firstAssets;
    string[15] private _secondAssets;
    string[15] private _thirdAssets;
    string[15] private _fourthAssets;
    string[15] private _fifthAssets;
    string[15] private _sixthAssets;
    string[15] private _seventhAssets;
    string[15] private _eightAssets;

    modifier onlyWhenInit() {
        require(!_finishInitialization, "Wut?");
        _;
    }

    modifier onlyWhenFinishInit() {
        require(_finishInitialization, "Can't call this yet");
        _;
    }

    modifier includesMintFee(uint256 amountToMint) {
        require(msg.value >= MINT_FEE * amountToMint, "Mint cost 0.0369258147 eth per token");
        _;
    }

    modifier onlyInMintingPeriod() {
        require(endMintingPeriodDateAndTime > block.timestamp, "Claiming period is over");
        _;
    }

    constructor(uint256 _endMintingPeriodDateAndTime) ERC721("Pythagorean Masks", "PythagoreanMasks") {
        endMintingPeriodDateAndTime = _endMintingPeriodDateAndTime;
        nextVestingPeriodDataAndTime = block.timestamp + (30 * 24 * 60 * 60);
    }

    function setFirstAssets(string[15] memory first) public onlyOwner onlyWhenInit {
        _firstAssets = first;
    }

    function setSecondAssets(string[15] memory second) public onlyOwner onlyWhenInit {
        _secondAssets = second;
    }

    function setThirdAssets(string[15] memory third) public onlyOwner onlyWhenInit {
        _thirdAssets = third;
    }

    function setFourthAssets(string[15] memory fourth) public onlyOwner onlyWhenInit {
        _fourthAssets = fourth;
    }

    function setFifthAssets(string[15] memory fifth) public onlyOwner onlyWhenInit {
        _fifthAssets = fifth;
    }

    function setSixthAssets(string[15] memory sixth) public onlyOwner onlyWhenInit {
        _sixthAssets = sixth;
    }

    function setSeventhAssets(string[15] memory seventh) public onlyOwner onlyWhenInit {
        _seventhAssets = seventh;
    }

    function setEightAssets(string[15] memory eight) public onlyOwner onlyWhenInit {
        _eightAssets = eight;
    }

    function finishInitialization(address newOwner) public onlyOwner onlyWhenInit {
        _finishInitialization = true;
        transferOwnership(newOwner);
    }

    function claimVestedTeamTokens(uint256[] memory tokenIds) public onlyOwner onlyWhenFinishInit {
        require(block.timestamp > nextVestingPeriodDataAndTime, "can't claim yet");
        // Vesting period every 1 month
        nextVestingPeriodDataAndTime = nextVestingPeriodDataAndTime + (30 * 24 * 60 * 60);
        for (uint256 i; i < tokenIds.length && i < 88; i++) {
            _safeTransfer(address(this), owner(), tokenIds[i], "");
        }
    }

    function mintToken(uint256 amountToMint)
        public
        payable
        nonReentrant
        includesMintFee(amountToMint)
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(amountToMint > 0, "Amount cannot be zero");
        require(totalOpenMinted < RESERVED_OPEN_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 i;
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (; i < amountToMint && totalOpenMinted < RESERVED_OPEN_TOKENS_TO_MINT; i++) {
            totalOpenMinted++;
            randomNumber = mintNextToken(randomNumber, msg.sender) + 1;
        }
        uint256 mintingFee = i * MINT_FEE;
        if (mintingFee > 0) {
            Address.sendValue(payable(owner()), mintingFee);
        }
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForNHolders(uint256 amountToMint)
        public
        payable
        nonReentrant
        includesMintFee(amountToMint)
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(amountToMint > 0, "Amount cannot be zero");
        require(totalNHoldersMinted < RESERVED_N_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 balance = n.balanceOf(msg.sender);
        require(balance > 0 && balance > nHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256 i;
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (
            ;
            i < amountToMint &&
                totalNHoldersMinted < RESERVED_N_TOKENS_TO_MINT &&
                balance > nHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalNHoldersMinted++;
            nHoldersMintedByAddress[msg.sender]++;
            randomNumber = mintNextToken(randomNumber, msg.sender) + 1;
        }
        uint256 mintingFee = i * MINT_FEE;
        if (mintingFee > 0) {
            Address.sendValue(payable(owner()), mintingFee);
        }
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForPunkHolders(uint256 amountToMint)
        public
        payable
        nonReentrant
        includesMintFee(amountToMint)
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(amountToMint > 0, "Amount cannot be zero");
        require(totalPunkHoldersMinted < RESERVED_PUNK_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 balance = punk.balanceOf(msg.sender);
        require(balance > 0 && balance > punkHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256 i;
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (
            ;
            i < amountToMint &&
                totalPunkHoldersMinted < RESERVED_PUNK_TOKENS_TO_MINT &&
                balance > punkHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalPunkHoldersMinted++;
            punkHoldersMintedByAddress[msg.sender]++;
            randomNumber = mintNextToken(randomNumber, msg.sender) + 1;
        }
        uint256 mintingFee = i * MINT_FEE;
        if (mintingFee > 0) {
            Address.sendValue(payable(owner()), mintingFee);
        }
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForTeam(uint256 amountToMint)
        public
        nonReentrant
        onlyOwner
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(totalTeamMinted < RESERVED_TEAM_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (uint256 i; i < amountToMint && totalTeamMinted < RESERVED_TEAM_TOKENS_TO_MINT; i++) {
            totalTeamMinted++;
            // Only 10% now
            randomNumber = mintNextToken(randomNumber, totalTeamMinted > 87 ? address(this) : msg.sender) + 1;
        }
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return n.getFirst(tokenId);
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return n.getSecond(tokenId);
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return n.getThird(tokenId);
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return n.getFourth(tokenId);
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return n.getFifth(tokenId);
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return n.getSixth(tokenId);
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return n.getSeventh(tokenId);
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return n.getEight(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[12] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 842 902"><defs><style> .cls-1{fill:#060606;}.cls-2{fill:url(#linear-gradient);}.cls-3{fill:url(#linear-gradient-2);}.cls-4{fill:url(#linear-gradient-3);}.cls-5{fill:url(#linear-gradient-4);}.cls-6{fill:url(#linear-gradient-5);}.cls-7{fill:url(#linear-gradient-6);}.cls-8{fill:url(#linear-gradient-7);}.cls-9{fill:url(#linear-gradient-8);}.cls-10{fill:url(#linear-gradient-9);}.cls-11{fill:url(#linear-gradient-10);} </style><linearGradient id="linear-gradient" x1="209.77" y1="593.77" x2="468.51" y2="548.14" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.01" stop-color="#acacac"/><stop offset="0.16" stop-color="#d0d0d0"/><stop offset="0.3" stop-color="#eaeaea"/><stop offset="0.43" stop-color="#fafafa"/><stop offset="0.53" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-2" x1="314" y1="573.93" x2="314" y2="841.6" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.44" stop-color="#dbdbdb"/><stop offset="0.8" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-3" x1="369.19" y1="485.41" x2="275.93" y2="646.94" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.13" stop-color="silver" stop-opacity="0.74"/><stop offset="0.28" stop-color="#d7d7d7" stop-opacity="0.47"/><stop offset="0.42" stop-color="#e8e8e8" stop-opacity="0.27"/><stop offset="0.56" stop-color="#f5f5f5" stop-opacity="0.12"/><stop offset="0.68" stop-color="#fcfcfc" stop-opacity="0.03"/><stop offset="0.78" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-4" x1="409.55" y1="666.27" x2="371.34" y2="666.27" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.25" stop-color="silver"/><stop offset="0.78" stop-color="#f7f7f7"/><stop offset="0.85" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-5" x1="394.32" y1="669.89" x2="394.32" y2="689.04" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.3" stop-color="silver"/><stop offset="0.92" stop-color="#f7f7f7"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-6" x1="395.2" y1="659.62" x2="395.2" y2="708.24" gradientUnits="userSpaceOnUse"><stop offset="0.38" stop-color="#aaa"/><stop offset="0.48" stop-color="#acacac" stop-opacity="0.98"/><stop offset="0.58" stop-color="#b2b2b2" stop-opacity="0.91"/><stop offset="0.67" stop-color="#bbb" stop-opacity="0.8"/><stop offset="0.76" stop-color="#c8c8c8" stop-opacity="0.64"/><stop offset="0.85" stop-color="#dadada" stop-opacity="0.44"/><stop offset="0.94" stop-color="#eee" stop-opacity="0.2"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-7" x1="411.09" y1="690.84" x2="411.09" y2="643.92" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.06" stop-color="#b4b4b4"/><stop offset="0.28" stop-color="#d4d4d4"/><stop offset="0.49" stop-color="#ececec"/><stop offset="0.68" stop-color="#fafafa"/><stop offset="0.85" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-8" x1="379.82" y1="841.71" x2="379.82" y2="783.12" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.17" stop-color="silver" stop-opacity="0.75"/><stop offset="0.55" stop-color="#ededed" stop-opacity="0.21"/><stop offset="0.72" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-9" x1="394.9" y1="762.41" x2="394.9" y2="803.85" gradientUnits="userSpaceOnUse"><stop offset="0.08" stop-color="#aaa"/><stop offset="0.26" stop-color="#c8c8c8" stop-opacity="0.65"/><stop offset="0.44" stop-color="#e0e0e0" stop-opacity="0.37"/><stop offset="0.59" stop-color="#f1f1f1" stop-opacity="0.17"/><stop offset="0.71" stop-color="#fbfbfb" stop-opacity="0.04"/><stop offset="0.79" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-10" x1="319.93" y1="509.65" x2="306.85" y2="583.81" gradientUnits="userSpaceOnUse"><stop offset="0.37" stop-color="#aaa"/><stop offset="0.43" stop-color="#b1b1b1" stop-opacity="0.91"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>';

        parts[1] = buildVariation(_firstAssets[getFirst(tokenId)]);
        parts[2] = buildVariation(_secondAssets[getSecond(tokenId)]);

        // Must be third
        parts[3] = buildVariation(
            '<path class="cls-2" d="M216.1,359.5l-12.4,52a34.9,34.9,0,0,0,3.5,24.9l8.1,14.6s11.6,26.1,3.1,56.2l-7.5,27.7a120.3,120.3,0,0,0,5,77.2c9.2,22,21.6,49.3,34.9,71.8,27,45.6,51.7,92.7,51.7,92.7s35.6,66.3,118.5,63.2V278.7s-97.8.6-171.2,38A64.5,64.5,0,0,0,216.1,359.5Z"/><path class="cls-3" d="M421,740.2V841.6c-82.4,1-118.5-65-118.5-65s-24.7-47.1-51.7-92.7c-13.3-22.5-25.7-49.8-34.9-71.8a120.2,120.2,0,0,1-8.9-38.2s1.6,29.9,36,44.3l48.8,25.7s28.8,14,36.6,45.8l9.6,26.6A22.7,22.7,0,0,0,355.5,731c7.7,1.3,17.4,2.7,25.2,2.7Z"/><path class="cls-4" d="M205.7,433.5s21.7,34.7,115.7,37c0,0,16.2-1.1,36.9,8.9a99.2,99.2,0,0,1,37.1,31.5l2.8,4a70.4,70.4,0,0,1,13,47c-1.7,21.2-4.5,49.8-7.9,64.4L401.7,641a59.4,59.4,0,0,0,1.7,22.2l4.1,15.4a15.8,15.8,0,0,0,12.7,11.6h.8v40.4l-93.5-72.4A326.8,326.8,0,0,1,223.2,519.4l-4.8-12.2s8.4-26.7-3.1-56.2Z"/><path class="cls-5" d="M409.5,683.2l-7.4-25.8a35.7,35.7,0,0,1-.7-8.1H385.2a13.1,13.1,0,0,0-11.4,6.6c-2.2,3.9-3.6,9.7-1.2,17.4Z"/><path class="cls-6" d="M372.6,673.3s1.2-3.9,9-3.3a23.8,23.8,0,0,1,10,3.1l17.9,10.1a17.5,17.5,0,0,0,3.2,3.5,13.3,13.3,0,0,0,3.7,2.3l-26.9-6.7-6.6-1.5C378.7,680,370.5,677.8,372.6,673.3Z"/><path class="cls-7" d="M372.2,659.6a29.3,29.3,0,0,0,0,15.3s-.5,4.3,13.8,6.5l29.5,7.2s2.9,2.1,5.5,1.7v17.9s-29.7-3.3-46.9-25c-5.2-6.5-6.1-14-2.7-23C371.5,659.9,371.9,659.8,372.2,659.6Z"/><path class="cls-1" d="M380.9,680.4c.4-1.7,4.3-2.7,8.2-1.7s6.7,3.4,6.3,5"/><path class="cls-8" d="M421,690.8s-6.1.4-11.5-7.6l-7.6-26.9s-1.3-4.5-.4-12.4H421Z"/><path class="cls-9" d="M421,841.6s-28.2,2.3-59-12.6-22.3-45.9-22.3-45.9l81.3,8Z"/><path class="cls-10" d="M372.2,775c8.3-7.1,21.2-12.6,48.8-12.6v41.5l-45-12.1A9.7,9.7,0,0,1,372.2,775Z"/><path class="cls-11" d="M394.3,566.5s-14.1-11-43.8-7.2-56.9-4.1-67.4-10.1c0,0-30.5-17-45-54,0,0-3.3,52.6,53.6,81.5S394.3,566.5,394.3,566.5Z"/>'
        );

        parts[5] = buildVariation(_thirdAssets[getThird(tokenId)]);
        parts[6] = buildVariation(_fourthAssets[getFourth(tokenId)]);
        parts[7] = buildVariation(_fifthAssets[getFifth(tokenId)]);
        parts[8] = buildVariation(_sixthAssets[getSixth(tokenId)]);
        parts[9] = buildVariation(_seventhAssets[getSeventh(tokenId)]);
        parts[10] = buildVariation(_eightAssets[getEight(tokenId)]);

        parts[11] = "</svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Pythagorean Mask # ',
                        toString(tokenId),
                        '", "description": "The Pythagorean school of thought teaches us that numbers are the basis of the entire universe, the base layer of perceived reality. The rest is but a mere expression of those. Numbers are all around us, have always been, will always be. Welcome to the n Collective.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function buildVariation(string memory variation) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                "<g>",
                variation,
                "</g>",
                '<g transform="scale(-1 1) translate(-842,0)">',
                variation,
                "</g>"
            )
        );
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

    // For gas efficiency, allowing to send the random number
    function mintNextToken(uint256 randomNumber, address to) internal returns (uint256) {
        uint256 nextTokenId = getNextToken(randomNumber);
        _safeMint(to, nextTokenId);
        totalSupply++;
        return nextTokenId;
    }

    function getNextToken(uint256 randomNumber) internal view returns (uint256) {
        uint256 nextToken = randomNumber;
        for (uint256 i; i < MAX_SUPPLY; i++) {
            if (!_exists(nextToken)) {
                break;
            }
            nextToken = (nextToken + 1) % MAX_SUPPLY;
        }
        return nextToken;
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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

