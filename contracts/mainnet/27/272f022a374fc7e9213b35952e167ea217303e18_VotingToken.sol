pragma solidity ^0.4.19;


// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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




contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed from, address indexed to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
        OwnershipTransferred(owner, _newOwner);
    }
}



// ----------------------------------------------------------------------------
// Safe maths
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



contract VotingToken is ERC20Interface, Owned {
    using SafeMath for uint;


    // ------------------------------------------------------------------------
    // ERC 20 fields
    // ------------------------------------------------------------------------
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Fields required for the referendum
    // ------------------------------------------------------------------------
    Description public description;
    Props public props;
    Reward public reward;
    bool public open;
    
    struct Description {
        string question;
        string firstProp;
        string secondProp;
    }

    struct Props {
        address firstPropAddress;
        address secondPropAddress;
        address blankVoteAddress;
    }

    struct Reward {
        address tokenAddress;
        address refundWalletAddress; 
    }

    event VoteRewarded(address indexed to, uint amount);
    event Finish(string question, 
        string firstProp, uint firstPropCount, 
        string secondProp, uint secondPropCount, uint blankVoteCount);


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function VotingToken(
        string _symbol, string _name, uint _totalSupply, 
        string _question, string _firstProp, string _secondProp,
        address _firstPropAddress, address _secondPropAddress, address _blankVoteAddress,
        address _tokenAddress) public {

        symbol = _symbol;
        name = _name;
        decimals = 8;
        totalSupply = _totalSupply;
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, totalSupply);

        description = Description(_question, _firstProp, _secondProp);
        props = Props(_firstPropAddress, _secondPropAddress, _blankVoteAddress);
        reward = Reward(_tokenAddress, owner);
        open = true;
    }

    function close() public onlyOwner returns (bool success) {
        require(open);
        open = false;
        Finish(description.question, 
            description.firstProp, balanceOf(props.firstPropAddress), 
            description.firstProp, balanceOf(props.secondPropAddress), 
            balanceOf(props.blankVoteAddress));

        ERC20Interface rewardToken = ERC20Interface(reward.tokenAddress);
        uint leftBalance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(reward.refundWalletAddress, leftBalance);

        return true;
    }

    function updateRefundWalletAddress(address _wallet) public onlyOwner returns (bool success) {
        reward.refundWalletAddress = _wallet;
        return true;
    }

    function getResults() public view returns (uint firstPropCount, uint secondPropCount, uint blankVoteCount) {
        return (
            balanceOf(props.firstPropAddress), 
            balanceOf(props.secondPropAddress), 
            balanceOf(props.blankVoteAddress));
    }

    function totalSupply() public constant returns (uint) {
        return totalSupply - balances[address(0)];
    }

    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }

    function rewardVote(address _from, address _to, uint _tokens) private {
        if(_to == props.firstPropAddress || 
           _to == props.secondPropAddress || 
           _to == props.blankVoteAddress) {
            ERC20Interface rewardToken = ERC20Interface(reward.tokenAddress);
            uint rewardTokens = _tokens.div(100);
            rewardToken.transfer(_from, rewardTokens);
            VoteRewarded(_from, _tokens);
        }
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        return transferFrom(msg.sender, to, tokens);
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(open);
        balances[from] = balances[from].sub(tokens);
        if(from != msg.sender) {
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        }
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        rewardVote(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require(open);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}