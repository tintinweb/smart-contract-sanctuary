// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
/**
Sc dev
t.me/bolpol
*/

/**
    @title ERC20 interface (short version)
*/
interface ERC20 {
    function balanceOf(address tokenOwner) external returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
}

/**
    @title Owned - ownership
*/
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
    @title Airdropper - using for package token transfer
*/
contract Airdropper is Owned {
    ERC20 public token;
    
    event Airdropped(bool indexed ok);
    event Destroyed(uint indexed time);

    /**
     * @dev Constructor.
     * @param tokenAddress Address of the token contract.
     */
    constructor(address tokenAddress) {
        token = ERC20(tokenAddress);
    }

    /**
     * @dev Airdrop.
     * @ !important Before using, send needed token amount to this contract
     */
    function airdrop(address[] memory dests, uint[] memory values) public onlyOwner {
        // This simple validation will catch most mistakes without consuming
        // too much gas.
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            token.transfer(dests[i], values[i]);
        }
        
        emit Airdropped(true);
    }

    /**
     * @dev Return all tokens back to owner, in case any were accidentally
     *   transferred to this contract.
     */
    function returnTokens() public onlyOwner returns(bool) {
        return token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Destroy this contract and recover any ether to the owner.
     */
    function destroy() public onlyOwner {
        if(returnTokens()) {
            emit Destroyed(block.timestamp);
            selfdestruct(msg.sender);
        }
    }
}