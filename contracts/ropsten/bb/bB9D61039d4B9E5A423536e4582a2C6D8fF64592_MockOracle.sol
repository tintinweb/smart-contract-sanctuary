pragma solidity ^0.6.0;

import "../interfaces/IPriceFeed.sol";

contract MockOracle is IPriceFeed {
    uint public price;

    function setPrice(uint _price) public {
        price = _price;
    }

    function getPrice() external override view returns(uint) {
        return price;
    }
}

pragma solidity ^0.6.0;

interface IPriceFeed {
    function getPrice() external view returns(uint);
}

