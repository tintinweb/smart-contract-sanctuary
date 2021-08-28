/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract UpgradeProxyImplementation {
    address public operator;
    string public version; // Current version of the contract
    address public childAddr;
    bool public isChildEnabled;

    // Operator events
    event TransferOwnership(address newOperator);
    event SetChildStatus(bool enable);
    event UpgradeChild(address newChild);

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

        emit TransferOwnership(_newOperator);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize(address _operator) external {
        require(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("")), "UserProxy: not upgrading from version zero");

        operator = _operator;
        emit TransferOwnership(_operator);

        // Upgrade version
        version = "1.2.3";
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/
    function setChildStatus(bool _enable) public onlyOperator {
        isChildEnabled = _enable;

        emit SetChildStatus(_enable);
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeChild(address _newChildAddr, bool _enable) external onlyOperator {
        childAddr = _newChildAddr;
        isChildEnabled = _enable;

        emit UpgradeChild(_newChildAddr);
        emit SetChildStatus(_enable);
    }
}