/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract OneRoleAccessControl {
    // Below are the variables which consume storage slots.
    address public operator;
    uint256 public someParam;
    address public importantDepedency;
    address public spender;

    // Operator events
    event TransferOwnership(address newOperator);
    event UpgradeImportantDependency(address newImportantDependency);
    event SetSomeParam(uint256 newParam);
    event AllowTransfer(address tokenAddr, address spender);
    event DisallowTransfer(address tokenAddr, address spender);

    receive() external payable {}

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "OneRoleAccessControl: not the operator");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "OneRoleAccessControl: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _operator,
        uint256 _someParam,
        address _importantDepedency
    ) {
        operator = _operator;
        someParam = _someParam;
        importantDepedency = _importantDepedency;
    }

    /************************************************************
     *           Management functions for Operator               *
     *************************************************************/
    /**
     * @dev set new ImportantDependency
     */
    function upgradeImportantDependency(address _newImportantDependency) external onlyOperator {
        require(_newImportantDependency != address(0), "OneRoleAccessControl: importantDepedency can not be zero address");
        importantDepedency = _newImportantDependency;

        emit UpgradeImportantDependency(_newImportantDependency);
    }

    function setSomeParam(uint256 _someParam) external onlyOperator {
        someParam = _someParam;

        emit SetSomeParam(_someParam);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) external onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            emit AllowTransfer(_tokenList[i], _spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) external onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            emit DisallowTransfer(_tokenList[i], _spender);
        }
    }
}