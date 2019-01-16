pragma solidity ^0.4.24;

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
  function Ownable() public {
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


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param info The contact information to attach to the contract.
    */
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}

/** @title Restricted
 *  Exposes onlyMonetha modifier
 */
contract Restricted is Ownable {

    //MonethaAddress set event
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

    /**
     *  Restrict methods in such way, that they can be invoked only by monethaAddress account.
     */
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

    /**
     *  Allows owner to set new monetha address
     */
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        MonethaAddressSet(_address, _isMonethaAddress);
    }
}



/**
 * @title SafeDestructible
 * Base contract that can be destroyed by owner.
 * Can be destructed if there are no funds on contract balance.
 */
contract SafeDestructible is Ownable {
    function destroy() onlyOwner public {
        require(this.balance == 0);
        selfdestruct(owner);
    }
}

/**
* @title ERC20 interface
*/
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function decimals() public view returns(uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}




/**
 *  @title MerchantWallet
 *  Serves as a public Merchant profile with merchant profile info,
 *      payment settings and latest reputation value.
 *  Also MerchantWallet accepts payments for orders.
 */

contract MerchantWallet is Pausable, SafeDestructible, Contactable, Restricted {

    string constant VERSION = "0.5";

    /// Address of merchant&#39;s account, that can withdraw from wallet
    address public merchantAccount;

    /// Address of merchant&#39;s fund address.
    address public merchantFundAddress;

    /// Unique Merchant identifier hash
    bytes32 public merchantIdHash;

    /// profileMap stores general information about the merchant
    mapping (string=>string) profileMap;

    /// paymentSettingsMap stores payment and order settings for the merchant
    mapping (string=>string) paymentSettingsMap;

    /// compositeReputationMap stores composite reputation, that compraises from several metrics
    mapping (string=>uint32) compositeReputationMap;

    /// number of last digits in compositeReputation for fractional part
    uint8 public constant REPUTATION_DECIMALS = 4;

    /**
     *  Restrict methods in such way, that they can be invoked only by merchant account.
     */
    modifier onlyMerchant() {
        require(msg.sender == merchantAccount);
        _;
    }

    /**
     *  Fund Address should always be Externally Owned Account and not a contract.
     */
    modifier isEOA(address _fundAddress) {
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_fundAddress)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     *  Restrict methods in such way, that they can be invoked only by merchant account or by monethaAddress account.
     */
    modifier onlyMerchantOrMonetha() {
        require(msg.sender == merchantAccount || isMonethaAddress[msg.sender]);
        _;
    }

    /**
     *  @param _merchantAccount Address of merchant&#39;s account, that can withdraw from wallet
     *  @param _merchantId Merchant identifier
     *  @param _fundAddress Merchant&#39;s fund address, where amount will be transferred.
     */
    constructor(address _merchantAccount, string _merchantId, address _fundAddress) public isEOA(_fundAddress) {
        require(_merchantAccount != 0x0);
        require(bytes(_merchantId).length > 0);

        merchantAccount = _merchantAccount;
        merchantIdHash = keccak256(_merchantId);

        merchantFundAddress = _fundAddress;
    }

    /**
     *  Accept payment from MonethaGateway
     */
    function () external payable {
    }

    /**
     *  @return profile info by string key
     */
    function profile(string key) external constant returns (string) {
        return profileMap[key];
    }

    /**
     *  @return payment setting by string key
     */
    function paymentSettings(string key) external constant returns (string) {
        return paymentSettingsMap[key];
    }

    /**
     *  @return composite reputation value by string key
     */
    function compositeReputation(string key) external constant returns (uint32) {
        return compositeReputationMap[key];
    }

    /**
     *  Set profile info by string key
     */
    function setProfile(
        string profileKey,
        string profileValue,
        string repKey,
        uint32 repValue
    )
        external onlyOwner
    {
        profileMap[profileKey] = profileValue;

        if (bytes(repKey).length != 0) {
            compositeReputationMap[repKey] = repValue;
        }
    }

    /**
     *  Set payment setting by string key
     */
    function setPaymentSettings(string key, string value) external onlyOwner {
        paymentSettingsMap[key] = value;
    }

    /**
     *  Set composite reputation value by string key
     */
    function setCompositeReputation(string key, uint32 value) external onlyMonetha {
        compositeReputationMap[key] = value;
    }

    /**
     *  Allows withdrawal of funds to beneficiary address
     */
    function doWithdrawal(address beneficiary, uint amount) private {
        require(beneficiary != 0x0);
        beneficiary.transfer(amount);
    }

    /**
     *  Allows merchant to withdraw funds to beneficiary address
     */
    function withdrawTo(address beneficiary, uint amount) public onlyMerchant whenNotPaused {
        doWithdrawal(beneficiary, amount);
    }

    /**
     *  Allows merchant to withdraw funds to it&#39;s own account
     */
    function withdraw(uint amount) external onlyMerchant {
        withdrawTo(msg.sender, amount);
    }

    /**
     *  Allows merchant or Monetha to initiate exchange of funds by withdrawing funds to deposit address of the exchange
     */
    function withdrawToExchange(address depositAccount, uint amount) external onlyMerchantOrMonetha whenNotPaused {
        doWithdrawal(depositAccount, amount);
    }

    /**
     *  Allows merchant or Monetha to initiate exchange of funds by withdrawing all funds to deposit address of the exchange
     */
    function withdrawAllToExchange(address depositAccount, uint min_amount) external onlyMerchantOrMonetha whenNotPaused {
        require (address(this).balance >= min_amount);
        doWithdrawal(depositAccount, address(this).balance);
    }

     /**
     *  Allows merchant or Monetha to initiate exchange of tokens by withdrawing all tokens to deposit address of the exchange
     */
    function withdrawAllTokensToExchange(address _tokenAddress, address _depositAccount, uint _minAmount) external onlyMerchantOrMonetha whenNotPaused {
        require(_tokenAddress != address(0));
        
        uint balance = ERC20(_tokenAddress).balanceOf(address(this));
        
        require(balance >= _minAmount);
        
        ERC20(_tokenAddress).transfer(_depositAccount, balance);
    }
    
    /**
     *  Allows merchant to change it&#39;s account address
     */
    function changeMerchantAccount(address newAccount) external onlyMerchant whenNotPaused {
        merchantAccount = newAccount;
    }

    /**
     *  Allows merchant to change it&#39;s fund address.
     */
    function changeFundAddress(address newFundAddress) external onlyMerchant isEOA(newFundAddress) {
        merchantFundAddress = newFundAddress;
    }
}