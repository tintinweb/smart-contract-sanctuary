pragma solidity =0.8.0;

import "./ERC20.sol";

contract Gattaca1 is ERC20 {
    constructor() ERC20('Gattaca 1', 'GAT1') public {}

    function faucet(address to, uint amount) external {
        _mint(to, amount);
    }
}