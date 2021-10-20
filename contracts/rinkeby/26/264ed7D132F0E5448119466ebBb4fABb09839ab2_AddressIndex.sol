/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later

contract AddressIndex {

    address public owner;
    address buoy;
    address bPool;
    address uniswapToken;
    address votingBooth;
    address smartPool;
    address xBuoy;
    address proxy;
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
    
    function setVotingBooth(address newaddress) public onlyOwner {
        votingBooth = newaddress;
    }
    
    function getVotingBooth() public view returns(address) {
        return(votingBooth);
    }
    
    function setXBuoy(address newaddress) public onlyOwner {
        xBuoy = newaddress;
    }
    
    function getXBuoy() public view returns(address) {
        return(xBuoy);
    }
    
    function setProxy(address newaddress) public onlyOwner {
        proxy = newaddress;
    }
    
    function getProxy() public view returns(address) {
        return(proxy);
    }

    function setMine(address newaddress) public onlyOwner {
        mine = newaddress;
    }
    
    function getMine() public view returns(address) {
        return(mine);
    }
        

}