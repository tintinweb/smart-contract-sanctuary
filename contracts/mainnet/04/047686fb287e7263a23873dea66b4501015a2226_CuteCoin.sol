pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
contract ERC20Interface {

    // ERC Token Standard #223 Interface
    // https://github.com/ethereum/EIPs/issues/223

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

    // approveAndCall
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

    // ERC Token Standard #20 Interface
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md


    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // bulk operations
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}

pragma solidity ^0.4.24;

/// @author https://BlockChainArchitect.iocontract Bank is CutiePluginBase
contract PluginInterface
{
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

    /// @dev Begins new feature.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    /// @param _seller - Old owner, if not the message sender
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    ) 
    public
    payable;

    /// @dev Begins new feature, approved and signed by COO.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    )
    external
    payable;

    function withdraw() public;
}


contract CuteCoinInterface is ERC20Interface
{
    function mint(address target, uint256 mintedAmount) public;
    function mintBulk(address[] target, uint256[] mintedAmount) external;
    function burn(uint256 amount) external;
}

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken

interface TokenRecipientInterface
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

pragma solidity ^0.4.24;

// https://github.com/ethereum/EIPs/issues/223
interface TokenFallback
{
    function tokenFallback(address _from, uint _value, bytes _data) external;
}


contract CuteCoin is CuteCoinInterface, Ownable
{
    using SafeMath for uint;

    constructor() public
    {
        symbol = "CUTE";
        name = "Cute Coin";
        decimals = 18;
    }

    uint _totalSupply;
    mapping (address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    // ---------------------------- Operator ----------------------------
    mapping (address => bool) operatorAddress;

    function addOperator(address _operator) public onlyOwner
    {
        operatorAddress[_operator] = true;
    }

    function removeOperator(address _operator) public onlyOwner
    {
        delete(operatorAddress[_operator]);
    }

    modifier onlyOperator() {
        require(operatorAddress[msg.sender] || msg.sender == owner);
        _;
    }

    function withdrawEthFromBalance() external onlyOwner
    {
        owner.transfer(address(this).balance);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // ---------------------------- Do not accept money ----------------------------
    function () payable public
    {
        revert();
    }

    // ---------------------------- Minting ----------------------------

    function mint(address target, uint256 mintedAmount) public onlyOperator
    {
        balances[target] = balances[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(0, target, mintedAmount);
    }

    function mintBulk(address[] target, uint256[] mintedAmount) external onlyOperator
    {
        require(target.length == mintedAmount.length);
        for (uint i = 0; i < target.length; i++)
        {
            mint(target[i], mintedAmount[i]);
        }
    }

    function burn(uint256 amount) external
    {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, 0, amount);
    }


    // ---------------------------- ERC20 ----------------------------

    function totalSupply() public constant returns (uint)
    {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance)
    {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        TokenRecipientInterface(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function transferBulk(address[] to, uint[] tokens) public
    {
        require(to.length == tokens.length);
        for (uint i = 0; i < to.length; i++)
        {
            transfer(to[i], tokens[i]);
        }
    }

    function approveBulk(address[] spender, uint[] tokens) public
    {
        require(spender.length == tokens.length);
        for (uint i = 0; i < spender.length; i++)
        {
            approve(spender[i], tokens[i]);
        }
    }

// ---------------------------- ERC223 ----------------------------

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) external returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        TokenFallback receiver = TokenFallback(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }


    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint tokens, bytes _data) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        emit Transfer(msg.sender, _to, tokens, _data);
        return true;
    }

    // @dev Transfers to _withdrawToAddress all tokens controlled by
    // contract _tokenContract.
    function withdrawTokenFromBalance(ERC20Interface _tokenContract, address _withdrawToAddress)
        external
        onlyOperator
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }
}