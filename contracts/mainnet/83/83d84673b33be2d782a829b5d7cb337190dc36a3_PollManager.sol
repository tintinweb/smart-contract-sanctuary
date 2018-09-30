pragma solidity ^0.4.23;

interface ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data
    ) external;
}


contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    constructor() internal { 
        controller = msg.sender; 
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}


/*
* Used to proxy function calls to the RLPReader for testing
*/
/*
* @author Hamdi Allam hamdi.a<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5c30303d31656b1c3b313d3530723f3331">[email&#160;protected]</a>
* Please reach our for any questions/concerns
*/


library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0) 
            return RLPItem(0, 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }
    }

    /*
    * Helpers
    */

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 1;
        
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /** RLPItem conversions into data types **/

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len == 21, "Invalid RLPItem. Addresses are encoded in 20 bytes");
        
        uint memPtr = item.memPtr + 1; // skip the length prefix
        uint addr;
        assembly {
            addr := div(mload(memPtr), exp(256, 12)) // right shift 12 bytes. we want the most significant 20 bytes
        }
        
        return address(addr);
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;

        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }


    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) internal pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

contract RLPHelper {
    using RLPReader for bytes;
    using RLPReader for uint;
    using RLPReader for RLPReader.RLPItem;

    function isList(bytes memory item) public pure returns (bool) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.isList();
    }

    function itemLength(bytes memory item) public pure returns (uint) {
        uint memPtr;
        assembly {
            memPtr := add(0x20, item)
        }

        return memPtr._itemLength();
    }

    function numItems(bytes memory item) public pure returns (uint) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.numItems();
    }

    function toBytes(bytes memory item) public pure returns (bytes) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toBytes();
    }

    function toUint(bytes memory item) public pure returns (uint) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toUint();
    }

    function toAddress(bytes memory item) public pure returns (address) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toAddress();
    }

    function toBoolean(bytes memory item) public pure returns (bool) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return rlpItem.toBoolean();
    }

    function bytesToString(bytes memory item) public pure returns (string) {
        RLPReader.RLPItem memory rlpItem = item.toRlpItem();
        return string(rlpItem.toBytes());
    }

    /* custom destructuring */
    /*function customDestructure(bytes memory item) public pure returns (address, bool, uint) {
        // first three elements follow the return types in order. Ignore the rest
        RLPReader.RLPItem[] memory items = item.toRlpItem().toList();
        return (items[0].toAddress(), items[1].toBoolean(), items[2].toUint());
    }

    function customNestedDestructure(bytes memory item) public pure returns (address, uint) {
        RLPReader.RLPItem[] memory items = item.toRlpItem().toList();
        items = items[0].toList();
        return (items[0].toAddress(), items[1].toUint());
    }*/


    //======================================

    function pollTitle(bytes memory item) public pure returns (string) {
        RLPReader.RLPItem[] memory items = item.toRlpItem().toList();
        return string(items[0].toBytes());
    }

    function pollBallot(bytes memory item, uint ballotNum) public pure returns (string) {
        RLPReader.RLPItem[] memory items = item.toRlpItem().toList();
        items = items[1].toList();
        return string(items[ballotNum].toBytes());
    }
}




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
/**
 * @title MiniMeToken Contract
 * @author Jordi Baylina
 * @dev This token contract&#39;s goal is to make it easy for anyone to clone this
 *  token using the token distribution at a given block, this will allow DAO&#39;s
 *  and DApps to upgrade their features in a decentralized manner without
 *  affecting the original token
 * @dev It is ERC20 compliant, but still needs to under go further testing.
 */



/**
 * @dev The token controller contract must implement these functions
 */
interface TokenController {
    /**
     * @notice Called when `_owner` sends ether to the MiniMe Token contract
     * @param _owner The address that sent the ether to create tokens
     * @return True if the ether is accepted, false if it throws
     */
    function proxyPayment(address _owner) external payable returns(bool);

