/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

pragma solidity ^0.4.25;
contract Sample{
    address private _admin;
    uint private _state;

    modifier onlyAdmin(){
        require(msg.sender == _admin, "you are not admin");
        _;
    }

    event setState(uint value);

    constructor() public{
        _admin = msg.sender;
    }

    function setstate(uint value) public onlyAdmin{
        _state = value;
        emit setState(value);
    }

    function getstate() public view returns (uint){
        return _state;
    }
}