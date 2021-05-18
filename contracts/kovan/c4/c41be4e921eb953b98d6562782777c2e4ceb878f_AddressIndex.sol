/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later

contract AddressIndex {

    address public owner;
    address buoy;
    address bPool;
    address uniswapToken;
    address balancerPool;
    address smartPool;
    address xBuoy;
    address governanceProxy;
    address mine;
    address lottery;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, 'Buoy AddressIndex: Not called by owner');
        _;
    }
    
    //pass ownership to govproxy when addresses set, onlyOwner modifier removed for testing
    function changeOwner(address newaddress) public  {
        owner = newaddress;
    }
    
    function setBuoy(address newaddress) public onlyOwner {
        buoy = newaddress;
    }
    
    function getBuoy() public view returns(address) {
        return(buoy);
    }

    function setUniswap(address newaddress) public onlyOwner {
        uniswapToken = newaddress;
    }
    
    function getUniswap() public view returns(address) {
        return(uniswapToken);
    }

    function setLottery(address newaddress) public onlyOwner {
        lottery = newaddress;
    }
    
    function getLottery() public view returns(address) {
        return(lottery);
    }

    //controller
    function setSmartPool(address newaddress) public onlyOwner {
        smartPool = newaddress;
    }
    
    function getSmartPool() public view returns(address) {
        return(smartPool);
    }
    
    //balancer pool, may not be needed
    function setBalancerPool(address newaddress) public onlyOwner {
        balancerPool = newaddress;
    }
    
    function getBalancerPool() public view returns(address) {
        return(balancerPool);
    }
    
    function setXBuoy(address newaddress) public onlyOwner {
        xBuoy = newaddress;
    }
    
    function getXBuoy() public view returns(address) {
        return(xBuoy);
    }
    
    function setGovernanceProxy(address newaddress) public onlyOwner {
        governanceProxy = newaddress;
    }
    
    function getGovernanceProxy() public view returns(address) {
        return(governanceProxy);
    }

    function setMine(address newaddress) public onlyOwner {
        mine = newaddress;
    }
    
    function getMine() public view returns(address) {
        return(mine);
    }
        

}