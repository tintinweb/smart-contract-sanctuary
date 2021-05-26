/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// Subset of ERC20, only the balanceOf view.
interface IERC20View {
    function balanceOf(address) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract BalanceScaler is IERC20View {
    IERC20View public balanceContract; // Usually an ERC20
    uint32 public scalingFactor;
    address public governor = msg.sender;
    
    modifier onlyGovernor {
      require(msg.sender == governor);
      _;
    }
    
    constructor(IERC20View _aContractThatImplementsBalanceOf, uint32 _scalingFactor) {
        balanceContract = _aContractThatImplementsBalanceOf;
        scalingFactor = _scalingFactor;
    }
    
    function balanceOf(address _beneficiary) external override view returns (uint256) {
        return scalingFactor * balanceContract.balanceOf(_beneficiary);
    }
    
     function name() external override view returns (string memory)  {
        return balanceContract.name();
    }
    
     function symbol() external override view returns (string memory) {
        return balanceContract.symbol();
    }
    
     function totalSupply() external override view returns (uint256) {
      return balanceContract.totalSupply();
    }
    
     function decimals() external override view returns (uint8) {
        return balanceContract.decimals();
    }
    
    function setGovernor(address _newGovernor) external onlyGovernor {
        governor = _newGovernor;
    }
    
    function setBalanceContract(IERC20View _newBalanceOfContract) external onlyGovernor {
        balanceContract = _newBalanceOfContract;
    }
    
    function setScalingFactor(uint32 _newScalingFactor) external onlyGovernor {
        scalingFactor = _newScalingFactor;
    }
}