/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// SPDX-License-Identifier: UNLICENSED

// File contracts/core/ArmorToken.sol
pragma solidity 0.8.4;

/*
    Copyright 2016, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// This minime token contract adjusted by ArmorFi to remove all functionality of
// inheriting from a parent and only keep functionality related to keeping track of
// balances through different checkpoints.

/// @title MiniMeToken Contract
/// @author Jordi Baylina
/// @dev This token contract's goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO's
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.


/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract ArmorToken {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = '69_420'; //An arbitrary versioning scheme

    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Shield that is allowed to mint tokens to peeps.
    address public arShield;
    // ShieldController--can just withdraw tokens.
    address public controller;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenName Name of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    constructor(
        address _arShield,
        string memory _tokenName,
        string memory _tokenSymbol
    ) 
    {
        require(arShield == address(0), "Contract already initialized.");
        arShield = _arShield;
        name = _tokenName;                                 // Set the name
        decimals = 18;                                     // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        creationBlock = block.number;
        controller = msg.sender;
    }

    modifier onlyController
    {
        require(msg.sender == controller, "Sender must be controller.");
        _;
    }
    
    modifier onlyShield
    {
        require(msg.sender == arShield, "Sender must be shield.");
        _;
    }

///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return success True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0

        // The standard ERC 20 transferFrom functionality
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;

        doTransfer(_from, _to, _amount);
        return true;
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               emit Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
               return;
           }

           // Do not allow transfer to 0x0 or the token contract itself
           require(_to != address(this));

           // If the amount being transfered is more than the balance of the
           //  account the transfer throws
           uint256 previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           uint256 previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           emit Transfer(_from, _to, _amount);

    }

    /// @param _owner The address that's balance is being requested
    /// @return balance The balance of `_owner` at the current block
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return success True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        
        // Armor is removing this cause frankly it's a bit annoying and so unlikely.
        //require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public view returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public view
        returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
                return 0;
        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
                return 0;
        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function mint(address _owner, uint _amount
    ) public onlyShield returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(address(0), _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function burn(uint _amount
    )  public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(msg.sender);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[msg.sender], previousBalanceFrom - _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) view internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint minimum = 0;
        uint max = checkpoints.length-1;
        while (max > minimum) {
            uint mid = (max + minimum + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                minimum = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[minimum].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               //Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               checkpoints.push( Checkpoint( uint128(block.number), uint128(_value) ) );
               //newCheckPoint.fromBlock =  uint128(block.number);
               //newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == address(0)) {
            payable(controller).transfer(address(this).balance);
            return;
        }

        ArmorToken token = ArmorToken(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


// File contracts/general/Governable.sol
pragma solidity ^0.8.4;

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract Governable {
    address payable private _governor;
    address payable private _pendingGovernor;

    event OwnershipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_governor == address(0), "already initialized");
        _governor = payable(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function governor() public view returns (address payable) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGov() {
        require(isGov(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isGov() public view returns (bool) {
        return msg.sender == _governor;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function transferOwnership(address payable newGovernor) public onlyGov {
        _pendingGovernor = newGovernor;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingGovernor, "Only pending governor can call this function");
        _transferOwnership(_pendingGovernor);
        _pendingGovernor = payable(address(0));
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function _transferOwnership(address payable newGovernor) internal {
        require(newGovernor != address(0));
        emit OwnershipTransferred(_governor, newGovernor);
        _governor = newGovernor;
    }

    uint256[50] private __gap;
}


// File contracts/interfaces/IarShield.sol
pragma solidity ^0.8.0;

interface IarShield {
    function initialize(
        address _oracle,
        address _pToken,
        address _arToken,
        address _uTokenLink,
        uint256[] calldata _fees,
        address[] calldata _covBases
    ) 
      external;
    function locked() external view returns(bool);
}


// File contracts/interfaces/ICovBase.sol
pragma solidity 0.8.4;

interface ICovBase {
    function editShield(address shield, bool active) external;
    function updateShield(uint256 ethValue) external payable;
    function checkCoverage(uint256 pAmount) external view returns (bool);
    function getShieldOwed(address shield) external view returns (uint256);
}


// File contracts/proxies/Proxy.sol
pragma solidity 0.8.4;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    fallback() external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
            }
    }

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view virtual returns (address);
}


// File contracts/proxies/UpgradeabilityProxy.sol
pragma solidity 0.8.4;

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.armor.proxy.implementation");

    /**
    * @dev Constructor function
    */
    constructor() public {}

    /**
    * @dev Tells the address of the current implementation
    * @return impl address of the current implementation
    */
    function implementation() public view override returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImplementation address representing the new implementation to be set
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
        sstore(position, _newImplementation)
        }
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}


