pragma solidity ^0.4.21;
contract TestExchange
{
    uint256 public exchange  = 500 ether;
    uint256 public nonEthWeiRaised;
    uint256 public tokenReserved;

    function changeExchange(uint256 _ETHUSD) public {

        exchange=_ETHUSD;

    }
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {

        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }
    
}