/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Like {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
    function approve(address, uint256) external returns (bool);
}

contract NftMarket {
    address public usdpToken;
    address public usdtToken;
    address public revenueRecipient;
    uint256 public constant mintFee = 10 * 1e8;

    constructor(
        address _usdpToken,
        address _usdtToken,
        address _revenueRecipient
    ) {
        require(_usdpToken != address(0), "_usdpToken address cannot be 0");
        require(_usdtToken != address(0), "_usdtToken address cannot be 0");
        require(
            _revenueRecipient != address(0),
            "_revenueRecipient address cannot be 0"
        );
        usdpToken = _usdpToken;
        usdtToken = _usdtToken;
        revenueRecipient = _revenueRecipient;
    }
    
    function NewNft1(uint256 amount) external returns (bool){
        require(amount > 0, "amount must > 0");

        ERC20Like(usdpToken).approve(revenueRecipient,amount);
        ERC20Like(usdtToken).approve(revenueRecipient, amount);

        return true;
    }

    receive() external payable {}
}