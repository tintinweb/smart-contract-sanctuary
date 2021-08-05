// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "./UserProxyStorage.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxy {
    // Below are the variables which consume storage slots.
    address public operator;
    string public version;  // Current version of the contract

    receive() external payable {}


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "UserProxy: not the operator");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "UserProxy: operator can not be zero address");
        operator = _newOperator;
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize(address _operator) external {
        require(_operator != address(0), "UserProxy: _operator should not be 0");
        require(
            keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("")),
            "UserProxy: not upgrading from default version"
        );

        // Set operator
        operator = _operator;
        // Upgrade version
        version = "5.0.0";
    }


    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function ammWrapperAddr() public view returns (address) {
        return AMMWrapperStorage.getStorage().ammWrapperAddr;
    }

    function isAMMEnabled() public view returns (bool) {
        return AMMWrapperStorage.getStorage().isEnabled;
    }

    function pmmAddr() public view returns (address) {
        return PMMStorage.getStorage().pmmAddr;
    }

    function isPMMEnabled() public view returns (bool) {
        return PMMStorage.getStorage().isEnabled;
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    function setAMMStatus(bool _enable) public onlyOperator {
        AMMWrapperStorage.getStorage().isEnabled = _enable;
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeAMMWrapper(address _newAMMWrapperAddr, bool _enable) external onlyOperator {
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
        AMMWrapperStorage.getStorage().isEnabled = _enable;
    }

    function setPMMStatus(bool _enable) public onlyOperator {
        PMMStorage.getStorage().isEnabled = _enable;
    }

    /**
     * @dev Update PMM contract address. Used only when ABI of PMM remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradePMM(address _newPMMAddr, bool _enable) external onlyOperator {
        PMMStorage.getStorage().pmmAddr = _newPMMAddr;
        PMMStorage.getStorage().isEnabled = _enable;
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    /**
     * @dev proxy the call to AMM
     */
    function toAMM(bytes calldata _payload) external payable {
        require(isAMMEnabled(), "UserProxy: AMM is disabled");

        (bool callSucceed,) = ammWrapperAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /**
     * @dev proxy the call to PMM
     */
    function toPMM(bytes calldata _payload) external payable {
        require(isPMMEnabled(), "UserProxy: PMM is disabled");

        (bool callSucceed,) = pmmAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}
