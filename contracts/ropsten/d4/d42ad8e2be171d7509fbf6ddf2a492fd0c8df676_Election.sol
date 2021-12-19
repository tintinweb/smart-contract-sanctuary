/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Election{
    mapping(address => bool) _voters;
    mapping(uint => uint) _candidates;
    
    address _owner;
    bool _open;

    constructor(){
        _owner == msg.sender;
    }

    modifier onlyOwner{
        require(_owner == msg.sender,"You're Not Authorized");
        _;
    }

    function vote(uint candidateNumber) public{
        require(_open,"Election coled");
        // require(!_voters[msg.sender], "You're Voted");
        _candidates[candidateNumber]++;
        _voters[msg.sender] = true;
    }

    function summary(uint candidateNumber) public view returns(uint){
        return _candidates[candidateNumber];
    }

    function open() public onlyOwner{
        _open = true;
    }

    function close() public onlyOwner{
        _open = false;
    }

}