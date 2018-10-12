pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


contract Authorize is Ownable {
    /* Define variable owner of the type address */
    address public backEndOperator = msg.sender;

    mapping(address=>bool) public whitelist;

    event Authorized(address wlCandidate, uint timestamp);

    event Revoked(address wlCandidate, uint timestamp);


    modifier backEnd() {
        require(msg.sender == backEndOperator || msg.sender == owner);
        _;
    }

    function setBackEndAddress(address newBackEndOperator) public onlyOwner {
        backEndOperator = newBackEndOperator;
    }


    function authorize(address wlCandidate) public backEnd  {
        require(wlCandidate != address(0x0));
        require(!isWhitelisted(wlCandidate));
        whitelist[wlCandidate] = true;
        emit Authorized(wlCandidate, now);
    }

    function revoke(address wlCandidate) public  onlyOwner {
        whitelist[wlCandidate] = false;
        emit Revoked(wlCandidate, now);
    }

    function isWhitelisted(address wlCandidate) public view returns(bool) {
        return whitelist[wlCandidate];
    }

}