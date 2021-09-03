//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

// Imported OZ helper contracts
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Address.sol";

import "./SafeMath.sol";

// TODO rename to Lottery when done
contract Stake {
    // Libraries 
    // Safe math
    using SafeMath for uint256;

    // Safe ERC20
    using SafeERC20 for IERC20;

    // State variables 
    // Instance of Cake token (collateral currency for lotto)
    IERC20 internal weth;

    // number of sales
    uint256 public nSales;
    
    //all gains made by buyers
    uint256 private tGains;
    
    //owner to protect contract
    address private owner;
    
    //only allow claims after inputing sales
    bool internal lock;
    
     
    // Storage for Sale info
    struct Sale {
        uint256 id;
        uint256 value;
        address buyer;
    }
    
    
    // uint256 => bool ownerDevs
    mapping(uint256 => Sale) internal orderBuyers;
    
    
     // adddress => bool ownerDevs
    mapping(address => uint256) internal balance;
    
    // adddress => bool ownerDevs
    mapping(address => uint256) internal allTimeGains;
    
    //only onwer can change the lock to true
    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    
    constructor(address wth){
        owner = msg.sender;
        nSales = 0;
        lock = false;
        weth = IERC20(wth);
    }
    
    
    
    function addSaleOne(uint256 value, address buyer) external onlyOwner() {
        
        require(orderBuyers[nSales + 1].buyer == address(0), "Order already submited");
        require(nSales == 0, "sale is over 1");
        nSales++;
        orderBuyers[nSales] = Sale(nSales, value, buyer);
        
        
    }
    
    function addSale(uint256 value, address buyer) external onlyOwner() {
        
        require(orderBuyers[nSales + 1].buyer == address(0), "Order already submited");
        require(nSales > 0, "sale needs to be over 1");
        nSales++;
        addReward(value);
        orderBuyers[nSales] = Sale(nSales, value, buyer);
        
    }
    
    function addReward(uint256 rw) internal{
        
        uint256 nS = nSales.sub(1);
        
        uint256 rewardPercentage = rw.mul(4375).div(10000).div(nS);
        
        for (uint8 i = 1; i < nSales; i++) {
            
             address by = orderBuyers[i].buyer;
             balance[by] = balance[by].add(rewardPercentage);
             allTimeGains[by] = allTimeGains[by].add(rewardPercentage);
             tGains = tGains.add(rewardPercentage);
            
        }
    }
    
    function claim() public{
        require(lock, "funds not available");
        uint256 money = balance[msg.sender];
        balance[msg.sender] = 0;
        weth.safeTransfer(address(msg.sender), money);
        
    }
    
    function getBalancing(address owning) public view returns(uint256){
        return balance[owning];
    }
    
    function getAllTimeGains(address owning) public view returns(uint256){
        return allTimeGains[owning];
    }
    
    function totoalGains() public view returns(uint256){
        return tGains;
    }
    
    function unlocking() public onlyOwner(){
        lock = true;
    }
    
    function lockTheGate() public onlyOwner(){
        lock = false;
    }
    
  
    
}