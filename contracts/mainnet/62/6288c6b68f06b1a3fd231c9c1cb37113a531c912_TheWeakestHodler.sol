pragma solidity ^0.4.25;

//
// https://github.com/TheWeakestHodler/TheWeakestHodler
//
// HODL UNTIL YOU ARE HOMELESS
//
contract TheWeakestHodler {
    using SafeMath for uint256;

    uint256 constant public percentsRemaining = 90;
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    
    function () public payable {
        if (msg.value > 0) {
            if (totalShares == 0) {
                uint256 amount = msg.value;
            } else {
                amount = msg.value.mul(totalShares).div(address(this).balance.sub(msg.value));
            }
            shares[msg.sender] = shares[msg.sender].add(amount);
            totalShares = totalShares.add(amount);
        } else {
            amount = balanceOf(msg.sender);
            totalShares = totalShares.sub(shares[msg.sender]);
            shares[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    function balanceOf(address _account) public view returns(uint256) {
        if (totalShares == 0) {
            return 0;
        }
        return address(this).balance.mul(shares[_account]).mul(percentsRemaining).div(totalShares).div(100);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}