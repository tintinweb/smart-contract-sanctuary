// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "./FullERC20.sol";

contract Tori is ERC20 {

    constructor() ERC20("Tori", "TORI") {
    }   

    uint256 private constant MAX_SUPPLY = 1000 * 1000 * 1000;    //1 billion
    uint256 private constant MAX_MINT_SUPPLY = 1000 * 1000;      //1 million
    uint256 public _mintSupply = 0;

    function mintCoin() external {
        require(totalSupply() <= MAX_SUPPLY, "cannot mint coins");
        require(_mintSupply <= MAX_MINT_SUPPLY, "cannot mint coins");
        require(balanceOf(_msgSender()) == 0, "address cannot mint coins");
        _mint(_msgSender(), 100);
        _mintSupply += 100;
    }   

    //for game contracts
    function ownerMintCoin(uint256 amount) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "cannot mint coins");
        _mint(_msgSender(), amount);
    }   
}