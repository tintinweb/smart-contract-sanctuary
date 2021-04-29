pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Nectar is  ERC20 , ERC20Burnable{

    constructor () public ERC20("Nectar", "NTA") {
        _mint(_msgSender(), 82800000000 * (10 ** uint256(decimals())));
    }

}