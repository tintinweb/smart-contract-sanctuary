/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint balance);
}

/// @title CrosschainLockLP
/// @author Artemij Artamonov - <[email protected].com>
/// @author Anton Davydov - <[email protected]>
contract CrosschainLockLP {

    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    mapping (address => bool) public allowedTokens;
    mapping (address => mapping (address => uint)) public balances;
    uint public totalSupply;
    mapping (address => uint) public lpSupply;

    event LockLPEvent(address indexed lptoken,
                      address indexed sender,
                      address indexed receiver,
                      uint amount);
    event UnlockLPEvent(address indexed lptoken,
                        address indexed sender,
                        address indexed receiver,
                        uint amount);

    constructor(address _owner, address[] memory _allowedTokens) {
        for (uint i = 0; i < _allowedTokens.length; i++) {
            allowedTokens[_allowedTokens[i]] = true;
        }
        owner = _owner;
    }

    function transferOwnership(address newOwner) public isOwner {
        owner = newOwner;
    }

    function toggleToken(address tokenAddress) public isOwner {
        allowedTokens[tokenAddress] = !allowedTokens[tokenAddress];
    }

    function lockTokens(address tokenAddress, address receiver, uint amount) public {
        require(allowedTokens[tokenAddress], "token not allowed");
        balances[tokenAddress][receiver] += amount;
        totalSupply += amount;
        lpSupply[tokenAddress] += amount;
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        emit LockLPEvent(tokenAddress, msg.sender, receiver, amount);
    }

    function unlockTokens(address tokenAddress, address receiver, uint amount) public {
        require(allowedTokens[tokenAddress], "token not allowed");
        require(balances[tokenAddress][msg.sender] >= amount, "not enough balance");
        balances[tokenAddress][msg.sender] -= amount;
        totalSupply -= amount;
        lpSupply[tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(receiver, amount);
        emit UnlockLPEvent(tokenAddress, msg.sender, receiver, amount);
    }

}