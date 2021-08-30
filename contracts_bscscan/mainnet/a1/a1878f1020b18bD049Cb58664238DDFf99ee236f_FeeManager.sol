//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract FeeManager is Ownable {

    using Address for address;
    using SafeMath for uint256;

    // fee denominator
    uint256 public feeDenominator = 100000;
    // swapper fees
    uint256 public swapperFee = 125;
    // Fee Receiver
    address payable public feeReceiver = payable(0x1e9c841A822D1D1c5764261ab5e26d4067Ca49D9);
    // Liquidity Provider
    address public liquidityProvider = 0x53442a56A7725c02d0C1827001CB677d30d50e62;
    // default fee for Token Bridge Crossing
    uint256 private defaultFee = 250;
    // specific fees for Token Bridge Crossing
    mapping ( address => uint256 ) tokenFees;

    function setFeeForToken(address token, uint256 fee) external onlyOwner {
        tokenFees[token] = fee;
    }

    function setSwapperFee(uint256 _swapperFee) external onlyOwner {
        require(_swapperFee <= feeDenominator.div(100), 'cannot have greater than 1% fees');
        swapperFee = _swapperFee;
    }

    function setDefaultFee(uint256 _defaultFee) external onlyOwner {
        require(_defaultFee <= 2500, 'must have under 2.5% fee');
        defaultFee = _defaultFee;
    }

    function setFeeReceiver(address payable newReceiver) external onlyOwner {
        feeReceiver = newReceiver;
    }

    function setLiquidityProvider(address newProvider) external onlyOwner {
        liquidityProvider = newProvider;
    }

    function getFeeForToken(address token) public view returns (uint256) {
        uint256 fee = tokenFees[token];
        return fee == 0 ? defaultFee : fee;
    }

    function calculateTokenFeeAmount(address token, uint256 amount) public view returns(uint256) {
        return amount.mul(getFeeForToken(token)).div(feeDenominator);
    }

    function getSwapperFee() public view returns (uint256) {
        return swapperFee;
    }

    function getFeeDenominator() public view returns (uint256) {
        return feeDenominator;
    }

    function getFeeReceiver() public view returns (address payable) {
        return feeReceiver;
    }

    function getLiquidityProvider() public view returns (address) {
        return liquidityProvider;
    }

    function calculateTaxAmount(uint256 amount) public view returns (uint256) {
        return amount.mul(swapperFee).div(feeDenominator);
    }

}