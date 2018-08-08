pragma solidity ^0.4.21;

/**
* @title Random Investor Contract
* @dev The Investor token contract
*/



contract RNDInvestor {
   
    address public owner; // Token owner address
    mapping (address => uint256) public balances; // balanceOf
    address[] public addresses;

    mapping (address => uint256) public debited;

    mapping (address => mapping (address => uint256)) allowed;

    string public standard = &#39;Random 1.1&#39;;
    string public constant name = "Random Investor Token";
    string public constant symbol = "RINVEST";
    uint   public constant decimals = 0;
    uint   public constant totalSupply = 2500;
    uint   public raised = 0;

    uint public ownerPrice = 1 ether;
    uint public soldAmount = 0; // current sold amount (for current state)
    bool public buyAllowed = true;
    bool public transferAllowed = false;
    
    State public current_state; // current token state
    
    // States
    enum State {
        Presale,
        ICO,
        Public
    }

    //
    // Events
    // This generates a publics event on the blockchain that will notify clients
    
    event Sent(address from, address to, uint amount);
    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Raised(uint _value);
    event StateSwitch(State newState);
    
    //
    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyIfAllowed() {
        if(!transferAllowed) { require(msg.sender == owner); }
        _;
    }

    //
    // Functions
    // 

    // Constructor
    function RNDInvestor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    // fallback function
    function() payable public {
        if(current_state == State.Public) {
            takeEther();
            return;
        }
        
        require(buyAllowed);
        require(msg.value >= ownerPrice);
        require(msg.sender != owner);
        
        uint wei_value = msg.value;

        // uint tokens = safeMul(wei_value, ownerPrice);
        uint tokens = wei_value / ownerPrice;
        uint cost = tokens * ownerPrice;
        
        if(current_state == State.Presale) {
            tokens = tokens * 2;
        }
        
        uint currentSoldAmount = safeAdd(tokens, soldAmount);

        if (current_state == State.Presale) {
            require(currentSoldAmount <= 1000);
        }
        
        require(balances[owner] >= tokens);
        
        balances[owner] = safeSub(balances[owner], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        soldAmount = safeAdd(soldAmount, tokens);
        
        uint extra_ether = safeSub(msg.value, cost); 
        if(extra_ether > 0) {
            msg.sender.transfer(extra_ether);
        }
    }
    
    
    function takeEther() payable public {
        if(msg.value > 0) {
            raised += msg.value;
            emit Raised(msg.value);
        } else {
            withdraw();
        }
    }
    
    function setOwnerPrice(uint _newPrice) public
        onlyOwner
        returns (bool success)
    {
        ownerPrice = _newPrice;
        return true;
    }
    
    function setTokenState(State _nextState) public
        onlyOwner
        returns (bool success)
    {
        bool canSwitchState
            =  (current_state == State.Presale && _nextState == State.ICO)
            || (current_state == State.Presale && _nextState == State.Public)
            || (current_state == State.ICO && _nextState == State.Public) ;

        require(canSwitchState);
        
        current_state = _nextState;

        emit StateSwitch(_nextState);

        return true;
    }
    
    function setBuyAllowed(bool _allowed) public
        onlyOwner
        returns (bool success)
    {
        buyAllowed = _allowed;
        return true;
    }
    
    function allowTransfer() public
        onlyOwner
        returns (bool success)
    {
        transferAllowed = true;
        return true;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function withdraw() public returns (bool success) {
        uint val = ethBalanceOf(msg.sender);
        if(val > 0) {
            msg.sender.transfer(val);
            debited[msg.sender] += val;
            return true;
        }
        return false;
    }



    function ethBalanceOf(address _investor) public view returns (uint256 balance) {
        uint val = (raised / totalSupply) * balances[_investor];
        if(val >= debited[_investor]) {
            return val - debited[_investor];
        }
        return 0;
    }


    function manager_withdraw() onlyOwner public {
        uint summ = 0;
        for(uint i = 0; i < addresses.length; i++) {
            summ += ethBalanceOf(addresses[i]);
        }
        require(summ < address(this).balance);
        msg.sender.transfer(address(this).balance - summ);
    }

    
    function manual_withdraw() public {
        for(uint i = 0; i < addresses.length; i++) {
            addresses[i].transfer( ethBalanceOf(addresses[i]) );
        }
    }


    function checkAddress(address _addr) public
        returns (bool have_addr)
    {
        for(uint i=0; i<addresses.length; i++) {
            if(addresses[i] == _addr) {
                return true;
            }
        }
        addresses.push(_addr);
        return true;
    }
    

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }


    /**
     * ERC 20 token functions
     *
     * https://github.com/ethereum/EIPs/issues/20
     */
    
    function transfer(address _to, uint256 _value) public
        onlyIfAllowed
        returns (bool success) 
    {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            checkAddress(_to);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyIfAllowed
        returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            checkAddress(_to);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public
        constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }
    
    
    
}