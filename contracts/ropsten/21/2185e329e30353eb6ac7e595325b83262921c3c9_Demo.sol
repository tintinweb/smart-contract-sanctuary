/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.5.16;

interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}


contract Demo{
        string public symbol;
        string public name;


     modifier onlyGovernance {
        require(msg.sender == governance, "Governance required.");
        _;
    }
    
    event TokenAllocated(address from, address to, uint amount);
    
    mapping(address => uint) public userAllocation;
    address public governance;
    address public airdropToken;
    
    constructor(address token) public {

        governance = msg.sender;
        airdropToken = token;
    }
    
    function setUserAllocation(address[] memory users, uint[] memory allocations) onlyGovernance public {
        require(users.length == allocations.length, "Inconsistent parameter length");
        for (uint256 i = 0; i < users.length; i++) {
            userAllocation[users[i]] = allocations[i];
        }
    }
    
    function getUserAllocation(address user) public view returns (uint) {
        return userAllocation[user];
    }
    
    function withdraw() public {
        uint amount = userAllocation[msg.sender];
        EIP20Interface(airdropToken).transfer(msg.sender, amount);
        emit TokenAllocated(address(this), msg.sender, amount);
    }
}