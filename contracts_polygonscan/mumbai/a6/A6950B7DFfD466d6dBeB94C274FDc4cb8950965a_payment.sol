// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./IPayment.sol"; 

contract payment is IPayment {
    address private _admin;
    mapping(uint8 => address) private _addresses;

    constructor(address admin) {
        _admin = admin;
    }

    function getPaymentToken(uint8 pt)
        external
        view
        override
        returns (address)
    {
        return _addresses[pt];
    }

    /**
     * @dev set ERC-20 token to be used as payment currency
     * in vRent contract
    */
    function setPaymentToken(uint8 index, address currencyAddress) external override {
        require(index != 0, "vRent::cant set sentinel");
        require(
            _addresses[index] == address(0),
            "vRent::cannot reset the address"
        );
        require(msg.sender == _admin, "vRent::only admin");
        _addresses[index] = currencyAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IPayment {
    enum PaymentToken {SENTINEL, WETH, DAI, USDC, USDT, TUSD, RENT}

    function getPaymentToken(uint8 index) external view returns (address);

    function setPaymentToken(uint8 index, address currencyAddress) external;
}