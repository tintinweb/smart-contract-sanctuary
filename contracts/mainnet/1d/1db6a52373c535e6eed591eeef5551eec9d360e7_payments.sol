pragma solidity ^0.6.11;
import "./IERC20.sol";
import "./SafeMath.sol";

contract payments {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    address private owner;
    bool public initialized;
    address private tokenAddress;
    address private recipientAddress;
    
    mapping(address => uint256) public balances;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    constructor(address _tokenAddress, address _recipientAddress) public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        tokenAddress = _tokenAddress;
        recipientAddress = _recipientAddress;
        initialized = true;
    }
    
    function deposit(uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, recipientAddress, amount), 'Transfer ERROR');
        balances[msg.sender] = SafeMath.add(balances[msg.sender], amount);
    }
    
    function spend(address user, uint32 amount) public isOwner {
        require(balances[user] >= amount, 'Insufficient Balance');
        balances[user] = SafeMath.sub(balances[user], amount);
    }
    
    function changePayee(address user) public isOwner {
       recipientAddress = user;
    }
    
    function changeToken(address token) public isOwner {
       tokenAddress = token;
    }
}