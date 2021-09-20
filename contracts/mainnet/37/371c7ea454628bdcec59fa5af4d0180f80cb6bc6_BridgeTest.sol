/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function setMinter(address _addr) external;
}

contract BridgeOperatable {
    address public owner;
    address public operator1;
    address public operator2;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Operator1Transferred(address indexed _from, address indexed _to);
    event Operator2Transferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
        operator1 = msg.sender;
        operator2 = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'onlyOwner: insufficient privilege');
        _;
    }

    modifier onlyOperator1 {
        require(msg.sender == operator1, 'onlyOperator1: insufficient privilege');
        _;
    }

    modifier onlyOperator2 {
        require(msg.sender == operator2, 'onlyOperator2: insufficient privilege');
        _;
    }

    function transferOwner(address _owner) public onlyOwner {
        emit Operator1Transferred(owner, _owner);
        owner = _owner;
    }

    function transferOperator1(address _operator1) public onlyOwner {
        emit Operator1Transferred(operator1, _operator1);
        operator1 = _operator1;
    }

    function transferOperator2(address _operator2) public onlyOwner {
        emit Operator2Transferred(operator2, _operator2);
        operator2 = _operator2;
    }
}

contract BridgeTest is BridgeOperatable {
    mapping(address => address payable) public treasury; 

    receive() external payable {
        // Do nothing
    }

    function setTreasury(address _token, address payable _treasury) external onlyOwner returns (bool) {
        treasury[_token] = _treasury;
        return true;
    }

    function withdraw(address _token, uint256 _amount) external onlyOperator1 returns (bool) {
        if(_token == address(0)) {
            // Native token
            require(address(this).balance >= _amount, 'insufficient balance');
            treasury[_token].transfer(_amount);
        } else {
            // ERC20 token
            IERC20 token = IERC20(_token);
            require(token.balanceOf(address(this)) >= _amount, 'insufficient balance');
            token.transfer(treasury[_token], _amount);
        }
        return true;
    }

    function withdraw2(address _token, uint256 _amount) external returns (bool) {
        if(_token == address(0)) {
            // Native token
            require(address(this).balance >= _amount, 'insufficient balance');
            treasury[_token].transfer(_amount);
        } else {
            // ERC20 token
            IERC20 token = IERC20(_token);
            require(token.balanceOf(address(this)) >= _amount, 'insufficient balance');
            token.transfer(treasury[_token], _amount);
        }
        return true;
    }

    function withdraw3(address _token, uint256 _amount) external onlyOperator1 returns (bool) {
        require(address(this).balance >= _amount, 'insufficient balance');
        treasury[_token].transfer(_amount);

        return true;
    }

    function withdraw4(address _token, uint256 _amount) external returns (bool) {
        require(address(this).balance >= _amount, 'insufficient balance');
        treasury[_token].transfer(_amount);

        return true;
    }

    function withdraw5(address _token, uint256 _amount) external onlyOperator1 returns (bool) {
        treasury[_token].transfer(_amount);

        return true;
    }

    function withdraw6(address _token, uint256 _amount) external returns (bool) {
        treasury[_token].transfer(_amount);

        return true;
    }

    function withdraw7(address payable _to, uint256 _amount) external returns (bool) {
        _to.transfer(_amount);

        return true;
    }
}