// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "./ILendingPool.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract MyFinance is Ownable {
    ILendingPool lendingPool = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);

    address daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address usdtToken = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address usdcToken = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    mapping(address=>uint256) public daiDeposits;
    mapping(address=>uint256) public usdtDeposits;
    mapping(address=>uint256) public usdcDeposits;

    mapping(address => bool) public charities;

    event Withdrew(address indexed beneficiary, uint totalRequested, address asset, address charity, uint percentage, uint totalRecovered, uint donation);

    function enableCharity(address _charity, bool _enabled) public onlyOwner {
        charities[_charity] = _enabled;
    }

    function withdrawDAI(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(daiDeposits[msg.sender] > 0, "Nothing to withdraw");

        uint256 amount = daiDeposits[msg.sender];
        daiDeposits[msg.sender] = 0;

        _withdraw(amount, daiToken, _charity, _percentage);
    }

    function depositDAI(uint256 _amount) public {
        _deposit(_amount, daiToken);
        daiDeposits[msg.sender] += _amount;
    }

    function withdrawUSDT(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(usdtDeposits[msg.sender] > 0, "Nothing to withdraw");

        uint256 amount = usdtDeposits[msg.sender];
        usdtDeposits[msg.sender] = 0;

        _withdraw(amount, usdtToken, _charity, _percentage);
    }

    function depositUSDT(uint256 _amount) public {
        _deposit(_amount, usdtToken);
        usdtDeposits[msg.sender] += _amount;
    }

    function withdrawUSDC(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage < 100, "Invalid percentage");
        require(usdcDeposits[msg.sender] > 0, "Nothing to withdraw");

        uint256 amount = usdcDeposits[msg.sender];
        usdcDeposits[msg.sender] = 0;

        _withdraw(amount, usdcToken, _charity, _percentage);
    }

    function depositUSDC(uint256 _amount) public {
        _deposit(_amount, usdcToken);
        usdcDeposits[msg.sender] += _amount;
    }

    function _withdraw(uint256 _amount, address _token, address _charity, uint256 _percentage) internal {
        IERC20(_token).approve(address(lendingPool), _amount);
        uint256 total = lendingPool.withdraw(_token, _amount, address(this));

        uint256 donation = total * _percentage / 100;
        uint256 earnings = total - donation;

        if (donation > 0) {
            require(IERC20(_token).transferFrom(address(this), _charity, donation), 'Could not transfer tokens');
        }

        if (earnings > 0) {
            require(IERC20(_token).transferFrom(address(this), msg.sender, earnings), 'Could not transfer tokens');
        }

        emit Withdrew(msg.sender, _amount, _token, _charity, _percentage, total, donation);
    }

    function _deposit(uint256 _amount, address _token) internal {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        IERC20(_token).approve(address(lendingPool), _amount);
        lendingPool.deposit(_token, _amount, address(this), 0);
    }
}