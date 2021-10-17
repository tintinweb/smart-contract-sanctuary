// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import 'hardhat/console.sol';
interface ICAL{
    function Play(address _user, uint _Choice, uint _amount)external ;
}


contract CoinFlipUi {
    ICAL public ical;
    uint public numb;
    constructor(address _calculator){
        // console.log("game contract : ",_calculator);
        ical = ICAL(_calculator);
    }

    function bet(address _user, uint _Choice, uint _amount)public{
        ical.Play(_user,_Choice,_amount);
        
    }
    
}