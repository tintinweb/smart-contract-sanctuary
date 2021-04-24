/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.4.19;

/* Interface for ERC20 Tokens */
contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

/* Interface for pTokens contract */
contract pToken {
    function redeem(uint256 _value, string memory _btcAddress) public returns (bool _success);
}

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes _data, uint256 _gas) external returns (bytes32);
    function requireToConfirmMessage(address _contract, bytes _data, uint256 _gas) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);
}

interface DOGEMEXXDAI {
    function depositTokenForUser(address token, uint128 amount, address user);
}

// The DOGEMEX base Contract
contract DOGEMEX_Base {
    address public owner; // holds the address of the contract owner
    mapping (address => bool) public admins; // mapping of admin addresses
    address public AMBBridgeContract;
    address public DOGEMEX_XDAI_CONTRACT;

    uint256 public inactivityReleasePeriod; // period in blocks before a user can use the withdraw() function

    bool public destroyed = false; // contract is destoryed
    uint256 public destroyDelay = 1000000; // number of blocks after destroy, the contract is still active (aprox 6 monthds)
    uint256 public destroyBlock;

    uint256 public ambInstructionGas = 2000000;

    mapping (bytes32 => bool) public processedMessages; // records processed bridge messages, so the same message is not executed twice

    
    /**
     *
     *  BALNCE FUNCTIONS
     *
     **/

    // Deposit ETH to contract
    function deposit() payable {
        if (destroyed) revert();
        
        sendDepositInstructionToAMBBridge(msg.sender, address(0), msg.value);
    }

    // Deposit token to contract
    function depositToken(address token, uint128 amount) {
        if (destroyed) revert();
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw; // attempts to transfer the token to this contract, if fails throws an error
        sendDepositInstructionToAMBBridge(msg.sender, token, amount);
    }

    // Deposit token to contract for a user
    function depositTokenForUser(address token, uint128 amount, address user) {    
        if (destroyed) revert();    

        if (!Token(token).transferFrom(msg.sender, this, amount)) throw; // attempts to transfer the token to this contract, if fails throws an error
        sendDepositInstructionToAMBBridge(user, token, amount);
    }


    function pTokenRedeem(address token, uint256 amount, string destinationAddress) onlyAMBBridge returns (bool success) {
        if (!pToken(token).redeem(amount, destinationAddress)) revert();
        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        processedMessages[msgId] = true;
        emit pTokenRedeemEvent(token, msg.sender, amount, destinationAddress);
    }


    function sendDepositInstructionToAMBBridge(address user, address token, uint256 amount) internal
    {
        bytes4 methodSelector = DOGEMEXXDAI(0).depositTokenForUser.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, token, amount, user);

        uint256 gas = ambInstructionGas;

        // send AMB bridge instruction
        bytes32 msgId = IAMB(AMBBridgeContract).requireToPassMessage(DOGEMEX_XDAI_CONTRACT, data, gas);

        emit Deposit(token, user, amount, msgId); // fires the deposit event
    }    
 


    // Withdrawal function used by the server to execute withdrawals
    function withdrawForUser(
        address token, // the address of the token to be withdrawn
        uint256 amount, // the amount to be withdrawn
        address user // address of the user
    ) onlyAMBBridge returns (bool success) {
        if (token == address(0)) { // checks if the withdrawal is in ETH or Tokens
            if (!user.send(amount)) throw; // sends ETH
        } else {
            if (!Token(token).transfer(user, amount)) throw; // sends tokens
        }

        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        processedMessages[msgId] = true;
        emit Withdraw(token, user, amount, msgId); // fires the withdraw event
    }



    /**
     *
     *  HELPER FUNCTIONS
     *
     **/

    // Event fired when the owner of the contract is changed
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }

    // Owner getter function
    function getOwner() returns (address out) {
        return owner;
    }

    // Adds or disables an admin account
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }


    // Allows for admins only to call the function
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }


    // Allows for AMB Bridge only to call the function
    modifier onlyAMBBridge {
        if (msg.sender != AMBBridgeContract) throw;

        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        require(!processedMessages[msgId], "Error: message already processed");
        _;
    }

    function() external {
        throw;
    }

    function assert(bool assertion) {
        if (!assertion) throw;
    }

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }



    /**
     *
     *  ADMIN FUNCTIONS
     *
     **/
    // Deposit event fired when a deposit takes place
    event Deposit(address indexed token, address indexed user, uint256 amount, bytes32 msgId);

    // Withdraw event fired when a withdrawal id executed
    event Withdraw(address indexed token, address indexed user, uint256 amount, bytes32 msgId);
    
    // pTokenRedeemEvent event fired when a pToken withdrawal is executed
    event pTokenRedeemEvent(address indexed token, address indexed user, uint256 amount, string destinationAddress);

    // Change inactivity release period event
    event InactivityReleasePeriodChange(uint256 value);

    // Fee account changed event
    event FeeAccountChanged(address indexed newFeeAccount);



    // Constructor function, initializes the contract and sets the core variables
    function DOGEMEX_Base(uint256 inactivityReleasePeriod_, address AMBBridgeContract_, address DOGEMEX_XDAI_CONTRACT_) {
        owner = msg.sender;
        inactivityReleasePeriod = inactivityReleasePeriod_;
        AMBBridgeContract = AMBBridgeContract_;
        DOGEMEX_XDAI_CONTRACT = DOGEMEX_XDAI_CONTRACT_;
    }

    // Sets the inactivity period before a user can withdraw funds manually
    function destroyContract() onlyOwner returns (bool success) {
        if (destroyed) throw;
        destroyBlock = block.number;

        return true;
    }

    // Sets the inactivity period before a user can withdraw funds manually
    function setInactivityReleasePeriod(uint256 expiry) onlyOwner returns (bool success) {
        if (expiry > 1000000) throw;
        inactivityReleasePeriod = expiry;

        emit InactivityReleasePeriodChange(expiry);
        return true;
    }

    // Returns the inactivity release perios
    function getInactivityReleasePeriod() view returns (uint256)
    {
        return inactivityReleasePeriod;
    }


    function releaseFundsAfterDestroy(address token, uint256 amount) onlyOwner returns (bool success) {
        if (!destroyed) throw;
        if (safeAdd(destroyBlock, destroyDelay) > block.number) throw; // destroy delay not yet passed

        if (token == address(0)) { // checks if withdrawal is a token or ETH, ETH has address 0x00000... 
            if (!msg.sender.send(amount)) throw; // send ETH
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw; // Send token
        }
    }

    function setAmbInstructionGas(uint256 newGas) onlyOwner {
        ambInstructionGas = newGas;
    }
}