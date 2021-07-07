pragma solidity ^0.5.17;
import "./AbstractToken.sol";
contract BurnToken is AbstractToken {
    constructor() public AbstractToken("ETHYFIS","EFI",6){
        _mint(address(msg.sender),300000 * (10 ** uint256(decimals())));
    }
}