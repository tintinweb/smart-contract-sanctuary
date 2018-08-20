pragma solidity ^0.4.16;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external;
    function transfer(address _to, uint256 _value) external;
}

contract AirdropiRide {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x51463cc990900e42f06439C30a6159a1A764Fb6F;

    uint256 public startDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor() public {
        creator = msg.sender;
        startDate = 1519862400;
        tokenReward = Token(0x69D94dC74dcDcCbadEc877454a40341Ecac34A7c);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;      
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;      
    }

    function setStartDate(uint256 _startDate) isCreator public {
        startDate = _startDate;      
    }
    
    function setToken(address _token) isCreator public {
        tokenReward = Token(_token);      
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

    function dropToken(address[] _to) isCreator public{
        require(now > startDate);
        for (uint256 i = 0; i < _to.length; i++) {
            uint256 amount = 1000 * (10**18);
            tokenReward.transferFrom(owner, _to[i], amount);
            emit FundTransfer(msg.sender, amount, true);
        }
    }

    function dropTokenV2(address[] _to) isCreator public{
        require(now > startDate);
        for (uint256 i = 0; i < _to.length; i++) {
            uint256 amount = 1000 * (10**18);
            tokenReward.transfer(_to[i], amount);
            emit FundTransfer(msg.sender, amount, true);
        }
    }

}