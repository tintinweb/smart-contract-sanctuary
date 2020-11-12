pragma solidity =0.4.25;

contract SafeMath {
     function safeMul(uint a, uint b) pure internal returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b)pure internal returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b)pure internal returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}

// Standard token interface (ERC 20)
// https://github.com/ethereum/EIPs/issues/20
contract Token is SafeMath {
     // Functions:
     /// @return total amount of tokens
     function totalSupply()public  constant returns (uint256 supply);

     /// @param _owner The address from which the balance will be retrieved
     /// @return The balance
     function balanceOf(address _owner)public constant returns (uint256 balance);

     /// @notice send `_value` token to `_to` from `msg.sender`
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     function transfer(address _to, uint256 _value)public returns(bool);

     /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     /// @param _from The address of the sender
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     /// @return Whether the transfer was successful or not
     function transferFrom(address _from, address _to, uint256 _value)public returns(bool);

     /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @param _value The amount of wei to be approved for transfer
     /// @return Whether the approval was successful or not
     function approve(address _spender, uint256 _value)public returns (bool success);

     /// @param _owner The address of the account owning tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @return Amount of remaining tokens allowed to spent
     function allowance(address _owner, address _spender)public constant returns (uint256 remaining);

     // Events:
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StdToken is Token {
     // Fields:
     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;
     uint public supply = 0;

     // Functions:
     function transfer(address _to, uint256 _value)public returns(bool) {
         
          require(balances[msg.sender] >= _value,"INSUFFICIENT BALANCE");
          require(balances[_to] + _value > balances[_to],"CANT TRANSFER");

          balances[msg.sender] = safeSub(balances[msg.sender],_value);
          balances[_to] = safeAdd(balances[_to],_value);

          emit Transfer(msg.sender, _to, _value);
          return true;
     }

     function transferFrom(address _from, address _to, uint256 _value)public returns(bool){
          require(balances[_from] >= _value,"INSUFFICIENT BALANCE");
          require(allowed[_from][msg.sender] >= _value,"CANT TRANSFER");
          require(balances[_to] + _value > balances[_to],"CANT TRANSFER");

          balances[_to] = safeAdd(balances[_to],_value);
          balances[_from] = safeSub(balances[_from],_value);
          allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);

          emit Transfer(_from, _to, _value);
          return true;
     }

     function totalSupply()public constant returns (uint256) {
          return supply;
     }

     function balanceOf(address _owner)public constant returns (uint256) {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value)public returns (bool) {
          // To change the approve amount you first have to reduce the addresses`
          //  allowance to zero by calling `approve(_spender, 0)` if it is not
          //  already 0 to mitigate the race condition described here:
          //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
          require((_value == 0) || (allowed[msg.sender][_spender] == 0),"CANT ALLOW");

          allowed[msg.sender][_spender] = _value;
          emit Approval(msg.sender, _spender, _value);

          return true;
     }

     function allowance(address _owner, address _spender)public constant returns (uint256) {
          return allowed[_owner][_spender];
     }
}

