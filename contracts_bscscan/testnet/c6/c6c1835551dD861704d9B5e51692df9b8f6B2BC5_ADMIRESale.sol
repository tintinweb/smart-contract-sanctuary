pragma solidity ^0.5.0;



import './Context.sol';
import './Ownable.sol';
import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';
import './SafeERC20.sol';
import './ReentrancyGaurd.sol';
import './Pausable.sol';
import './Crowdsale.sol';
import './CappedCrowdsale.sol';


contract ADMIRESale is Crowdsale, CappedCrowdsale, Ownable, Pausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private tokenRate = 500;    // rate in TKNbits
    address payable private tokenWallet = 0xf9D50fF6f5766FdB65e5234F0EcFB86c959a1816;
    IERC20 private tokenAddress = IERC20(0x85968cBddf773a5305957E1e2956f0B7f8D66F08);
    address private returnAddress = 0xf9D50fF6f5766FdB65e5234F0EcFB86c959a1816;
    uint256 public investorMinCap = 100000000000000000;   
	uint256 public investorHardCap = 20000000000000000000;
    uint256 public _cap = 500000000000000000000;
    
    mapping(address => uint256) public contributions;
    // uint256 public newRateChange;    // rate in TKNbits

    constructor()
        Crowdsale(tokenRate, tokenWallet, tokenAddress)
        CappedCrowdsale(_cap)
        public
    {

    }

    function setRate(uint256 newRate) public onlyOwner {
        tokenRate = newRate;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(tokenRate);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view whenNotPaused {
       super._preValidatePurchase(beneficiary, weiAmount);
       uint256 _existingContribution = contributions[beneficiary];
       uint256 _newContribution = _existingContribution.add(weiAmount);
       require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
       require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
	    
    }

    function leftover(uint256 tokenAmount) public onlyOwner {
        tokenAddress.safeTransfer(returnAddress, tokenAmount);
    }
}