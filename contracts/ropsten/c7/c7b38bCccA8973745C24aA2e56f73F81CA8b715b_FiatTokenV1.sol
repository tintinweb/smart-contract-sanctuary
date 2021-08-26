pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
* Copyright CENTRE SECZ 2018
* Copyright (c) 2020 Xfers Pte. Ltd.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is furnished to
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.24;

import "./Ownable.sol";

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
*/
contract Blacklistable is Ownable {

    address public blacklister;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
    */
    modifier onlyBlacklister() {
        require(msg.sender == blacklister, "not blacklister");
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
    */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false, "notBlacklisted: is blacklisted");
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
    */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
    */
    function blacklist(address _account) public onlyBlacklister {
        require(_account != address(0), "blacklist: 0x0 invalid");
        require(!isBlacklisted(_account), "blacklist: already blacklisted");
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) public onlyBlacklister {
        require(_account != address(0), "unBlacklist: 0x0 invalid");
        require(isBlacklisted(_account), "unBlacklist: not blacklisted");
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0), "updateBlacklister: 0x0 invalid");
        require(_newBlacklister != blacklister, "updateBlacklister: same address");
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }
}

/**
* Copyright (c) 2020 Xfers Pte. Ltd.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is furnished to
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.24;

/**
 * @title ERC20Recovery
 * @dev Minimal version of ERC20 interface required to allow ERC20 locked tokens recovery
 */

