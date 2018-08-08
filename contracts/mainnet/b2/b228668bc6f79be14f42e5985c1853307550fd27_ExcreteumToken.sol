pragma solidity ^0.4.8;

// ----------------------------------------------------------------------------------------------
// EXCRETEUM
// Standard ERC20 Token
// 120M supply distributed as such: 10M creators, 20M marketing, 90M ico
// ----------------------------------------------------------------------------------------------

contract ERC20Interface {

    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

// As of 2017
// 14 000 000 000 000 US dollars go through the banking system daily

// In America, the top 1% earns $360 000 per year
// Roughly ten times the average income
// The top 0.01% earns $10 000 000 per year
// Roughly thirty times as much as the top 1%

// The human brain handles large numbers poorly
// The difference between a billionaire and a millionaire is remote to most
// The difference between 1M, 10M and 100M even more so

contract ExcreteumToken is ERC20Interface {
    
    string public constant symbol = "SHET";
    string public constant name = "Excreteum";
    uint8 public constant decimals = 8;
    uint256 _totalSupply = 12000000000000000;

    // 1. EQUALITY IS AN ILLUSION
    //
    // People are born with varied levels of ability
    // Further enhanced or discouraged by environmental factors
    //
    // Natural selection demands competition
    // Attempts to enforce a level-playing field cannot change this nature
    // Only the nature of said competition differs

    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    
    // 2. CODE CANNOT BE LAW
    //
    // Technology is beyond the intuition of the average person
    // The knowledge gap widens with each innovation
    //
    // A sufficiently advanced decentralized system becomes defacto centralized
    // As actors who understand this system are increasingly sparse
    
    function ExcreteumToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
    
    // 3. TRUST IS MANDATORY
    //
    // Social bridges are required even in trustless environments
    // Confidence is built between people rather than systems
    //
    // Benevolent dictators can foster positive communities
    // In the absence of guidance, negative actors will fill that gap

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // 4. TRANSPARENCY IS SYNONYMOUS WITH ANONYMITY
    //
    // Transparency in action keeps actors honest
    // Transparency in identity opens up single points of failure
    //
    // An immutable ledger works best when no human transactions occur offchain
    // Anonymous entities cannot be silenced, influenced or disposed of
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // 5. INFORMATION IS PRICELESS
    //
    // Neither assets nor currencies have inherent worth
    // Asynchronous value comes from asynchronous information
    //
    // Sharing knowledge at any level of understanding help actors make choices
    // Information is useful regardless of veracity


    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // 6. NATURE IS GOOD
    //
    // Take a walk outside
    // Learn to build a campfire
    // Plant a tree this year
    // Watch out for cow dung
    
}