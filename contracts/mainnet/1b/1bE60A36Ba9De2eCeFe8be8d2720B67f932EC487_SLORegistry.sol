/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// File: contracts/SLORegistry.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

/**
 * @title SLORegistry
 * @dev SLORegistry is a contract for handling creation of service level
 * objectives and querying those service level objectives
 */
contract SLORegistry {
    enum SLOType {
        EqualTo,
        NotEqualTo,
        SmallerThan,
        SmallerOrEqualTo,
        GreaterThan,
        GreaterOrEqualTo
    }

    struct SLO {
        uint256 sloValue;
        SLOType sloType;
    }
    /**
     * @dev SLO Registered event
     * @param sla 1. -
     * @param sloValue 2. -
     * @param sloType 3. -
     */
    event SLORegistered(address indexed sla, uint256 sloValue, SLOType sloType);

    address private slaRegistry;
    mapping(address => SLO) public registeredSLO;

    modifier onlySLARegistry {
        require(
            msg.sender == slaRegistry,
            "Should only be called using the SLARegistry contract"
        );
        _;
    }

    function setSLARegistry() public {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            "SLARegistry address has already been set"
        );
        slaRegistry = msg.sender;
    }

    /**
     * @dev public function for creating service level objectives
     * @param _sloValue 1. -
     * @param _sloType 2. -
     * @param _slaAddress 3. -
     */
    function registerSLO(
        uint256 _sloValue,
        SLOType _sloType,
        address _slaAddress
    ) public onlySLARegistry {
        registeredSLO[_slaAddress] = SLO({
            sloValue: _sloValue,
            sloType: _sloType
        });
        emit SLORegistered(_slaAddress, _sloValue, _sloType);
    }

    /**
     * @dev external view function to check a value against the SLO
     * @param _value The SLI value to check against the SL
     * @return boolean with the SLO honored state
     */
    function isRespected(uint256 _value, address _slaAddress)
        public
        view
        returns (bool)
    {
        SLO memory slo = registeredSLO[_slaAddress];
        SLOType sloType = slo.sloType;
        uint256 sloValue = slo.sloValue;

        if (sloType == SLOType.EqualTo) {
            return _value == sloValue;
        }

        if (sloType == SLOType.NotEqualTo) {
            return _value != sloValue;
        }

        if (sloType == SLOType.SmallerThan) {
            return _value < sloValue;
        }

        if (sloType == SLOType.SmallerOrEqualTo) {
            return _value <= sloValue;
        }

        if (sloType == SLOType.GreaterThan) {
            return _value > sloValue;
        }

        if (sloType == SLOType.GreaterOrEqualTo) {
            return _value >= sloValue;
        }
        revert("isRespected wasn't executed properly");
    }
}