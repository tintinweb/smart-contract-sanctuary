/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.5.0;

contract BadToken {

    string public constant name = "BadToken";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "BTN";

    /// @notice EIP-20 token decimals for this token
    uint256 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 1_000e18; // 1 billion Uni

    /// @notice Official record of token balances for each account
    mapping (address => uint256) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);


    constructor() public {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        address src = msg.sender;
        balances[src] -= amount;
        balances[dst] += amount;
        emit Transfer(src, dst, amount);
        return true;
    }
}