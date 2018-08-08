pragma solidity ^0.4.10;
 

contract Burner {
    function burnILF(address , uint ) {}
}

contract StandardToken {

    /* *  Data structures */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    /* *  Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* *  Read and write storage functions */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /* * Read storage functions */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

contract ILF is StandardToken {

    mapping(address => bool) public previousMinters;
    mapping(address => bool) public previousBurners;
    bool public minterChangeable = true;
    bool public burnerChangeable = true;
    bool public manualEmissionEnabled = true;
    string public constant symbol = "ILF";
    string public constant name = "ICO Lab Fund Token";
    uint8 public constant decimals = 8;
    address public burnerAddress;
    address public minterAddress;
    address public ILFManager;
    address public ILFManagerCandidate;   
    bytes32 public ILFManagerCandidateKeyHash; 
    Burner burner;
                                           
    event Emission(address indexed emitTo, uint amount);
    event Burn(address indexed burnFrom, uint amount);

    // @dev Create token.
    // @param _ILFManager ILF manager address.
    function ILF(address _ILFManager){
        ILFManager = _ILFManager;
    }

    /// @dev Emit new tokens for an address. Only usable by minter or manager.
    /// @param emitTo Emission destination address.
    /// @param amount Amount to emit.
    function emitToken(address emitTo, uint amount) {
        assert(amount>0);
        assert(msg.sender == minterAddress || (msg.sender == ILFManager && manualEmissionEnabled));
        balances[emitTo] += amount;
        totalSupply += amount;
        Emission(emitTo, amount);
    }

    /// @dev Burn tokens from an address. Only usable by burner.
    /// @param burnFrom Address to burn tokens from.
    /// @param amount Amount to burn.
    function burnToken(address burnFrom, uint amount) external onlyBurner {
        assert(amount <= balances[burnFrom] && amount <= totalSupply);
        balances[burnFrom] -= amount;
        totalSupply -= amount;
        Burn(burnFrom, amount);
    }

    //Overloading the original ERC20 transfer function to handle token burn
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        assert(!previousBurners[_to] && !previousMinters[_to] && _to != minterAddress);
        
        if (balances[msg.sender] >= _value && _value > 0 && _to != address(0) && _to != address(this)) {//The last two checks are done for preventing sending tokens to zero address or token address (this contract).
            if (_to == burnerAddress) {
                burner.burnILF(msg.sender, _value);
            }
            else {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
            }
            return true;
        }
        else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        assert(!previousBurners[_to] && !previousMinters[_to] && _to != minterAddress);

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && _to != address(0) && _to != address(this)) {
            if (_to == burnerAddress) {
                burner.burnILF(_from, _value);
            }
            else {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
            }
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Change minter manager. Only usable by manager.
    /// @param candidate New manager address.
    /// @param keyHash Hash of secret key possessed by candidate.
    function changeILFManager(address candidate, bytes32 keyHash) external onlyILFManager {
        ILFManagerCandidate = candidate;
        ILFManagerCandidateKeyHash = keyHash;
    }

    /// @dev Accept taking manager role. Only usable by manager candidate.
    /// @param key Hash of the secret key from the current manager.
    function acceptManagement(string key) external onlyManagerCandidate(key) {
        ILFManager = ILFManagerCandidate;
    }

    /// @dev Change minter address. Only usable by manager.
    /// @param _minterAddress New minter address.
    function changeMinter(address _minterAddress) external onlyILFManager {
        assert(minterChangeable);
        previousMinters[minterAddress]=true;
        minterAddress = _minterAddress;
    }

    /// @dev Seals minter. After this procedure minter is no longer changeable.
    /// @param _hash SHA3 hash of current minter address.
    function sealMinter(bytes32 _hash) onlyILFManager {
        assert(sha3(minterAddress)==_hash);
        minterChangeable = false; 
    }
    
    /// @dev Change burner address. Only usable by manager.
    /// @param _burnerAddress New burner address.
    function changeBurner(address _burnerAddress) external onlyILFManager {
        assert(burnerChangeable);
        burner = Burner(_burnerAddress);
        previousBurners[burnerAddress]=true;
        burnerAddress = _burnerAddress;
    }

    /// @dev Seals burner. After this procedure burner is no longer changeable.
    /// @param _hash SHA3 hash of current burner address.
    function sealBurner(bytes32 _hash) onlyILFManager {
        assert(sha3(burnerAddress)==_hash);
        burnerChangeable = false; 
    }

    /// @dev Disable calling emitToken by manager needed for initial token distribution. Only usable by manager.
    /// @param _hash SHA3 Hash of current manager address.
    function disableManualEmission(bytes32 _hash) onlyILFManager {
        assert(sha3(ILFManager)==_hash);
        manualEmissionEnabled = false; 
    }

    modifier onlyILFManager() {
        assert(msg.sender == ILFManager);
        _;
    }

    modifier onlyMinter() {
        assert(msg.sender == minterAddress);
        _;
    }

    modifier onlyBurner() {
        assert(msg.sender == burnerAddress);
        _;
    }

    modifier onlyManagerCandidate(string key) {
        assert(msg.sender == ILFManagerCandidate);
        assert(sha3(key) == ILFManagerCandidateKeyHash);
        _;
    }

}