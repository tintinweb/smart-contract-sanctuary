pragma solidity ^0.4.21;


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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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
}


/**
 * @title Team Fund Contract
 * @dev Lock conditions comply with the VNETToken contract
 */
contract TeamFund is Ownable {
    ERC20Basic public vnetToken;

    string public description;  // Description


    event Donate(address indexed _from, uint256 _amount);


    /**
     * @dev Constructor
     */
    constructor(ERC20Basic _token) public {
        vnetToken = _token;
        description = "Balance is locked by the VNETToken contract until 2019-6-30 23:59:59 UTC +0";
    }

    /**
     * @dev Sending eth to this contract will be considered as a donation
     */
    function () public payable {
        emit Donate(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw VNET Token
     */
    function withdrawVNET(address _to, uint256 _amount) external onlyOwner {
        assert(vnetToken.transfer(_to, _amount));
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