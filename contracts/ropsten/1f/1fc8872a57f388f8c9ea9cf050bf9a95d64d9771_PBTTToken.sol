pragma solidity ^0.4.24;

// Implements a simple ownership model with 2-phase transfer.
contract Owned {

    address public owner;
    address public proposedOwner;

    constructor() public
    {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender) == true);
        _;
    }


    function isOwner(address _address) public view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        require(_proposedOwner != address(0), &#39;Require proposedOwner != address(0)&#39;);
        require(_proposedOwner != address(this), &#39;Require proposedOwner != address(this)&#39;);
        require(_proposedOwner != owner, &#39;Require proposedOwner != owner&#39;);

        proposedOwner = _proposedOwner;
        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {
        require(msg.sender == proposedOwner, &#39;Require msg.sender == proposedOwner&#39;);

        owner = msg.sender;
        proposedOwner = address(0);

        return true;
    }
}

// ----------------------------------------------------------------------------
// OpsManaged - Implements an Owner and Ops Permission Model
// ----------------------------------------------------------------------------

//
// Implements a security model with owner and ops.
//
contract OpsManaged is Owned {

    address public opsAddress;


    constructor() public
        Owned()
    {
    }


    modifier onlyOwnerOrOps() {
        require(isOwnerOrOps(msg.sender), &#39;Require only owner or ops&#39;);
        _;
    }


    function isOps(address _address) public view returns (bool) {
        return (opsAddress != address(0) && _address == opsAddress);
    }


    function isOwnerOrOps(address _address) public view returns (bool) {
        return (isOwner(_address) || isOps(_address));
    }


    function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool) {
        require(_newOpsAddress != owner, &#39;Require newOpsAddress != owner&#39;);
        require(_newOpsAddress != address(this), &#39;Require newOpsAddress != address(this)&#39;);

        opsAddress = _newOpsAddress;

        return true;
    }
}

// ----------------------------------------------------------------------------
// Finalizable - Implement Finalizable (Crowdsale) model
// ----------------------------------------------------------------------------

contract Finalizable is OpsManaged {

    FinalizableState public finalized;
    enum FinalizableState { 
        None,
        Finalized
    }

    event Finalized();


    constructor() public OpsManaged()
    {
        finalized = FinalizableState.None;
    }


    function finalize() public onlyOwner returns (bool success) {
        require(finalized == FinalizableState.None, &#39;Require !finalized&#39;);

        finalized = FinalizableState.Finalized;

        emit Finalized();

        return true;
    }
}
// ----------------------------------------------------------------------------
// Math - Implement Math Library
// ----------------------------------------------------------------------------

library Math {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 r = a + b;

        require(r >= a, &#39;Require r >= a&#39;);

        return r;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, &#39;Require a >= b&#39;);

        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 r = a * b;

        require(r / a == b, &#39;Require r / a == b&#39;);

        return r;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC20Interface - Standard ERC20 Interface Definition
// Enuma Blockchain Platform
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Based on the final ERC20 specification at:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC20Token - Standard ERC20 Implementation
// Enuma Blockchain Platform
//
// ----------------------------------------------------------------------------



contract ERC20Token is ERC20Interface {

    using Math for uint256;

    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) allowed;


    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        // The initial balance of tokens is assigned to the given token holder address.
        balances[_initialTokenHolder] = _totalSupply;

        // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
        emit Transfer(0x0, _initialTokenHolder, _totalSupply);
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            emit Transfer(msg.sender, _to, _value);

            return true;
        } else { 
            return false;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            return true;
        } else { 
            return false;
        }
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
}

// ----------------------------------------------------------------------------
// FinalizableToken - Extension to ERC20Token with ops and finalization
// ----------------------------------------------------------------------------

//
// ERC20 token with the following additions:
//    1. Owner/Ops Ownership
//    2. Finalization
//
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

    using Math for uint256;


    // The constructor will assign the initial token supply to the owner (msg.sender).
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
        ERC20Token(_name, _symbol, _decimals, _totalSupply, msg.sender)
        Finalizable()
    {
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to);

        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }


    function validateTransfer(address _sender, address _to) internal view {
        // Once the token is finalized, everybody can transfer tokens.
        if (finalized == FinalizableState.Finalized) {
            return;
        }

        if (isOwner(_to)) {
            return;
        }

        // Before the token is finalized, only owner and ops are allowed to initiate transfers.
        // This allows them to move tokens while the sale is still in private sale.
        require(isOwnerOrOps(_sender), &#39;Require is owner or ops allowed to initiate transfer&#39;);
    }
}



// ----------------------------------------------------------------------------
// PBTT Token Contract Configuration
//
// The MIT Licence.
// ----------------------------------------------------------------------------


contract PBTTTokenConfig {

    string  internal constant TOKEN_SYMBOL      = &#39;PBTT&#39;;
    string  internal constant TOKEN_NAME        = &#39;Purple Butterfly Token (PBTT)&#39;;
    uint8   internal constant TOKEN_DECIMALS    = 3;

    uint256 internal constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 internal constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}


// ----------------------------------------------------------------------------
// PBTT Token Contract
// ----------------------------------------------------------------------------

contract PBTTToken is FinalizableToken, PBTTTokenConfig {
    
    HaltState public halts;
    uint256 public buyPriceEth = 0.0002 ether;                              // Buy price for PBTT
    uint256 public sellPriceEth = 0.0002 ether;                             // Sell price for PBTT
    uint256 public gasForPBTT = 0.005 ether;                                // Eth from contract against PBTT to pay tx (10 times sellPriceEth)
    uint256 public PBTTForGas = 1;                                          // PBTT to contract against eth to pay tx
    uint256 public gasReserve = 1 ether;                                    // Eth amount that remains in the contract for gas and can&#39;t be sold
    uint256 public minBalanceForAccounts = 0.01 ether;                      // Minimal eth balance of sender and recipient
    uint256 public totalTokenSold = 0;
    //
    // Events
    //

    enum HaltState { 
        Halted,
        Unhalted
    }
 
    constructor() public
        FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY)
    {
        halts = HaltState.Unhalted;
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(halts == HaltState.Unhalted, &#39;Require smart contract is not in halted state&#39;);

        if (_value < PBTTForGas) {
            // Prevents drain and spam
            revert();                            
        }
      
        if (!isOwnerOrOps(msg.sender) && _to == address(this)) {
            // Trade PBTT against eth by sending to the token contract
            sellPBTTAgainstEther(_value);                             
            return true;
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(halts == HaltState.Unhalted, &#39;Require smart contract is not in halted state&#39;);
        return super.transferFrom(_from, _to, _value);
    }
    
    //Change PPBT Selling and Buy Price
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) public onlyOwner {
        // Set prices to buy and sell PBTT
        buyPriceEth = newBuyPriceEth;                                       
        sellPriceEth = newSellPriceEth;
    }

    function setGasForPBTT(uint newGasAmountInWei) public onlyOwner {
        gasForPBTT = newGasAmountInWei;
    }

    //set PBTT to contract against eth to pay tx
    function setPBTTForGas(uint newPBTTAmount) public onlyOwner {
        PBTTForGas = newPBTTAmount;
    }

    function setGasReserve(uint newGasReserveInWei) public onlyOwner {
        gasReserve = newGasReserveInWei;
    }

    function setMinBalance(uint minimumBalanceInWei) public onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }

    function getTokenRemaining() public view returns (uint256 total){
        return (TOKEN_TOTALSUPPLY / DECIMALSFACTOR) - totalTokenSold;
    }

    function () payable public {
        if (msg.sender != owner) {
            // validateTransfer(owner, msg.sender);
            require(finalized == FinalizableState.None, &#39;Require smart contract is not finalized&#39;);
            require(halts == HaltState.Unhalted, &#39;Require smart contract is not halted&#39;);
            buyPBTTAgainstEther();                                    
        } 
    } 

    /* User buys PBTT and pays in Ether */
    function buyPBTTAgainstEther() private returns (uint amount) {
        // Avoid dividing 0, sending small amounts and spam
        if (buyPriceEth == 0 || msg.value < buyPriceEth)
        {            
            revert(); 
        }   

        // Calculate the amount of PBTT
        amount = (msg.value / buyPriceEth) * DECIMALSFACTOR;                
        
        // Check if it has enough to sell
        if (balances[owner] < amount) 
        { 
            revert();                             
        }
        
        // Add the amount to buyer&#39;s balance
        balances[msg.sender] = balances[msg.sender].add(amount);            

        // Subtract amount from PBTT balance
        balances[owner] = balances[owner].sub(amount);

        // Execute an event reflecting the change
        emit Transfer(owner, msg.sender, amount);                           
        
        totalTokenSold = totalTokenSold + amount;
		
        return amount;
    }

    function sellPBTTAgainstEther(uint256 amount) private returns (uint revenue) {
        // Avoid selling and spam
        if (sellPriceEth == 0 || amount < PBTTForGas) 
        {
            revert();
        }      

        // Check if the sender has enough to sell
        if (balances[msg.sender] < amount) {
            revert();
        }                    

        // Revenue = eth that will be send to the user
        revenue = amount.mul(sellPriceEth);                                 

        // Keep min amount of eth in contract to provide gas for transactions
        uint256 remaining = address(this).balance.sub(revenue);
        if (remaining < gasReserve)
        { 
            revert();      
        }

        msg.sender.transfer(revenue);

        balances[owner] = balances[owner].add(amount);                      // Add the amount to Dentacoin balance
        balances[msg.sender] = balances[msg.sender].sub(amount);            // Subtract the amount from seller&#39;s balance
        emit Transfer(owner, msg.sender, revenue);                          // Execute an event reflecting on the change
        return revenue;                                                     // End function and returns

    }

    // Allows a token holder to burn tokens. Once burned, tokens are permanently
    // removed from the total supply.
    function burn(uint256 _amount) public returns (bool success) {
        require(_amount > 0);

        address account = msg.sender;
        require(_amount <= balanceOf(account));

        balances[account] = balances[account].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        return true;
    }

    // Allows the owner to reclaim tokens that are assigned to the token contract itself.
    function reclaimTokens() public onlyOwner returns (bool) {

        address account = address(this);
        uint256 amount = balanceOf(account);

        if (amount == 0) {
            return false;
        }

        balances[account] = balances[account].sub(amount);
        balances[owner] = balances[owner].add(amount);

        return true;
    }

    // Allows the owner to withdraw that are assigned to the token contract itself.
    function withdrawFundToOwner () public onlyOwner {
        // transfer to owner
        uint256 eth = address(this).balance; 
        owner.transfer(eth);
    }

    // Allows the owner to withdraw all fund from contract to owner&#39;s specific adress
    function withdrawFundToAddress (address _ownerOtherAdress) public onlyOwner {
        // transfer to owner
        uint256 eth = address(this).balance; 
        _ownerOtherAdress.transfer(eth);
    }

    /* Halts or unhalts direct trades without the sell/buy functions below */
    function haltsTrades() public onlyOwner returns (bool) {
        halts = HaltState.Halted;
        return halts == HaltState.Halted;
    }

    function unhaltsTrades() public onlyOwner returns (bool) {
        halts = HaltState.Unhalted;
        return halts == HaltState.Unhalted;
    }
}