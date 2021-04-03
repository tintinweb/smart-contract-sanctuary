/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// 3.4.2021 Benito e Mimmmo Buona Pasqua 2021

pragma solidity >=0.7.0 <0.9.0;

contract memorizza{

    uint256 number;

    function store(uint256 num) public {
        number = num;
    }


    function recupera() public view returns (uint256){
        return number;
    }
}