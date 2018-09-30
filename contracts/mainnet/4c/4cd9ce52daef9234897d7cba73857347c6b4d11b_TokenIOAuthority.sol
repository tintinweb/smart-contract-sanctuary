pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @notice Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @notice Multiplies two numbers, throws on overflow.
  * @param a Multiplier
  * @param b Multiplicand
  * @return {"result" : "Returns product"}
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "Error: Unsafe multiplication operation!");
    return c;
  }

  /**
  * @notice Integer division of two numbers, truncating the quotient.
  * @param a Dividend
  * @param b Divisor
  * @return {"result" : "Returns quotient"}
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // @dev require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // @dev require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @notice Subtracts two numbers, throws on underflow.
  * @param a Subtrahend
  * @param b Minuend
  * @return {"result" : "Returns difference"}
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // @dev throws on overflow (i.e. if subtrahend is greater than minuend)
    require(b <= a, "Error: Unsafe subtraction operation!");
    return a - b;
  }

  /**
  * @notice Adds two numbers, throws on overflow.
  * @param a First addend
  * @param b Second addend
  * @return {"result" : "Returns summation"}
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
    uint256 c = a + b;
    require(c >= a, "Error: Unsafe addition operation!");
    return c;
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

@author Ryan Tate <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b5c7ccd4db9bc1d4c1d0f5c1daded0db9bdcda">[email&#160;protected]</a>>, Sean Pollock <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f685939798d886999a9a99959db682999d9398d89f99">[email&#160;protected]</a>>

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


/**
COPYRIGHT 2018 Token, Inc.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


@title TokenIOLib

@author Ryan Tate <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5a28233b34742e3b2e3f1a2e35313f34743335">[email&#160;protected]</a>>, Sean Pollock <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0c7f696d62227c636060636f674c7863676962226563">[email&#160;protected]</a>>

@notice This library proxies the TokenIOStorage contract for the interface contract,
allowing the library and the interfaces to remain stateless, and share a universally
available storage contract between interfaces.


*/


