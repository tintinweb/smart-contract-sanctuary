// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Strategic.sol";
import "./PrivateSale.sol";
import "./PublicSale.sol";
import "./Advisor.sol";
import "./CoreTeam.sol";
import "./Development.sol";
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