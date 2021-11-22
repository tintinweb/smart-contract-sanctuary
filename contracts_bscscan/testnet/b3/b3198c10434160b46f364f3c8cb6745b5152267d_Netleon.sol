/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

 // safemath library
    library SafeMath { 
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
 
 //Init contract
 contract Init{
    constructor() internal 
    {}
    
    function msgSender() internal view returns(address payable)
    {
        return msg.sender;
    }
    
}


//Ownable contract 
 contract Ownable is Init{
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() internal {
    _owner = msgSender();
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner(), "You are not the owner!");
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// main contract
contract Netleon is Ownable{
    
   
     string public constant name = "PADS Token";
     string public constant symbol = "PADS";
     uint8 private constant decimal = 18;
     address private contract_owner;
     uint256 private price = 10 ** 16;
     uint256 private _totalSupply;
     using SafeMath for uint256;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed source, address indexed to, uint tokens);
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    // Constructor to add balances to each account
    constructor(uint256 total) public{
        contract_owner = msg.sender;
        _totalSupply = total;
        _totalSupply = _totalSupply * (10 ** 18);
        balances[msg.sender]=_totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    // function to transfer/send tokens to a person
    function transfer(address owner, address receiver, uint256 numTokens) public returns(bool)
    {
        require(owner!= address(0), "Invalid owner address");
        require(receiver!= address(0), "Invalid receiver address");
        require(numTokens <= balances[owner],"Insufficient Balance");
        balances[owner] = balances[owner].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(owner, receiver, numTokens);
        return true;
    }
    
    //function to set price of tokens
    function buy(uint256 amount) public returns(bool)
    {
        uint256 token = amount*(10 **18);
        token = token/price;
        require(token <= balances[contract_owner], "Insufficient Balance");
        transfer(contract_owner, msg.sender, token);
        return true;
    }
    
    // function to allow a delegate/another person to spend tokens
    function approve(address delegate, uint256 numTokens) public returns(bool){
        require(delegate!= address(0), "Invalid delegate address");
        require(numTokens <= balances[msgSender()],"Insufficient Balance");
        allowed[msgSender()][delegate] = numTokens;
        emit Approval(msgSender(), delegate, numTokens);
        return true;
    }

    // function to sell tokens to a third party/buyer through the delegate     
    function transferFrom(address owner, address buyer, uint256 numTokens) public returns(bool)
    {
        require(owner!=address(0), "Invalid owner address");
        require(buyer!= address(0), "Invalid buyer address");
        require(numTokens <= balances[owner], "Tokens exceeded Balance of Owner");
        require(numTokens <= allowed[owner][msg.sender], "Token exceeded allowed tokens");
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    //function to view balances
    function viewBalance(address owner) public view returns(uint)
    {
        return balances[owner];
    }
    
    // function to view total totalSupply
    function totalSupply() public view returns(uint)
    {
        return _totalSupply;
    }
    
    // function to view allowed tokens spendable by the delegate
    function allow(address owner, address delegate) public view returns(uint)
    {
        return allowed[owner][delegate];
    }
    
    function decimals() public view returns(uint8)
    {
        return decimal;
    }

    
    //function to increase allowance
    function increaseAllowance(address delegate, uint256 extra) public returns(bool)
    {
        approve(delegate,allowed[msgSender()][delegate].add(extra));
        return true;
    }
    
    //function to decrease allowance
    function decreaseAllowance(address delegate, uint256 reduce) public returns(bool)
    {
        approve(delegate,allowed[msgSender()][delegate].sub(reduce));
        return true;
    }
    
    //function to mint tokens
    function mint(address account ,uint256 amount) public onlyOwner returns(bool)
    {
        require(account != address(0), "Invalid Account");
        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    
    }
    
    //function to burn tokens
    function burn(address account, uint256 amount) public onlyOwner returns(bool)
    {
        require(account != address(0), "Invalid Account");
        _totalSupply = _totalSupply.sub(amount);
        balances[account] = balances[account].sub(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }
    
    
    
    
    
    
    
}