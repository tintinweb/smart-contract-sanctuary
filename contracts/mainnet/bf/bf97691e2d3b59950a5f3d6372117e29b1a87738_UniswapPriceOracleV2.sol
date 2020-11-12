// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

interface CErc20 {
    function underlying() external view returns (address);
}

contract UniswapConfig {
    enum PriceSource {
        FIXED_ETH, /// 0: implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// 1: implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER_ETH,   /// 2: implies the price is set by the reporter
        REPORTER_USDT_OR_USDC /// 3:get price by uniswap  TOKEN/USDT or TOKEN/USDC
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        address gToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isPrice1FromUniswap; // if (isPrice1FromUniswap) {return cumulativePrice1;} else {return cumulativePrice0;}
    }

    /// @notice The max number of tokens this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint public constant maxTokens = 20;

    /// @notice The number of tokens this contract actually supports
    uint public immutable numTokens;

    address internal immutable gToken00;
    address internal immutable gToken01;
    address internal immutable gToken02;
    address internal immutable gToken03;
    address internal immutable gToken04;
    address internal immutable gToken05;
    address internal immutable gToken06;
    address internal immutable gToken07;
    address internal immutable gToken08;
    address internal immutable gToken09;
    address internal immutable gToken10;
    address internal immutable gToken11;
    address internal immutable gToken12;
    address internal immutable gToken13;
    address internal immutable gToken14;
    address internal immutable gToken15;
    address internal immutable gToken16;
    address internal immutable gToken17;
    address internal immutable gToken18;
    address internal immutable gToken19;


    address internal immutable underlying00;
    address internal immutable underlying01;
    address internal immutable underlying02;
    address internal immutable underlying03;
    address internal immutable underlying04;
    address internal immutable underlying05;
    address internal immutable underlying06;
    address internal immutable underlying07;
    address internal immutable underlying08;
    address internal immutable underlying09;
    address internal immutable underlying10;
    address internal immutable underlying11;
    address internal immutable underlying12;
    address internal immutable underlying13;
    address internal immutable underlying14;
    address internal immutable underlying15;
    address internal immutable underlying16;
    address internal immutable underlying17;
    address internal immutable underlying18;
    address internal immutable underlying19;


    bytes32 internal immutable symbolHash00;
    bytes32 internal immutable symbolHash01;
    bytes32 internal immutable symbolHash02;
    bytes32 internal immutable symbolHash03;
    bytes32 internal immutable symbolHash04;
    bytes32 internal immutable symbolHash05;
    bytes32 internal immutable symbolHash06;
    bytes32 internal immutable symbolHash07;
    bytes32 internal immutable symbolHash08;
    bytes32 internal immutable symbolHash09;
    bytes32 internal immutable symbolHash10;
    bytes32 internal immutable symbolHash11;
    bytes32 internal immutable symbolHash12;
    bytes32 internal immutable symbolHash13;
    bytes32 internal immutable symbolHash14;
    bytes32 internal immutable symbolHash15;
    bytes32 internal immutable symbolHash16;
    bytes32 internal immutable symbolHash17;
    bytes32 internal immutable symbolHash18;
    bytes32 internal immutable symbolHash19;

    uint256 internal immutable baseUnit00;
    uint256 internal immutable baseUnit01;
    uint256 internal immutable baseUnit02;
    uint256 internal immutable baseUnit03;
    uint256 internal immutable baseUnit04;
    uint256 internal immutable baseUnit05;
    uint256 internal immutable baseUnit06;
    uint256 internal immutable baseUnit07;
    uint256 internal immutable baseUnit08;
    uint256 internal immutable baseUnit09;
    uint256 internal immutable baseUnit10;
    uint256 internal immutable baseUnit11;
    uint256 internal immutable baseUnit12;
    uint256 internal immutable baseUnit13;
    uint256 internal immutable baseUnit14;
    uint256 internal immutable baseUnit15;
    uint256 internal immutable baseUnit16;
    uint256 internal immutable baseUnit17;
    uint256 internal immutable baseUnit18;
    uint256 internal immutable baseUnit19;

    PriceSource internal immutable priceSource00;
    PriceSource internal immutable priceSource01;
    PriceSource internal immutable priceSource02;
    PriceSource internal immutable priceSource03;
    PriceSource internal immutable priceSource04;
    PriceSource internal immutable priceSource05;
    PriceSource internal immutable priceSource06;
    PriceSource internal immutable priceSource07;
    PriceSource internal immutable priceSource08;
    PriceSource internal immutable priceSource09;
    PriceSource internal immutable priceSource10;
    PriceSource internal immutable priceSource11;
    PriceSource internal immutable priceSource12;
    PriceSource internal immutable priceSource13;
    PriceSource internal immutable priceSource14;
    PriceSource internal immutable priceSource15;
    PriceSource internal immutable priceSource16;
    PriceSource internal immutable priceSource17;
    PriceSource internal immutable priceSource18;
    PriceSource internal immutable priceSource19;

    uint256 internal immutable fixedPrice00;
    uint256 internal immutable fixedPrice01;
    uint256 internal immutable fixedPrice02;
    uint256 internal immutable fixedPrice03;
    uint256 internal immutable fixedPrice04;
    uint256 internal immutable fixedPrice05;
    uint256 internal immutable fixedPrice06;
    uint256 internal immutable fixedPrice07;
    uint256 internal immutable fixedPrice08;
    uint256 internal immutable fixedPrice09;
    uint256 internal immutable fixedPrice10;
    uint256 internal immutable fixedPrice11;
    uint256 internal immutable fixedPrice12;
    uint256 internal immutable fixedPrice13;
    uint256 internal immutable fixedPrice14;
    uint256 internal immutable fixedPrice15;
    uint256 internal immutable fixedPrice16;
    uint256 internal immutable fixedPrice17;
    uint256 internal immutable fixedPrice18;
    uint256 internal immutable fixedPrice19;

    address internal immutable uniswapMarket00;
    address internal immutable uniswapMarket01;
    address internal immutable uniswapMarket02;
    address internal immutable uniswapMarket03;
    address internal immutable uniswapMarket04;
    address internal immutable uniswapMarket05;
    address internal immutable uniswapMarket06;
    address internal immutable uniswapMarket07;
    address internal immutable uniswapMarket08;
    address internal immutable uniswapMarket09;
    address internal immutable uniswapMarket10;
    address internal immutable uniswapMarket11;
    address internal immutable uniswapMarket12;
    address internal immutable uniswapMarket13;
    address internal immutable uniswapMarket14;
    address internal immutable uniswapMarket15;
    address internal immutable uniswapMarket16;
    address internal immutable uniswapMarket17;
    address internal immutable uniswapMarket18;
    address internal immutable uniswapMarket19;

    bool internal immutable isPrice1FromUniswap00;
    bool internal immutable isPrice1FromUniswap01;
    bool internal immutable isPrice1FromUniswap02;
    bool internal immutable isPrice1FromUniswap03;
    bool internal immutable isPrice1FromUniswap04;
    bool internal immutable isPrice1FromUniswap05;
    bool internal immutable isPrice1FromUniswap06;
    bool internal immutable isPrice1FromUniswap07;
    bool internal immutable isPrice1FromUniswap08;
    bool internal immutable isPrice1FromUniswap09;
    bool internal immutable isPrice1FromUniswap10;
    bool internal immutable isPrice1FromUniswap11;
    bool internal immutable isPrice1FromUniswap12;
    bool internal immutable isPrice1FromUniswap13;
    bool internal immutable isPrice1FromUniswap14;
    bool internal immutable isPrice1FromUniswap15;
    bool internal immutable isPrice1FromUniswap16;
    bool internal immutable isPrice1FromUniswap17;
    bool internal immutable isPrice1FromUniswap18;
    bool internal immutable isPrice1FromUniswap19;

    constructor(address[] memory gTokens_, address[] memory underlyings_,
        bytes32[] memory symbolHashs_, uint256[] memory baseUints_,
        PriceSource[] memory priceSources_, uint256[] memory fixedPrices_, address[] memory uniswapMarkets_, bool[] memory isPrice1FromUniswapArray_) public {

        require(gTokens_.length <= maxTokens, "too many gToken");
        TokenConfig[] memory configs = new TokenConfig[](maxTokens);
        for (uint i = 0; i < gTokens_.length; i++) {
            TokenConfig memory config = TokenConfig({
            gToken : gTokens_[i],
            underlying : underlyings_[i],
            symbolHash : symbolHashs_[i],
            baseUnit : baseUints_[i],
            priceSource: priceSources_[i],
            fixedPrice: fixedPrices_[i],
            uniswapMarket : uniswapMarkets_[i],
            isPrice1FromUniswap : isPrice1FromUniswapArray_[i]
            });
            configs[i] = config;
        }

        require(configs.length <= maxTokens, "too many configs");
        numTokens = configs.length;

        gToken00 = get(configs, 0).gToken;
        gToken01 = get(configs, 1).gToken;
        gToken02 = get(configs, 2).gToken;
        gToken03 = get(configs, 3).gToken;
        gToken04 = get(configs, 4).gToken;
        gToken05 = get(configs, 5).gToken;
        gToken06 = get(configs, 6).gToken;
        gToken07 = get(configs, 7).gToken;
        gToken08 = get(configs, 8).gToken;
        gToken09 = get(configs, 9).gToken;
        gToken10 = get(configs, 10).gToken;
        gToken11 = get(configs, 11).gToken;
        gToken12 = get(configs, 12).gToken;
        gToken13 = get(configs, 13).gToken;
        gToken14 = get(configs, 14).gToken;
        gToken15 = get(configs, 15).gToken;
        gToken16 = get(configs, 16).gToken;
        gToken17 = get(configs, 17).gToken;
        gToken18 = get(configs, 18).gToken;
        gToken19 = get(configs, 19).gToken;

        underlying00 = get(configs, 0).underlying;
        underlying01 = get(configs, 1).underlying;
        underlying02 = get(configs, 2).underlying;
        underlying03 = get(configs, 3).underlying;
        underlying04 = get(configs, 4).underlying;
        underlying05 = get(configs, 5).underlying;
        underlying06 = get(configs, 6).underlying;
        underlying07 = get(configs, 7).underlying;
        underlying08 = get(configs, 8).underlying;
        underlying09 = get(configs, 9).underlying;
        underlying10 = get(configs, 10).underlying;
        underlying11 = get(configs, 11).underlying;
        underlying12 = get(configs, 12).underlying;
        underlying13 = get(configs, 13).underlying;
        underlying14 = get(configs, 14).underlying;
        underlying15 = get(configs, 15).underlying;
        underlying16 = get(configs, 16).underlying;
        underlying17 = get(configs, 17).underlying;
        underlying18 = get(configs, 18).underlying;
        underlying19 = get(configs, 19).underlying;

        symbolHash00 = get(configs, 0).symbolHash;
        symbolHash01 = get(configs, 1).symbolHash;
        symbolHash02 = get(configs, 2).symbolHash;
        symbolHash03 = get(configs, 3).symbolHash;
        symbolHash04 = get(configs, 4).symbolHash;
        symbolHash05 = get(configs, 5).symbolHash;
        symbolHash06 = get(configs, 6).symbolHash;
        symbolHash07 = get(configs, 7).symbolHash;
        symbolHash08 = get(configs, 8).symbolHash;
        symbolHash09 = get(configs, 9).symbolHash;
        symbolHash10 = get(configs, 10).symbolHash;
        symbolHash11 = get(configs, 11).symbolHash;
        symbolHash12 = get(configs, 12).symbolHash;
        symbolHash13 = get(configs, 13).symbolHash;
        symbolHash14 = get(configs, 14).symbolHash;
        symbolHash15 = get(configs, 15).symbolHash;
        symbolHash16 = get(configs, 16).symbolHash;
        symbolHash17 = get(configs, 17).symbolHash;
        symbolHash18 = get(configs, 18).symbolHash;
        symbolHash19 = get(configs, 19).symbolHash;

        baseUnit00 = get(configs, 0).baseUnit;
        baseUnit01 = get(configs, 1).baseUnit;
        baseUnit02 = get(configs, 2).baseUnit;
        baseUnit03 = get(configs, 3).baseUnit;
        baseUnit04 = get(configs, 4).baseUnit;
        baseUnit05 = get(configs, 5).baseUnit;
        baseUnit06 = get(configs, 6).baseUnit;
        baseUnit07 = get(configs, 7).baseUnit;
        baseUnit08 = get(configs, 8).baseUnit;
        baseUnit09 = get(configs, 9).baseUnit;
        baseUnit10 = get(configs, 10).baseUnit;
        baseUnit11 = get(configs, 11).baseUnit;
        baseUnit12 = get(configs, 12).baseUnit;
        baseUnit13 = get(configs, 13).baseUnit;
        baseUnit14 = get(configs, 14).baseUnit;
        baseUnit15 = get(configs, 15).baseUnit;
        baseUnit16 = get(configs, 16).baseUnit;
        baseUnit17 = get(configs, 17).baseUnit;
        baseUnit18 = get(configs, 18).baseUnit;
        baseUnit19 = get(configs, 19).baseUnit;

        priceSource00 = get(configs, 0).priceSource;
        priceSource01 = get(configs, 1).priceSource;
        priceSource02 = get(configs, 2).priceSource;
        priceSource03 = get(configs, 3).priceSource;
        priceSource04 = get(configs, 4).priceSource;
        priceSource05 = get(configs, 5).priceSource;
        priceSource06 = get(configs, 6).priceSource;
        priceSource07 = get(configs, 7).priceSource;
        priceSource08 = get(configs, 8).priceSource;
        priceSource09 = get(configs, 9).priceSource;
        priceSource10 = get(configs, 10).priceSource;
        priceSource11 = get(configs, 11).priceSource;
        priceSource12 = get(configs, 12).priceSource;
        priceSource13 = get(configs, 13).priceSource;
        priceSource14 = get(configs, 14).priceSource;
        priceSource15 = get(configs, 15).priceSource;
        priceSource16 = get(configs, 16).priceSource;
        priceSource17 = get(configs, 17).priceSource;
        priceSource18 = get(configs, 18).priceSource;
        priceSource19 = get(configs, 19).priceSource;

        fixedPrice00 = get(configs, 0).fixedPrice;
        fixedPrice01 = get(configs, 1).fixedPrice;
        fixedPrice02 = get(configs, 2).fixedPrice;
        fixedPrice03 = get(configs, 3).fixedPrice;
        fixedPrice04 = get(configs, 4).fixedPrice;
        fixedPrice05 = get(configs, 5).fixedPrice;
        fixedPrice06 = get(configs, 6).fixedPrice;
        fixedPrice07 = get(configs, 7).fixedPrice;
        fixedPrice08 = get(configs, 8).fixedPrice;
        fixedPrice09 = get(configs, 9).fixedPrice;
        fixedPrice10 = get(configs, 10).fixedPrice;
        fixedPrice11 = get(configs, 11).fixedPrice;
        fixedPrice12 = get(configs, 12).fixedPrice;
        fixedPrice13 = get(configs, 13).fixedPrice;
        fixedPrice14 = get(configs, 14).fixedPrice;
        fixedPrice15 = get(configs, 15).fixedPrice;
        fixedPrice16 = get(configs, 16).fixedPrice;
        fixedPrice17 = get(configs, 17).fixedPrice;
        fixedPrice18 = get(configs, 18).fixedPrice;
        fixedPrice19 = get(configs, 19).fixedPrice;

        uniswapMarket00 = get(configs, 0).uniswapMarket;
        uniswapMarket01 = get(configs, 1).uniswapMarket;
        uniswapMarket02 = get(configs, 2).uniswapMarket;
        uniswapMarket03 = get(configs, 3).uniswapMarket;
        uniswapMarket04 = get(configs, 4).uniswapMarket;
        uniswapMarket05 = get(configs, 5).uniswapMarket;
        uniswapMarket06 = get(configs, 6).uniswapMarket;
        uniswapMarket07 = get(configs, 7).uniswapMarket;
        uniswapMarket08 = get(configs, 8).uniswapMarket;
        uniswapMarket09 = get(configs, 9).uniswapMarket;
        uniswapMarket10 = get(configs, 10).uniswapMarket;
        uniswapMarket11 = get(configs, 11).uniswapMarket;
        uniswapMarket12 = get(configs, 12).uniswapMarket;
        uniswapMarket13 = get(configs, 13).uniswapMarket;
        uniswapMarket14 = get(configs, 14).uniswapMarket;
        uniswapMarket15 = get(configs, 15).uniswapMarket;
        uniswapMarket16 = get(configs, 16).uniswapMarket;
        uniswapMarket17 = get(configs, 17).uniswapMarket;
        uniswapMarket18 = get(configs, 18).uniswapMarket;
        uniswapMarket19 = get(configs, 19).uniswapMarket;

        isPrice1FromUniswap00 = get(configs, 0).isPrice1FromUniswap;
        isPrice1FromUniswap01 = get(configs, 1).isPrice1FromUniswap;
        isPrice1FromUniswap02 = get(configs, 2).isPrice1FromUniswap;
        isPrice1FromUniswap03 = get(configs, 3).isPrice1FromUniswap;
        isPrice1FromUniswap04 = get(configs, 4).isPrice1FromUniswap;
        isPrice1FromUniswap05 = get(configs, 5).isPrice1FromUniswap;
        isPrice1FromUniswap06 = get(configs, 6).isPrice1FromUniswap;
        isPrice1FromUniswap07 = get(configs, 7).isPrice1FromUniswap;
        isPrice1FromUniswap08 = get(configs, 8).isPrice1FromUniswap;
        isPrice1FromUniswap09 = get(configs, 9).isPrice1FromUniswap;
        isPrice1FromUniswap10 = get(configs, 10).isPrice1FromUniswap;
        isPrice1FromUniswap11 = get(configs, 11).isPrice1FromUniswap;
        isPrice1FromUniswap12 = get(configs, 12).isPrice1FromUniswap;
        isPrice1FromUniswap13 = get(configs, 13).isPrice1FromUniswap;
        isPrice1FromUniswap14 = get(configs, 14).isPrice1FromUniswap;
        isPrice1FromUniswap15 = get(configs, 15).isPrice1FromUniswap;
        isPrice1FromUniswap16 = get(configs, 16).isPrice1FromUniswap;
        isPrice1FromUniswap17 = get(configs, 17).isPrice1FromUniswap;
        isPrice1FromUniswap18 = get(configs, 18).isPrice1FromUniswap;
        isPrice1FromUniswap19 = get(configs, 19).isPrice1FromUniswap;
    }

    function get(TokenConfig[] memory configs, uint i) internal pure returns (TokenConfig memory) {
        if (i < configs.length)
            return configs[i];
        return TokenConfig({
        gToken : address(0),
        underlying : address(0),
        symbolHash : bytes32(0),
        baseUnit : uint256(0),
        priceSource: PriceSource(0),
        fixedPrice: uint256(0),
        uniswapMarket : address(0),
        isPrice1FromUniswap : false
        });
    }

    function getCTokenIndex(address gToken) internal view returns (uint) {
        if (gToken == gToken00) return 0;
        if (gToken == gToken01) return 1;
        if (gToken == gToken02) return 2;
        if (gToken == gToken03) return 3;
        if (gToken == gToken04) return 4;
        if (gToken == gToken05) return 5;
        if (gToken == gToken06) return 6;
        if (gToken == gToken07) return 7;
        if (gToken == gToken08) return 8;
        if (gToken == gToken09) return 9;
        if (gToken == gToken10) return 10;
        if (gToken == gToken11) return 11;
        if (gToken == gToken12) return 12;
        if (gToken == gToken13) return 13;
        if (gToken == gToken14) return 14;
        if (gToken == gToken15) return 15;
        if (gToken == gToken16) return 16;
        if (gToken == gToken17) return 17;
        if (gToken == gToken18) return 18;
        if (gToken == gToken19) return 19;

        return uint(- 1);
    }

    function getUnderlyingIndex(address underlying) internal view returns (uint) {
        if (underlying == underlying00) return 0;
        if (underlying == underlying01) return 1;
        if (underlying == underlying02) return 2;
        if (underlying == underlying03) return 3;
        if (underlying == underlying04) return 4;
        if (underlying == underlying05) return 5;
        if (underlying == underlying06) return 6;
        if (underlying == underlying07) return 7;
        if (underlying == underlying08) return 8;
        if (underlying == underlying09) return 9;
        if (underlying == underlying10) return 10;
        if (underlying == underlying11) return 11;
        if (underlying == underlying12) return 12;
        if (underlying == underlying13) return 13;
        if (underlying == underlying14) return 14;
        if (underlying == underlying15) return 15;
        if (underlying == underlying16) return 16;
        if (underlying == underlying17) return 17;
        if (underlying == underlying18) return 18;
        if (underlying == underlying19) return 19;

        return uint(- 1);
    }

    function getSymbolHashIndex(bytes32 symbolHash) internal view returns (uint) {
        if (symbolHash == symbolHash00) return 0;
        if (symbolHash == symbolHash01) return 1;
        if (symbolHash == symbolHash02) return 2;
        if (symbolHash == symbolHash03) return 3;
        if (symbolHash == symbolHash04) return 4;
        if (symbolHash == symbolHash05) return 5;
        if (symbolHash == symbolHash06) return 6;
        if (symbolHash == symbolHash07) return 7;
        if (symbolHash == symbolHash08) return 8;
        if (symbolHash == symbolHash09) return 9;
        if (symbolHash == symbolHash10) return 10;
        if (symbolHash == symbolHash11) return 11;
        if (symbolHash == symbolHash12) return 12;
        if (symbolHash == symbolHash13) return 13;
        if (symbolHash == symbolHash14) return 14;
        if (symbolHash == symbolHash15) return 15;
        if (symbolHash == symbolHash16) return 16;
        if (symbolHash == symbolHash17) return 17;
        if (symbolHash == symbolHash18) return 18;
        if (symbolHash == symbolHash19) return 19;

        return uint(- 1);
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < numTokens, "token config not found");

        if (i == 0) return TokenConfig({gToken: gToken00, underlying: underlying00, symbolHash: symbolHash00, baseUnit: baseUnit00, priceSource: priceSource00, fixedPrice: fixedPrice00, uniswapMarket: uniswapMarket00, isPrice1FromUniswap: isPrice1FromUniswap00});
        if (i == 1) return TokenConfig({gToken: gToken01, underlying: underlying01, symbolHash: symbolHash01, baseUnit: baseUnit01, priceSource: priceSource01, fixedPrice: fixedPrice01, uniswapMarket: uniswapMarket01, isPrice1FromUniswap: isPrice1FromUniswap01});
        if (i == 2) return TokenConfig({gToken: gToken02, underlying: underlying02, symbolHash: symbolHash02, baseUnit: baseUnit02, priceSource: priceSource02, fixedPrice: fixedPrice02, uniswapMarket: uniswapMarket02, isPrice1FromUniswap: isPrice1FromUniswap02});
        if (i == 3) return TokenConfig({gToken: gToken03, underlying: underlying03, symbolHash: symbolHash03, baseUnit: baseUnit03, priceSource: priceSource03, fixedPrice: fixedPrice03, uniswapMarket: uniswapMarket03, isPrice1FromUniswap: isPrice1FromUniswap03});
        if (i == 4) return TokenConfig({gToken: gToken04, underlying: underlying04, symbolHash: symbolHash04, baseUnit: baseUnit04, priceSource: priceSource04, fixedPrice: fixedPrice04, uniswapMarket: uniswapMarket04, isPrice1FromUniswap: isPrice1FromUniswap04});
        if (i == 5) return TokenConfig({gToken: gToken05, underlying: underlying05, symbolHash: symbolHash05, baseUnit: baseUnit05, priceSource: priceSource05, fixedPrice: fixedPrice05, uniswapMarket: uniswapMarket05, isPrice1FromUniswap: isPrice1FromUniswap05});
        if (i == 6) return TokenConfig({gToken: gToken06, underlying: underlying06, symbolHash: symbolHash06, baseUnit: baseUnit06, priceSource: priceSource06, fixedPrice: fixedPrice06, uniswapMarket: uniswapMarket06, isPrice1FromUniswap: isPrice1FromUniswap06});
        if (i == 7) return TokenConfig({gToken: gToken07, underlying: underlying07, symbolHash: symbolHash07, baseUnit: baseUnit07, priceSource: priceSource07, fixedPrice: fixedPrice07, uniswapMarket: uniswapMarket07, isPrice1FromUniswap: isPrice1FromUniswap07});
        if (i == 8) return TokenConfig({gToken: gToken08, underlying: underlying08, symbolHash: symbolHash08, baseUnit: baseUnit08, priceSource: priceSource08, fixedPrice: fixedPrice08, uniswapMarket: uniswapMarket08, isPrice1FromUniswap: isPrice1FromUniswap08});
        if (i == 9) return TokenConfig({gToken: gToken09, underlying: underlying09, symbolHash: symbolHash09, baseUnit: baseUnit09, priceSource: priceSource09, fixedPrice: fixedPrice09, uniswapMarket: uniswapMarket09, isPrice1FromUniswap: isPrice1FromUniswap09});

        if (i == 10) return TokenConfig({gToken: gToken10, underlying: underlying10, symbolHash: symbolHash10, baseUnit: baseUnit10, priceSource: priceSource10, fixedPrice: fixedPrice10, uniswapMarket: uniswapMarket10, isPrice1FromUniswap: isPrice1FromUniswap10});
        if (i == 11) return TokenConfig({gToken: gToken11, underlying: underlying11, symbolHash: symbolHash11, baseUnit: baseUnit11, priceSource: priceSource11, fixedPrice: fixedPrice11, uniswapMarket: uniswapMarket11, isPrice1FromUniswap: isPrice1FromUniswap11});
        if (i == 12) return TokenConfig({gToken: gToken12, underlying: underlying12, symbolHash: symbolHash12, baseUnit: baseUnit12, priceSource: priceSource12, fixedPrice: fixedPrice12, uniswapMarket: uniswapMarket12, isPrice1FromUniswap: isPrice1FromUniswap12});
        if (i == 13) return TokenConfig({gToken: gToken13, underlying: underlying13, symbolHash: symbolHash13, baseUnit: baseUnit13, priceSource: priceSource13, fixedPrice: fixedPrice13, uniswapMarket: uniswapMarket13, isPrice1FromUniswap: isPrice1FromUniswap13});
        if (i == 14) return TokenConfig({gToken: gToken14, underlying: underlying14, symbolHash: symbolHash14, baseUnit: baseUnit14, priceSource: priceSource14, fixedPrice: fixedPrice14, uniswapMarket: uniswapMarket14, isPrice1FromUniswap: isPrice1FromUniswap14});
        if (i == 15) return TokenConfig({gToken: gToken15, underlying: underlying15, symbolHash: symbolHash15, baseUnit: baseUnit15, priceSource: priceSource15, fixedPrice: fixedPrice15, uniswapMarket: uniswapMarket15, isPrice1FromUniswap: isPrice1FromUniswap15});
        if (i == 16) return TokenConfig({gToken: gToken16, underlying: underlying16, symbolHash: symbolHash16, baseUnit: baseUnit16, priceSource: priceSource16, fixedPrice: fixedPrice16, uniswapMarket: uniswapMarket16, isPrice1FromUniswap: isPrice1FromUniswap16});
        if (i == 17) return TokenConfig({gToken: gToken17, underlying: underlying17, symbolHash: symbolHash17, baseUnit: baseUnit17, priceSource: priceSource17, fixedPrice: fixedPrice17, uniswapMarket: uniswapMarket17, isPrice1FromUniswap: isPrice1FromUniswap17});
        if (i == 18) return TokenConfig({gToken: gToken18, underlying: underlying18, symbolHash: symbolHash18, baseUnit: baseUnit18, priceSource: priceSource18, fixedPrice: fixedPrice18, uniswapMarket: uniswapMarket18, isPrice1FromUniswap: isPrice1FromUniswap18});
        if (i == 19) return TokenConfig({gToken: gToken19, underlying: underlying19, symbolHash: symbolHash19, baseUnit: baseUnit19, priceSource: priceSource19, fixedPrice: fixedPrice19, uniswapMarket: uniswapMarket19, isPrice1FromUniswap: isPrice1FromUniswap19});
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    /**
     * @notice Get the config for the symbolHash
     * @param symbolHash The keccack256 of the symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbolHash(bytes32 symbolHash) public view returns (TokenConfig memory) {
        uint index = getSymbolHashIndex(symbolHash);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }

    /**
     * @notice Get the config for the gToken
     * @dev If a config for the gToken is not found, falls back to searching for the underlying.
     * @param gToken The address of the gToken of the config to get
     * @return The config object
     */
    function getTokenConfigByCToken(address gToken) public view returns (TokenConfig memory) {
        uint index = getCTokenIndex(gToken);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(CErc20(gToken).underlying());
    }

    /**
     * @notice Get the config for an underlying asset
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying) public view returns (TokenConfig memory) {
        uint index = getUnderlyingIndex(underlying);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }
}




// Based on code from https://github.com/Uniswap/uniswap-v2-periphery

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
    function decode112with18(uq112x112 memory self) internal pure returns (uint) {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint(self._x) / 5192296858534827;
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);
}


    struct Observation {
        uint timestamp;
        uint acc;
    }

contract UniswapPriceOracleV2 is UniswapConfig {
    using FixedPoint for *;

    /// @notice The number of wei in 1 ETH
    uint public constant ethBaseUnit = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint public constant expScale = 1e18;

    /// @notice The Price Oracle admin
    address public immutable admin;

    /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
    uint public immutable anchorPeriod;

    /// @notice Official prices by symbol hash
    mapping(bytes32 => uint) public prices;

    /// @notice The old observation for each symbolHash
    mapping(bytes32 => Observation) public oldObservations;

    /// @notice The new observation for each symbolHash
    mapping(bytes32 => Observation) public newObservations;

    /// @notice The event emitted when new prices are posted but the stored price is not updated due to the anchor
    event PriceGuarded(string symbol, uint reporter, uint anchor);

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(string symbol, uint price);

    /// @notice The event emitted when anchor price is updated
    event AnchorPriceUpdated(string symbol, uint anchorPrice, uint oldTimestamp, uint newTimestamp);

    /// @notice The event emitted when the uniswap window changes
    event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

    bytes32 constant ethHash = keccak256(abi.encodePacked("ETH"));

    constructor(uint anchorPeriod_,
        address[] memory gTokens_, address[] memory underlyings_,
        bytes32[] memory symbolHashs_, uint256[] memory baseUints_,
        PriceSource[] memory priceSources_, uint256[] memory fixedPrices_,
        address[] memory uniswapMarkets_, bool[] memory isPrice1FromUniswapArray_)
    UniswapConfig(gTokens_, underlyings_, symbolHashs_, baseUints_, priceSources_, fixedPrices_, uniswapMarkets_,
        isPrice1FromUniswapArray_) public {
        admin = msg.sender;

        anchorPeriod = anchorPeriod_;

        for (uint i = 0; i < gTokens_.length; i++) {
            TokenConfig memory config = TokenConfig({ gToken : gTokens_[i], underlying : underlyings_[i],
            symbolHash : symbolHashs_[i], baseUnit : baseUints_[i],
            priceSource: priceSources_[i], fixedPrice: fixedPrices_[i],
            uniswapMarket : uniswapMarkets_[i], isPrice1FromUniswap : isPrice1FromUniswapArray_[i] });
            require(config.baseUnit > 0, "baseUnit must be greater than zero");
            address uniswapMarket = config.uniswapMarket;
            if (config.priceSource == PriceSource.REPORTER_ETH || config.priceSource == PriceSource.REPORTER_USDT_OR_USDC) {
                require(uniswapMarket != address(0), "reported prices must have an anchor");
                bytes32 symbolHash = config.symbolHash;
                uint cumulativePrice = currentCumulativePrice(config);
                oldObservations[symbolHash].timestamp = block.timestamp;
                newObservations[symbolHash].timestamp = block.timestamp;
                oldObservations[symbolHash].acc = cumulativePrice;
                newObservations[symbolHash].acc = cumulativePrice;
                emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
            } else {
                require(uniswapMarket == address(0), "only reported prices utilize an anchor");
            }
        }
    }

    /**
     * @notice Get the official price for a symbol
     * @param symbol The symbol to fetch the price of
     * @return Price denominated in USD, with 6 decimals
     */
    function price(string memory symbol) external view returns (uint) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return priceInternal(config);
    }

    function priceInternal(TokenConfig memory config) internal view returns (uint) {
        if (config.priceSource == PriceSource.REPORTER_ETH || config.priceSource == PriceSource.REPORTER_USDT_OR_USDC) return prices[config.symbolHash];
        if (config.priceSource == PriceSource.FIXED_USD) return config.fixedPrice;
        if (config.priceSource == PriceSource.FIXED_ETH) {
            uint usdPerEth = prices[ethHash];
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
            return mul(usdPerEth, config.fixedPrice) / ethBaseUnit;
        }
    }

    /**
     * @notice Get the underlying price of a gToken
     * @dev Implements the PriceOracle interface for Compound v2.
     * @param gToken The gToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given gToken address
     */
    function getUnderlyingPrice(address gToken) external view returns (uint) {
        TokenConfig memory config = getTokenConfigByCToken(gToken);
        // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
        // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    function refresh(string[] calldata symbols) external {
        uint ethPrice = fetchEthPrice();

        // Try to update the view storage
        for (uint i = 0; i < symbols.length; i++) {
            postPriceInternal(symbols[i], ethPrice);
        }
    }

    function postPriceInternal(string memory symbol, uint ethPrice) internal {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);

        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        uint anchorPrice;
        if (symbolHash == ethHash) {
            anchorPrice = ethPrice;
        } else if (config.priceSource == PriceSource.REPORTER_ETH){
            anchorPrice = fetchAnchorPrice(symbol, config, ethPrice);
        }
        else if(config.priceSource == PriceSource.REPORTER_USDT_OR_USDC) {
            anchorPrice = fetchAnchorPriceUSDTorUSDC(symbol, config, config.baseUnit);
        }
        else{
            revert("wrong config.priceSource");
        }


        prices[symbolHash] = anchorPrice;
        emit PriceUpdated(symbol, anchorPrice);
    }

    /**
     * @dev Fetches the current token/eth price accumulator from uniswap.
     */
    function currentCumulativePrice(TokenConfig memory config) internal view returns (uint) {
        (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
        if (config.isPrice1FromUniswap) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    /**
     * @dev Fetches the current eth/usd price from uniswap, with 6 decimals of precision.
     *  Conversion factor is 1e18 for eth/usdc market, since we decode uniswap price statically with 18 decimals.
     */
    function fetchEthPrice() internal returns (uint) {
        return fetchAnchorPrice("ETH", getTokenConfigBySymbolHash(ethHash), ethBaseUnit);
    }

    /**
     * @dev Fetches the current token/usd price from uniswap, with 6 decimals of precision.
     * @param conversionFactor 1e18 if seeking the ETH price, and a 6 decimal ETH-USDC price in the case of other assets
     */
    function fetchAnchorPrice(string memory symbol, TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;

        // Calculate uniswap time-weighted average price
        // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
        uint anchorPrice;

        // Adjust rawUniswapPrice according to the units of the non-ETH asset
        // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels
        if (config.isPrice1FromUniswap) {
            // unscaledPriceMantissa * ethBaseUnit / config.baseUnit / expScale, but we simplify bc ethBaseUnit == expScale
            anchorPrice = unscaledPriceMantissa / config.baseUnit;
        } else {
            anchorPrice = mul(unscaledPriceMantissa, config.baseUnit) / ethBaseUnit / expScale;
        }

        emit AnchorPriceUpdated(symbol, anchorPrice, oldTimestamp, block.timestamp);

        return anchorPrice;
    }

    /**
 * @dev Fetches the current token/usdt or token/usdc price from uniswap, with 6 decimals of precision.
 * @param conversionFactor : token decimals, such as  1e18
 */
    function fetchAnchorPriceUSDTorUSDC(string memory symbol, TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;

        // Calculate uniswap time-weighted average price
        // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
        uint anchorPrice = unscaledPriceMantissa / expScale;

        emit AnchorPriceUpdated(symbol, anchorPrice, oldTimestamp, block.timestamp);

        return anchorPrice;
    }

    /**
     * @dev Get time-weighted average prices for a token at the current timestamp.
     *  Update new and old observations of lagging window if period elapsed.
     */
    function pokeWindowValues(TokenConfig memory config) internal returns (uint, uint, uint) {
        bytes32 symbolHash = config.symbolHash;
        uint cumulativePrice = currentCumulativePrice(config);

        Observation memory newObservation = newObservations[symbolHash];

        // Update new and old observations if elapsed time is greater than or equal to anchor period
        uint timeElapsed = block.timestamp - newObservation.timestamp;
        if (timeElapsed >= anchorPeriod) {
            oldObservations[symbolHash].timestamp = newObservation.timestamp;
            oldObservations[symbolHash].acc = newObservation.acc;

            newObservations[symbolHash].timestamp = block.timestamp;
            newObservations[symbolHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(config.symbolHash, newObservation.timestamp, block.timestamp, newObservation.acc, cumulativePrice);
        }
        return (cumulativePrice, oldObservations[symbolHash].acc, oldObservations[symbolHash].timestamp);
    }


    /**
     * @notice Recovers the source address which signed a message
     * @dev Comparing to a claimed address would add nothing,
     *  as the caller could simply perform the recover and claim that address.
     * @param message The data that was presumably signed
     * @param signature The fingerprint of the data + private key
     * @return The source address which signed the message, presumably
     */
    function source(bytes memory message, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}