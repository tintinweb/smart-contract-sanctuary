/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ForeignToken {
    function balanceOf(address _owner) pure external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}


contract Tran {

    using SafeMath for uint256;
    using SafeMath for uint;
    address public owner = msg.sender;
    mapping (address => bool) public sendlist;
    address public fil = 0xae3a768f9aB104c69A7CD6041fE16fFa235d1810;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySender() {
        require(sendlist[msg.sender] == true || msg.sender == owner);
        _;
    }

    function enableSendlist(address[] calldata addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            sendlist[addresses[i]] = true;
        }
    }

    function disableSendlist(address[] calldata addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            sendlist[addresses[i]] = false;
        }
    }

    receive() external payable {
    }

    function withdraw(address payable receiveAddress) onlyOwner public {
        uint256 etherBalance = address(this).balance;
        if(!receiveAddress.send(etherBalance))revert();
    }

    function withdrawForeignTokens(address _tokenContract)  onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function TranEth(address[] calldata addresses,uint256 amount)  onlySender public returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            address(uint160(addresses[i])).transfer(amount);
        }
    }

    function TranForeignTokens(address _tokenContract,address[] calldata addresses,uint256 amount) onlySender public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amount);
        }
    }

    function TranForeignTokens2(address _tokenContract,address[] calldata addresses,uint256[] calldata amount) onlySender public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amount[i]);
        }
    }

    function TranForeignTokensOne(address _tokenContract,address addresses,uint256 amount) onlySender public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        token.transfer(addresses, amount);
    }

}