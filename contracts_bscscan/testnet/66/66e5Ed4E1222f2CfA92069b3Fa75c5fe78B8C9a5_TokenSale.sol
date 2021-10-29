/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBEP20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract TokenSale {
    using SafeMath for uint256;
    
    IBEP20Token public hotFriesCoin; 
    address owner;
    uint256 public constant PRICE_PER_TOKEN=0.006*10**18;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

   constructor(IBEP20Token _hotFriesCoin)  {
        owner = msg.sender;
        hotFriesCoin = _hotFriesCoin;
   }

    function buyTokens(uint256 _numberOfTokens) public payable {
        uint256 priceCalculated=PRICE_PER_TOKEN.mul(_numberOfTokens);
        require(msg.value>=priceCalculated,"Not enough Amount of BNB!");
        
        require(hotFriesCoin.balanceOf(address(this)) >= _numberOfTokens);
        hotFriesCoin.transfer(msg.sender,_numberOfTokens*10**18);
        
        tokensSold =tokensSold.add(_numberOfTokens*10**18);
        emit Sold(msg.sender, _numberOfTokens*10**18);
       
    }
    
    function endSale()public{
        require(msg.sender==owner,"You're not authorized!");
        hotFriesCoin.transfer(owner,hotFriesCoin.balanceOf(address(this)));
        
        payable(owner).transfer(address(this).balance);
    }
    
    function checkPriceForTokens(uint256 _numberOfTokens) public pure returns(uint256){
        return PRICE_PER_TOKEN.mul(_numberOfTokens);
    }
    

}