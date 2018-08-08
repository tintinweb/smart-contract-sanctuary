pragma solidity 0.4.18;

contract owned {
    address public owner;

    // The one who sent the contract to the blockchain, will automatically become the owner of the contract
    function owned() internal {
        owner = msg.sender;
    }

    // The function containing this modifier can only call the owner of the contract
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    // Change the owner of the contract
    function changeOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// Functions for safe operation with input values (subtraction and addition)
library SafeMath {
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

// ERC20 interface https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256 balance);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AdvancedToken is ERC20, owned {
    using SafeMath for uint256;

    // Stores the balances of all holders of the tokens, including the owner of the contract
    mapping (address => uint256) internal balances;

    // The event informs that N tokens have been destroyed
    event Burn(address indexed from, uint256 value);

    // Creates the required number of tokens on the specified account
    function mintTokens(address _who, uint256 amount) internal returns(bool) {
        require(_who != address(0));
        totalSupply = totalSupply.add(amount);
        balances[_who] = balances[_who].add(amount);
        Transfer(this, _who, amount);
        return true;
    }

    // Burns tokens on the contract, without affecting the token holders and the owner of the contract
    function burnTokens(uint256 _value) public onlyOwner {
        require(balances[this] > 0);
        balances[this] = balances[this].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(this, _value);
    }

    // Withdraws tokens from the contract if they accidentally or on purpose was it placed there
    function withdrawTokens(uint256 _value) public onlyOwner {
        require(balances[this] > 0 && balances[this] >= _value);
        balances[this] = balances[this].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Transfer(this, msg.sender, _value);
    }

    // Withdraws all the ether from the contract to the owner account
    function withdrawEther(uint256 _value) public onlyOwner {
        require(this.balance >= _value);
        owner.transfer(_value);
    }
}

contract ICO is AdvancedToken {
    using SafeMath for uint256;

    enum State { Presale, waitingForICO, ICO, Active }
    State public contract_state = State.Presale;

    uint256 private startTime;
    uint256 private presaleMaxSupply;
    uint256 private marketMaxSupply;

    event NewState(State state);

    // Purchasing tokens is only allowed for Presale and ICO contract states
    modifier crowdsaleState {
        require(contract_state == State.Presale || contract_state == State.ICO);
        _;
    }

    // Call functions transfer transferFrom and approve, is only allowed with Active state of the contract
    modifier activeState {
        require(contract_state == State.Active);
        _;
    }

    // The initialization values when the contract has been mined to the blockchain
    function ICO() internal {
        startTime = 1528205440; // pomeriggio
        presaleMaxSupply = 0 * 1 ether;
        marketMaxSupply = 450000000 * 1 ether;
    }

    // The function of purchasing tokens
    function () private payable crowdsaleState {
        require(msg.value >= 0.0001 ether);
        require(now >= startTime);
        uint256 currentMaxSupply;
        uint256 tokensPerEther = 5000;
        uint256 _tokens = tokensPerEther * msg.value;
        uint256 bonus = 0;

        // PRE-SALE calculation of bonuses
        // NOTE: PRE-SALE will be not used for TESTERIUM2
        if (contract_state == State.Presale) {
            // PRE-SALE supply limit
            currentMaxSupply = presaleMaxSupply;
            // For the tests replace days to minutes
            if (now <= startTime + 1 days) {
                bonus = 25;
            } else if (now <= startTime + 2 days) {
                bonus = 20;
            }
        // ICO supply limit
        } else {
            currentMaxSupply = marketMaxSupply;
        }

        _tokens += _tokens * bonus / 100;
        uint256 restTokens = currentMaxSupply - totalSupply;
        // If supplied tokens more that the rest of the tokens, will refund the excess ether
        if (_tokens > restTokens) {
            uint256 bonusTokens = restTokens - restTokens / (100 + bonus) * 100;
            // The wei that the investor will spend for this purchase
            uint256 spentWei = (restTokens - bonusTokens) / tokensPerEther;
            // Verify that not return more than the incoming ether
            assert(spentWei < msg.value);
            // Will refund extra ether
            msg.sender.transfer(msg.value - spentWei);
            _tokens = restTokens;
        }
        mintTokens(msg.sender, _tokens);
    }

    // Finish the PRE-SALE period, is required the Presale state of the contract
    function finishPresale() public onlyOwner returns (bool success) {
        require(contract_state == State.Presale);
        contract_state = State.waitingForICO;
        NewState(contract_state);
        return true;
    }

    // Start the ICO period, is required the waitingForICO state of the contract
    function startICO() public onlyOwner returns (bool success) {
        require(contract_state == State.waitingForICO);
        contract_state = State.ICO;
        NewState(contract_state);
        return true;
    }

    // Our tokens
    function finishICO() public onlyOwner returns (bool success) {
        require(contract_state == State.ICO);
        mintTokens(owner, 50000000000000000000000000);
        contract_state = State.Active;
        NewState(contract_state);
        return true;
    }
}

// See ERC20 interface above
contract TESTERIUM2 is ICO {
    using SafeMath for uint256;

    string public constant name     = "ZAREK TOKEN";
    string public constant symbol   = "€XPLAY";
    uint8  public constant decimals = 18;

    mapping (address => mapping (address => uint256)) private allowed;

    function balanceOf(address _who) public constant returns (uint256 available) {
        return balances[_who];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public activeState returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public activeState returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public activeState returns (bool success) {
        require(_spender != address(0));
        require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


}