pragma solidity ^0.4.24;

/******************************************/
/*      Netkiller Batch Transfer          */
/******************************************/
/* Author netkiller <netkiller@msn.com>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-07-02 - Solc ver: 0.4.24  */
/******************************************/

interface token {
    function transfer(address receiver, uint amount) external;
}

contract NetkillerBatchToken {

    token public tokenContract;

    constructor(address addressOfToken) public {
        tokenContract = token(addressOfToken);
    }

    function transferBatch(address[] _to, uint256 _value) public returns (bool success) {
        for (uint i=0; i<_to.length; i++) {
            tokenContract.transfer(_to[i], _value);
        }
        return true;
    }
}