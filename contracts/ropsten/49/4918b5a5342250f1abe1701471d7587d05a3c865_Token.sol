pragma solidity ^0.4.23;

// File: contracts\Owned.sol

// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned{

    address public owner;
    address public newOwner;

    mapping(address => bool) public isAdmin;

    event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransfered(address indexed _from, address indexed _to);
    event AdminChange(address indexed _admin, bool _status);
    event OwnershipTransferCancelled();

    modifier onlyOwner{
        require(isOwner(msg.sender) == true);
        _;
    }

    modifier onlyAdmin{
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyOwnerOrAdmin{
        require(isOwner(msg.sender) == true || isAdmin[msg.sender] == true);
        _;
    }

    constructor() public {
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner returns (bool){
        require(_newOwner != address(0));
        require(_newOwner != address(this));
        require(_newOwner != owner);
        owner = _newOwner;
        emit OwnershipTransferProposed(owner, _newOwner);
        
        return true;
    }

    function cancelOwnershipTransfer() public onlyOwner returns (bool){
        if(newOwner == address(0)){
            return true;
        }

        newOwner = address(0);
        emit OwnershipTransferCancelled();

        return true;
    }

    function isOwner(address _address) public view returns (bool){
        return (_address == owner);
    }

    function isOwnerOrAdmin (address _address) public view returns (bool){
        return (isOwner(_address) || isAdmin[_address]);
    }
    
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnershipTransfered(owner, newOwner);
        owner = newOwner;
    }

    function addAdmin(address _a) public onlyOwner{
        require(isAdmin[_a] == false);
        isAdmin[_a] = true;
        emit AdminChange(_a, true);
    }

    function removeAdmin(address _a) public onlyOwner{
        require(isAdmin[_a] == true);
        isAdmin[_a] = false;
        emit AdminChange(_a, false);
    }
}

// File: contracts\Finalizable.sol

contract Finalizable is Owned{ 
	bool public finalized;

	event Finalized();

	constructor () public Owned(){
		finalized = false;
	}

	function finalize() public onlyOwner returns (bool){
		require(!finalized);

		finalized = true;
		emit Finalized();

		return true;
	}
}

// File: contracts\Math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts\Token.sol

contract Token is Owned, Finalizable {
    using SafeMath for uint256;

    string  public constant name = "We Inc Token";
    string  public constant symbol = "WINC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public tokensOutInMarket;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Burn(address indexed _burner, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor () public Finalizable(){
        totalSupply = 12000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        tokensOutInMarket = 0;

        //Constructor fire a Transfer event if tokens are assigned to an account.
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function decimals() public view returns (uint8){
        return decimals;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply;
    }

    //@dev Gets the balance of the specified address
    //@param _owner The address to query the balance of.
    //@return An uint256 representing the amount owned by the passed address
    function balanceOf(address _owner) public view returns(uint256){
        return balanceOf[_owner];
    }

    function burn(uint256 _value) public{
        _burn(msg.sender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowance[_owner][_spender];
    }

    function tokensOutInMarket() public view returns (uint256){
        return tokensOutInMarket;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        require(balanceOf[_to] + _value > _value);

        validateTransfer(msg.sender, _to);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);

        return true;
    }

    function validateTransfer(address _from, address _to) private view{
        require(_to != address(0));

        //Once the token is finalized, everybody can transfer tokens
        if(finalized){
            return;
        }

        if(isOwner(_to)){
            return;
        }

        //Before the token is finalized, only owner and admin are allowed to initiate transfer
        //this allows moving token while the sale is still ongoing
        require(isOwnerOrAdmin(_from));
    }

    function _burn(address _who, uint256 _value) internal{
        require(_value <= balanceOf[_who]);

        balanceOf[_who] = balanceOf[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    //@dev Burns a specific amount of tokens from the target address and decrements allowance
    //@param _from address The address which you want to send tokens from
    //@param _value uint256 The amount of tokens to be burned
    function burnFrom(address _from, uint256 _value) public{
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
}