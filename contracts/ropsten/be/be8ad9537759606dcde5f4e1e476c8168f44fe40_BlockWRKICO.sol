pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    if (allowed[msg.sender][_spender] == 0) {
        require(_value >= 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    } else {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title ERC865Basic
 * @dev Simpler version of the ERC865 interface from https://github.com/adilharis2001/ERC865Demo
 * @author jsdavis28
 * @notice ERC865Token allows for users to pay gas costs to a delegate in an ERC20 token
 * https://github.com/ethereum/EIPs/issues/865
 */
 contract ERC865Basic is ERC20 {
     function _transferPreSigned(
         bytes _signature,
         address _from,
         address _to,
         uint256 _value,
         uint256 _fee,
         uint256 _nonce
     )
        internal;

     event TransferPreSigned(
         address indexed delegate,
         address indexed from,
         address indexed to,
         uint256 value);
}


/**
 * @title ERC865BasicToken
 * @dev Simpler version of the ERC865 token from https://github.com/adilharis2001/ERC865Demo
 * @author jsdavis28
 * @notice ERC865Token allows for users to pay gas costs to a delegate in an ERC20 token
 * https://github.com/ethereum/EIPs/issues/865
 */

 contract ERC865BasicToken is ERC865Basic, StandardToken {
    /**
     * @dev Sets internal variables for contract
     */
    address internal feeAccount;
    mapping(bytes => bool) internal signatures;

    /**
     * @dev Allows a delegate to submit a transaction on behalf of the token holder.
     * @param _signature The signature, issued by the token holder.
     * @param _to The recipient&#39;s address.
     * @param _value The amount of tokens to be transferred.
     * @param _fee The amount of tokens paid to the delegate for gas costs.
     * @param _nonce The transaction number.
     */
    function _transferPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        internal
    {
        //Pre-validate transaction
        require(_to != address(0));
        require(signatures[_signature] == false);

        //Create a hash of the transaction details
        bytes32 hashedTx = _transferPreSignedHashing(_to, _value, _fee, _nonce);

        //Obtain the token holder&#39;s address and check balance
        address from = _recover(hashedTx, _signature);
        require(from == _from);
        uint256 total = _value.add(_fee);
        require(total <= balances[from]);

        //Transfer tokens
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[feeAccount] = balances[feeAccount].add(_fee);

        //Mark transaction as completed
        signatures[_signature] = true;

        emit TransferPreSigned(msg.sender, from, _to, _value);
        emit TransferPreSigned(msg.sender, from, feeAccount, _fee);
    }

    /**
     * @dev Creates a hash of the transaction information passed to transferPresigned.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     * @return A copy of the hashed message signed by the token holder, with prefix added.
     */
    function _transferPreSignedHashing(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        internal
        returns (bytes32)
    {
        //Create a copy of thehashed message signed by the token holder
        bytes32 hash = keccak256(abi.encodePacked(_to, _value, _fee, _nonce));

        //Add prefix to hash
        return _prefix(hash);
    }

    /**
     * @dev Adds prefix to the hashed message signed by the token holder.
     * @param _hash The hashed message (keccak256) to be prefixed.
     * @return Prefixed hashed message to return from _transferPreSignedHashing.
     */
    function _prefix(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    /**
     * @dev Validate the transaction information and recover the token holder&#39;s address.
     * @param _hash A prefixed version of the hash used in the original signed message.
     * @param _sig The signature submitted by the token holder.
     * @return The token holder/transaction signer&#39;s address.
     */
    function _recover(bytes32 _hash, bytes _sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (_sig.length != 65) {
            return (address(0));
        }

        //Split the signature into r, s and v variables
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        //Version of signature should be 27 or 28, but 0 and 1 are also possible
        if (v < 27) {
            v += 27;
        }

        //If the version is correct, return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(_hash, v, r, s);
        }
    }
}


/**
 * @title Taxed token
 * @dev Version of BasicToken that allows for a fee on token transfers.
 * See https://github.com/OpenZeppelin/openzeppelin-solidity/pull/788
 * @author jsdavis28
 */
contract TaxedToken is ERC865BasicToken {
    /**
     * @dev Sets taxRate fee as public
     */
    uint8 public taxRate;

    /**
     * @dev Transfer tokens to a specified account after diverting a fee to a central account.
     * @param _to The receiving address.
     * @param _value The number of tokens to transfer.
     */
    function transfer(
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 fee = _value.mul(taxRate).div(100);
        uint256 taxedValue = _value.sub(fee);

        balances[_to] = balances[_to].add(taxedValue);
        emit Transfer(msg.sender, _to, taxedValue);
        balances[feeAccount] = balances[feeAccount].add(fee);
        emit Transfer(msg.sender, feeAccount, fee);

        return true;
    }

    /**
     * @dev Provides a taxed transfer on StandardToken&#39;s transferFrom() function
     * @param _from The address providing allowance to spend
     * @param _to The receiving address.
     * @param _value The number of tokens to transfer.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        uint256 fee = _value.mul(taxRate).div(100);
        uint256 taxedValue = _value.sub(fee);

        balances[_to] = balances[_to].add(taxedValue);
        emit Transfer(_from, _to, taxedValue);
        balances[feeAccount] = balances[feeAccount].add(fee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, feeAccount, fee);

        return true;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Authorizable
 * @dev The Authorizable contract allows the owner to set a number of additional
 *  acccounts with limited administrative privileges to simplify user permissions.
 * Only the contract owner can add or remove authorized accounts.
 * @author jsdavis28
 */
contract Authorizable is Ownable {
    using SafeMath for uint256;

    address[] public authorized;
    mapping(address => bool) internal authorizedIndex;
    uint8 public numAuthorized;

    /**
     * @dev The Authorizable constructor sets the owner as authorized
     */
    constructor() public {
        authorized.length = 2;
        authorized[1] = msg.sender;
        authorizedIndex[msg.sender] = true;
        numAuthorized = 1;
    }

    /**
     * @dev Throws if called by any account other than an authorized account.
     */
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

    /**
     * @dev Allows the current owner to add an authorized account.
     * @param _account The address being added as authorized.
     */
    function addAuthorized(address _account) public onlyOwner {
        if (authorizedIndex[_account] == false) {
        	authorizedIndex[_account] = true;
        	authorized.length++;
        	authorized[authorized.length.sub(1)] = _account;
        	numAuthorized++;
        }
    }

    /**
     * @dev Validates whether an account is authorized for enhanced permissions.
     * @param _account The address being evaluated.
     */
    function isAuthorized(address _account) public constant returns (bool) {
        if (authorizedIndex[_account] == true) {
        	return true;
        }

        return false;
    }

    /**
     * @dev Allows the current owner to remove an authorized account.
     * @param _account The address to remove from authorized.
     */
    function removeAuthorized(address _account) public onlyOwner {
        require(isAuthorized(_account));
        authorizedIndex[_account] = false;
        numAuthorized--;
    }
}


/**
 * @title BlockWRKToken
 * @dev BlockWRKToken contains administrative features that allow the BlockWRK
 *  application to interface with the BlockWRK token, an ERC20-compliant token
 *  that integrates taxed token and ERC865 functionality.
 * @author jsdavis28
 */

contract BlockWRKToken is TaxedToken, Authorizable {
    /**
     * @dev Sets token information.
     */
    string public name = "BlockWRK";
    string public symbol = "WRK";
    uint8 public decimals = 4;
    uint256 public INITIAL_SUPPLY;

    /**
     * @dev Sets public variables for BlockWRK token.
     */
    address public distributionPoolWallet;
    address public inAppPurchaseWallet;
    address public reservedTokenWallet;
    uint256 public premineDistributionPool;
    uint256 public premineReserved;

    /**
     * @dev Sets private variables for custom token functions.
     */
    uint256 internal decimalValue = 10000;

    constructor() public {
        //Test values
        // feeAccount = 0x2EDDEe216fFB08E01Cb67CA5B4F405FCbBB3C1fB;
        // distributionPoolWallet = 0x5ad5f036280b996e28f49783089d96c77af1a6a6;
        // inAppPurchaseWallet = 0x2EDDEe216fFB08E01Cb67CA5B4F405FCbBB3C1fB;
        // reservedTokenWallet = 0x1A50DdEb4C1D1c8Fa46A4CdE40c11fd003157A32;
        // premineDistributionPool = decimalValue.mul(5600000000);
        // premineReserved = decimalValue.mul(2000000000);
        // INITIAL_SUPPLY = premineDistributionPool.add(premineReserved);
        // balances[distributionPoolWallet] = premineDistributionPool;
        // emit Transfer(address(this), distributionPoolWallet, premineDistributionPool);
        // balances[reservedTokenWallet] = premineReserved;
        // emit Transfer(address(this), reservedTokenWallet, premineReserved);
        // totalSupply_ = INITIAL_SUPPLY;
        // taxRate = 2;
    }

    /**
     * @dev Allows App to distribute WRK tokens to users.
     * This function will be called by authorized from within the App.
     * @param _to The recipient&#39;s BlockWRK address.
     * @param _value The amount of WRK to transfer.
     */
    function inAppTokenDistribution(
        address _to,
        uint256 _value
    )
        public
        onlyAuthorized
    {
        require(_value <= balances[distributionPoolWallet]);
        require(_to != address(0));

        balances[distributionPoolWallet] = balances[distributionPoolWallet].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(distributionPoolWallet, _to, _value);
    }

    /**
     * @dev Allows App to process fiat payments for WRK tokens, charging a fee in WRK.
     * This function will be called by authorized from within the App.
     * @param _to The buyer&#39;s BlockWRK address.
     * @param _value The amount of WRK to transfer.
     * @param _fee The fee charged in WRK for token purchase.
     */
    function inAppTokenPurchase(
        address _to,
        uint256 _value,
        uint256 _fee
    )
        public
        onlyAuthorized
    {
        require(_value <= balances[inAppPurchaseWallet]);
        require(_to != address(0));

        balances[inAppPurchaseWallet] = balances[inAppPurchaseWallet].sub(_value);
        uint256 netAmount = _value.sub(_fee);
        balances[_to] = balances[_to].add(netAmount);
        emit Transfer(inAppPurchaseWallet, _to, netAmount);
        balances[feeAccount] = balances[feeAccount].add(_fee);
        emit Transfer(inAppPurchaseWallet, feeAccount, _fee);
    }

    /**
     * @dev Allows owner to set the percentage fee charged by TaxedToken on external transfers.
     * @param _newRate The amount to be set.
     */
    function setTaxRate(uint8 _newRate) public onlyOwner {
        taxRate = _newRate;
    }

    /**
     * @dev Allows owner to set the fee account to receive transfer fees.
     * @param _newAddress The address to be set.
     */
    function setFeeAccount(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        feeAccount = _newAddress;
    }

    /**
     * @dev Allows owner to set the wallet that holds WRK for sale via in-app purchases with fiat.
     * @param _newAddress The address to be set.
     */
    function setInAppPurchaseWallet(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        inAppPurchaseWallet = _newAddress;
    }

    /**
     * @dev Allows authorized to act as a delegate to transfer a pre-signed transaction for ERC865
     * @param _signature The pre-signed message.
     * @param _to The token recipient.
     * @param _value The amount of WRK to send the recipient.
     * @param _fee The fee to be paid in WRK (calculated by App off-chain).
     * @param _nonce The transaction number (stored in App off-chain).
     */
    function transactionHandler(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        onlyAuthorized
    {
        _transferPreSigned(_signature, _from, _to, _value, _fee, _nonce);
    }
}


/**
 * @title BlockWRKICO
 * @notice This contract manages the sale of WRK tokens for the BlockWRK ICO.
 * @dev This contract incorporates elements of OpenZeppelin crowdsale contracts with some modifications.
 * @author jsdavis28
 */
 contract BlockWRKICO is BlockWRKToken {
    /**
     * @dev Sets public variables for BlockWRK ICO
     */
    address public salesWallet;
    uint256 public cap;
    uint256 public closingTime;
    uint256 public currentTierRate;
    uint256 public openingTime;
    uint256 public weiRaised;

    /**
     * @dev Sets private variables for custom token functions.
     */
     uint256 internal availableInCurrentTier;
     uint256 internal availableInSale;
     uint256 internal totalPremineVolume;
     uint256 internal totalSaleVolume;
     uint256 internal totalTokenVolume;
     uint256 internal tier1Rate;
     uint256 internal tier2Rate;
     uint256 internal tier3Rate;
     uint256 internal tier4Rate;
     uint256 internal tier5Rate;
     uint256 internal tier6Rate;
     uint256 internal tier7Rate;
     uint256 internal tier8Rate;
     uint256 internal tier9Rate;
     uint256 internal tier10Rate;
     uint256 internal tier1Volume;
     uint256 internal tier2Volume;
     uint256 internal tier3Volume;
     uint256 internal tier4Volume;
     uint256 internal tier5Volume;
     uint256 internal tier6Volume;
     uint256 internal tier7Volume;
     uint256 internal tier8Volume;
     uint256 internal tier9Volume;
     uint256 internal tier10Volume;

     constructor() public {
         //Test values
         // cap = 9999999999999999999999999999999999999999999999;
         // salesWallet = 0x2eddee216ffb08e01cb67ca5b4f405fcbbb3c1fb;
         // openingTime = 1539346800;
         // closingTime = 1539348900;

         // totalPremineVolume = 76000000000000;
         // totalSaleVolume = 43000000000000;
         // totalTokenVolume = 119000000000000;
         // availableInSale = totalSaleVolume;
         // tier1Rate = 200000;
         // tier2Rate = 40000;
         // tier3Rate = 20000;
         // tier4Rate = 10000;
         // tier5Rate = 10000;
         // tier6Rate = 10000;
         // tier7Rate = 10000;
         // tier8Rate = 10000;
         // tier9Rate = 10000;
         // tier10Rate = 10000;
         // tier1Volume = totalPremineVolume.add(1000000000000);
         // tier2Volume = tier1Volume.add(2000000000000);
         // tier3Volume = tier2Volume.add(5000000000000);
         // tier4Volume = tier3Volume.add(5000000000000);
         // tier5Volume = tier4Volume.add(5000000000000);
         // tier6Volume = tier5Volume.add(5000000000000);
         // tier7Volume = tier6Volume.add(5000000000000);
         // tier8Volume = tier7Volume.add(5000000000000);
         // tier9Volume = tier8Volume.add(5000000000000);
         // tier10Volume = tier9Volume.add(5000000000000);
     }

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
     * Event marking the transfer of any remaining WRK to the distribution pool post-ICO
     * @param wallet The address remaining sale tokens are delivered
     * @param amount The remaining tokens after the sale has closed
     */
     event CloseoutSale(address indexed wallet, uint256 amount);



    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Allows ICO participants to purchase WRK tokens
     * @param _beneficiary The address of the ICO participant
     */
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        //Calculate number of tokens to issue
        uint256 tokens = _calculateTokens(weiAmount);

        //Calculate new amount of Wei raised
        weiRaised = weiRaised.add(weiAmount);

        //Process token purchase and forward funcds to salesWallet
        _processPurchase(_beneficiary, tokens);
        _forwardFunds();
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

     /**
      * @dev Checks whether the period in which the crowdsale is open has already elapsed.
      * @return Whether crowdsale period has elapsed
      */
     function hasClosed() public view returns (bool) {
         // solium-disable-next-line security/no-block-members
         return block.timestamp > closingTime;
     }



    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Calculates total number of tokens to sell, accounting for varied rates per tier.
     * @param _amountWei Total amount of Wei sent by ICO participant
     * @return Total number of tokens to send to buyer
     */
    function _calculateTokens(uint256 _amountWei) internal returns (uint256) {
        //Tokens pending in sale
        uint256 tokenAmountPending;

        //Tokens to be sold
        uint256 tokenAmountToIssue;

        //Note: tierCaps must take into account reserved and distribution pool tokens
        //Determine tokens remaining in tier and set current token rate
        uint256 tokensRemainingInTier = _getRemainingTokens(totalSupply_);

        //Calculate new tokens pending sale
        uint256 newTokens = _getTokenAmount(_amountWei);

        //Check if _newTokens exceeds _tokensRemainingInTier
        bool nextTier = true;
        while (nextTier) {
            if (newTokens > tokensRemainingInTier) {
                //Get tokens sold in current tier and add to pending total supply
                tokenAmountPending = tokensRemainingInTier;
                uint256 newTotal = totalSupply_.add(tokenAmountPending);

                //Save number of tokens pending from current tier
                tokenAmountToIssue = tokenAmountToIssue.add(tokenAmountPending);

                //Calculate Wei spent in current tier and set remaining Wei for next tier
                uint256 pendingAmountWei = tokenAmountPending.div(currentTierRate);
                uint256 remainingWei = _amountWei.sub(pendingAmountWei);

                //Calculate number of tokens in next tier
                tokensRemainingInTier = _getRemainingTokens(newTotal);
                newTokens = _getTokenAmount(remainingWei);
            } else {
                tokenAmountToIssue = tokenAmountToIssue.add(newTokens);
                nextTier = false;
                _setAvailableInCurrentTier(tokensRemainingInTier, newTokens);
                _setAvailableInSale(newTokens);
            }
        }

        //Return amount of tokens to be issued in this sale
        return tokenAmountToIssue;
    }

    /**
     * @dev Source of tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        totalSupply_ = totalSupply_.add(_tokenAmount);
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        salesWallet.transfer(msg.value);
    }

    /**
     * @dev Performs a binary search of the sale tiers to determine current sales volume and rate.
     * @param _tokensSold The total number of tokens sold in the ICO prior to this tx
     * @return The remaining number of tokens for sale in the current sale tier
     */
    function _getRemainingTokens(uint256 _tokensSold) internal returns (uint256) {
        //Deteremine the current sale tier, set current rate and find remaining tokens in tier
        uint256 remaining;
        if (_tokensSold < tier5Volume) {
            if (_tokensSold < tier3Volume) {
                if (_tokensSold < tier1Volume) {
                    _setCurrentTierRate(tier1Rate);
                    remaining = tier1Volume.sub(_tokensSold);
                } else if (_tokensSold < tier2Volume) {
                    _setCurrentTierRate(tier2Rate);
                    remaining = tier2Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier3Rate);
                    remaining = tier3Volume.sub(_tokensSold);
                }
            } else {
                if (_tokensSold < tier4Volume) {
                    _setCurrentTierRate(tier4Rate);
                    remaining = tier4Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier5Rate);
                    remaining = tier5Volume.sub(_tokensSold);
                }
            }
        } else {
            if (_tokensSold < tier8Volume) {
                if (_tokensSold < tier6Volume) {
                    _setCurrentTierRate(tier6Rate);
                    remaining = tier6Volume.sub(_tokensSold);
                } else if (_tokensSold < tier7Volume) {
                    _setCurrentTierRate(tier7Rate);
                    remaining = tier7Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier8Rate);
                    remaining = tier8Volume.sub(_tokensSold);
                }
            } else {
                if (_tokensSold < tier9Volume) {
                    _setCurrentTierRate(tier9Rate);
                    remaining = tier9Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier10Rate);
                    remaining = tier10Volume.sub(_tokensSold);
                }
            }
        }

        return remaining;
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(currentTierRate).mul(decimalValue).div(1 ether);
    }

    /**
     * @dev Validation of an incoming purchase.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) <= cap);
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Calculates remaining tokens available in the current tier after a sale is processed
     * @param _tierPreviousRemaining Number of tokens remaining prior to sale
     * @param _newIssue Number of tokens to be purchased
     */
    function _setAvailableInCurrentTier(uint256 _tierPreviousRemaining, uint256 _newIssue) internal {
        availableInCurrentTier = _tierPreviousRemaining.sub(_newIssue);
    }

    /**
     * @dev Calculates remaining tokens available in the ICO after a sale is processed
     * @param _newIssue Number of tokens to be purchased
     */
    function _setAvailableInSale(uint256 _newIssue) internal {
        availableInSale = totalSaleVolume.sub(_newIssue);
    }

    /**
     * @dev Sets the current tier rate based on sale volume
     * @param _rate The new rate
     */
    function _setCurrentTierRate(uint256 _rate) internal {
        currentTierRate = _rate;
    }

    /**
     * @dev Returns the remaining number of tokens for sale
     * @return Total remaining tokens available for sale
     */
    function tokensRemainingInSale() public view returns (uint256) {
        return availableInSale;
    }

    /**
     * @dev Returns the remaining number of tokens for sale in the current tier
     * @return Total remaining tokens available for sale in the current tier
     */
    function tokensRemainingInTier() public view returns (uint256) {
        return availableInCurrentTier;
    }

    /**
     * @dev Allows the owner to transfer any remaining tokens not sold to a wallet
     * @return Total remaining tokens available for sale
     */
     function transferRemainingTokens() public onlyOwner {
         //require that sale is closed
         require(hasClosed());

         //require that tokens are still remaining after close
         require(availableInSale > 0);

         //send remaining tokens to distribution pool wallet
         balances[distributionPoolWallet] = balances[distributionPoolWallet].add(availableInSale);
         emit CloseoutSale(distributionPoolWallet, availableInSale);
     }
}