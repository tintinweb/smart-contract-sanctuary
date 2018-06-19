pragma solidity ^0.4.23;

contract APS{
    string public name; // AutopaymentParkingSystem
    string public symbol; // APS
    uint256 public decimals = 18;
    uint256 public totalSupply; 
    address public centralMinter; // Urbana
    uint256 public divisor; // Denominator used with buyPrice, sellPrice. If value(APS) > value(ETH), divisor = 1. Otherwise, divisor = 10**N()
    uint256 public buyPrice; // Numerator used with divisor. 1 APS = ($buyPrice) ETH.
    uint256 public sellPrice;  // Numerator used with divisor. 1 APS = ($sellPrice) ETH.

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) allowed;
    mapping (address => bool) public frozenAccount; // freezing balances of invalid account

    event SetPrice(uint256 buyPrice, uint256 sellPrice);
    event MintToken(uint256 amount);
    event BurnToken(uint256 amount);
    event FrozenAccounts(address target, bool frozen);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    
    function APS(
        string tokenName,
        string tokenSymbol,
        uint256 initialSupply
    ) public {
        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = initialSupply * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply; 
        centralMinter = msg.sender;
    }

    modifier onlyCentralMinter {
        require(msg.sender == centralMinter);
        _;
    }

    /*  
     * CentralMinter Functions 
     * Functions related with controlling amount of APS in circulation
     * Functions related with controlling node accounts
     */

    // Set buy/sell price of APS
    function setPrices(uint256 newBuyPrice,uint256 newSellPrice, uint256 newDivisor) public onlyCentralMinter {
        buyPrice = newBuyPrice;
        sellPrice = newSellPrice;
        divisor = newDivisor;
        emit SetPrice(buyPrice,sellPrice);
    }

    // Issue new tokens in circulation
    function mintToken(uint256 mintedAmount) public onlyCentralMinter{
        balanceOf[centralMinter] += mintedAmount;
        totalSupply += mintedAmount;
        emit MintToken(mintedAmount);
    }

    // Remove tokens from circulation to control token prcie
    function burnToken(uint256 burnedAmount) public onlyCentralMinter{
        balanceOf[centralMinter] -= burnedAmount;
        totalSupply -= burnedAmount;
        emit BurnToken(burnedAmount);
    }

    function freezeAccount(address target,bool freeze) public onlyCentralMinter{
        frozenAccount[target] = freeze;
        emit FrozenAccounts(target,freeze);
    }

    /*  
     * Node functions
     * Functions related with buying/selling APS
     * ERC20 Token functions
     */
    
    function buy() payable public returns (uint256 amount) {
        if(divisor == 1) amount = msg.value / buyPrice;
        else amount = msg.value * (divisor/buyPrice);
        require(balanceOf[centralMinter]>= amount);
        balanceOf[msg.sender] += amount;
        balanceOf[centralMinter] -= amount;
        emit Transfer(centralMinter,msg.sender,amount);
        return amount;       
    }

    
    function sell(uint256 amount) payable public returns (uint256 revenue) {
        require(balanceOf[msg.sender]>=amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[centralMinter] += amount;
        revenue = amount * sellPrice / divisor;
        msg.sender.transfer(revenue); 
        emit Transfer(msg.sender,centralMinter,amount);
        return revenue;
    }

    /*  ERC20 Token Functions
     *  NOTE : ERC223, ERC721 could be used as an alternative to current ERC20 Tokens
     */

    // ERC20 Standard: Get the total token supply
    function totalSupply() public constant returns (uint256){
        return totalSupply;
    }

    // ERC20 Standard: Get the account balance of another account with address tokenOwner
    function balanceOf(address _owner) public constant returns (uint256 balance){
        return balanceOf[_owner];
    }

    // ERC20 Standard: Returns the amount which spender is still allowed to withdraw from tokenOwner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(balanceOf[_from]>= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 totalBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
        assert(totalBalances == balanceOf[_from] + balanceOf[_to]);
    }

    // ERC20 Standard: Send tokens amount of tokens to address to
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender,_to,_value);
        return true;
    }

    // ERC20 Standard: Allow spender to withdraw from your account, multiple times, up to the tokens amount. 
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != 0x0);
        require(balanceOf[msg.sender]>=_value);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    // ERC20 Standard: send tokens from address from to address to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowed[_from][msg.sender]>=_value);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        // emit Transfer(msg.sender,_from,_to,_value);
        emit Transfer(_from,_to,_value);
        return true;
    }
}