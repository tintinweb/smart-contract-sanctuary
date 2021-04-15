pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./Ownable.sol";

contract GRBToken is ERC20, Ownable {

    constructor () public ERC20("GRB2-Protection+", "GRB2") {
        _setupDecimals(6);
        _mint(msg.sender, 9800000000 * (10 ** uint256(decimals())));
    }

    function increaseSupply(uint256 _amount) public onlyOwner
    {
        _mint(msg.sender, _amount);
    }
}