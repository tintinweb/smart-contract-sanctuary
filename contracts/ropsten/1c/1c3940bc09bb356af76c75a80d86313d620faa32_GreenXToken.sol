pragma solidity ^0.4.18;

/**
* @notice greenX token contract
* Deployed to : 0x6fca488c744e5a73806c95551a6e7f92a91a8a40
* Symbol      : GREENX
* Name        : greenX Token
* Total supply: 0
* Decimals    : 18
*/

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "unable to safe add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "unable to safe subtract");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "unable to safe multiply");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "undable to safe divide");
        c = a / b;
    }
}

/**
* @notice ERC Token Standard #20 Interface
*/
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);
}

/**
* @notice Contract function to receive approval and execute function in one call
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
* @notice Owned contract
*/
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "sender is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "sender is not new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
* @notice ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract GreenXToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor () public {
        symbol = "GREENX";
        name = "greenX Token";
        decimals = 18;
        _totalSupply = 0;
        balances[0x5ccA4A8aBEd1967F5e53400B1c60d5F1cE2CD270] = _totalSupply;
        emit Transfer(address(0), 0x5ccA4A8aBEd1967F5e53400B1c60d5F1cE2CD270, _totalSupply);
    }

    /**
    * @notice Get the total supply of greenX
    */
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    /**
    * @notice Get the token balance for a specified address
    *
    * @param tokenOwner address to get balance of
    */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    /**
    * @notice Transfer the balance from token owner&#39;s account to to account
    *
    * @param to transfer to this address
    * @param tokens number of tokens to transfer
    */
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    /**
    * @notice Token owner can approve for spender to transferFrom(...) tokens from the token owner&#39;s account
    *
    * @param spender spender address
    * @param tokens number of tokens allowed to transfer
    */
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
    * @notice Transfer tokens from one account to the other
    *
    * @param from transfer from this address
    * @param to transfer to this address
    * @param tokens amount of tokens to transfer
    */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
    * @notice Returns the amount of tokens approved by the owner that can be transferred to the spender&#39;s account
    *
    * @param tokenOwner token owner address
    * @param spender spender address
    */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    /**
    * @notice Token owner can approve for spender to transferFrom(...) tokens from the token owner&#39;s account. The spender contract function receiveApproval(...) is then executed
    *
    * @param spender address of the spender
    * @param tokens number of tokens
    * @param data add extra data
    */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    /**
    * @notice ETH not accepted
    */
    function () public payable {
        revert("ETH not accepted");
    }

    /**
    * @notice Transfer ERC20 tokens that were accidentally sent
    *
    * @param tokenAddress Address to send token to
    * @param tokens Number of tokens to transfer
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    /**
    * @notice Burn tokens belonging to the sender
    *
    * @param _value the amount of tokens to burn
    */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "insufficient sender balance");
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
    * @notice Mint and distribute greenX
    *
    * @param distAddresses The list of addresses to distribute to
    * @param distValues The list of values to be distributed to addresses based on index
    */
    function distributeMinting(address[] distAddresses, uint[] distValues) public onlyOwner returns (bool success) {
        require(msg.sender == owner, "sender is not owner");
        require(distAddresses.length == distValues.length, "address listed and values listed are not equal lengths");
        for (uint i = 0; i < distAddresses.length; i++) {
            mintToken(distAddresses[i], distValues[i]);
        }
        return true;
    }

    /**
    * @notice Internal function for minting and distributing to a single address
    *
    * @param target Address to distribute minted tokens to
    * @param mintAmount Amount of tokens to mint and distribute
    */
    function mintToken(address target, uint mintAmount) internal {
        balances[target] += mintAmount;
        _totalSupply += mintAmount;
        require(balances[target] >= mintAmount && _totalSupply >= mintAmount, "overflow detected");
        emit Transfer(owner, target, mintAmount);
    }
}