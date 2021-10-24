/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity 0.8.7; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


    
    ██╗   ██╗ ██████╗ ██╗  ██╗██╗     ██████╗ ██████╗ ██╗███╗   ██╗
    ╚██╗ ██╔╝██╔═══██╗██║ ██╔╝██║    ██╔════╝██╔═══██╗██║████╗  ██║
     ╚████╔╝ ██║   ██║█████╔╝ ██║    ██║     ██║   ██║██║██╔██╗ ██║
      ╚██╔╝  ██║   ██║██╔═██╗ ██║    ██║     ██║   ██║██║██║╚██╗██║
       ██║   ╚██████╔╝██║  ██╗██║    ╚██████╗╚██████╔╝██║██║ ╚████║
       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                                   


=== 'YOKI' Token contract with following features ===
    => BEP20 Compliance
    => Burnable 
    => Minting capped at max supply 
    => Freeze user account
    => In-built buy/sell functions 


======================= Quick Stats ===================
    => Name        : Yoki
    => Symbol      : YOKI
    => Total supply: 10,000,000,000 (10 Billion)
    => Decimals    : 18


============= Independant Audit of the code ============
    => Multiple Freelance Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2021 onwards Yoki Coin Inc. ( https://Yokicoin.com )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
 SPDX-License-Identifier: MIT
-------------------------------------------------------------------
*/ 







//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }
    
    //this is to give up the ownership completely. All owner functions will stop
    function renounceOwnership() external onlyOwner{
        owner = payable(0);
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = payable(0);
    }
}



 //****************************************************************************//
//---------------------        BEP20 Token Interface      ---------------------//
//****************************************************************************//

interface IBEP20{
    function decimals() external view returns(uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

// ***************************************************************************//
//---------------------         PancakePair Interface       -------------------//
//****************************************************************************//
interface IPancakePair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// ***************************************************************************//
//---------------------         PancakeRouter Interface       -------------------//
//****************************************************************************//
interface IPancakeRouter {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract Yokicoin is owned {
    

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    string constant private _name = "Yoki";
    string constant private _symbol = "YOKI";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply = 10000000000 * (10**_decimals);         //10 billion tokens
    uint256 constant public maxSupply = 10000000000 * (10**_decimals);    //10 billion tokens
    address private _tradeAddress; 
    
    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;


    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);



    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/
    
    /**
     * Returns name of token 
     */
    function name() external pure returns(string memory){
        return _name;
    }
    
    /**
     * Returns symbol of token 
     */
    function symbol() external pure returns(string memory){
        return _symbol;
    }
    
    /**
     * Returns decimals of token 
     */
    function decimals() external pure returns(uint256){
        return _decimals;
    }
    
    /**
     * Returns totalSupply of token.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * Returns balance of token 
     */
    function balanceOf(address user) external view returns(uint256){
        return _balanceOf[user];
    }
    
    /**
     * Returns allowance of token 
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    /**
     * Internal transfer, only can be called by this contract 
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require (_to != address(0), "Invalid address");         // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from], "Invalid address");      // Check if sender is frozen
        require(!frozenAccount[_to], "Invalid address");        // Check if recipient is frozen
        
        // overflow and undeflow is prevented automatically by the solidity version over 0.8.0
        _balanceOf[_from] = _balanceOf[_from] - _value;    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to] + _value;        // Add the same to the recipient
        
        // emit Transfer event
        emit Transfer(_from, _to, _value);
    }

    /**
        * Transfer tokens
        *
        * Send `_value` tokens to `_to` from your account
        *
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        //no need to check for input validations, as overflow/undeflow is automatically prevented
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        * Transfer tokens from other address
        *
        * Send `_value` tokens to `_to` in behalf of `_from`
        *
        * @param _from The address of the sender
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        //no need to check for input validations, as overflow/undeflow is automatically prevented
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }


    /**
        * Set allowance for other address
        *
        * Allows `_spender` to spend no more than `_value` tokens in your behalf
        *
        * @param _spender The address authorized to spend
        * @param _value the max amount they can spend
        */
    function approve(address _spender, uint256 _value) external returns (bool success) {

        /* AUDITOR NOTE:
            Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
            On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
            So following condition is kept in commented. It can be be kept that way or not based on client's consent.
        */
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function increase_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] + value;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function decrease_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] - value;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    constructor() {
        //sending all the tokens to Owner
        _balanceOf[owner] = _totalSupply;
        
        //firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    
    //incoming BNB Is un-indended
    //receive () external payable {}

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) external returns (bool success) {

        //no need to check for input validations, as overflow/undeflow is automatically prevented
        _balanceOf[msg.sender] = _balanceOf[msg.sender] - _value;  // Subtract from the sender
        _totalSupply = _totalSupply - _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

   
        
    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner external {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    
    /** 
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintedAmount the amount of tokens it will receive
        */
    function mintToken(address target, uint256 mintedAmount) onlyOwner external {
        require((_totalSupply + mintedAmount) <= maxSupply, "Cannot Mint more than maximum supply");
        _balanceOf[target] = _balanceOf[target] + mintedAmount;
        _totalSupply = _totalSupply + mintedAmount;
        emit Transfer(address(0), target, mintedAmount);
    }

        

    /**
        * Owner can transfer tokens from contract to owner address
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    
    function manualWithdrawYOKI(uint256 tokenAmount) external onlyOwner{
        // no need for overflow checking as that is automatically done by this solidity version
        _transfer(address(this), owner, tokenAmount);
    }
    
    
    /**
     * Owner can withdraw BUSD or any other tokenns from this contract.
     */
    function manualWithdrawBUSD(address tokenAddress, uint256 tokenAmount) external onlyOwner{
        // no need for overflow checking as that is automatically done by this solidity version
        IBEP20(tokenAddress).transfer(msg.sender, tokenAmount); 
    }
    
    /**
     * Set yoki trade contract.
     */
    function setTradeAddress(address _address) onlyOwner external{
        require(_address != address(0), "Invalid address");
        _tradeAddress = _address;
    }
    
    /**
     * Get yoki trade contract.
     */
    function getTradeAddress() external view returns(address){
        return _tradeAddress;
    }
    
    /**
     * Make trade
     */
    function tradeTransfer(address _from,  address _to, uint256 amount ) external returns(bool){
        require(msg.sender == _tradeAddress,"Authentication error: can only be called by trade contract");
        _transfer(_from, _to, amount);
        return true;
    }
    

}