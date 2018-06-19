pragma solidity ^0.4.20;

contract Treethereum {  
    uint timeout; // PAY WHAT YOU WANT PROMO ENDS Saturday, March 10, 2018 7:01:29 AM, 0.2 ETH after
    mapping (address => address) inviter;
    
    function bytesToAddr (bytes b) constant returns (address)  {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }
    
    function addrecruit(address _recaddress, address _invaddress) private {
        if (inviter[_recaddress] != 0x0) {
                revert();
            }
        inviter[_recaddress] = _invaddress;
    }

    function () external payable { // Fallback Function
        timeout = 1520665289;
        address recaddress = msg.sender;
        invaddress = bytesToAddr(msg.data);
        if (invaddress == 0x0 || invaddress == recaddress) {
            address invaddress = 0x93D43eeFcFbE8F9e479E172ee5d92DdDd2600E3b;
        }
        addrecruit(recaddress, invaddress);
        uint i=0;
        uint amount = msg.value;
        if (amount < 0.2 ether && now > timeout) {
            msg.sender.transfer(msg.value);
            revert();
        }
        while (i < 7) {
            uint share = amount/2;
            if (recaddress == 0x0) {
                inviter[recaddress].transfer(share);
                recaddress = 0x93D43eeFcFbE8F9e479E172ee5d92DdDd2600E3b;
            }
            inviter[recaddress].transfer(share);
            recaddress = inviter[recaddress];
            amount -= share;
            i++;
        }
        inviter[recaddress].transfer(share);
    }
}