    /**
     * @notice Notifies the controller about a token transfer allowing the
     *  controller to react if desired
     * @param _from The origin of the transfer
     * @param _to The destination of the transfer
     * @param _amount The amount of the transfer
     * @return False if the controller does not authorize the transfer
     */
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

    /**
     * @notice Notifies the controller about an approval allowing the
     *  controller to react if desired
     * @param _owner The address that calls `approve()`
     * @param _spender The spender in the `approve()` call
     * @param _amount The amount in the `approve()` call
     * @return False if the controller does not authorize the approval
     */
    function onApprove(address _owner, address _spender, uint _amount) external
        returns(bool);
}






// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

interface ERC20Token {

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    /**
     * @notice return total supply of tokens
     */
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract MiniMeTokenInterface is ERC20Token {

    /**
     * @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     *  its behalf, and then a function is triggered in the contract that is
     *  being approved, `_spender`. This allows users to use their tokens to
     *  interact with contracts in one function call instead of two
     * @param _spender The address of the contract able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return True if the function call was successful
     */
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) 
        external 
        returns (bool success);

    /**    
     * @notice Creates a new clone token with the initial distribution being
     *  this token at `_snapshotBlock`
     * @param _cloneTokenName Name of the clone token
     * @param _cloneDecimalUnits Number of decimals of the smallest unit
     * @param _cloneTokenSymbol Symbol of the clone token
     * @param _snapshotBlock Block when the distribution of the parent token is
     *  copied to set the initial distribution of the new clone token;
     *  if the block is zero than the actual block, the current block is used
     * @param _transfersEnabled True if transfers are allowed in the clone
     * @return The address of the new MiniMeToken Contract
     */
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) 
        public
        returns(address);

    /**    
     * @notice Generates `_amount` tokens that are assigned to `_owner`
     * @param _owner The address that will be assigned the new tokens
     * @param _amount The quantity of tokens generated
     * @return True if the tokens are generated correctly
     */
    function generateTokens(
        address _owner,
        uint _amount
    )
        public
        returns (bool);

    /**
     * @notice Burns `_amount` tokens from `_owner`
     * @param _owner The address that will lose the tokens
     * @param _amount The quantity of tokens to burn
     * @return True if the tokens are burned correctly
     */
    function destroyTokens(
        address _owner,
        uint _amount
    ) 
        public
        returns (bool);

    /**        
     * @notice Enables token holders to transfer their tokens freely if true
     * @param _transfersEnabled True if transfers are allowed in the clone
     */
    function enableTransfers(bool _transfersEnabled) public;

    /**    
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token) public;

    /**
     * @dev Queries the balance of `_owner` at a specific `_blockNumber`
     * @param _owner The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at `_blockNumber`
     */
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) 
        public
        constant
        returns (uint);

    /**
     * @notice Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     */
    function totalSupplyAt(uint _blockNumber) public view returns(uint);

}




////////////////
// MiniMeTokenFactory
////////////////

/**
 * @dev This contract is used to generate clone contracts from a contract.
 *  In solidity this is the way to create a contract from a contract of the
 *  same class
 */
