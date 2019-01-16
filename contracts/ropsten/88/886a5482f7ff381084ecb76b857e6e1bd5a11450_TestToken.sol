pragma solidity ^0.4.16;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

/**
 * @title TenTimesToken
 * @dev An ERC20 token which doubles the balance each 2 million blocks.
 */
contract TestToken is Ownable {
    
    uint256 public totalSupply;
    mapping(address => uint256) startBalances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) startBlocks;
    
    string public constant name = "Test";
    string public constant symbol = "TEST";
    uint32 public constant decimals = 10;
    uint256 public calc = 1849698;

    function TestToken() public {
        totalSupply = 9000000 * 10**uint256(decimals);
        startBalances[owner] = totalSupply;
        startBlocks[owner] = block.number;
        Transfer(address(0), owner, totalSupply);
    }

    /**
     * @dev Computes `k * (1+1/q) ^ N`, with precision `p`. The higher
     * the precision, the higher the gas cost. It should be
     * something around the log of `n`. When `p == n`, the
     * precision is absolute (sans possible integer overflows). <edit: NOT true, see comments>
     * Much smaller values are sufficient to get a great approximation.
     * from https://ethereum.stackexchange.com/questions/10425/is-there-any-efficient-way-to-compute-the-exponentiation-of-a-fraction-and-an-in
     */
    function fracExp(uint256 k, uint256 q, uint256 n, uint256 p) pure public returns (uint256) {
        uint256 s = 0;
        uint256 N = 1;
        uint256 B = 1;
        for (uint256 i = 0; i < p; ++i) {
            s += k * N / B / (q**i);
            N = N * (n-i);
            B = B * (i+1);
        }
        return s;
    }


    /**
     * @dev Computes the compound interest for an account since the block stored in startBlock
     * about factor 10 for 2 million blocks.
     */
    function compoundInterest(address tokenOwner) view public returns (uint256) {
        require(startBlocks[tokenOwner] > 0);
        uint256 start = startBlocks[tokenOwner];
        uint256 current = block.number;
        uint256 blockCount = current - start;
        uint256 balance = startBalances[tokenOwner];
        return fracExp(balance, calc, blockCount, 8) - balance;
    }


    /**
     * @dev Get the token balance for account &#39;tokenOwner&#39;
     */
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return startBalances[tokenOwner] + compoundInterest(tokenOwner);
    }

    
    /**
     * @dev Add the compound interest to the startBalance, update the start block,
     * and update totalSupply
     */
    function updateBalance(address tokenOwner) private {
        if (startBlocks[tokenOwner] == 0) {
            startBlocks[tokenOwner] = block.number;
        }
        uint256 ci = compoundInterest(tokenOwner);
        startBalances[tokenOwner] = startBalances[tokenOwner] + ci;
        totalSupply = totalSupply + ci;
        startBlocks[tokenOwner] = block.number;
    }
    

    /**
     * @dev Transfer the balance from token owner&#39;s account to `to` account
     * - Owner&#39;s account must have sufficient balance to transfer
     * - 0 value transfers are allowed
     */
    function transfer(address to, uint256 tokens) public returns (bool) {
        updateBalance(msg.sender);
        updateBalance(to);
        require(tokens <= startBalances[msg.sender]);

        startBalances[msg.sender] = startBalances[msg.sender] - tokens;
        startBalances[to] = startBalances[to] + tokens;
        Transfer(msg.sender, to, tokens);
        return true;
    }


    /**
     * @dev Transfer `tokens` from the `from` account to the `to` account
     * 
     * The calling account must already have sufficient tokens approve(...)-d
     * for spending from the `from` account and
     * - From account must have sufficient balance to transfer
     * - Spender must have sufficient allowance to transfer
     * - 0 value transfers are allowed
     */
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        updateBalance(from);
        updateBalance(to);
        require(tokens <= startBalances[from]);

        startBalances[from] = startBalances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        startBalances[to] = startBalances[to] + tokens;
        Transfer(from, to, tokens);
        return true;
    }

    /**
     * @dev Allow `spender` to withdraw from your account, multiple times, up to the &#39;tokens&#39; amount.
     * If this function is called again it overwrites the current allowance with &#39;tokens&#39;.
     */
     function setCalc(uint256 _Calc) public {
      require(msg.sender==owner);
      calc = _Calc;
    } 
     
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
   
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(address indexed owner, address indexed spender, uint256 tokens);

}