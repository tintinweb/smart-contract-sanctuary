/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract Vote {
    function vote(bool _vote) public virtual;
    function whoVoted() public virtual returns(bytes32);
    function getVote() public virtual returns(bool);
}

contract VoteImpl is Vote {
    bytes32 _name;
    bool _voted;
    bool __vote;

    constructor(bytes32 name) public {
        _name = name;
        _voted = false;
    }

    function vote(bool _vote) override public {
        Passport p = Passport(msg.sender);
        require(_name == p.getName(), "User should not be suplanted, sorry.");
        require(!_voted, "User should not vote twice.");
        __vote = _vote;
        _voted = true;
    }
    
    function whoVoted() override public returns(bytes32) {
        require(_voted, "User has not voted yet.");

        return _name;
    }

    function getVote() override public returns(bool) {
        require(_voted, "User has not voted yet.");

        return __vote;
    }
}

abstract contract Passport {
    function getName() public virtual returns(bytes32);
    function getAge() public virtual returns(uint16);
    function vote(bool _vote, address caller) public virtual;
}

contract PassportImpl is Passport {
    bytes32 private _name;
    uint16 private _age;

    constructor(bytes32 name, uint16 age) public {
        _name = name;
        _age = age;
    }

    function getName() override public view returns(bytes32){
        return _name;
    }
    
    function getAge() override public view returns(uint16){
        return _age;
    }

    function vote(bool _vote, address caller) override public {
        Vote v = Vote(caller);
        v.vote(_vote);
    }
}