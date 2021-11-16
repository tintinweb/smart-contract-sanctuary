pragma solidity =0.8.0;

import "./ERC20.sol";

contract Gattaca2 is ERC20 {
    constructor() ERC20('Gattaca 2', 'GAT2') public {}

    function faucet(address to, uint amount) external {
        _mint(to, amount);
    }
}