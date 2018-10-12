pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract InvestInterface {
    function registerReferral(address _refferal) external;
}

contract ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract ReferalRegistrator is Ownable {
    
    InvestInterface public invest;
    ERC20 public token;
    
    uint256 public registrationPrice = 10**6;

    constructor() public {
        token = ERC20(0x1d099f784a31a05011a84c8c18087b56f4701c9b);
    }

    function setInvest(address _address) external onlyOwner {
        invest = InvestInterface(_address);
    }
    
    function setToken(address _address) external onlyOwner {
        token = ERC20(_address);
    }
    
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) {
        require(token.transferFrom(from, owner, registrationPrice));
        invest.registerReferral(from);
    }
    
}