/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.5.16;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function safeMod(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a % b;
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    function _burn(address account, uint amount) internal;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


contract Owned is SafeMath{
    
    mapping (address => User) public users;
    
    uint ownerCount;
    
    struct User{
        bool isowner;
        bool voted;
        uint lastVotedStart;
        bool dividends_taked;
        uint dividendsStart;
    }
    
    Proposal public lastProposal;
    
    struct Proposal {
        address account;   
        uint voteCount; 
        uint startBallot;
        bool added;
    }

    event newOwner(address indexed newOwner);
    event newProposal(address indexed _created, address indexed _newProposal);

    constructor() public {
        users[msg.sender].isowner = true;
        address second_owner = 0x69aE669404a1825fF2AF4F2Eff2AeE94cDce37D4;
        users[second_owner].isowner = true;
        ownerCount = 2;
        emit newOwner(msg.sender);
        emit newOwner(second_owner);
    }

    modifier onlyOwner {
        require(users[msg.sender].isowner == true);
        _;
    }

    function ballotNewOwner(address _proposal) public onlyOwner {
        require(now - lastProposal.startBallot >= 3600 || lastProposal.added == true);
        require(_proposal != lastProposal.account && users[_proposal].isowner != true);
        lastProposal = Proposal(_proposal, 1, now, false);
        users[msg.sender].lastVotedStart = now;
        users[msg.sender].voted = true;
        emit newProposal(msg.sender, _proposal);
    }
    
    function vote() external onlyOwner {
        if (users[msg.sender].lastVotedStart != lastProposal.startBallot && users[msg.sender].voted == true){
            users[msg.sender].voted =false;
        }
        require(lastProposal.added == false && users[msg.sender].voted == false);
        users[msg.sender].voted = true;
        users[msg.sender].lastVotedStart = lastProposal.startBallot;
        lastProposal.voteCount++;
        uint needVotes = safeDiv(ownerCount, 2) + 1;
        if (lastProposal.voteCount == needVotes){
            acceptNewOwner();
        }
    }
    
    function acceptNewOwner() internal {
        lastProposal.added = true;
        users[lastProposal.account].isowner = true;
        ownerCount++;
        emit newOwner(lastProposal.account);
    }
}

contract Dividends{
    uint public test;
    function addDividends() external payable;
    function getDividends() external;
    
    event new_Dividends(address indexed _from, uint indexed _value);
    event user_get_dividends(address indexed _who);
    
} 

contract MyElephant is ERC20Interface, Owned, Dividends {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public dividends;
    uint public dividends_started;

    mapping (address => uint) burntime;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "ME";
        name = "My Elephant";
        decimals = 18;
        _totalSupply = 10**26;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function addDividends() external payable{
        require(now - dividends_started >= 2592000 && msg.value != 0);  // 30 днів  
        dividends_started = now;
        dividends = msg.value;
        emit new_Dividends(msg.sender, msg.value);
    }
    
    function getDividends() external{
        require(balances[msg.sender] != 0);
        if (users[msg.sender].dividends_taked == true && users[msg.sender].dividendsStart != dividends_started){
            users[msg.sender].dividends_taked = false;
        }
        require(users[msg.sender].dividends_taked == false);
        users[msg.sender].dividends_taked = true;
        users[msg.sender].dividendsStart = dividends_started;
        uint user_dividends = safeDiv(safeMul(balances[msg.sender], dividends), _totalSupply);
        msg.sender.transfer(user_dividends);
        emit user_get_dividends(msg.sender);
    }
    
    function burn(uint _amount) external returns(bool success){
        _burn(msg.sender, _amount);
        return true;
    }
    
    function _burn(address account, uint amount) internal {
        require(amount != 0 && amount <= balances[account] && now-burntime[msg.sender] >= 30);
        burntime[msg.sender] = now;
        _totalSupply = safeSub(_totalSupply, amount);
        balances[account] = safeSub(balances[account], amount);
        emit Transfer(account, address(0), amount);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

}