/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface Ifactory{
    function addToken(address _token, uint256 _min) external;
    function updateTokenConfig(string  memory _symbol, address _token, uint256 _min)  external;
}

contract Initialize {
    bool private initialized;
    
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Owner {
    address public owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "only owner");
        _;
    }
    
    function setOwner(address addr) external onlyOwner{
        owner = addr;
    }
}

contract File is Owner, Initialize {
    //atm default token
    address public luca;
    address public wluca;
    address public agt;
    address public weth;
    
    //atm module contract
    address public factory;
    address public trader;
    address public pledger;
    address public linkTemp;
    
    //factory setings
    bool    public active; 
    uint256 public minLockDay;
    uint256 public maxLockDay;
    // uint256 public minFine;
    // uint256 public maxFine;
    
    //link steings 
    address public collector;
    
    function initialize(address _luca, address _wluca,  address _agt, address _weth, address _factory, address _trader, address _linkTemp, address _pledger, address _collector) external noInit {
        (luca, wluca, agt, weth) = (_luca, _wluca, _agt, _weth);
        (factory, trader, linkTemp) = (_factory, _trader, _linkTemp);
        (pledger, collector) = (_pledger, _collector);
        owner = msg.sender;
        active = true;
    }
    
    //token seting
    function fileToken(bytes32 item, address addr) external onlyOwner{
        if (item == "luca") luca = addr;
        else if (item == "wluca") wluca = addr;
        else if (item == "agt") agt = addr;
        else if (item == "weth") weth = addr;
        else revert("not this token");
    }
    
    //module setings 
    function fileModule(bytes32 item, address addr) external onlyOwner{
        if (item == "factory") factory = addr;
        else if (item == "trader") trader = addr;
        else if (item == "pledger") pledger = addr;
        else if (item == "linkTemp") linkTemp = addr;
        else revert("not this module");
    }
    
    function fileLockDay(uint256 min, uint256 max) external onlyOwner{
        require(max > min);
        minLockDay = min;
        maxLockDay = max;
    }

    function linkLoad() external view returns (address, address, address, address, address){
        return (luca, wluca, weth, trader, pledger);
    }
    
    function factoryLoad() external view returns (address, address, address, uint256, uint256){
        return (luca, weth, trader, minLockDay, maxLockDay);
    }
    
    function setCollector(address addr) external onlyOwner {
        collector = addr;
    }
    
    //emergency shutdown
    function shutdown() external onlyOwner{
        active = false;
    }
    
    function restart() external onlyOwner{
        active = true;
    }
    
    function addToken(address addr, uint256 min) external onlyOwner{
        Ifactory(factory).addToken(addr, min);
    }
    
    function updateTokenConfig(string memory symbol, address addr, uint256 min) external onlyOwner{
        Ifactory(factory).updateTokenConfig(symbol, addr, min);
    }
}