// File contracts/proxies/OwnedUpgradeabilityProxy.sol
pragma solidity 0.8.4;

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.armor.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor(address _implementation) public {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return owner the address of the owner
    */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param _implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}


// File contracts/core/ShieldController.sol
pragma solidity 0.8.4;

/** 
 * @title Shield Controller
 * @notice Shield Controller is in charge of creating new shields and storing universal variables.
 * @author Armor.fi -- Robert M.C. Forster
**/
contract ShieldController is Governable {

    // Liquidation bonus for users who are liquidating funds.
    uint256 public bonus;
    // Fee % for referrals. 10000 == 100% of the rest of the fees.
    uint256 public refFee;
    // Amount that needs to be deposited to lock the contract.
    uint256 public depositAmt;
    // Default beneficiary of all shields.
    address payable public beneficiary;
    // Mapping of arShields to determine if call is allowed.
    mapping (address => bool) public shieldMapping;
    // List of all arShields.
    address[] private arShields;
    // List of all arTokens.
    address[] private arTokens;

    // Event sent from arShield for frontend to get all referrals from one source.
    event ShieldAction(
        address user, 
        address indexed referral,
        address indexed shield,
        address indexed token,
        uint256 amount,
        uint256 refFee,
        bool mint,
        uint256 timestamp
    ); 

    function initialize(
        uint256 _bonus,
        uint256 _refFee,
        uint256 _depositAmt
    )
      external
    {
        require(arShields.length == 0, "Contract already initialized.");
        initializeOwnable();
        bonus = _bonus;
        refFee = _refFee;
        depositAmt = _depositAmt;
        beneficiary = payable(msg.sender);
    }

    // In case a token has Ether lost in it we need to be able to receive.
    receive() external payable {}

    /**
     * @notice Greatly helps frontend to have all shield referral events in one spot.
     * @param _user The user making the contract interaction.
     * @param _referral The referral of the contract interaction.
     * @param _shield The address of the shield calling.
     * @param _pToken The address of the token for the shield.
    **/
    function emitAction(
        address _user,
        address _referral,
        address _shield,
        address _pToken,
        uint256 _amount,
        uint256 _refFee,
        bool _mint
    )
      external
    {
        require(shieldMapping[msg.sender] == true, "Only arShields may call emitEvents.");
        emit ShieldAction(_user, _referral, _shield, _pToken, _amount, _refFee, _mint, block.timestamp);
    }

    /**
     * @notice Create a new arShield from an already-created family.
     * @param _name Name of the armorToken to be created.
     * @param _symbol Symbol of the armorToken to be created.
     * @param _oracle Address of the family's oracle contract to find token value.
     * @param _pToken Protocol token that the shield will use.
     * @param _uTokenLink Address of the ChainLink contract for the underlying token.
     * @param _masterCopy Mastercopy for the arShield proxy.
     * @param _fees Mint/redeem fee for each coverage base.
     * @param _covBases Coverage bases that the shield will subscribe to.
    **/
    function createShield(
        string calldata _name,
        string calldata _symbol,
        address _oracle,
        address _pToken,
        address _uTokenLink,
        address _masterCopy,
        uint256[] calldata _fees,
        address[] calldata _covBases
    )
      external
      onlyGov
    {
        address proxy = address( new OwnedUpgradeabilityProxy(_masterCopy) );
        address token = address( new ArmorToken(proxy, _name, _symbol) );
        
        IarShield(proxy).initialize(
            _oracle,
            _pToken,
            token,
            _uTokenLink,
            _fees,
            _covBases
        );
        
        for(uint256 i = 0; i < _covBases.length; i++) ICovBase(_covBases[i]).editShield(proxy, true);

        arTokens.push(token);
        arShields.push(proxy);
        shieldMapping[proxy] = true;

        OwnedUpgradeabilityProxy( payable(proxy) ).transferProxyOwnership(msg.sender);
    }

    /**
     * @notice Delete a shield. We use both shield address and index for safety.
     * @param _shield Address of the shield to delete from array.
     * @param _idx Index of the shield in the arShields array.
    **/
    function deleteShield(
        address _shield,
        uint256 _idx
    )
      external
      onlyGov
    {
        if (arShields[_idx] == _shield) {
            arShields[_idx] = arShields[arShields.length - 1];
            arTokens[_idx] = arTokens[arTokens.length - 1];
            arShields.pop();
            arTokens.pop();
            delete shieldMapping[_shield];
        }
    }

    /**
     * @notice Claim any lost tokens on an arShield contract.
     * @param _armorToken Address of the Armor token that has tokens or ether lost in it.
     * @param _token The address of the lost token.
     * @param _beneficiary Address to send the tokens to.
    **/
    function claimTokens(
        address _armorToken,
        address _token,
        address payable _beneficiary
    )
      external
      onlyGov
    {
        ArmorToken(_armorToken).claimTokens(_token);
        if (_token == address(0)) _beneficiary.transfer(address(this).balance);
        else ArmorToken(_token).transfer( _beneficiary, ArmorToken(_token).balanceOf( address(this) ) );
    }

    /**
     * @notice Edit the discount on Chainlink price that liquidators receive.
     * @param _newBonus The new bonus amount that will be given to liquidators.
    **/
    function changeBonus(
        uint256 _newBonus
    )
      external
      onlyGov
    {
        bonus = _newBonus;
    }

    /**
     * @notice Change amount required to deposit to lock a shield.
     * @param _depositAmt New required deposit amount in Ether to lock a contract.
    **/
    function changeDepositAmt(
        uint256 _depositAmt
    )
      external
      onlyGov
    {
        depositAmt = _depositAmt;
    }

    /**
     * @notice Change amount required to deposit to lock a shield.
     * @param _refFee New fee to be paid to referrers. 10000 == 100%
     *                of the protocol fees that will be charged.
    **/
    function changeRefFee(
        uint256 _refFee
    )
      external
      onlyGov
    {
        refFee = _refFee;
    }

    /**
     * @notice Change the main beneficiary of all shields.
     * @param _beneficiary New address to withdraw excess funds and get default referral fees.
    **/
    function changeBeneficiary(
        address payable _beneficiary
    )
      external
      onlyGov
    {
        beneficiary = _beneficiary;
    }

    /**
     * @notice Get all arShields.
    **/
    function getShields()
      external
      view
    returns(
        address[] memory shields
    )
    {
        shields = arShields;
    }

    /**
     * @notice Get all arTokens.
    **/
    function getTokens()
      external
      view
    returns(
        address[] memory tokens
    )
    {
        tokens = arTokens;
    }

    /**
     * @notice Used by frontend to get a list of balances for the user in one call.
     *         Start and end are included in case the list gets too long for the gas of one call.
     * @param _user Address to get balances for.
     * @param _start Start index of the arTokens list. Inclusive.
     * @param _end End index of the arTokens list (if too high, defaults to length). Exclusive.
    **/
    function getBalances(
        address _user, 
        uint256 _start, 
        uint256 _end
    )
      public
      view
    returns(
        address[] memory tokens,
        uint256[] memory balances
    )
    {
        if (_end > arTokens.length || _end == 0) _end = arTokens.length;
        tokens = new address[](_end - _start);
        balances = new uint[](_end - _start);

        for (uint256 i = _start; i < _end; i++) {
            tokens[i] = arTokens[i];
            balances[i] = ArmorToken(arTokens[i]).balanceOf(_user);
        }
    }

}