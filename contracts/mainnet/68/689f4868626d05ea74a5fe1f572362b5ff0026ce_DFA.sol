pragma solidity ^0.8.0;
import "./ERC20.sol";
contract DFA is ERC20 {
constructor ()
ERC20("DeFine", "DFA")
{
_mint(
msg.sender,
5 * 10 ** 26
);
}
}