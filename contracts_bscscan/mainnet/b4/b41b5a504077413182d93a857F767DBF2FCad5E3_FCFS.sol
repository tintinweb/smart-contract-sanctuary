/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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



contract  FCFS is  Ownable
{
    using SafeMath for uint256;
    uint public totalTokens=250000000 * 10**18;
    uint public preSalePrice = 16949200000000 ;
    uint public icoPrice = 16949200000000 ;
    uint public preSaleMinQuantity=33250* 10**18;
    uint public preSaleMaxQuantity=665000* 10**18;
    uint private priceQuantity;
    uint private quantity20per;
    uint private quantity80per;
    address public Owner;
    bool public isPreSalePaused = true;
    bool public isIcoPaused=true;
    IBEP20 private bep;
    struct SpecificAddresses{
        
        
        address userAddress;
        uint sentTokens;
        uint pendingTokens;
    }
    
    mapping(address => SpecificAddresses) private _whiteList;
    mapping(address=>bool) public _addressExist;  

    constructor()  {
        
       bep =  IBEP20(0xe0910BC6BbF79e1Fb3046c1B733A4cbdfFBE1Da6);
       
        
    }
   

    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
       icoPrice = _newPrice;
    }
    function setPreSalePrice(uint256 _newPrice) public onlyOwner() {
       preSalePrice = _newPrice;
    }
    function setMinMaxQuantity(uint256 minQ, uint256 maxQ) public onlyOwner() {
       preSaleMinQuantity = minQ;
        preSaleMaxQuantity = maxQ;
    }

    function flipPreSalePauseStatus() public onlyOwner {
        isPreSalePaused = !isPreSalePaused;
    }
    function flipIcoPauseStatus() public onlyOwner {
        isIcoPaused = !isIcoPaused;
    }
    function getPreSalePrice(uint256 _quantity) public view returns (uint256) {
           return _quantity*preSalePrice ;
     }
    function getIcoPrice(uint256 _quantity) public view returns (uint256) {
           return _quantity*icoPrice ;
     }
    

        function addWhiteListBundle(address[] memory whiteAddress)public onlyOwner {
            for (uint i = 0; i < whiteAddress.length; i++)
            {
        require(!_addressExist[whiteAddress[i]],"Address already Exist");
        _whiteList[whiteAddress[i]]=SpecificAddresses({
            userAddress :whiteAddress[i],
            sentTokens:0,
            pendingTokens:0
           });
           _addressExist[whiteAddress[i]]=true;
    }
        }
    
    function preSale(uint256 _quantity) public payable
    {
        require(isPreSalePaused == false, "Sale is not active at the moment");
        _quantity=_quantity*10**18;
        require(_quantity>=preSaleMinQuantity,"quantity is less than minimum price");
        require(_quantity<=preSaleMaxQuantity,"quantity is greater than maximum price");
        priceQuantity=_quantity/1000000000000000000;
        require(preSalePrice.mul(priceQuantity) == msg.value, "Sent bnb value is incorrect");
        require(_quantity<=totalTokens,"quantity is greater than remaining amount of tokens");
        quantity20per=_quantity*20/100;
        quantity80per=_quantity*80/100;
        SpecificAddresses storage myaddress = _whiteList[msg.sender];
        require(_addressExist[msg.sender]==true,"Address not exist in WhiteList");
        bep.transferFrom(owner(),msg.sender,quantity20per);
        myaddress.userAddress=msg.sender;
        myaddress.sentTokens=quantity20per/1000000000000000000;
        myaddress.pendingTokens=quantity80per/1000000000000000000;
        quantity20per=0;
        quantity80per=0;
        totalTokens-=_quantity;
       
    }
    
    function buyRmp(uint256 _quantity) public payable
    {
        require(isIcoPaused == false, "Sale is not active at the moment");
        require(_quantity>0,"quantity is less than zero");
        require(icoPrice.mul(_quantity) == msg.value, "Sent bnb value is incorrect");
         _quantity=_quantity*10**18;
        require(_quantity<=totalTokens,"quantity is greater than remaining amount of tokens");
        quantity20per=_quantity*20/100;
        quantity80per=_quantity*80/100;
        SpecificAddresses storage myaddress = _whiteList[msg.sender];
        bep.transferFrom(owner(),msg.sender,quantity20per);
        myaddress.userAddress=msg.sender;
        myaddress.sentTokens=quantity20per/1000000000000000000;
        myaddress.pendingTokens=quantity80per/1000000000000000000;
        quantity20per=0;
        quantity80per=0;
        totalTokens-=_quantity;
    }

    function pendingTransfer(address _reciever, uint amount) public onlyOwner
    {
        
        SpecificAddresses storage myaddress = _whiteList[_reciever];
        require(amount<=myaddress.pendingTokens,"pending token is less than amount");
        amount=amount*10**18;
        bep.transferFrom(msg.sender,_reciever,amount);
        amount=amount/1000000000000000000;
        myaddress.sentTokens+=amount;
        myaddress.pendingTokens-=amount;
    }
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
}