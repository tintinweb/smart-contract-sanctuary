// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import './SafeMath.sol';
contract Work is ERC20Burnable {
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _totalSupply,
        address owner,
        address _community,
        address _liq,
        address _mark,
        address _dev,
        address _presale,
        address _team,
        address _reserve
    ) ERC20(name, symbol) {
        _mint(owner, _totalSupply.mul(55).div(100));
        _mint(_community, _totalSupply.mul(2).div(100));
        _mint(_liq, _totalSupply.mul(1).div(100));
        _mint(_mark, _totalSupply.mul(4).div(100));
        _mint(_dev, _totalSupply.mul(7).div(100));
        _mint(_presale, _totalSupply.mul(4).div(100));
        _mint(_team, _totalSupply.mul(17).div(100));
        _mint(_reserve, _totalSupply.mul(10).div(100));
    }
}