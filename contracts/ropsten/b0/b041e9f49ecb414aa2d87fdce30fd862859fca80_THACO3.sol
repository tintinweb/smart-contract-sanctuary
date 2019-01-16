pragma solidity ^0.4.21;

contract EIP20Interface {


    function totalSupply() public constant returns (uint256);
    
    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract THACO3 is EIP20Interface, Owned {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    

    uint256 price;
    uint256 _initialAmount;
    string _tokenName;
    uint8 _decimalUnits;
    string tokenSymbol;
    uint256 Maximumcaptotalsupply;
    uint256 totalSupply_;
    uint256 totalICOable_;
    address creatorofthecontract = msg.sender;


    function THACO2() public {
        balances[msg.sender] = 0;       // Give the creator all initial tokens
        totalSupply_ = 0;                // Update total supply
        price = 0.01*(10**18);        ////10^18 wei = 1 ether  //price = 0.01*(10**18); 
        Maximumcaptotalsupply = 1000000*(10**18);   // maximumcap for token creation
        totalICOable_ = 0;                // ICO available at the moment
        name = "THACO2";                     // Set the name for display purposes
        decimals = 18;                      // Amount of decimals for display purposes
        symbol = "THC2";
    }
    
    // need count totalsupply function that doesn&#39;t cost lot of gases
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function totalICOable() public view returns (uint256) {
        return totalICOable_;
    }
    
    function set_price_in_micro_ether(uint256 _value) public returns (uint256){
        if (msg.sender == creatorofthecontract){
            price = _value*(10**12); // input in micro of ether
        }
        return price;
    }
    
    function getprice() public view returns (uint256) {
        return price;
    }

    function generatetoken(uint256 _value) public returns (bool success) {

        if (msg.sender == creatorofthecontract && Maximumcaptotalsupply >= (totalSupply() + _value)){
            balances[msg.sender] += _value*(10**18);
            totalSupply_ += _value*(10**18);
            
            Transfer (0 , msg.sender, _value);
            
            return true;
        }
        else {
            return false;
        }
    }
    
    function increaseICOcap(uint256 _value) public returns (bool success) {

        if (msg.sender == creatorofthecontract && Maximumcaptotalsupply >= (totalICOable() + _value)){
            totalICOable_ += _value*(10**18);
            return true;
        }
        else {
            return false;
        }
    }
    
    function decreaseICOcap(uint256 _value) public returns (bool success) {

        if (msg.sender == creatorofthecontract && Maximumcaptotalsupply >= (totalICOable() + _value)){
            totalICOable_ -= _value*(10**18);
            return true;
        }
        else {
            return false;
        }
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
    
    /*function () public payable { // very basic crowdsale function

        
        uint256 toMint = msg.value/price;
        totalSupply_ += toMint;
        balances[msg.sender] += toMint;
        
        Transfer (0 , msg.sender, toMint);
        
    }*/
    
    function() public payable { 
        
        uint256 toMint = msg.value*(10**18)/price;
        
        if(totalICOable() >= totalSupply() + toMint){
            
            totalSupply_ += toMint;
            balances[msg.sender] += toMint;
            
            Transfer (0 , msg.sender, toMint);
        }
        
        /*else if (totalICOable() > totalSupply()){ // need to find ways to return exceed ether
            if(totalSupply() + toMint > totalICOable()){
                  
                balances[msg.sender] += (totalICOable()-totalSupply());
                totalSupply_ += (totalICOable()-totalSupply()); //((totalSupply() + toMint)-totalICOable())
            
                Transfer (0 , msg.sender, toMint);
                throw;
            }
        }*/
        else revert();
        
        
    }
    
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    
    /*
    function generateICOcrowdsale (uint256 _value) public payable { // very basic crowdsale function
    
        if ((msg.sender == creatorofthecontract) && Maximumcaptotalsupply >= (totalSupply() + _value)) {
        
            uint256 toMint = msg.value/price;
            totalSupply_ += toMint;
            balances[msg.sender] += toMint;
            
            Transfer (0 , msg.sender, toMint);
        }
        
    }*/


}