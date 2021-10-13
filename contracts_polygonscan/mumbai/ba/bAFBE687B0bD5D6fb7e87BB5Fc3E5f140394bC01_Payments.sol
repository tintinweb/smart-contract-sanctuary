// SPDX-License-Identifier: MIT

/*
    Created by DeNet

    WARNING:
        This token includes fees for transfers, but no fees for ProofOfStorage.
        - Transfers may used only for tests. 
        - Transfers will removed in future versions.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./StorageToken.sol";
import "./PoSAdmin.sol";
import "./interfaces/IPayments.sol";


contract Payments is IPayments, Ownable, StorageToken, PoSAdmin {
    using SafeMath for uint256;

    uint256 private _tokensCount;
    address public oldPaymentAddress;
    uint256 private _autoMigrationTimeEnds = 0;

    // mapping (address =>  uint) public balances;

    constructor(
            address _address, 
            address _oldPaymentsAddress,
            string memory _tokenName,
            string memory _tokenSymbol,
            uint  _endTime
    ) PoSAdmin(_address) StorageToken(_tokenName, _tokenSymbol) {
        oldPaymentAddress = _oldPaymentsAddress;
        _autoMigrationTimeEnds = _endTime;
    }

    function canMigrate(address _user) public view returns (bool) {
        return IPayments(oldPaymentAddress).getBalance(DeNetFileToken, _user) > 0;
    }

    function migrateFromOldPayments(address _user) public {
        IPayments oldPay = IPayments(oldPaymentAddress);
        uint256 oldBalance = oldPay.getBalance(DeNetFileToken, _user);
         // do not revert if user have zero balance
        if (oldBalance > 0) {
           
            oldPay.localTransferFrom(DeNetFileToken,_user, address(this), oldBalance);
            oldPay.closeDeposit(address(this), DeNetFileToken);
            _mint(_user, _getDepositReturns(oldBalance));
            dfileBalance = dfileBalance.add(oldBalance);
        }
    }

    function getBalance(address _token, address _address) public override view returns (uint result) {
        return balanceOf(_address);
    }

    function localTransferFrom(address _token, address _from, address _to, uint _amount)  override public onlyPoS {
        if (block.timestamp <= _autoMigrationTimeEnds) {
            
            if (canMigrate(_from)) {
                migrateFromOldPayments(_from);
            }
            
            if (canMigrate(_to)) {
                migrateFromOldPayments(_to);
            }
        }
        require (_balances[_from]  >= _amount, "Not enough balance");
        require (0  <  _amount, "Amount < 0");
        
        _balances[_from] = _balances[_from].sub(_amount, "Not enough balance");
        _balances[_to] = _balances[_to].add(_amount);
        
        emit LocalTransferFrom(_token, _from, _to, _amount);
    }



    function depositToLocal(address _user_address, address _token, uint _amount)  override public onlyPoS{
        _depositByAddress(_user_address, _amount);
    }


    /**
        TODO:
            - add vesting/unlockable balance
     **/
    function closeDeposit(address _account, address _token) public override onlyPoS {
        _closeAllDeposiByAddresst(_account);
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IPayments {
    event LocalTransferFrom(
        address indexed _token,
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event RegisterToken(
        address indexed _token,
        uint256 indexed _id
    );

    function getBalance(address _token, address _address)
        external
        view
        returns (uint256 result);

    function localTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function depositToLocal(
        address _user_address,
        address _token,
        uint256 _amount
    ) external;

    function closeDeposit(address _user_address, address _token) external;
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    Contract is modifier only
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoSAdmin.sol";

contract PoSAdmin  is IPoSAdmin, Ownable {
    address public proofOfStorageAddress = address(0);
    
    constructor (address _pos) {
        proofOfStorageAddress = _pos;
    }

    modifier onlyPoS() {
        require(msg.sender == proofOfStorageAddress, "Access denied by PoS");
        _;
    }

    function changePoS(address _newAddress) public onlyOwner {
        proofOfStorageAddress = _newAddress;
        emit ChangePoSAddress(_newAddress);
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20Unsafe.sol";


import "./interfaces/IUserStorage.sol";
import "./interfaces/IPayments.sol";


/*
    @feeCollector - is cotnract created for getting some fees per storage actions.
    
    User Transfer Fee = 7% 
    User Payout Fee = 10%
    Local Transfer's - zeor or less than User Transfer Fee.

    where does the fees go:
        30% of fee goes to Govermance
        20% of fee goes to Dapp Market Fund
        10% of fee goes to Miners Funding 
        10% of fee goes to All storage Token Holders 
        10% of fee goes to Referal rewards 

    fees can be changed via Voting by DFILE Token
*/

contract feeCollector is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    
    /* 
        Fee in TB tokne works with Minting by Transaction and Payout operations
        
        Fee calcs  by amount * fee / div_fee
    */
    
    uint16 constant public div_fee = 10000;
    uint16 public transfer_fee = 350; // 3.5% by default always minting, no charging
    uint16 public payout_fee = 200;// 2% by default 
    uint16 public payin_fee = 200; // 2% by default
    uint16 public mint_percent = 5000; // 45% will minted by default if user exchange TB to DFILE,  50% will charded from user.
    uint16 private _mint_daily_limit_of_totalSupply = 100; // 0.1%
    
    
    address public recipient_fee = 0x3D71E8A1A1038623A2dEF831ABDF390897Eb1D77; // for testnet only
    uint256 public fee_limit = 100000000000000000000; // 100 TB 
    uint256 public fee_collected = 0;
     
    function _addFee(uint256 amount) internal  {
        require(amount > 0);
        fee_collected = fee_collected.add(amount);
    }
    
    function calc_transfer_fee(uint256 amount) public view returns(uint256) {
        return amount.mul(transfer_fee).div(div_fee);
    }
    
    function calc_payout_fee(uint256 amount) public  view returns(uint256){
        return amount.mul(payout_fee).div(div_fee);
    }
    
    function toFeeless(uint256 amount) public view returns(uint256) {
        return amount.div(div_fee.add(transfer_fee.mul(mint_percent).div(div_fee))).mul(div_fee);
    }
    function toFeelessPayout(uint256 amount) public view returns(uint256) {
        return amount.div(div_fee.add(payout_fee.mul(mint_percent).div(div_fee))).mul(div_fee);
    }
    
    function change_fee_limit(uint new_fee_limit) public onlyOwner {
        fee_limit = new_fee_limit;
    }
    function change_transfer_fee(uint16 new_fee) public onlyOwner {
        require(new_fee <= div_fee, "max fee limit exceeded");
        transfer_fee = new_fee;
    }
    function change_payout_fee(uint16 new_fee) public onlyOwner {
        require(new_fee <= div_fee, "max fee limit exceeded");
        payout_fee = new_fee;
    }
    function change_payin_fee(uint16 new_fee) public onlyOwner {
        require(new_fee <= div_fee, "max fee limit exceeded");
        payin_fee = new_fee;
    }
    function change_recipient_fee(address _new_recipient_fee) public onlyOwner {
        require(_new_recipient_fee != address(0), "wrong address");
        recipient_fee = _new_recipient_fee;
    }
    
}


contract StorageToken is  ERC20, Ownable, feeCollector{
    using SafeMath for uint256;
    using SafeMath for uint16;
    
    uint256 public dfileBalance = 30000000000000000000000; // for dfile 30000000000000000000000; // 300 DFILE per TB year start price
    address public DeNetFileToken = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;
    
    constructor (string memory name_, string memory symbol_)  ERC20(name_, symbol_) {
        _mint(recipient_fee, fee_limit); // mint start capital
    }
    
    // function toStorageDecimals(address _token, uint256 _amount) public view returns (uint256) {
    //     ERC20 selectedToken = ERC20(_token);
    //     uint _decimals = selectedToken.decimals();
    //     if (_decimals < decimals()) {
    //         return _amount.mul(10 ** (decimals() - _decimals));
    //     }
    //     return _amount.div(10 ** (_decimals - decimals()));
    // }

    // function toTokenDecimals(address _token, uint256 _amount) public view returns (uint256) {
    //     ERC20 selectedToken = ERC20(_token);
    //     uint _decimals = selectedToken.decimals();
    //     if (_decimals > decimals()) {
    //         return _amount.mul(10 ** (decimals() - _decimals));
    //     }
    //     return _amount.div(10 ** (_decimals - decimals()));
    // }

    // only for test
    function changeTokenAddress(address newAddress) public onlyOwner {
        DeNetFileToken = newAddress;
    }
    function _getDepositReturns(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "amount can't require 0 or zero");
         return totalSupply().mul(amount).div(dfileBalance).mul(div_fee.sub(payin_fee)).div(div_fee);
    }
    
    function _getWidthdrawithReturns(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "amount can't require 0 or zero");
        return dfileBalance.mul(amount).div(totalSupply());
    }
    function feelessBalance(address account) public view returns(uint256) {
        return _balances[account];
    }
    
    function getWidthdrawtReturns(uint256 amount) public view returns (uint256) {
        return _getWidthdrawithReturns(toFeelessPayout(amount));
    }
    
    
    /*
        returns amount of returnable Storage Token with Fees.
    */
    function getDepositRate(uint256 amount) public view  returns (uint256){
        return toFeeless(amount);
    }
    
 
    /*
        Function to Deposit DFILE
    */
    function _deposit(uint256 amount) internal {
        _depositByAddress(msg.sender, amount);
    }
    
    function _depositByAddress(address _account, uint256 amount) internal {
        IERC20 DFILEToken = IERC20(DeNetFileToken);
        require(DFILEToken.transferFrom(_account, address(this), amount), "Can't transfer from DFILE token");
        _mint(_account, _getDepositReturns(amount));
        dfileBalance = dfileBalance.add(amount);
    }

    function _updatePairTokenBalance() internal {
        IERC20 DFILEToken = IERC20(DeNetFileToken);
        dfileBalance = DFILEToken.balanceOf(address(this));
    }
    
    function  _closeAllDeposit() internal  {
        _closeAllDeposiByAddresst(msg.sender);
    }
    
    function  _closeAllDeposiByAddresst(address account) internal  {
        require(account != recipient_fee, "recipient_fee can't close deposit");
        
        IERC20 DFILEToken = IERC20(DeNetFileToken);
        uint256 account_balance_TB = feelessBalance(account);
        uint256 dfile_return = _getWidthdrawithReturns(account_balance_TB);
        dfileBalance = dfileBalance.sub(dfile_return);
        _burn(account, account_balance_TB);
        DFILEToken.transfer(account,dfile_return);
    }
    
    function _closePartOfDeposit(uint256 amount) internal {
        _closePartOfDepositByAddress(msg.sender, amount);
    }

    function _closePartOfDepositByAddress(address account, uint256 amount) internal {

        IERC20 DFILEToken = IERC20(DeNetFileToken);
        require(feelessBalance(account) >= amount, "Amount too big");
        uint256 dfile_return = _getWidthdrawithReturns(amount);
        dfileBalance = dfileBalance.sub(dfile_return);
        _burn(account, amount);
        DFILEToken.transfer(account, dfile_return);
        
    }
       
    /*
            Balance OF with fee collector changer 
            
            Balance = amount / (100% + fee percent)
            amount / (div fee  + payout_fee * mint_percent / div fee) * div fee
    */
    function balanceOf (address _user) public view override(ERC20) returns (uint256){
        return toFeeless(_balances[_user]);
    }
        
    function testMint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        _updatePairTokenBalance();
    }

    function testBurn(address to, uint256 amount) public onlyOwner {
        _burn(to, amount);
        _updatePairTokenBalance();
    }

    function distruct() public onlyOwner {
        _name = "Deleted";
        _symbol = "Deleted";
        IERC20 DFILE = IERC20(DeNetFileToken);
        DFILE.transfer(msg.sender, DFILE.balanceOf(address(this)));
        // require (fee_collected == 0, "fee is not zero");
        selfdestruct(payable(owner()));
    }
    
    function _collectFee()  internal virtual {
        if (fee_collected >= fee_limit) {
            _balances[address(this)] = _balances[address(this)].sub(fee_collected);
            _balances[recipient_fee] = _balances[recipient_fee].add(fee_collected);
            fee_collected = 0;
        }
    }
    function collect_by_admin() public onlyOwner {
        _balances[address(this)] = _balances[address(this)].sub(fee_collected);
        _balances[recipient_fee] = _balances[recipient_fee].add(fee_collected);
        fee_collected = 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        // if it simple transfer
        if (from != address(0) && to != address(0)) {
            require(amount <= balanceOf(from), "Not enought balance for transfer fee");
            uint256 total_fee = calc_transfer_fee(amount);
            uint256 minting_amount = total_fee.mul(mint_percent).div(div_fee);
            uint256 charged_fee = total_fee.sub(minting_amount);
            _mint(address(this), minting_amount);
            _balances[from] = _balances[from].sub(charged_fee);
            _balances[address(this)] = _balances[address(this)].add(charged_fee);
            _addFee(total_fee);
            _collectFee();
        } 
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IUserStorage {
    event ChangeRootHash(
        address indexed user_address,
        address indexed node_address,
        bytes32 new_root_hash
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event ChangePaymentMethod(
        address indexed user_address,
        address indexed token
    );

    function getUserPayToken(address _user_address)
        external
        view
        returns (address);

    function getUserLastBlockNumber(address _user_address)
        external
        view
        returns (uint32);

    function getUserRootHash(address _user_address)
        external
        view
        returns (bytes32, uint256);

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _nonce,
        address _updater
    ) external;

    function updateLastBlockNumber(address _user_address, uint32 _block_number) external;

    function setUserPlan(address _user_address, address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

interface IPoSAdmin {
    event ChangePoSAddress(
        address indexed newPoSAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}