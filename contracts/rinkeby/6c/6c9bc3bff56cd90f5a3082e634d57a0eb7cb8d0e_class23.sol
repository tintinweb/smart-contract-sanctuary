/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.4.24;
contract class23{
    //鼓勵同學按照影片的東西打出來，因為remix都會提示，不會打錯啦！
    
    string public log_;
    
    event setNumber(string _from);
    
    constructor() public {
    
        
    }
    
    function fun_1 (string x) public returns(string){
        log_ = x;
        emit setNumber(log_);
        return x;
    }

    
    function fallback() external payable {
        // custom function code
    }

    function receive() external payable {
        // custom function code
    }
}