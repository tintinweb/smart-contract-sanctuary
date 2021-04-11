pragma solidity >=0.4.22 <=0.6.2;

// import "OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol";
// import "OpenZeppelin/[email protected]/contracts/math/SafeMath.sol";
// import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract HotelToken is Ownable {

    string public constant name = "Hotel Token";
    string public constant symbol = "HT";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor() public {
     totalSupply_ = 9999999999999999999999999999;
     balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
	     return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function mint(address account, uint256 value) public returns (bool) {
      require(account != address(0));

      totalSupply_ = totalSupply_.add(value);
      balances[account] = balances[account].add(value);
      emit Transfer(address(0), account, value);
      return true;
    }

    function burn(address account, uint256 value) public returns (bool)  {
      require(account != address(0));

      totalSupply_ = totalSupply_.sub(value);
      balances[account] = balances[account].sub(value);
      emit Transfer(account, address(0), value);
      return true;
    }

    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }
}