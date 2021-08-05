/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

}

interface Token {
    function tokensSoldPreSale(address buyer, uint256 amount) external  returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function burn(uint256 _value) external returns (bool success);
}

contract UtrinPreSale is Ownable{
    
    using SafeMath for uint256;
    

    uint256 public priceFactor;
    uint256 public totalSold;
    address public tokenAddress;
    uint256 public startTime =  1610708400;                                     //GMT Friday 15 January 2021 11:00:00
    uint256 public endTime =    1611053940;                                     //GMT Tuesday 19 January 2021 10:59:00
    

    uint256 public minimumBuyAmount = 100 ** 17;                                //Set to 1 ETH.
    uint256 public maximumBuyAmount = 3000 ** 17;                               //Set to 30 ETH.
    address payable public walletAddress;
    event TokensSold(address indexed to, uint256 amount);
    
    constructor() {
        priceFactor = uint256(3350);                                            //1 ETH = 3350 Utrin.   
        walletAddress = 0x22bAF3bF140928201962dD1a01A63EE158BcC616;             
        tokenAddress = address(0x0);
    }
    
    receive() external payable {
        buy();
    }
    
    function setToken(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }
    
    function buy() public payable {
        require((block.timestamp > startTime ) && (block.timestamp < endTime)  , "UTRIN Token presale is not active");
        
        uint256 weiValue = msg.value;
        require(weiValue >= minimumBuyAmount, "Minimum amount to participate is 1 ETH.");
        require(weiValue <= maximumBuyAmount, "Maximum amount to participate is 30 ETH.");
        uint256 amount = weiValue.mul(priceFactor);
        Token token = Token(tokenAddress);
        require(walletAddress.send(weiValue));
        require(token.tokensSoldPreSale(msg.sender, amount));
        totalSold += amount;
        emit TokensSold(msg.sender, amount);
    }
    

    function burnUnsold() onlyOwner public {
        require((block.timestamp > endTime), "UTRIN Token presale is still active");
        Token token = Token(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);
    }
    
}