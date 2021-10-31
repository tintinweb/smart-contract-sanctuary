/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

pragma solidity ^0.8.9;

//====================================================
// 
// Name: Medi Coin
// Symbol: MEDI
// Total Supply: 1,000,000,000 (1 billion)
// Decimals: 18
//
//
//
//====================================================



// ================================================================
//   Abstract Contract MediCoinInterface
//// @title Abstract contract to implement functions required by ERC20
// ================================================================
abstract contract MediCoinInterface {
    function totalSupply()public view virtual returns (uint256);
    function transfer(address _to, uint256 _value) public virtual returns(bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256);
    function transferFrom(address _from, address _to,  uint256 _value) public virtual returns (bool success);
    function balanceOf(address account) public view virtual returns (uint256);
    function approve(address _spender, uint256 _value) public virtual returns(bool success);
}

// ================================================================
//   Abstract Contract MediCoinSaleInterface
//// @title Abstract contract to implement functions required by ERC20
// ================================================================
abstract contract MediCoinSaleInterface {
    function multiply(uint x, uint y) internal virtual pure returns (uint z);
    function buyTokens(uint256 _numberOfTokens) public virtual payable;
    function endSale() public virtual;
}
// ================================================================
//   Main Contract
//// @title Main contract for MediCoin, implementing the MediCoinInterface
// ================================================================
contract MediCoin is MediCoinInterface{

    // Name
    string public name = "MediCoin";
    // Symbol
    string public symbol = "MEDI";
    // Standard
    string public standard = "Medi Coin v1.0";
    // Decimals 
    uint8 public decimals;
    MediCoinSale coinSale;

    uint256 public _totalSupply;


    // Transfer Event
    event Transfer(address indexed _from, address indexed _to,uint256 _value);

    // Approval Event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address  => uint) balances;
    mapping(address => mapping(address => uint256)) public allowed;

    // ================================================================
    //   CONSTRUCTOR
    //// @notice Initializes the cryptocurrency. 
    //// @dev Runs once when the crypto is initialized. Sets the decimals and total supply
    // ================================================================
    constructor () {
        decimals = 18;
        // totalSupply = _initialSupply;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[msg.sender] = _totalSupply;
    }


    // ================================================================
    //   Transfer Tokens
    //// @notice Transfers token to account
    //// @param _to (address) The address of the account to transfer tokens to
    //// @param _value (uint256) The number of tokens to transfer to the account
    //// @return (boolean) Returns true if function is successful (Required by ERC20)
    // ================================================================
    function transfer(address _to, uint256 _value) public override returns(bool success){
        require(balances[msg.sender] >= _value);
        // Changing Balances
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        // Calling transfer event
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ================================================================
    //   Total Supply
    //// @notice Gives the total supply of MediCoin available
    //// @return (uint256) Returns the total amount of MediCoin
    // ================================================================
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // ================================================================
    //   Allowance
    //// @notice Finds the number of tokens that can be send from owner to spender
    //// @return (uint256) Returns the number of tokens that can be sent from owner to spender
    // ================================================================
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    // ================================================================
    //   Transfer From
    //// @notice Transfers _value number of tokens from the _from account to the _to account
    //// @param _from (address) Address of the account to transfer tokens from
    //// @param _to (address) Address of the account to transfer tokens to
    //// @param _value (uint256) The number of tokens to be transferred
    //// @return (boolean) Returns true if function is successful (Required by ERC20)
    // ================================================================
    function transferFrom(address _from, address _to,  uint256 _value) public override returns (bool success){
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }
    // ================================================================
    //   Balance Of
    //// @notice Returns the balance of a given account
    //// @param account (address) Address of the account 
    //// @return (uint256) The number of tokens belonging to the account
    // ================================================================
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }
    // ================================================================
    //   Approve 
    //// @notice Approves the spending of _value number of tokens from _spender account
    //// @param _spender (address) The address of the account spending tokens
    //// @param _value (uint256) The number of tokens to approve transfer of
    //// @return Returns true if function is successful (Required by ERC20)
    // ================================================================
    function approve(address _spender, uint256 _value) public override returns(bool success) {
        
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}


// ================================================================
//   Token Sale Contract
//// @title Contract to handle the sale of MediCoin tokens. Implements the MediCoinSaleInterface
// ================================================================
contract MediCoinSale is MediCoinSaleInterface{

    address admin;
    uint256 public coinPrice;
    MediCoin public tokenContract;
    uint256 public coinsSold;

    event Sell(address _buyer, uint256 _amount);

    // ================================================================
    // Constructor
    //// @param _tokenContract The contract of which tokens are sold
    //// @param _coinPrice The current price of a single MediCoin in Wei
    // ================================================================
    constructor(MediCoin _tokenContract, uint256 _coinPrice) {
        admin = msg.sender;
        coinPrice = _coinPrice;
        tokenContract = _tokenContract;
    }

    // ================================================================
    //   Safe Multiplication from DS-Math
    //// @notice A safe multiplication function taken from the DS-Math library
    //// @param x (uint) First number to multiply
    //// @param y (uint) Second number to multiply
    //// @return (uint) Returns x & y multiplied together
    // ================================================================
    function multiply(uint x, uint y) internal override pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // ================================================================
    //   Token Buying
    //// @notice Allows the user to buy _tokens number of tokens
    //// @param _tokens The number of tokens to buy
    // ================================================================
    function buyTokens(uint256 _tokens) public override payable {
        require(msg.value == multiply(_tokens, coinPrice));
        require(tokenContract.balanceOf(address(this)) >= _tokens);
        require(tokenContract.transfer(msg.sender, _tokens));
        coinsSold += _tokens;
        emit Sell(msg.sender, _tokens);
    }

    // ================================================================
    //  End Sale
    //// @notice Ends the sale by sending all remaining tokens to the admin account
    // ================================================================
    function endSale() public override {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
    }
}