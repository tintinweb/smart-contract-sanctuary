pragma solidity ^0.4.24;

contract plantatree  {  
    mapping (address => address) inviter;
    
    function bytesToAddr (bytes b) public pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }
    
    function withdraw(uint amount) public {
        if (address(this).balance >= amount) {
            msg.sender.transfer(amount);
        }
    }
    
    function addrecruit(address _recaddress, address _invaddress) private {
        if (inviter[_recaddress] != 0x0) {
                revert();
            }
        inviter[_recaddress] = _invaddress;
    }

    function () external payable { // Fallback Function
        address recaddress = msg.sender;
        invaddress = bytesToAddr(msg.data);
        if (invaddress == 0x0 || invaddress == recaddress) {
            address invaddress = 0x4f77e02b735a5da4707f48ec30f6c80544dc2b94;
        }
        addrecruit(recaddress, invaddress);
        uint i=0;
        uint amount = msg.value;
        if (amount < 0.2 ether) {
            msg.sender.transfer(msg.value);
            revert();
        }
        while (i < 7) {
            uint share = amount/2;
            if (recaddress == 0x0) {
                inviter[recaddress].transfer(share);
                recaddress = 0x4f77e02b735a5da4707f48ec30f6c80544dc2b94;
            }
            inviter[recaddress].transfer(share);
            recaddress = inviter[recaddress];
            amount -= share;
            i++;
        }
        inviter[recaddress].transfer(share);
    }
}