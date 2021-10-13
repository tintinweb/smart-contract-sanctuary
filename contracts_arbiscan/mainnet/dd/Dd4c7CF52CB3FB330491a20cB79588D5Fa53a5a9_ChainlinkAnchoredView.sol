// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./AggregatorV3Interface.sol";
import "./FlagsInterface.sol";

/**
 * @notice A contract with helpers for safe contract ownership.
 */
contract Ownable {

    address private ownerAddr;
    address private pendingOwnerAddr;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        ownerAddr = msg.sender;
    }

    /**
    * @notice Allows an owner to begin transferring ownership to a new address,
    * pending.
    */
    function transferOwnership(address to) external onlyOwner() {
        require(to != msg.sender, "Cannot transfer to self");

        pendingOwnerAddr = to;

        emit OwnershipTransferRequested(ownerAddr, to);
    }

    /**
    * @notice Allows an ownership transfer to be dankleted by the recipient.
    */
    function acceptOwnership() external {
        require(msg.sender == pendingOwnerAddr, "Must be proposed owner");

        address oldOwner = ownerAddr;
        ownerAddr = msg.sender;
        pendingOwnerAddr = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
    * @notice Get the current owner
    */
    function owner() public view returns (address) {
        return ownerAddr;
    }

    /**
    * @notice Reverts if called by anyone other than the contract owner.
    */
    modifier onlyOwner() {
        require(msg.sender == ownerAddr, "Only callable by owner");
        _;
    }

}

interface DErc20 {
    function underlying() external view returns (address);
}

