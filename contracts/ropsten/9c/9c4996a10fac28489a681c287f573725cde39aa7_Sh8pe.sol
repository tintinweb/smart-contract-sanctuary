pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Is not owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract WhiteList is Ownable {

    mapping(address => address) whiteList;

    constructor() public {
        whiteList[msg.sender] = msg.sender;
    }

    function add(address who) public onlyOwner() {
        require(who != address(0), "Invalid address");
        whiteList[who] = who;
    }

    function remove(address who) public onlyOwner() {
        require(who != address(0), "Invalid address");
        delete whiteList[who];
    }

    function isWhiteListed(address who) public view returns (bool) {
        return whiteList[who] != address(0);
    }
}

// import "./Ownable.sol";
// import "./SafeMath.sol";
// import "./WhiteList.sol";

contract Sh8pe is Ownable, WhiteList {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor () public {

        name = "Angel Token";
        symbol = "Angels";
        decimals = 18;
        totalSupply = 100000000;

        balances[msg.sender] = totalSupply;
        emit Transfer(this, msg.sender, totalSupply);
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

    //THIS IS A FUNCTION USED BE THE MASTER WALLET TO TRANSFER FUNDS BETWEEN ACCOUNTS ON THE NETWORK
    function transfer(address from, address to, uint256 value) public returns (bool) {
        require(isWhiteListed(msg.sender) == true, "Not white listed");
        require(balances[from] >= value, "Insufficient balance"); //CHECK IF FROM ADDRESS HAS ENOUGH BALANCE

        balances[from] = balances[from].sub(value); //SUB FROM SENDING ADDRESS
        balances[to] = balances[to].add(value); //ADD TO OTHER ADDRESS

        //emit Transfer(msg.sender, to, value);
        return true;
    }

    //!THIS FUNCITON IS DEPRECIATED
    // function transferFrom(address from, address to, uint256 value) public returns (bool) {
    //     require(balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value >= balances[to], "Insufficient balance");

    //     balances[from] = balances[from].sub(value);
    //     allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    //     balances[to] = balances[to].add(value);

    //     emit Transfer(from, to, value);
    //     return true;
    // }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid address");

        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}