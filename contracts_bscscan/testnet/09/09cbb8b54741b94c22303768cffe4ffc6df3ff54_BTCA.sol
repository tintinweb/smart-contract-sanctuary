/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

/**
 * Math operations with safety checks
 */
library SafeMath {

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * Bitcoin Anonymous Contract
 */
contract BTCA {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol
        ) {
            balanceOf[msg.sender] = initialSupply;
            totalSupply = initialSupply;
            name = tokenName;
            symbol = tokenSymbol;
            decimals = decimalUnits;
            owner = msg.sender;
        }

    /**
     * Transfer functions
     */
    function transfer(address _to, uint256 _value) public {
        require(_to != address(this));
        require(_to != address(0), "Cannot use zero address");
        require(_value > 0, "Cannot use zero value");

        require (balanceOf[msg.sender] >= _value, "Balance not enough");         // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to], "Overflow" );        // Check for overflows
        
        uint previousBalances = balanceOf[msg.sender] + balanceOf[_to];          
        
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);               // Add the same to the recipient
        
        emit Transfer(msg.sender, _to, _value);                                  // Notify anyone listening that this transfer took place
        
        assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require (_value > 0, "Cannot use zero");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function multiTransfer(address[] memory _receivers, uint256 _value) public returns (bool success) {
        uint256 toSend = _value * 10**18;

        require(_receivers.length <= 200, "Too many recipients");

        for(uint256 i = 0; i < _receivers.length; i++) {
            transfer(_receivers[i], toSend);
        }

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot use zero address");
        require(_value > 0, "Cannot use zero value");
        
        require( balanceOf[_from] >= _value, "Balance not enough" );
        require( balanceOf[_to] + _value > balanceOf[_to], "Cannot overflow" );
        
        require( _value <= allowance[_from][msg.sender], "Cannot over allowance" );
        
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    /**
     * Ownership functions
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}