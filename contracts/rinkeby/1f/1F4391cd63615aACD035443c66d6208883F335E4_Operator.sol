// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

contract Operator {
    address public superAdmin;

    event OperatorAdded(address _operator, bool _status);
    event OperatorUpdated(address _operator, bool _status);
    
    constructor() {
        superAdmin = msg.sender;
    }
    
    modifier onlySuperAdmin {
        require(superAdmin == msg.sender, "Unauthorized Access");
        _;
    }

    struct Operators {
        address _operator;
        bool _isActive;
    }
    
    mapping (address => Operators) public operators;
    
    function addOperator(address _address, bool _status) external onlySuperAdmin {
        require(_address != address(0), "Operator can't be the zero address");
        operators[_address]._operator = _address;
        operators[_address]._isActive = _status;
        emit OperatorAdded(_address, _status);
    }
    
    function getOperator(address _address) view external returns (address, bool) {
        return(operators[_address]._operator, operators[_address]._isActive);
    }

    function isOperator(address _address) external view returns(bool _status) {
        return(operators[_address]._isActive);
    }
    
    function updateOperator(address _address, bool _status) external onlySuperAdmin {
        require(_address != address(0), "Operator can't be the zero address");
        require(operators[_address]._isActive != _status);
        operators[_address]._isActive = _status;
        emit OperatorUpdated(_address, _status);
    }
    
    function governance() external view returns(address){
        return superAdmin;
    }    
}