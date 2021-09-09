//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

//interface TestUsdtToken {
//    function transferFrom(address _from, address _to, uint256 _value) external payable;
//}
//
//interface WeenusToken {
//    function transferFrom(address from, address to, uint tokens) external returns (bool success);
//}
//
//interface YeenusToken {
//    function transferFrom(address from, address to, uint tokens) external returns (bool success);
//}

abstract contract ERC20 {
    function transferFrom(address from, address to, uint tokens) virtual external returns (bool success);
}

contract InternalTxGenerator {
    address private TusdtAddress = 0xD92E713d051C37EbB2561803a3b5FBAbc4962431;
    address private WeenusAddress = 0xaFF4481D10270F50f203E0763e2597776068CBc5;
    address private YeenusAddress = 0xc6fDe3FD2Cc2b173aEC24cc3f267cb3Cd78a26B7;

    ERC20 Tusdt = ERC20(TusdtAddress);
    ERC20 Weenus = ERC20(WeenusAddress);
    ERC20 Yeenus = ERC20(YeenusAddress);

    function internalTxWithToken(
        address payable _to,
        uint _tusdtValue,
        uint _weenusValue,
        uint _yeenusValue
    ) external payable {
        _to.transfer(msg.value);
        if (_tusdtValue > 0) {
            Tusdt.transferFrom(msg.sender, _to, _tusdtValue);
        }
        if (_weenusValue > 0) {
            Tusdt.transferFrom(msg.sender, _to, _weenusValue);
        }
        if (_yeenusValue > 0) {
            Tusdt.transferFrom(msg.sender, _to, _yeenusValue);
        }
    }
}