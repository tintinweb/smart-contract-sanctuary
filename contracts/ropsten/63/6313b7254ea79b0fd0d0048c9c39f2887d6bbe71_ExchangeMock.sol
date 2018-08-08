pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

contract ExchangeMock {
    string constant public VERSION = "1.0.0";
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;

    address public owner;

    address[5] public orderAddressesX;
    uint[6] public orderValuesX;
    uint public fillTakerTokenAmountX;
    bool public shouldThrowOnInsufficientBalanceOrAllowanceX;
    uint8 public vX;
    bytes32 public rX;
    bytes32 public sX;
    uint public cancelTakerTokenAmountX;

    address[5] public orderAddressesY;
    uint[6] public orderValuesY;
    uint public fillTakerTokenAmountY;
    uint8 public vY;
    bytes32 public rY;
    bytes32 public sY;

    constructor() public {
        owner = msg.sender;
    }
    function batchFillOrders(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
    {
        uint8 i = 0;
        orderAddressesX = orderAddresses[i];
        orderValuesX = orderValues[i];
        fillTakerTokenAmountX = fillTakerTokenAmounts[i];
        vX = v[i];
        rX = r[i];
        sX = s[i];

        i = 1;
        orderAddressesY = orderAddresses[i];
        orderValuesY = orderValues[i];
        fillTakerTokenAmountY = fillTakerTokenAmounts[i];
        vY = v[i];
        rY = r[i];
        sY = s[i];
        shouldThrowOnInsufficientBalanceOrAllowanceX = shouldThrowOnInsufficientBalanceOrAllowance;
    }



    function userAddr() public view returns (address) {
        return msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

}