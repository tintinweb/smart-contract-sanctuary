pragma solidity ^0.4.18;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
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
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}

interface Token {
    function transfer(address _to, uint256 _value) public;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    //function transfer(address _to, uint256 _value) public returns (bool success);
    //event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract BatchTransfer is Ownable {
    using SafeMath for uint256;
    event TransferToken(address indexed from, address indexed to, uint256 value);
    Token public standardToken;
    // List of admins
    mapping (address => bool) public contractAdmins;
    mapping (address => bool) public userTransfered;
    uint256 public totalUserTransfered;

    function BatchTransfer(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
        owner = msg.sender; //for test
    }

    function setContractToken (address _addressContract) public onlyOwner {
        require(_addressContract != address(0));
        standardToken = Token(_addressContract);
        totalUserTransfered = 0;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return standardToken.balanceOf(_owner);
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || contractAdmins[msg.sender]);
        _;
    }

    /**
    * @dev Add an contract admin
    */
    function setContractAdmin(address _admin, bool _isAdmin) public onlyOwner {
        contractAdmins[_admin] = _isAdmin;
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint256[] _values) external onlyOwnerOrAdmin returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);
        uint256 total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= standardToken.balanceOf(msg.sender));
        for(uint j = 0; j < _recipients.length; j++){
            standardToken.transfer(_recipients[j], _values[j]);
            totalUserTransfered = totalUserTransfered.add(1);
            userTransfered[_recipients[j]] = true;
            TransferToken(msg.sender, _recipients[j], _values[j]);
        }
        return true;
    }
}