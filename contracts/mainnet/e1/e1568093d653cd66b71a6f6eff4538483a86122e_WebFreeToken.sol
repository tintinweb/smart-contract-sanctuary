pragma solidity ^0.4.22;

// ----------------------------------------------------------------------------

// Symbol      : FREE
// Name        : Webfree
// Total supply: 777,777,777.000000000000000000
// Decimals    : 18

// ----------------------------------------------------------------------------

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
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


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
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract WebFreeToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    bool freezed = true;
    
    address SupernodesNodesOwnersFREE = 
        0x2CAadf019F6a5F557c552a33ED9a2Ce36C982d70;

    address WebfreeFoundationFREE = 
        0x0E1EA5831d0d2c1745D583dd93B9114222416372;

    address WebfreePrivateContributionFREE = 
        0x89cE7309953124caCbdCe6CcC1E23aF927d8e703;
 
    address WebfreePublicContributionFREE = 
        0x5E911c5A41A60c23C2836eedc80E1Bdeb2991Eb2;

    address WebfreeCommunityRewardsFREE = 
        0xBeA8E036eb401C1d01526cAFb6cb1dd6e3ea122E;

    address WebfreeTeamFREE = 
        0x5da594967B254c1bA3E816C99D691439EE1dDD76;
    

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        symbol = "FREE";
        name = "Webfree";
        decimals = 18;
        uint dec = 10**uint(decimals);
        
        balances[SupernodesNodesOwnersFREE] = 311111111 * dec;
        balances[WebfreeFoundationFREE] = 155555555 * dec;
        balances[WebfreePrivateContributionFREE] = 77777777 * dec;
        balances[WebfreePublicContributionFREE] = 77777777 * dec;
        balances[WebfreeCommunityRewardsFREE] = 77777777 * dec;
        balances[WebfreeTeamFREE] = 77777780 * dec;
        
        _totalSupply = uint(0)
            .add(balances[SupernodesNodesOwnersFREE])
            .add(balances[WebfreeFoundationFREE])
            .add(balances[WebfreePrivateContributionFREE])
            .add(balances[WebfreePublicContributionFREE])
            .add(balances[WebfreeCommunityRewardsFREE])
            .add(balances[WebfreeTeamFREE]);
        
        
        emit Transfer(address(0), SupernodesNodesOwnersFREE, 311111111 * dec);
        emit Transfer(address(0), WebfreeFoundationFREE, 155555555 * dec);
        emit Transfer(address(0), WebfreePrivateContributionFREE, 77777777 * dec);
        emit Transfer(address(0), WebfreePublicContributionFREE, 77777777 * dec);
        emit Transfer(address(0), WebfreeCommunityRewardsFREE, 77777777 * dec);
        emit Transfer(address(0), WebfreeTeamFREE, 77777780 * dec);
        transferOwnership(0x5da594967B254c1bA3E816C99D691439EE1dDD76);
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        bool req = !freezed || 
            msg.sender == SupernodesNodesOwnersFREE ||
            msg.sender == WebfreeFoundationFREE ||
            msg.sender == WebfreePrivateContributionFREE ||
            msg.sender == WebfreePublicContributionFREE ||
            msg.sender == WebfreeCommunityRewardsFREE ||
            msg.sender == WebfreeTeamFREE;
        require(req);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(!freezed);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function unfreez() public onlyOwner {
        freezed = false;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    function () public payable {
        revert();
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}