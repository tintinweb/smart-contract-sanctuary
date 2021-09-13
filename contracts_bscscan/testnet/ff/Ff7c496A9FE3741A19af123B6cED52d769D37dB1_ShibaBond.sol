// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";

contract ShibaBond is Ownable, ERC20 {
    using SafeMath for uint256;

    address payable public devAddr;
    uint256 public burnFee;
    uint256 public devFee;
    bool public isTaxActive;
    mapping(address => bool) public isTaxless;

    event BurnFeeSet(uint256 burnFee);
    event DevFeeSet(uint256 devFee);
    event SwapEnabled(bool status);

    constructor() ERC20("Shiba Bond","007") public {
        _mint(_msgSender(),100_000e18);
        isTaxless[_msgSender()] = true;
        burnFee = 500;
        devFee = 200;
        devAddr = _msgSender();
    }
    
    function setTaxActive(bool _value) external onlyOwner {
        isTaxActive = _value;
    }

    function setTaxless(address account, bool _value) external onlyOwner {
        isTaxless[account] = _value;
    }

    function setBurnFee(uint256 _burnFee) external onlyOwner {
        require(_burnFee > 0 && _burnFee <= 1000, "Burn fee out of range!");
        burnFee = _burnFee;

        emit BurnFeeSet(burnFee);
    }

    function setDevFee(uint256 _devFee) external onlyOwner {
        require(_devFee > 0 && _devFee <= 1000, "Dev fee out of range!");
        devFee = _devFee;

        emit DevFeeSet(devFee);
    }
    
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender,_msgSender()).sub(amount, "007: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 transferAmount = amount;
        if(isTaxActive && !isTaxless[sender] && !isTaxless[recipient]) {
            uint256 burnAmount = amount.mul(burnFee).div(10_000);
            uint256 devAmount = amount.mul(devFee).div(10_000);
            transferAmount = amount.sub(burnAmount).sub(devAmount);
            super._burn(sender,burnAmount);
            super._transfer(sender, devAddr, devAmount);
        }
        super._transfer(sender, recipient, transferAmount);
    }
}