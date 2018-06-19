pragma solidity ^0.4.18;

// BlackBox2.0 - Secure Ether & Token Storage
// Rinkeby test contract: 0x21ED89693fF7e91c757DbDD9Aa30448415aa8156

// token interface
contract Token {
    function balanceOf(address _owner) constant public returns (uint balance);
    function allowance(address _user, address _spender) constant public returns (uint amount);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
}

// owned by contract creator
contract Owned {
    address public owner = msg.sender;
    bool public restricted = true;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // restrict external contract calls
    modifier onlyCompliant {
        if (restricted) require(tx.origin == msg.sender);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function changeRestrictions() public onlyOwner {
        restricted = !restricted;
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// helper functions for hashing
contract Encoder {
    enum Algorithm { sha, keccak }

    /// @dev generateProofSet - function for off-chain proof derivation
    /// @param seed Secret used to secure the proof-set
    /// @param caller Address of the caller, or account that verifies the proof-set
    /// @param receiver Address of the encoded recepient
    /// @param tokenAddress Address of the token to transfer from the caller
    /// @param algorithm Hash algorithm to use for generating proof-set
    function generateProofSet(
        string seed,
        address caller,
        address receiver,
        address tokenAddress,
        Algorithm algorithm
    ) pure public returns(bytes32 hash, bytes32 operator, bytes32 check, address check_receiver, address check_token) {
        (hash, operator, check) = _escrow(seed, caller, receiver, tokenAddress, algorithm);
        bytes32 key = hash_seed(seed, algorithm);
        check_receiver = address(hash_data(key, algorithm)^operator);
        if (check_receiver == 0) check_receiver = caller;
        if (tokenAddress != 0) check_token = address(check^key^blind(receiver, algorithm));
    }

    // internal function for generating the proof-set
    function _escrow(
        string seed, 
        address caller,
        address receiver,
        address tokenAddress,
        Algorithm algorithm
    ) pure internal returns(bytes32 index, bytes32 operator, bytes32 check) {
        require(caller != receiver && caller != 0);
        bytes32 x = hash_seed(seed, algorithm);
        if (algorithm == Algorithm.sha) {
            index = sha256(x, caller);
            operator = sha256(x)^bytes32(receiver);
            check = x^sha256(receiver);
        } else {
            index = keccak256(x, caller);
            operator = keccak256(x)^bytes32(receiver);
            check = x^keccak256(receiver);
        }
        if (tokenAddress != 0) {
            check ^= bytes32(tokenAddress);
        }
    }
    
    // internal function for hashing the seed
    function hash_seed(
        string seed, 
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) return sha256(seed);
        else return keccak256(seed);
    }
    
   // internal function for hashing bytes
    function hash_data(
        bytes32 key, 
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) return sha256(key);
        else return keccak256(key);
    }
    
    // internal function for hashing an address
    function blind(
        address addr,
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) return sha256(addr);
        else return keccak256(addr);
    }
    
}


contract BlackBox is Owned, Encoder {

    // struct of proof set
    struct Proof {
        uint256 balance;
        bytes32 operator;
        bytes32 check;
    }
    
    // mappings
    mapping(bytes32 => Proof) public proofs;
    mapping(bytes32 => bool) public used;
    mapping(address => uint) private deposits;

    // events
    event ProofVerified(string _key, address _prover, uint _value);
    event Locked(bytes32 _hash, bytes32 _operator, bytes32 _check);
    event WithdrawTokens(address _token, address _to, uint _value);
    event ClearedDeposit(address _to, uint value);
    event TokenTransfer(address _token, address _from, address _to, uint _value);

    /// @dev lock - store a proof-set
    /// @param _hash Hash Key used to index the proof
    /// @param _operator A derived operator to encode the intended recipient
    /// @param _check A derived operator to check recipient, or a decode the token address
    function lock(
        bytes32 _hash,
        bytes32 _operator,
        bytes32 _check
    ) public payable {
        // protect invalid entries on value transfer
        if (msg.value > 0) {
            require(_hash != 0 && _operator != 0 && _check != 0);
        }
        // check existence
        require(!used[_hash]);
        // lock the ether
        proofs[_hash].balance = msg.value;
        proofs[_hash].operator = _operator;
        proofs[_hash].check = _check;
        // track unique keys
        used[_hash] = true;
        Locked(_hash, _operator, _check);
    }

    /// @dev unlock - verify a proof to transfer the locked funds
    /// @param _seed Secret used to derive the proof set
    /// @param _value Optional token value to transfer if the proof-set maps to a token transfer
    /// @param _algo Hash algorithm type
    function unlock(
        string _seed,
        uint _value,
        Algorithm _algo
    ) public onlyCompliant {
        bytes32 hash = 0;
        bytes32 operator = 0;
        bytes32 check = 0;
        // calculate the proof
        (hash, operator, check) = _escrow(_seed, msg.sender, 0, 0, _algo);
        require(used[hash]);
        // get balance to send to decoded receiver
        uint balance = proofs[hash].balance;
        address receiver = address(proofs[hash].operator^operator);
        address _token = address(proofs[hash].check^hash_seed(_seed, _algo)^blind(receiver, _algo));
        delete proofs[hash];
        if (receiver == 0) receiver = msg.sender;
        // send balance and deposits
        clearDeposits(receiver, balance);
        ProofVerified(_seed, msg.sender, balance);

        // check for token transfer
        if (_token != 0) {
            Token token = Token(_token);
            uint tokenBalance = token.balanceOf(msg.sender);
            uint allowance = token.allowance(msg.sender, this);
            // check the balance to send to the receiver
            if (_value == 0 || _value > tokenBalance) _value = tokenBalance;
            if (allowance > 0 && _value > 0) {
                if (_value > allowance) _value = allowance;
                TokenTransfer(_token, msg.sender, receiver, _value);
                require(token.transferFrom(msg.sender, receiver, _value));
            }
        }
    }
    
    /// @dev withdrawTokens - withdraw tokens from contract
    /// @param _token Address of token that this contract holds
    function withdrawTokens(address _token) public onlyOwner {
        Token token = Token(_token);
        uint256 value = token.balanceOf(this);
        require(token.transfer(msg.sender, value));
        WithdrawTokens(_token, msg.sender, value);
    }
    
    /// @dev clearDeposits - internal function to send ether
    /// @param _for Address of recipient
    /// @param _value Value of proof balance
    function clearDeposits(address _for, uint _value) internal {
        uint deposit = deposits[msg.sender];
        if (deposit > 0) delete deposits[msg.sender];
        if (deposit + _value > 0) {
            if (!_for.send(deposit+_value)) {
                require(msg.sender.send(deposit+_value));
            }
            ClearedDeposit(_for, deposit+_value);
        }
    }
    
    function allowance(address _token, address _from) public view returns(uint _allowance) {
        Token token = Token(_token);
        _allowance = token.allowance(_from, this);
    }
    
    // store deposits for msg.sender
    function() public payable {
        require(msg.value > 0);
        deposits[msg.sender] += msg.value;
    }
    
}