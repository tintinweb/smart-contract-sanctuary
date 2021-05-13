/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//kim dong hyeon

pragma solidity 0.8.0;
contract multiplication{
    function mul(uint a , uint b) public view returns(uint,uint){
        return(a*b,a**b);
    }
}