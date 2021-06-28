/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.8.0;

contract MyToken {
    uint public supply = 1000000000000000000000000000000000000; //en WEI//
    mapping(address => uint) public balances;
    string public name;
    string public trigramm;
    
    constructor(){
        //_mint(address(this), supply);//
        // On donne tous les tokens au créateur//
        balances[msg.sender] = supply;
        name = "myToken";
        trigramm= "MTN";
    }
    // transférer un montant de tokens du compte de celui qui appelle la transacction au compte du receveur
    function transfer(uint _amont, address _receiver) public{ 
        //require(balances[msg.sender] >= _amount, "Must have ennougth tokens");//vérifier que la personne a suffisamment de tokens//
        balances[msg.sender] -= _amont;//est équivalent à balances[msg.sender] = balances[msg.sender] - _amount//
        balances[_receiver] +=_amont;
    }
}