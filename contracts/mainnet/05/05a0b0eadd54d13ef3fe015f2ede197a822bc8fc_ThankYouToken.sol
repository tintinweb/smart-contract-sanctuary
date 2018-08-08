pragma solidity ^0.4.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 is Owned {

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);

    // Send _value amount of tokens from address _from to address _to on the condition it is approved by _from
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ThankYouToken is ERC20 {
    using SafeMath for uint256;

    // Total amount of token
    uint256 public totalSupply;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping (address => uint256)) allowed;

    //Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint256 size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value
        && allowed[_from][msg.sender] >= _value //the transfer is approved
        && _value > 0
        && balances[_to] + _value > balances[_to]) {

            balances[_to]   = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2*32) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Transfer the balance _value from owner&#39;s account (msg.sender) to another account (_to)
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {

            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);

            return true;
        } else {
            return false;
        }
    }


    string public thankYou  = "ThankYou!";
    string public name;
    string public symbol;
    uint256 public decimals = 18;

    function ThankYouToken(uint256 _initialSupply) {
        name = "ThankYou! Token";
        symbol = "TYT";
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }
    //---------------------------------------------------------------------------------------------------

    //Number of purchases per address
    mapping(address => uint256) numPurchasesPerAddress;

    bool public crowdsaleClosed = true;
    uint256 bonusMultiplier             = 50 * 10**decimals;
    uint256 public bonusTokensIssued    = 0;
    uint256 public freeTokensAvailable  = 10000 * 10**decimals;
    uint256 public freeTokensIssued     = 0;
    uint256 freeTokensPerAddress        = 2 * 10**decimals;
    uint256 public contribution         = 0;
    uint256 public totalTokensIssued    = 0;
    // Accounts that have received the 2 TYT for free
    mapping(address => bool) addressBonusReceived;

    event BonusTokens(address _from, address _to, uint256 _bonusToken);
    event FreeTokensIssued(address _from, address _to, uint256 _value);
    event FreeTokenAdded(address _from, uint256 _value);

    function openCrowdsale() onlyOwner {
        crowdsaleClosed = false;
    }

    function stopCrowdsale() onlyOwner {
        crowdsaleClosed = true;
    }


    function() payable {
        if(msg.value == 0){
            assert(!addressBonusReceived[msg.sender]);
            assert(freeTokensAvailable >= freeTokensPerAddress);
            assert(balances[owner] >= freeTokensPerAddress);

            addressBonusReceived[msg.sender] = true;

            freeTokensAvailable = freeTokensAvailable.sub(freeTokensPerAddress);
            freeTokensIssued    = freeTokensIssued.add(freeTokensPerAddress);

            balances[msg.sender] = balances[msg.sender].add(freeTokensPerAddress);
            balances[owner] = balances[owner].sub(freeTokensPerAddress);

            totalTokensIssued = totalTokensIssued.add(freeTokensPerAddress);

            FreeTokensIssued(owner, msg.sender, freeTokensPerAddress);

        } else {
            assert(!crowdsaleClosed);

            // 1 ETH = 1000 ThankYou tokens
            uint256 tokensSent = (msg.value * 1000);
            assert(balances[owner] >= tokensSent);

            if(msg.value >= 50 finney){
                numPurchasesPerAddress[msg.sender] = numPurchasesPerAddress[msg.sender].add(1);

                uint256 bonusTokens = numPurchasesPerAddress[msg.sender].mul(bonusMultiplier);
                tokensSent = tokensSent.add(bonusTokens);
                bonusTokensIssued = bonusTokensIssued.add(bonusTokens);

                assert(balances[owner] >= tokensSent);
                BonusTokens(owner, msg.sender, bonusTokens);
            }

            owner.transfer(msg.value);
            contribution = contribution.add(msg.value);

            balances[owner] = balances[owner].sub(tokensSent);
            totalTokensIssued = totalTokensIssued.add(tokensSent);
            balances[msg.sender] = balances[msg.sender].add(tokensSent);
            Transfer(address(this), msg.sender, tokensSent);
        }

    }

}