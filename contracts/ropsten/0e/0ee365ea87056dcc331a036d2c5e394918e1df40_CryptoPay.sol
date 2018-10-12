pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function balanceOf(address who) external returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint amt) external returns (bool);
}

interface Kyber {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns (uint);
}

contract GlobalVar {
    mapping(address => uint) public AllSoldAmt;
    mapping(address => uint) public AllSoldTx;
    address public ETHToken = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    address public KyberAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // KN Proxy
    address public DAIToken = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; // DAI
}

contract KyberPay is GlobalVar {

    // then run this function (keep the src address token amount 3% inflated)
    // if ether then send value along with transaction
    function InstantPay(
        address payTo, // seller
        address src,
        uint srcAmt,
        uint DAIToPay // in DAI ($) 18 decimals // if token is DAI srcAmt & HowMuchToPay will be same
    ) public payable {
        token tokenFunctions = token(src);
        if (src == DAIToken) {
            // provide allowance first
            tokenFunctions.transferFrom(msg.sender, address(this), DAIToPay);
            tokenFunctions.transfer(payTo, DAIToPay);
        } else {
            if (src != ETHToken) {
                tokenFunctions.transferFrom(msg.sender, address(this), srcAmt);
            }
            Kyber kyberFunctions = Kyber(KyberAddress);
            kyberFunctions.trade.value(msg.value)(
                src,
                srcAmt,
                DAIToken, // dest
                payTo, // address(this)
                2**256 - 1,
                0,
                0
            );
        }
        AllSoldAmt[payTo] += DAIToPay;
        AllSoldTx[payTo] += 1;
    }

}

contract CryptoPay is KyberPay {
    constructor() public {}
}