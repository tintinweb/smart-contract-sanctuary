// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

// should import zepplin and use nft token
contract MetaCoin {
    enum ProductType {book, music, art}
    struct ProductItem {
        uint256 price;
        string name;
        uint256 count;
    }

    struct UserAccount {
        string name;
        uint256 balance;
        mapping(uint256 => uint256) itemList;
    }

    address owner;

    event Sell(address indexed _to, uint256 productType, uint256 _count);

    mapping(uint256 => ProductItem) productList;
    mapping(address => UserAccount) userList;

    constructor() public {
        productList[0].price = 1000000000000000;
        productList[0].name = "Music Album";
        productList[0].count = 10000;

        productList[1].price = 2000000000000000;
        productList[1].name = "Art Album";
        productList[1].count = 5000;

        productList[2].price = 3000000000000000;
        productList[2].name = "Novel Book";
        productList[2].count = 8000;

        owner = msg.sender;
    }

    function getProductList(uint256 productIndex)
        public
        view
        returns (uint256)
    {
        return productList[productIndex].count;
    }

    function BuyItems(uint256 productType, uint256 amount)
        public
        returns (bool sufficient)
    {
        require(
            userList[msg.sender].balance <
                amount * productList[productType].price,
            "Not enough balance"
        );
        require(productList[productType].count > amount, "Not enough products");

        userList[msg.sender].balance -= amount * productList[productType].price;
        userList[msg.sender].itemList[productType] += amount;
        productList[productType].count -= amount;

        emit Sell(msg.sender, productType, amount);
        return true;
    }

    // function getBalanceOfUser() public view returns (uint256) {
    //     return balanceOf(msg.sender);
    // }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}