contract ChainlinkConfig {

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        address dToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        address chainlinkMarket;
        uint256 reporterMultiplier;
    }

    /// @notice The max number of tokens this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint public constant maxTokens = 25;

    /// @notice The number of tokens this contract actually supports
    uint public immutable numTokens;

    address internal immutable dToken00;
    address internal immutable dToken01;
    address internal immutable dToken02;
    address internal immutable dToken03;
    address internal immutable dToken04;
    address internal immutable dToken05;
    address internal immutable dToken06;
    address internal immutable dToken07;
    address internal immutable dToken08;
    address internal immutable dToken09;
    address internal immutable dToken10;
    address internal immutable dToken11;
    address internal immutable dToken12;
    address internal immutable dToken13;
    address internal immutable dToken14;
    address internal immutable dToken15;
    address internal immutable dToken16;
    address internal immutable dToken17;
    address internal immutable dToken18;
    address internal immutable dToken19;
    address internal immutable dToken20;
    address internal immutable dToken21;
    address internal immutable dToken22;
    address internal immutable dToken23;
    address internal immutable dToken24;

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
    address internal immutable underlying20;
    address internal immutable underlying21;
    address internal immutable underlying22;
    address internal immutable underlying23;
    address internal immutable underlying24;

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
    bytes32 internal immutable symbolHash20;
    bytes32 internal immutable symbolHash21;
    bytes32 internal immutable symbolHash22;
    bytes32 internal immutable symbolHash23;
    bytes32 internal immutable symbolHash24;

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
    uint256 internal immutable baseUnit20;
    uint256 internal immutable baseUnit21;
    uint256 internal immutable baseUnit22;
    uint256 internal immutable baseUnit23;
    uint256 internal immutable baseUnit24;

    address internal immutable chainlinkMarket00;
    address internal immutable chainlinkMarket01;
    address internal immutable chainlinkMarket02;
    address internal immutable chainlinkMarket03;
    address internal immutable chainlinkMarket04;
    address internal immutable chainlinkMarket05;
    address internal immutable chainlinkMarket06;
    address internal immutable chainlinkMarket07;
    address internal immutable chainlinkMarket08;
    address internal immutable chainlinkMarket09;
    address internal immutable chainlinkMarket10;
    address internal immutable chainlinkMarket11;
    address internal immutable chainlinkMarket12;
    address internal immutable chainlinkMarket13;
    address internal immutable chainlinkMarket14;
    address internal immutable chainlinkMarket15;
    address internal immutable chainlinkMarket16;
    address internal immutable chainlinkMarket17;
    address internal immutable chainlinkMarket18;
    address internal immutable chainlinkMarket19;
    address internal immutable chainlinkMarket20;
    address internal immutable chainlinkMarket21;
    address internal immutable chainlinkMarket22;
    address internal immutable chainlinkMarket23;
    address internal immutable chainlinkMarket24;

    uint256 internal immutable reporterMultiplier00;
    uint256 internal immutable reporterMultiplier01;
    uint256 internal immutable reporterMultiplier02;
    uint256 internal immutable reporterMultiplier03;
    uint256 internal immutable reporterMultiplier04;
    uint256 internal immutable reporterMultiplier05;
    uint256 internal immutable reporterMultiplier06;
    uint256 internal immutable reporterMultiplier07;
    uint256 internal immutable reporterMultiplier08;
    uint256 internal immutable reporterMultiplier09;
    uint256 internal immutable reporterMultiplier10;
    uint256 internal immutable reporterMultiplier11;
    uint256 internal immutable reporterMultiplier12;
    uint256 internal immutable reporterMultiplier13;
    uint256 internal immutable reporterMultiplier14;
    uint256 internal immutable reporterMultiplier15;
    uint256 internal immutable reporterMultiplier16;
    uint256 internal immutable reporterMultiplier17;
    uint256 internal immutable reporterMultiplier18;
    uint256 internal immutable reporterMultiplier19;
    uint256 internal immutable reporterMultiplier20;
    uint256 internal immutable reporterMultiplier21;
    uint256 internal immutable reporterMultiplier22;
    uint256 internal immutable reporterMultiplier23;
    uint256 internal immutable reporterMultiplier24;

    /**
     * @notice Construct an immutable store of configs into the contract data
     * @param configs The configs for the supported assets
     */
    constructor(TokenConfig[] memory configs) public {
        require(configs.length <= maxTokens, "too many configs");
        numTokens = configs.length;

        dToken00 = get(configs, 0).dToken;
        dToken01 = get(configs, 1).dToken;
        dToken02 = get(configs, 2).dToken;
        dToken03 = get(configs, 3).dToken;
        dToken04 = get(configs, 4).dToken;
        dToken05 = get(configs, 5).dToken;
        dToken06 = get(configs, 6).dToken;
        dToken07 = get(configs, 7).dToken;
        dToken08 = get(configs, 8).dToken;
        dToken09 = get(configs, 9).dToken;
        dToken10 = get(configs, 10).dToken;
        dToken11 = get(configs, 11).dToken;
        dToken12 = get(configs, 12).dToken;
        dToken13 = get(configs, 13).dToken;
        dToken14 = get(configs, 14).dToken;
        dToken15 = get(configs, 15).dToken;
        dToken16 = get(configs, 16).dToken;
        dToken17 = get(configs, 17).dToken;
        dToken18 = get(configs, 18).dToken;
        dToken19 = get(configs, 19).dToken;
        dToken20 = get(configs, 20).dToken;
        dToken21 = get(configs, 21).dToken;
        dToken22 = get(configs, 22).dToken;
        dToken23 = get(configs, 23).dToken;
        dToken24 = get(configs, 24).dToken;

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
        underlying20 = get(configs, 20).underlying;
        underlying21 = get(configs, 21).underlying;
        underlying22 = get(configs, 22).underlying;
        underlying23 = get(configs, 23).underlying;
        underlying24 = get(configs, 24).underlying;

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
        symbolHash20 = get(configs, 20).symbolHash;
        symbolHash21 = get(configs, 21).symbolHash;
        symbolHash22 = get(configs, 22).symbolHash;
        symbolHash23 = get(configs, 23).symbolHash;
        symbolHash24 = get(configs, 24).symbolHash;

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
        baseUnit20 = get(configs, 20).baseUnit;
        baseUnit21 = get(configs, 21).baseUnit;
        baseUnit22 = get(configs, 22).baseUnit;
        baseUnit23 = get(configs, 23).baseUnit;
        baseUnit24 = get(configs, 24).baseUnit;

        chainlinkMarket00 = get(configs, 0).chainlinkMarket;
        chainlinkMarket01 = get(configs, 1).chainlinkMarket;
        chainlinkMarket02 = get(configs, 2).chainlinkMarket;
        chainlinkMarket03 = get(configs, 3).chainlinkMarket;
        chainlinkMarket04 = get(configs, 4).chainlinkMarket;
        chainlinkMarket05 = get(configs, 5).chainlinkMarket;
        chainlinkMarket06 = get(configs, 6).chainlinkMarket;
        chainlinkMarket07 = get(configs, 7).chainlinkMarket;
        chainlinkMarket08 = get(configs, 8).chainlinkMarket;
        chainlinkMarket09 = get(configs, 9).chainlinkMarket;
        chainlinkMarket10 = get(configs, 10).chainlinkMarket;
        chainlinkMarket11 = get(configs, 11).chainlinkMarket;
        chainlinkMarket12 = get(configs, 12).chainlinkMarket;
        chainlinkMarket13 = get(configs, 13).chainlinkMarket;
        chainlinkMarket14 = get(configs, 14).chainlinkMarket;
        chainlinkMarket15 = get(configs, 15).chainlinkMarket;
        chainlinkMarket16 = get(configs, 16).chainlinkMarket;
        chainlinkMarket17 = get(configs, 17).chainlinkMarket;
        chainlinkMarket18 = get(configs, 18).chainlinkMarket;
        chainlinkMarket19 = get(configs, 19).chainlinkMarket;
        chainlinkMarket20 = get(configs, 20).chainlinkMarket;
        chainlinkMarket21 = get(configs, 21).chainlinkMarket;
        chainlinkMarket22 = get(configs, 22).chainlinkMarket;
        chainlinkMarket23 = get(configs, 23).chainlinkMarket;
        chainlinkMarket24 = get(configs, 24).chainlinkMarket;

        reporterMultiplier00 = get(configs, 0).reporterMultiplier;
        reporterMultiplier01 = get(configs, 1).reporterMultiplier;
        reporterMultiplier02 = get(configs, 2).reporterMultiplier;
        reporterMultiplier03 = get(configs, 3).reporterMultiplier;
        reporterMultiplier04 = get(configs, 4).reporterMultiplier;
        reporterMultiplier05 = get(configs, 5).reporterMultiplier;
        reporterMultiplier06 = get(configs, 6).reporterMultiplier;
        reporterMultiplier07 = get(configs, 7).reporterMultiplier;
        reporterMultiplier08 = get(configs, 8).reporterMultiplier;
        reporterMultiplier09 = get(configs, 9).reporterMultiplier;
        reporterMultiplier10 = get(configs, 10).reporterMultiplier;
        reporterMultiplier11 = get(configs, 11).reporterMultiplier;
        reporterMultiplier12 = get(configs, 12).reporterMultiplier;
        reporterMultiplier13 = get(configs, 13).reporterMultiplier;
        reporterMultiplier14 = get(configs, 14).reporterMultiplier;
        reporterMultiplier15 = get(configs, 15).reporterMultiplier;
        reporterMultiplier16 = get(configs, 16).reporterMultiplier;
        reporterMultiplier17 = get(configs, 17).reporterMultiplier;
        reporterMultiplier18 = get(configs, 18).reporterMultiplier;
        reporterMultiplier19 = get(configs, 19).reporterMultiplier;
        reporterMultiplier20 = get(configs, 20).reporterMultiplier;
        reporterMultiplier21 = get(configs, 21).reporterMultiplier;
        reporterMultiplier22 = get(configs, 22).reporterMultiplier;
        reporterMultiplier23 = get(configs, 23).reporterMultiplier;
        reporterMultiplier24 = get(configs, 24).reporterMultiplier;

    }

    function get(TokenConfig[] memory configs, uint i) internal pure returns (TokenConfig memory) {
        if (i < configs.length)
            return configs[i];
        return TokenConfig({
        dToken : address(0),
        underlying : address(0),
        symbolHash : bytes32(0),
        baseUnit : uint256(0),
        chainlinkMarket : address(0),
        reporterMultiplier: uint256(0)
        });
    }

    function getDTokenIndex(address dToken) internal view returns (uint) {
        if (dToken == dToken00) return 0;
        if (dToken == dToken01) return 1;
        if (dToken == dToken02) return 2;
        if (dToken == dToken03) return 3;
        if (dToken == dToken04) return 4;
        if (dToken == dToken05) return 5;
        if (dToken == dToken06) return 6;
        if (dToken == dToken07) return 7;
        if (dToken == dToken08) return 8;
        if (dToken == dToken09) return 9;
        if (dToken == dToken10) return 10;
        if (dToken == dToken11) return 11;
        if (dToken == dToken12) return 12;
        if (dToken == dToken13) return 13;
        if (dToken == dToken14) return 14;
        if (dToken == dToken15) return 15;
        if (dToken == dToken16) return 16;
        if (dToken == dToken17) return 17;
        if (dToken == dToken18) return 18;
        if (dToken == dToken19) return 19;
        if (dToken == dToken20) return 20;
        if (dToken == dToken21) return 21;
        if (dToken == dToken22) return 22;
        if (dToken == dToken23) return 23;
        if (dToken == dToken24) return 24;

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
        if (underlying == underlying20) return 20;
        if (underlying == underlying21) return 21;
        if (underlying == underlying22) return 22;
        if (underlying == underlying23) return 23;
        if (underlying == underlying24) return 24;

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
        if (symbolHash == symbolHash20) return 20;
        if (symbolHash == symbolHash21) return 21;
        if (symbolHash == symbolHash22) return 22;
        if (symbolHash == symbolHash23) return 23;
        if (symbolHash == symbolHash24) return 24;

        return uint(- 1);
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < numTokens, "token config not found");

        if (i == 0) return TokenConfig({dToken : dToken00, underlying : underlying00, symbolHash : symbolHash00, baseUnit : baseUnit00, chainlinkMarket : chainlinkMarket00, reporterMultiplier: reporterMultiplier00});
        if (i == 1) return TokenConfig({dToken : dToken01, underlying : underlying01, symbolHash : symbolHash01, baseUnit : baseUnit01, chainlinkMarket : chainlinkMarket01, reporterMultiplier: reporterMultiplier01});
        if (i == 2) return TokenConfig({dToken : dToken02, underlying : underlying02, symbolHash : symbolHash02, baseUnit : baseUnit02, chainlinkMarket : chainlinkMarket02, reporterMultiplier: reporterMultiplier02});
        if (i == 3) return TokenConfig({dToken : dToken03, underlying : underlying03, symbolHash : symbolHash03, baseUnit : baseUnit03, chainlinkMarket : chainlinkMarket03, reporterMultiplier: reporterMultiplier03});
        if (i == 4) return TokenConfig({dToken : dToken04, underlying : underlying04, symbolHash : symbolHash04, baseUnit : baseUnit04, chainlinkMarket : chainlinkMarket04, reporterMultiplier: reporterMultiplier04});
        if (i == 5) return TokenConfig({dToken : dToken05, underlying : underlying05, symbolHash : symbolHash05, baseUnit : baseUnit05, chainlinkMarket : chainlinkMarket05, reporterMultiplier: reporterMultiplier05});
        if (i == 6) return TokenConfig({dToken : dToken06, underlying : underlying06, symbolHash : symbolHash06, baseUnit : baseUnit06, chainlinkMarket : chainlinkMarket06, reporterMultiplier: reporterMultiplier06});
        if (i == 7) return TokenConfig({dToken : dToken07, underlying : underlying07, symbolHash : symbolHash07, baseUnit : baseUnit07, chainlinkMarket : chainlinkMarket07, reporterMultiplier: reporterMultiplier07});
        if (i == 8) return TokenConfig({dToken : dToken08, underlying : underlying08, symbolHash : symbolHash08, baseUnit : baseUnit08, chainlinkMarket : chainlinkMarket08, reporterMultiplier: reporterMultiplier08});
        if (i == 9) return TokenConfig({dToken : dToken09, underlying : underlying09, symbolHash : symbolHash09, baseUnit : baseUnit09, chainlinkMarket : chainlinkMarket09, reporterMultiplier: reporterMultiplier09});

        if (i == 10) return TokenConfig({dToken : dToken10, underlying : underlying10, symbolHash : symbolHash10, baseUnit : baseUnit10, chainlinkMarket : chainlinkMarket10, reporterMultiplier: reporterMultiplier10});
        if (i == 11) return TokenConfig({dToken : dToken11, underlying : underlying11, symbolHash : symbolHash11, baseUnit : baseUnit11, chainlinkMarket : chainlinkMarket11, reporterMultiplier: reporterMultiplier11});
        if (i == 12) return TokenConfig({dToken : dToken12, underlying : underlying12, symbolHash : symbolHash12, baseUnit : baseUnit12, chainlinkMarket : chainlinkMarket12, reporterMultiplier: reporterMultiplier12});
        if (i == 13) return TokenConfig({dToken : dToken13, underlying : underlying13, symbolHash : symbolHash13, baseUnit : baseUnit13, chainlinkMarket : chainlinkMarket13, reporterMultiplier: reporterMultiplier13});
        if (i == 14) return TokenConfig({dToken : dToken14, underlying : underlying14, symbolHash : symbolHash14, baseUnit : baseUnit14, chainlinkMarket : chainlinkMarket14, reporterMultiplier: reporterMultiplier14});
        if (i == 15) return TokenConfig({dToken : dToken15, underlying : underlying15, symbolHash : symbolHash15, baseUnit : baseUnit15, chainlinkMarket : chainlinkMarket15, reporterMultiplier: reporterMultiplier15});
        if (i == 16) return TokenConfig({dToken : dToken16, underlying : underlying16, symbolHash : symbolHash16, baseUnit : baseUnit16, chainlinkMarket : chainlinkMarket16, reporterMultiplier: reporterMultiplier16});
        if (i == 17) return TokenConfig({dToken : dToken17, underlying : underlying17, symbolHash : symbolHash17, baseUnit : baseUnit17, chainlinkMarket : chainlinkMarket17, reporterMultiplier: reporterMultiplier17});
        if (i == 18) return TokenConfig({dToken : dToken18, underlying : underlying18, symbolHash : symbolHash18, baseUnit : baseUnit18, chainlinkMarket : chainlinkMarket18, reporterMultiplier: reporterMultiplier18});
        if (i == 19) return TokenConfig({dToken : dToken19, underlying : underlying19, symbolHash : symbolHash19, baseUnit : baseUnit19, chainlinkMarket : chainlinkMarket19, reporterMultiplier: reporterMultiplier19});

        if (i == 20) return TokenConfig({dToken : dToken20, underlying : underlying20, symbolHash : symbolHash20, baseUnit : baseUnit20, chainlinkMarket : chainlinkMarket20, reporterMultiplier: reporterMultiplier20});
        if (i == 21) return TokenConfig({dToken : dToken21, underlying : underlying21, symbolHash : symbolHash21, baseUnit : baseUnit21, chainlinkMarket : chainlinkMarket21, reporterMultiplier: reporterMultiplier21});
        if (i == 22) return TokenConfig({dToken : dToken22, underlying : underlying22, symbolHash : symbolHash22, baseUnit : baseUnit22, chainlinkMarket : chainlinkMarket22, reporterMultiplier: reporterMultiplier22});
        if (i == 23) return TokenConfig({dToken : dToken23, underlying : underlying23, symbolHash : symbolHash23, baseUnit : baseUnit23, chainlinkMarket : chainlinkMarket23, reporterMultiplier: reporterMultiplier23});
        if (i == 24) return TokenConfig({dToken : dToken24, underlying : underlying24, symbolHash : symbolHash24, baseUnit : baseUnit24, chainlinkMarket : chainlinkMarket24, reporterMultiplier: reporterMultiplier24});
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    function getHashBySymbol(string memory symbol) public view returns (bytes32) {
        return keccak256(abi.encodePacked(symbol));
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
     * @notice Get the config for the dToken
     * @dev If a config for the dToken is not found, falls back to searching for the underlying.
     * @param dToken The address of the dToken of the config to get
     * @return The config object
     */
    function getTokenConfigByDToken(address dToken) public view returns (TokenConfig memory) {
        uint index = getDTokenIndex(dToken);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(DErc20(dToken).underlying());
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

    struct PriceData {
        uint248 price;
        bool failoverActive;
    }

contract ChainlinkAnchoredView is ChainlinkConfig, Ownable {

    /// @notice Official prices by symbol hash
    mapping(bytes32 => PriceData) public prices;


    /// @notice The event emitted when failover is activated
    event FailoverActivated(bytes32 indexed symbolHash);

    /// @notice The event emitted when failover is deactivated
    event FailoverDeactivated(bytes32 indexed symbolHash);

    FlagsInterface internal chainlinkFlags;
    // Identifier of the Sequencer offline flag on the Flags contract
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));

    /**
     * @notice Construct a chainlink anchored view for a set of token configurations
     * @dev Note that to avoid immature TWAPs, the system must run for at least a single anchorPeriod before using.
     *      NOTE: Reported prices are set to 1 during construction. We assume that this contract will not be voted in by
     *      governance until prices have been updated through `validate` for each TokenConfig.
     * @param _chainlinkFlags The minimum amount of time required for the old chainlink price accumulator to be replaced
     * @param configs The static token configurations which define what prices are supported and how
     */
    constructor(
        address _chainlinkFlags,
        TokenConfig[] memory configs) ChainlinkConfig(configs) public {
        chainlinkFlags = FlagsInterface(_chainlinkFlags);

        for (uint i = 0; i < configs.length; i++) {
            TokenConfig memory config = configs[i];
            require(config.baseUnit > 0, "baseUnit must be greater than zero");
            address chainlinkMarket = config.chainlinkMarket;
            require(chainlinkMarket != address(0), "reported prices must have an anchor");
            bytes32 symbolHash = config.symbolHash;
            prices[symbolHash].price = 1;
            prices[symbolHash].failoverActive = true;
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
        bool isRaised = chainlinkFlags.getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
        if (isRaised) {
            // If flag is raised we shouldn't perform any critical operations
            revert("Chainlink feeds are not being updated");
        }
        (
        uint80 roundID,
        int currentAnswer,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = AggregatorV3Interface(config.chainlinkMarket).latestRoundData();
        uint256 anchorPrice = convertReportedPrice(config, currentAnswer);

        PriceData memory priceData = prices[config.symbolHash];
        require(priceData.failoverActive, "Failover must be active");
        require(anchorPrice < 2 ** 248, "Anchor price too large");
        return uint248(anchorPrice);
    }

    /**
     * @notice Get the underlying price of a dToken
     * @dev Implements the PriceOracle interface for Dank v2.
     * @param dToken The dToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given dToken address
     */
    function getUnderlyingPrice(address dToken) external view returns (uint) {
        TokenConfig memory config = getTokenConfigByDToken(dToken);
        // Danktroller needs prices in the format: ${raw price} * 1e36 / baseUnit
        // The baseUnit of an asset is the amount of the smallest denomination of that asset per whole.
        // For example, the baseUnit of ETH is 1e18.
        // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6)/baseUnit
        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    /**
     * @notice Convert the reported price to the 6 decimal format that this view requires
     * @param config TokenConfig
     * @param reportedPrice  dd
     * @return convertedPrice uint256
     */
    function convertReportedPrice(TokenConfig memory config, int256 reportedPrice) internal pure returns (uint256) {
        require(reportedPrice >= 0, "Reported price cannot be negative");
        uint256 unsignedPrice = uint256(reportedPrice);

        uint256 convertedPrice;
        if (config.reporterMultiplier > 10 ** 6) {
            convertedPrice = unsignedPrice / (config.reporterMultiplier / 10 ** 6);
        } else if (config.reporterMultiplier < 10 ** 6) {
            convertedPrice = unsignedPrice * (10 ** 6 / config.reporterMultiplier);
        }

        return convertedPrice;
    }

    /**
     * @notice Activate failover, and fall back to using failover directly.
     * @dev Only the owner can call this function
     */
    function activateFailover(bytes32 symbolHash) external onlyOwner() {
        require(!prices[symbolHash].failoverActive, "Already activated");
        prices[symbolHash].failoverActive = true;
        emit FailoverActivated(symbolHash);
    }

    /**
     * @notice Deactivate a previously activated failover
     * @dev Only the owner can call this function
     */
    function deactivateFailover(bytes32 symbolHash) external onlyOwner() {
        require(prices[symbolHash].failoverActive, "Already deactivated");
        prices[symbolHash].failoverActive = false;
        emit FailoverDeactivated(symbolHash);
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}