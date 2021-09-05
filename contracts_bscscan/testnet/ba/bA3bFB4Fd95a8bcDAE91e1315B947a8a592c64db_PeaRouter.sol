// SPDX-License-Identifier: UNLICENSED
import "./Ownable.sol";

pragma solidity ^0.7.6;

contract PeaRouter is Ownable {
    mapping(address => bool) public gemers;

    address public feeAddress;
    uint256 public priceKey = 10 * 10**3 * 10**18;
    uint256 public feeGem = 0;
    uint256 public feeMarket = 25;
    uint256 public divPercent = 1000;

    constructor() {
        feeAddress = _msgSender();
    }

    function setGemers(address _gemer) public onlyOwner {
        gemers[_gemer] = true;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function setPriceKey(uint256 _price) public onlyOwner {
        priceKey = _price;
    }

    function setFeeGem(uint256 _fee) public onlyOwner {
        feeGem = _fee;
    }

    function setFeeMarket(uint256 _fee) public onlyOwner {
        feeMarket = _fee;
    }
}