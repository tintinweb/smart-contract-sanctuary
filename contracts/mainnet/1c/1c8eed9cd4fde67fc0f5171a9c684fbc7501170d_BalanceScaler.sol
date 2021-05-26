/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// Subset of ERC20, only view functions.
interface IERC20View {
    function balanceOf(address) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract BalanceScaler is IERC20View {
    IERC20View public erc20; 
    uint32 public scalingFactor;
    address public governor = msg.sender;
    
    modifier onlyGovernor {
      require(msg.sender == governor);
      _;
    }
    
    constructor(IERC20View _erc20, uint32 _scalingFactor) {
        erc20 = _erc20;
        scalingFactor = _scalingFactor;
    }
    
    function balanceOf(address _beneficiary) external override view returns (uint256) {
        return scalingFactor * erc20.balanceOf(_beneficiary);
    }
    
    function name() external override view returns (string memory)  {
        return erc20.name();
    }
    
    function symbol() external override view returns (string memory) {
        return erc20.symbol();
    }
    
    function totalSupply() external override view returns (uint256) {
      return erc20.totalSupply();
    }
    
    function decimals() external override view returns (uint8) {
        return erc20.decimals();
    }
    
    function setGovernor(address _newGovernor) external onlyGovernor {
        governor = _newGovernor;
    }
    
    function setERC20(IERC20View _newERC20) external onlyGovernor {
        erc20 = _newERC20;
    }
    
    function setScalingFactor(uint32 _newScalingFactor) external onlyGovernor {
        scalingFactor = _newScalingFactor;
    }
}