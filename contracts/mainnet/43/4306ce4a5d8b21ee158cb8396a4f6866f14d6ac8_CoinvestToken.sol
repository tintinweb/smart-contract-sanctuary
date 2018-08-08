pragma solidity ^0.4.9;

 /*
 * Contract that is working with ERC223 tokens
 */
 
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
} 

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-tokens
 */
 
 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) throw;
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) throw;
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) throw;
        return x * y;
    }
}
 
contract CoinvestToken is SafeMath {
    
    address public maintainer;
    address public icoContract; // icoContract is needed to allow it to transfer tokens during crowdsale.
    uint256 public lockupEndTime; // lockupEndTime is needed to determine when users may start transferring.
    
    bool public ERC223Transfer_enabled = false;
    bool public Transfer_data_enabled = false;
    bool public Transfer_nodata_enabled = true;

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event ERC223Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _from, address indexed _spender, uint indexed _amount);

    mapping(address => uint) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
  

    string public constant symbol = "COIN";
    string public constant name = "Coinvest COIN Token";
    
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 107142857 * (10 ** 18);
    
    /**
     * @dev Set owner and beginning balance.
     * @param _lockupEndTime The time at which the token may be traded.
    **/
    function CoinvestToken(uint256 _lockupEndTime)
      public
    {
        balances[msg.sender] = totalSupply;
        lockupEndTime = _lockupEndTime;
        maintainer = msg.sender;
    }
  
  
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) transferable returns (bool success) {
      
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) throw;
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
            if(Transfer_data_enabled)
            {
                Transfer(msg.sender, _to, _value, _data);
            }
            if(Transfer_nodata_enabled)
            {
                Transfer(msg.sender, _to, _value);
            }
            if(ERC223Transfer_enabled)
            {
                ERC223Transfer(msg.sender, _to, _value, _data);
            }
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function ERC20transfer(address _to, uint _value, bytes _data) transferable returns (bool success) {
        bytes memory empty;
        return transferToAddress(_to, _value, empty);
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) transferable returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) transferable returns (bool success) {
      
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) public returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        if(Transfer_data_enabled)
        {
            Transfer(msg.sender, _to, _value, _data);
        }
        if(Transfer_nodata_enabled)
        {
            Transfer(msg.sender, _to, _value);
        }
        if(ERC223Transfer_enabled)
        {
            ERC223Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }
  
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        if(Transfer_data_enabled)
        {
            Transfer(msg.sender, _to, _value, _data);
        }
        if(Transfer_nodata_enabled)
        {
            Transfer(msg.sender, _to, _value);
        }
        if(ERC223Transfer_enabled)
        {
            ERC223Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }


    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    /**
     * @dev An allowed address can transfer tokens from another&#39;s address.
     * @param _from The owner of the tokens to be transferred.
     * @param _to The address to which the tokens will be transferred.
     * @param _amount The amount of tokens to be transferred.
    **/
    function transferFrom(address _from, address _to, uint _amount)
      external
      transferable
    returns (bool success)
    {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        bytes memory empty;
        
        Transfer(_from, _to, _amount, empty);
        return true;
    }

    /**
     * @dev Approves a wallet to transfer tokens on one&#39;s behalf.
     * @param _spender The wallet approved to spend tokens.
     * @param _amount The amount of tokens approved to spend.
    **/
    function approve(address _spender, uint256 _amount) 
      external
      transferable // Protect from unlikely maintainer-receiver trickery
    {
        require(balances[msg.sender] >= _amount);
        
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
    }
    
    /**
     * @dev Allow the owner to take ERC20 tokens off of this contract if they are accidentally sent.
    **/
    function token_escape(address _tokenContract)
      external
      only_maintainer
    {
        CoinvestToken lostToken = CoinvestToken(_tokenContract);
        
        uint256 stuckTokens = lostToken.balanceOf(address(this));
        lostToken.transfer(maintainer, stuckTokens);
    }

    /**
     * @dev Allow maintainer to set the ico contract for transferable permissions.
    **/
    function setIcoContract(address _icoContract)
      external
      only_maintainer
    {
        require(icoContract == 0);
        icoContract = _icoContract;
    }

    /**
     * @dev Allowed amount for a user to spend of another&#39;s tokens.
     * @param _owner The owner of the tokens approved to spend.
     * @param _spender The address of the user allowed to spend the tokens.
    **/
    function allowance(address _owner, address _spender) 
      external
      constant 
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    function adjust_ERC223Transfer(bool _value) only_maintainer
    {
        ERC223Transfer_enabled = _value;
    }
    
    function adjust_Transfer_nodata(bool _value) only_maintainer
    {
        Transfer_nodata_enabled = _value;
    }
    
    function adjust_Transfer_data(bool _value) only_maintainer
    {
        Transfer_data_enabled = _value;
    }
    
    modifier only_maintainer
    {
        assert(msg.sender == maintainer);
        _;
    }
    
    /**
     * @dev Allows the current maintainer to transfer maintenance of the contract to a new maintainer.
     * @param newMaintainer The address to transfer ownership to.
     */
    function transferMaintainer(address newMaintainer) only_maintainer public {
        require(newMaintainer != address(0));
        maintainer = newMaintainer;
    }
    
    modifier transferable
    {
        if (block.timestamp < lockupEndTime) {
            require(msg.sender == maintainer || msg.sender == icoContract);
        }
        _;
    }
    
}