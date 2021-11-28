/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;


//*********************************************************************************//
//---------------------   TOKEN MAIN CODE STARTS HERE     ---------------------//
//*********************************************************************************//

    
contract TEST_Token 
{

    string constant public name = "TEST Token";
    string constant public symbol = "TST";
    uint256 constant public decimals = 18;
    uint256 public totalSupply;



    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;



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
     * Internal transfer, only can be called by this contract 
     */
    function _transfer(address _from, address _to, uint _value) internal {

        require (_from != address(0));
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        
        // overflow and undeflow checked by SafeMath Library
        balanceOf[_from] = balanceOf[_from] - _value;    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to] + _value;        // Add the same to the recipient
        
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
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
    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] - value;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    address public icoContract;
    address public ICOChanger;

    constructor() { 
        ICOChanger = msg.sender;
    }
    

    /** 
        * @notice Create `mintAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintAmount the amount of tokens it will receive
        */
    function mintToken(address target, uint256 mintAmount) public returns(bool){
        require(msg.sender == icoContract, "Invalid Caller");
        mintAmount = mintAmount;
        balanceOf[target] = balanceOf[target] + mintAmount;
        totalSupply = totalSupply + mintAmount;
        emit Transfer(address(0), target, mintAmount);
        return true;
    }


    /** 
        * @notice Change ICO Contract address if upgrade requires in future
        * @param newICOContract, new address of upgraded ICO contract
        */
    event changeICOContractEv(address newICOContract, uint timeNow);
    function changeICOContract(address newICOContract) public returns(bool){
        require(msg.sender == ICOChanger, "Invalid Caller");
        icoContract = newICOContract;
        emit changeICOContractEv(newICOContract, block.timestamp);
        return true;
    }

}