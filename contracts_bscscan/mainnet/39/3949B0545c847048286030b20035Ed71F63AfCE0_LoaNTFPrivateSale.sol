/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract LoaNTFPrivateSale {
    uint256 private constant sixteen_decimals_value = 10_000_000_000_000_000;

    // Item 1 = Immortal Skin
    // Item 2 = Genesis Capsule
    // Item 3 = Alpha Capsule
    // Item 4 = Beta Capsule

    uint256 public _itemDateFrom;
    uint256 public _itemDateTo;

    mapping(uint256 => string) public _itemDescription; // item => description
    mapping(uint256 => uint256) public _itemTotalSupply; // item => totalSupply
    mapping(uint256 => uint256) public _itemPrice; // item => price
    mapping(uint256 => mapping(address => uint256)) public _itemOwned; // item => address => qty

    address public _admin; // Admin address

    constructor() {
        _admin = msg.sender;

        _itemDescription[0] = "Immortal Skin";
        _itemDescription[1] = "Genesis Capsule";
        _itemDescription[2] = "Alpha Capsule";
        _itemDescription[3] = "Beta Capsule";

        _itemTotalSupply[0] = 40;
        _itemTotalSupply[1] = 1_200;
        _itemTotalSupply[2] = 8_000;
        _itemTotalSupply[3] = 80_000;

        _itemPrice[0] = 16 * 100 * sixteen_decimals_value; // 16
        _itemPrice[1] = 16 * 10 * sixteen_decimals_value; // 1.6
        _itemPrice[2] = 5 * 10 * sixteen_decimals_value; // 0.5
        _itemPrice[3] = 5 * sixteen_decimals_value; // 0.05

        _itemDateFrom = 1_638_316_800; // 1/12/2021
        _itemDateTo = 1_638_403_200; // 2/12/2021
    }

    // Modifier
    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    // Transfer ownership
    function transferOwnership(address payable admin) external onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }

    function buyImmortalSkin(uint256 qty) external payable {
        return _buyItem(0, qty);
    }

    function buyGenesisCapture(uint256 qty) external payable {
        return _buyItem(1, qty);
    }

    function buyAlphaCapture(uint256 qty) external payable {
        return _buyItem(2, qty);
    }

    function buyBetaCapture(uint256 qty) external payable {
        return _buyItem(3, qty);
    }

    function _buyItem(uint256 item, uint256 qty) internal {
        // require(item <= 3, 'Item should be 0, 1, 2 or 3');
        // require(qty > 0, 'Qty should be greater than 0');
        require(block.timestamp >= _itemDateFrom, "Date has not yet started");
        require(block.timestamp <= _itemDateTo, "Date has ended");
        require(qty <= _itemTotalSupply[item], "Not enough supply to buy");
        require(
            _itemPrice[item] * qty == msg.value,
            "Deposited amount should be the multiplier of qty"
        );
        _itemOwned[item][msg.sender] = _itemOwned[item][msg.sender] + qty;
        _itemTotalSupply[item] = _itemTotalSupply[item] - qty;
    }

    // Allow admin to withdraw all the deposited BNB
    function withdrawAll() external onlyAdmin {
        payable(_admin).transfer(address(this).balance);
    }

    // Reject all direct deposit
    receive() external payable {
        revert();
    }
}