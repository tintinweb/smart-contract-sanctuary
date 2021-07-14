/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity 0.8.0;

contract nametok{
    
    string tokname;
    string toksym;

    function name() public view returns(string memory){
        return(tokname);
    }

    function symbol() public view returns(string memory){
        return(toksym);
    }

    function changName(string memory _name) public{
        tokname = _name;
    }

    function changSym(string memory _symbol) public{
        toksym = _symbol;
    }

}