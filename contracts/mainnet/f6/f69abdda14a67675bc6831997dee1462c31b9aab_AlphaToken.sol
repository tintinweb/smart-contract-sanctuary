pragma solidity ^0.4.21;

interface ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract AlphaToken is Ownable {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    mapping(address => uint) balances; // List of user balances.
    mapping(address => mapping (address => uint256)) allowed;

    string _name;
    string _symbol;
    uint8 DECIMALS = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 _totalSupply;
    uint256 _saledTotal = 0;
    uint256 _amounToSale = 0;
    uint _buyPrice = 4500;
    uint256 _totalEther = 0;

    function AlphaToken(
        string tokenName,
        string tokenSymbol
    ) public 
    {
        _totalSupply = 4000000000 * 10 ** uint256(DECIMALS);  // 实际供应总量
        _amounToSale = _totalSupply;
        _saledTotal = 0;
        _name = tokenName;                                       // 设置Token名字
        _symbol = tokenSymbol;                                   // 设置Token符号
        owner = msg.sender;
    }

    function name() public constant returns (string) {
        return _name;
    }

    function symbol() public constant returns (string) {
        return _symbol;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function buyPrice() public constant returns (uint256) {
        return _buyPrice;
    }
    
    function decimals() public constant returns (uint8) {
        return DECIMALS;
    }

    function _transfer(address _from, address _to, uint _value, bytes _data) internal {
        uint codeLength;
        require (_to != 0x0);
        require(balances[_from]>=_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(_from, _to, _value);
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) public returns (bool ok) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        _transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) public returns(bool ok) {
        bytes memory empty;
        _transfer(msg.sender, _to, _value, empty);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(balances[msg.sender]>=tokens);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) onlyOwner public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        bytes memory empty;
        _transfer(_from, _to, _value, empty);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }
    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function setPrices(uint256 newBuyPrice) onlyOwner public {
        _buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buyCoin() payable public returns (bool ok) {
        uint amount = ((msg.value * _buyPrice) * 10 ** uint256(DECIMALS))/1000000000000000000;               // calculates the amount
        require ((_amounToSale - _saledTotal)>=amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        _saledTotal = _saledTotal.add(amount);
        _totalEther += msg.value;
        return true;
    }

    function dispatchTo(address target, uint256 amount) onlyOwner public returns (bool ok) {
        require ((_amounToSale - _saledTotal)>=amount);
        balances[target] = balances[target].add(amount);
        _saledTotal = _saledTotal.add(amount);
        return true;
    }

    function withdrawTo(address _target, uint256 _value) onlyOwner public returns (bool ok) {
        require(_totalEther <= _value);
        _totalEther -= _value;
        _target.transfer(_value);
        return true;
    }
    
    function () payable public {
    }

}