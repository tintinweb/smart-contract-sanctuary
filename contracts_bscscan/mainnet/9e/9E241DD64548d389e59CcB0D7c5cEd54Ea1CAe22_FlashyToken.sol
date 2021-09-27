// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "SafeMath.sol";

contract FlashyToken is ERC20 {
    using SafeMath for uint256;
    
    address private _official = address(0x680957146f49ce15233Dc4d6620382750A838A9B);
    address private _owner;
    mapping(address => address) private _inviter;
    
    constructor(uint256 initialSupply) ERC20("Flashy", "FLA") {
        _owner = msg.sender;
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
    
    function setOfficial(address _address) public returns (bool) {
        require(msg.sender == _owner);
        _official = _address;
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (_inviter[recipient] == address(0)) {
            _inviter[recipient] = _msgSender();
        }
        uint256 dead_amount = amount.div(100);
        uint256 uper_amount = amount.div(100);
        uint256 offi_amount = amount.div(200);
        uint256 targ_amount = amount.sub(dead_amount + uper_amount + offi_amount);
        _transfer(_msgSender(), address(0x000000000000000000000000000000000000dEaD), dead_amount);
        _transfer(_msgSender(), _inviter[recipient], uper_amount);
        _transfer(_msgSender(), _official, offi_amount);
        _transfer(_msgSender(), recipient, targ_amount);
        return true;
    }
    
}