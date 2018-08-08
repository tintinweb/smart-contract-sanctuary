pragma solidity ^0.4.21;


/**
 * VNET Token Private Placement Contract
 * 
 * Send ETH here, and you will receive the VNET Tokens immediately.
 * The minimum ivnestment limit is 300 ETH, and the accumulated maximum limit is 1000 ETH.
 * 
 * RATE: 1 ETH = 200,000 VNET
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
 * @title VNET Token Private Placement
 */
contract VNETPrivatePlacement is Ownable {
    using SafeMath for uint256;

    ERC20Basic public vnetToken;

    uint256 public rate = 200000;
    string public description;
    uint256 public etherMinimum = 300;
    uint256 public etherMaximum = 1000;

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
        // Make sure balance > 0
        uint256 balance = vnetToken.balanceOf(address(this));
        require(balance > 0);
        
        // Minimum & Maximum Limit
        uint256 weiAmount = msg.value;
        require(weiAmount >= etherMinimum.mul(10 ** 18));
        require(weiAmount <= etherMaximum.mul(10 ** 18));

        // VNET Token Amount to be send back
        uint256 tokenAmount = weiAmount.mul(rate).div(10 ** 12);

        // Send VNET
        if (balance >= tokenAmount) {
            assert(vnetToken.transfer(msg.sender, tokenAmount));
            owner.transfer(address(this).balance);
        } else {
            uint256 expend = balance.div(rate);
            assert(vnetToken.transfer(msg.sender, balance));
            msg.sender.transfer(weiAmount - expend.mul(10 ** 12));
            owner.transfer(address(this).balance);
        }
    }

    /**
     * @dev Send VNET Token
     *
     * @param _to address
     * @param _amount uint256
     */ 
    function sendVNET(address _to, uint256 _amount) external onlyOwner {
        assert(vnetToken.transfer(_to, _amount));
    }

    /**
     * @dev Set Description
     * 
     * @param _description string
     */
    function setDescription(string _description) external onlyOwner returns (bool) {
        description = _description;
        return true;
    }
}