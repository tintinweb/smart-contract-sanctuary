// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Proxy.sol";

contract LucaPorxy is Proxy {
    event Upgraded(address indexed impl);
    event AdminChanged(address preAdmin, address newAdmin);
    
    modifier onlyAmdin(){
        require(msg.sender == admin(), "LucaPorxy: Caller not admin");
        _;
    }
    
    function changeAdmin(address newAdmin) external onlyAmdin returns(bool) {
        _setAdmin(newAdmin);
        emit AdminChanged(admin(), newAdmin);
        return true;
    } 
    
    function upgrad(address newLogic) external onlyAmdin returns(bool) {
        _setLogic(newLogic);
        emit Upgraded(newLogic);
        return true;
    }

    constructor(address impl) {
        _setAdmin(msg.sender);
        _setLogic(impl);
    }
    
}