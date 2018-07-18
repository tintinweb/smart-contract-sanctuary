pragma solidity ^0.4.24;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract FlowStop is Owned {

    bool public stopped = false;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner {
        stopped = true;
    }
    function start() public onlyOwner {
        stopped = false;
    }
}


contract Utils {
    function Utils() internal {
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }
}


contract BuyFlowingHair100ETH is Owned, FlowStop, Utils {
    using SafeMath for uint;
    ERC20Interface public flowingHairAddress;

    function BuyFlowingHair100ETH(ERC20Interface _flowingHairAddress) public{
        flowingHairAddress = _flowingHairAddress;
    }
        
    function withdrawTo(address to, uint amount)
        public onlyOwner stoppable
        notThis(to)
    {   
        require(amount <= this.balance);
        to.transfer(amount);
    }
    
    function withdrawERC20TokenTo(ERC20Interface token, address to, uint amount)
        public onlyOwner
        validAddress(token)
        validAddress(to)
        notThis(to)
    {
        assert(token.transfer(to, amount));

    }
    
    function buyToken() internal
    {
        require(!stopped && msg.value >= 100 ether);
        uint amount = msg.value * 41600;
        assert(flowingHairAddress.transfer(msg.sender, amount));
    }

    function() public payable stoppable {
        buyToken();
    }
}