contract MiniMeTokenFactory {

    /**
     * @notice Update the DApp by creating a new token with new functionalities
     *  the msg.sender becomes the controller of this clone token
     * @param _parentToken Address of the token being cloned
     * @param _snapshotBlock Block of the parent token that will
     *  determine the initial distribution of the clone token
     * @param _tokenName Name of the new token
     * @param _decimalUnits Number of decimals of the new token
     * @param _tokenSymbol Token Symbol for the new token
     * @param _transfersEnabled If true, tokens will be able to be transferred
     * @return The address of the new token contract
     */
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

/**
 * @dev The actual token contract, the default controller is the msg.sender
 *  that deploys the contract, so usually this token will be deployed by a
 *  token controller contract, which Giveth will call a "Campaign"
 */
contract MiniMeToken is MiniMeTokenInterface, Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "MMT_0.1"; //An arbitrary versioning scheme

    /**
     * @dev `Checkpoint` is the structure that attaches a block number to a
     *  given value, the block number attached is the one that last changed the
     *  value
     */
    struct Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

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

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /** 
     * @notice Constructor to create a MiniMeToken
     * @param _tokenFactory The address of the MiniMeTokenFactory contract that
     *  will create the Clone token contracts, the token factory needs to be
     *  deployed first
     * @param _parentToken Address of the parent token, set to 0x0 if it is a
     *  new token
     * @param _parentSnapShotBlock Block of the parent token that will
     *  determine the initial distribution of the clone token, set to 0 if it
     *  is a new token
     * @param _tokenName Name of the new token
     * @param _decimalUnits Number of decimals of the new token
     * @param _tokenSymbol Token Symbol for the new token
     * @param _transfersEnabled If true, tokens will be able to be transferred
     */
    constructor(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) 
        public
    {
        require(_tokenFactory != address(0)); //if not set, clone feature will not work properly
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /**
     * @notice Send `_amount` tokens to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /**
     * @notice Send `_amount` tokens to `_to` from `_from` on the condition it
     *  is approved by `_from`
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) 
        public 
        returns (bool success)
    {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount) { 
                return false;
            }
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

    /**
     * @dev This is the actual transfer function in the token contract, it can
     *  only be called by other functions in this contract.
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function doTransfer(
        address _from,
        address _to,
        uint _amount
    ) 
        internal
        returns(bool)
    {

        if (_amount == 0) {
            return true;
        }

        require(parentSnapShotBlock < block.number);

        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != 0) && (_to != address(this)));

        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }

        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(_from, _to, _amount));
        }

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

        return true;
    }

    function doApprove(
        address _from,
        address _spender,
        uint256 _amount
    )
        internal 
        returns (bool)
    {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[_from][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(_from, _spender, _amount));
        }

        allowed[_from][_spender] = _amount;
        emit Approval(_from, _spender, _amount);
        return true;
    }

    /**
     * @param _owner The address that&#39;s balance is being requested
     * @return The balance of `_owner` at the current block
     */
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /**
     * @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
     *  its behalf. This is a modified version of the ERC20 approve function
     *  to be a little bit safer
     * @param _spender The address of the account able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return True if the approval was successful
     */
    function approve(address _spender, uint256 _amount) external returns (bool success) {
        doApprove(msg.sender, _spender, _amount);
    }

    /**
     * @dev This function makes it easy to read the `allowed[]` map
     * @param _owner The address of the account that owns the token
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens of _owner that _spender is allowed
     *  to spend
     */
    function allowance(
        address _owner,
        address _spender
    ) 
        external
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
    /**
     * @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     *  its behalf, and then a function is triggered in the contract that is
     *  being approved, `_spender`. This allows users to use their tokens to
     *  interact with contracts in one function call instead of two
     * @param _spender The address of the contract able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return True if the function call was successful
     */
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) 
        external 
        returns (bool success)
    {
        require(doApprove(msg.sender, _spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /**
     * @dev This function makes it easy to get the total number of tokens
     * @return The total number of tokens
     */
    function totalSupply() external view returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /**
     * @dev Queries the balance of `_owner` at a specific `_blockNumber`
     * @param _owner The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at `_blockNumber`
     */
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) 
        public
        view
        returns (uint) 
    {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /**
     * @notice Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     */
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Clone Token Method
////////////////

    /**
     * @notice Creates a new clone token with the initial distribution being
     *  this token at `_snapshotBlock`
     * @param _cloneTokenName Name of the clone token
     * @param _cloneDecimalUnits Number of decimals of the smallest unit
     * @param _cloneTokenSymbol Symbol of the clone token
     * @param _snapshotBlock Block when the distribution of the parent token is
     *  copied to set the initial distribution of the new clone token;
     *  if the block is zero than the actual block, the current block is used
     * @param _transfersEnabled True if transfers are allowed in the clone
     * @return The address of the new MiniMeToken Contract
     */
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) 
            public
            returns(address)
        {
        uint snapshotBlock = _snapshotBlock;
        if (snapshotBlock == 0) {
            snapshotBlock = block.number;
        }
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        emit NewCloneToken(address(cloneToken), snapshotBlock);
        return address(cloneToken);
    }

////////////////
// Generate and destroy tokens
////////////////
    
    /**
     * @notice Generates `_amount` tokens that are assigned to `_owner`
     * @param _owner The address that will be assigned the new tokens
     * @param _amount The quantity of tokens generated
     * @return True if the tokens are generated correctly
     */
    function generateTokens(
        address _owner,
        uint _amount
    )
        public
        onlyController
        returns (bool)
    {
        uint curTotalSupply = totalSupplyAt(block.number);
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOfAt(_owner, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }

    /**
     * @notice Burns `_amount` tokens from `_owner`
     * @param _owner The address that will lose the tokens
     * @param _amount The quantity of tokens to burn
     * @return True if the tokens are burned correctly
     */
    function destroyTokens(
        address _owner,
        uint _amount
    ) 
        public
        onlyController
        returns (bool)
    {
        uint curTotalSupply = totalSupplyAt(block.number);
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOfAt(_owner, block.number);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////

    /**
     * @notice Enables token holders to transfer their tokens freely if true
     * @param _transfersEnabled True if transfers are allowed in the clone
     */
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /**
     * @dev `getValueAt` retrieves the number of tokens at a given block number
     * @param checkpoints The history of values being queried
     * @param _block The block number to retrieve the value at
     * @return The number of tokens being queried
     */
    function getValueAt(
        Checkpoint[] storage checkpoints,
        uint _block
    ) 
        view
        internal
        returns (uint)
    {
        if (checkpoints.length == 0) {
            return 0;
        }

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /**
     * @dev `updateValueAtNow` used to update the `balances` map and the
     *  `totalSupplyHistory`
     * @param checkpoints The history of data being updated
     * @param _value The new number of tokens
     */
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if (
            (checkpoints.length == 0) ||
            (checkpoints[checkpoints.length - 1].fromBlock < block.number)) 
        {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    /**
     * @dev Internal function to determine if an address is a contract
     * @param _addr The address being queried
     * @return True if `_addr` is a contract
     */
    function isContract(address _addr) internal view returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }    
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @dev Helper function to return a min betwen the two uints
     */
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice The fallback function: If the contract&#39;s controller has not been
     *  set to 0, then the `proxyPayment` method is called which relays the
     *  ether and creates tokens as described in the token controller contract
     */
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

//////////
// Safety Methods
//////////

    /**
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(address(this).balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

}



contract PollManager is Controlled {

    struct Poll {
        uint startBlock;
        uint endBlock;
        bool canceled;
        uint voters;
        bytes description;
        uint8 numBallots;
        mapping(uint8 => mapping(address => uint)) ballots;
        mapping(uint8 => uint) qvResults;
        mapping(uint8 => uint) results;
        address author;
    }

    Poll[] _polls;

    MiniMeToken public token;

    RLPHelper public rlpHelper;

    /// @notice Contract constructor
    /// @param _token Address of the token used for governance
    constructor(address _token) 
        public {
        token = MiniMeToken(_token);
        rlpHelper = new RLPHelper();
    }

    /// @notice Only allow addresses that have > 0 SNT to perform an operation
    modifier onlySNTHolder {
        require(token.balanceOf(msg.sender) > 0, "SNT Balance is required to perform this operation"); 
        _; 
    }

    /// @notice Create a Poll and enable it immediatly
    /// @param _endBlock Block where the poll ends
    /// @param _description RLP encoded: [poll_title, [poll_ballots]]
    /// @param _numBallots Number of ballots
    function addPoll(
        uint _endBlock,
        bytes _description,
        uint8 _numBallots)
        public
        onlySNTHolder
        returns (uint _idPoll)
    {
        _idPoll = addPoll(block.number, _endBlock, _description, _numBallots);
    }

    /// @notice Create a Poll
    /// @param _startBlock Block where the poll starts
    /// @param _endBlock Block where the poll ends
    /// @param _description RLP encoded: [poll_title, [poll_ballots]]
    /// @param _numBallots Number of ballots
    function addPoll(
        uint _startBlock,
        uint _endBlock,
        bytes _description,
        uint8 _numBallots)
        public
        onlySNTHolder
        returns (uint _idPoll)
    {
        require(_endBlock > block.number, "End block must be greater than current block");
        require(_startBlock >= block.number && _startBlock < _endBlock, "Start block must not be in the past, and should be less than the end block" );
        require(_numBallots <= 15, "Only a max of 15 ballots are allowed");

        _idPoll = _polls.length;
        _polls.length ++;

        Poll storage p = _polls[_idPoll];
        p.startBlock = _startBlock;
        p.endBlock = _endBlock;
        p.voters = 0;
        p.numBallots = _numBallots;
        p.description = _description;
        p.author = msg.sender;

        emit PollCreated(_idPoll); 
    }

    /// @notice Update poll description (title or ballots) as long as it hasn&#39;t started
    /// @param _idPoll Poll to update
    /// @param _description RLP encoded: [poll_title, [poll_ballots]]
    /// @param _numBallots Number of ballots
    function updatePollDescription(
        uint _idPoll, 
        bytes _description,
        uint8 _numBallots)
        public
    {
        require(_idPoll < _polls.length, "Invalid _idPoll");
        require(_numBallots <= 15, "Only a max of 15 ballots are allowed");

        Poll storage p = _polls[_idPoll];
        require(p.startBlock > block.number, "You cannot modify an active poll");
        require(p.author == msg.sender || msg.sender == controller, "Only the owner/controller can modify the poll");

        p.numBallots = _numBallots;
        p.description = _description;
        p.author = msg.sender;
    }

    /// @notice Cancel an existing poll
    /// @dev Can only be done by the controller (which should be a Multisig/DAO) at any time, or by the owner if the poll hasn&#39;t started
    /// @param _idPoll Poll to cancel
    function cancelPoll(uint _idPoll) 
        public {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];
        
        require(!p.canceled, "Poll has been canceled already");
        require(p.endBlock > block.number, "Only active polls can be canceled");

        if(p.startBlock < block.number){
            require(msg.sender == controller, "Only the controller can cancel the poll");
        } else {
            require(p.author == msg.sender, "Only the owner can cancel the poll");
        }

        p.canceled = true;

        emit PollCanceled(_idPoll);
    }

    /// @notice Determine if user can bote for a poll
    /// @param _idPoll Id of the poll
    /// @return bool Can vote or not
    function canVote(uint _idPoll) 
        public 
        view 
        returns(bool)
    {
        if(_idPoll >= _polls.length) return false;

        Poll storage p = _polls[_idPoll];
        uint balance = token.balanceOfAt(msg.sender, p.startBlock);
        return block.number >= p.startBlock && block.number < p.endBlock && !p.canceled && balance != 0;
    }
    
    /// @notice Calculate square root of a uint (It has some precision loss)
    /// @param x Number to calculate the square root
    /// @return Square root of x
    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Vote for a poll
    /// @param _idPoll Poll to vote
    /// @param _ballots array of (number of ballots the poll has) elements, and their sum must be less or equal to the balance at the block start
    function vote(uint _idPoll, uint[] _ballots) public {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];

        require(block.number >= p.startBlock && block.number < p.endBlock && !p.canceled, "Poll is inactive");
        require(_ballots.length == p.numBallots, "Number of ballots is incorrect");

        unvote(_idPoll);

        uint amount = token.balanceOfAt(msg.sender, p.startBlock);
        require(amount != 0, "No SNT balance available at start block of poll");

        p.voters++;

        uint totalBallots = 0;
        for(uint8 i = 0; i < _ballots.length; i++){
            totalBallots += _ballots[i];

            p.ballots[i][msg.sender] = _ballots[i];

            if(_ballots[i] != 0){
                p.qvResults[i] += sqrt(_ballots[i] / 1 ether);
                p.results[i] += _ballots[i];
            }
        }

        require(totalBallots <= amount, "Total ballots must be less than the SNT balance at poll start block");

        emit Vote(_idPoll, msg.sender, _ballots);
    }

    /// @notice Cancel or reset a vote
    /// @param _idPoll Poll 
    function unvote(uint _idPoll) public {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];
        
        require(block.number >= p.startBlock && block.number < p.endBlock && !p.canceled, "Poll is inactive");

        if(p.voters == 0) return;

        p.voters--;

        for(uint8 i = 0; i < p.numBallots; i++){
            uint ballotAmount = p.ballots[i][msg.sender];

            p.ballots[i][msg.sender] = 0;

            if(ballotAmount != 0){
                p.qvResults[i] -= sqrt(ballotAmount / 1 ether);
                p.results[i] -= ballotAmount;
            }
        }

        emit Unvote(_idPoll, msg.sender);
    }

    // Constant Helper Function

    /// @notice Get number of polls
    /// @return Num of polls
    function nPolls()
        public
        view 
        returns(uint)
    {
        return _polls.length;
    }

    /// @notice Get Poll info
    /// @param _idPoll Poll 
    function poll(uint _idPoll)
        public 
        view 
        returns(
        uint _startBlock,
        uint _endBlock,
        bool _canVote,
        bool _canceled,
        bytes _description,
        uint8 _numBallots,
        bool _finalized,
        uint _voters,
        address _author,
        uint[15] _tokenTotal,
        uint[15] _quadraticVotes
    )
    {
        require(_idPoll < _polls.length, "Invalid _idPoll");

        Poll storage p = _polls[_idPoll];

        _startBlock = p.startBlock;
        _endBlock = p.endBlock;
        _canceled = p.canceled;
        _canVote = canVote(_idPoll);
        _description = p.description;
        _numBallots = p.numBallots;
        _author = p.author;
        _finalized = (!p.canceled) && (block.number >= _endBlock);
        _voters = p.voters;

        for(uint8 i = 0; i < p.numBallots; i++){
            _tokenTotal[i] = p.results[i];
            _quadraticVotes[i] = p.qvResults[i];
        }
    }

    /// @notice Decode poll title
    /// @param _idPoll Poll
    /// @return string with the poll title
    function pollTitle(uint _idPoll) public view returns (string){
        require(_idPoll < _polls.length, "Invalid _idPoll");
        Poll memory p = _polls[_idPoll];

        return rlpHelper.pollTitle(p.description);
    }

    /// @notice Decode poll ballot
    /// @param _idPoll Poll
    /// @param _ballot Index (0-based) of the ballot to decode
    /// @return string with the ballot text
    function pollBallot(uint _idPoll, uint _ballot) public view returns (string){
        require(_idPoll < _polls.length, "Invalid _idPoll");
        Poll memory p = _polls[_idPoll];

        return rlpHelper.pollBallot(p.description, _ballot);
    }

    /// @notice Get votes for poll/ballot
    /// @param _idPoll Poll
    /// @param _voter Address of the voter
    function getVote(uint _idPoll, address _voter) 
        public 
        view 
        returns (uint[15] votes){
        require(_idPoll < _polls.length, "Invalid _idPoll");
        Poll storage p = _polls[_idPoll];
        for(uint8 i = 0; i < p.numBallots; i++){
            votes[i] = p.ballots[i][_voter];
        }
        return votes;
    }

    event Vote(uint indexed idPoll, address indexed _voter, uint[] ballots);
    event Unvote(uint indexed idPoll, address indexed _voter);
    event PollCanceled(uint indexed idPoll);
    event PollCreated(uint indexed idPoll);
}