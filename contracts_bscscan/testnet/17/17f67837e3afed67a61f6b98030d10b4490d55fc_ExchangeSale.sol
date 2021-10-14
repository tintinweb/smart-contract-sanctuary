/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity ^0.6.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Exchange.sol

// File: contracts/ExchangeContract.sol




interface Nftn721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenTransfer(address from, address to, uint256 tokenId) external returns (bool);
    function _mint(address to, uint256 tokenId, string calldata uri) external returns (bool);
    function setApprovalForAll(address from, address to, bool approved, uint256 tokenId) external returns (bool);
    function _burn(uint256 tokenId, address from) external returns (bool);
    function _transferOwnership(address newOwner) external returns (bool);
}

interface Nftn1155{
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external returns (bool);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function setApprovalForAll(address from, address _operator, bool _approved) external returns (bool);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function mint(address from, uint256 _id, uint256 _supply, string calldata _uri) external;
    function burn(address from, uint256 _id, uint256 _value) external returns (bool);
    function _transferOwnership(address newOwner) external returns(bool);
}

interface BEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ExchangeSale is Initializable, OwnableUpgradeSafe{
    event CancelOrder(address indexed from, uint256 indexed tokenId);
    event ChangePrice(address indexed from, uint256 indexed tokenId, uint256 indexed value);
    event OrderPlace(address indexed from, uint256 indexed tokenId, uint256 indexed value);
    event FeeDetails(uint256 indexed owner, uint256 indexed admin, uint256 indexed admin2);
    event Calcu(uint256 indexed owner, uint256 indexed admin, uint256 indexed admin2);
    event FeeDiv(uint256 indexed owner, uint256 indexed admin, uint256 indexed admin2);
    using SafeMath for uint256;
    struct Order{
        uint256 tokenId;
        uint256 price;
    }
     struct Royalty{
        uint256 tokenId;
        address[] royaltyaddress;
        uint[] percentage;
        uint royaltypercentage;
    }

    uint public totalroyalty;
    uint256 public tokenCount;
    address public ownerWallet;
    uint256 public serviceValue;
    mapping (uint256 => uint256) public totalQuantity;
    mapping (uint256 => Royalty) public RoyaltyInfo;
    mapping (address => mapping (uint256 => Order)) public order_place;
    mapping (uint256 => mapping (address => bool)) public checkOrder;
    mapping (uint256 =>  bool) public _operatorApprovals;
    mapping (uint256 => address) public _creator;
    mapping (uint256 => uint256) public _royal;
    mapping (uint256 => mapping(address => uint256)) public balances;

    // function initialize(uint256 _serviceValue,uint256 totalVal) public initializer {
    //     serviceValue = _serviceValue;
    //     totalroyalty = totalVal;
    //     __Context_init_unchained();
    //    __Ownable_init_unchained();
    // }

    constructor(uint256 _serviceValue,uint256 totalVal) public{
       serviceValue = _serviceValue;
       totalroyalty = totalVal;
    }

