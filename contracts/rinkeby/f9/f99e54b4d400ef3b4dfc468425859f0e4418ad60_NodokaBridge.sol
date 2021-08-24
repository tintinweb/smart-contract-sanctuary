/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
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

contract NodokaBridge is BridgeOperatable {
    mapping(address => Token) public tokens;
    mapping(address => Token) public pairs;
    mapping(address => address payable) public treasury; 

    struct Token {
        bool active;
        address tokenAddress;
        bool isERC20;  // false: native, true: ERC20
        bool mintable; // false: unlock, true: mint
        bool burnable; // false: lock,   true: burn
        uint256 minAmount;
        uint256 maxAmount;
    }
    
    event Bridge(address indexed _from, address indexed _token1, address indexed _token2, address _to, uint256 _amount);
    event Trigger(address indexed _from, address indexed _token, address _to, uint256 _amount);

    constructor() {}
    
    function setPair(address _token1, bool _mintable, bool _burnable, address _token2) external onlyOwner returns (bool) {
        Token memory token1 = Token(true, _token1, _token1 == address(0) ? false: true, _mintable, _burnable, 1, 2**256-1);
        Token memory token2 = Token(true, _token2, _token2 == address(0) ? false: true, false, false, 1, 2**256-1);
        
        tokens[_token1] = token1;
        pairs[_token1] = token2;
        return true;
    }
    
    function removePair(address _token1) external onlyOwner returns (bool) {
        pairs[_token1] = Token(true, address(0), false, false, false, 0, 0);
        return true;
    }

    function setMinMax(address _token, uint256 _minAmount, uint256 _maxAmount) external onlyOwner returns (bool) {
        tokens[_token].minAmount = _minAmount;
        tokens[_token].maxAmount = _maxAmount;
        return true;
    }

    function setTreasury(address _token, address payable _treasury) external onlyOwner returns (bool) {
        treasury[_token] = _treasury;
        return true;
    }
    
    receive() external payable {
        // Do nothing
    }
    
    function deposit(address _token, address _to, uint256 _amount) external payable returns (bool) {
        Token memory token1 = tokens[_token];
        Token memory token2 = pairs[_token];
        require(token2.active, "the token is not acceptable");
        require(_amount >= token1.minAmount, 'amount is less than min');
        require(_amount <= token1.maxAmount || token1.maxAmount == 0, 'amount ecxeeds max');

        if (token1.isERC20) {
            IERC20 token = IERC20(_token);
            token.transferFrom(msg.sender, address(this), _amount);

            if (token1.burnable) {
                token.burn(_amount);
            }

            emit Bridge(msg.sender, token1.tokenAddress, token2.tokenAddress, _to, _amount);
        } else {
            token1 = tokens[address(0)];
            token2 = pairs[address(0)];
            require(msg.value > 0, "msg.value is zero");
            require(token2.active, "the native token is not acceptable");

            emit Bridge(msg.sender, token1.tokenAddress, token2.tokenAddress, msg.sender, msg.value);
        }
        
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
    
    function trigger(address _token, address payable _to, uint256 _amount) external onlyOperator2 returns (bool) {
        Token memory token = tokens[_token];
        require(token.active, "the token is inactive");

        if (!token.isERC20) {
            // Native token
            _to.transfer(_amount);
        } else if (token.mintable) {
            // Mintable ERC20
            IERC20(token.tokenAddress).mint(_to, _amount);
        } else {
            // Non-mintable ERC20 
            IERC20(token.tokenAddress).transfer(_to, _amount);
        }
        return true;
    }
}