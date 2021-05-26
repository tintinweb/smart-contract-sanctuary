/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// Subset of ERC20, only the balanceOf view.
interface BalanceOf {
    function balanceOf(address) external view returns (uint256);
}
contract BalanceScaler is BalanceOf {
    BalanceOf public balanceContract; // Usually an ERC20
    uint32 public scalingFactor;
    address public governor = msg.sender;
    modifier onlyGovernor {
      require(msg.sender == governor);
      _;
    }
    
    constructor(BalanceOf _aContractThatImplementsBalanceOf, uint32 _scalingFactor) {
        balanceContract = _aContractThatImplementsBalanceOf;
        scalingFactor = _scalingFactor;
    }
    
    function balanceOf(address _beneficiary) external override view returns (uint256) {
        return scalingFactor * balanceContract.balanceOf(_beneficiary);
    }
    
    function setGovernor(address _newGovernor) external onlyGovernor {
        governor = _newGovernor;
    }
    
    function setBalanceContract(BalanceOf _newBalanceOfContract) external onlyGovernor {
        balanceContract = _newBalanceOfContract;
    }
    
    function setScalingFactor(uint32 _newScalingFactor) external onlyGovernor {
        scalingFactor = _newScalingFactor;
    }
}