/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.5.0;

contract TradeZRX {

    address payable OWNER;

    // ZRX Config ROPSTEN
    address ZRX_EXCHANGE_PROXY = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == OWNER, "caller is not the owner!");
        _;
    }

    function zrxTrade(bytes memory _calldataHexString) onlyOwner public payable {
        _zrxTrade(_calldataHexString);
    }

    function _zrxTrade(bytes memory _calldataHexString) internal {
        //do trade
        address(ZRX_EXCHANGE_PROXY).call.value(msg.value)(_calldataHexString);
    }

}