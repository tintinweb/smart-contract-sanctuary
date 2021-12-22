// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract ZSTToken is Ownable, ERC20{

    uint256 private _maxtotalSupply = 1000000000 * 10 ** decimals();

    constructor (string memory tokenName, string memory simbol) Ownable() ERC20(tokenName, simbol){
//    constructor () Ownable() ERC20("ZenstyToken", "ZST"){
        _mint(msg.sender,  _maxtotalSupply);
    }

    function burn(uint256 _value) external onlyOwner {
        _burn(_msgSender(), _value);
    }

}

//ZenToken
//ZTO