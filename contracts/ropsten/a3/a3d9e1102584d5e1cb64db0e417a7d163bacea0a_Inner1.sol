/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.26;
contract Inner{
     function test(uint value)payable public;
}
contract Inner1 {
    
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    address public i6;
    function setI6(address _i6) public{
        i6=_i6;
    }
    event BalanceInfo(address indexed currentAddress, uint indexed amount);
    event ReceivedInfo(address indexed sender, address indexed to,uint indexed amount);
    function () payable external {
       emit ReceivedInfo(msg.sender,address(this), msg.value);
    }
    event Test(address indexed from,address indexed to, uint indexed amount);
    function test(uint value)payable public{
        emit BalanceInfo(address(this),address(this).balance);
        if(isContract(i6)){
            if(address(this).balance<=value){
                value=address(this).balance;
            }
            i6.transfer(value);
            Inner(i6).test(value);
            emit Test(address(this), i6,value);
        }
        
    }
}