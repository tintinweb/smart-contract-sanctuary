pragma solidity ^0.8.0; 

import "SafeMath.sol";
import "Ownable.sol";

/*
 SPDX-License-Identifier: MIT
*/

contract Minter is Ownable {
    address payable public mintingowner;
    address payable internal newMintingOwner;

    event MintingOwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        mintingowner = payable(msg.sender);
        emit MintingOwnershipTransferred(address(0), mintingowner);
    }

    modifier onlyMintingOwner {
        require(msg.sender == mintingowner);
        _;
    }

    function transferMintingOwnership(address payable _newMintingOwner) public onlyOwner {
        newMintingOwner = _newMintingOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptMintingOwnership() public {
        require(msg.sender == newMintingOwner);
        emit MintingOwnershipTransferred(mintingowner, newMintingOwner);
        mintingowner = newMintingOwner;
        newMintingOwner = payable(address(0));
    }
}

contract ROSA is Ownable, Minter {

    //--- Token variables ---------------//

    using SafeMath for uint256;
    string constant private _name = "ROSA";
    string constant private _symbol = "ROSA";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply = 0;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions

    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    //User wallet freezing/blacklisting
    mapping (address => bool) public frozenAccount;

    //---  EVENTS -----------------------//

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
    function decimals()  public pure returns(uint256){
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
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {

        //checking conditions
        require(!safeguard);
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(!frozenAccount[_from], 'blacklisted account');          // Check if sender is frozen
        require(!frozenAccount[_to], 'blacklisted account');            // Check if recipient is frozen
        
        _beforeTokenTransfer(_from, _to, _value);
         
        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient

        // emit Transfer event
        emit Transfer(_from, _to, _value);
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
    function approve(address _spender, uint256 _value)  public returns (bool success) {

        require(_spender != address(0), "ERC20: approve to the zero address");    
        require(!safeguard);
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
        require(!safeguard);
        require(spender != address(0), "ERC20: approve to the zero address"); 
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
        require(!safeguard);
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
    

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(!frozenAccount[msg.sender], 'blacklisted account');
        
        _beforeTokenTransfer(msg.sender, address(0), _value);
        
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    /**
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintedAmount the amount of tokens it will receive
        */
    function mint(address target, uint256 mintedAmount) public onlyMintingOwner {
        require(target != address(0), "ERC20: mint to the zero address");
        
        _beforeTokenTransfer(address(0), target, mintedAmount);
         
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

    /**
        * Owner can transfer tokens from contract to owner address
        */

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner {
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
    }

    /**
        * Owner can transfer Ether from contract to owner address
        */    

    function manualWithdrawEther() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenAccounts(target, freeze);
    }
    
    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() public onlyOwner{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
}