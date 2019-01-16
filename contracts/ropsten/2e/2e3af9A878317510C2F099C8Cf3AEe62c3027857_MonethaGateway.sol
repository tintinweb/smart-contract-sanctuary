pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/ownership/Contactable.sol

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param _info The contact information to attach to the contract.
    */
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}

// File: contracts/Restricted.sol

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

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }
}

// File: contracts/GenericERC20.sol

/**
* @title GenericERC20 interface
*/
contract GenericERC20 {
    function totalSupply() public view returns (uint256);

    function decimals() public view returns(uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);
        
    // Return type not defined intentionally since not all ERC20 tokens return proper result type
    function transfer(address _to, uint256 _value) public;

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

// File: contracts/IMonethaVoucher.sol

interface IMonethaVoucher {
    /**
    * @dev Total number of vouchers in shared pool
    */
    function totalInSharedPool() external view returns (uint256);

    /**
     * @dev Converts vouchers to equivalent amount of wei.
     * @param _value amount of vouchers (vouchers) to convert to amount of wei
     * @return A uint256 specifying the amount of wei.
     */
    function toWei(uint256 _value) external view returns (uint256);

    /**
     * @dev Converts amount of wei to equivalent amount of vouchers.
     * @param _value amount of wei to convert to vouchers (vouchers)
     * @return A uint256 specifying the amount of vouchers.
     */
    function fromWei(uint256 _value) external view returns (uint256);

    /**
     * @dev Applies discount for address by returning vouchers to shared pool and transferring funds (in wei). May be called only by Monetha.
     * @param _for address to apply discount for
     * @param _vouchers amount of vouchers to return to shared pool
     * @return Actual number of vouchers returned to shared pool and amount of funds (in wei) transferred.
     */
    function applyDiscount(address _for, uint256 _vouchers) external returns (uint256 amountVouchers, uint256 amountWei);

    /**
     * @dev Applies payback by transferring vouchers from the shared pool to the user.
     * The amount of transferred vouchers is equivalent to the amount of Ether in the `_amountWei` parameter.
     * @param _for address to apply payback for
     * @param _amountWei amount of Ether to estimate the amount of vouchers
     * @return The number of vouchers added
     */
    function applyPayback(address _for, uint256 _amountWei) external returns (uint256 amountVouchers);

    /**
     * @dev Function to buy vouchers by transferring equivalent amount in Ether to contract. May be called only by Monetha.
     * After the vouchers are purchased, they can be sold or released to another user. Purchased vouchers are stored in
     * a separate pool and may not be expired.
     * @param _vouchers The amount of vouchers to buy. The caller must also transfer an equivalent amount of Ether.
     */
    function buyVouchers(uint256 _vouchers) external payable;

    /**
     * @dev The function allows Monetha account to sell previously purchased vouchers and get Ether from the sale.
     * The equivalent amount of Ether will be transferred to the caller. May be called only by Monetha.
     * @param _vouchers The amount of vouchers to sell.
     * @return A uint256 specifying the amount of Ether (in wei) transferred to the caller.
     */
    function sellVouchers(uint256 _vouchers) external returns(uint256 weis);

    /**
     * @dev Function allows Monetha account to release the purchased vouchers to any address.
     * The released voucher acquires an expiration property and should be used in Monetha ecosystem within 6 months, otherwise
     * it will be returned to shared pool. May be called only by Monetha.
     * @param _to address to release vouchers to.
     * @param _value the amount of vouchers to release.
     */
    function releasePurchasedTo(address _to, uint256 _value) external returns (bool);

    /**
     * @dev Function to check the amount of vouchers that an owner (Monetha account) allowed to sell or release to some user.
     * @param owner The address which owns the funds.
     * @return A uint256 specifying the amount of vouchers still available for the owner.
     */
    function purchasedBy(address owner) external view returns (uint256);
}

// File: contracts/MonethaGateway.sol

/**
 *  @title MonethaGateway
 *
 *  MonethaGateway forward funds from order payment to merchant&#39;s wallet and collects Monetha fee.
 */
contract MonethaGateway is Pausable, Contactable, Destructible, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.6";

    /**
     *  Fee permille of Monetha fee.
     *  1 permille (‰) = 0.1 percent (%)
     *  15‰ = 1.5%
     */
    uint public constant FEE_PERMILLE = 15;


    uint public constant PERMILLE_COEFFICIENT = 1000;

    /**
     *  Address of Monetha Vault for fee collection
     */
    address public monethaVault;

    /**
     *  Account for permissions managing
     */
    address public admin;

    /**
     * Monetha voucher contract
     */
    IMonethaVoucher public monethaVoucher;

    /**
     *  Max. discount permille.
     *  10 permille = 1 %
     */
    uint public MaxDiscountPermille;

    event PaymentProcessedEther(address merchantWallet, uint merchantIncome, uint monethaIncome);
    event PaymentProcessedToken(address tokenAddress, address merchantWallet, uint merchantIncome, uint monethaIncome);
    event MonethaVoucherChanged(
        address indexed previousMonethaVoucher,
        address indexed newMonethaVoucher
    );
    event MaxDiscountPermilleChanged(uint prevPermilleValue, uint newPermilleValue);

    /**
     *  @param _monethaVault Address of Monetha Vault
     */
    constructor(address _monethaVault, address _admin, IMonethaVoucher _monethaVoucher) public {
        require(_monethaVault != 0x0);
        monethaVault = _monethaVault;

        setAdmin(_admin);
        setMonethaVoucher(_monethaVoucher);
        setMaxDiscountPermille(700); // 70%
    }

    /**
     *  acceptPayment accept payment from PaymentAcceptor, forwards it to merchant&#39;s wallet
     *      and collects Monetha fee.
     *  @param _merchantWallet address of merchant&#39;s wallet for fund transfer
     *  @param _monethaFee is a fee collected by Monetha
     */
    function acceptPayment(address _merchantWallet,
        uint _monethaFee,
        address _customerAddress,
        uint _vouchersApply,
        uint _paybackPermille)
    external payable onlyMonetha whenNotPaused returns (uint discountWei){
        require(_merchantWallet != 0x0);
        uint price = msg.value;
        // Monetha fee cannot be greater than 1.5% of payment
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(price).div(1000));

        discountWei = 0;
        if (monethaVoucher != address(0) && _vouchersApply > 0) {
            if (MaxDiscountPermille > 0) {
                uint maxDiscountWei = price.mul(MaxDiscountPermille).div(PERMILLE_COEFFICIENT);
                uint maxVouchers = monethaVoucher.fromWei(maxDiscountWei);
                // limit vouchers to apply
                uint vouchersApply = _vouchersApply;
                if (vouchersApply > maxVouchers) {
                    vouchersApply = maxVouchers;
                }

                (, discountWei) = monethaVoucher.applyDiscount(_customerAddress, vouchersApply);
            }

            if (_paybackPermille > 0) {
                uint paybackWei = price.sub(discountWei).mul(_paybackPermille).div(PERMILLE_COEFFICIENT);
                if (paybackWei > 0) {
                    monethaVoucher.applyPayback(_customerAddress, paybackWei);
                }
            }
        }

        uint merchantIncome = price.sub(_monethaFee);

        _merchantWallet.transfer(merchantIncome);
        monethaVault.transfer(_monethaFee);

        emit PaymentProcessedEther(_merchantWallet, merchantIncome, _monethaFee);
    }

    /**
     *  acceptTokenPayment accept token payment from PaymentAcceptor, forwards it to merchant&#39;s wallet
     *      and collects Monetha fee.
     *  @param _merchantWallet address of merchant&#39;s wallet for fund transfer
     *  @param _monethaFee is a fee collected by Monetha
     *  @param _tokenAddress is the token address
     *  @param _value is the order value
     */
    function acceptTokenPayment(
        address _merchantWallet,
        uint _monethaFee,
        address _tokenAddress,
        uint _value
    )
    external onlyMonetha whenNotPaused
    {
        require(_merchantWallet != 0x0);

        // Monetha fee cannot be greater than 1.5% of payment
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(_value).div(1000));

        uint merchantIncome = _value.sub(_monethaFee);

        GenericERC20(_tokenAddress).transfer(_merchantWallet, merchantIncome);
        GenericERC20(_tokenAddress).transfer(monethaVault, _monethaFee);

        emit PaymentProcessedToken(_tokenAddress, _merchantWallet, merchantIncome, _monethaFee);
    }

    /**
     *  changeMonethaVault allows owner to change address of Monetha Vault.
     *  @param newVault New address of Monetha Vault
     */
    function changeMonethaVault(address newVault) external onlyOwner whenNotPaused {
        monethaVault = newVault;
    }

    /**
     *  Allows other monetha account or contract to set new monetha address
     */
    function setMonethaAddress(address _address, bool _isMonethaAddress) public {
        require(msg.sender == admin || msg.sender == owner);

        isMonethaAddress[_address] = _isMonethaAddress;

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }

    /**
     *  setAdmin allows owner to change address of admin.
     *  @param _admin New address of admin
     */
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0));
        admin = _admin;
    }

    /**
     *  setAdmin allows owner to change address of Monetha voucher contract. If set to 0x0 address, discounts and paybacks are disabled.
     *  @param _monethaVoucher New address of Monetha voucher contract
     */
    function setMonethaVoucher(IMonethaVoucher _monethaVoucher) public onlyOwner {
        if (monethaVoucher != _monethaVoucher) {
            emit MonethaVoucherChanged(monethaVoucher, _monethaVoucher);
            monethaVoucher = _monethaVoucher;
        }
    }

    /**
     *  setMaxDiscountPermille allows Monetha to change max.discount percentage
     *  @param _maxDiscountPermille New value of max.discount (in permille)
     */
    function setMaxDiscountPermille(uint _maxDiscountPermille) public onlyOwner {
        require(_maxDiscountPermille <= PERMILLE_COEFFICIENT);
        emit MaxDiscountPermilleChanged(MaxDiscountPermille, _maxDiscountPermille);
        MaxDiscountPermille = _maxDiscountPermille;
    }
}