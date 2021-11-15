// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract NFTSaleOpenEdition {
    using SafeMath for uint256;

    uint256 public price;
    uint256 public start;
    uint256 public endTime;
    uint256 public hausFeePercentage;
    bool public ended = false;

    address payable public haus;
    address payable public seller;
    address public controller;

    uint256 public buyCount = 0;
    mapping (address => uint256) public buyerToBuyCount;
    
    event Buy(address buyer, uint256 amount);
    
    constructor(
        uint256 _startTime,
        uint256 _priceWei,
        uint8 _hausFeePercentage,
        address _sellerAddress,
        address _hausAddress,
        address _controllerAddress
    ) public {
        start = _startTime;
        price = _priceWei;
        endTime = _startTime + 24 hours;
        seller = payable(_sellerAddress);
        haus = payable(_hausAddress);
        hausFeePercentage = _hausFeePercentage;
        controller = _controllerAddress;
    }
    
    function buy(uint256 amount) public payable {
        require(ended == false, "Open Edition has been ended");
        require(isClosed() == false, "Open Edition has closed");
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= start, "early");
        require(msg.value == price.mul(amount), "wrong amount");
        uint256 balance = address(this).balance;
        uint256 hausFee = balance.div(100).mul(hausFeePercentage);
        haus.transfer(hausFee);
        seller.transfer(address(this).balance);
        buyCount += amount;
        buyerToBuyCount[msg.sender] += amount;
        emit Buy(msg.sender, amount);
    }

    function setEnded(bool setting) public onlyController {
        ended = setting;
    }

    function isClosed() public view returns (bool) {
        return ended || block.timestamp >= endTime;
    }

    function getBuyerQuantity(address _buyer) public view returns (uint256) {
        return buyerToBuyCount[_buyer];
    }

    modifier onlyController {
      require(msg.sender == controller);
      _;
    }
}

