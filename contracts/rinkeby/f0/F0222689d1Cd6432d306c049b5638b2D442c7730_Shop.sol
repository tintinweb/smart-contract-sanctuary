pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT




import "./interfaces/IPerson.sol";

contract Shop {
    uint256 public price;
    address public person;

    constructor(uint256 _price) {
        price = _price;
    }

    fallback() external payable {}
    receive() external payable {}

    function buy(uint256 id, bytes memory data) external payable {
        require(msg.value > price, "Shop:: Invalid amount given");
        uint256 amount = msg.value / price;
        IPerson(person).mint(msg.sender, id, amount, data);
    }

    function setPersonAddress(address _person) public {
        person = _person;
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