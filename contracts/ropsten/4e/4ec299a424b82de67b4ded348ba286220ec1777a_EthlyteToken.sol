pragma solidity ^0.4.0;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


interface token {
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns(uint balance);
}





// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

}

contract EthlyteToken is  Owned, SafeMath {

    uint public startDate;
    uint public bonusEnds;
    uint public endDate;
    token public reward;
    uint public Ownerbalance;

    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        address EthlyteTokenAddress = 0xa19ED2a67A86B27B48Ad33b69e9179c6AaC4a10b;
        bonusEnds = now + 3 weeks;
        endDate = now + 6 weeks;
        reward = token(EthlyteTokenAddress);


    }
    function getbalance() public returns(uint) {
        uint test = reward.balanceOf(this);
        return (test);
    }
    // ------------------------------------------------------------------------
    // 500 EthlyteToken Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        if (now <= bonusEnds) {
            tokens = msg.value * 600;
        } else {
            tokens = msg.value * 500;
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        reward.transfer(msg.sender, tokens);
        //Cialfor : The owner will get the amount transferred to this contract
        uint amount = this.balance;
        owner.transfer(amount);
    }
    //function to withdraw funds during crowdsale
    function safeWithdrawal() public onlyOwner {
            uint amount = this.balance;
            owner.transfer(amount);
    }
    //function to end crowdsale
    function endCrowdsale() public onlyOwner {
        endDate = now;
    }

    function withdrawTokens() public onlyOwner{
        Ownerbalance = reward.balanceOf(this);
        reward.transfer(owner, Ownerbalance);

    }

}