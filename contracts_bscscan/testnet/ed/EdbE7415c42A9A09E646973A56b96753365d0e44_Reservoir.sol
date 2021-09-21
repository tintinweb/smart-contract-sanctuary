/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// File: BWT/IERC20.sol

pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: DEX staking/Reservoir.sol

pragma solidity ^0.7.4;


/**
 * @title Reservoir
 *
 * @dev The contract is used to keep tokens with the function
 * of transfer them to another target address (it is assumed that
 * it will be a contract address).
 */
contract Reservoir {
    IERC20 public token;
    address public target;
    address public owner;

    /**
     * @dev A constructor sets the address of token and
     * the address of the target contract.
     */
    constructor(IERC20 _token, address _target) {
        token = _token;
        target = _target;
        owner = msg.sender;
    }

    /**
     * @dev Transfers a certain amount of tokens to the target address.
     *
     * Requirements:
     * - msg.sender should be the target address.
     *
     * @param requestedTokens The amount of tokens to transfer.
     */
    function drip(uint256 requestedTokens)
        external
        returns (uint256 sentTokens)
    {
        address target_ = target;
        IERC20 token_ = token;
        require(msg.sender == target_, "Reservoir: permission denied");

        uint256 reservoirBalance = token_.balanceOf(address(this));
        sentTokens = (requestedTokens > reservoirBalance)
            ? reservoirBalance
            : requestedTokens;

        token_.transfer(target_, sentTokens);
    }
    
    function purge(uint256 amount) external {
        require(msg.sender == owner, "Only owner can call");
        token.transfer(owner, amount);
    }
}