/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
        emit OwnershipTransferred(owner, _owner);
    }
}

contract BurnBridge is Ownable {
    mapping(address => Token) public tokens;
    mapping(address => Token) public pairs;
    uint256 public nativeCirculation = 0;

    struct Token {
        bool active;
        address tokenAddress;
        bool isERC20;  // false: native, true: ERC20
        bool mintable; // false: unlock, true: mint
        bool burnable; // false: lock,   true: burn
    }
    
    event Bridge(address indexed _from, address indexed _token1, address indexed _token2, address _to, uint256 _amount);

    constructor() {}
    
    function setPair(address _token1, bool _mintable, bool _burnable, address _token2) external onlyOwner returns (bool) {
        Token memory token1 = Token(true, _token1, _token1 == address(0) ? false: true, _mintable, _burnable);
        Token memory token2 = Token(true, _token2, _token2 == address(0) ? false: true, false, false);
        
        tokens[_token1] = token1;
        pairs[_token1] = token2;
        return true;
    }
    
    function removePair(address _token1) external onlyOwner returns (bool) {
        pairs[_token1] = Token(true, address(0), false, false, false);
        return true;
    }
    
    receive() external payable {
        // Do nothing
    }
    
    function deposit(address _token, address _to, uint256 _amount) external payable returns (bool) {
        Token memory token1 = tokens[_token];
        Token memory token2 = pairs[_token];
        require(token2.active, "the token is not acceptable");

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

            nativeCirculation = nativeCirculation - _amount;
            emit Bridge(msg.sender, token1.tokenAddress, token2.tokenAddress, msg.sender, msg.value);
        }
        
        return true;
    }
    
    function trigger(address _token, address payable _to, uint256 _amount) external onlyOwner returns (bool) {
        Token memory token = tokens[_token];
        require(token.active, "the token is not acceptable");

        if (!token.isERC20) {
            // Native token
            nativeCirculation = nativeCirculation + _amount;
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