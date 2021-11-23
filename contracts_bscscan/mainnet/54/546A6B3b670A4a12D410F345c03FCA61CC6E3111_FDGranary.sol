// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
import "./Context.sol";
import "./Ownable.sol";
import "./IFDGranary.sol";
import "./IBEP20.sol";

contract FDGranary is Context, IFDGranary, Ownable {
    
    address public farmerAddress;
    string public name;
    constructor () {
        name = "FDPool";
    }
    event UpdatedFarmerAddressAddress(address account);
    receive() external payable {}

    function setFarmerAddress(address account) external onlyOwner{
        farmerAddress = account;
        emit UpdatedFarmerAddressAddress(account);
    }
    function claimBNB(address account, uint256 amount) external override {
        require(_msgSender() == farmerAddress, "You are not allowed to call this function");
        require(amount <= address(this).balance, "Amount is exceeded");
        (bool success, ) = payable(account).call{value: amount}("");
        require(success == true, "Transfer failed.");
    }
}