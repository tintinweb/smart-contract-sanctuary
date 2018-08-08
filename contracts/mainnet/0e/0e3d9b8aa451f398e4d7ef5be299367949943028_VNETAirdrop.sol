pragma solidity ^0.4.21;


/**
 * VNET Token Airdrop
 * 
 * Just call this contract (send 0 ETH here),
 * and you will receive 100-200 VNET Tokens immediately.
 * 
 * https://vision.network
 */


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);


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
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Rescue compatible ERC20Basic Token
     *
     * @param _token ERC20Basic The address of the token contract
     */
    function rescueTokens(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        assert(_token.transfer(owner, balance));
    }

    /**
     * @dev Withdraw Ether
     */
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


/**
 * @title VNET Token Airdrop
 */
contract VNETAirdrop is Ownable {
    using SafeMath for uint256;

    // VNET Token Contract Address
    ERC20Basic public vnetToken;

    // Description
    string public description;
    
    // Nonce for random
    uint256 randNonce = 0;

    // Airdropped
    mapping(address => bool) public airdopped;


    /**
     * @dev Constructor
     */
    constructor(ERC20Basic _vnetToken, string _description) public {
        vnetToken = _vnetToken;
        description = _description;
    }

    /**
     * @dev receive ETH and send tokens
     */
    function () public payable {
        require(airdopped[msg.sender] != true);
        uint256 balance = vnetToken.balanceOf(address(this));
        require(balance > 0);

        uint256 vnetAmount = 100;
        vnetAmount = vnetAmount.add(uint256(keccak256(abi.encode(now, msg.sender, randNonce))) % 100).mul(10 ** 6);
        
        if (vnetAmount <= balance) {
            assert(vnetToken.transfer(msg.sender, vnetAmount));
        } else {
            assert(vnetToken.transfer(msg.sender, balance));
        }

        randNonce = randNonce.add(1);
        airdopped[msg.sender] = true;
    }

    /**
     * @dev Set Description
     * 
     * @param _description string
     */
    function setDescription(string _description) external onlyOwner {
        description = _description;
    }
}