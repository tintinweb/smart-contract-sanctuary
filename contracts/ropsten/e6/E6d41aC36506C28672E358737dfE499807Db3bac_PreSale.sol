// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./JadeToken.sol";

contract PreSale is OlympusERC20Token {
    bool private presale;

    uint256 private price_of_token = 2 * (10**9); // 2 complete tokens per ether

    constructor() OlympusERC20Token("ACX","ACX") {}

    //---------------TOKEN_PRICING-------------------------

    function setTokenPrice(uint256 _price)
        public
        onlyOwner
        returns (uint256 _tokenPrice)
    {
        price_of_token = _price;
        return price_of_token;
    }

    function getTokenPrice() public view returns (uint256 _tokenPrice) {
        return price_of_token;
    }

    //---------------BUY_TOKENS-----------------------------

    function buyTokens() public payable isPreSale returns (bool _buy) {
        require(
            (msg.value > 0),
            "InSufficient Balance"
        );
        uint256 _tokens = (msg.value * price_of_token) / 1 ether;
        require(_tokens > 0, "No Token to buy");
        _mint(msg.sender, _tokens);
        return true;
    }

    //---------------WITHDRAW-ETH---------------------------

    function withdrawETH(address payable _beneficiary)public onlyOwner 
    {
        bool transferred = _beneficiary.send(address(this).balance);
        require(transferred, "Failed to withdraw Ethers!");
    }

    //----------------PRESALE-------------------------------

    function EnablePreSale() public onlyOwner {
        require(!presale, "PreSale Already Enabled!");
        presale = true;
    }

    function DisablePreSale() public onlyOwner {
        require(presale, "PreSale Already Disabled!");
        presale = false;
    }

    modifier isPreSale() {
        require(presale, "PreSale is Disabled!");
        _;
    }

    //---------------FALLBACK---------------------------
    receive() external payable {
        buyTokens();
    }
}