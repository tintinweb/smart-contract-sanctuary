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
  a) Added an emergency transfer function to transfer tokens to the contract owner.
  b) Removed crowdsale logic according to the MintToken standard to improve neatness and legibility of the token contract.
  c) Added the &#39;Frozen&#39; broadcast event.
  d) Changed name, symbol, decimal, etc, parameters to lower-case according to the convention. Adjust format parameters.
  e) Added a global parameter to the smart contact to prevent exchanges trading Sharder tokens before officially partnering.
  f) Added address mapping to facilitate the exchange of current ERC-20 tokens to the Sharder Chain token when it goes live.
  g) Added Lockup and lock-up query functionality.

  Sharder-Token-v1.0 has expired. The deprecated code is available in the sharder-token-v1.0&#39; branch.
*/
pragma solidity ^0.4.18;

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
    * @dev Add two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
* @title Sharder Token v2.0. SS (Sharder) is an upgrade from SS (Sharder Storage).
* @author Ben-<<span class="__cf_email__" data-cfemail="661e1f26150e071402031448091401">[email&#160;protected]</span>>, Community Contributor: Nick Parrin-<<span class="__cf_email__" data-cfemail="04746576766d6a4474766b706b6a69656d682a676b69">[email&#160;protected]</span>>
* @dev ERC-20: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/
contract SharderToken {
    using SafeMath for uint256;
    string public name = "Sharder";
    string public symbol = "SS";
    uint8 public decimals = 18;

    /// +--------------------------------------------------------------+
    /// |                 SS (Sharder) Token Issue Plan                |
    /// +--------------------------------------------------------------+
    /// |                    First Round (Crowdsale)                   |
    /// +--------------------------------------------------------------+
    /// |     Total Sale    |      Airdrop      |  Community Reserve   |
    /// +--------------------------------------------------------------+
    /// |     250,000,000   |     50,000,000    |     50,000,000       |
    /// +--------------------------------------------------------------+
    /// | Team Reserve (50,000,000 SS): Issue in 3 year period         |
    /// +--------------------------------------------------------------+
    /// | System Reward (100,000,000 SS): Reward by Sharder Chain Auto |
    /// +--------------------------------------------------------------+
    
    // Total Supply of Sharder Tokens
    uint256 public totalSupply = 350000000000000000000000000;

    // Multi-dimensional mapping to keep allow transfers between addresses
    mapping (address => mapping (address => uint256)) public allowance;
    
    // Mapping to retrieve balance of a specific address
    mapping (address => uint256) public balanceOf;

    /// The owner of contract
    address public owner;

    /// The admin account of contract
    address public admin;

    // Mapping of addresses that are locked up
    mapping (address => bool) internal accountLockup;

    // Mapping that retrieves the current lockup time for a specific address
    mapping (address => uint256) public accountLockupTime;
    
    // Mapping of addresses that are frozen
    mapping (address => bool) public frozenAccounts;
    
    // Mapping of holder addresses (index)
    mapping (address => uint256) internal holderIndex;

    // Array of holder addressses
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
    event Issue(uint256 issueIndex, address addr, uint256 ethAmount, uint256 tokenAmount);

    // This notifies clients about the amount to transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount to approve
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
     * @dev Internal transfer, only can be called by this contract
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to transfer between addressses.
     */
    function _transfer(address _from, address _to, uint256 _value) internal isNotFrozen isNotPaused {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        // Update Token holders
        addOrUpdateHolder(_from);
        addOrUpdateHolder(_to);
        // Send the Transfer Event
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * @dev Transfer to a specific address
     * @param _to The address to transfer to.
     * @param _transferTokensWithDecimal The amount to be transferred.
    */
    function transfer(address _to, uint256 _transferTokensWithDecimal) public {
        _transfer(msg.sender, _to, _transferTokensWithDecimal);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _transferTokensWithDecimal uint the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint256 _transferTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(_transferTokensWithDecimal <= allowance[_from][msg.sender]);
        // Check allowance
        allowance[_from][msg.sender] -= _transferTokensWithDecimal;
        _transfer(_from, _to, _transferTokensWithDecimal);
        return true;
    }

    /**
     * @dev Allows `_spender` to spend no more (allowance) than `_approveTokensWithDecimal` tokens in your behalf
     *
     * !!Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address authorized to spend.
     * @param _approveTokensWithDecimal the max amount they can spend.
     */
    function approve(address _spender, uint256 _approveTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _approveTokensWithDecimal;
        Approval(msg.sender, _spender, _approveTokensWithDecimal);
        return true;
    }

    /**
     * @dev Destroy tokens and remove `_value` tokens from the system irreversibly
     * @param _burnedTokensWithDecimal The amount of tokens to burn. !!IMPORTANT is 18 DECIMALS
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
     * @dev Destroy tokens (`_value`) from the system irreversibly on behalf of `_from`.
     * @param _from The address of the sender.
     * @param _burnedTokensWithDecimal The amount of tokens to burn. !!! IMPORTANT is 18 DECIMALS
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
     * @dev Add holder address into `holderIndex` mapping and to the `holders` array.
     * @param _holderAddr The address of the holder
    */
    function addOrUpdateHolder(address _holderAddr) internal {
        // Check and add holder to array
        if (holderIndex[_holderAddr] == 0) {
            holderIndex[_holderAddr] = holders.length++;
            holders[holderIndex[_holderAddr]] = _holderAddr;
        }
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
     * @param _issueTokensWithDecimal The amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
    */
    function issueReserveToken(uint256 _issueTokensWithDecimal) onlyOwner public {
        balanceOf[owner] = balanceOf[owner].add(_issueTokensWithDecimal);
        totalSupply = totalSupply.add(_issueTokensWithDecimal);
        Issue(issueIndex++, owner, 0, _issueTokensWithDecimal);
    }

    /**
    * @dev Freeze or Unfreeze an address
    * @param _address address that will be frozen or unfrozen
    * @param _frozenStatus status indicating if the address will be frozen or unfrozen.
    */
    function changeFrozenStatus(address _address, bool _frozenStatus) public onlyAdmin {
        frozenAccounts[_address] = _frozenStatus;
    }

    /**
    * @dev Lockup account till the date. Can&#39;t lock-up again when this account locked already.
    * 1 year = 31536000 seconds, 0.5 year = 15768000 seconds
    */
    function lockupAccount(address _address, uint256 _lockupSeconds) public onlyAdmin {
        require((accountLockup[_address] && now > accountLockupTime[_address]) || !accountLockup[_address]);
        // lock-up account
        accountLockupTime[_address] = now + _lockupSeconds;
        accountLockup[_address] = true;
    }

    /**
    * @dev Get the cuurent SS holder count.
    */
    function getHolderCount() public view returns (uint256 _holdersCount){
        return holders.length - 1;
    }

    /**
    * @dev Get the current SS holder addresses.
    */
    function getHolders() public onlyAdmin view returns (address[] _holders){
        return holders;
    }

    /**
    * @dev Pause the contract by only the owner. Triggers Pause() Event.
    */
    function pause() onlyAdmin isNotPaused public {
        paused = true;
        Pause();
    }

    /**
    * @dev Unpause the contract by only he owner. Triggers the Unpause() Event.
    */
    function unpause() onlyAdmin isPaused public {
        paused = false;
        Unpause();
    }

    /**
    * @dev Change the symbol attribute of the contract by the Owner.
    * @param _symbol Short name of the token, symbol.
    */
    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }

    /**
    * @dev Change the name attribute of the contract by the Owner.
    * @param _name Name of the token, full name.
    */
    function setName(string _name) public onlyOwner {
        name = _name;
    }

    /// @dev This default function rejects anyone to purchase the SS (Sharder) token. Crowdsale has finished.
    function() public payable {
        revert();
    }

}