// SPDX-License-Identifier: CC BY 3.0 US
// AND PDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Context.sol';
import './Ownable.sol';
import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';
import './SafeERC20.sol';
import './ReentrancyGuard.sol';
import './Pausable.sol';
import './Crowdsale.sol';
// Not a minted sale, the hard cap is how many tokens sent to the contract
// import './CappedCrowdsale.sol';


contract GroguSale is Crowdsale, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private tokenRate = 500;    // rate in TKNbits
    address payable private tokenWallet = 0x13A6BB08350E321f66a19D238E774e1b870D9123;
    IERC20 public tokenAddress = IERC20(0x9BF44d9e8D9Ae56197068eAB2d2c0572996C3ef7);
    address private returnAddress = 0x13A6BB08350E321f66a19D238E774e1b870D9123;
    // investorMinCap is 0.01 below, mind your decimals
    uint256 public investorMinCap = 9900000000000000;
    // Individual cap is 20 below, mind your decimals!
	uint256 public investorHardCap = 20000000000000000001;
    // uint256 public _cap = 500000000000000000000;
    
    mapping(address => uint256) public contributions;
    // uint256 public newRateChange;    // rate in TKNbits

    constructor()
        Crowdsale(tokenRate, tokenWallet, tokenAddress)
       // CappedCrowdsale(_cap)
        public
    {

    }

    function setRate(uint256 newRate) public onlyOwner {
        tokenRate = newRate;
    }

    function setinvestorMinCap(uint256 newMinCap) public onlyOwner {
        investorMinCap = newMinCap;
    }

    function setinvestorHardCap(uint256 newHardCap) public onlyOwner {
        investorHardCap = newHardCap;
    }

    /**
     * @return the address where funds are collected.
     */
    function viewDepositWallet() public view returns (address payable) {
        return tokenWallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function viewCurrentRate() public view returns (uint256) {
        return tokenRate;
    }

    /**
     * @return the minimum buy amount. Mind your decimals.
     */
    function viewCurrentCapMin() public view returns (uint256) {
        return investorMinCap;
    }

    /**
     * @return the minimum buy amount. Mind your decimals.
     */
    function viewCurrentCapMax() public view returns (uint256) {
        return investorHardCap;
    }

    function _getTokenAmount(uint256 weiAmount) internal override view returns (uint256) {
        return weiAmount.mul(tokenRate);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override view whenNotPaused {
       super._preValidatePurchase(beneficiary, weiAmount);
       uint256 _existingContribution = contributions[beneficiary];
       uint256 _newContribution = _existingContribution.add(weiAmount);
       // require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
       require(_newContribution >= investorMinCap, "Individual Min Not Met");
       require(_newContribution <= investorHardCap, "Individual Cap Exceeded");
      // require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
	    
    }

    function withdrawOtherTokensSentHere(IERC20 token, uint256 tokenAmount) public onlyOwner {
        token.safeTransfer(returnAddress, tokenAmount);
    }


    function leftover(uint256 tokenAmount) public onlyOwner {
        tokenAmount = tokenAmount.mul(1000000000000000000);
        tokenAddress.safeTransfer(returnAddress, tokenAmount);
    }
}