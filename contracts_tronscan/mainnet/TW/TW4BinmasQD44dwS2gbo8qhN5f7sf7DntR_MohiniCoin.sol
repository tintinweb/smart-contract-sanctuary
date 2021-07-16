//SourceUnit: mico_final_V110.sol

pragma solidity 0.5.12;

// Website:  https://MohiniCoin.com
// Telegram: https://t.me/MohiniCoinOfficial

interface ITRC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address owner, address spender) external view returns(uint256);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, "SafeMath: MATH_ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, "SafeMath: MATH_SUB_UNDERFLOW");
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: MATH_MUL_OVERFLOW");
    }
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol; 
    uint8 public decimals;

    // predefined supply 
    uint256 public totalSupply = 1333333333e6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // blockList feature
    mapping(address => bool) blockListed;


    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {

        require( balanceOf[msg.sender] >= value && value > 0, "Value error!");
        require( !blockListed[to] && !blockListed[msg.sender], "BlockListed account!" );

        balanceOf[from] =  SafeMath.sub(balanceOf[from], value);
        balanceOf[to] = SafeMath.add(balanceOf[to], value);

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns(bool) {
        _approve(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns(bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        if(allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }

        _transfer(from, to, value);

        return true;
    }

}

contract MohiniCoin is TRC20 {
    address public owner;
    uint256 public startTime = 1614736980;          //2021.03.03. 03:03:00
    uint256 public constructTime = 1614736980;      // will be burned into the system for later use

    modifier onlyOwner() {
        require(msg.sender == owner, "MICO: ACCESS_DENIED");
        _;
    }

    constructor() public {
        owner = msg.sender;

        name = "MohiniCoin";
        symbol = "MICO";
        decimals = 6;

        constructTime = now;
        balanceOf[msg.sender] = totalSupply;      
    }

   function burn(uint256 value) external onlyOwner {
        require(balanceOf[msg.sender] >= value, "MICO: INSUFFICIENT_FUNDS");

        _burn(msg.sender, value);
    }

  function sendCoin(address _to, uint _amount) public returns (bool sufficient) {
    if (balanceOf[msg.sender] < _amount) return false;

    balanceOf[msg.sender] = SafeMath.sub( balanceOf[msg.sender] , _amount);
    balanceOf[_to] = SafeMath.add( balanceOf[_to],  _amount);

    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

   function addBlockList(address wallet) onlyOwner public returns (bool) {
        blockListed[wallet] = true;

        return true ;
    }

    function isBlockListed(address wallet) onlyOwner public returns (bool) {

		return blockListed[wallet];
    }

    function removeBlockList(address wallet) onlyOwner public returns (bool) {
        blockListed[wallet] = false;

        return true ;
    }


    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (uint256 restamount) {
        require(balanceOf[_from] >= _value);                                                   // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                                       // Check allowance

        allowance[_from][msg.sender] =  SafeMath.sub( allowance[_from][msg.sender],  _value );  // Subtract from the sender's allowance
		
        balanceOf[ _from ] = SafeMath.sub(balanceOf[ _from ], _value);                          // Subtract from the sender
        totalSupply = SafeMath.sub(totalSupply,_value);                                         // Updates totalSupply
		
        _burn(_from, _value);
        return balanceOf[ _from ];
    }



 
}