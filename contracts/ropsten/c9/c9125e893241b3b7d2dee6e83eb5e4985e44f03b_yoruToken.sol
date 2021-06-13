/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: Unlinced

pragma solidity >=0.7.0 <0.9.0;

contract yoruToken {
    address payable public owner;
    address public xOwner;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public Nights = 1001;
    uint256 public exchangeRatio;
    uint256 public meltedTokens;
    bool public mintable;

    
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Melt(address indexed from, uint256 _value);
    event Minted(address indexed from, uint256 _value);
    event MeltOthers(address indexed from, address indexed to, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner, "Owner Only");
        _;
    }
    
    
    constructor()    {
        owner = payable(msg.sender);
        totalSupply = Nights * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply/4;           // You understand it
        meltedTokens = 3*(totalSupply/4);                 // This line is clear if you understand what is standing above 
        name = "Yoru";                                   // Set the name for display purposes
        symbol = "YOR";                               // Set the symbol for display purposes
        mintable = true;
        exchangeRatio = 100;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        xOwner = owner;
        emit OwnershipTransferred(owner, newOwner);
        owner = payable(newOwner);
    }
    
    
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value, "Insufficient tokens");
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
     * Smelt tokens
     * 
     * Put tokens in the smith, with no return
     */
    function melt(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient tokens");
        balanceOf[msg.sender] -= _value;
        meltedTokens += _value;
        emit Melt(msg.sender, _value);
        return true;
    }

    /**
     * Mint tokens
     * 
     * NOT FREE!
     */
    receive() external payable {
        uint _toExchange = msg.value;
        require(_toExchange > 0);
        uint _value = _toExchange * exchangeRatio;
        require(meltedTokens >= _value, "Not enough tokens to reforge");
        meltedTokens -= _value;
        balanceOf[msg.sender] += _value;
        emit Minted(msg.sender, _value);
    }

    
    /**
     * Melt tokens of someone else
     * 
     * Almost the same as melt but without returning
     */
     function meltFrom(address _address, uint256 _value) public onlyOwner returns  (bool success){
        require(balanceOf[_address] >= _value, "Insufficient tokens");
        balanceOf[_address] -= _value;
        meltedTokens += _value;
        emit MeltOthers(msg.sender, _address, _value);
        return true;
     }
     
    function priceAvailabilityTime(uint256 _ratio, bool _canMint, uint256) public onlyOwner {
        exchangeRatio = _ratio;
        mintable = _canMint;
    }

    function withdraw(uint256 _amount) public onlyOwner returns (bool) {
        payable(msg.sender).transfer(_amount);
        return false;
    }


}