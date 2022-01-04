// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./OlympusERC20.sol";

contract PreSale is OlympusERC20Token {
    bool private presale;

    uint256 private price_of_token = 2 * (10**9); // 2 complete tokens per ether

    constructor(address _authority) OlympusERC20Token(_authority) {}

    //---------------TOKEN_PRICING-------------------------

    function setTokenPrice(uint256 _price)
        public
        onlyVault
        returns (uint256 _tokenPrice)
    {
        price_of_token = _price;
        return price_of_token;
    }

    function getTokenPrice() public view returns (uint256 _tokenPrice) {
        return price_of_token;
    }

    //---------------BUY_TOKENS-----------------------------

    // At least 1gwei required for 1 gwei token...
    function buyTokens() public payable isPreSale returns (bool _buy) {
        require(
            (msg.value > 0) && (msg.value >= 1000000000),
            "InSufficient Balance"
        );
        uint256 _tokens = (msg.value * price_of_token) / 1 ether;
        _mint(msg.sender, _tokens);
        return true;
    }

    //----------------PRESALE-------------------------------

    function EnablePreSale() public onlyVault {
        require(!presale, "PreSale Already Enabled!");
        presale = true;
    }

    function DisablePreSale() public onlyVault {
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