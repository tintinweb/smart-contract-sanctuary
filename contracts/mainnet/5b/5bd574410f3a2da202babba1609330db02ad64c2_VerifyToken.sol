pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;VRF&#39; &#39;0xVerify&#39; token contract
//
// Symbol      : VRF
// Name        : 0xVerify
// Decimals    : 18
//
// A faucet distributed token, powered by ethverify.net
// ----------------------------------------------------------------------------





contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event TokensClaimed(address indexed to, uint tokens);
}

contract EthVerifyCore{
    mapping (address => bool) public verifiedUsers;
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// 0xVRF ERC20 Token
// ----------------------------------------------------------------------------
contract VerifyToken is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public dailyDistribution;
    uint public timestep;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    mapping(address => uint) public lastClaimed;
    uint public claimedYesterday;
    uint public claimedToday;
    uint public dayStartTime;
    bool public activated=false;
    address public creator;

    EthVerifyCore public ethVerify=EthVerifyCore(0x1c307A39511C16F74783fCd0091a921ec29A0b51);//0x1Ea6fAd76886fE0C0BF8eBb3F51678B33D24186c);//0x286A090b31462890cD9Bf9f167b610Ed8AA8bD1a);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        timestep=24 hours;//10 minutes;//24 hours;
        symbol = "VRF";
        name = "0xVerify";
        decimals = 18;
        dailyDistribution=10000000 * 10**uint(decimals);
        claimedYesterday=20;
        claimedToday=0;
        dayStartTime=now;
        _totalSupply=140000000 * 10**uint(decimals);
        balances[msg.sender] = _totalSupply;
        creator=msg.sender;
    }
    function activate(){
      require(!activated);
      require(msg.sender==creator);
      dayStartTime=now-1 minutes;
      activated=true;
    }
    // ------------------------------------------------------------------------
    // Claim VRF tokens daily, requires an Eth Verify account
    // ------------------------------------------------------------------------
    function claimTokens() public{
        require(activated);
        //progress the day if needed
        if(dayStartTime<now.sub(timestep)){
            uint daysPassed=(now.sub(dayStartTime)).div(timestep);
            dayStartTime=dayStartTime.add(daysPassed.mul(timestep));
            claimedYesterday=claimedToday > 1 ? claimedToday : 1; //make 1 the minimum to avoid divide by zero
            claimedToday=0;
        }

        //requires each account to be verified with eth verify
        require(ethVerify.verifiedUsers(msg.sender));

        //only allows each account to claim tokens once per day
        require(lastClaimed[msg.sender] <= dayStartTime);
        lastClaimed[msg.sender]=now;

        //distribute tokens based on the amount distributed the previous day; the goal is to shoot for an average equal to dailyDistribution.
        claimedToday=claimedToday.add(1);
        balances[msg.sender]=balances[msg.sender].add(dailyDistribution.div(claimedYesterday));
        _totalSupply=_totalSupply.add(dailyDistribution.div(claimedYesterday));
        emit TokensClaimed(msg.sender,dailyDistribution.div(claimedYesterday));
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
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
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
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
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
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