pragma solidity 0.4.24;


/**

COPYRIGHT 2018 Token, Inc.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


@title Ownable
@dev The Ownable contract has an owner address, and provides basic authorization control
functions, this simplifies the implementation of "user permissions".


 */
contract Ownable {

  mapping(address => bool) public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AllowOwnership(address indexed allowedAddress);
  event RevokeOwnership(address indexed allowedAddress);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner[msg.sender] = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner[msg.sender], "Error: Transaction sender is not allowed by the contract.");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   * @return {"success" : "Returns true when successfully transferred ownership"}
   */
  function transferOwnership(address newOwner) public onlyOwner returns (bool success) {
    require(newOwner != address(0), "Error: newOwner cannot be null!");
    emit OwnershipTransferred(msg.sender, newOwner);
    owner[newOwner] = true;
    owner[msg.sender] = false;
    return true;
  }

  /**
   * @dev Allows interface contracts and accounts to access contract methods (e.g. Storage contract)
   * @param allowedAddress The address of new owner
   * @return {"success" : "Returns true when successfully allowed ownership"}
   */
  function allowOwnership(address allowedAddress) public onlyOwner returns (bool success) {
    owner[allowedAddress] = true;
    emit AllowOwnership(allowedAddress);
    return true;
  }

  /**
   * @dev Disallows interface contracts and accounts to access contract methods (e.g. Storage contract)
   * @param allowedAddress The address to disallow ownership
   * @return {"success" : "Returns true when successfully allowed ownership"}
   */
  function removeOwnership(address allowedAddress) public onlyOwner returns (bool success) {
    owner[allowedAddress] = false;
    emit RevokeOwnership(allowedAddress);
    return true;
  }

}


