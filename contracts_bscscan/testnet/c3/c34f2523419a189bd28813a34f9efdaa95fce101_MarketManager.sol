// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

contract MarketManager is Ownable {
    
    address private adminAddress;
    address private tokenAddress;
    
    constructor(address _adminAddress, address _tokenAddress) {
        adminAddress = _adminAddress;
        tokenAddress = _tokenAddress;
    }
    
    modifier onlyAdmin {
        require(msg.sender == adminAddress, "need_admin_permission");
        _;
    }
    
    function setAdminAddress(address _newAdminAddress) external onlyOwner {
        adminAddress = _newAdminAddress;
    }
    
    function setTokenAddress(address _tokenAddress) external onlyAdmin {
        tokenAddress = _tokenAddress;
    }
    
    function getMarketManagerBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function withdrawBalance(address _to, uint256 _amount) external onlyAdmin returns(bool) {
        return IERC20(tokenAddress).transfer(_to, _amount);
    }
    
    function withdrawAllBalance(address _to) external onlyAdmin returns(bool) {
        uint256 marketManagerBalance = getMarketManagerBalance();
        return IERC20(tokenAddress).transfer(_to, marketManagerBalance);
    }
    
    function transferToMarketManager(address _from, uint256 _amount) external onlyAdmin returns(bool) {
        return IERC20(tokenAddress).transferFrom(_from, address(this), _amount);
    }
    
    
}