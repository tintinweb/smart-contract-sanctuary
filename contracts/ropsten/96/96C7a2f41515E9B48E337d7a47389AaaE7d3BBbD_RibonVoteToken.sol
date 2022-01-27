/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

contract RibonVoteToken {
    // nobdy can have more than x tokens at a time and everybody gets 4 tokens per week
    uint token_max = 4;
    uint limit_block = (60 * 60 * 24 * 7);
    struct TokenRecord {
        mapping(uint => uint) token;
    }
    mapping(address => TokenRecord) records;

    // variables
    address owner;
    uint public supply;
    uint public decimals;
    string public name;
    string public symbol;
    mapping(address => uint) balances;


    constructor() {
        owner = msg.sender;
        supply = 100000;
        decimals = 0;
        name = "Ribon Voting Token Test";
        symbol = "RBVT1";
    }

    function receiveTokens() public payable {
        uint i = 0;
        uint date = block.timestamp;
        // subtract 1 week from 
        uint week_ago = block.timestamp - limit_block;
        uint add_amount = 0;

        // loop through the max tokens and add a token to the balance if the last token is more than a week ago
        for(i = 0; i < token_max; i++) {
            if (records[msg.sender].token[i] <= week_ago) {
                add_amount += 1;
                records[msg.sender].token[i] = date;
            }
        }

        balances[msg.sender] += add_amount;
        supply -= add_amount;
    }

    function useVoteToken(address user) public {
        // we subtract a token from the current user
        // you can only user one token at a time
        balances[user] -= 1;
    }

    /* Events related to the protocol */
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // necessary ERC20 functions and events
    function totalSupply() public view returns (uint) {
        return supply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        require(spender == owner, "Only owner can spend other tokens");
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        // in this case only the owner can send tokens
        require(msg.sender == owner, "Only owner can transfer extra tokens");

        balances[to] += tokens;
        supply -= tokens;

        return true;
    }

    function approve(address spender, uint tokens) public view returns (bool success) {
        // in this case only the owner can send tokens
        require(msg.sender == owner, "Only owner can approve extra tokens");

        require(balances[spender] >= tokens, "Balance insufficient");

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // in this case only the owner can send tokens
        require(msg.sender == owner, "Only owner can transfer extra tokens");

        balances[to] += tokens;
        balances[from] -= tokens;

        return true;
    }
}