// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import {ILendingPool} from './ILendingPool.sol';
import "./Ownable.sol";
import "./IERC20.sol";

contract MyFinance is Ownable {
    ILendingPool lendingPool = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);

    address daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address usdtToken = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address usdcToken = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    mapping(address => bool) public charities;

    function enableCharity(address _charity, bool _enabled) public onlyOwner {
        charities[_charity] = _enabled;
    }

    function withdrawDAI(uint256 _amount, address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");

        _withdraw(_amount, daiToken, _charity, _percentage);
    }

    function depositDAI(uint256 _amount) public {
        _deposit(_amount, daiToken);
    }

    function withdrawUSDT(uint256 _amount, address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");

        _withdraw(_amount, usdtToken, _charity, _percentage);
    }

    function depositUSDT(uint256 _amount) public {
        _deposit(_amount, usdtToken);
    }

    function withdrawUSDC(uint256 _amount, address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");

        _withdraw(_amount, usdcToken, _charity, _percentage);
    }

    function depositUSDC(uint256 _amount) public {
        _deposit(_amount, usdcToken);
    }

    function _withdraw(uint256 _amount, address _token, address _charity, uint256 _percentage) internal {
        uint256 total = lendingPool.withdraw(_token, _amount, msg.sender);

        uint256 donation = total * _percentage / 100;
        uint256 earnings = total - donation;

        if (donation > 0) {
            require(IERC20(_token).transferFrom(address(this), _charity, donation), 'Could not transfer tokens');
        }

        if (earnings > 0) {
            require(IERC20(_token).transferFrom(address(this), msg.sender, earnings), 'Could not transfer tokens');
        }
    }

    function _deposit(uint256 _amount, address _token) internal {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        IERC20(_token).approve(address(lendingPool), _amount);
        lendingPool.deposit(_token, _amount, msg.sender, 0);
    }
}