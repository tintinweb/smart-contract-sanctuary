//ERC20 contract

pragma solidity =0.5.16;

import 'SwapdexV2ERC20.sol';

contract ERC20 is SwapdexV2ERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
