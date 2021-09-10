/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-07
*/

pragma solidity 0.5.16; /*

/**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract BabyDogeToken is owned {


    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "BabyDoge";
    string constant private _symbol = "BDoge";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply = 10000000000 * (10**_decimals);         //10 Billion tokens
    uint256 constant public maxSupply = 10000000000 * (10**_decimals);    //10 Billion tokens
    bool public safeguard;  //putting safeguard on will halt all non-owner functions

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
    function name() public pure returns(string memory){
        return _name;
    }

    /**
     * Returns symbol of token
     */
    function symbol() public pure returns(string memory){
        return _symbol;
    }

    /**
     * Returns decimals of token
     */
    function decimals() public pure returns(uint256){
        return _decimals;
    }

    /**
     * Returns totalSupply of token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Returns balance of token
     */
    function balanceOf(address user) public view returns(uint256){
        return _balanceOf[user];
    }

    /**
     * Returns allowance of token
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {

        //checking conditions
        require(!safeguard);
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen

        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient

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
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //no need to check for input validations, as that is ruled by SafeMath
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //checking of allowance and token value is done by SafeMath
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
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
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
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
    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    constructor() public{
        //sending all the tokens to Owner
        _balanceOf[owner] = _totalSupply;

        //firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }

    //It just accepts ETH
    function () external payable {
    }

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
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
        require(!safeguard);
        //checking of allowance and token value is done by SafeMath
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        _totalSupply = _totalSupply.sub(_value);                                   // Update totalSupply
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }


    /**
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }

    /**
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintedAmount the amount of tokens it will receive
        */
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require(_totalSupply.add(mintedAmount) <= maxSupply, "Cannot Mint more than maximum supply");
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }



    /**
        * Owner can transfer tokens from contract to owner address
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
    }

    //Just in rare case, owner wants to transfer Ether from contract to owner address
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }

    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }



    /*************************************/
    /*    Section for User Air drop      */
    /*************************************/

    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }



}