    function _orderPlace(address from, uint256 tokenId, uint256 _price) internal{
        require( balances[tokenId][from] > 0, "Is Not a Owner");
        Order memory order;
        order.tokenId = tokenId;
        order.price = _price;
        order_place[from][tokenId] = order;
        checkOrder[tokenId][from] = true;
        emit OrderPlace(from, tokenId, _price);
    }
    function _cancelOrder(address from, uint256 tokenId) internal{
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        delete order_place[msg.sender][tokenId];
        checkOrder[tokenId][from] = false;
        emit CancelOrder(msg.sender, tokenId);
    }
    function _changePrice(uint256 value, uint256 tokenId) internal{
        require( balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        require( value < order_place[msg.sender][tokenId].price);
        order_place[msg.sender][tokenId].price = value;
        emit ChangePrice(msg.sender, tokenId, value);
    }
    function _acceptBId(address token,address from, address admin,  uint tokenprice, uint256 tokenId) internal{
        require(_operatorApprovals[tokenId], "Token Not approved");
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        (uint256 _adminfee, uint256 netamount) = calc(tokenprice, totalroyalty, serviceValue);
        BEP20 t = BEP20(token);
         uint256 totalFee = _adminfee.mul(2);
        t.transferFrom(from,admin,totalFee);
       // uint256 totalPrice = tokenprice.sub(_adminfee);
        payforRoyaltyToken(tokenprice, tokenId,from, token);
        t.transferFrom(from,msg.sender,netamount);
    }
    function checkTokenApproval(uint256 tokenId, address from) internal view returns (bool result){
        require(checkOrder[tokenId][from], "This Token Not for Sale");
        require(_operatorApprovals[tokenId], "Token Not approved");
        return true;
    }
    function _saleToken(address payable from, address payable admin,uint256 tokenId, uint256 amount , uint256 tokenprice) internal{
        require(amount> order_place[from][tokenId].price , "Insufficent found");
        require(checkTokenApproval(tokenId, from));
       // address payable create = address(uint160(_creator[tokenId]));
       (uint256 _adminfee, uint256 netamount) = calc(tokenprice, totalroyalty, serviceValue);
       uint256 totalFee = _adminfee.mul(2);
        admin.transfer(totalFee);
        //uint256 totalPrice = tokenprice.sub(_adminfee);
        payforRoyalty(tokenprice, tokenId);
        from.transfer(netamount);
    }
     function payforRoyalty(uint originalamount, uint tokenId) internal {

        for(uint i=0;i<RoyaltyInfo[tokenId].royaltyaddress.length;i++){
             address payable payAddress = address(uint160(RoyaltyInfo[tokenId].royaltyaddress[i]));
             uint256 roy = originalamount.mul(RoyaltyInfo[tokenId].percentage[i]).div(1000000);
             payAddress.transfer(roy);
        }

    }
     function payforRoyaltyToken(uint originalamount, uint tokenId, address from, address token) internal {

        BEP20 trnasferToken = BEP20(token);

        for(uint i=0;i<RoyaltyInfo[tokenId].royaltyaddress.length;i++){
             address payable payAddress = address(uint160(RoyaltyInfo[tokenId].royaltyaddress[i]));
             uint256 roy = originalamount.mul(RoyaltyInfo[tokenId].percentage[i]).div(1000000);
             trnasferToken.transferFrom(from,payAddress,roy);
        }

    }
    function calc(uint256 tokenprice, uint256 royal, uint256 _serviceValue) internal pure returns(uint256, uint256){
        uint256 fee = percent(tokenprice, _serviceValue.div(10));
        uint256 roy = percent(tokenprice, royal);
        uint256 netamount = tokenprice.sub(roy);
        uint256 netamountlast = netamount.sub(fee);
        return (fee, netamountlast);
    }

    function percent(uint256 value1, uint256 value2) internal pure returns(uint256){
        uint256 result = value1.mul(value2).div(100);
        return(result);
    }
    function setServiceValue(uint256 _serviceValue) internal{
        serviceValue = _serviceValue;
    }

     function serviceFunction(uint256 _serviceValue) public onlyOwner{
        setServiceValue(_serviceValue);
    }

    function transferOwnershipForColle(address newOwner, address token721, address token1155) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        Nftn721 tok= Nftn721(token721);
        Nftn1155 tok1155= Nftn1155(token1155);
        tok._transferOwnership(newOwner);
        tok1155._transferOwnership(newOwner);
    }
    function mint(address token ,string memory tokenuri, uint256 value, uint256 tokenId, uint256 _type, uint256 supply, address[] memory royaltyaddr, uint256[] memory royaltypercentage) public{
       require(_creator[tokenId] == address(0), "Token Already Minted");
          require(royaltyaddr.length > 0 && royaltypercentage.length > 0 && royaltyaddr.length ==royaltypercentage.length, 'Invalid royalty list');

        uint256 checkPercentage;
        for(uint c=0;c<royaltypercentage.length;c++){
        uint256 Percentage = royaltypercentage[c];
        checkPercentage +=Percentage;
        }
        require(((checkPercentage)/10000)==totalroyalty, 'Invalid royalty percentage');
        Royalty memory royalty;
        royalty = Royalty({
            tokenId: tokenId,
            royaltypercentage:totalroyalty,
            royaltyaddress : new address[](0),
            percentage:new uint256[](0)
        });
        RoyaltyInfo[tokenId] = royalty;
        for(uint i = 0; i < royaltyaddr.length; i++) {
            RoyaltyInfo[tokenId].royaltyaddress.push(royaltyaddr[i]);
            RoyaltyInfo[tokenId].percentage.push(royaltypercentage[i]);
        }

       if(_type == 721){
           Nftn721 tok= Nftn721(token);
           _creator[tokenId]=msg.sender;
           tok._mint(msg.sender, tokenId, tokenuri);
           balances[tokenId][msg.sender] = supply;
           if(value != 0){
                _orderPlace(msg.sender, tokenId, value);
            }
        }
        else{
            Nftn1155 tok = Nftn1155(token);
            tok.mint(msg.sender, tokenId, supply, tokenuri);
            _creator[tokenId]=msg.sender;
            balances[tokenId][msg.sender] = supply;
            if(value != 0){
                _orderPlace(msg.sender, tokenId, value);
            }
       }
       totalQuantity[tokenId] = supply;
       tokenCount++;

    }

