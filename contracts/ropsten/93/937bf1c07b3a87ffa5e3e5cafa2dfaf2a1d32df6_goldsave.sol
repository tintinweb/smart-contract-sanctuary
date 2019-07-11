pragma solidity ^0.5.1;

import "./owned.sol";
import "./safemath.sol";
import "./erc20.sol";

contract goldsave is owned, ERC20 {
    using SafeMath for uint256;
    //coin details
    string public name = "goldsave";  
    string public symbol = "GAVE";
    uint256 public TotalSupply;
    address public contractAddress = address(this); 
    uint8 public decimals = 18;
    // This creates an array with all balances
    mapping (address => uint256) public BalanceOf;
    mapping (address => mapping (address => uint256)) public Allowance;
    //ether exchg details
    uint256 public buyPriceEth = 1 ether;                                  // Buy price 
    uint256 public sellPriceEth = 1 ether;                                 // Sell price 

    constructor (uint256 initialSupply, uint256 ownerSupply) public owned(){
        require(initialSupply >= ownerSupply);
        TotalSupply = initialSupply.mul(10 ** uint256(decimals));  // Update total supply with the decimal amount
        uint256 ownertotalSupply = ownerSupply.mul(10 ** uint256(decimals));
        BalanceOf[contractAddress] = TotalSupply.sub(ownertotalSupply);
        BalanceOf[msg.sender] = ownertotalSupply;
    }
    event Withdraw(address indexed owner, uint256 withdrawal, uint256 blockNumber);
    function withdraw(uint256 _eth) public onlyOwner{
        address payable _owner = address( uint160(owner) );
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
        return TotalSupply;
    }
    function allowance(address _giver, address _spender) public view returns (uint256){
        return Allowance[_giver][_spender];
    }
    function balanceOf(address who) public view returns (uint256){
        return BalanceOf[who];
    }
    //the transfer function core
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require( (_to) != address(0x0) );
        // Check if the sender has enough
        require(BalanceOf[_from] >= _value);
        // Check for overflows
        require(BalanceOf[_to] + _value >= BalanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = BalanceOf[_from] + BalanceOf[_to];
        // Subtract from the sender
        BalanceOf[_from] -= _value;
        // Add the same to the recipient
        BalanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(BalanceOf[_from] + BalanceOf[_to] == previousBalances);
    }
    //user can transfer from an address that allowed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= Allowance[_from][msg.sender]);     // Check allowance
        Allowance[_from][msg.sender] -= _value;
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
    function notedTransfer (address _to, uint256 _value, string memory _note) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        emit noted_transfer(msg.sender, _to, _value, _note, block.number);
        return true;
    }
    event noted_transfer(address indexed from, address indexed to, uint256 value, string note, uint256 blockNumber);
    //give allowance for transfer to a user (spender)
    function approve(address _spender, uint256 _value) public returns (bool success) {
        Allowance[msg.sender][_spender] = _value;
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
        require (BalanceOf[contractAddress] >= totalAmount);                              // Check if it has enough to sell
        BalanceOf[contractAddress] = BalanceOf[contractAddress]-(totalAmount);                   // Subtract amount from balance
        BalanceOf[msg.sender] = BalanceOf[msg.sender]+(totalAmount);       // Add the amount to buyer&#39;s balance
        emit Transfer(contractAddress, msg.sender, totalAmount);                                 // Execute an event reflecting the change
        emit noted_transfer(contractAddress, msg.sender, totalAmount, &#39;BuyFromEth&#39;, block.number);
        return totalAmount;
    }
    /* User sells and gets Ether */
    function sellToEther(uint256 amountOFGoldsave) public returns (uint ethToBeClaimed) {
        require (BalanceOf[msg.sender] >= amountOFGoldsave);                           // Check if the sender has enough to sell
        ethToBeClaimed = amountOFGoldsave * (sellPriceEth);                            // ethToBeClaimed = eth that will be send to the user
        uint256 amountOFGoldsaveWei =(amountOFGoldsave * (10 ** uint256(decimals)));
        emit Transfer(msg.sender, contractAddress, amountOFGoldsaveWei);                            // Execute an event reflecting on the change
        emit noted_transfer(msg.sender, contractAddress, amountOFGoldsaveWei, &#39;SellToEth&#39;, block.number);
        BalanceOf[msg.sender] -= amountOFGoldsaveWei;   // Subtract the amount from seller&#39;s balance
        BalanceOf[contractAddress] +=(amountOFGoldsaveWei);               // Add the amount to balance
        msg.sender.transfer(ethToBeClaimed);
        return ethToBeClaimed;                                                 // End function and returns
    }

}