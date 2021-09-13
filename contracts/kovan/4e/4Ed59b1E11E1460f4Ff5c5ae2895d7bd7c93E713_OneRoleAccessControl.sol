/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract OneRoleAccessControl {
    // Below are the variables which consume storage slots.
    address public moreSecuredOperator;
    address public lessSecuredOperator;
    address public errandOperator;
    address public sentinel;
    uint256 public importantParam;
    uint256 public errandParam;
    address public importantDepedency;

    // Operator events
    event TransferMoreSecuredOperator(address newMoreSecuredOperator);
    event TransferLessSecuredOperator(address newLessSecuredOperator);
    event TransferErrandOperator(address newErrandOperator);
    event SetNewSentinel(address _newSentinel);
    event Paused();
    event Unpaused();
    event UpgradeImportantDependency(address newImportantDependency);
    event SetImportantParam(uint256 newImportantParam);
    event SetErrandParam(uint256 newErrandParam);
    event AllowTransferToFixedRecipeint(address tokenAddr);
    event DisallowTransferToFixedRecipeint(address tokenAddr);

    receive() external payable {}

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyMoreSecuredOperator() {
        require(moreSecuredOperator == msg.sender, "OneRoleAccessControl: not the moreSecuredOperator");
        _;
    }

    modifier onlyLessSecuredOperator() {
        require(lessSecuredOperator == msg.sender, "OneRoleAccessControl: not the lessSecuredOperator");
        _;
    }

    modifier onlyErrandOperator() {
        require(errandOperator == msg.sender, "OneRoleAccessControl: not the errandOperator");
        _;
    }

    modifier onlySentinel() {
        require(sentinel == msg.sender, "OneRoleAccessControl: not the sentinel");
        _;
    }

    function transferMoreSecuredOperator(address _newMoreSecuredOperator) external onlyMoreSecuredOperator {
        require(_newMoreSecuredOperator != address(0), "OneRoleAccessControl: moreSecuredOperator can not be zero address");

        emit TransferMoreSecuredOperator(_newMoreSecuredOperator);
    }

    function transferLessSecuredOperator(address _newLessSecuredOperator) external onlyMoreSecuredOperator {
        require(_newLessSecuredOperator != address(0), "OneRoleAccessControl: lessSecuredOperator can not be zero address");

        emit TransferLessSecuredOperator(_newLessSecuredOperator);
    }

    function transferErrandOperator(address _newErrandOperator) external onlyLessSecuredOperator {
        require(_newErrandOperator != address(0), "OneRoleAccessControl: errandOperator can not be zero address");

        emit TransferErrandOperator(_newErrandOperator);
    }

    function setNewSentinel(address _newSentinel) external onlyMoreSecuredOperator {
        require(_newSentinel != address(0), "OneRoleAccessControl: sentinel can not be zero address");
        sentinel = _newSentinel;

        emit SetNewSentinel(_newSentinel);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _moreSecuredOperator,
        address _lessSecuredOperator,
        address _errandOperator,
        address _sentinel
    ) {
        moreSecuredOperator = _moreSecuredOperator;
        lessSecuredOperator = _lessSecuredOperator;
        errandOperator = _errandOperator;
        sentinel = _sentinel;
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

    function upgradeImportantDependency(address _newImportantDependency) external onlyMoreSecuredOperator {
        require(_newImportantDependency != address(0), "OneRoleAccessControl: importantDepedency can not be zero address");
        importantDepedency = _newImportantDependency;

        emit UpgradeImportantDependency(_newImportantDependency);
    }

    function setImportantParam(uint256 _importantParam) external onlyLessSecuredOperator {
        require(_importantParam < 100, "OneRoleAccessControl: _importantParam reach upper bound");
        importantParam = _importantParam;

        emit SetImportantParam(_importantParam);
    }

    function setErrandParam(uint256 _errandParam) external onlyErrandOperator {
        errandParam = _errandParam;

        emit SetErrandParam(_errandParam);
    }

    function setAllowance(address[] calldata _tokenList) external onlyLessSecuredOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            emit AllowTransferToFixedRecipeint(_tokenList[i]);
        }
    }

    function closeAllowance(address[] calldata _tokenList) external onlyLessSecuredOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            emit DisallowTransferToFixedRecipeint(_tokenList[i]);
        }
    }
}