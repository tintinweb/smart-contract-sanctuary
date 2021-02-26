/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity >=0.5.12;


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(this));
        owner = newOwner;
    }
}


contract tokenRecipient {
    event receivedEther(address sender, uint amount);
    event receivedTokens(address _from, uint256 _value, address _token, bytes _extraData);

    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public {
        Token t = Token(_token);
        require(t.transferFrom(_from, address(this), _value));
        emit receivedTokens(_from, _value, _token, _extraData);
    }

    function () payable external {
        emit receivedEther(msg.sender, msg.value);
    }
}


contract Token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function transfer(address _to, uint256 _value) public returns (bool success);
}


/**
 * The PubeCoin Foundation contract
 */
contract PubeCoinFoundation is owned, tokenRecipient {
    Token public tokenAddress;
    bool public initialized = false;

    event Initialized();
    event WithdrawTokens(address destination, uint256 amount);
    event WithdrawAnyTokens(address tokenAddress, address destination, uint256 amount);
    event WithdrawEther(address destination, uint256 amount);


    /**
     * Constructor
     *
     * First time rules setup 
     */
    constructor() payable public {
    }


    /**
     * Initialize contract
     *
     * @param _tokenAddress token address
     */
    function init(Token _tokenAddress) onlyOwner public {
        require(!initialized);
        initialized = true;
        tokenAddress = _tokenAddress;
        emit Initialized();
    }


    /**
     * withdrawTokens
     *
     * Withdraw tokens from the contract
     *
     * @param amount is an amount of tokens
     */
    function withdrawTokens(
        uint256 amount
    )
        onlyOwner public
    {
        require(initialized);
        tokenAddress.transfer(msg.sender, amount);
        emit WithdrawTokens(msg.sender, amount);
    }

    /**
     * withdrawAnyTokens
     *
     * Withdraw any tokens from the contract
     *
     * @param _tokenAddress is a token contract address
     * @param amount is an amount of tokens
     */
    function withdrawAnyTokens(
        address _tokenAddress,
        uint256 amount
    )
        onlyOwner public
    {
        Token(_tokenAddress).transfer(msg.sender, amount);
        emit WithdrawAnyTokens(_tokenAddress, msg.sender, amount);
    }
    
    /**
     * withdrawEther
     *
     * Withdraw ether from the contract
     *
     * @param amount is a wei amount 
     */
    function withdrawEther(
        uint256 amount
    )
        onlyOwner public
    {
        msg.sender.transfer(amount);
        emit WithdrawEther(msg.sender, amount);
    }
    
    /**
     * Execute transaction
     *
     * @param transactionBytecode transaction bytecode
     */
    function execute(bytes memory transactionBytecode) onlyOwner public {
        require(initialized);
        (bool success, ) = msg.sender.call.value(0)(transactionBytecode);
            require(success);
    }
}