/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract UpgradeProxyImplementation {
    address public moreSecuredOperator;
    address public lessSecuredOperator;
    address public errandOperator;
    address public sentinel;
    string public version; // Current version of the contract
    address public childAddr;
    bool public isChildEnabled;

    // Operator events
    event TransferMoreSecuredOperator(address newMoreSecuredOperator);
    event TransferLessSecuredOperator(address newLessSecuredOperator);
    event TransferErrandOperator(address newErrandOperator);
    event SetNewSentinel(address _newSentinel);
    event Paused();
    event Unpaused();
    event SetChildStatus(bool enable);
    event UpgradeChild(address newChild);

    receive() external payable {}

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyMoreSecuredOperator() {
        require(moreSecuredOperator == msg.sender, "UserProxy: not the moreSecuredOperator");
        _;
    }

    modifier onlyLessSecuredOperator() {
        require(lessSecuredOperator == msg.sender, "UserProxy: not the lessSecuredOperator");
        _;
    }

    modifier onlyErrandOperator() {
        require(errandOperator == msg.sender, "UserProxy: not the errandOperator");
        _;
    }

    modifier onlySentinel() {
        require(sentinel == msg.sender, "UserProxy: not the sentinel");
        _;
    }

    function transferMoreSecuredOperator(address _newMoreSecuredOperator) external onlyMoreSecuredOperator {
        require(_newMoreSecuredOperator != address(0), "UserProxy: moreSecuredOperator can not be zero address");

        emit TransferMoreSecuredOperator(_newMoreSecuredOperator);
    }

    function transferLessSecuredOperator(address _newLessSecuredOperator) external onlyMoreSecuredOperator {
        require(_newLessSecuredOperator != address(0), "UserProxy: lessSecuredOperator can not be zero address");

        emit TransferLessSecuredOperator(_newLessSecuredOperator);
    }

    function transferErrandOperator(address _newErrandOperator) external onlyLessSecuredOperator {
        require(_newErrandOperator != address(0), "UserProxy: errandOperator can not be zero address");

        emit TransferErrandOperator(_newErrandOperator);
    }

    function setNewSentinel(address _newSentinel) external onlyMoreSecuredOperator {
        require(_newSentinel != address(0), "UserProxy: sentinel can not be zero address");

        emit SetNewSentinel(_newSentinel);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize(
        address _moreSecuredOperator,
        address _lessSecuredOperator,
        address _errandOperator,
        address _sentinel
    ) external {
        require(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("")), "UserProxy: not upgrading from version zero");

        moreSecuredOperator = _moreSecuredOperator;
        lessSecuredOperator = _lessSecuredOperator;
        errandOperator = _errandOperator;
        sentinel = _sentinel;

        // Upgrade version
        version = "1.2.3";
    }

    /************************************************************
     *           Management functions for Operators              *
     *************************************************************/
    function pause() external onlySentinel {
        emit Paused();
    }

    function unpause() external onlyMoreSecuredOperator {
        emit Unpaused();
    }

    function setChildStatus(bool _enable) public onlyLessSecuredOperator {
        isChildEnabled = _enable;

        emit SetChildStatus(_enable);
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeChild(address _newChildAddr, bool _enable) external onlyMoreSecuredOperator {
        childAddr = _newChildAddr;
        isChildEnabled = _enable;

        emit UpgradeChild(_newChildAddr);
        emit SetChildStatus(_enable);
    }
}