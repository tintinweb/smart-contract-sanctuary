/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

pragma solidity ^0.7.4;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address who) public virtual view returns (uint);
    function transfer(address to, uint value) public virtual;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual view returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public override virtual onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public override virtual view returns (uint) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is BasicToken, ERC20 {
    using SafeMath for uint;
    mapping (address => mapping (address => uint)) public allowed;

    uint public MAX_UINT = 2**256 - 1;

    function transferFrom(address _from, address _to, uint _value) public override virtual onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) override virtual public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public override virtual view returns (uint) {
        return allowed[_owner][_spender];
    }

}

contract ProdexpToken is StandardToken {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint public decimals;
    
    uint public unlockedTime;
    address public lockedAddress;
    address public icoAddress;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor() {
        _totalSupply = 1000000000000000000000000000;
        name = "Prodexp Token";
        symbol = "PROD";
        decimals = 18;
        
        //Locked information
        lockedAddress = 0x26e7336705C074ac1Bc87C6637eAeFf63ABd14F4;
        icoAddress = 0x4E384604D8a9bDb44D3A25aC8717c81f421d5Cc5;
        unlockedTime = block.timestamp.add(1095 days);
        
        balances[icoAddress] = 200000000000000000000000000;
        emit Transfer(address(0), icoAddress, 200000000000000000000000000);
        
        balances[lockedAddress] = 800000000000000000000000000;
        emit Transfer(address(0), lockedAddress, 800000000000000000000000000);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public override {
        require(_validFromLockedAddress(msg.sender),"Locked address can not transfer now");
        return super.transfer(_to, _value);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public override {
        require(_validFromLockedAddress(_from),"Locked address can not transfer now");
        return super.transferFrom(_from, _to, _value);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    
    //Check sender is locked address or not, if yes, check for unlocked time
    function _validFromLockedAddress(address sender) private view returns(bool){
        if(sender != lockedAddress)
            return true;
            
        if(unlockedTime < block.timestamp)
            return true;
            
        return false;
    }
}

//SPDX-License-Identifier: MIT