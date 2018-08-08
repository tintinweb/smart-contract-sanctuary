pragma solidity ^0.4.22;

 /**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
 /**
  * New ERC223 contract interface
  */
contract ERC223 {
  using SafeMath for uint256;
  uint public totalSupply;
  uint public hardCap;
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);

  // ERC20 Transfer event
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC223ReceivingContract {

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _from Transaction initiator, analogue of msg.sender
    /// @param _value Number of tokens to transfer.
    /// @param _data Data containig a function signature and/or parameters
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
    
}





/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract MintableToken is ERC223, Ownable {

    uint256 public hardCap;
    mapping(address => uint256) public balances;

    event Mint(address indexed to, uint256 amount);

    modifier canMint() {
        require(totalSupply < hardCap);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_amount < hardCap);
        require(_amount > 0);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(0x0, _to, _amount);
        return true;
    }
}

contract Token is MintableToken,ERC223ReceivingContract{
    string public name;
    string public symbol;
    uint256 public decimals;
    bool public canChangeHardCap;

    constructor() public {
        name = "XXXxxxXXX";
        symbol = "XXX";
        decimals = 9;
        hardCap = 20000000000000;
        canChangeHardCap = true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);
        if (isContract(_to)){
            ERC223ReceivingContract recieve = ERC223ReceivingContract(_to);
            recieve.tokenFallback(msg.sender, _value,  empty);
           }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);
        if (isContract(_to)){
            ERC223ReceivingContract recieve = ERC223ReceivingContract(_to);
            recieve.tokenFallback(msg.sender, _value,  _data);
           }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
   function transferFrom(address _from, address _to, uint256 _value) onlyOwner public returns (bool success) {
        require(_value > 0);
        if (balances[msg.sender] >= _value){
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        }else{
            require(_value <= balanceOf(_from));
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
        }
        return true;
    }
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    // 発行上限変更
    function changeHardCap(uint256 amount) onlyOwner public {
        require(canChangeHardCap);
        require(amount >totalSupply);
        hardCap = amount;
    }
    
    function tokenFallback(address _from, uint256 _value, bytes _data) public{
        ERC223 erc223 = ERC223(msg.sender);
        erc223.transfer(_from,_value);
    }
    

    
}