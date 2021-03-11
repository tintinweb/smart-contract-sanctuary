/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity >=0.4.0 <0.7.0;

interface contractB{
    function freeFunds(address payable receiver) external returns(bool); }

contract contractA {
    contractB public conB;
    address payable public receiver;
    
    event fundsSent();
    event error();
    
    constructor(address b, address payable _receiver) public {
        conB = contractB(b);
        receiver = _receiver;
    }

    function sendToReceiver() public {
        if(conB.freeFunds(receiver)) emit fundsSent();
        else emit error();
    }

    
}