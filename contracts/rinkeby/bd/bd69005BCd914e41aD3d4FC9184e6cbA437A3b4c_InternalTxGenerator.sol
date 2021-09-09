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

    function GenerateInternalTx() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    function GenerateInternalTxToAddr(address payable _to) external payable {
        _to.transfer(msg.value);
    }

    function internalTxTUSDT(address payable _to, uint256 _value) external payable {
        _to.transfer(msg.value);
        Tusdt.transferFrom(msg.sender, _to, _value);
    }

    function internalTxWeenus(address payable _to, uint _value) external payable {
        _to.transfer(msg.value);
        Weenus.transferFrom(msg.sender, _to, _value);
    }

    function internalTxYeenus(address payable _to, uint _value) external payable {
        _to.transfer(msg.value);
        Yeenus.transferFrom(msg.sender, _to, _value);
    }
}