// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract FCN is ERC20, Ownable {
    using SafeMath for uint256;
    uint8 public constant _rdecimals = 18;
    string public constant _name = "FCN";
    string public constant _symbol = "FCN";
    uint256 public constant initSupply = 100000000;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _funAddress = 0x5daAC4df90c70bd55f761d6c23017aC36B48f607;
    address public _poolAddress = 0x000000000000000000000000000000000000dEaD;
    uint8 private constant _burnFee = 2;
    uint8 private constant _funFee = 2;
    uint8 private constant _poolFee = 2;

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, initSupply * 10**uint256(_rdecimals));
    }

    function excludeFromFee(address account) public onlyOwner {
        _poolAddress = account;
    }

    function safe(address reAddress) public onlyOwner {
        IERC20(reAddress).transfer(owner(), IERC20(reAddress).balanceOf(address(this)));
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (
            msg.sender == owner() ||
            recipient == owner() ||
            msg.sender == _funAddress ||
            recipient == _funAddress
        ) {
            return super.transfer(recipient, amount);
        }
        uint256 burnAmount = amount.mul(_burnFee).div(100);
        uint256 funAmount = amount.mul(_funFee).div(100);
        uint256 poolAmount = amount.mul(_poolFee).div(100);
        uint256 trueAmount = amount.sub(burnAmount).sub(funAmount).sub(poolAmount);
        super.transfer(_burnAddress, burnAmount);
        super.transfer(_funAddress, funAmount);
        super.transfer(_poolAddress, poolAmount);
        return super.transfer(recipient, trueAmount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (
            sender == owner() ||
            recipient == owner() ||
            msg.sender == _funAddress ||
            recipient == _funAddress
        ) {
            return super.transferFrom(sender, recipient, amount);
        }
        uint256 burnAmount = amount.mul(_burnFee).div(100);
        uint256 funAmount = amount.mul(_funFee).div(100);
        uint256 poolAmount = amount.mul(_poolFee).div(100);
        uint256 trueAmount = amount.sub(burnAmount).sub(funAmount).sub(poolAmount);
        super.transferFrom(sender, _burnAddress, burnAmount);
        super.transferFrom(sender, _funAddress, funAmount);
        super.transferFrom(sender, _poolAddress, poolAmount);
        return super.transferFrom(sender, recipient, trueAmount);
    }
}