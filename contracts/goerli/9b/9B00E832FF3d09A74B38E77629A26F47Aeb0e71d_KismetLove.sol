/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract ERC20 {
constructor(string memory _name, string memory _symbol,
                uint8 _decimals) {
        myName = _name;
        mySymbol = _symbol;
        myDecimals = _decimals;
        //balances[msg.sender] = myTotalSupply;   // deployer
        admin = msg.sender;
    }
    address admin;  // deployer
    string myName;
    function name() public view returns (string memory){
        return myName;
    }
    string mySymbol;
    function symbol() public view returns (string memory) {
        return mySymbol;
    }
    uint8 myDecimals;
    function decimals() public view returns (uint8) {
        return myDecimals;
    }
    uint256 myTotalSupply;
    function totalSupply() public view returns (uint256) {
        return myTotalSupply;
    }
    mapping(address => uint256) balances;
    function balanceOf(address _user) public view returns (uint256 balance){
        return balances[_user];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Insufficient balance");
   //  require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;

    }
    // run by spender;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Insufficient owner balance");
        require( allowed[_from][msg.sender]>= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from , _to, _value);
        return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address => mapping (address => uint256)) allowed;
    // Run by Owner.
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    // increaseAllowance
    // decreaseAllowance

    // mint - To incrase total supply.
    function mint(uint256 _qty) public returns (bool){
        require (admin==msg.sender,"only admin is authorised");
        myTotalSupply += _qty;
        // To my wallet.
        balances[msg.sender]+= _qty;

        // To deployer wallet
       // balances[admin] += _qty;
        // to _to wallet.
       // balances[_to] += _qty;
        return true;
    }
    // burn - To decrease total supply.

    function burn(uint256 _qty) public returns (bool) {
                require (admin==msg.sender,"only admin is authorised");
         require(balanceOf(msg.sender) >= _qty, "Insufficient balance");
        myTotalSupply -= _qty; 
        balances[msg.sender]-= _qty; 
        return true; 
    
    }

}
contract KismetLove is ERC20 {

    constructor() ERC20("Kismet Love","KLUXY",8) {
         mint(1111111111*10**decimals());
         unlockTime = block.timestamp + 300;
    }   

    uint256 public unlockTime;
    modifier checkLocked {
        require( block.timestamp <= unlockTime, "No more locked");
        _;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Insufficient balance");
        if(block.timestamp<=unlockTime && msg.sender==admin) {
            require((balanceOf(admin) - _value) >= 1000000000, "balance below 1 billion in lock period");
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        }
        

    } 
    function changeOwner (address _new) public{
       require (admin==msg.sender,"only admin is authorised");
        admin = _new; 
    }
    
    
}