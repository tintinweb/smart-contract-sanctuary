//SourceUnit: Beneficiary.sol

pragma solidity ^0.5.8;

import "./Ownable.sol";

contract Beneficiary is Ownable {

    address payable public beneficiary;

    constructor() public  {
        beneficiary = msg.sender;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function withdrawal(uint256 value) public onlyOwner {
        if (value > address(this).balance) {
            revert("Insufficient balance");
        }

        beneficiaryPayout(value);
    }

    function withdrawalAll() public onlyOwner {
        beneficiaryPayout(address(this).balance);
    }

    function beneficiaryPayout(uint256 value) internal {
        beneficiary.transfer(value);
        emit BeneficiaryPayout(value);
    }

    event BeneficiaryPayout(uint256 value);
}


//SourceUnit: MBt.sol

pragma solidity ^0.5.8;

import "./Manageable.sol";
import "./TRC20.sol";

contract MBt is TokenTRC20, Manageable {
    uint public cap = 1_000_000 * 1e18;

    address payable operator = address(0);

    constructor() TokenTRC20(0, "MegaCryptoPolis $MEGA Token", "MEGA") public {
        _mint(address(this), cap - 100_000 * 1e18);
        _mint(address(0x222aAE2bd32102fF4A37EbbE83ec1604529CA794), 100_000 * 1e18);
    }

    function setOperator(address payable _operator) public onlyManager {
        operator = _operator;
        _approve(address(this), _operator, cap);
    }


    function increaseOperatorAllowance() public onlyManager {
        _approve(address(this), operator,  allowance[address(this)][operator] + cap);
    }

    function decreaseOperatorAllowance() public onlyManager {
        _approve(address(this), operator, 0);
    }
}


//SourceUnit: Manageable.sol

pragma solidity ^0.5.8;

import "./Beneficiary.sol";


contract Manageable is Beneficiary {

    mapping(address => bool) public managers;

    modifier onlyManager() {

        require(managers[msg.sender] || msg.sender == address(this), "Only managers allowed");
        _;
    }


    constructor() public {
        managers[msg.sender] = true;
    }

    function setManager(address _manager) public onlyOwner {
        managers[_manager] = true;
    }

    function deleteManager(address _manager) public onlyOwner {
        delete managers[_manager];
    }

    function _addressToPayable(address _address) internal pure returns (address payable) {
        return address(uint160(_address));
    }

    event FailedPayout(address to, uint256 value);

}


//SourceUnit: Ownable.sol

pragma solidity ^0.5.8;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Transfer to null address is not allowed");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenTRC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply;  // Update total supply with the decimal amount
        balanceOf[address(this)] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
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
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _approve(address _sender, address _spender, uint _value) internal {
        allowance[_sender][_spender] = _value;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "TRC20: mint to the zero address");

        totalSupply = totalSupply + _amount;
        balanceOf[_account] = balanceOf[_account] + _amount;
        emit Transfer(address(0), _account, _amount);
    }


    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}