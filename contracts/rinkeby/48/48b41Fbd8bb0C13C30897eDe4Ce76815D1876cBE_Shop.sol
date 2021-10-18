pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT




import "./interfaces/IPerson.sol";

contract Shop {
    uint256 public price;
    address public person;

    constructor(uint256 _price, address _person) {
        price = _price;
        person = _person;
    }

    receive() external payable {}

    fallback() external payable {}
    
    function buy(uint256 id, bytes memory data) external payable {
        require(msg.value > price, "Shop:: Invalid amount given");
        IPerson(person).mint(msg.sender, id, msg.value / price, data);
    }

}

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT



interface IPerson {

    function mint(
        address,
        uint256,
        uint256,
        bytes memory
    ) external;
}