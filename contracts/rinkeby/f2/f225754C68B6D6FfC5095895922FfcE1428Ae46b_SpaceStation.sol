/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.7.6;



// File: SpaceStation.sol

//pragma experimental "ABIEncoderV2";

//import {Address} from "../../zeppelin-solidity/contracts/utils/Address.sol";
//import {Ownable} from "../../zeppelin-solidity/contracts/access/Ownable.sol";
//import {SafeMath} from "../../zeppelin-solidity/contracts/math/SafeMath.sol";
//import {Pausable} from "../../zeppelin-solidity/contracts/utils/Pausable.sol";
//import {IERC20} from "../../zeppelin-solidity/contracts/token/ERC20/IERC20.sol";

//import {ISpaceStation} from "../../interfaces/ISpaceStation.sol";


/**
 * @title SpaceStation
 * @author Galaxy Protocol
 *
 * Campaign contract that allows privileged DAOs to initiate campaigns for members to claim StarNFTs.
 */
contract SpaceStation {
//    using SafeMath for uint256;
//    using Address for address;

    /* ============ Constants ============ */
    /* ============ Events ============ */
    /* ============ Modifiers ============ */

    /* ============ Structs ============ */

    struct CampaignStakeConfig {
        address erc20;                  // Address of token being staked //TODO: or use address?
        uint256 minStakeAmount;        // Minimum amount of token to stake required, included
        uint256 maxStakeAmount;        // Maximum amount of token to stake required, included
        uint256 unlockBlock;           // Time when token lock-up period is met
        bool burnRequired;             // Require NFT burnt if staked out
        bool isEarlyStakeOutAllowed;   // Whether early stake out is allowed or not
        uint256 earlyStakeOutFine;     // If early stake out is allowed, the applied penalty // TODO: nullable
    }

    struct CampaignFeeConfig {
        address erc20;                  // Address of token asset required by DAO
        uint256 daoFee;                // Amount of token required by DAO
        uint256 platformFee;           // Amount of fee per network
    }

    /* ============ State Variables ============ */

    // Mapping that stores all stake requirement for a given activated campaign.
    mapping(uint256 => CampaignStakeConfig) public campaignStakeConfigs;

    // Mapping that stores all fee requirements per Operation for a given activated campaign.
    // If no fee is required at all, instead of set Operation(DEFAULT) to all zero values, Operation(*) should not exist.
//    mapping(uint256 => mapping(Operation => CampaignFeeConfig)) private campaignFeeConfigs;

    /* ============ Constructor ============ */

//    constructor() public {}

    /* ============ External Functions ============ */

//    function activateCampaign(uint256 _cid, Operation[] memory _op, uint256[] memory _platformFee, uint256[] memory _daoFee, address[] memory _daoErc20) external override {
//
//    }
//
//    function expireCampaign(uint256 _cid) external override {
//
//    }
//
//    function activateStakeCampaign(uint256 _cid, address _erc20, uint256 _minStakeAmount, uint256 _maxStakeAmount, uint256 _unlockBlock, bool _burnRequired, bool _isEarlyStakeOutAllowed, uint256 _earlyStakeOutFine, Operation[] memory _op, uint256[] memory _platformFee, uint256[] memory _daoFee, address[] memory _daoErc20) external override {
//
//    }
//
//    // FIXME: is pausable enough?
//    function haltCampaign(uint256 _cid) external override {
//
//    }
    /* ============ External Getter Functions ============ */
    /* ============ Internal Functions ============ */
}