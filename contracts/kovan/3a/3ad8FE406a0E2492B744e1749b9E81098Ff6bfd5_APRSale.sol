// SPDX-License-Identifier: MIT

pragma solidity ^ 0.7.6;

import "./Ownable.sol";
import "./APR.sol";

/**
 *  Smart Contract to sell APR token
 */
contract APRSale is Ownable {
    using SafeMath for uint256;

    APR private _token;
    uint256 private _price;

    event Sold(address buyer, uint256 amount);

    /**
     *  constructor
     *  param {address} token_
     */
    constructor () {
        _token = new APR();
        setPrice(1);
        deposit();
    }

    /**
     * get price
     */
    function price() public view virtual returns (uint256) {
        return _price;
    }

    /**
     * get token address
     */
    function tokenAddress() public view virtual returns (address) {
        return address(_token);
    }

    /**
     * get balance
     */
    function balance() public view virtual returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * deposit
     * transfer all of APR tokens to this
     */
    function deposit() public virtual onlyOwner {
        require(_token.transfer(address(this), _token.totalSupply()), "APRSale: deposit must succeed.");
    }

    /**
     * set price
     */
    function setPrice(uint256 price_) public virtual onlyOwner {
        _price = price_;
    }

    /**
     * buy APR tokens
     */
    function buy(uint256 numberOfTokens) public payable {
        require(msg.value == numberOfTokens.mul(_price), "APRSale: value must equal number of tokens in wei.");

        uint256 amount = numberOfTokens.mul(uint256(10) ** _token.decimals());

        require(_token.balanceOf(address(this)) >= amount, "APRSale: token balance must be larger than amount.");

        emit Sold(msg.sender, numberOfTokens);

        require(_token.transfer(msg.sender, amount), "APRSale: token transfer must succeed.");
    }
}