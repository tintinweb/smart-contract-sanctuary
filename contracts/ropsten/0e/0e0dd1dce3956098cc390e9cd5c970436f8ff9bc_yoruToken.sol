/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: Unlinced

pragma solidity >=0.7.0 <0.9.0;

contract yoruToken {

    address payable public contractAddress;
    address payable public owner;
    address public xOwner;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public Nights = 1001;
    uint256 public exchangeRatio;
    bool public mintable;
    
    
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 _value);
    event Melt(address indexed from, uint256 _amount, uint256 _ether);
    event Minted(address indexed from, uint256 _amount, uint256 _ether);
    event MeltOthers(address indexed executor, address indexed from, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PriceChange(uint256 exchangeRatio, bool mintable);
    event Withdraw(address indexed to, uint256 _amount);

    modifier onlyOwner {
        require(msg.sender == owner, "Owner Only");
        _;
    }
    
    
    constructor()    {
        contractAddress = payable( address(this));
        owner = payable(msg.sender);
        totalSupply = Nights * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[contractAddress] = totalSupply;                 // xD
        name = "Yoru";                                   // Set the name for display purposes
        symbol = "YOR";                               // Set the symbol for display purposes
        mintable = true;
        exchangeRatio = 10000;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    function contractHolds () public view returns (uint256){
        return balanceOf[contractAddress];
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
     * Put tokens in the smith, with 95% price returning
     * Absolutely not worth to do so
     */
    function melt(uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient tokens");
        _transfer(msg.sender, contractAddress, _amount);
        uint _ether = _amount/exchangeRatio/100*95;
        require(balanceOf[contractAddress] >= _ether);
        payable(msg.sender).transfer(_ether);
        emit Melt(msg.sender, _amount, _ether);
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
        uint _amount = _toExchange * exchangeRatio;
        require(balanceOf[contractAddress] >= _amount, "Not enough tokens");
        _transfer(contractAddress, msg.sender, _amount);
        emit Minted(msg.sender, _amount, msg.value);
    }

    
    /**
     * Melt tokens of someone else
     * 
     * Almost the same as melt but without returning
     */
     function meltFrom(address _address, uint256 _amount) public onlyOwner returns  (bool success){
        require(balanceOf[_address] >= _amount, "Insufficient tokens");
        _transfer(_address, contractAddress, _amount);
        emit MeltOthers(msg.sender, _address, _amount);
        return true;
     }
     
    function priceAvailability(uint256 _ratio, bool _canMint) public onlyOwner {
        require(balanceOf[contractAddress] * _ratio/100*95 > contractAddress.balance);
        exchangeRatio = _ratio;
        mintable = _canMint;
        emit PriceChange(_ratio, _canMint);
    }

    function withdrawAdmin(uint256 _amount) public onlyOwner returns (bool) {
        require( balanceOf[contractAddress]*((_amount/exchangeRatio)/100)*95 >= _amount );
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
        return true;
    }



}