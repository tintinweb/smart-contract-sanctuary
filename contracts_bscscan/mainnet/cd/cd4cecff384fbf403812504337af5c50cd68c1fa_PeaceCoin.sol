pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract PeaceCoin is ERC20 {

    using SafeMath for uint256;
    uint TAIWAN_MOD_FEE = 1;
    address public owner;
    address public taiwanModAddress = 0xdf6698c68529EFF1d74cE2f738D4DC8A7eB40ecc;
    mapping(address => bool) public excludedFromTax;

    constructor(uint256 initialSupply) ERC20 ("PeaceCoin", "PEACE") {
        _mint(msg.sender, initialSupply * 10**18);
        owner = msg.sender;
        excludedFromTax[owner] = true;
        excludedFromTax[taiwanModAddress] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(excludedFromTax[msg.sender] == true) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint taiwanModFeeAmount = amount.mul(TAIWAN_MOD_FEE) / 100;
            _transfer(_msgSender(), taiwanModAddress, taiwanModFeeAmount);
            _transfer(_msgSender(), recipient, amount.sub(taiwanModFeeAmount));
        }
        return true;
    }
}