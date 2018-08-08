pragma solidity ^0.4.21;

contract SafeMath {
     function safeMul(uint a, uint b) internal pure returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal pure returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal pure returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}


contract Token is SafeMath {

     
     function transfer(address _to, uint256 _value) public;
     function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
     function approve(address _spender, uint256 _amount) public returns (bool success);

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Crowdsale is Token {

    // Public and other variables of the token
    address public owner;
    string public name = "crowdsalenetworkplatform";
    string public symbol = "CSNP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 50000000 * 10 ** uint256(decimals);
    
    address internal foundersAddress;
    address internal bonusAddress;
    uint internal dayStart = now;


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);


    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function Crowdsale(address enterFoundersAddress, address enterBonusAddress) public {
        foundersAddress = enterFoundersAddress;
        bonusAddress = enterBonusAddress;
        balanceOf[foundersAddress] = 12500000 * 10 ** uint256(decimals);
        balanceOf[bonusAddress] = 18750000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply - (12500000 * 10 ** uint256(decimals)) - (18750000 * 10 ** uint256(decimals));                
        owner = msg.sender;

    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = safeSub(balanceOf[_from],_value);
        // Add the same to the recipient
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        emit Transfer(_from, _to, _value);

    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public  {
        if(now < (dayStart + 365 days)){
            require(msg.sender != foundersAddress && tx.origin != foundersAddress);
        }
        
        if(now < (dayStart + 180 days)){
            require(msg.sender != bonusAddress && tx.origin != bonusAddress);
        }
        

        _transfer(msg.sender, _to, _value);
    }




    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        
        if(now < (dayStart + 365 days)){
            require(_from != foundersAddress);
        }
        
        if(now < (dayStart + 180 days)){
            require(_from != bonusAddress);
        }

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    
    /**
    *   Set allowance for other address
    *
    *   also, to minimize the risk of the approve/transferFrom attack vector
    *   approve has to be called twice in 2 separate transactions - once to
    *   change the allowance to 0 and secondly to change it to the new allowance
    *   value
    *
    *   @param _spender      approved address
    *   @param _amount       allowance amount
    *
    *   @return true if the approval was successful
    */
    function approve(address _spender, uint256 _amount) public returns(bool success) {
        require((_amount == 0) || (allowance[msg.sender][_spender] == 0));
        
        if(now < (dayStart + 365 days)){
            require(msg.sender != foundersAddress && tx.origin != foundersAddress);
        }
        
        if(now < (dayStart + 180 days)){
            require(msg.sender != bonusAddress && tx.origin != bonusAddress);
        }
        
        
        allowance[msg.sender][_spender] = _amount;
        return true;
    }
    
        
     

}