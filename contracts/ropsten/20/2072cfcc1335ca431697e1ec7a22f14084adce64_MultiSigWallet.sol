pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MultiSigWallet {
    string constant public VERSION = "0.0.2";
    uint constant public MAX_OWNER_COUNT = 50;
    uint public threshold;
    string private privateKey;
    address[] public owners;
    mapping(address => bool) public isOwner;

    event Deposit(address indexed sender, uint value);
    event Execution(address indexed sender, address destination, uint value, address tokenContractAddr, uint requestId);
    event ExecutionFailure(address indexed sender, address destination, uint value, address tokenContractAddr, uint requestId);

    modifier validRequirement(uint ownerCount, uint _threshold) {
        if (ownerCount > MAX_OWNER_COUNT
        || _threshold > ownerCount
        || _threshold == 0
        || ownerCount == 0)
            revert();
        _;
    }


    // @dev Contract constructor sets initial owners and required number of confirmations.
    // @param _owners List of initial owners.
    // @param _threshold Number of required confirmations.
    constructor(address[] _owners, uint _threshold, string _privateKey) public validRequirement(_owners.length, _threshold)
    {
        for (uint i = 0; i < _owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        threshold = _threshold;
        privateKey = _privateKey;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }


    /// @dev Fallback function allows to deposit ether.
    function() public payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    function executeTransaction(uint8[] sigV, bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data, address tokenContractAddr, uint requestId) public {
        require(isOwner[msg.sender]);
        require(sigR.length >= threshold);
        require(sigR.length == sigS.length && sigR.length == sigV.length);
        // Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
        bytes32 txHash = keccak256(byte(0x19), byte(0), this, destination, value, data, privateKey);

        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
            // cannot have address(0) as an owner
            require(recovered > address(0) && isOwner[recovered]);
        }

        // If we make it here all signatures are accounted for.
        bool success = false;
        if (tokenContractAddr == address(0)) {

            //call(g, a, v, in, insize, out, outsize)
            //call contract at address a with input mem[in..(in+insize)) providing g gas and v wei and output area mem[out..(out+outsize)) returning 0 on error (eg. out of gas) and 1 on success
            assembly {success := call(gas, destination, value, add(data, 0x20), mload(data), 0, 0)}
        } else {
            ERC20Interface instance = ERC20Interface(tokenContractAddr);
            success = instance.transfer(destination, value);
        }
        if (!success) {
            emit ExecutionFailure(msg.sender, destination, value, tokenContractAddr, requestId);
        } else {
            emit Execution(msg.sender, destination, value, tokenContractAddr, requestId);
        }
    }
}