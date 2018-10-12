pragma solidity ^0.4.24;

contract CuteCoinPriceOracle {

    mapping (address => bool) admins;

    // How much Tokens you get for 1 ETH, multiplied by 10^18
    uint256 public ETHPrice = 1000 ether;

    event PriceChanged(uint256 newPrice);

    constructor() public {
        admins[msg.sender] = true;
    }

    function updatePrice(uint256 _newPrice) public {
        require(_newPrice > 0);
        require(admins[msg.sender] == true);
        ETHPrice = _newPrice;
        emit PriceChanged(_newPrice);
    }

    function setAdmin(address _newAdmin, bool _value) public {
        require(admins[msg.sender] == true);
        admins[_newAdmin] = _value;
    }
}