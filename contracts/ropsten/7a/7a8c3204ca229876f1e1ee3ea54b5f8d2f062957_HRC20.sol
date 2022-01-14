/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >= 0.4.22 <0.9.0;

contract SimpleTerms {
    event NewTerms(string url, string value);
    event NewParticipant(address indexed participant);

    //The issuer must create the agreement on ricardian fabric
    address public issuer;

    Terms private terms;

    struct Terms {
        string url;
        bytes32 value;
    }

    // The key here is the hash from the terms hashed with the agreeing address.
    mapping(bytes32 => Participant) private agreements;

    // The participant any wallet that accepts the terms.
    struct Participant {
        bool signed;
    }

    constructor() {
        issuer = msg.sender;
    }

    /* The setTerms allows an issuer to add new Term to their contract

       Error code 901: "Only the deployer can call this." 
    */
    function setTerms(string calldata url, string calldata value)
        external
        returns (bool)
    {
        require(msg.sender == issuer, "901");
        // If the issuer signature is detected, the terms can be updated
        terms = Terms({url: url, value: keccak256(abi.encodePacked(value))});
        emit NewTerms(url, value);
        return true;
    }

    /* The accept function is called when a user accepts an agreement represented by the hash
    
       Error code 902: "Invalid terms."
    */
    function accept(string calldata value) external {
        require(
            keccak256(abi.encodePacked(value)) == terms.value,
            "902"
        );
        bytes32 access = keccak256(abi.encodePacked(msg.sender, terms.value));
        agreements[access] = Participant({signed: true});
        emit NewParticipant(msg.sender);
    }

    // We can check if an address accepted the current terms or not
    function acceptedTerms(address _address) external view returns (bool) {
        bytes32 access = keccak256(abi.encodePacked(_address, terms.value));
        return agreements[access].signed;
    }

    // Get the terms url to display it so people can visit it and accept it
    function getTerms() external view returns (string memory) {
        return (terms.url);
    }

    /* The modifier allows a contract inheriting from this, to controll access easily based on agreement signing.
      
       Error code 903: "You must accept the terms first."
    */
    modifier checkAcceptance() {
        bytes32 access = keccak256(abi.encodePacked(msg.sender, terms.value));
        require(agreements[access].signed, "903");
        _;
    }
}



contract HRC20 is SimpleTerms {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint8 _decimals
    ) {
        decimals = _decimals;
        totalSupply = initialSupply * 10**uint256(decimals); // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
        name = tokenName; // Set the name for display purposes
        symbol = tokenSymbol; // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send '_value' tokens to '_to' from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value)
        public
        checkAcceptance
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send '_value' tokens to '_to' on behalf of '_from'
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public checkAcceptance returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows '_spender' to spend no more than '_value' tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value)
        public
        checkAcceptance
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}