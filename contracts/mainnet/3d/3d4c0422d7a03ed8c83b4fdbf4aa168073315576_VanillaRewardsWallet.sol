/**
 *Submitted for verification at Etherscan.io on 2020-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract VanillaRewardsWallet is Owned{
    
    mapping(address => bool) public allowedPools;
    
    IERC20 public vanilla;
    
    constructor(address payable _owner, address _vanillaToken) public{
        owner = _owner;
        vanilla = IERC20(_vanillaToken);
    }
    
    function addPool(address _poolAddress) external onlyOwner{
        allowedPools[_poolAddress] = true;
    }
    
    function removePool(address _poolAddress) external onlyOwner{
        allowedPools[_poolAddress] = false;
    }
    
    function sendRewards(address to, uint256 tokens) public{
        require(allowedPools[msg.sender], "UnAuthorized");
        
        // transfer rewards tokens
        require(vanilla.transfer(to, tokens));
    }
}