contract ERC20Recovery {
  function balanceOf(address account) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

/**
* Copyright CENTRE SECZ 2018
* Copyright (c) 2020 Xfers Pte. Ltd.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is furnished to
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Ownable.sol";
import "./Blacklistable.sol";
import "./Pausable.sol";
import "./ERC20Recovery.sol";

/**
 * @title FiatToken
 * @dev Token backed by fiat reserves
 */
contract FiatTokenV1 is Ownable, Pausable, Blacklistable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    address public masterMinter;

    bool internal initialized;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);

    /**
     * @dev Throws if called by any account other than a minter
    */
    modifier onlyMinters() {
        require(minters[msg.sender] == true, "minters only");
        _;
    }

    /**
     * @dev Throws if called by any account other than the masterMinter
    */
    modifier onlyMasterMinter() {
        require(msg.sender == masterMinter, "master minter only");
        _;
    }

    /**
     * @dev Function to initialise contract
     * @param _name string Token name
     * @param _symbol string Token symbol
     * @param _decimals uint8 Token decimals
     * @param _masterMinter address Address of the master minter
     * @param _pauser address Address of the pauser
     * @param _blacklister address Address of the blacklister
     * @param _owner address Address of the owner
    */
    function initialize(
        string _name,
        string _symbol,
        uint8 _decimals,
        address _masterMinter,
        address _pauser,
        address _blacklister,
        address _owner
    ) public {
        require(!initialized, "already initialized!");
        require(_masterMinter != address(0), "master minter can't be 0x0");
        require(_pauser != address(0), "pauser can't be 0x0");
        require(_blacklister != address(0), "blacklister can't be 0x0");
        require(_owner != address(0), "owner can't be 0x0");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        masterMinter = _masterMinter;
        pauser = _pauser;
        blacklister = _blacklister;
        setOwner(_owner);
        initialized = true;
    }

    /**
     * @dev Function to mint tokens
     * Validates that the contract is not paused
     * only minters can call this function
     * minter and the address that will received the minted tokens are not blacklisted
     * @param _to address The address that will receive the minted tokens.
     * @param _amount uint256 The amount of tokens to mint. Must be less than or equal to the minterAllowance of the caller.
     * @return True if the operation was successful.
    */
    function mint(address _to, uint256 _amount)
        public
        whenNotPaused
        onlyMinters
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        require(_to != address(0), "can't mint to 0x0");
        require(_amount > 0, "amount to mint has to be > 0");

        uint256 mintingAllowedAmount = minterAllowance(msg.sender);
        require(_amount <= mintingAllowedAmount, "minter allowance too low");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
        if (minterAllowance(msg.sender) == 0) {
            minters[msg.sender] = false;
            emit MinterRemoved(msg.sender);
        }
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Function to get minter allowance of an address
     * @param _minter address The address of check minter allowance of
     * @return The minter allowance of the address
    */
    function minterAllowance(address _minter) public view returns (uint256) {
        return minterAllowed[_minter];
    }

    /**
     * @dev Function to check if an address is a minter
     * @param _address The address to check
     * @return A boolean value to indicates if an address is a minter
    */
    function isMinter(address _address) public view returns (bool) {
        return minters[_address];
    }

    /**
     * @dev Function to get total supply of token
     * @return The total supply of the token
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Function to get token balance of an address
     * @param _address address The account
     * @return The token balance of an address
    */
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    /**
     * @dev Function to approves a spender to spend up to a certain amount of tokens
     * Validates that the contract is not paused
     * the owner and spender are not blacklisted
     * Avoid calling this function if possible (https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param _spender address The Address of the spender
     * @param _amount uint256 The amount of tokens that the spender is approved to spend
     * @return True if the operation was successful.
    */
    function approve(address _spender, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        return _approve(_spender, _amount);
    }

    /**
     * @dev Alternative function to the approve function
     * Increases the allowance of the spender
     * Validates that the contract is not paused
     * the owner and spender are not blacklisted
     * @param _spender address The Address of the spender
     * @param _addedValue uint256 The amount of tokens to be added to a spender's allowance
     * @return True if the operation was successful.
    */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        uint256 updatedAllowance = allowed[msg.sender][_spender].add(
            _addedValue
        );
        return _approve(_spender, updatedAllowance);
    }

    /**
     * @dev Alternative function to the approve function
     * Decreases the allowance of the spender
     * Validates that the contract is not paused
     * the owner and spender are not blacklisted
     * @param _spender address The Address of the spender
     * @param _subtractedValue uint256 The amount of tokens to be subtracted from a spender's allowance
     * @return True if the operation was successful.
    */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        uint256 updatedAllowance = allowed[msg.sender][_spender].sub(
            _subtractedValue
        );
        return _approve(_spender, updatedAllowance);
    }

    /**
     * @dev Function to approves a spender to spend up to a certain amount of tokens
     * @param _spender address The Address of the spender
     * @param _amount uint256 The amount of tokens that the spender is approved to spend
    */
    function _approve(address _spender, uint256 _amount)
        internal
        returns (bool)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Function to get token allowance given to a spender by the owner
     * @param _owner address The address of the owner
     * @param _spender address The address of the spender
     * @return The number of tokens that a spender can spend on behalf of the owner
    */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Function to transfer tokens from one address to another.
     * Validates that the contract is not paused
     * the caller, sender and receiver of the tokens are not blacklisted
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _amount uint256 the amount of tokens to be transferred
     * @return True if the operation was successful.
    */
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(_to)
        notBlacklisted(msg.sender)
        notBlacklisted(_from)
        returns (bool)
    {
        require(_to != address(0), "can't transfer to 0x0");
        require(_amount <= balances[_from], "insufficient balance");
        require(
            _amount <= allowed[_from][msg.sender],
            "token allowance is too low"
        );

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Function to transfer token to a specified address
     * Validates that the contract is not paused
     * The sender and receiver are not blacklisted
     * @param _to The address to transfer to.
     * @param _amount The amount of tokens to be transferred.
     * @return True if the operation is successful
    */
    function transfer(address _to, uint256 _amount)
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        require(_to != address(0), "can't transfer to 0x0");
        require(_amount <= balances[msg.sender], "insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * @dev Function to increase minter allowance of a minter
    * Validates that only the master minter can call this function
    * @param _minter address The address of the minter
    * @param _increasedAmount uint256 The amount of to be added to a minter's allowance
    */
    function increaseMinterAllowance(address _minter, uint256 _increasedAmount)
        public
        onlyMasterMinter
    {
        require(_minter != address(0), "minter can't be 0x0");
        uint256 updatedAllowance = minterAllowance(_minter).add(
            _increasedAmount
        );
        minterAllowed[_minter] = updatedAllowance;
        minters[_minter] = true;
        emit MinterConfigured(_minter, updatedAllowance);
    }

    /**
    * @dev Function to decrease minter allowance of a minter
    * Validates that only the master minter can call this function
    * @param _minter address The address of the minter
    * @param _decreasedAmount uint256 The amount of allowance to be subtracted from a minter's allowance
    */
    function decreaseMinterAllowance(address _minter, uint256 _decreasedAmount)
        public
        onlyMasterMinter
    {
        require(_minter != address(0), "minter can't be 0x0");
        require(minters[_minter], "not a minter");

        uint256 updatedAllowance = minterAllowance(_minter).sub(
            _decreasedAmount
        );
        minterAllowed[_minter] = updatedAllowance;
        if (minterAllowance(_minter) > 0) {
            emit MinterConfigured(_minter, updatedAllowance);
        } else {
            minters[_minter] = false;
            emit MinterRemoved(_minter);

        }
    }

    /**
     * @dev Function to allow a minter to burn some of its own tokens
     * Validates that the contract is not paused
     * caller is a minter and is not blacklisted
     * amount is less than or equal to the minter's mint allowance balance
     * @param _amount uint256 the amount of tokens to be burned
    */
    function burn(uint256 _amount)
        public
        whenNotPaused
        onlyMinters
        notBlacklisted(msg.sender)
    {
        uint256 balance = balances[msg.sender];
        require(_amount > 0, "burn amount has to be > 0");
        require(balance >= _amount, "balance in minter is < amount to burn");

        totalSupply_ = totalSupply_.sub(_amount);
        balances[msg.sender] = balance.sub(_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    /**
     * @dev Function to allow the blacklister to burn entire balance of tokens from a blacklisted address
     * Validates that contract is not paused
     * caller is the blacklister
     * address to burn tokens from is a blacklisted address
     * @param _from address the address to burn tokens from
    */
    function lawEnforcementWipingBurn(address _from)
        public
        whenNotPaused
        onlyBlacklister
    {
        require(
            isBlacklisted(_from),
            "Can't wipe balances of a non blacklisted address"
        );
        uint256 balance = balances[_from];
        totalSupply_ = totalSupply_.sub(balance);
        balances[_from] = 0;
        emit Burn(_from, balance);
        emit Transfer(_from, address(0), balance);
    }

    /**
     * @dev Function to update the masterMinter role
     * Validates that the caller is the owner
     */
    function updateMasterMinter(address _newMasterMinter) public onlyOwner {
        require(_newMasterMinter != address(0), "master minter can't be 0x0");
        require(_newMasterMinter != masterMinter, "master minter is the same");
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }

    /**
      * @dev Function to reject all EIP223 compatible tokens
      * @param _from address The address that is transferring the tokens
      * @param _value uint256 the amount of the specified token
      * @param _data bytes The data passed from the caller
      */
    function tokenFallback(address _from, uint256 _value, bytes _data)
        external
        pure
    {
        revert("reject EIP223 token transfers");
    }

    /**
     * @dev Function to reclaim all ERC20Recovery compatible tokens
     * Validates that the caller is the owner
     * @param _tokenAddress address The address of the token contract
     */
    function reclaimToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "token can't be 0x0");
        ERC20Recovery token = ERC20Recovery(_tokenAddress);
        uint256 balance = token.balanceOf(this);
        require(token.transfer(owner(), balance), "reclaim token failed");
    }
}

/**
* Copyright CENTRE SECZ 2018
* Copyright (c) 2020 Xfers Pte. Ltd.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is furnished to
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.24;

contract Ownable {

  address private _owner;

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
  * @dev The constructor sets the original owner of the contract to the sender account.
  */
  constructor() internal {
    setOwner(msg.sender);
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner(), "onlyOwner: not owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "transferOwnership: 0x0 invalid");
    require(newOwner != owner(), "transferOwnership: same address");
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

/**
* Copyright CENTRE SECZ 2018
* Copyright (c) 2020 Xfers Pte. Ltd.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is furnished to
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.24;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * Based on openzeppelin tag v1.10.0 commit: feb665136c0dae9912e08397c1a21c4af3651ef3
 * Modifications:
 * 1) Added pauser role, switched pause/unpause to be onlyPauser (6/14/2018)
 * 2) Removed whenNotPause/whenPaused from pause/unpause (6/14/2018)
 * 3) Removed whenPaused (6/14/2018)
 * 4) Switches ownable library to use zeppelinos (7/12/18)
 * 5) Remove constructor (7/13/18)
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PauserChanged(address indexed newAddress);


  address public pauser;
  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused, "whenNotPaused: contract paused");
    _;
  }

  /**
   * @dev throws if called by any account other than the pauser
   */
  modifier onlyPauser() {
    require(msg.sender == pauser, "pauser only");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser {
    paused = false;
    emit Unpause();
  }

  /**
   * @dev update the pauser role
   */
  function updatePauser(address _newPauser) public onlyOwner {
    require(_newPauser != address(0), "updatePauser: 0x0 invalid");
    require(_newPauser != pauser, "updatePauser: same address");
    pauser = _newPauser;
    emit PauserChanged(pauser);
  }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}