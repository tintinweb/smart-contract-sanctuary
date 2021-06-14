pragma solidity ^0.8.1;

// SPDX-License-Identifier: Unlicensed

import "./IMaster.sol";
import "./TransferHelper.sol";

contract MasterProxy {
    IMaster master;
    address deployer;

    modifier onlyAdmin {
        require(master.isAdmin(msg.sender) || deployer == msg.sender, "no admin");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setMaster(address _master) external {
        master = IMaster(_master);
    }

    function setToken(address _token) external onlyAdmin {
        master.setToken(_token);
    }

    function setUncl(address _uncl) external onlyAdmin {
        master.setUncl(_uncl);
    }

    function setPresale(address _presale) external onlyAdmin {
        master.setPresale(_presale);
    }

    function addSlave(address _slave) external onlyAdmin {
        master.addSlave(_slave);
    }

    function removeSlave(address _slave) external onlyAdmin {
        master.removeSlave(_slave);
    }

    function setPresaleAmount(uint256 _presaleAmount) external onlyAdmin {
        master.setPresaleAmount(_presaleAmount);
    }

    function execute() external onlyAdmin {
        master.execute();
    }

    function massWithdrawFromPresale() external onlyAdmin {
        master.massWithdrawFromPresale();
    }

    function massWithdrawFromPresaleAndSendToMaster() external onlyAdmin {
        master.massWithdrawFromPresaleAndSendToMaster();
    }

    function getUncl() external view returns (address) {
        return master.getUncl();
    }

    function getToken() external view returns (address) {
        return master.getToken();
    }

    function getPresale() external view returns(address) {
        return master.getPresale();
    }

    function getPresaleAmount() external view returns (uint256) {
        return master.getPresaleAmount();
    }

    function withdrawErc(address _token, address _recipient, uint256 _value) external onlyAdmin {
        master.withdrawErc(_token, _recipient, _value);
    }
    function withdrawETH(address _recipient, uint256 _value) external onlyAdmin {
        master.withdrawETH(_recipient, _value);
    }

    function isAdmin(address _address) external view returns (bool) {
        return master.isAdmin(_address);
    }

    function editAdmin(address _adminAddy, bool _isAdmin)  external onlyAdmin {
        master.editAdmin(_adminAddy, _isAdmin);
    }

    function createSlave() external onlyAdmin returns (address) {
        return master.createSlave();
    }

    receive() external payable {
        address(master).call{value: msg.value, gas: 5000}("");
    }

    function divideBNBOverSlaves() external payable onlyAdmin {
        master.divideBNBOverSlaves{value: msg.value}();
    }


    function getSlaves() external view returns (address[] memory) {
        return master.getSlaves();
    }

    function withdrawErcFromProxy(address _token, address _recipient, uint256 _value) external onlyAdmin {
        TransferHelper.safeApprove(_token, _recipient, _value);
        TransferHelper.safeTransfer(_token, _recipient, _value);
    }

    function withdrawETHFromProxy(address _recipient, uint256 _value) external onlyAdmin {
        TransferHelper.safeTransferETH(_recipient, _value);
    }

    function massWithdrawBNBFromSlaves() external onlyAdmin {
        master.massWithdrawBNBFromSlaves();
    }
}