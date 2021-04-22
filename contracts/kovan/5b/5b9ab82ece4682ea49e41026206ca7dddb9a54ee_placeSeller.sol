/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.7.4;

contract placeSeller {
    address payable _owner;
    uint8 _places;
    mapping (uint8 => uint128) private _prices; // price in wei
    mapping (uint8 => string) private _placeText;

    constructor () {
        _owner = msg.sender;
        _places = 0;
    }

    function createPlace(uint8 count, uint128 price) public {
        require(msg.sender == _owner);
        require(count > 0);
        require((_places + count) < 256); // 256 = 2 ^ 8

        for (uint8 i = 0; i < count; i++) {
            _places++;
            _prices[_places] = price;
        }
    }

    function isFree(uint8 place) public view returns (bool) {
        return _prices[place] > 0; // && (_placeText[place].length == 0);
    }

    function buy(uint8 place, string memory text) public payable {
        require(place <= _places);
        require(bytes(text).length > 0);
        require(bytes(_placeText[place]).length == 0);
        require(msg.value >= _prices[place]);

        _placeText[place] = text;
    }

    function withdraw(uint256 amount) public {
        _owner.transfer(amount);
    }
}