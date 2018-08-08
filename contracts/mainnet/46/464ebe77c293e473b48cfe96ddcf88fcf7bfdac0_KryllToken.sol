pragma solidity ^0.4.23;

// File: zeppelin/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: zeppelin/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: zeppelin/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

// File: zeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

// File: contracts/TransferableToken.sol

/**
    Copyright (c) 2018 Cryptense SAS - Kryll.io

    Kryll.io / Transferable ERC20 token mechanism
    Version 0.2
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

    based on the contracts of OpenZeppelin:
    https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts
**/

pragma solidity ^0.4.23;




/**
 * @title Transferable token
 *
 * @dev StandardToken modified with transfert on/off mechanism.
 **/
contract TransferableToken is StandardToken,Ownable {

    /** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    * @dev TRANSFERABLE MECANISM SECTION
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/

    event Transferable();
    event UnTransferable();

    bool public transferable = false;
    mapping (address => bool) public whitelisted;

    /**
        CONSTRUCTOR
    **/
    
    constructor() 
        StandardToken() 
        Ownable()
        public 
    {
        whitelisted[msg.sender] = true;
    }

    /**
        MODIFIERS
    **/

    /**
    * @dev Modifier to make a function callable only when the contract is not transferable.
    */
    modifier whenNotTransferable() {
        require(!transferable);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is transferable.
    */
    modifier whenTransferable() {
        require(transferable);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the caller can transfert token.
    */
    modifier canTransfert() {
        if(!transferable){
            require (whitelisted[msg.sender]);
        } 
        _;
   }
   
    /**
        OWNER ONLY FUNCTIONS
    **/

    /**
    * @dev called by the owner to allow transferts, triggers Transferable state
    */
    function allowTransfert() onlyOwner whenNotTransferable public {
        transferable = true;
        emit Transferable();
    }

    /**
    * @dev called by the owner to restrict transferts, returns to untransferable state
    */
    function restrictTransfert() onlyOwner whenTransferable public {
        transferable = false;
        emit UnTransferable();
    }

    /**
      @dev Allows the owner to add addresse that can bypass the transfer lock.
    **/
    function whitelist(address _address) onlyOwner public {
        require(_address != 0x0);
        whitelisted[_address] = true;
    }

    /**
      @dev Allows the owner to remove addresse that can bypass the transfer lock.
    **/
    function restrict(address _address) onlyOwner public {
        require(_address != 0x0);
        whitelisted[_address] = false;
    }


    /** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    * @dev Strandard transferts overloaded API
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/

    function transfer(address _to, uint256 _value) public canTransfert returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfert returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

  /**
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. We recommend to use use increaseApproval
   * and decreaseApproval functions instead !
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263555598
   */
    function approve(address _spender, uint256 _value) public canTransfert returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public canTransfert returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public canTransfert returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

// File: contracts/KryllToken.sol

/**
    Copyright (c) 2018 Cryptense SAS - Kryll.io

    Kryll.io / KRL ERC20 Token Smart Contract    
    Version 0.2

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

    based on the contracts of OpenZeppelin:
    https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts
**/

pragma solidity ^0.4.23;




contract KryllToken is TransferableToken {
//    using SafeMath for uint256;

    string public symbol = "KRL";
    string public name = "Kryll.io Token";
    uint8 public decimals = 18;
  

    uint256 constant internal DECIMAL_CASES    = (10 ** uint256(decimals));
    uint256 constant public   SALE             =  17737348 * DECIMAL_CASES; // Token sale
    uint256 constant public   TEAM             =   8640000 * DECIMAL_CASES; // TEAM (vested)
    uint256 constant public   ADVISORS         =   2880000 * DECIMAL_CASES; // Advisors
    uint256 constant public   SECURITY         =   4320000 * DECIMAL_CASES; // Security Reserve
    uint256 constant public   PRESS_MARKETING  =   5040000 * DECIMAL_CASES; // Press release
    uint256 constant public   USER_ACQUISITION =  10080000 * DECIMAL_CASES; // User Acquisition 
    uint256 constant public   BOUNTY           =    720000 * DECIMAL_CASES; // Bounty (ICO & future)

    address public sale_address     = 0x29e9535AF275a9010862fCDf55Fe45CD5D24C775;
    address public team_address     = 0xd32E4fb9e8191A97905Fb5Be9Aa27458cD0124C1;
    address public advisors_address = 0x609f5a53189cAf4EeE25709901f43D98516114Da;
    address public security_address = 0x2eA5917E227552253891C1860E6c6D0057386F62;
    address public press_address    = 0xE9cAad0504F3e46b0ebc347F5bf591DBcB49756a;
    address public user_acq_address = 0xACD80ad0f7beBe447ea0625B606Cf3DF206DafeF;
    address public bounty_address   = 0x150658D45dc62E9EB246E82e552A3ec93d664985;
    bool public initialDistributionDone = false;

    /**
    * @dev Setup the initial distribution addresses
    */
    function reset(address _saleAddrss, address _teamAddrss, address _advisorsAddrss, address _securityAddrss, address _pressAddrss, address _usrAcqAddrss, address _bountyAddrss) public onlyOwner{
        require(!initialDistributionDone);
        team_address = _teamAddrss;
        advisors_address = _advisorsAddrss;
        security_address = _securityAddrss;
        press_address = _pressAddrss;
        user_acq_address = _usrAcqAddrss;
        bounty_address = _bountyAddrss;
        sale_address = _saleAddrss;
    }

    /**
    * @dev compute & distribute the tokens
    */
    function distribute() public onlyOwner {
        // Initialisation check
        require(!initialDistributionDone);
        require(sale_address != 0x0 && team_address != 0x0 && advisors_address != 0x0 && security_address != 0x0 && press_address != 0x0 && user_acq_address != 0 && bounty_address != 0x0);      

        // Compute total supply 
        totalSupply_ = SALE.add(TEAM).add(ADVISORS).add(SECURITY).add(PRESS_MARKETING).add(USER_ACQUISITION).add(BOUNTY);

        // Distribute KRL Token 
        balances[owner] = totalSupply_;
        emit Transfer(0x0, owner, totalSupply_);

        transfer(team_address, TEAM);
        transfer(advisors_address, ADVISORS);
        transfer(security_address, SECURITY);
        transfer(press_address, PRESS_MARKETING);
        transfer(user_acq_address, USER_ACQUISITION);
        transfer(bounty_address, BOUNTY);
        transfer(sale_address, SALE);
        initialDistributionDone = true;
        whitelist(sale_address); // Auto whitelist sale address
        whitelist(team_address); // Auto whitelist team address (vesting transfert)
    }

    /**
    * @dev Allows owner to later update token name if needed.
    */
    function setName(string _name) onlyOwner public {
        name = _name;
    }

}