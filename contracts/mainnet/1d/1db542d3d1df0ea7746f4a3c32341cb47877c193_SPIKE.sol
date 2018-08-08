pragma solidity ^0.4.20;
// ----------------------------------------------------------------------------------------------
// SPIKE Token by SPIKING Limited.
// An ERC223 standard
//
// author: SPIKE Team
// Contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="31525d545c545f714241585a585f561f585e">[email&#160;protected]</a>

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

contract ERC20 {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    // approve an address with _value amount of tokens
    function approve(address _spender, uint256 _value) public returns (bool success);

    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC223 is ERC20{
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
}

/// contract receiver interface
contract ContractReceiver {  
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

contract BasicSPIKE is ERC223 {
    using SafeMath for uint256;
    
    uint256 public constant decimals = 10;
    string public constant symbol = "SPIKE";
    string public constant name = "Spiking";
    uint256 public _totalSupply = 10 ** 20; // total supply is 10^20 unit, equivalent to 10 Billion SPIKE

    // Owner of this contract
    address public owner;

    // tradable
    bool public tradable = false;

    // Balances SPIKE for each account
    mapping(address => uint256) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
            
    /**
     * Functions with this modifier can only be executed by the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isTradable(){
        require(tradable == true || msg.sender == owner);
        _;
    }

    /// @dev Constructor
    function BasicSPIKE() 
    public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
    /// @dev Gets totalSupply
    /// @return Total supply
    function totalSupply()
    public 
    constant 
    returns (uint256) {
        return _totalSupply;
    }
        
    /// @dev Gets account&#39;s balance
    /// @param _addr Address of the account
    /// @return Account balance
    function balanceOf(address _addr) 
    public
    constant 
    returns (uint256) {
        return balances[_addr];
    }
    
    
    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) 
    private 
    view 
    returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
 
    /// @dev Transfers the balance from msg.sender to an account
    /// @param _to Recipient address
    /// @param _value Transfered amount in unit
    /// @return Transfer status
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /// @dev Function that is called when a user or another contract wants to transfer funds .
    /// @param _to Recipient address
    /// @param _value Transfer amount in unit
    /// @param _data the data pass to contract reveiver
    function transfer(
        address _to, 
        uint _value, 
        bytes _data) 
    public
    isTradable 
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        if(isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
        }
        
        return true;
    }
    
    /// @dev Function that is called when a user or another contract wants to transfer funds .
    /// @param _to Recipient address
    /// @param _value Transfer amount in unit
    /// @param _data the data pass to contract reveiver
    /// @param _custom_fallback custom name of fallback function
    function transfer(
        address _to, 
        uint _value, 
        bytes _data, 
        string _custom_fallback) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);

        if(isContract(_to)) {
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }
         
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
    public
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        return true;
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) 
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    // get allowance
    function allowance(address _owner, address _spender) 
    public
    constant 
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // withdraw any ERC20 token in this contract to owner
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC223(tokenAddress).transfer(owner, tokens);
    }
    
    // allow people can transfer their token
    // NOTE: can not turn off
    function turnOnTradable() 
    public
    onlyOwner{
        tradable = true;
    }
}

contract SPIKE is BasicSPIKE {

    bool public _selling = true;//initial selling
    
    uint256 public _originalBuyPrice = 50000 * 10**10; // original buy 1ETH = 50000 SPIKE = 50000 * 10**10 unit

    // List of approved investors
    mapping(address => bool) private approvedInvestorList;
    
    // deposit
    mapping(address => uint256) private deposit;
    
    // icoPercent
    uint256 public _icoPercent = 30;
    
    // _icoSupply is the avalable unit. Initially, it is _totalSupply
    uint256 public _icoSupply = (_totalSupply * _icoPercent) / 100;
    
    // minimum buy 0.3 ETH
    uint256 public _minimumBuy = 3 * 10 ** 17;
    
    // maximum buy 25 ETH
    uint256 public _maximumBuy = 25 * 10 ** 18;

    // totalTokenSold
    uint256 public totalTokenSold = 0;

    /**
     * Functions with this modifier check on sale status
     * Only allow sale if _selling is on
     */
    modifier onSale() {
        require(_selling);
        _;
    }
    
    /**
     * Functions with this modifier check the validity of address is investor
     */
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
    /**
     * Functions with this modifier check the validity of msg value
     * value must greater than equal minimumBuyPrice
     * total deposit must less than equal maximumBuyPrice
     */
    modifier validValue(){
        // require value >= _minimumBuy AND total deposit of msg.sender <= maximumBuyPrice
        require ( (msg.value >= _minimumBuy) &&
                ( (deposit[msg.sender].add(msg.value)) <= _maximumBuy) );
        _;
    }

    /// @dev Fallback function allows to buy by ether.
    function()
    public
    payable {
        buySPIKE();
    }
    
    /// @dev buy function allows to buy ether. for using optional data
    function buySPIKE()
    public
    payable
    onSale
    validValue
    validInvestor {
        uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10**18;
        require(balances[owner] >= requestedUnits);
        // prepare transfer data
        balances[owner] = balances[owner].sub(requestedUnits);
        balances[msg.sender] = balances[msg.sender].add(requestedUnits);
        
        // increase total deposit amount
        deposit[msg.sender] = deposit[msg.sender].add(msg.value);
        
        // check total and auto turnOffSale
        totalTokenSold = totalTokenSold.add(requestedUnits);
        if (totalTokenSold >= _icoSupply){
            _selling = false;
        }
        
        // submit transfer
        Transfer(owner, msg.sender, requestedUnits);
        owner.transfer(msg.value);
    }

    /// @dev Constructor
    function SPIKE() BasicSPIKE()
    public {
        setBuyPrice(_originalBuyPrice);
    }
    
    /// @dev Enables sale 
    function turnOnSale() onlyOwner 
    public {
        _selling = true;
    }

    /// @dev Disables sale
    function turnOffSale() onlyOwner 
    public {
        _selling = false;
    }
    
    /// @dev set new icoPercent
    /// @param newIcoPercent new value of icoPercent
    function setIcoPercent(uint256 newIcoPercent)
    public 
    onlyOwner {
        _icoPercent = newIcoPercent;
        _icoSupply = (_totalSupply * _icoPercent) / 100;
    }
    
    /// @dev set new _maximumBuy
    /// @param newMaximumBuy new value of _maximumBuy
    function setMaximumBuy(uint256 newMaximumBuy)
    public 
    onlyOwner {
        _maximumBuy = newMaximumBuy;
    }

    /// @dev Updates buy price (owner ONLY)
    /// @param newBuyPrice New buy price (in UNIT) 1ETH <=> 100 000 0000000000 unit
    function setBuyPrice(uint256 newBuyPrice) 
    onlyOwner 
    public {
        require(newBuyPrice>0);
        _originalBuyPrice = newBuyPrice; // unit
        // control _maximumBuy_USD = 10,000 USD, SPIKE price is 0.01USD
        // maximumBuy_SPIKE = 1000,000 SPIKE = 1000,000,0000000000 unit = 10^16
        _maximumBuy = (10**18 * 10**16) /_originalBuyPrice;
    }
    
    /// @dev check address is approved investor
    /// @param _addr address
    function isApprovedInvestor(address _addr)
    public
    constant
    returns (bool) {
        return approvedInvestorList[_addr];
    }
    
    /// @dev get ETH deposit
    /// @param _addr address get deposit
    /// @return amount deposit of an buyer
    function getDeposit(address _addr)
    public
    constant
    returns(uint256){
        return deposit[_addr];
}
    
    /// @dev Adds list of new investors to the investors list and approve all
    /// @param newInvestorList Array of new investors addresses to be added
    function addInvestorList(address[] newInvestorList)
    onlyOwner
    public {
        for (uint256 i = 0; i < newInvestorList.length; i++){
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }

    /// @dev Removes list of investors from list
    /// @param investorList Array of addresses of investors to be removed
    function removeInvestorList(address[] investorList)
    onlyOwner
    public {
        for (uint256 i = 0; i < investorList.length; i++){
            approvedInvestorList[investorList[i]] = false;
        }
    }
    
    /// @dev Withdraws Ether in contract (Owner only)
    /// @return Status of withdrawal
    function withdraw() onlyOwner 
    public 
    returns (bool) {
        return owner.send(this.balance);
    }
}