    function setApprovalForAll(address token, uint256 _type, bool approved, uint256 tokenId) public {
        _operatorApprovals[tokenId] = true;
        if(_type == 721){
            Nftn721 tok= Nftn721(token);
            tok.setApprovalForAll(msg.sender, address(this),approved,tokenId);
        }
        else{
            Nftn1155 tok = Nftn1155(token);
            tok.setApprovalForAll(msg.sender, address(this), approved);
        }
    }
    function saleToken(address payable from, address payable admin,uint256 tokenId, uint256 amount,uint256 tokenprice, address token, uint256 _type, uint256 NOFToken) public payable{
       _saleToken(from, admin, tokenId, amount, tokenprice);
       if(_type == 721){
           Nftn721 tok= Nftn721(token);
            if(checkOrder[tokenId][from]==true){
                delete order_place[from][tokenId];
                checkOrder[tokenId][from] = false;
            }
           tok.tokenTransfer(from, msg.sender, tokenId);
           balances[tokenId][from] = balances[tokenId][from] - NOFToken;
           balances[tokenId][msg.sender] = NOFToken;
       }
       else{
            Nftn1155 tok= Nftn1155(token);
            tok.safeTransferFrom(from, msg.sender, tokenId, NOFToken);
            balances[tokenId][from] = balances[tokenId][from] - NOFToken;
            balances[tokenId][msg.sender] = balances[tokenId][msg.sender] + NOFToken;
            if(checkOrder[tokenId][from] == true){
                if(balances[tokenId][from] == 0){
                    delete order_place[from][tokenId];
                    checkOrder[tokenId][from] = false;
                }
            }

       }


    }
    function acceptBId(address bittoken,address from, address admin, uint256 tokenprice, uint256 tokenId, address token, uint256 _type, uint256 NOFToken) public{
        _acceptBId(bittoken, from, admin, tokenprice, tokenId);
        if(_type == 721){
           Nftn721 tok= Nftn721(token);
           if(checkOrder[tokenId][msg.sender]==true){
                delete order_place[msg.sender][tokenId];
                checkOrder[tokenId][msg.sender] = false;
           }
           tok.tokenTransfer(msg.sender, from, tokenId);
           balances[tokenId][msg.sender] = balances[tokenId][msg.sender] - NOFToken;
           balances[tokenId][from] = NOFToken;
        }
        else{
            Nftn1155 tok= Nftn1155(token);
            tok.safeTransferFrom(msg.sender, from, tokenId, NOFToken);
            balances[tokenId][from] = balances[tokenId][from] + NOFToken;
            balances[tokenId][msg.sender] = balances[tokenId][msg.sender] - NOFToken;
            if(checkOrder[tokenId][msg.sender] == true){
                if(balances[tokenId][msg.sender] == 0){
                    delete order_place[msg.sender][tokenId];
                    checkOrder[tokenId][msg.sender] = false;
                }
            }

        }
    }
    function orderPlace(uint256 tokenId, uint256 _price) public{
        _orderPlace(msg.sender, tokenId, _price);
    }
    function cancelOrder(uint256 tokenId) public{
        _cancelOrder(msg.sender, tokenId);
    }
    function changePrice(uint256 value, uint256 tokenId) public{
        _changePrice(value, tokenId);
    }

     function changeroyaltypercentage(uint256 percentage) external onlyOwner {

        totalroyalty =percentage;
    }
    function Royaltyaddress(uint tokenId) public view returns(address[5] memory List) {
         for (uint i = 0; i<RoyaltyInfo[tokenId].royaltyaddress.length; i++) {
            List[i] =RoyaltyInfo[tokenId].royaltyaddress[i];
         }
    }
    function Royaltypercentage(uint tokenId) public view returns(uint[5] memory List) {
         for (uint i = 0; i<RoyaltyInfo[tokenId].royaltyaddress.length; i++) {
            List[i] =RoyaltyInfo[tokenId].percentage[i];
         }
    }

    function burn(address from, uint256 tokenId, address token, uint256 _type, uint256 NOFToken ) public{
        require( balances[tokenId][msg.sender] >= NOFToken || msg.sender == owner(), "Your Not a Token Owner or insuficient Token Balance");
        require( balances[tokenId][from] >= NOFToken, "Your Not a Token Owner or insuficient Token Balance");
        require( _operatorApprovals[tokenId], "Token Not approved");
        if(_type == 721){
            Nftn721 tok= Nftn721(token);
            tok._burn(tokenId, from);
            balances[tokenId][from] = balances[tokenId][from].sub(NOFToken);
            if(checkOrder[tokenId][from]==true){
                delete order_place[from][tokenId];
                checkOrder[tokenId][from] = false;
            }
        }
        else{
            Nftn1155 tok= Nftn1155(token);
            tok.burn(from, tokenId, NOFToken);
            if(balances[tokenId][from] == NOFToken){
                if(checkOrder[tokenId][from]==true){
                    delete order_place[from][tokenId];
                    checkOrder[tokenId][from] = false;
                }

            }
            balances[tokenId][from] = balances[tokenId][from].sub(NOFToken);

        }
        if(totalQuantity[tokenId] == NOFToken){
             _operatorApprovals[tokenId] = false;
             delete _creator[tokenId];
             delete _royal[tokenId];
        }
        totalQuantity[tokenId] = totalQuantity[tokenId].sub(NOFToken);

    }

}