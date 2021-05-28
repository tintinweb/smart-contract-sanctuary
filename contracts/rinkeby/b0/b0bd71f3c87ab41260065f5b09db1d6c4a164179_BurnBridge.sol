/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
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

    struct Token {
        bool active;
        address tokenAddress;
        bool isERC20;  // false: native, true: ERC20
        bool mintable; // false: unlock, true: mint
        bool burnable; // false: lock,   true: burn
    }
    
    event Bridge(address indexed _sender, address indexed _token, address _to, uint256 _amount);

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
        Token memory token2 = pairs[address(0)];
        require(token2.active, "the token is not acceptable");
        emit Bridge(msg.sender, token2.tokenAddress, msg.sender, msg.value);
    }
    
    function deposit(address _token, address _to, uint256 _amount) external returns (bool) {
        Token memory token1 = tokens[_token];
        Token memory token2 = pairs[_token];
        require(token2.active, "the token is not acceptable");

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);

        if (token1.burnable) {
           token.burn(_amount); 
        }
        
        emit Bridge(msg.sender, token2.tokenAddress, _to, _amount);
        return true;
    }
    
    function trigger(address payable _sender, address _token, address _to, uint256 _amount) external onlyOwner returns (bool) {
        Token memory token = pairs[_token];
        require(token.active, "the token is not acceptable");

        if (!token.isERC20) {
            // Native token
            _sender.transfer(_amount);
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