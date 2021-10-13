//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IVault.sol";

contract VaultWhaleBuyer {
    
    using Address for address;
    using SafeMath for uint256;

    // constants
    uint256 public constant unit = 10**18;
    uint256 public constant _denominator = 10**5;
    address constant vault = 0x92da405b6771c9Caa7988A41dd969a73d10A3cc6;
    
    // fees
    uint256 public _startingFee;
    uint256 public _minFee;
    uint256 public _reflectionPercentage;
    address public _distributor;

    // math
    uint256 public _factor;
    uint256 public _minBNB;
    
    // swaps
    bool public _swapEnabled;
    
    // ownership
    address _master;
    modifier onlyOwner(){require(msg.sender == _master, 'Invalid Entry'); _;}
    
    // events
    event BoughtAndReturnedVault(address to, uint256 amountVault);
    event UpdatedReflectionPercentage(uint256 newPercent);
    event UpdatedFactor(uint256 newFactor);
    event UpdatedMinBNB(uint256 newMin);
    event UpdatedMinimumFee(uint256 minFee);
    event UpdatedStartingFee(uint256 newStartingFee);
    event UpdatedDistributor(address newDistributor);
    event UpdatedSwapEnabled(bool swapEnabled);
    event TransferredOwnership(address newOwner);

    constructor() {
        // ownership
        _master = msg.sender;
        // state
        _swapEnabled = true;
        _minBNB = 10 * unit;
        _factor = 30;
        _startingFee = 5000;
        _reflectionPercentage = 60;
        _minFee = 0;
        _distributor = 0xb3Eff438e0ED127b0da9329EA84828171EDE93cD;
    }

    function buyVault() private {
        
        // calculate fees
        (uint256 _reflectionFee, uint256 _burnFee) = calculateFees(msg.value);
        
        // portion out amounts
        uint256 distributorAmount = msg.value.mul(_reflectionFee).div(_denominator);
        uint256 swapAmount = msg.value.sub(distributorAmount);
        
        // purchase vault
        uint256 vaultReceived = purchaseVault(swapAmount);
        
        // send bnb to distributor
        if (distributorAmount > 0) {
            (bool s2,) = payable(_distributor).call{value: distributorAmount}("");
            require(s2, 'Error On Distributor Payment');
        }
        
        // portion amount for sender
        uint256 burnAmount = vaultReceived.mul(_burnFee).div(_denominator);
        uint256 sendAmount = vaultReceived.sub(burnAmount);
        
        // transfer Vault To Sender
        bool success = IERC20(vault).transfer(msg.sender, sendAmount);
        require(success, 'Error on Vault Transfer');
        
        // delete remaining Vault Balance
        if (burnAmount > 0) {
            bool deletion = IVault(vault).deleteBag(burnAmount);
            require(deletion, 'Error Deleting Vault Bag');
        }
        emit BoughtAndReturnedVault(msg.sender, sendAmount);
    }
    
    function purchaseVault(uint256 amount) internal returns (uint256) {
        uint256 vaultBefore = IERC20(vault).balanceOf(address(this));
        (bool s,) = payable(vault).call{value: amount}("");
        require(s, 'Failure On Vault Purchase');
        return IERC20(vault).balanceOf(address(this)).sub(vaultBefore);
    }
    
    function calculateFees(uint256 amount) public view returns (uint256, uint256) {
        
        uint256 bVal = _factor.mul(amount).div(unit);
        if (bVal >= _startingFee) {
            return (_minFee,_minFee);
        }
        
        uint256 fee = _startingFee.sub(bVal).add(_minFee);
        uint256 rAlloc = _reflectionPercentage.mul(fee).div(10**2);
        return (rAlloc, fee.sub(rAlloc));
    }
    
    function updateReflectionPercentage(uint256 reflectionPercent) external onlyOwner {
        require(reflectionPercent <= 100);
        _reflectionPercentage = reflectionPercent;
        emit UpdatedReflectionPercentage(reflectionPercent);
    }
    
    function updateFactor(uint256 newFactor) external onlyOwner {
        _factor = newFactor;
        emit UpdatedFactor(newFactor);
    }
    
    function updateMinimumBNB(uint256 newMinimum) external onlyOwner {
        _minBNB = newMinimum;
        emit UpdatedMinBNB(newMinimum);
    }
    
    function updateStartingFee(uint256 newFee) external onlyOwner {
        _startingFee = newFee;
        emit UpdatedStartingFee(newFee);
    }
    
    function updateDistributorAddress(address newDistributor) external onlyOwner {
        _distributor = newDistributor;
        emit UpdatedDistributor(newDistributor);
    }
    
    function setSwapperEnabled(bool isEnabled) external onlyOwner {
        _swapEnabled = isEnabled;
        emit UpdatedSwapEnabled(isEnabled);
    }
    
    function setMinFee(uint256 minFee) external onlyOwner {
        _minFee = minFee;
        emit UpdatedMinimumFee(minFee);
    }

    function withdrawBNB(uint256 percent) external onlyOwner returns (bool s) {
        uint256 am = address(this).balance.mul(percent).div(10**2);
        require(am > 0);
        (s,) = payable(_master).call{value: am}("");
    }

    function withdrawToken(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(_master, bal);
    }

    function transferOwnership(address newMaster) external onlyOwner {
        _master = newMaster;
        emit TransferredOwnership(newMaster);
    }
    
    receive() external payable {
        require(_swapEnabled, 'Swapper Is Disabled');
        require(msg.value >= _minBNB, 'Purchase Value Too Small');
        buyVault();
    }
}