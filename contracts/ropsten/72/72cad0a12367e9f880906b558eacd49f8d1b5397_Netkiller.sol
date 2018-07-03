pragma solidity ^0.4.24;

/******************************************/
/*      Netkiller Crowdsale Contract      */
/******************************************/
/* Author netkiller <netkiller@msn.com>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-06-07 - Solc ver: 0.4.24  */
/******************************************/

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Netkiller {
    
    token public tokenContract;

    constructor(address addressOfToken) public {
        tokenContract = token(addressOfToken);
    }

    function transfer(address _to, uint256 _value) payable public{
        tokenContract.transfer(_to, _value);
    }

    function transferOne(address _to, uint256 _value) public returns (bool success) {
        tokenContract.transfer(_to, _value);
        return true;
    }

    function transferBatch(address[] _to, uint256 _value) public returns (bool success) {
        for (uint i=0; i<_to.length; i++) {
            tokenContract.transfer(_to[i], _value);
        }
        return true;
    }
}