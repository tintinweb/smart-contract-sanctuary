/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/* Interface for the DOGEMEX base contract */
contract DOGEMEX_Base {
    function availableBalanceOf(address token, address user) view returns (uint256);   
    function withdraw(address token, uint256 amount) returns (bool success); 
}

// https://theethereum.wiki/w/index.php/ERC20_Token_Standard
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    // optional
    function name() external view returns (string);
    function symbol() external view returns (string);
    function decimals() external view returns (string);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/* Interface for the Uniswap Exchange contract */
contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

contract DOGEMEX_Token {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    uint256 public operationalPct = 800e15; // % that goes into the operations wallet 80%
    uint256 public buybackPct = 200e15; // % going to the uniswap contract 20%

    address public operationalAddress; // the operational address 

    function assert(bool assertion) pure {
        
        if (!assertion) {
            throw;
        }
    }

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    address public owner; // holds the address of the contract owner

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => address) public uniswapTokenContracts; // mapping of tokens to uniswapTokenContracts for swap

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    event LogUint(uint8 id, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function DOGEMEX_Token(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol, 
        address _operationalAddress
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name    = tokenName;                                   // Set the name for display purposes
        symbol  = tokenSymbol;                               // Set the symbol for display purposes
    
        operationalAddress      = _operationalAddress;
        owner = msg.sender;
    }
    
    // allows contract to receive ETH
    function () payable {}

    // Change operational wallet
    function changeOperationalAddress (address newOperationalAddress) onlyOwner {
        operationalAddress = newOperationalAddress;
    }

    // Adds an uniswap exchange contract for a new collateral token
    function setUniswapTokenContract(address token, address _uniswapTokenContract) onlyOwner  {
        uniswapTokenContracts[token]  = _uniswapTokenContract;
    }

    

    function extractFeesFromDmex (address token, address dogemexContractAddress) public
    {
        uint256 availableBalance = DOGEMEX_Base(dogemexContractAddress).availableBalanceOf(token, this);
        DOGEMEX_Base(dogemexContractAddress).withdraw(token, availableBalance);
        
        uint256 ethAmount; 
        
        if (uniswapTokenContracts[token] == address(0)) revert();
        

        if (token != address(0))
        {
            // transfer token to uniswap token contract
            ERC20Interface(token).approve(uniswapTokenContracts[token], availableBalance);

            // swap token for ETH
            ethAmount = UniswapExchangeInterface(uniswapTokenContracts[token]).tokenToEthSwapInput(availableBalance, 1, 2**256 - 1);
        }
        else
        {
            ethAmount = availableBalance;
        }

        uint256 buybackValue = safeMul(ethAmount, buybackPct) / 1e18;
        uint256 operationalValue = safeSub(ethAmount, buybackValue);
        
        // use the buybackValue to buy back tokens through the UniSwap contract
        uint256 tokens_bought = UniswapExchangeInterface(uniswapTokenContracts[address(0)]).ethToTokenSwapInput.value(buybackValue)(1, 2**256 - 1);
    
        // send the operational income share to the operational address
        if (!operationalAddress.send(operationalValue))
        {
            revert();
        }     
        
        // burn bought tokens and reduce total supply
        selfBurn(tokens_bought);
    }
    
    // used once when deploying the uniswap exchange
    function allowUniswap(uint256 tokenAmount)
    {
        allowance[this][uniswapTokenContracts[address(0)]] = tokenAmount;
    }
    
    // provides initial liquidity to the uniswap exchange
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) onlyOwner
    {
        UniswapExchangeInterface(uniswapTokenContracts[address(0)]).addLiquidity.value(ethAmount)(1, tokenAmount, 2**256 - 1);
    }
   

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }

    

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /**
     * Destroy tokens 
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function selfBurn(uint256 _value) internal returns (bool success) {
        require(balanceOf[this] >= _value);   // Check if the sender has enough
        balanceOf[this] -= _value;            // Subtract from the sender
        totalSupply -= _value;                // Updates totalSupply
        emit Burn(this, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}