pragma solidity ^0.8.0;
import "./ERC20.sol";

contract DAI is ERC20 {
    address private _owner;

    constructor() public ERC20("StableCoin", "DAI") {
        _owner = msg.sender;
    }

    function mint(address addr, uint256 amount) public {
        require(msg.sender == _owner);
        _mint(addr, amount);
    }
}