library TokenIOLib {

  /// @dev all math operating are using SafeMath methods to check for overflow/underflows
  using SafeMath for uint;

  /// @dev the Data struct uses the Storage contract for stateful setters
  struct Data {
    TokenIOStorage Storage;
  }

  /// @notice Not using `Log` prefix for events to be consistent with ERC20 named events;
  event Approval(address indexed owner, address indexed spender, uint amount);
  event Deposit(string currency, address indexed account, uint amount, string issuerFirm);
  event Withdraw(string currency, address indexed account, uint amount, string issuerFirm);
  event Transfer(string currency, address indexed from, address indexed to, uint amount, bytes data);
  event KYCApproval(address indexed account, bool status, string issuerFirm);
  event AccountStatus(address indexed account, bool status, string issuerFirm);
  event FxSwap(string tokenASymbol,string tokenBSymbol,uint tokenAValue,uint tokenBValue, uint expiration, bytes32 transactionHash);
  event AccountForward(address indexed originalAccount, address indexed forwardedAccount);
  event NewAuthority(address indexed authority, string issuerFirm);

  /**
   * @notice Set the token name for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param tokenName Name of the token contract
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setTokenName(Data storage self, string tokenName) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.name&#39;, address(this)));
    require(
      self.Storage.setString(id, tokenName),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set the token symbol for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param tokenSymbol Symbol of the token contract
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setTokenSymbol(Data storage self, string tokenSymbol) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.symbol&#39;, address(this)));
    require(
      self.Storage.setString(id, tokenSymbol),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set the token three letter abreviation (TLA) for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param tokenTLA TLA of the token contract
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setTokenTLA(Data storage self, string tokenTLA) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.tla&#39;, address(this)));
    require(
      self.Storage.setString(id, tokenTLA),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set the token version for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param tokenVersion Semantic (vMAJOR.MINOR.PATCH | e.g. v0.1.0) version of the token contract
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setTokenVersion(Data storage self, string tokenVersion) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.version&#39;, address(this)));
    require(
      self.Storage.setString(id, tokenVersion),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set the token decimals for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @dev This method is not set to the address of the contract, rather is maped to currency
   * @dev To derive decimal value, divide amount by 10^decimal representation (e.g. 10132 / 10**2 == 101.32)
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param tokenDecimals Decimal representation of the token contract unit amount
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setTokenDecimals(Data storage self, string currency, uint tokenDecimals) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.decimals&#39;, currency));
    require(
      self.Storage.setUint(id, tokenDecimals),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set basis point fee for contract interface
   * @dev Transaction fees can be set by the TokenIOFeeContract
   * @dev Fees vary by contract interface specified `feeContract`
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param feeBPS Basis points fee for interface contract transactions
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setFeeBPS(Data storage self, uint feeBPS) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.bps&#39;, address(this)));
    require(
      self.Storage.setUint(id, feeBPS),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set minimum fee for contract interface
   * @dev Transaction fees can be set by the TokenIOFeeContract
   * @dev Fees vary by contract interface specified `feeContract`
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param feeMin Minimum fee for interface contract transactions
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setFeeMin(Data storage self, uint feeMin) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.min&#39;, address(this)));
    require(
      self.Storage.setUint(id, feeMin),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set maximum fee for contract interface
   * @dev Transaction fees can be set by the TokenIOFeeContract
   * @dev Fees vary by contract interface specified `feeContract`
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param feeMax Maximum fee for interface contract transactions
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setFeeMax(Data storage self, uint feeMax) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.max&#39;, address(this)));
    require(
      self.Storage.setUint(id, feeMax),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set flat fee for contract interface
   * @dev Transaction fees can be set by the TokenIOFeeContract
   * @dev Fees vary by contract interface specified `feeContract`
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param feeFlat Flat fee for interface contract transactions
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setFeeFlat(Data storage self, uint feeFlat) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.flat&#39;, address(this)));
    require(
      self.Storage.setUint(id, feeFlat),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set fee message for contract interface
   * @dev Default fee messages can be set by the TokenIOFeeContract (e.g. "tx_fees")
   * @dev Fee messages vary by contract interface specified `feeContract`
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param feeMsg Fee message included in a transaction with fees
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setFeeMsg(Data storage self, bytes feeMsg) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.msg&#39;, address(this)));
    require(
      self.Storage.setBytes(id, feeMsg),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set fee contract for a contract interface
   * @dev feeContract must be a TokenIOFeeContract storage approved contract
   * @dev Fees vary by contract interface specified `feeContract`
   * @dev | This method has an `internal` view
   * @dev | This must be called directly from the interface contract
   * @param self Internal storage proxying TokenIOStorage contract
   * @param feeContract Set the fee contract for `this` contract address interface
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setFeeContract(Data storage self, address feeContract) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.account&#39;, address(this)));
    require(
      self.Storage.setAddress(id, feeContract),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set contract interface associated with a given TokenIO currency symbol (e.g. USDx)
   * @dev | This should only be called once from a token interface contract;
   * @dev | This method has an `internal` view
   * @dev | This method is experimental and may be deprecated/refactored
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setTokenNameSpace(Data storage self, string currency) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.namespace&#39;, currency));
    require(
      self.Storage.setAddress(id, address(this)),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set the KYC approval status (true/false) for a given account
   * @dev | This method has an `internal` view
   * @dev | Every account must be KYC&#39;d to be able to use transfer() & transferFrom() methods
   * @dev | To gain approval for an account, register at https://tsm.token.io/sign-up
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder
   * @param isApproved Boolean (true/false) KYC approval status for a given account
   * @param issuerFirm Firm name for issuing KYC approval
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setKYCApproval(Data storage self, address account, bool isApproved, string issuerFirm) internal returns (bool success) {
      bytes32 id = keccak256(abi.encodePacked(&#39;account.kyc&#39;, getForwardedAccount(self, account)));
      require(
        self.Storage.setBool(id, isApproved),
        "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
      );

      /// @dev NOTE: Issuer is logged for setting account KYC status
      emit KYCApproval(account, isApproved, issuerFirm);
      return true;
  }

  /**
   * @notice Set the global approval status (true/false) for a given account
   * @dev | This method has an `internal` view
   * @dev | Every account must be permitted to be able to use transfer() & transferFrom() methods
   * @dev | To gain approval for an account, register at https://tsm.token.io/sign-up
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder
   * @param isAllowed Boolean (true/false) global status for a given account
   * @param issuerFirm Firm name for issuing approval
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setAccountStatus(Data storage self, address account, bool isAllowed, string issuerFirm) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;account.allowed&#39;, getForwardedAccount(self, account)));
    require(
      self.Storage.setBool(id, isAllowed),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );

    /// @dev NOTE: Issuer is logged for setting account status
    emit AccountStatus(account, isAllowed, issuerFirm);
    return true;
  }


  /**
   * @notice Set a forwarded address for an account.
   * @dev | This method has an `internal` view
   * @dev | Forwarded accounts must be set by an authority in case of account recovery;
   * @dev | Additionally, the original owner can set a forwarded account (e.g. add a new device, spouse, dependent, etc)
   * @dev | All transactions will be logged under the same KYC information as the original account holder;
   * @param self Internal storage proxying TokenIOStorage contract
   * @param originalAccount Original registered Ethereum address of the account holder
   * @param forwardedAccount Forwarded Ethereum address of the account holder
   * @return {"success" : "Returns true when successfully called from another contract"}
   */
  function setForwardedAccount(Data storage self, address originalAccount, address forwardedAccount) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;master.account&#39;, forwardedAccount));
    require(
      self.Storage.setAddress(id, originalAccount),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Get the original address for a forwarded account
   * @dev | This method has an `internal` view
   * @dev | Will return the registered account for the given forwarded account
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder
   * @return { "registeredAccount" : "Will return the original account of a forwarded account or the account itself if no account found"}
   */
  function getForwardedAccount(Data storage self, address account) internal view returns (address registeredAccount) {
    bytes32 id = keccak256(abi.encodePacked(&#39;master.account&#39;, account));
    address originalAccount = self.Storage.getAddress(id);
    if (originalAccount != 0x0) {
      return originalAccount;
    } else {
      return account;
    }
  }

  /**
   * @notice Get KYC approval status for the account holder
   * @dev | This method has an `internal` view
   * @dev | All forwarded accounts will use the original account&#39;s status
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder
   * @return { "status" : "Returns the KYC approval status for an account holder" }
   */
  function getKYCApproval(Data storage self, address account) internal view returns (bool status) {
      bytes32 id = keccak256(abi.encodePacked(&#39;account.kyc&#39;, getForwardedAccount(self, account)));
      return self.Storage.getBool(id);
  }

  /**
   * @notice Get global approval status for the account holder
   * @dev | This method has an `internal` view
   * @dev | All forwarded accounts will use the original account&#39;s status
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder
   * @return { "status" : "Returns the global approval status for an account holder" }
   */
  function getAccountStatus(Data storage self, address account) internal view returns (bool status) {
    bytes32 id = keccak256(abi.encodePacked(&#39;account.allowed&#39;, getForwardedAccount(self, account)));
    return self.Storage.getBool(id);
  }

  /**
   * @notice Get the contract interface address associated with token symbol
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @return { "contractAddress" : "Returns the contract interface address for a symbol" }
   */
  function getTokenNameSpace(Data storage self, string currency) internal view returns (address contractAddress) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.namespace&#39;, currency));
    return self.Storage.getAddress(id);
  }

  /**
   * @notice Get the token name for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return {"tokenName" : "Name of the token contract"}
   */
  function getTokenName(Data storage self, address contractAddress) internal view returns (string tokenName) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.name&#39;, contractAddress));
    return self.Storage.getString(id);
  }

  /**
   * @notice Get the token symbol for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return {"tokenSymbol" : "Symbol of the token contract"}
   */
  function getTokenSymbol(Data storage self, address contractAddress) internal view returns (string tokenSymbol) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.symbol&#39;, contractAddress));
    return self.Storage.getString(id);
  }

  /**
   * @notice Get the token Three letter abbreviation (TLA) for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return {"tokenTLA" : "TLA of the token contract"}
   */
  function getTokenTLA(Data storage self, address contractAddress) internal view returns (string tokenTLA) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.tla&#39;, contractAddress));
    return self.Storage.getString(id);
  }

  /**
   * @notice Get the token version for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return {"tokenVersion" : "Semantic version of the token contract"}
   */
  function getTokenVersion(Data storage self, address contractAddress) internal view returns (string) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.version&#39;, contractAddress));
    return self.Storage.getString(id);
  }

  /**
   * @notice Get the token decimals for Token interfaces
   * @dev This method must be set by the token interface&#39;s setParams() method
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @return {"tokenDecimals" : "Decimals of the token contract"}
   */
  function getTokenDecimals(Data storage self, string currency) internal view returns (uint tokenDecimals) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.decimals&#39;, currency));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the basis points fee of the contract address; typically TokenIOFeeContract
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "feeBps" : "Returns the basis points fees associated with the contract address"}
   */
  function getFeeBPS(Data storage self, address contractAddress) internal view returns (uint feeBps) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.bps&#39;, contractAddress));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the minimum fee of the contract address; typically TokenIOFeeContract
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "feeMin" : "Returns the minimum fees associated with the contract address"}
   */
  function getFeeMin(Data storage self, address contractAddress) internal view returns (uint feeMin) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.min&#39;, contractAddress));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the maximum fee of the contract address; typically TokenIOFeeContract
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "feeMax" : "Returns the maximum fees associated with the contract address"}
   */
  function getFeeMax(Data storage self, address contractAddress) internal view returns (uint feeMax) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.max&#39;, contractAddress));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the flat fee of the contract address; typically TokenIOFeeContract
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "feeFlat" : "Returns the flat fees associated with the contract address"}
   */
  function getFeeFlat(Data storage self, address contractAddress) internal view returns (uint feeFlat) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.flat&#39;, contractAddress));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the flat message of the contract address; typically TokenIOFeeContract
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "feeMsg" : "Returns the fee message (bytes) associated with the contract address"}
   */
  function getFeeMsg(Data storage self, address contractAddress) internal view returns (bytes feeMsg) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.msg&#39;, contractAddress));
    return self.Storage.getBytes(id);
  }

  /**
   * @notice Set the master fee contract used as the default fee contract when none is provided
   * @dev | This method has an `internal` view
   * @dev | This value is set in the TokenIOAuthority contract
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "success" : "Returns true when successfully called from another contract"}
   */
  function setMasterFeeContract(Data storage self, address contractAddress) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.contract.master&#39;));
    require(
      self.Storage.setAddress(id, contractAddress),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Get the master fee contract set via the TokenIOAuthority contract
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @return { "masterFeeContract" : "Returns the master fee contract set for TSM."}
   */
  function getMasterFeeContract(Data storage self) internal view returns (address masterFeeContract) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.contract.master&#39;));
    return self.Storage.getAddress(id);
  }

  /**
   * @notice Get the fee contract set for a contract interface
   * @dev | This method has an `internal` view
   * @dev | Custom fee pricing can be set by assigning a fee contract to transactional contract interfaces
   * @dev | If a fee contract has not been set by an interface contract, then the master fee contract will be returned
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the queryable interface
   * @return { "feeContract" : "Returns the fee contract associated with a contract interface"}
   */
  function getFeeContract(Data storage self, address contractAddress) internal view returns (address feeContract) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fee.account&#39;, contractAddress));

    address feeAccount = self.Storage.getAddress(id);
    if (feeAccount == 0x0) {
      return getMasterFeeContract(self);
    } else {
      return feeAccount;
    }
  }

  /**
   * @notice Get the token supply for a given TokenIO TSM currency symbol (e.g. USDx)
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @return { "supply" : "Returns the token supply of the given currency"}
   */
  function getTokenSupply(Data storage self, string currency) internal view returns (uint supply) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.supply&#39;, currency));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the token spender allowance for a given account
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder
   * @param spender Ethereum address of spender
   * @return { "allowance" : "Returns the allowance of a given spender for a given account"}
   */
  function getTokenAllowance(Data storage self, string currency, address account, address spender) internal view returns (uint allowance) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.allowance&#39;, currency, getForwardedAccount(self, account), getForwardedAccount(self, spender)));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the token balance for a given account
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param account Ethereum address of account holder
   * @return { "balance" : "Return the balance of a given account for a specified currency"}
   */
  function getTokenBalance(Data storage self, string currency, address account) internal view returns (uint balance) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.balance&#39;, currency, getForwardedAccount(self, account)));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Get the frozen token balance for a given account
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param account Ethereum address of account holder
   * @return { "frozenBalance" : "Return the frozen balance of a given account for a specified currency"}
   */
  function getTokenFrozenBalance(Data storage self, string currency, address account) internal view returns (uint frozenBalance) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.frozen&#39;, currency, getForwardedAccount(self, account)));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Set the frozen token balance for a given account
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param account Ethereum address of account holder
   * @param amount Amount of tokens to freeze for account
   * @return { "success" : "Return true if successfully called from another contract"}
   */
  function setTokenFrozenBalance(Data storage self, string currency, address account, uint amount) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.frozen&#39;, currency, getForwardedAccount(self, account)));
    require(
      self.Storage.setUint(id, amount),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

  /**
   * @notice Set the frozen token balance for a given account
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Contract address of the fee contract
   * @param amount Transaction value
   * @return { "calculatedFees" : "Return the calculated transaction fees for a given amount and fee contract" }
   */
  function calculateFees(Data storage self, address contractAddress, uint amount) internal view returns (uint calculatedFees) {

    uint maxFee = self.Storage.getUint(keccak256(abi.encodePacked(&#39;fee.max&#39;, contractAddress)));
    uint minFee = self.Storage.getUint(keccak256(abi.encodePacked(&#39;fee.min&#39;, contractAddress)));
    uint bpsFee = self.Storage.getUint(keccak256(abi.encodePacked(&#39;fee.bps&#39;, contractAddress)));
    uint flatFee = self.Storage.getUint(keccak256(abi.encodePacked(&#39;fee.flat&#39;, contractAddress)));
    uint fees = ((amount.mul(bpsFee)).div(10000)).add(flatFee);

    if (fees > maxFee) {
      return maxFee;
    } else if (fees < minFee) {
      return minFee;
    } else {
      return fees;
    }
  }

  /**
   * @notice Verified KYC and global status for two accounts and return true or throw if either account is not verified
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param accountA Ethereum address of first account holder to verify
   * @param accountB Ethereum address of second account holder to verify
   * @return { "verified" : "Returns true if both accounts are successfully verified" }
   */
  function verifyAccounts(Data storage self, address accountA, address accountB) internal view returns (bool verified) {
    require(
      verifyAccount(self, accountA),
      "Error: Account is not verified for operation. Please ensure account has been KYC approved."
    );
    require(
      verifyAccount(self, accountB),
      "Error: Account is not verified for operation. Please ensure account has been KYC approved."
    );
    return true;
  }

  /**
   * @notice Verified KYC and global status for a single account and return true or throw if account is not verified
   * @dev | This method has an `internal` view
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of account holder to verify
   * @return { "verified" : "Returns true if account is successfully verified" }
   */
  function verifyAccount(Data storage self, address account) internal view returns (bool verified) {
    require(
      getKYCApproval(self, account),
      "Error: Account does not have KYC approval."
    );
    require(
      getAccountStatus(self, account),
      "Error: Account status is `false`. Account status must be `true`."
    );
    return true;
  }


  /**
   * @notice Transfer an amount of currency token from msg.sender account to another specified account
   * @dev This function is called by an interface that is accessible directly to the account holder
   * @dev | This method has an `internal` view
   * @dev | This method uses `forceTransfer()` low-level api
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param to Ethereum address of account to send currency amount to
   * @param amount Value of currency to transfer
   * @param data Arbitrary bytes data to include with the transaction
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function transfer(Data storage self, string currency, address to, uint amount, bytes data) internal returns (bool success) {
    require(address(to) != 0x0, "Error: `to` address cannot be null." );
    require(amount > 0, "Error: `amount` must be greater than zero");

    address feeContract = getFeeContract(self, address(this));
    uint fees = calculateFees(self, feeContract, amount);

    require(
      setAccountSpendingAmount(self, msg.sender, getFxUSDAmount(self, currency, amount)),
      "Error: Unable to set spending amount for account.");

    require(
      forceTransfer(self, currency, msg.sender, to, amount, data),
      "Error: Unable to transfer funds to account.");

    // @dev transfer fees to fee contract
    require(
      forceTransfer(self, currency, msg.sender, feeContract, fees, getFeeMsg(self, feeContract)),
      "Error: Unable to transfer fees to fee contract.");

    return true;
  }

  /**
   * @notice Transfer an amount of currency token from account to another specified account via an approved spender account
   * @dev This function is called by an interface that is accessible directly to the account spender
   * @dev | This method has an `internal` view
   * @dev | Transactions will fail if the spending amount exceeds the daily limit
   * @dev | This method uses `forceTransfer()` low-level api
   * @dev | This method implements ERC20 transferFrom() method with approved spender behavior
   * @dev | msg.sender == spender; `updateAllowance()` reduces approved limit for account spender
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param from Ethereum address of account to send currency amount from
   * @param to Ethereum address of account to send currency amount to
   * @param amount Value of currency to transfer
   * @param data Arbitrary bytes data to include with the transaction
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function transferFrom(Data storage self, string currency, address from, address to, uint amount, bytes data) internal returns (bool success) {
    require(
      address(to) != 0x0,
      "Error: `to` address must not be null."
    );

    address feeContract = getFeeContract(self, address(this));
    uint fees = calculateFees(self, feeContract, amount);

    /// @dev NOTE: This transaction will fail if the spending amount exceeds the daily limit
    require(
      setAccountSpendingAmount(self, from, getFxUSDAmount(self, currency, amount)),
      "Error: Unable to set account spending amount."
    );

    /// @dev Attempt to transfer the amount
    require(
      forceTransfer(self, currency, from, to, amount, data),
      "Error: Unable to transfer funds to account."
    );

    // @dev transfer fees to fee contract
    require(
      forceTransfer(self, currency, from, feeContract, fees, getFeeMsg(self, feeContract)),
      "Error: Unable to transfer fees to fee contract."
    );

    /// @dev Attempt to update the spender allowance
    require(
      updateAllowance(self, currency, from, amount),
      "Error: Unable to update allowance for spender."
    );

    return true;
  }

  /**
   * @notice Low-level transfer method
   * @dev | This method has an `internal` view
   * @dev | This method does not include fees or approved allowances.
   * @dev | This method is only for authorized interfaces to use (e.g. TokenIOFX)
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param from Ethereum address of account to send currency amount from
   * @param to Ethereum address of account to send currency amount to
   * @param amount Value of currency to transfer
   * @param data Arbitrary bytes data to include with the transaction
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function forceTransfer(Data storage self, string currency, address from, address to, uint amount, bytes data) internal returns (bool success) {
    require(
      address(to) != 0x0,
      "Error: `to` address must not be null."
    );

    bytes32 id_a = keccak256(abi.encodePacked(&#39;token.balance&#39;, currency, getForwardedAccount(self, from)));
    bytes32 id_b = keccak256(abi.encodePacked(&#39;token.balance&#39;, currency, getForwardedAccount(self, to)));

    require(
      self.Storage.setUint(id_a, self.Storage.getUint(id_a).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );
    require(
      self.Storage.setUint(id_b, self.Storage.getUint(id_b).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );

    emit Transfer(currency, from, to, amount, data);

    return true;
  }

  /**
   * @notice Low-level method to update spender allowance for account
   * @dev | This method is called inside the `transferFrom()` method
   * @dev | msg.sender == spender address
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param account Ethereum address of account holder
   * @param amount Value to reduce allowance by (i.e. the amount spent)
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function updateAllowance(Data storage self, string currency, address account, uint amount) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;token.allowance&#39;, currency, getForwardedAccount(self, account), getForwardedAccount(self, msg.sender)));
    require(
      self.Storage.setUint(id, self.Storage.getUint(id).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );
    return true;
  }

  /**
   * @notice Low-level method to set the allowance for a spender
   * @dev | This method is called inside the `approve()` ERC20 method
   * @dev | msg.sender == account holder
   * @param self Internal storage proxying TokenIOStorage contract
   * @param spender Ethereum address of account spender
   * @param amount Value to set for spender allowance
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function approveAllowance(Data storage self, address spender, uint amount) internal returns (bool success) {
    require(spender != 0x0,
        "Error: `spender` address cannot be null.");

    string memory currency = getTokenSymbol(self, address(this));

    require(
      getTokenFrozenBalance(self, currency, getForwardedAccount(self, spender)) == 0,
      "Error: Spender must not have a frozen balance directly");

    bytes32 id_a = keccak256(abi.encodePacked(&#39;token.allowance&#39;, currency, getForwardedAccount(self, msg.sender), getForwardedAccount(self, spender)));
    bytes32 id_b = keccak256(abi.encodePacked(&#39;token.balance&#39;, currency, getForwardedAccount(self, msg.sender)));

    require(
      self.Storage.getUint(id_a) == 0 || amount == 0,
      "Error: Allowance must be zero (0) before setting an updated allowance for spender.");

    require(
      self.Storage.getUint(id_b) >= amount,
      "Error: Allowance cannot exceed msg.sender token balance.");

    require(
      self.Storage.setUint(id_a, amount),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  /**
   * @notice Deposit an amount of currency into the Ethereum account holder
   * @dev | The total supply of the token increases only when new funds are deposited 1:1
   * @dev | This method should only be called by authorized issuer firms
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param account Ethereum address of account holder to deposit funds for
   * @param amount Value of currency to deposit for account
   * @param issuerFirm Name of the issuing firm authorizing the deposit
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function deposit(Data storage self, string currency, address account, uint amount, string issuerFirm) internal returns (bool success) {
    bytes32 id_a = keccak256(abi.encodePacked(&#39;token.balance&#39;, currency, getForwardedAccount(self, account)));
    bytes32 id_b = keccak256(abi.encodePacked(&#39;token.issued&#39;, currency, issuerFirm));
    bytes32 id_c = keccak256(abi.encodePacked(&#39;token.supply&#39;, currency));


    require(self.Storage.setUint(id_a, self.Storage.getUint(id_a).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(self.Storage.setUint(id_b, self.Storage.getUint(id_b).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(self.Storage.setUint(id_c, self.Storage.getUint(id_c).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    emit Deposit(currency, account, amount, issuerFirm);

    return true;

  }

  /**
   * @notice Withdraw an amount of currency from the Ethereum account holder
   * @dev | The total supply of the token decreases only when new funds are withdrawn 1:1
   * @dev | This method should only be called by authorized issuer firms
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  currency Currency symbol of the token (e.g. USDx, JYPx, GBPx)
   * @param account Ethereum address of account holder to deposit funds for
   * @param amount Value of currency to withdraw for account
   * @param issuerFirm Name of the issuing firm authorizing the withdraw
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function withdraw(Data storage self, string currency, address account, uint amount, string issuerFirm) internal returns (bool success) {
    bytes32 id_a = keccak256(abi.encodePacked(&#39;token.balance&#39;, currency, getForwardedAccount(self, account)));
    bytes32 id_b = keccak256(abi.encodePacked(&#39;token.issued&#39;, currency, issuerFirm)); // possible for issuer to go negative
    bytes32 id_c = keccak256(abi.encodePacked(&#39;token.supply&#39;, currency));

    require(
      self.Storage.setUint(id_a, self.Storage.getUint(id_a).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(
      self.Storage.setUint(id_b, self.Storage.getUint(id_b).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(
      self.Storage.setUint(id_c, self.Storage.getUint(id_c).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    emit Withdraw(currency, account, amount, issuerFirm);

    return true;

  }

  /**
   * @notice Method for setting a registered issuer firm
   * @dev | Only Token, Inc. and other authorized institutions may set a registered firm
   * @dev | The TokenIOAuthority.sol interface wraps this method
   * @dev | If the registered firm is unapproved; all authorized addresses of that firm will also be unapproved
   * @param self Internal storage proxying TokenIOStorage contract
   * @param issuerFirm Name of the firm to be registered
   * @param approved Approval status to set for the firm (true/false)
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function setRegisteredFirm(Data storage self, string issuerFirm, bool approved) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;registered.firm&#39;, issuerFirm));
    require(
      self.Storage.setBool(id, approved),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );
    return true;
  }

  /**
   * @notice Method for setting a registered issuer firm authority
   * @dev | Only Token, Inc. and other approved institutions may set a registered firm
   * @dev | The TokenIOAuthority.sol interface wraps this method
   * @dev | Authority can only be set for a registered issuer firm
   * @param self Internal storage proxying TokenIOStorage contract
   * @param issuerFirm Name of the firm to be registered to authority
   * @param authorityAddress Ethereum address of the firm authority to be approved
   * @param approved Approval status to set for the firm authority (true/false)
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function setRegisteredAuthority(Data storage self, string issuerFirm, address authorityAddress, bool approved) internal returns (bool success) {
    require(
      isRegisteredFirm(self, issuerFirm),
      "Error: `issuerFirm` must be registered.");

    bytes32 id_a = keccak256(abi.encodePacked(&#39;registered.authority&#39;, issuerFirm, authorityAddress));
    bytes32 id_b = keccak256(abi.encodePacked(&#39;registered.authority.firm&#39;, authorityAddress));

    require(
      self.Storage.setBool(id_a, approved),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    require(
      self.Storage.setString(id_b, issuerFirm),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");


    return true;
  }

  /**
   * @notice Get the issuer firm registered to the authority Ethereum address
   * @dev | Only one firm can be registered per authority
   * @param self Internal storage proxying TokenIOStorage contract
   * @param authorityAddress Ethereum address of the firm authority to query
   * @return { "issuerFirm" : "Name of the firm registered to authority" }
   */
  function getFirmFromAuthority(Data storage self, address authorityAddress) internal view returns (string issuerFirm) {
    bytes32 id = keccak256(abi.encodePacked(&#39;registered.authority.firm&#39;, getForwardedAccount(self, authorityAddress)));
    return self.Storage.getString(id);
  }

  /**
   * @notice Return the boolean (true/false) registration status for an issuer firm
   * @param self Internal storage proxying TokenIOStorage contract
   * @param issuerFirm Name of the issuer firm
   * @return { "registered" : "Return if the issuer firm has been registered" }
   */
  function isRegisteredFirm(Data storage self, string issuerFirm) internal view returns (bool registered) {
    bytes32 id = keccak256(abi.encodePacked(&#39;registered.firm&#39;, issuerFirm));
    return self.Storage.getBool(id);
  }

  /**
   * @notice Return the boolean (true/false) status if an authority is registered to an issuer firm
   * @param self Internal storage proxying TokenIOStorage contract
   * @param issuerFirm Name of the issuer firm
   * @param authorityAddress Ethereum address of the firm authority to query
   * @return { "registered" : "Return if the authority is registered with the issuer firm" }
   */
  function isRegisteredToFirm(Data storage self, string issuerFirm, address authorityAddress) internal view returns (bool registered) {
    bytes32 id = keccak256(abi.encodePacked(&#39;registered.authority&#39;, issuerFirm, getForwardedAccount(self, authorityAddress)));
    return self.Storage.getBool(id);
  }

  /**
   * @notice Return if an authority address is registered
   * @dev | This also checks the status of the registered issuer firm
   * @param self Internal storage proxying TokenIOStorage contract
   * @param authorityAddress Ethereum address of the firm authority to query
   * @return { "registered" : "Return if the authority is registered" }
   */
  function isRegisteredAuthority(Data storage self, address authorityAddress) internal view returns (bool registered) {
    bytes32 id = keccak256(abi.encodePacked(&#39;registered.authority&#39;, getFirmFromAuthority(self, getForwardedAccount(self, authorityAddress)), getForwardedAccount(self, authorityAddress)));
    return self.Storage.getBool(id);
  }

  /**
   * @notice Return boolean transaction status if the transaction has been used
   * @param self Internal storage proxying TokenIOStorage contract
   * @param txHash keccak256 ABI tightly packed encoded hash digest of tx params
   * @return {"txStatus": "Returns true if the tx hash has already been set using `setTxStatus()` method"}
   */
  function getTxStatus(Data storage self, bytes32 txHash) internal view returns (bool txStatus) {
    bytes32 id = keccak256(abi.encodePacked(&#39;tx.status&#39;, txHash));
    return self.Storage.getBool(id);
  }

  /**
   * @notice Set transaction status if the transaction has been used
   * @param self Internal storage proxying TokenIOStorage contract
   * @param txHash keccak256 ABI tightly packed encoded hash digest of tx params
   * @return { "success" : "Return true if successfully called from another contract" }
   */
  function setTxStatus(Data storage self, bytes32 txHash) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;tx.status&#39;, txHash));
    /// @dev Ensure transaction has not yet been used;
    require(!getTxStatus(self, txHash),
      "Error: Transaction status must be false before setting the transaction status.");

    /// @dev Update the status of the transaction;
    require(self.Storage.setBool(id, true),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    return true;
  }

  /**
   * @notice Accepts a signed fx request to swap currency pairs at a given amount;
   * @dev | This method can be called directly between peers
   * @dev | This method does not take transaction fees from the swap
   * @param self Internal storage proxying TokenIOStorage contract
   * @param  requester address Requester is the orginator of the offer and must
   * match the signature of the payload submitted by the fulfiller
   * @param  symbolA    Symbol of the currency desired
   * @param  symbolB    Symbol of the currency offered
   * @param  valueA     Amount of the currency desired
   * @param  valueB     Amount of the currency offered
   * @param  sigV       Ethereum secp256k1 signature V value; used by ecrecover()
   * @param  sigR       Ethereum secp256k1 signature R value; used by ecrecover()
   * @param  sigS       Ethereum secp256k1 signature S value; used by ecrecover()
   * @param  expiration Expiration of the offer; Offer is good until expired
   * @return {"success" : "Returns true if successfully called from another contract"}
   */
  function execSwap(
    Data storage self,
    address requester,
    string symbolA,
    string symbolB,
    uint valueA,
    uint valueB,
    uint8 sigV,
    bytes32 sigR,
    bytes32 sigS,
    uint expiration
  ) internal returns (bool success) {

    bytes32 fxTxHash = keccak256(abi.encodePacked(requester, symbolA, symbolB, valueA, valueB, expiration));

    /// @notice check that sender and requester accounts are verified
    /// @notice Only verified accounts can perform currency swaps
    require(
      verifyAccounts(self, msg.sender, requester),
      "Error: Only verified accounts can perform currency swaps.");

    /// @dev Immediately set this transaction to be confirmed before updating any params;
    require(
      setTxStatus(self, fxTxHash),
      "Error: Failed to set transaction status to fulfilled.");

    /// @dev Ensure contract has not yet expired;
    require(expiration >= now, "Error: Transaction has expired!");

    /// @dev Recover the address of the signature from the hashed digest;
    /// @dev Ensure it equals the requester&#39;s address
    require(
      ecrecover(fxTxHash, sigV, sigR, sigS) == requester,
      "Error: Address derived from transaction signature does not match the requester address");

    /// @dev Transfer funds from each account to another.
    require(
      forceTransfer(self, symbolA, msg.sender, requester, valueA, "0x0"),
      "Error: Unable to transfer funds to account.");

    require(
      forceTransfer(self, symbolB, requester, msg.sender, valueB, "0x0"),
      "Error: Unable to transfer funds to account.");

    emit FxSwap(symbolA, symbolB, valueA, valueB, expiration, fxTxHash);

    return true;
  }

  /**
   * @notice Deprecate a contract interface
   * @dev | This is a low-level method to deprecate a contract interface.
   * @dev | This is useful if the interface needs to be updated or becomes out of date
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Ethereum address of the contract interface
   * @return {"success" : "Returns true if successfully called from another contract"}
   */
  function setDeprecatedContract(Data storage self, address contractAddress) internal returns (bool success) {
    require(contractAddress != 0x0,
        "Error: cannot deprecate a null address.");

    bytes32 id = keccak256(abi.encodePacked(&#39;depcrecated&#39;, contractAddress));

    require(self.Storage.setBool(id, true),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

  /**
   * @notice Return the deprecation status of a contract
   * @param self Internal storage proxying TokenIOStorage contract
   * @param contractAddress Ethereum address of the contract interface
   * @return {"status" : "Return deprecation status (true/false) of the contract interface"}
   */
  function isContractDeprecated(Data storage self, address contractAddress) internal view returns (bool status) {
    bytes32 id = keccak256(abi.encodePacked(&#39;depcrecated&#39;, contractAddress));
    return self.Storage.getBool(id);
  }

  /**
   * @notice Set the Account Spending Period Limit as UNIX timestamp
   * @dev | Each account has it&#39;s own daily spending limit
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @param period Unix timestamp of the spending period
   * @return {"success" : "Returns true is successfully called from a contract"}
   */
  function setAccountSpendingPeriod(Data storage self, address account, uint period) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;limit.spending.period&#39;, account));
    require(self.Storage.setUint(id, period),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

  /**
   * @notice Get the Account Spending Period Limit as UNIX timestamp
   * @dev | Each account has it&#39;s own daily spending limit
   * @dev | If the current spending period has expired, it will be set upon next `transfer()`
   * or `transferFrom()` request
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @return {"period" : "Returns Unix timestamp of the current spending period"}
   */
  function getAccountSpendingPeriod(Data storage self, address account) internal view returns (uint period) {
    bytes32 id = keccak256(abi.encodePacked(&#39;limit.spending.period&#39;, account));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Set the account spending limit amount
   * @dev | Each account has it&#39;s own daily spending limit
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @param limit Spending limit amount
   * @return {"success" : "Returns true is successfully called from a contract"}
   */
  function setAccountSpendingLimit(Data storage self, address account, uint limit) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;account.spending.limit&#39;, account));
    require(self.Storage.setUint(id, limit),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

  /**
   * @notice Get the account spending limit amount
   * @dev | Each account has it&#39;s own daily spending limit
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @return {"limit" : "Returns the account spending limit amount"}
   */
  function getAccountSpendingLimit(Data storage self, address account) internal view returns (uint limit) {
    bytes32 id = keccak256(abi.encodePacked(&#39;account.spending.limit&#39;, account));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Set the account spending amount for the daily period
   * @dev | Each account has it&#39;s own daily spending limit
   * @dev | This transaction will throw if the new spending amount is greater than the limit
   * @dev | This method is called in the `transfer()` and `transferFrom()` methods
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @param amount Set the amount spent for the daily period
   * @return {"success" : "Returns true is successfully called from a contract"}
   */
  function setAccountSpendingAmount(Data storage self, address account, uint amount) internal returns (bool success) {

    /// @dev NOTE: Always ensure the period is current when checking the daily spend limit
    require(updateAccountSpendingPeriod(self, account),
      "Error: Unable to update account spending period.");

    uint updatedAmount = getAccountSpendingAmount(self, account).add(amount);

    /// @dev Ensure the spend limit is greater than the amount spend for the period
    require(
      getAccountSpendingLimit(self, account) >= updatedAmount,
      "Error: Account cannot exceed its daily spend limit.");

    /// @dev Update the spending period amount if within limit
    bytes32 id = keccak256(abi.encodePacked(&#39;account.spending.amount&#39;, account, getAccountSpendingPeriod(self, account)));
    require(self.Storage.setUint(id, updatedAmount),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

  /**
   * @notice Low-level API to ensure the account spending period is always current
   * @dev | This method is internally called by `setAccountSpendingAmount()` to ensure
   * spending period is always the most current daily period.
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @return {"success" : "Returns true is successfully called from a contract"}
   */
  function updateAccountSpendingPeriod(Data storage self, address account) internal returns (bool success) {
    uint begDate = getAccountSpendingPeriod(self, account);
    if (begDate > now) {
      return true;
    } else {
      uint duration = 86400; // 86400 seconds in a day
      require(
        setAccountSpendingPeriod(self, account, begDate.add(((now.sub(begDate)).div(duration).add(1)).mul(duration))),
        "Error: Unable to update account spending period.");

      return true;
    }
  }

  /**
   * @notice Return the amount spent during the current period
   * @dev | Each account has it&#39;s own daily spending limit
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @return {"amount" : "Returns the amount spent by the account during the current period"}
   */
  function getAccountSpendingAmount(Data storage self, address account) internal view returns (uint amount) {
    bytes32 id = keccak256(abi.encodePacked(&#39;account.spending.amount&#39;, account, getAccountSpendingPeriod(self, account)));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Return the amount remaining during the current period
   * @dev | Each account has it&#39;s own daily spending limit
   * @param self Internal storage proxying TokenIOStorage contract
   * @param account Ethereum address of the account holder
   * @return {"amount" : "Returns the amount remaining by the account during the current period"}
   */
  function getAccountSpendingRemaining(Data storage self, address account) internal view returns (uint remainingLimit) {
    return getAccountSpendingLimit(self, account).sub(getAccountSpendingAmount(self, account));
  }

  /**
   * @notice Set the foreign currency exchange rate to USD in basis points
   * @dev | This value should always be relative to USD pair; e.g. JPY/USD, GBP/USD, etc.
   * @param self Internal storage proxying TokenIOStorage contract
   * @param currency The TokenIO currency symbol (e.g. USDx, JPYx, GBPx)
   * @param bpsRate Basis point rate of foreign currency exchange rate to USD
   * @return { "success": "Returns true if successfully called from another contract"}
   */
  function setFxUSDBPSRate(Data storage self, string currency, uint bpsRate) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fx.usd.rate&#39;, currency));
    require(
      self.Storage.setUint(id, bpsRate),
      "Error: Unable to update account spending period.");

    return true;
  }

  /**
   * @notice Return the foreign currency USD exchanged amount in basis points
   * @param self Internal storage proxying TokenIOStorage contract
   * @param currency The TokenIO currency symbol (e.g. USDx, JPYx, GBPx)
   * @return {"usdAmount" : "Returns the foreign currency amount in USD"}
   */
  function getFxUSDBPSRate(Data storage self, string currency) internal view returns (uint bpsRate) {
    bytes32 id = keccak256(abi.encodePacked(&#39;fx.usd.rate&#39;, currency));
    return self.Storage.getUint(id);
  }

  /**
   * @notice Return the foreign currency USD exchanged amount
   * @param self Internal storage proxying TokenIOStorage contract
   * @param currency The TokenIO currency symbol (e.g. USDx, JPYx, GBPx)
   * @param fxAmount Amount of foreign currency to exchange into USD
   * @return {"amount" : "Returns the foreign currency amount in USD"}
   */
  function getFxUSDAmount(Data storage self, string currency, uint fxAmount) internal view returns (uint amount) {
    uint usdDecimals = getTokenDecimals(self, &#39;USDx&#39;);
    uint fxDecimals = getTokenDecimals(self, currency);
    /// @dev ensure decimal precision is normalized to USD decimals
    uint usdAmount = ((fxAmount.mul(getFxUSDBPSRate(self, currency)).div(10000)).mul(10**usdDecimals)).div(10**fxDecimals);
    return usdAmount;
  }


}

/*
COPYRIGHT 2018 Token, Inc.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
@title TokenIOAuthority - Authority Smart Contract for Token, Inc.

@author Ryan Tate <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="64161d050a4a1005100124100b0f010a4a0d0b">[email&#160;protected]</a>>, Sean Pollock <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7e0d1b1f10500e111212111d153e0a11151b10501711">[email&#160;protected]</a>>

@notice Contract uses generalized storage contract, `TokenIOStorage`, for
upgradeability of interface contract.
*/



contract TokenIOAuthority is Ownable {

    /// @dev Set reference to TokenIOLib interface which proxies to TokenIOStorage
    using TokenIOLib for TokenIOLib.Data;
    TokenIOLib.Data lib;

    /**
     * @notice Constructor method for Authority contract
     * @param _storageContract Ethereum Address of TokenIOStorage contract
     */
    constructor(address _storageContract) public {
        /*
         * @notice Set the storage contract for the interface
         * @dev This contract will be unable to use the storage constract until
         * @dev contract address is authorized with the storage contract
         * @dev Once authorized, you can setRegisteredFirm and setRegisteredAuthority
        */
        lib.Storage = TokenIOStorage(_storageContract);

        /// @dev set owner to contract initiator
        owner[msg.sender] = true;
    }

    /**
     * @notice Registers a firm as authorized true/false
     * @param firmName Name of firm
     * @param _authorized Authorization status
     * @return {"success" : "Returns true if lib.setRegisteredFirm succeeds"}
     */
    function setRegisteredFirm(string firmName, bool _authorized) public onlyAuthority(firmName, msg.sender) returns (bool success) {
        /// @notice set firm registration status
        require(
          lib.setRegisteredFirm(firmName, _authorized),
          "Error: Failed to register firm with storage contract! Please check your arguments."
        );
        return true;
    }

    /**
     * @notice Registers an authority asoociated with the given firm as true/false
     * @param firmName Name of firm
     * @param authority Address of authority account
     * @param _authorized Authorization status
     * @return {"success" : "Returns true if lib.setRegisteredAuthority succeeds"}
     */
    function setRegisteredAuthority(string firmName, address authority, bool _authorized) public onlyAuthority(firmName, msg.sender) returns (bool success) {
        /// @notice set authority of firm to given status
        require(
          lib.setRegisteredAuthority(firmName, authority, _authorized),
          "Error: Failed to register authority for issuer firm with storage contract! Please check your arguments and ensure firmName is registered before allowing an authority of said firm"
        );
        return true;
    }

    /**
     * @notice Gets firm asoociated with an authority address
     * @param authority Address of authority account
     * @return {"firm" : "name of firm"}
     */
    function getFirmFromAuthority(address authority) public view returns (string firm) {
        return lib.getFirmFromAuthority(authority);
    }

    /**
     * @notice Gets status of firm registration
     * @param firmName Name of firm
     * @return {"status" : "Returns status of firm registration"}
     */
    function isRegisteredFirm(string firmName) public view returns (bool status) {
        /// @notice check firm&#39;s registration status
        return lib.isRegisteredFirm(firmName);
    }

    /**
     * @notice Checks if an authority account is registered to a given firm
     * @param firmName Name of firm
     * @param authority Address of authority account
     * @return {"registered" : "Returns status of account registration to firm"}
     */
    function isRegisteredToFirm(string firmName, address authority) public view returns (bool registered) {
        /// @notice check if registered to firm
        return lib.isRegisteredToFirm(firmName, authority);
    }

    /**
     * @notice Gets status of authority registration
     * @param authority Address of authority account
     * @return { "registered" : "Returns true if account is a registered authority" }
     */
    function isRegisteredAuthority(address authority) public view returns (bool registered) {
        /// @notice check if registered authority
        return lib.isRegisteredAuthority(authority);
    }

    /**
     * @notice Sets contract which specifies fee parameters
     * @param feeContract Address of the fee contract
     * @return { "success" : "Returns true if lib.setMasterFeeContract succeeds" }
     */
    function setMasterFeeContract(address feeContract) public onlyOwner returns (bool success) {
        /// @notice set master fee contract
        require(
          lib.setMasterFeeContract(feeContract),
          "Error: Unable to set master fee contract. Please ensure fee contract has the correct parameters."
        );
        return true;
      }


    modifier onlyAuthority(string firmName, address authority) {
        /// @notice throws if not an owner authority or not registered to the given firm
        require(owner[authority] || lib.isRegisteredToFirm(firmName, authority),
          "Error: Transaction sender does not have permission for this operation!"
        );
        _;
    }

}