/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.7.0;

/** THIS CONTRACT IS NOT LEGITIMATE, IT'S A JOKE. YOU MAY, HOWEVER, GET SOMETHING OUT OF IT.*/

contract PonziCoin {
    address public currentInvestor;
    uint public currentInvestment = 0;

    fallback () external payable {
        uint minimumInvestment = currentInvestment * 11/10;
        require(msg.value > minimumInvestment);

        address payable previousInvestor = payable(currentInvestor);
        
        currentInvestor = msg.sender;
        currentInvestment = msg.value;

        previousInvestor.send(msg.value);
    }
}