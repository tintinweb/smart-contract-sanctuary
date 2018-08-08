pragma solidity ^0.4.13;

/**
* @title PlusCoin Contract
* @dev The main token contract
*/



contract PlusCoin {
    address public owner; // Token owner address
    mapping (address => uint256) public balances; // balanceOf
    // mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => mapping (address => uint256)) allowed;

    string public standard = &#39;PlusCoin 1.0&#39;;
    string public constant name = "PlusCoin";
    string public constant symbol = "PLC";
    uint   public constant decimals = 18;
    uint public totalSupply;
    
    uint public constant fpct_packet_size = 3300;
    uint public ownerPrice = 40 * fpct_packet_size; //PRESALE_PRICE * 3 * fpct_packet_size;

    State public current_state; // current token state
    uint public soldAmount; // current sold amount (for current state)

    uint public constant owner_MIN_LIMIT = 15000000 * fpct_packet_size * 1000000000000000000;

    uint public constant TOKEN_PRESALE_LIMIT = 100000 * fpct_packet_size * 1000000000000000000;
    uint public constant TOKEN_ICO1_LIMIT = 3000000 * fpct_packet_size * 1000000000000000000;
    uint public constant TOKEN_ICO2_LIMIT = 3000000 * fpct_packet_size * 1000000000000000000;
    uint public constant TOKEN_ICO3_LIMIT = 3000000 * fpct_packet_size * 1000000000000000000;

    address public allowed_contract;


    // States
    enum State {
        Created,
        Presale,
        ICO1,
        ICO2,
        ICO3,
        Freedom,
        Paused // only for first stages
    }

    //
    // Events
    // This generates a publics event on the blockchain that will notify clients
    
    event Sent(address from, address to, uint amount);
    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event StateSwitch(State newState);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //
    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyAllowedContract() {
        require(msg.sender == allowed_contract);
        _;
    }


    modifier onlyOwnerBeforeFree() {
        if(current_state != State.Freedom) {
            require(msg.sender == owner);   
        }
        _;
    }


    modifier inState(State _state) {
        require(current_state == _state);
        _;
    }


    //
    // Functions
    // 

    // Constructor
    function PlusCoin() {
        owner = msg.sender;
        totalSupply = 25000000 * fpct_packet_size * 1000000000000000000;
        balances[owner] = totalSupply;
        current_state = State.Created;
        soldAmount = 0;
    }

    // fallback function
    function() payable {
        require(current_state != State.Paused && current_state != State.Created && current_state != State.Freedom);
        require(msg.value >= 1);
        require(msg.sender != owner);
        buyTokens(msg.sender);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    // Buy entry point
    function buy() public payable {
        require(current_state != State.Paused && current_state != State.Created && current_state != State.Freedom);
        require(msg.value >= 1);
        require(msg.sender != owner);
        buyTokens(msg.sender);
    }

    // Payable function for buy coins from token owner
    function buyTokens(address _buyer) public payable
    {
        require(current_state != State.Paused && current_state != State.Created && current_state != State.Freedom);
        require(msg.value >= 1);
        require(_buyer != owner);
        
        uint256 wei_value = msg.value;

        uint256 tokens = safeMul(wei_value, ownerPrice);
        tokens = tokens;
        
        uint256 currentSoldAmount = safeAdd(tokens, soldAmount);

        if(current_state == State.Presale) {
            require(currentSoldAmount <= TOKEN_PRESALE_LIMIT);
        }
        if(current_state == State.ICO1) {
            require(currentSoldAmount <= TOKEN_ICO1_LIMIT);
        }
        if(current_state == State.ICO2) {
            require(currentSoldAmount <= TOKEN_ICO2_LIMIT);
        }
        if(current_state == State.ICO3) {
            require(currentSoldAmount <= TOKEN_ICO3_LIMIT);
        }

        require( (balances[owner] - tokens) >= owner_MIN_LIMIT );
        
        balances[owner] = safeSub(balances[owner], tokens);
        balances[_buyer] = safeAdd(balances[_buyer], tokens);
        soldAmount = safeAdd(soldAmount, tokens);
        
        owner.transfer(this.balance);
        
        Buy(_buyer, msg.value, tokens);
        
    }


    function setOwnerPrice(uint128 _newPrice) public
        onlyOwner
        returns (bool success)
    {
        ownerPrice = _newPrice;
        return true;
    }


	function setAllowedContract(address _contract_address) public
        onlyOwner
        returns (bool success)
    {
        allowed_contract = _contract_address;
        return true;
    }


    // change state of token
    function setTokenState(State _nextState) public
        onlyOwner
        returns (bool success)
    {
        bool canSwitchState
            =  (current_state == State.Created && _nextState == State.Presale)
            || (current_state == State.Presale && _nextState == State.ICO1)
            || (current_state == State.ICO1 && _nextState == State.ICO2)
            || (current_state == State.ICO2 && _nextState == State.ICO3)
            || (current_state == State.ICO3 && _nextState == State.Freedom)
            //pause (allowed only &#39;any state->pause&#39; & &#39;pause->presale&#39; transition)
            // || (current_state == State.Presale && _nextState == State.Paused)
            // || (current_state == State.Paused && _nextState == State.Presale)
            || (current_state != State.Freedom && _nextState == State.Paused)
            || (current_state == State.Paused);

        require(canSwitchState);
        
        current_state = _nextState;

        soldAmount = 0;
        
        StateSwitch(_nextState);

        return true;
    }


    function remaining_for_sale() public constant returns (uint256 remaining_coins) {
        uint256 coins = 0;

        if (current_state == State.Presale) {
            coins = TOKEN_PRESALE_LIMIT - soldAmount;
        }
        if (current_state == State.ICO1) {
            coins = TOKEN_PRESALE_LIMIT - soldAmount;
        }
        if (current_state == State.ICO2) {
            coins = TOKEN_PRESALE_LIMIT - soldAmount;
        }
        if (current_state == State.ICO3) {
            coins = TOKEN_PRESALE_LIMIT - soldAmount;
        }
        if (current_state == State.Freedom) {
            coins = balances[owner] - owner_MIN_LIMIT;
        }

        return coins;
    }

    function get_token_state() public constant returns (State) {
        return current_state;
    }


    function withdrawEther(address _to) public 
        onlyOwner
    {
        _to.transfer(this.balance);
    }



    /**
     * ERC 20 token functions
     *
     * https://github.com/ethereum/EIPs/issues/20
     */
    
    function transfer(address _to, uint256 _value) 
        onlyOwnerBeforeFree
        returns (bool success) 
    {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) 
        onlyOwnerBeforeFree
        returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) 
        onlyOwnerBeforeFree
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) 
        onlyOwnerBeforeFree
        constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

    


    ///suicide & send funds to owner
    function destroy() { 
        if (msg.sender == owner) {
          suicide(owner);
        }
    }

    
}