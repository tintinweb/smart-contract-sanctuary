pragma solidity ^0.8.0;

import "./ERC777.sol";

contract L2DCN is ERC777 {
    constructor(address[] memory defaultOperators_) ERC777("Dentacoin", "DCN", defaultOperators_) {
        _mint(_msgSender(), 5000 * 10**decimals(), "", "");
    }
}