/**

COPYRIGHT 2018 Token, Inc.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


@title TokenIOStorage - Serves as derived contract for TokenIO contract and
is used to upgrade interfaces in the event of deprecating the main contract.

@author Ryan Tate <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="89fbf0e8e7a7fde8fdecc9fde6e2ece7a7e0e6">[email&#160;protected]</a>>, Sean Pollock <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cebdabafa0e0bea1a2a2a1ada58ebaa1a5aba0e0a7a1">[email&#160;protected]</a>>

@notice Storage contract

@dev In the event that the main contract becomes deprecated, the upgraded contract
will be set as the owner of this contract, and use this contract&#39;s storage to
maintain data consistency between contract.

@notice NOTE: This contract is based on the RocketPool Storage Contract,
found here: https://github.com/rocket-pool/rocketpool/blob/master/contracts/RocketStorage.sol
And this medium article: https://medium.com/rocket-pool/upgradable-solidity-contract-design-54789205276d

Changes:
 - setting primitive mapping view to internal;
 - setting method views to public;

 @dev NOTE: When deprecating the main TokenIO contract, the upgraded contract
 must take ownership of the TokenIO contract, it will require using the public methods
 to update changes to the underlying data. The updated contract must use a
 standard call to original TokenIO contract such that the  request is made from
 the upgraded contract and not the transaction origin (tx.origin) of the signing
 account.


 @dev NOTE: The reasoning for using the storage contract is to abstract the interface
 from the data of the contract on chain, limiting the need to migrate data to
 new contracts.

*/
contract TokenIOStorage is Ownable {


    /// @dev mapping for Primitive Data Types;
		/// @notice primitive data mappings have `internal` view;
		/// @dev only the derived contract can use the internal methods;
		/// @dev key == `keccak256(param1, param2...)`
		/// @dev Nested mapping can be achieved using multiple params in keccak256 hash;
    mapping(bytes32 => uint256)    internal uIntStorage;
    mapping(bytes32 => string)     internal stringStorage;
    mapping(bytes32 => address)    internal addressStorage;
    mapping(bytes32 => bytes)      internal bytesStorage;
    mapping(bytes32 => bool)       internal boolStorage;
    mapping(bytes32 => int256)     internal intStorage;

    constructor() public {
				/// @notice owner is set to msg.sender by default
				/// @dev consider removing in favor of setting ownership in inherited
				/// contract
        owner[msg.sender] = true;
    }

    /// @dev Set Key Methods

    /**
     * @notice Set value for Address associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @param _value The Address value to be set
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function setAddress(bytes32 _key, address _value) public onlyOwner returns (bool success) {
        addressStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Set value for Uint associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @param _value The Uint value to be set
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function setUint(bytes32 _key, uint _value) public onlyOwner returns (bool success) {
        uIntStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Set value for String associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @param _value The String value to be set
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function setString(bytes32 _key, string _value) public onlyOwner returns (bool success) {
        stringStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Set value for Bytes associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @param _value The Bytes value to be set
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function setBytes(bytes32 _key, bytes _value) public onlyOwner returns (bool success) {
        bytesStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Set value for Bool associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @param _value The Bool value to be set
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function setBool(bytes32 _key, bool _value) public onlyOwner returns (bool success) {
        boolStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Set value for Int associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @param _value The Int value to be set
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function setInt(bytes32 _key, int _value) public onlyOwner returns (bool success) {
        intStorage[_key] = _value;
        return true;
    }

    /// @dev Delete Key Methods
		/// @dev delete methods may be unnecessary; Use set methods to set values
		/// to default?

    /**
     * @notice Delete value for Address associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function deleteAddress(bytes32 _key) public onlyOwner returns (bool success) {
        delete addressStorage[_key];
        return true;
    }

    /**
     * @notice Delete value for Uint associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function deleteUint(bytes32 _key) public onlyOwner returns (bool success) {
        delete uIntStorage[_key];
        return true;
    }

    /**
     * @notice Delete value for String associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function deleteString(bytes32 _key) public onlyOwner returns (bool success) {
        delete stringStorage[_key];
        return true;
    }

    /**
     * @notice Delete value for Bytes associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function deleteBytes(bytes32 _key) public onlyOwner returns (bool success) {
        delete bytesStorage[_key];
        return true;
    }

    /**
     * @notice Delete value for Bool associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function deleteBool(bytes32 _key) public onlyOwner returns (bool success) {
        delete boolStorage[_key];
        return true;
    }

    /**
     * @notice Delete value for Int associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "success" : "Returns true when successfully called from another contract" }
     */
    function deleteInt(bytes32 _key) public onlyOwner returns (bool success) {
        delete intStorage[_key];
        return true;
    }

    /// @dev Get Key Methods

    /**
     * @notice Get value for Address associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "_value" : "Returns the Address value associated with the id key" }
     */
    function getAddress(bytes32 _key) public view returns (address _value) {
        return addressStorage[_key];
    }

    /**
     * @notice Get value for Uint associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "_value" : "Returns the Uint value associated with the id key" }
     */
    function getUint(bytes32 _key) public view returns (uint _value) {
        return uIntStorage[_key];
    }

    /**
     * @notice Get value for String associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "_value" : "Returns the String value associated with the id key" }
     */
    function getString(bytes32 _key) public view returns (string _value) {
        return stringStorage[_key];
    }

    /**
     * @notice Get value for Bytes associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "_value" : "Returns the Bytes value associated with the id key" }
     */
    function getBytes(bytes32 _key) public view returns (bytes _value) {
        return bytesStorage[_key];
    }

    /**
     * @notice Get value for Bool associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "_value" : "Returns the Bool value associated with the id key" }
     */
    function getBool(bytes32 _key) public view returns (bool _value) {
        return boolStorage[_key];
    }

    /**
     * @notice Get value for Int associated with bytes32 id key
     * @param _key Pointer identifier for value in storage
     * @return { "_value" : "Returns the Int value associated with the id key" }
     */
    function getInt(bytes32 _key) public view returns (int _value) {
        return intStorage[_key];
    }

}