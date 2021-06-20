/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity 0.8.0;


// TODO: Need to create restrictions on functions.

contract warehouse  {
    

uint256 public price = 1 * 10**18;
address public _receiver = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

   struct Stock {
        uint256 units;
        string name;
    }

    // An array of 'Todo' structs
    Stock[] public stock;

    function create(string memory _name, uint256 _units) public {
        // key value mapping
        stock.push(Stock({
            units: _units,
            name: _name
        }));

    }
    
     receive() external payable {}
    
    
        // Send Ether to another address.
    function reOrder(uint256 _itemid) public returns (bool) {
        if (stock[_itemid].units == 0) {
            payable(_receiver).transfer(price/2);
            return true;
        }
        
    }
    
    function deliver(uint _itemid, uint amount, uint _hoursofdelivery) public {
        Stock storage stock = stock[_itemid];
        if (amount == 100) {
        stock.units = amount;
        
        
        // reduced 10% from 1 ETH due to delay
        if (_hoursofdelivery >= 72) {
         uint payment = (price / 2) - (1 * 10**17);
        payable(_receiver).transfer(payment);
        }
        
        // Full ammount. Delivered within acceptable timeframe.
        if (_hoursofdelivery <= 72) {
        uint payment = (price / 2);
        payable(_receiver).transfer(payment);
        }
        
        // 10% bonus for fast delivery
        if (_hoursofdelivery < 24) {
        uint bonus = 1 * 10**17; 
        payable(_receiver).transfer(bonus);
        }
        
        }
        
        }
        
    
}