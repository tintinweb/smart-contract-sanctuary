pragma solidity ^0.4.25;

import "./owned.sol";
import "./safemath.sol";
import "./erc20.sol";

contract goldcash is owned, ERC20 {
    using SafeMath for uint256;
    //coin details
    string public name = "goldcash";  
    string public symbol = "GAS";
    uint256 public totalSupply;
    address public contractAddress = this; 
    uint8 public decimals = 18;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    //ether exchg details
    uint256 public buyPriceEth = 1 finney;                                  // Buy price 
    uint256 public sellPriceEth = 1 finney;                                 // Sell price 

    constructor (uint256 initialSupply, uint256 ownerSupply) public owned(){
        require(initialSupply >= ownerSupply);
        totalSupply = initialSupply.mul(10 ** uint256(decimals));  // Update total supply with the decimal amount
        uint256 ownertotalSupply = ownerSupply.mul(10 ** uint256(decimals));
        balanceOf[contractAddress] = totalSupply.sub(ownertotalSupply);
        balanceOf[msg.sender] = ownertotalSupply;
    }
    event Withdraw(address indexed owner, uint256 withdrawal, uint256 blockNumber);
    function withdraw(uint256 _eth) public onlyOwner{
        address _owner = owner;
        uint256 oldBal = _eth;//address(this).balance;
        //_owner.transfer(address(this).balance);
        emit Withdraw(_owner, oldBal, block.number);
        _owner.transfer(_eth);
    }
    function set_sellPriceEth(uint256 _eth) public onlyOwner returns (uint256){
        require(_eth > 0);
        uint256 oldValue = sellPriceEth;
        sellPriceEth = _eth;
        emit chg_setting(owner, oldValue, sellPriceEth, "set_sellPriceEth", block.number);
        return sellPriceEth;
    }
    function set_buyPriceEth(uint256 _eth) public onlyOwner returns (uint256){
        require(_eth > 0);
        uint256 oldValue = buyPriceEth;
        buyPriceEth = _eth;
        emit chg_setting(owner, oldValue, buyPriceEth, "set_buyPriceEth", block.number);
        return buyPriceEth;
    }
    event chg_setting(address indexed changer, uint256 oldValue, uint256 newValue, string indexed setting, uint256 blockNumber);
   

    /*
        For coin transaction implementing ERC20
    */
    function totalSupply() public view returns (uint256){
        return totalSupply;
    }
    function allowance(address _giver, address _spender) public view returns (uint256){
        return allowance[_giver][_spender];
    }
    function balanceOf(address who) public view returns (uint256){
        return balanceOf[who];
    }
    //the transfer function core
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
    //user can transfer from an address that allowed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    //user can transfer from their balance
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        emit noted_transfer(msg.sender, _to, _value, "", block.number);
        return true;
    }
    //transfer+note
    function notedTransfer (address _to, uint256 _value, string _note) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        emit noted_transfer(msg.sender, _to, _value, _note, block.number);
        return true;
    }
    event noted_transfer(address indexed from, address indexed to, uint256 value, string note, uint256 blockNumber);
    //give allowance for transfer to a user (spender)
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    event ETH_transaction(address indexed source, address indexed aplicant, uint256 value, string indexed act, uint256 time);
    /*
        getting by ether
    */
    function buyWithEther() public payable returns (uint amount) {
        require (buyPriceEth != 0 && msg.value >= buyPriceEth );             // Avoid dividing 0, sending small amounts and spam
        amount = msg.value/(buyPriceEth);                                   // Calculate the amount of token
        uint256 totalAmount = amount * (10 ** uint256(decimals));
        require (balanceOf[this] >= totalAmount);                              // Check if it has enough to sell
        balanceOf[this] = balanceOf[this]-(totalAmount);                   // Subtract amount from balance
        balanceOf[msg.sender] = balanceOf[msg.sender]+(totalAmount);       // Add the amount to buyer&#39;s balance
        emit Transfer(this, msg.sender, totalAmount);                                 // Execute an event reflecting the change
        emit noted_transfer(this, msg.sender, totalAmount, &#39;BuyFromEth&#39;, block.number);
        return totalAmount;
    }
    /* User sells and gets Ether */
    function sellToEther(uint256 amountOFGoldcash) public returns (uint ethToBeClaimed) {
        require (balanceOf[msg.sender] >= amountOFGoldcash);                           // Check if the sender has enough to sell
        ethToBeClaimed = amountOFGoldcash * (sellPriceEth);                            // ethToBeClaimed = eth that will be send to the user
        uint256 amountOFGoldcashWei =(amountOFGoldcash * (10 ** uint256(decimals)));
        emit Transfer(msg.sender, this, amountOFGoldcashWei);                            // Execute an event reflecting on the change
        emit noted_transfer(msg.sender, this, amountOFGoldcashWei, &#39;SellToEth&#39;, block.number);
        balanceOf[msg.sender] -= amountOFGoldcashWei;   // Subtract the amount from seller&#39;s balance
        balanceOf[this] +=(amountOFGoldcashWei);               // Add the amount to balance
        msg.sender.transfer(ethToBeClaimed);
        return ethToBeClaimed;                                                 // End function and returns
    }

}