/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    
    // Events
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Paused(bool isPaused);
    event OwnershipTransferred(address newOwner);
    

}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// assisted token transfers
// ----------------------------------------------------------------------------
contract MRAZToken is ERC20Interface {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address owner;
    address deputyOwner;
    bool paused = false;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        symbol = "MRAZ";
        name = "MOE RAZ TOKEN";
        decimals = 18;
        _totalSupply = 700000000000000  * 10 ** 18;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
        
    modifier onlyDeputyOrOwner() {
        require(msg.sender == owner || msg.sender == deputyOwner, "Only owner or deputy owner is allowed");
        _;
    }
    
    modifier onlyNonZeroAddress(address _user) {
        require(_user != address(0), "Zero address not allowed");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }
    
    
    modifier isPaused() {
        require( !paused, "Contract is in paused state");
        _;
    }

    
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to receiver account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address receiver, uint tokens) public override  isPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override isPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Transfer tokens from sender account to receiver account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from sender account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address sender, address receiver, uint tokens) public override isPaused returns (bool success) {
        balances[sender] = balances[sender] - tokens;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(sender, receiver, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    

    // ------------------------------------------------------------------------
    function pause(bool _flag) external onlyDeputyOrOwner {
        paused = _flag;
        emit Paused(_flag);
    }

    /**
     * @notice Increase allowance
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _addedValue amount by which allowance needs to be increased
     * @return Bool value
     */ 
    function increaseApproval(address _spender, uint256 _addedValue) public isPaused returns (bool) {
       return _increaseApproval(msg.sender, _spender, _addedValue);
    }
    
    /**
     * @notice Decrease allowance
     * @dev if the _subtractedValue is more than previous allowance, allowance will be set to 0
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _subtractedValue amount by which allowance needs to be decreases
     * @return Bool value
     */ 
    function decreaseApproval (address _spender, uint256 _subtractedValue) public isPaused returns (bool) {
        return _decreaseApproval(msg.sender, _spender, _subtractedValue);
    }
    
    
    /**
     * @notice Internal method to Increase allowance
     * @param _sender The user which allows _spender to spend on his behalf
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _addedValue amount by which allowance needs to be increased
     * @return Bool value
     */ 
    function _increaseApproval(address _sender, address _spender, uint256 _addedValue)
        internal returns (bool)
    {
        allowed[_sender][_spender] = allowed[_sender][_spender] + _addedValue;
        emit Approval(_sender, _spender, allowed[_sender][_spender]);
        return true;
    }
    
        /**
     * @notice Internal method to Decrease allowance
     * @dev if the _subtractedValue is more than previous allowance, allowance will be set to 0
     * @param _sender The user which allows _spender to spend on his behalf
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _subtractedValue amount by which allowance needs to be decreases
     * @return Bool value
     */
    function _decreaseApproval (address _sender, address _spender, uint256 _subtractedValue )
        internal returns (bool)
    {
        uint256 oldValue = allowed[_sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[_sender][_spender] = 0;
        } else {
            allowed[_sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(_sender, _spender, allowed[_sender][_spender]);
        return true;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public virtual onlyOwner onlyNonZeroAddress(_newOwner) {
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }
    
    /**
     * @notice Prevents contract from accepting ETHs
     * @dev Contracts can still be sent ETH with self destruct. If anyone deliberately does that, the ETHs will be lost
     */
    receive() external payable {
        revert("Contract does not accept ethers");
    }
    
}