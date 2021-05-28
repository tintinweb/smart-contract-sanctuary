/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.8.4;

abstract contract AdminOperatorAccess {
    address private admin;
    address private operator;

    event NewAdmin(address indexed previousAdmin, address indexed newAdmin);
    event NewOperator(address indexed previousOperator, address indexed newOperator);

    constructor () {
        address msgSender = msg.sender;
        admin = msgSender;
        emit NewAdmin(address(0), msgSender);
    }

    function getAdmin() public view virtual returns (address) {
        return admin;
    }

    function getOperator() public view virtual returns (address) {
        return operator;
    }

    modifier onlyAdmin() {
        require(getAdmin() == msg.sender, "AdminOperatorAccess: caller is not the admin");
        _;
    }

    modifier onlyOperator() {
        require(getOperator() == msg.sender, "AdminOperatorAccess: caller is not the operator");
        _;
    }
    
    function setAdmin(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "AdminOperatorAccess: new admin is the zero address");
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setOperator(address newOperator) public virtual onlyAdmin {
        require(newOperator != address(0), "AdminOperatorAccess: new operator is the zero address");
        emit NewOperator(operator, newOperator);
        operator = newOperator;
    }
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokensBridge is AdminOperatorAccess {
    IERC20 public token;

    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount) public onlyOperator returns (bool success) {
        require(token.allowance(_sender, address(this)) >= _amount, "Amount check failed");
        require(token.transferFrom(_sender, address(this), _amount), "transferFrom() failure. Make sure that your balance is not lower than the allowance you set");
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) public onlyOperator returns (bool success) {
        require(token.transfer(_sender, _amount), "transfer() failure. Contact contract owner");
        emit Dispense(_sender, _amount);
        return true;
    }

    constructor(IERC20 _token) {
        token = _token;
    }
}