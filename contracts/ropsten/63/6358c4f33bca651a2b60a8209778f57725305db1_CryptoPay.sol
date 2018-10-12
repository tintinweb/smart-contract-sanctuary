/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity 0.4.24;

/// @author Sowmay Jain - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7a09150d171b033a17151b0e54141f0e0d150811">[email&#160;protected]</a>> - @sowmay_jain (Twitter) - @Sowmay (Telegram)

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
        uint HowMuchToPay // if token is DAI srcAmt & HowMuchToPay will be same
    ) public payable {
        token tokenFunctions = token(src);
        Kyber kyberFunctions = Kyber(KyberAddress);
        if (src == DAIToken) {
            // provide allowance first
            tokenFunctions.transferFrom(msg.sender, address(this), HowMuchToPay);
            uint DAISplitToETH = HowMuchToPay / 10 * 3;

            tokenFunctions.transfer(payTo, HowMuchToPay - DAISplitToETH);
            kyberFunctions.trade.value(msg.value)(
                DAIToken,
                DAISplitToETH,
                ETHToken, // dest
                payTo, // address(this)
                2**256 - 1,
                0,
                0
            );
        } else {
            if (src != ETHToken) {
                // provide allowance first
                tokenFunctions.transferFrom(msg.sender, address(this), srcAmt);
            }
            // you should enough ether to cover the DAIToPay DAI amount after Kyber Swap
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
        AllSoldAmt[payTo] += HowMuchToPay;
        AllSoldTx[payTo] += 1;
    }

}

contract CryptoPay is KyberPay {

    function ApproveERC20() internal {
        // Only 4 tokens are allowed for Any Token, Anywhere
        token OMGtkn = token(0x4BFBa4a8F28755Cb2061c413459EE562c6B9c51b);
        OMGtkn.approve(KyberAddress, 2**256 - 1);
        token KNCtkn = token(0x4E470dc7321E84CA96FcAEDD0C8aBCebbAEB68C6);
        KNCtkn.approve(KyberAddress, 2**256 - 1);
        token BATtkn = token(0xDb0040451F373949A4Be60dcd7b6B8D6E42658B6);
        BATtkn.approve(KyberAddress, 2**256 - 1);
        token DAItkn = token(DAIToken);
        DAItkn.approve(KyberAddress, 2**256 - 1);
    }
    constructor() public {
        ApproveERC20();
    }
}