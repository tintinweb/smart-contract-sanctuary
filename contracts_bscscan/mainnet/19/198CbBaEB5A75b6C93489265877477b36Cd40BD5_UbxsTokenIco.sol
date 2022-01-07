// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./SafeMath.sol";

contract UbxsTokenIco {
    using SafeMath for uint256;

    uint256 public constant UBXS_PER_BNB = 5_555_000_000;
    uint256 public constant MINIMUM_COST = 200_000_000_000_000_000;

    address payable public tokenOwnerWallet;
    address public _token;
    uint256 internal saleEnd;

    event BuyToken(address indexed buyer, uint256 amount);

    constructor(address payable wallet, address payable tokenAddress) {
        saleEnd = block.timestamp.add(45 days);
        tokenOwnerWallet = wallet;
        _token = tokenAddress;
    }

    function buyTokens() public payable {
        require(msg.value >= MINIMUM_COST, "Minimum cost is 0.2 BNB.");
        require(block.timestamp < saleEnd, "Sale is ended.");

        uint256 ubxsAmount = msg.value.mul(UBXS_PER_BNB).div(1 ether);
        require(ubxsAmount <= getRemainingTokens(), "Not enought token.");

        ERC20(_token).transfer(msg.sender, ubxsAmount);
        tokenOwnerWallet.transfer(msg.value);

        emit BuyToken(msg.sender, ubxsAmount);
    }

    function sendTokensToOwnerIfSaleEnded() public payable {
        require(msg.sender == tokenOwnerWallet, "This is for only owner.");
        require(block.timestamp > saleEnd, "Sale is not ended.");

        ERC20(_token).transfer(msg.sender, getRemainingTokens());
    }

    function getRemainingTokens() public view returns (uint256) {
        return ERC20(_token).balanceOf(address(this));
    }

    function getTokenAddress() public view returns (address) {
        return _token;
    }
}