// contracts/PiPiCoin.sol
pragma solidity >=0.6.0 <0.9.0;

import "./SafeMath.sol";
import "./ERC20Burnable.sol";
import "./ERC20.sol";

contract PiPiCoin is ERC20, ERC20Burnable {
    using SafeMath for uint256;

    constructor(uint256 initialSupply) ERC20("PiPiCoin", "PIPI") public {
        _mint(msg.sender, initialSupply);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}