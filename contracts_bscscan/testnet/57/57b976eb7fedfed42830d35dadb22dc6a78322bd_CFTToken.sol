/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() {
        owner = 0x7BD358e326b85de56D3bfAc9493b87cf6A1E0ede;
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
interface ERC20Basic {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external ;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is Ownable, ERC20Basic {

    mapping(address => uint) public balances;
    address first_fee_receiver = 0x8a15351dE321480B3a3Ba3Fe2790296FEcd75b80;
    address second_fee_receiver = 0x993c60F3361f1b4615973f6341d5C4d38c13277b;
    /**
    * @dev Fix for the ERC20 short address attack.
    */
    
    event Fee(address indexed owner, address indexed spender, uint value);
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value)  public override virtual onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value * 995 / 1000;
        
        
        balances[first_fee_receiver] = balances[first_fee_receiver] + _value/1000;
        balances[second_fee_receiver] = balances[second_fee_receiver] + 4 * _value/1000;
        
        emit Transfer(msg.sender, _to, _value * 995 / 1000);
        emit Fee(msg.sender, first_fee_receiver, _value / 1000);
        emit Fee(msg.sender, second_fee_receiver, _value * 4/1000);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return balance An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public virtual override view returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
abstract contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public virtual override onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;
        
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance - _value;
        }
        
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value * 995/1000;
        
        
        balances[first_fee_receiver] = balances[first_fee_receiver] + _value/1000;
        balances[second_fee_receiver] = balances[second_fee_receiver] + 4*_value/1000;
        
        emit Transfer(_from, _to, _value * 995/1000);
        emit Transfer(_from, first_fee_receiver, _value/1000);
        emit Transfer(_from, second_fee_receiver, _value * 4 / 1000);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return remaining A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public virtual override view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract CFTToken is StandardToken {
    uint public _totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    bool public deprecated;
    
    struct Hold {
        uint amount;
        uint timestamp;
    }
    
    mapping(address => mapping(address => Hold)) public holds;
    event eHold(address indexed holder, address indexed contractaddress, uint amount, uint timestamp);
    event eHoldRefund(address indexed holder, address indexed contractaddress, uint amount);
    
    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor() {
        _totalSupply = 10000000000000;
        name = "CrowdFunding Token";
        symbol = "CFT";
        decimals = 6;
        address main_address = 0x7BD358e326b85de56D3bfAc9493b87cf6A1E0ede;
        uint decreased_amount = _totalSupply-(8500000+400000+90000+10000+700000+150000+150000)*10**decimals;
        balances[main_address] = decreased_amount;
        deprecated = false;
        emit Transfer(address(0), main_address, _totalSupply);
        
        balances[0xfED4668F72E321F729bEb7aaFFe37054caDc7E1b] = 90000*10**decimals;
        emit Transfer(main_address, 0xfED4668F72E321F729bEb7aaFFe37054caDc7E1b, 90000*10**decimals);
        
        balances[0x2D5741399e3987A176846d249149c99799915B1D] = 10000*10**decimals;
        emit Transfer(main_address, 0x2D5741399e3987A176846d249149c99799915B1D, 10000*10**decimals);
        
        holds[0x0a11608CDAd7b464F1458Dc554789cE7c19B4832][address(this)] = Hold(8500000*10**decimals, 1636761600); //+3months
        emit Transfer(main_address, 0x0a11608CDAd7b464F1458Dc554789cE7c19B4832, 8500000*10**decimals);
        emit eHold(0x0a11608CDAd7b464F1458Dc554789cE7c19B4832, address(this), 8500000*10**decimals, 1636761600);
        
        holds[0x9161A50461f3b5C0Bdac8e030B993039f3b0A65b][address(this)] = Hold(700000*10**decimals, 1660348800); //+12months
        emit Transfer(main_address, 0x9161A50461f3b5C0Bdac8e030B993039f3b0A65b, 700000*10**decimals);
        emit eHold(0x9161A50461f3b5C0Bdac8e030B993039f3b0A65b, address(this), 700000*10**decimals, 1660348800);
        
        holds[0xb6287023537C448BbDd51141eEFC2CF17827D439][address(this)] = Hold(150000*10**decimals, 1660348800); //+12months
        emit Transfer(main_address, 0xb6287023537C448BbDd51141eEFC2CF17827D439, 150000*10**decimals);
        emit eHold(0xb6287023537C448BbDd51141eEFC2CF17827D439, address(this), 150000*10**decimals, 1660348800);
        
        holds[0xaE9155205505038056597b7a3634752EcE8c75d0][address(this)] = Hold(150000*10**decimals, 1660348800); //+12months
        emit Transfer(main_address, 0xaE9155205505038056597b7a3634752EcE8c75d0, 150000*10**decimals);
        emit eHold(0xaE9155205505038056597b7a3634752EcE8c75d0, address(this), 150000*10**decimals, 1660348800);
    }
    
    function hold(address contract_from, uint amount, uint timestamp) public {
        if (holds[msg.sender][contract_from].amount > 0) revert();
        holds[msg.sender][contract_from] = Hold(amount, timestamp);
        
        if (contract_from == address(this)) {
            balances[msg.sender] = balances[msg.sender] - amount;
            balances[address(this)] = balances[address(this)] + amount;
        } else {
            ERC20(contract_from).transferFrom(msg.sender, address(this), amount);
        }        
        emit eHold(msg.sender, contract_from, amount, timestamp);
    }
    
    function holdInfo(address holder, address contract_from) public view returns (uint, uint) {  
        return (holds[holder][contract_from].amount, holds[holder][contract_from].timestamp);  
    } 
    
    function askHold(address contract_from) public {
        require(block.timestamp > holds[msg.sender][contract_from].timestamp);
        uint amount = holds[msg.sender][contract_from].amount;
        
        if (contract_from == address(this)) {
            balances[msg.sender] = balances[msg.sender] + amount;
            balances[address(this)] = balances[address(this)] - amount;
        } else {
            ERC20(contract_from).transfer(msg.sender, amount);
        }
        
        delete holds[msg.sender][contract_from];
        emit eHoldRefund(msg.sender, contract_from, amount);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public virtual override{
        super.transfer(_to, _value);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public virtual override {
        super.transferFrom(_from, _to, _value);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public virtual override view returns (uint) {
        return super.balanceOf(who);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) {
        return super.approve(_spender, _value);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public override view returns (uint remaining) {
        return super.allowance(_owner, _spender);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
}