contract GrandMarcheToken is StdToken
{
/// Fields:
    string public constant name = "Grand Marche Token";
    string public constant symbol = "GMT";
    uint public constant decimals = 18;
    
    uint public constant TOTAL_SUPPLY = 1000000 * (1 ether / 1 wei);
    uint public constant AIRDROP_SHARE = 50000 * (1 ether / 1 wei);

    uint public constant PRESALE_PRICE = 250;  // per 1 Ether
    uint public constant PRESALE_MAX_ETH = 400;
    
    uint public constant PRESALE_TOKEN_SUPPLY_LIMIT = PRESALE_PRICE * PRESALE_MAX_ETH * (1 ether / 1 wei);

    uint public constant ICO_PRICE = 100;     // per 1 Ether

    // 1bln - this includes presale tokens
    uint public constant TOTAL_SOLD_TOKEN_SUPPLY_LIMIT = 300000 * (1 ether / 1 wei);

    enum State{
       Init,
       Paused,
       PresaleRunning,
       PresaleFinished,
       ICORunning,
       ICOFinished
    }

    State public currentState = State.Init;
    bool public enableTransfers = false;

    
    address public AI = 0;
    address public airdrop = 0;
    address public privateSales = 0;
    address public teamTokenBonus = 0;

    // Gathered funds can be withdrawn only to escrow's address.
    address public escrow = 0;

    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager = 0;
    
    uint public CREATE_CONTRACT = 0;
    
    uint public presaleSoldTokens = 0;
    uint public icoSoldTokens = 0;
    uint public totalSoldTokens = 0;
    
    bool public ai_balout = true;
    bool public privateSales_balout = true;
    bool public teamTokenBonus_balout = true;

/// Modifiers:
    modifier onlyTokenManager()
    {
        require(msg.sender==tokenManager,"NOT MANAGER"); 
        _; 
    }

    modifier onlyInState(State state)
    {
        require(state==currentState,"STATE WRONG"); 
        _; 
    }

/// Events:
    event unlock(address indexed owner, uint value);
    event LogBuy(address indexed owner, uint value);

/// Functions:
    /// @dev Constructor
    /// @param _tokenManager Token manager address.
    constructor (address _tokenManager, address _teamTokenBonus, address _escrow, address _AI, address _privateSales, address _airdrop)public
    {   
        
        supply = TOTAL_SUPPLY;
        
        tokenManager = _tokenManager;
        teamTokenBonus = _teamTokenBonus;
        escrow = _escrow;
        AI = _AI;
        privateSales = _privateSales;
        airdrop = _airdrop;
        uint for_airdrop = AIRDROP_SHARE;
        balances[_airdrop] += for_airdrop;
        totalSoldTokens+= for_airdrop;
        
        CREATE_CONTRACT = uint40(block.timestamp);

        assert(PRESALE_TOKEN_SUPPLY_LIMIT==100000 * (1 ether / 1 wei));
        assert(TOTAL_SOLD_TOKEN_SUPPLY_LIMIT==300000 * (1 ether / 1 wei));
    }

    function buyTokens() public payable
    {
        require(currentState==State.PresaleRunning || currentState==State.ICORunning,"CANT BUY");

        if(currentState==State.PresaleRunning){
            return buyTokensPresale();
        }else{
            return buyTokensICO();
        }
    }
    
    function userbalance(address _addrress)public view returns(uint256){
        return balances[_addrress];
    }
    
    function buyTokensPresale() public payable onlyInState(State.PresaleRunning)
    {
        // min - 0.5 ETH
        require(msg.value >= 5e17,"Min 0.5 ETH");
        uint newTokens = msg.value * PRESALE_PRICE;

        require(presaleSoldTokens + newTokens <= PRESALE_TOKEN_SUPPLY_LIMIT,"PRESALE REACHED");

        balances[msg.sender] += newTokens;
        presaleSoldTokens+= newTokens;
        totalSoldTokens+= newTokens;

        emit LogBuy(msg.sender, newTokens);
    }

    function buyTokensICO() public payable onlyInState(State.ICORunning)
    {
        // min - 0.1 ETH
        require(msg.value >= 1e17,"Min 0.1 ETH");
        uint newTokens = msg.value * getPrice();

        require(totalSoldTokens + newTokens <= TOTAL_SOLD_TOKEN_SUPPLY_LIMIT,"Total Sold Token REACHED");

        balances[msg.sender] += newTokens;
        icoSoldTokens+= newTokens;
        totalSoldTokens+= newTokens;

        emit LogBuy(msg.sender, newTokens);
    }

    function getPrice()public constant returns(uint)
    {
        if(currentState==State.ICORunning){
             if(icoSoldTokens<(200000 * (1 ether / 1 wei))){
                  return ICO_PRICE;
             }
        }else{
             return PRESALE_PRICE;
        }
    }

    function setState(State _nextState) public payable onlyTokenManager
    {
        //setState() method call shouldn't be entertained after ICOFinished
        require(currentState != State.ICOFinished,"ICO FINISHED");
        
        currentState = _nextState;
        // enable/disable transfers
        //enable transfers only after ICOFinished, disable otherwise
        enableTransfers = (currentState==State.ICOFinished);
    }

    function withdrawEther() public onlyTokenManager
    {
        if(address(this).balance > 0) 
        {
            escrow.transfer(address(this).balance);
        }
    }
    
    function request_unlock()public payable{
        if(msg.sender==AI){
            require(uint40(block.timestamp) >= CREATE_CONTRACT +( 730 * 86400),"LOCKED"); //lock for 24 month
            require(ai_balout==true,"Token has been sent");
            uint tokenai = 400000 * (1 ether / 1 wei);
            balances[msg.sender] += tokenai;
            totalSoldTokens+= tokenai;
            ai_balout=false;
            emit unlock(msg.sender,tokenai);
        }else if(msg.sender==teamTokenBonus){
            require(uint40(block.timestamp) >= CREATE_CONTRACT +( 365 * 86400),"LOCKED"); //lock for 12 month
            require(teamTokenBonus_balout==true,"Token has been sent");
            uint tokenteam = 150000 * (1 ether / 1 wei);
            balances[msg.sender] += tokenteam;
            totalSoldTokens+= tokenteam;
            teamTokenBonus_balout=false;
            emit unlock(msg.sender,tokenteam);
        }else if(msg.sender==privateSales){
            require(uint40(block.timestamp) >= CREATE_CONTRACT +( 182 * 86400),"LOCKED"); //lock for 6 month
            require(privateSales_balout==true,"Token has been sent");
            uint tokenprivate = 100000 * (1 ether / 1 wei);
            balances[msg.sender] += tokenprivate;
            privateSales_balout=false;
            totalSoldTokens+= tokenprivate;
            emit unlock(msg.sender,tokenprivate);
        }
    }
    

/// Overrides:
    function transfer(address _to, uint256 _value)public returns(bool){
        require(enableTransfers,"TRANSFER DISABLED");
        
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns(bool){
        require(enableTransfers,"TRANSFER DISABLED");
        return super.transferFrom(_from,_to,_value);
    }

    function approve(address _spender, uint256 _value)public returns (bool) {
        require(enableTransfers,"TRANSFER DISABLED");
        return super.approve(_spender,_value);
    }

/// Setters/getters
    function setTokenManager(address _mgr) public onlyTokenManager
    {
        tokenManager = _mgr;
    }

    // Default fallback function
    function()public payable 
    {
        buyTokens();
    }
}