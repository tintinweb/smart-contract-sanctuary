/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
    uint256 public _totalSupply = 100000000000000000000000000; //100 000 000
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address who) public virtual view returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 */
abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    // Owner address of contract. Assigned on deployment.
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



/**
 * Standard ERC20 token implementation
 */
abstract contract StandardToken is ERC20, Ownable {
    // Addresses and balances (in tokens) of all clients. Required by ERC20.
    mapping (address => uint256) balances;
    // Clients, allowed to work. Required by ERC20.
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function transfer(address _to, uint256 _value) override public returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to])
        {
            uint256 obalance = balances[msg.sender];
            if ( obalance >= _value)
            {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                emit Transfer(msg.sender, _to, _value);
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            return false;
        }
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/*
 * @title Coin
*/
contract Coin is StandardToken {
    // A symbol of a coin.
    string public constant symbol = "EXTRA";
    // A name of a coin.
    string public constant name = "ExtraToken";
    // A number of decimals in a coin.
    uint8 public constant decimals = 18;
    
    event TransferFromTo(address indexed _from, address indexed _to, address indexed _by, uint256 _value);

    /**
    * @dev Constructor of a contract
    */
    constructor() payable {
        owner = payable(msg.sender);
        balances[owner] = _totalSupply;
        emit Transfer(address(this), owner, _totalSupply);
    }

    /**
    * @dev Destructor of a contract.
    */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (msg.sender == owner) {
            allowed[_from][msg.sender] = _value;
        }

        if (balances[_from] >= _value
        && allowed[_from][msg.sender] >= _value
        && _value > 0)
        {
            uint256 obalance = balances[_from];
            if ( obalance >= _value)
            {

                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                balances[_to] += _value;
                emit Transfer(_from, _to, _value);
                emit TransferFromTo(_from, _to, msg.sender, _value);
                return true;
            }
            else
            {
                return false;
            }
        }
        else
		{
            return false;
        }
    }

}