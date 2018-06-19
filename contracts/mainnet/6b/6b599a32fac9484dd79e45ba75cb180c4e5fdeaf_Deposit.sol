pragma solidity ^0.4.11;

contract Deposit {
    /* Constructor */
    function Deposit() {

    }

    event Received(address from, address to, uint value);

    function() payable {
        if (msg.value > 0) {
            Received(msg.sender, this, msg.value);
            m_account.transfer(msg.value);
        }
    }

    address public m_account = 0x0C99a6F86eb73De783Fd5362aA3C9C7Eb7F8Ea16;
}