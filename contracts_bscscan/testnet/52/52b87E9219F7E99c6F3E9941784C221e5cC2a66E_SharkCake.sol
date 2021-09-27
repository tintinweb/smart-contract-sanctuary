pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract SharkCake is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public maxSupply = 100 * 10**6 * 10**18;

    constructor() public ERC20("SharkCake Test", "SHARK") {
        _mint(_msgSender(), maxSupply);
    }
}