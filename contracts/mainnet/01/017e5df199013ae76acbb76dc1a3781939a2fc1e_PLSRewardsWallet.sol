/**
 *Submitted for verification at Etherscan.io on 2021-02-04
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

    function transferOwnership(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0),"Invalid address passed");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract PLSRewardsWallet is Owned{
    
    mapping(address => bool) public allowedStakingPools;
    
    IERC20 public PLS;
    
    constructor() public{
        owner = 0x0C3B4D8E2eCF2aBBe45842FF1837C000Fd4Bdc08;
    }
    
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        PLS = IERC20(_tokenAddress);
    }
    
    function addPool(address _poolAddress) external onlyOwner{
        allowedStakingPools[_poolAddress] = true;
    }
    
    function removePool(address _poolAddress) external onlyOwner{
        allowedStakingPools[_poolAddress] = false;
    }
    
    function sendRewards(address to, uint256 tokens) public{
        require(allowedStakingPools[msg.sender], "UnAuthorized");
        
        // transfer rewards tokens
        require(PLS.transfer(to, tokens));
    }
}