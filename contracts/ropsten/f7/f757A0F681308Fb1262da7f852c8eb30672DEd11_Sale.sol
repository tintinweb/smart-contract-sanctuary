pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

// File: contracts/utils/Stateable.sol

contract Stateable is Ownable {
    enum State{Unknown, Preparing, Starting, Pausing, Finished}
    State state;

    event OnStateChange(string _state);

    constructor() public {
        state = State.Unknown;
    }

    modifier prepared() {
        require(getState() == State.Preparing);
        _;
    }

    modifier started() {
        require(getState() == State.Starting);
        _;
    }

    modifier paused() {
        require(getState() == State.Pausing);
        _;
    }

    modifier finished() {
        require(getState() == State.Finished);
        _;
    }

    function setState(State _state) internal onlyOwner {
        state = _state;
        emit OnStateChange(getKeyByValue(state));
    }

    function getState() public view returns (State) {
        return state;
    }

    function getKeyByValue(State _state) public pure returns (string) {
        if (State.Preparing == _state) return &quot;Preparing&quot;;
        if (State.Starting == _state) return &quot;Starting&quot;;
        if (State.Pausing == _state) return &quot;Pausing&quot;;
        if (State.Finished == _state) return &quot;Finished&quot;;
        return &quot;&quot;;
    }
}

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: contracts/sale/Product.sol

/**
 * @title Product
 * @dev Simpler version of Product interface
 */
contract Product is ExtendsOwnable {
    using SafeMath for uint256;

    string public name;
    uint256 public maxcap;
    uint256 public weiRaised;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;
    uint256 public lockup;

    constructor (
        string _name,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        uint256 _lockup
    ) public {
        require(_maxcap > _minimum);

        name = _name;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;
        lockup = _lockup;
    }

    function addWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised <= _weiRaised);

        weiRaised = _weiRaised;
    }

    function subWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised >= _weiRaised);

        weiRaised = weiRaised.sub(_weiRaised);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts/sale/TokenDistributor.sol

contract TokenDistributor is ExtendsOwnable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        bytes32 id;
        address buyer;
        address product;
        uint256 amount;
        uint256 criterionTime;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] purchasedList;
    mapping (bytes32 => uint256) indexId;
    uint256 private nonce;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    event Receipt(
        bytes32 id,
        address buyer,
        address product,
        uint256 amount,
        uint256 criterionTime,
        bool release,
        bool refund
    );

    event BuyerAddressTransfer(bytes32 _id, address _from, address _to);

    event WithdrawToken(address to, uint256 amount);

    constructor(address _token) public {
        token = ERC20(_token);
        nonce = 0;

        //for error check
        purchasedList.push(Purchased(0, 0, 0, 0, 0, true, true));
    }

    function addPurchased(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(bytes32)
    {
        nonce = nonce.add(1);
        bytes32 id = keccak256(_buyer, block.timestamp, nonce);
        purchasedList.push(Purchased(id, _buyer, _product, _amount, 0, false, false));
        indexId[id] = purchasedList.length;
        return id;

        emit Receipt(id, _buyer, _product, _amount, 0, false, false);
    }

    function addPurchased(bytes32 _id, uint256 _amount) external onlyOwner {
        require(_id != 0);

        uint index = indexId[_id];
        if (isLive(index)) {
            purchasedList[index].amount = purchasedList[index].amount.add(_amount);

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                _amount,
                0,
                false,
                false);
        }
    }

    function getAmount(bytes32 _id) external view returns(uint256) {
        if (_id == 0) {
            return 0;
        }

        uint index = indexId[_id];
        if (purchasedList[index].release || purchasedList[index].refund) {
            return 0;
        } else {
            return purchasedList[index].amount;
        }
    }

    function setCriterionTime(address _product, uint256 _criterionTime)
        external
        onlyOwner
        validAddress(_product)
    {
        for(uint index=1; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product) {
                purchasedList[index].criterionTime = _criterionTime;
            }
        }
    }

    function releaseProduct(address _product)
        external
        onlyOwner
        validAddress(_product)
    {
        for(uint index=1; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product
                && !purchasedList[index].release
                && !purchasedList[index].refund)
            {
                Product product = Product(purchasedList[index].product);
                require(purchasedList[index].criterionTime != 0);
                require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
                purchasedList[index].release = true;

                require(token.balanceOf(address(this)) >= purchasedList[index].amount);
                token.safeTransfer(purchasedList[index].buyer, purchasedList[index].amount);

                emit Receipt(
                    purchasedList[index].id,
                    purchasedList[index].buyer,
                    purchasedList[index].product,
                    purchasedList[index].amount,
                    purchasedList[index].criterionTime,
                    purchasedList[index].release,
                    purchasedList[index].refund);
            }
        }
    }

    function release(bytes32 _id) external onlyOwner {
        uint index = indexId[_id];

        if (isLive(index)) {
            Product product = Product(purchasedList[index].product);
            require(purchasedList[index].criterionTime != 0);
            require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
            purchasedList[index].release = true;

            require(token.balanceOf(address(this)) >= purchasedList[index].amount);
            token.safeTransfer(purchasedList[index].buyer, purchasedList[index].amount);

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);
        }
    }

    function refund(bytes32 _id) external onlyOwner returns (bool, uint256) {
        uint index = indexId[_id];

        if (isLive(index)) {
            Product product = Product(purchasedList[index].product);
            require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
            purchasedList[index].refund = true;

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);

            return (true, purchasedList[index].amount);
        } else {
            return (false, 0);
        }
    }

    function buyerAddressTransfer(bytes32 _id, address _from, address _to)
        external
        onlyOwner
        returns (bool)
    {
        uint index = indexId[_id];
        if (purchasedList[index].buyer == _from) {
            purchasedList[index].buyer = _to;
            emit BuyerAddressTransfer(_id, _from, _to);
            return true;
        } else {
            return false;
        }
    }

    function withdrawToken(address _Owner) external onlyOwner {
        token.safeTransfer(_Owner, token.balanceOf(address(this)));
        emit WithdrawToken(_Owner, token.balanceOf(address(this)));
    }

    function isLive(uint256 _index) private view returns(bool){
        if (!purchasedList[_index].release && !purchasedList[_index].refund) {
            return true;
        } else {
            return false;
        }
    }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: openzeppelin-solidity/contracts/access/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of &quot;user permissions&quot;.
 */
contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = &quot;whitelist&quot;;

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
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

// File: contracts/sale/Sale.sol

contract Sale is Stateable {
    using SafeMath for uint256;
    using Math for uint256;

    address public wallet;
    Whitelist public whiteList;
    Product public product;
    TokenDistributor public tokenDistributor;

    mapping (string => bool) isRegistered;
    mapping (string => mapping (address => bytes32)) buyers;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    modifier validProductName(string _productName) {
        require(bytes(_productName).length != 0);
        _;
    }

    modifier changeProduct() {
        require(getState() == State.Preparing || getState() == State.Finished);
        _;
    }

    constructor (
        address _wallet,
        address _whiteList,
        address _product,
        address _tokenDistributor
    ) public {
        require(_wallet != address(0));
        require(_whiteList != address(0));
        require(_product != address(0));
        require(_tokenDistributor != address(0));

        wallet = _wallet;
        whiteList = Whitelist(_whiteList);
        product = Product(_product);
        tokenDistributor = TokenDistributor(_tokenDistributor);
        isRegistered[product.name()] = true;

        setState(State.Preparing);
    }

    function registerProduct(address _product) external onlyOwner changeProduct validAddress(_product) {
        product = Product(_product);

        require(!isRegistered[product.name()]);
        isRegistered[product.name()] = true;

        setState(State.Preparing);

        emit ChangeExternalAddress(_product, &quot;Product&quot;);
    }

    function setTokenDistributor(address _tokenDistributor) external onlyOwner validAddress(_tokenDistributor) {
        tokenDistributor = TokenDistributor(_tokenDistributor);
        emit ChangeExternalAddress(_tokenDistributor, &quot;TokenDistributor&quot;);
    }

    function setWhitelist(address _whitelist) external onlyOwner validAddress(_whitelist) {
        whiteList = Whitelist(_whitelist);
        emit ChangeExternalAddress(_whitelist, &quot;Whitelist&quot;);
    }

    function setWallet(address _wallet) external onlyOwner validAddress(_wallet) {
        wallet = _wallet;
        emit ChangeExternalAddress(_wallet, &quot;Wallet&quot;);
    }

    function pause() external onlyOwner {
        setState(State.Pausing);
    }

    function start() external onlyOwner {
        setState(State.Starting);
    }

    function finish() external onlyOwner {
        setState(State.Finished);
    }

    function () external payable {
        address buyer = msg.sender;
        uint256 amount = msg.value;

        emit BuyerTest(buyer, amount);

        require(getState() == State.Starting, &quot;State Failed&quot;);
        require(whiteList.whitelist(buyer), &quot;Whitelist Failed&quot;);
        require(buyer != address(0), &quot;Address 0x Failed&quot;);
        require(product.weiRaised() < product.maxcap(), &quot;maxcap Failed&quot;);

        address productAddress = address(product);
        uint256 tokenAmount = tokenDistributor.getAmount(buyers[product.name()][buyer]);
        uint256 buyerAmount = (tokenAmount > 0) ? tokenAmount.div(product.rate()) : 0 ;

        require(buyerAmount < product.exceed(), &quot;exceed Failed&quot;);
        require(buyerAmount.add(amount) >= product.minimum(), &quot;minimum Failed&quot;);

        uint256 purchase;
        uint256 refund;
        uint256 totalAmount;
        (purchase, refund, totalAmount) = getPurchaseDetail(buyerAmount, amount);

        product.addWeiRaised(totalAmount);

        if(buyerAmount > 0) {
            tokenDistributor.addPurchased(buyers[product.name()][buyer], purchase.mul(product.rate()));
        } else {
            buyers[product.name()][buyer] = tokenDistributor.addPurchased(buyer, productAddress, purchase.mul(product.rate()));
            emit AddTest(buyers[product.name()][buyer]);
        }

        wallet.transfer(purchase);

        if(refund > 0) {
            buyer.transfer(refund);
        }

        if(totalAmount >= product.maxcap()) {
            setState(State.Finished);
        }

        emit Purchase(buyer, purchase, refund, purchase.mul(product.rate()));
    }

    function getPurchaseDetail(uint256 _buyerAmount, uint256 _amount) private view returns (uint256, uint256, uint256) {
        uint256 d1 = product.maxcap().sub(product.weiRaised());
        uint256 d2 = product.exceed().sub(_buyerAmount);
        uint256 possibleAmount = (d1.min256(d2)).min256(_amount);

        return (possibleAmount, _amount.sub(possibleAmount), possibleAmount.add(product.weiRaised()));
    }

    function refund(string _productName, address _buyerAddress) external onlyOwner validProductName(_productName) validAddress(_buyerAddress) {
        bool isRefund;
        uint256 refundAmount;
        (isRefund, refundAmount) = tokenDistributor.refund(buyers[_productName][_buyerAddress]);

        if(isRefund) {
            product.subWeiRaised(refundAmount);
            delete buyers[_productName][_buyerAddress];
        }
    }

    function buyerAddressTransfer(string _productName, address _from, address _to) external onlyOwner validProductName(_productName) validAddress(_from) validAddress(_to) {
        require(whiteList.whitelist(_from));
        require(whiteList.whitelist(_to));
        require(tokenDistributor.getAmount(buyers[_productName][_from]) > 0);
        require(tokenDistributor.getAmount(buyers[_productName][_to]) == 0);

        bool isChanged = tokenDistributor.buyerAddressTransfer(buyers[_productName][_from], _from, _to);

        require(isChanged);

        bytes32 fromId = buyers[_productName][_from];
        buyers[_productName][_to] = fromId;
        delete buyers[_productName][_from];

        emit BuyerAddressTransfer(_from, _to, buyers[_productName][_to]);
    }

    function withDrawEther() external onlyOwner {
        require(getState() == State.Finished);
        wallet.transfer(address(this).balance);
        emit WithdrawEther(wallet, address(this).balance);
    }

    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);
    event ChangeExternalAddress(address _addr, string _name);
    event BuyerAddressTransfer(address indexed _from, address indexed _to, bytes32 _id);
    event WithdrawEther(address indexed _from, uint256 _amount);
    event AddTest(bytes32 _id);

    event BuyerTest(address indexed _buyer, uint256 _amount);
}