/*
  Copyright 2017 Sharder Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  ################ Sharder-Token-v2.0 ###############
    a) Adding the emergency transfer functionality for owner.
    b) Removing the logic of crowdsale according to standard MintToken in order to improve the neatness and
    legibility of the Sharder smart contract coding.
    c) Adding the broadcast event &#39;Frozen&#39;.
    d) Changing the parameters of name, symbol, decimal, etc. to lower-case according to convention. Adjust format of input paramters.
    e) The global parameter is added to our smart contact in order to avoid that the exchanges trade Sharder tokens
    before officials partnering with Sharder.
    f) Add holder array to facilitate the exchange of the current ERC-20 token to the Sharder Chain token later this year
    when Sharder Chain is online.
    g) Lockup and lock-up query functions.
    The deplyed online contract you can found at: https://etherscan.io/address/XXXXXX

    Sharder-Token-v1.0 is expired. You can check the code and get the details on branch &#39;sharder-token-v1.0&#39;.
*/
pragma solidity ^0.4.18;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
* @title Sharder Token v2.0. SS(Sharder) is upgrade from SS(Sharder Storage).
* @author Ben - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c0b8b980b3a8a1b2a4a5b2eeafb2a7">[email&#160;protected]</a>>.
* @dev ERC-20: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/
contract SharderToken {
    using SafeMath for uint;
    string public name = "Sharder";
    string public symbol = "SS";
    uint8 public  decimals = 18;

    /// +--------------------------------------------------------------+
    /// |                 SS(Sharder) Token Issue Plan                 |
    /// +--------------------------------------------------------------+
    /// |                    First Round(Crowdsale)                    |
    /// +--------------------------------------------------------------+
    /// |     Total Sale    |      Airdrop      |  Community Reserve   |
    /// +--------------------------------------------------------------+
    /// |     250,000,000   |     50,000,000    |     50,000,000       |
    /// +--------------------------------------------------------------+
    /// | Team Reserve(50,000,000 SS): Issue in 3 years period         |
    /// +--------------------------------------------------------------+
    /// | System Reward(100,000,000 SS): Reward by Sharder Chain Auto  |
    /// +--------------------------------------------------------------+
    uint256 public totalSupply = 350000000000000000000000000;

    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;

    /// The owner of contract
    address public owner;

    /// The admin account of contract
    address public admin;

    mapping (address => bool) internal accountLockup;
    mapping (address => uint) public accountLockupTime;
    mapping (address => bool) public frozenAccounts;

    mapping (address => uint) internal holderIndex;
    address[] internal holders;

    ///First round tokens whether isssued.
    bool internal firstRoundTokenIssued = false;

    /// Contract pause state
    bool public paused = true;

    /// Issue event index starting from 0.
    uint256 internal issueIndex = 0;

    // Emitted when a function is invocated without the specified preconditions.
    event InvalidState(bytes msg);

    // This notifies clients about the token issued.
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

    // This notifies clients about the amount to transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount to approve
    event Approval(address indexed owner, address indexed spender, uint value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This notifies clients about the account frozen
    event FrozenFunds(address target, bool frozen);

    // This notifies clients about the pause
    event Pause();

    // This notifies clients about the unpause
    event Unpause();


    /*
     * MODIFIERS
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when account not frozen.
     */
    modifier isNotFrozen {
        require(frozenAccounts[msg.sender] != true && now > accountLockupTime[msg.sender]);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier isNotPaused() {
        require((msg.sender == owner && paused) || (msg.sender == admin && paused) || !paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier isPaused() {
        require(paused);
        _;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal isNotFrozen isNotPaused {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        // Update holders
        addOrUpdateHolder(_from);
        addOrUpdateHolder(_to);

        Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _transferTokensWithDecimal The amount to be transferred.
    */
    function transfer(address _to, uint _transferTokensWithDecimal) public {
        _transfer(msg.sender, _to, _transferTokensWithDecimal);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _transferTokensWithDecimal uint the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint _transferTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(_transferTokensWithDecimal <= allowance[_from][msg.sender]);
        // Check allowance
        allowance[_from][msg.sender] -= _transferTokensWithDecimal;
        _transfer(_from, _to, _transferTokensWithDecimal);
        return true;
    }

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_approveTokensWithDecimal` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _approveTokensWithDecimal the max amount they can spend
     */
    function approve(address _spender, uint256 _approveTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _approveTokensWithDecimal;
        Approval(msg.sender, _spender, _approveTokensWithDecimal);
        return true;
    }

    /**
     * Destroy tokens
     * Remove `_value` tokens from the system irreversibly
     * @param _burnedTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
    */
    function burn(uint256 _burnedTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(balanceOf[msg.sender] >= _burnedTokensWithDecimal);
        /// Check if the sender has enough
        balanceOf[msg.sender] -= _burnedTokensWithDecimal;
        /// Subtract from the sender
        totalSupply -= _burnedTokensWithDecimal;
        Burn(msg.sender, _burnedTokensWithDecimal);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _burnedTokensWithDecimal the amount of reserve tokens. !!! IMPORTANT is 18 DECIMALS
    */
    function burnFrom(address _from, uint256 _burnedTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(balanceOf[_from] >= _burnedTokensWithDecimal);
        /// Check if the targeted balance is enough
        require(_burnedTokensWithDecimal <= allowance[_from][msg.sender]);
        /// Check allowance
        balanceOf[_from] -= _burnedTokensWithDecimal;
        /// Subtract from the targeted balance
        allowance[_from][msg.sender] -= _burnedTokensWithDecimal;
        /// Subtract from the sender&#39;s allowance
        totalSupply -= _burnedTokensWithDecimal;
        Burn(_from, _burnedTokensWithDecimal);
        return true;
    }

    /**
     * Add holder addr into arrays.
     * @param _holderAddr the address of the holder
    */
    function addOrUpdateHolder(address _holderAddr) internal {
        // Check and add holder to array
        if (holderIndex[_holderAddr] == 0) {
            holderIndex[_holderAddr] = holders.length++;
        }
        holders[holderIndex[_holderAddr]] = _holderAddr;
    }

    /**
     * CONSTRUCTOR
     * @dev Initialize the Sharder Token v2.0
     */
    function SharderToken() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    /**
    * @dev Set admin account to manage contract.
    */
    function setAdmin(address _address) public onlyOwner {
        admin = _address;
    }

    /**
    * @dev Issue first round tokens to `owner` address.
    */
    function issueFirstRoundToken() public onlyOwner {
        require(!firstRoundTokenIssued);

        balanceOf[owner] = balanceOf[owner].add(totalSupply);
        Issue(issueIndex++, owner, 0, totalSupply);
        addOrUpdateHolder(owner);
        firstRoundTokenIssued = true;
    }

    /**
     * @dev Issue tokens for reserve.
     * @param _issueTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
    */
    function issueReserveToken(uint256 _issueTokensWithDecimal) onlyOwner public {
        balanceOf[owner] = balanceOf[owner].add(_issueTokensWithDecimal);
        totalSupply = totalSupply.add(_issueTokensWithDecimal);
        Issue(issueIndex++, owner, 0, _issueTokensWithDecimal);
    }

    /**
    * @dev Frozen or unfrozen account.
    */
    function changeFrozenStatus(address _address, bool _frozenStatus) public onlyAdmin {
        frozenAccounts[_address] = _frozenStatus;
    }

    /**
    * @dev Lockup account till the date. Can&#39;t lock-up again when this account locked already.
    * 1 year = 31536000 seconds, 0.5 year = 15768000 seconds
    */
    function lockupAccount(address _address, uint _lockupSeconds) public onlyAdmin {
        require((accountLockup[_address] && now > accountLockupTime[_address]) || !accountLockup[_address]);
        // lock-up account
        accountLockupTime[_address] = now + _lockupSeconds;
        accountLockup[_address] = true;
    }

    /**
    * @dev Get the cuurent ss holder count.
    */
    function getHolderCount() public constant returns (uint _holdersCount){
        return holders.length - 1;
    }

    /*
    * @dev Get the current ss holder addresses.
    */
    function getHolders() public onlyAdmin constant returns (address[] _holders){
        return holders;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyAdmin isNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyAdmin isPaused public {
        paused = false;
        Unpause();
    }

    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }

    function setName(string _name) public onlyOwner {
        name = _name;
    }

    /// @dev This default function reject anyone to purchase the SS(Sharder) token after crowdsale finished.
    function() public payable {
        revert();
    }

}