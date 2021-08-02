// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./INEFIReferral.sol";
import "./Address.sol";

contract NEFIReferral is INEFIReferral, Ownable {
    uint8 private limitPercentList;
    using Address for address;

    uint32[] private _percentLevelMulti = [7000, 1000, 1000, 500, 500];

    mapping(address => bool) existing;

    struct ReferralConfig {
        address referrer;
        bool isMultiLevel;
    }

    mapping(address => ReferralConfig) referrersDB;

    constructor() {}

    function register(address referrer, address referree) public onlyOwner {
        require(
            referrer != address(0) &&
                referree != address(0) &&
                !referrer.isContract() &&
                !referree.isContract() &&
                referrer != referree,
            "NEFIReferral: invalid referrer or referree"
        );
        require(!existing[referree], "NEFIReferral: exist referral path");
        existing[referree] = true;

        referrersDB[referree] = ReferralConfig(referrer, false);
    }

    function updateShareLevel(bool isMultiLevel) public {
        require(existing[msg.sender], "NEFIReferral: referral path not found");
        referrersDB[msg.sender].isMultiLevel = isMultiLevel;
    }

    function hasReferralPath(address sender)
        external
        view
        override
        returns (bool)
    {
        return existing[sender];
    }

    function referrerPath(address sender)
        external
        view
        override
        returns (address[] memory, uint32[] memory)
    {
        require(existing[sender], "NEFIReferral: referral path not found");
        ReferralConfig memory currentReferrerConfig = referrersDB[sender];

        address[] memory _referrerPath = new address[](5);
        uint32[] memory _percentPath = new uint32[](5);

        address curReferrer = currentReferrerConfig.referrer;
        bool isDirectRef = true;

        uint256 totalPayout = 0;

        for (uint256 i = 0; i < _percentLevelMulti.length; i++) {
            currentReferrerConfig = referrersDB[curReferrer];

            if (currentReferrerConfig.referrer == address(0)) {
                _referrerPath[i] = curReferrer;
                _percentPath[i] = _percentLevelMulti[i];
                totalPayout = totalPayout + uint256(_percentLevelMulti[i]);
                curReferrer = currentReferrerConfig.referrer;
                if (curReferrer == address(0)) {
                    break;
                }
                continue;
            }

            if (currentReferrerConfig.isMultiLevel == false) {
                if (isDirectRef) {
                    _referrerPath[i] = curReferrer;
                    _percentPath[i] = 10000;
                    totalPayout = totalPayout + 10000;
                    break;
                }
                curReferrer = currentReferrerConfig.referrer;
                continue;
            }

            isDirectRef = false;

            _referrerPath[i] = curReferrer;
            _percentPath[i] = _percentLevelMulti[i];
            totalPayout = totalPayout + uint256(_percentLevelMulti[i]);
            curReferrer = currentReferrerConfig.referrer;
        }

        if (totalPayout != 10000) {
            _percentPath[0] = uint32(_percentPath[0] + (10000 - totalPayout));
        }
        return (_referrerPath, _percentPath);
    }

    function getSum(uint32[] memory percentLevels)
        internal
        pure
        returns (uint32)
    {
        uint256 i;
        uint32 sum = 0;

        for (i = 0; i < percentLevels.length; i++) sum = sum + percentLevels[i];
        return sum;
    }

    function updatePercentLevelMulti(uint32[] calldata _newPercentLevelMulti)
        public
        onlyOwner
    {
        require(
            getSum(_newPercentLevelMulti) == 10000,
            "NEFIReferral: invalid total percent level"
        );
        _percentLevelMulti = _newPercentLevelMulti;
    }
}