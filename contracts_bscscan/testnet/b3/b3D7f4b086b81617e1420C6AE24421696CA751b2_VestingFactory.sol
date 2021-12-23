// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Vesting.sol";

contract Strategic is Vesting {
    // TGE+60 day unlock 3%, lock 120 days, vest linearly over 30 months
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt + 5184000 + 7776000), // After fist claim + 90 days (claimed beginning of the each month)
            30, // lasting 30 months
            (_vestingStartAt + 5184000), // TGE + 60days
            3, // 3% for fist claim
            Frequently.MONTH
        )
    {}
}

/**
 * @dev TGE+30 day 5% unlock, lock 90 days, vest linearly over 12 months
 */
contract PrivateSale is Vesting {
    //uint256 private SECONDS_PER_75_DAYS = 6480000;
    //uint256 private SECONDS_PER_15_DAYS = 1296000;
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt + 2592000 + 5184000), // After fist claim + 60 days (claimed beginning of the each month)
            12, // lasting 12 months
            (_vestingStartAt + 2592000), // TGE + 30
            5,
            Frequently.MONTH
        )
    {}
}

/**
 * @dev TGE 20% unlock, lock 30 days, vest monthly over 06 months
 */
contract PublicSale is Vesting {
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            _vestingStartAt,
            6,
            _vestingStartAt,
            20,
            Frequently.MONTH
        )
    {}
}

/**
 * @dev Lock 12 months, vest linearly over 36 months
 */
contract Advisor is Vesting {
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt + 28944000), // Lock 335 days (claimed beginning of the each month)
            36, // lasting in 36 months
            0,
            0,
            Frequently.MONTH
        )
    {}
}

/**
 * @dev Lock 12 months, vest linearly over 36 months
 */
contract CoreTeam is Vesting {
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt + 28944000), // Lock 335 days (claimed beginning of the each month)
            36, // lasting in 36 months
            0,
            0,
            Frequently.MONTH
        )
    {}
}

/**
 * @dev Vest linearly over 48 months
 */
contract Development is Vesting {
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt - 2592000),
            48,
            0,
            0,
            Frequently.DAY
        )
    {}
}

/**
 * @dev VestingMonthlyFactory is the main and is the only contract should be deployed.
 * Notice: remember to config the Token address and approriate startAtTimeStamp
 */
contract VestingFactory {
    // put the token address here
    // This should be included in the contract for transparency
    address public SEAR_TOKEN_ADDRESS =
        0x56691ed83d0BEe29CEe1b41366aae05a177c68a8;

    // put the startAtTimeStamp here
    // To test all contracts, change this timestamp to time in the past.
    uint256 public startAtTimeStamp = 1640232726;

    // address to track other information
    address public owner;
    address public privateSale;
    address public strategic;
    address public publicSale;
    address public advisor;
    address public coreTeam;
    address public development;

    constructor() {
        owner = msg.sender;

        Strategic _strategic = new Strategic(
            SEAR_TOKEN_ADDRESS,
            owner,
            startAtTimeStamp
        );

        PrivateSale _privateSale = new PrivateSale(
            SEAR_TOKEN_ADDRESS,
            owner,
            startAtTimeStamp
        );

        PublicSale _publicSale = new PublicSale(
            SEAR_TOKEN_ADDRESS,
            owner,
            startAtTimeStamp
        );

        Advisor _advisor = new Advisor(
            SEAR_TOKEN_ADDRESS,
            owner,
            startAtTimeStamp
        );

        CoreTeam _coreTeam = new CoreTeam(
            SEAR_TOKEN_ADDRESS,
            owner,
            startAtTimeStamp
        );

        Development _development = new Development(
            SEAR_TOKEN_ADDRESS,
            owner,
            startAtTimeStamp
        );

        strategic = address(_strategic);
        privateSale = address(_privateSale);
        publicSale = address(_publicSale);
        advisor = address(_advisor);
        coreTeam = address(_coreTeam);
        development = address(_development);
    }
}