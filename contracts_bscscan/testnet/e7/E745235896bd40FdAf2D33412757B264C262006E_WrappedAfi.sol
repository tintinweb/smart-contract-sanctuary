// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract WrappedAfi is ERC20("Wrapped AFI", "wAFI"), Ownable {
    using SafeMath for uint256;

    IERC20 public immutable safeToken;
    address public devAddr;

    uint256 public originalSafeBalance = 0;

    // TOEDIT: Fee
    uint256 public wrapFeeRate = 0;
    uint256 public unwrapFeeRate = 0;

    // TOEDIT: Set decimal place here
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    constructor(IERC20 _safeToken) {
        safeToken = _safeToken;
        devAddr = msg.sender;
    }

    event SetWrapFeeRate(
        address indexed setter,
        uint256 oldRate,
        uint256 newRate
    );

    function setWrapFeeRate(uint256 _wrapFeeRate) public onlyOwner {
        // Prevent too greedy
        require(_wrapFeeRate <= 200, "Too greedy");
        emit SetWrapFeeRate(msg.sender, wrapFeeRate, _wrapFeeRate);
        wrapFeeRate = _wrapFeeRate;
    }

    event SetUnwrapFeeRate(
        address indexed setter,
        uint256 oldRate,
        uint256 newRate
    );

    function setUnwrapFeeRate(uint256 _unwrapFeeRate) public onlyOwner {
        // Prevent too greedy
        require(_unwrapFeeRate <= 200, "Too greedy");
        emit SetUnwrapFeeRate(msg.sender, unwrapFeeRate, _unwrapFeeRate);
        unwrapFeeRate = _unwrapFeeRate;
    }

    event SetDev(
        address indexed setter,
        address indexed oldDev,
        address indexed newDev
    );

    function setDev(address _devAddr) public {
        require(msg.sender == devAddr || msg.sender == owner(), "Only Dev");
        emit SetDev(msg.sender, devAddr, _devAddr);
        devAddr = _devAddr;
    }

    event Wrap(
        address indexed wrapper,
        uint256 amount,
        uint256 wrapFee,
        uint256 totalReceived
    );

    function wrap(uint256 amount) public returns (uint256 totalReceived) {
        uint256 balanceBefore = safeToken.balanceOf(address(this));
        uint256 wrapRatio = getWrapRatio();
        safeToken.transferFrom(msg.sender, address(this), amount);

        uint256 safeBalance = safeToken.balanceOf(address(this));

        totalReceived = safeBalance.sub(balanceBefore);
        totalReceived = totalReceived.mul(1e18).div(wrapRatio);
        uint256 wrapFee = totalReceived.mul(wrapFeeRate).div(1000);

        totalReceived = totalReceived.sub(wrapFee);

        originalSafeBalance = originalSafeBalance.add(totalReceived);

        _mint(msg.sender, totalReceived);
        _mint(devAddr, wrapFee);

        emit Wrap(msg.sender, amount, wrapFee, totalReceived);
    }

    event Unwrap(
        address indexed wrapper,
        uint256 amount,
        uint256 unwrapFee,
        uint256 outputAmount
    );

    function unwrap(uint256 amount) public {
        uint256 unwrapFee = amount.mul(unwrapFeeRate).div(1000);
        uint256 remainingAmount = amount.sub(unwrapFee);
        uint256 outputAmount = getWrapRatio().mul(remainingAmount).div(1e18);

        _burn(msg.sender, amount);
        _mint(devAddr, unwrapFee);

        uint256 distributionTax = calculateDistributionTax(outputAmount);
        
        if (outputAmount >= originalSafeBalance) {
            originalSafeBalance = 0;
        } else {
            originalSafeBalance = originalSafeBalance.sub(outputAmount);
        }

        outputAmount = outputAmount.add(distributionTax);
        
        safeToken.transfer(msg.sender, outputAmount);

        emit Unwrap(msg.sender, amount, unwrapFee, outputAmount);
    }

    function getWrapRatio() public view returns (uint256 ratio) {
        if (totalSupply() == 0) return 1e18;

        uint256 safeBalance = safeToken.balanceOf(address(this));
        return safeBalance.mul(1e18).div(totalSupply());
    }

    function calculateDistributionTax(uint256 outputAmount)
        public
        view
        returns (uint256)
    {
        uint256 safeBalanceWithTax = safeToken.balanceOf(address(this));

        uint256 distributionTax = 0;
        if (safeBalanceWithTax > originalSafeBalance) {
            uint256 tax = safeBalanceWithTax.sub(originalSafeBalance);
            uint256 distributeRate = outputAmount.mul(100).div(
                originalSafeBalance
            );

            distributionTax = tax.mul(distributeRate).div(100);

            if (distributionTax > tax) {
                distributionTax = tax;
            }
        }

        return distributionTax;
    }
}