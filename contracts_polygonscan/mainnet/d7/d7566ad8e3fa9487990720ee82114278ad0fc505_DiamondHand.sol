/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

pragma solidity ^0.6.12;

 

// SPDX-License-Identifier: Unlicensed

 

interface IBEP20 {

    /**

     * @dev Returns the amount of tokens in existence.

     */

    function totalSupply() external view returns (uint256);

 

    /**

     * @dev Returns the token decimals.

     */

    function decimals() external view returns (uint8);

 

    /**

     * @dev Returns the token symbol.

     */

    function symbol() external view returns (string memory);

 

    /**

     * @dev Returns the token name.

     */

    function name() external view returns (string memory);

 

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

    function transfer(address recipient, uint256 amount)

        external

        returns (bool);

 

    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through {transferFrom}. This is

     * zero by default.

     *

     * This value changes when {approve} or {transferFrom} are called.

     */

    function allowance(address _owner, address spender)

        external

        view

        returns (uint256);

 

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

    event Approval(

        address indexed owner,

        address indexed spender,

        uint256 value

    );

}

 

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

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying

    // an instance of this contract, which should be used via inheritance.

    constructor() internal {}

 

    function _msgSender() internal view returns (address payable) {

        return msg.sender;

    }

 

    function _msgData() internal view returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

}

 

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

    function sub(

        uint256 a,

        uint256 b,

        string memory errorMessage

    ) internal pure returns (uint256) {

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

    function div(

        uint256 a,

        uint256 b,

        string memory errorMessage

    ) internal pure returns (uint256) {

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

    function mod(

        uint256 a,

        uint256 b,

        string memory errorMessage

    ) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}

 

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

contract Ownable is Context {

    address private _owner;

    address private _previousOwner;

    uint256 private _lockTime;

 

 

    event OwnershipTransferred(

        address indexed previousOwner,

        address indexed newOwner

    );

 

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor() internal {

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

    function renounceOwnership() public onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }

 

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {

        _transferOwnership(newOwner);

    }

 

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     */

    function _transferOwnership(address newOwner) internal {

        require(

            newOwner != address(0),

            "Ownable: new owner is the zero address"

        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

        function getUnlockTime() public view returns (uint256) {

        return _lockTime;

    }

   

    //Added function

    // 1 minute = 60

    // 1h 3600

    // 24h 86400

    // 1w 604800

   

    function getTime() public view returns (uint256) {

        return now;

    }

 

    function lock(uint256 time) public virtual onlyOwner {

        _previousOwner = _owner;

        _owner = address(0);

        _lockTime = now + time;

        emit OwnershipTransferred(_owner, address(0));

    }

   

    function unlock() public virtual {

        require(_previousOwner == msg.sender, "You don't have permission to unlock");

        require(now > _lockTime , "Contract is locked until 7 days");

        emit OwnershipTransferred(_owner, _previousOwner);

        _owner = _previousOwner;

    }

 

}

 

 

contract DiamondHand is Context, IBEP20, Ownable {

    using SafeMath for uint256;

 

    mapping(address => uint256) private _rOwned;

    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

 

    mapping(address => bool) private _isExcludedFromFee;

 

    address[] private _excluded;

 

    uint256 private constant MAX = ~uint256(0);

    bool inSwapAndLiquify;

    uint256 private constant _tTotal = 100 * 10**9 * 10**9;

    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;

    uint256 public _taxFee = 1;

    uint256 public _previousTaxFee = _taxFee;

    uint256 public _maxTxAmount = 1 * 10**9 * 10**9;

    uint256 public _maxWalletToken = 5 * 10**9 * 10**9;

 

 

    string private _name = " DiamondHand ";

    string private _symbol = "DHand";

    uint8 private _decimals = 9;

    uint256 public _start_timestamp = block.timestamp;

 

   

    function setStartTime(uint256 start) public onlyOwner {

        _start_timestamp = start;

    }

   

    function setFee(uint256 taxFee) public onlyOwner {

        _taxFee = taxFee;

 

    }

   

    function setMaxTxAmount(uint256 setMaxTx) public onlyOwner {

        _maxTxAmount = setMaxTx;

    }

   

    function setMaxWalletAmount(uint256 setMaxWallet) public onlyOwner {

        _maxWalletToken = setMaxWallet;

    }

   

    constructor() public {

        _rOwned[_msgSender()] = _rTotal;

        _isExcludedFromFee[owner()] = true;

        _isExcludedFromFee[address(this)] = true;

 

        emit Transfer(address(0), _msgSender(), _tTotal);

    }

 

 

    function name() public view override returns (string memory) {

        return _name;

    }

 

    function symbol() public view override returns (string memory) {

        return _symbol;

    }

 

    function decimals() public view override returns (uint8) {

        return _decimals;

    }

 

    function totalSupply() public view override returns (uint256) {

        return _tTotal;

    }

 

    function balanceOf(address account) public view override returns (uint256) {

        return tokenFromReflection(_rOwned[account]);

    }

 

    function transfer(address recipient, uint256 amount)

        public

        override

        returns (bool)

    {

        _transfer(_msgSender(), recipient, amount);

        return true;

    }

 

    function allowance(address owner, address spender)

        public

        view

        override

        returns (uint256)

    {

        return _allowances[owner][spender];

    }

 

    function approve(address spender, uint256 amount)

        public

        override

        returns (bool)

    {

        _approve(_msgSender(), spender, amount);

        return true;

    }

 

    function transferFrom(

        address sender,

        address recipient,

        uint256 amount

    ) public override returns (bool) {

        _transfer(sender, recipient, amount);

        _approve(

            sender,

            _msgSender(),

            _allowances[sender][_msgSender()].sub(

                amount,

                "ERC20: transfer amount exceeds allowance"

            )

        );

        return true;

    }

 

    function increaseAllowance(address spender, uint256 addedValue)

        public

        virtual

        returns (bool)

    {

        _approve(

            _msgSender(),

            spender,

            _allowances[_msgSender()][spender].add(addedValue)

        );

        return true;

    }

 

    function decreaseAllowance(address spender, uint256 subtractedValue)

        public

        virtual

        returns (bool)

    {

        _approve(

            _msgSender(),

            spender,

            _allowances[_msgSender()][spender].sub(

                subtractedValue,

                "ERC20: decreased allowance below zero"

            )

        );

        return true;

    }

 

    function totalFees() public view returns (uint256) {

        return _tFeeTotal;

    }

 

    function reflect(uint256 tAmount) public {

        address sender = _msgSender();

        (uint256 rAmount, , , ,) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rTotal = _rTotal.sub(rAmount);

        _tFeeTotal = _tFeeTotal.add(tAmount);

    }

 

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)

        public

        view

        returns (uint256)

    {

        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {

            (uint256 rAmount, , , ,) = _getValues(tAmount);

            return rAmount;

        } else {

            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);

            return rTransferAmount;

        }

    }

 

    function tokenFromReflection(uint256 rAmount)

        public

        view

        returns (uint256)

    {

        require(

            rAmount <= _rTotal,

            "Amount must be less than total reflections"

        );

        uint256 currentRate = _getRate();

        return rAmount.div(currentRate);

    }

 

    function _approve(

        address owner,

        address spender,

        uint256 amount

    ) private {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

 

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }

 

    function removeAllFee() private {

        if (_taxFee == 0) return;

 

        _previousTaxFee = _taxFee;

  

 

        _taxFee = 0;

 

    }

 

    function restoreAllFee() private {

        _taxFee = _previousTaxFee;

  

    }

   

    function excludeFromFee(address account) public onlyOwner {

        _isExcludedFromFee[account] = true;

    }

 

    function _transfer(

        address sender,

        address recipient,

        uint256 amount

    ) private {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(amount > 0, "Transfer amount must be greater than zero");

        if (

            sender != owner() &&

            recipient != owner() &&

            recipient != address(1)) {

            require(

                amount <= _maxTxAmount,

                "Transfer amount exceeds the maxTxAmount."

            );

            uint256 contractBalanceRecepient = balanceOf(recipient);

            require(

                contractBalanceRecepient + amount <= _maxWalletToken,

                "Exceeds maximum wallet token amount (100,000,000)"

            );

        }

 

        // is the token balance of this contract address over the min number of

        // tokens that we need to initiate a swap + liquidity lock?

        // also, don't get caught in a circular liquidity event.

        // also, don't swap & liquify if sender is uniswap pair.

        uint256 contractTokenBalance = balanceOf(address(this));

 

        if (contractTokenBalance >= _maxTxAmount) {

            contractTokenBalance = _maxTxAmount;

        }

 

 

        bool takeFee = true;

 

        //if any account belongs to _isExcludedFromFee account then remove the fee

        if (

            _isExcludedFromFee[sender] ||

            _isExcludedFromFee[recipient]

        ) {

            takeFee = false;

        }

 

        if (!takeFee) removeAllFee();

 

        _transferStandard(sender, recipient, amount);

 

        if (!takeFee) restoreAllFee();

    }

 

    function _transferStandard(

        address sender,

        address recipient,

        uint256 tAmount

    ) private {

        (

            uint256 rAmount,

            uint256 rTransferAmount,

            uint256 rFee,

            uint256 tTransferAmount,

            uint256 tFee

        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }

 

    function _reflectFee(uint256 rFee, uint256 tFee) private {

        _rTotal = _rTotal.sub(rFee);

        _tFeeTotal = _tFeeTotal.add(tFee);

    }

 

    function _getValues(uint256 tAmount)

        private

        view

        returns (

            uint256,

            uint256,

            uint256,

            uint256,

            uint256

        )

    {

        (uint256 tTransferAmount, uint256 tFee) =

            _getTValues(tAmount);

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =

            _getRValues(tAmount, tFee, _getRate());

        return (

            rAmount,

            rTransferAmount,

            rFee,

            tTransferAmount,

            tFee

        );

    }

 
    function _getAntiDumpMultiplier() private view returns (uint256) {

        uint256 time_since_start = block.timestamp - _start_timestamp;

        uint256 day = 60 * 60 * 24;

        if (time_since_start < 1 * day) {

            return (99);

        } else if (time_since_start < 2 * day) {

            return (98);

        } else if (time_since_start < 3 * day) {

            return (97);

        } else if (time_since_start < 4 * day) {

            return (96);

        } else if (time_since_start < 5 * day) {

            return (95);

        } else if (time_since_start < 6 * day) {

            return (94);

        } else if (time_since_start < 7 * day) {

            return (93);

        } else if (time_since_start < 8 * day) {

            return (92);

        } else if (time_since_start < 9 * day) {

            return (91);

        } else if (time_since_start < 10 * day) {

            return (90);
        } else if (time_since_start < 11 * day) {

            return (89);
        } else if (time_since_start < 12 * day) {

            return (88);
        } else if (time_since_start < 13 * day) {

            return (87);
        } else if (time_since_start < 14 * day) {

            return (86);
        } else if (time_since_start < 15 * day) {

            return (85);
        } else if (time_since_start < 16 * day) {

            return (84);
        } else if (time_since_start < 17* day) {

            return (83);

        } else if (time_since_start < 18 * day) {

            return (82);

        } else if (time_since_start < 19 * day) {

            return (81);

        } else if (time_since_start < 20 * day) {

            return (80);

        } else if (time_since_start < 21 * day) {

            return (79);

        } else if (time_since_start < 22 * day) {

            return (78);

        } else if (time_since_start < 23 * day) {

            return (77);

        } else if (time_since_start < 24 * day) {

            return (76);
        } else if (time_since_start < 25 * day) {

            return (75);
        } else if (time_since_start < 26 * day) {

            return (74);
        } else if (time_since_start < 27 * day) {

            return (73);
        } else if (time_since_start < 28 * day) {

            return (72);
        } else if (time_since_start < 29 * day) {

            return (71);
        } else if (time_since_start < 30 * day) {

            return (70);
        } else if (time_since_start < 31 * day) {

            return (69);

        } else if (time_since_start < 32 * day) {

            return (68);

        } else if (time_since_start < 33 * day) {

            return (67);

        } else if (time_since_start < 34 * day) {

            return (66);

        } else if (time_since_start < 35 * day) {

            return (65);

        } else if (time_since_start < 36 * day) {

            return (64);

        } else if (time_since_start < 37 * day) {

            return (63);

        } else if (time_since_start < 38 * day) {

            return (62);
        } else if (time_since_start < 39 * day) {

            return (61);
        } else if (time_since_start < 40 * day) {

            return (60);
        } else if (time_since_start < 41 * day) {

            return (59);
        } else if (time_since_start < 42 * day) {

            return (58);
        } else if (time_since_start < 43 * day) {

            return (57);
        } else if (time_since_start < 44 * day) {

            return (56);
        } else if (time_since_start < 45 * day) {

            return (55);

        } else if (time_since_start < 46 * day) {

            return (54);

        } else if (time_since_start < 47 * day) {

            return (53);

        } else if (time_since_start < 48 * day) {

            return (52);

        } else if (time_since_start < 49 * day) {

            return (51);

        } else if (time_since_start < 50 * day) {

            return (50);

        } else if (time_since_start < 51 * day) {

            return (49);

        } else if (time_since_start < 52 * day) {

            return (48);
        } else if (time_since_start < 53 * day) {

            return (47);
        } else if (time_since_start < 54 * day) {

            return (46);
        } else if (time_since_start < 55 * day) {

            return (45);
        } else if (time_since_start < 56 * day) {

            return (44);
        } else if (time_since_start < 57 * day) {

            return (43);
        } else if (time_since_start < 58 * day) {

            return (42);

        } else if (time_since_start < 59 * day) {

            return (41);

        } else if (time_since_start < 60 * day) {

            return (40);

        } else if (time_since_start < 61 * day) {

            return (39);

        } else if (time_since_start < 62 * day) {

            return (38);

        } else if (time_since_start < 63 * day) {

            return (37);

        } else if (time_since_start < 64 * day) {

            return (36);

        } else if (time_since_start < 65 * day) {

            return (35);

        } else if (time_since_start < 66 * day) {

            return (34);

        } else if (time_since_start < 67 * day) {

            return (33);
        } else if (time_since_start < 68 * day) {

            return (32);
        } else if (time_since_start < 69 * day) {

            return (31);
        } else if (time_since_start < 70 * day) {

            return (30);
        } else if (time_since_start < 71 * day) {

            return (29);
        } else if (time_since_start < 72 * day) {

            return (28);
        } else if (time_since_start < 73 * day) {

            return (27);
        } else if (time_since_start < 74* day) {

            return (26);

        } else if (time_since_start < 75 * day) {

            return (25);

        } else if (time_since_start < 76 * day) {

            return (24);

        } else if (time_since_start < 77 * day) {

            return (23);

        } else if (time_since_start < 78 * day) {

            return (22);

        } else if (time_since_start < 78 * day) {

            return (21);

        } else if (time_since_start < 80 * day) {

            return (20);

        } else if (time_since_start < 81 * day) {

            return (19);
        } else if (time_since_start < 82 * day) {

            return (18);
        } else if (time_since_start < 83 * day) {

            return (17);
        } else if (time_since_start < 84 * day) {

            return (16);
        } else if (time_since_start < 85 * day) {

            return (15);
        } else if (time_since_start < 86 * day) {

            return (14);
        } else if (time_since_start < 87 * day) {

            return (13);
        } else if (time_since_start < 88 * day) {

            return (12);

        } else if (time_since_start < 89 * day) {

            return (11);

        } else if (time_since_start < 90 * day) {

            return (10);

        } else if (time_since_start < 91 * day) {

            return (9);

        } else if (time_since_start < 92 * day) {

            return (8);

        } else if (time_since_start < 93 * day) {

            return (7);

        } else if (time_since_start < 94 * day) {

            return (6);

        } else if (time_since_start < 95 * day) {

            return (5);
        } else if (time_since_start < 96 * day) {

            return (4);
        } else if (time_since_start < 97 * day) {

            return (3);
        } else if (time_since_start < 98 * day) {

            return (2);
        } else if (time_since_start < 99 * day) {

            return (1);
 
        } else {

            return (0);

        }
    }

 

    function _getTValues(uint256 tAmount)

        private

        view

        returns (

            uint256,

            uint256

        )

    {

        uint256 multiplier = _getAntiDumpMultiplier();

        uint256 tFee = tAmount.div(10**2).mul(_taxFee).mul(multiplier);

 

        uint256 tTransferAmount = tAmount.sub(tFee);

        return (tTransferAmount, tFee);

    }

 

    function _getRValues(

        uint256 tAmount,

        uint256 tFee,

        uint256 currentRate

    )

        private

        pure

        returns (

            uint256,

            uint256,

            uint256

        )

    {

        uint256 rAmount = tAmount.mul(currentRate);

        uint256 rFee = tFee.mul(currentRate);

        uint256 rTransferAmount = rAmount.sub(rFee);

        return (rAmount, rTransferAmount, rFee);

    }

 

    function _getRate() private view returns (uint256) {

        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);

    }

 

    function _getCurrentSupply() private view returns (uint256, uint256) {

        uint256 rSupply = _rTotal;

        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (

                _rOwned[_excluded[i]] > rSupply ||

                _tOwned[_excluded[i]] > tSupply

            ) return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);

            tSupply = tSupply.sub(_tOwned[_excluded[i]]);

        }

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (rSupply, tSupply);

    }

 

    function _takeLiquidity(uint256 tLiquidity) private {

        uint256 currentRate = _getRate();

        uint256 rLiquidity = tLiquidity.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);

    }

 

    receive() external payable {}

}