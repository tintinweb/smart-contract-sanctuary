/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-27
*/

pragma solidity ^0.4.16;

/**
 * The previous smart contract was submitted on 2017-11-07
*/

contract Ownable {
    
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));      
        owner = newOwner;
    }

}

contract XENIT is Ownable {
    
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    string public constant name = "XENIT TOKEN";
    string public constant symbol = "XENIT";
    uint32 public constant decimals = 18;

    uint constant restrictedPercent = 30;
    address constant restricted = 0xe5cF86fC6420A4404Ee96535ae2367897C94D831;
    uint constant start = 1601200042;
    uint constant period = 3;
    uint256 public constant hardcap = 100000000 * 1 ether;
    
    bool public transferAllowed = false;
    bool public mintingFinished = false;
    
    modifier whenTransferAllowed() {
        if(msg.sender != owner){
            require(transferAllowed);
        }
        _;
    }

    modifier saleIsOn() {
        require(now > start && now < start + period * 1 days);
        _;
    }
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
  
    function transfer(address _to, uint256 _value) whenTransferAllowed public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        //assert(balances[_to] >= _value); no need to check, since mint has limited hardcap
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) whenTransferAllowed public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        //assert(balances[_to] >= _value); no need to check, since mint has limited hardcap
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        //NOTE: To prevent attack vectors like the one discussed here:
        //https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729,
        //clients SHOULD make sure to create user interfaces in such a way
        //that they set the allowance first to 0 before setting it to another
        //value for the same spender.
    
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
   
    function allowTransfer() onlyOwner public {
        transferAllowed = true;
    }
    
    function mint(address _to, uint256 _value) onlyOwner saleIsOn canMint public returns (bool) {
        require(_to != address(0));
        
        uint restrictedTokens = _value * restrictedPercent / (100 - restrictedPercent);
        uint _amount = _value + restrictedTokens;
        assert(_amount >= _value);
        
        if(_amount + totalSupply <= hardcap){
        
            totalSupply = totalSupply + _amount;
            
            assert(totalSupply >= _amount);
            
            balances[msg.sender] = balances[msg.sender] + _amount;
            assert(balances[msg.sender] >= _amount);
            Mint(msg.sender, _amount);
        
            transfer(_to, _value);
            transfer(restricted, restrictedTokens);
        }
        return true;
    }

    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
    
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        balances[msg.sender] = balances[msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(_from, _value);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    event Burn(address indexed burner, uint256 value);

}