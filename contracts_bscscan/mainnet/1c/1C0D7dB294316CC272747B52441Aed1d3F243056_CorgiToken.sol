// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract CorgiToken is Ownable, ERC20 {
    using SafeMath for uint256;
    uint256 public maxSupply = 100 * 10**6 * 10**18;
    address public corgiFarm;
    address public devAddress;
    uint256 public taxFee = 2;
    uint256 public _maxTxAmount = 10000 * 10**18; // Max 10000 COR / 1 TRANSACTION
    mapping(address => bool) private _isExcludedFromFee;

    constructor() ERC20("CorgiToken", "COR", 18) {
        _mint(_msgSender(), maxSupply);
        _isExcludedFromFee[_msgSender()] = true;
        corgiFarm = _msgSender();
        devAddress = _msgSender();
    }

    /// @dev overrides transfer function to meet tokenomics of Token
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (sender != owner() && recipient != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[sender] ||
            (_isExcludedFromFee[recipient] && recipient != corgiFarm)
        ) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 _taxFee = amount.mul(taxFee).div(1000);
            super._transfer(sender, devAddress, _taxFee);
            amount = amount.sub(_taxFee);
        }
        super._transfer(sender, recipient, amount);
    }

    function setFarm(address farm_) external onlyOwner {
        if (corgiFarm == address(0)) {
            require(msg.sender == owner(), "not owner");
        } else {
            require(msg.sender == corgiFarm, "not farm");
        }
        corgiFarm = farm_;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setFee(uint256 _taxFee) public onlyOwner {
        taxFee = _taxFee;
    }

    function updatedevAddress(address _devAddress)
        public
        onlyOwner
        returns (bool)
    {
        _isExcludedFromFee[devAddress] = false;
        devAddress = _devAddress;
        _isExcludedFromFee[devAddress] = true;
        return true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
}