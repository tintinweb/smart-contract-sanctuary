pragma solidity ^0.4.18;

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */

    function tokenFallback(address _from, uint _value, bytes _data);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` 
     * of the contract to the sender account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the current owner
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
}




contract MEER is Ownable, ERC223Interface {
    
    string public constant symbol = "MEER";
    string public constant name = "MEER";
    uint8 public constant decimals = 18;
    uint256 private _unmintedTokens = 200000000000*uint(10)**decimals;

    mapping(address => uint) balances; // List of user balances.
    mapping (address => mapping (address => uint256)) internal allowed;
    
	
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
    function transfer(address _to, uint _value, bytes _data) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        if(codeLength>0) {
           ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
        /**
     * @dev Transfer token back to owner
     * @param _to The address to transfer  to
     * @param _value The amount to be transferred
     */  
    function transferBack(address _to, uint256 _value) {
        uint codeLength;
        bytes memory empty;
        
       // require(_to != address(0));
        //require(balances[_to] >= _value);
       // assert(balances[msg.sender] + _value >= balances[msg.sender]);
        
        balances[msg.sender] += _value;
        balances[_to] -= _value;
        if(codeLength>0) {
           ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(_to, msg.sender, _value, empty);
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
    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }

    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    
    

    
    
        /**
     * @dev Mint REM tokens. No more than 200,000,000,000 REM can be minted
     * @param _target The address to which new tokens will be minted
     * @param _mintedAmount The amout of tokens to be minted
     */    
    function mintTokens(address _target, uint256 _mintedAmount) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        balances[_target] += _mintedAmount;
        _unmintedTokens -= _mintedAmount;
        totalSupply += _mintedAmount;
        return true;
    }
    
    /**
     * @dev Mint REM tokens and aproves the passed address to spend the minted amount of tokens
     * No more than 200,000,000,000 REM can be minted
     * @param _target The address to which new tokens will be minted
     * @param _mintedAmount The amout of tokens to be minted
     * @param _spender The address which will spend minted funds
     */ 
    function mintTokensWithApproval(address _target, uint256 _mintedAmount, address _spender) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        balances[_target] += _mintedAmount;
        _unmintedTokens -= _mintedAmount;
        totalSupply += _mintedAmount;
        allowed[_target][_spender] += _mintedAmount;
        return true;
    }
    
    /**
     * @dev Decrease amount of REM tokens that can be minted
     * @param _burnedAmount The amout of unminted tokens to be burned
     */ 
    function burnUnmintedTokens(uint256 _burnedAmount) public onlyOwner returns (bool success){
        require(_burnedAmount <= _unmintedTokens);
        _unmintedTokens -= _burnedAmount;
        return true;
    }

   
}