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
    mapping(address => Pair) public pairs;

    struct Token {
        address tokenAddress;
        bool isERC20;  // false: native, true: ERC20
        bool mintable; // false: unlock, true: mint
        bool burnable; // false: lock,   true: burn
    }

    struct Pair {
        bool active;
        Token token1;
        Token token2;
    }
    
    event Bridge(address indexed _sender, address indexed _token, address _to, uint256 _amount);

    constructor() {}
    
    function setPair(address _token1, bool _token1Mintable, bool _token1Burnable, address _token2, bool _token2Mintable, bool _token2Burnable) external onlyOwner returns (bool) {
        Token memory token1 = Token(_token1, _token1 == address(0) ? false: true, _token1Mintable, _token1Burnable);
        Token memory token2 = Token(_token2, _token2 == address(0) ? false: true, _token2Mintable, _token2Burnable);
        pairs[_token1] = Pair(true, token1, token2);
        return true;
    }
    
    function removePair(address _token1) external onlyOwner returns (bool) {
        pairs[_token1] = Pair(false, Token(address(0), false, false, false), Token(address(0), false, false, false));
        return true;
    }
    
    receive() external payable {
        Pair memory pair = pairs[address(0)];
        require(pair.active, "the token is not acceptable");
        emit Bridge(msg.sender, address(0), msg.sender, msg.value);
    }
    
    function deposit(address _token, address _to, uint256 _amount) external returns (bool) {
        Pair memory pair = pairs[address(0)];
        require(pair.active, "the token is not acceptable");

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);

        if (pair.token1.burnable) {
           token.burn(_amount); 
        }
        
        emit Bridge(msg.sender, _token, _to, _amount);
        return true;
    }
    
    function trigger(address payable _sender, address _token, address _to, uint256 _amount) external returns (bool) {
        Pair memory pair = pairs[_token];
        require(pair.active, "the token is not acceptable");

        if (!pair.token2.isERC20) {
            // Native token
            _sender.transfer(_amount);
        } else if (pair.token2.mintable) {
            // Mintable ERC20
            IERC20(pair.token2.tokenAddress).mint(_to, _amount);
        } else {
            // Non-mintable ERC20 
            IERC20(pair.token2.tokenAddress).transfer(_to, _amount);
        }
        return true;
    }
}