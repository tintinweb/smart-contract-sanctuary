pragma solidity 0.5.7;

contract SendFunds {
    address payable owner;
    bool reentrantCheck;
    constructor(address payable _add) public  {
        owner = _add;
    }

    function sendEth(address payable[] memory _users, uint[] memory _amounts) public payable {
        require(msg.sender == owner);
        require(!reentrantCheck);
        reentrantCheck = true;
        for(uint i=0;i<_users.length;i++) {
            _users[i].transfer(_amounts[i]);
        }
        delete reentrantCheck;
        if((address(this)).balance > 0) {
            owner.transfer((address(this)).balance);
        }
    }
}