/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

interface IERC20 {

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
    
    
    function mint(address to, uint amount) external;
    
    function burn( address _account, uint amount) external;

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
 
library SafeMath {
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface PredictionLala {
    function depositFor( address _account, uint _amount) external returns (bool);
    function updateLiquidateLala( address _account, uint _amount) external;
    function updateLiquidatedBrorrowLala( address _account, uint _amount) external;
    function viewBorrowAvailable( address _user) external view returns ( uint);
}

contract BorrowLala is Ownable {
    using SafeMath for uint;
    
    // Event logs
    event Borrow( address indexed _vault, address indexed _token, uint _collateral, uint _borrowed, uint indexed _borrowID, uint _borrowTime);
    event Payback( address indexed _vault, address indexed _token, uint _paybackToken, uint _collateral, uint _borrowTime);
    
    IERC20 public lala;
    PredictionLala public PredictionCon;
    
    struct token {
        uint _tokenPrice;
        uint _decimals;
        bool _isActive;
    }
    
    struct Vault {
        uint _borrowed;
        mapping(address => borrows)  _borrow;
    }
    
    struct borrows {
        uint borrowID;
        uint pastBorrowID;
        uint pastBorrows;
        uint pastLalaBorrows;
        uint recentBorrows;
        mapping(uint => borrowListStruct) listOfBorrows;
    }
    
    struct borrowListStruct{
        uint borrows;
        uint lalaBorrows;
        uint pastBorrowTime;
        bool isExpired;
    }
    
    mapping(address => token) public getToken;
    mapping(address => Vault) public vault;
    
    address public predictionContract;
    address[] public tokenList;
    
    address liquidateWallet;
    address public _dead = 0x000000000000000000000000000000000000dEaD;
    
    uint public estimatedLoop = 10; 
    uint public borrowTimeStamp = 7 days;
    
    constructor(PredictionLala _predictionContract, address _liquidateWallet) public {
        PredictionCon = _predictionContract;
        liquidateWallet = _liquidateWallet;
    }
    
    function setlala(IERC20 _lala) public onlyOwner { lala = _lala; }
    
    function updateLoopEstimation( uint _esLp) public onlyOwner { estimatedLoop = _esLp; }
    
    function updateBorrowTimeStamp( uint _borrowTimeStamp) public onlyOwner { borrowTimeStamp = _borrowTimeStamp; }
    
    function updatePrediction( PredictionLala _predict) public onlyOwner { PredictionCon = _predict; }
    
    function addToken( address _token, uint _decimal, uint _price) public onlyOwner {
        require(_price > 0, "lendingAndBorrow :: addToken : Price must be greater than zero");
        require(!getToken[_token]._isActive, "lendingAndBorrow :: addToken : Token already activated");
        require((_decimal >= 0) && (_decimal <= 18), "lendingAndBorrow :: addToken : decimals must be inbetween 0 to 18");
        
        getToken[_token] = token(_price,(10**(_decimal)),true);
        tokenList.push(_token);
    }
    
    function updateTokenPrice(address _token, uint _price) public onlyOwner {
        require(_price > 0, "lendingAndBorrow :: updateCollateralPrice : Price must be greater than zero");
        require(getToken[_token]._isActive, "lendingAndBupdateCollateralPriceorrow :: updateCollateralPrice : Token is not activated");
        
        getToken[_token]._tokenPrice = _price;
    }
    
    function borrow( address _token, uint _value, uint _leverage, bool _withUpdate) public payable {
        require(getToken[_token]._isActive, "lendingAndBorrow :: borrow : Token is not activated");
        require(_leverage <= 125, "lendingAndBorrow :: borrow : leverage must be between 1 to 125");
        
        if(_token == address(0)) { require((msg.value > 0) && (msg.value == _value), "lendingAndBorrow :: borrow : value must be equal to msg.value and msg.value must be greater than zero"); }
        else{
            require(IERC20(_token).balanceOf(msg.sender) > _value, "lendingAndBorrow :: borrow : insufficient balance");
            require(IERC20(_token).allowance(msg.sender, address(this)) >= _value, "lendingAndBorrow :: borrow : insufficient allowance");
            require(IERC20(_token).transferFrom(msg.sender, address(this), _value), "lendingAndBorrow :: borrow : transferFrom failed");
        }
        
        uint _borrow = cumulativePrice(_token, _value);
        _borrow = _borrow.add(cumulativePrice(_token, _value.mul(30).div(100))); // 30% more on investment
        
        if(_leverage >= 1)
            _borrow = _borrow.add(_borrow.mul(_leverage).div(100));
        
        lala.mint( address(PredictionCon), _borrow);
        PredictionCon.depositFor( msg.sender, _borrow);
        
        vault[msg.sender]._borrowed = vault[msg.sender]._borrowed.add(_borrow);
        
        if(_withUpdate) { updateTokenVaults( msg.sender,_token); }// With update. 
        
        vault[msg.sender]._borrow[_token].borrowID++;
        
        uint _collateralFee = _value.div(100);
        
        vault[msg.sender]._borrow[_token].listOfBorrows[vault[msg.sender]._borrow[_token].borrowID] = borrowListStruct(_value.sub(_collateralFee), _borrow, block.timestamp, false);
        vault[msg.sender]._borrow[_token].recentBorrows = vault[msg.sender]._borrow[_token].recentBorrows.add(_value.sub(_collateralFee));
        
        if(_token == address(0)) require(payable(liquidateWallet).send(_collateralFee), "borrow: _collateralFee transfer failed");
        else
            IERC20(_token).transfer(liquidateWallet,_collateralFee);
        
        emit Borrow( msg.sender, _token, _value, _borrow, vault[msg.sender]._borrow[_token].borrowID, block.timestamp);
    }
    
    function payBack( address _token, address _account, uint _borrowID, uint _amount) external {
        require(vault[_account]._borrow[_token].borrowID >= _borrowID);
        require(vault[_account]._borrow[_token].listOfBorrows[_borrowID].lalaBorrows > 0, "lendingAndBorrow :: payBack : borrow amount already paybacked");
        
        updateTokenVaults( _account,_token);
        
        require(vault[_account]._borrow[_token].recentBorrows > 0, "lendingAndBorrow :: payBack : There is no recent borrows to payback");
        require(_amount == vault[_account]._borrow[_token].listOfBorrows[_borrowID].lalaBorrows, "lendingAndBorrow :: payBack : payBack amount doesnot match");
        require(!vault[_account]._borrow[_token].listOfBorrows[_borrowID].isExpired, "lendingAndBorrow :: payBack : payback period ends");
        
        lala.transferFrom(msg.sender, _dead, _amount);
        
        uint _amountOut = vault[_account]._borrow[_token].listOfBorrows[_borrowID].borrows;
         uint _deduction;
         
        if(_amountOut > 0){
            _deduction = _amountOut.mul(3).div(100);
            if(_token == address(0)){
                require(payable(_account).send(_amountOut.sub(_deduction)), "lendingAndBorrow :: payBack : value send failed");
                require(payable(liquidateWallet).send(_deduction), "lendingAndBorrow :: payBack : payback commission value send failed");
            }
            else{
                require(IERC20(_token).transfer(_account,_amountOut.sub(_deduction)), "lendingAndBorrow :: payBack : Token transfer failed");
                require(IERC20(_token).transfer(liquidateWallet,_deduction), "lendingAndBorrow :: payBack : payback commission Token transfer failed");
            }
            
            vault[_account]._borrow[_token].listOfBorrows[_borrowID].lalaBorrows = 0;
            vault[_account]._borrow[_token].recentBorrows = vault[_account]._borrow[_token].recentBorrows.sub(_amount);
        }
        else{
            revert("lendingAndBorrow :: payBack : collateral returns zero");
        }
        
        emit Payback( _account, _token, _amount, _amountOut.sub(_deduction), block.timestamp);
    }
    
    function updateTokenVaults(address _vault, address _token) public returns (bool) {
        if((vault[_vault]._borrow[_token].borrowID > 0) && (vault[_vault]._borrow[_token].pastBorrowID < vault[_vault]._borrow[_token].borrowID)){
            uint _workUntill = vault[_vault]._borrow[_token].borrowID;
            uint _start = vault[_vault]._borrow[_token].pastBorrowID;
            if(vault[_vault]._borrow[_token].borrowID.sub(vault[_vault]._borrow[_token].pastBorrowID) > estimatedLoop) _workUntill = vault[_vault]._borrow[_token].pastBorrowID.add(estimatedLoop);
            
            _start = (vault[_vault]._borrow[_token].pastBorrowID == 0) ? 1 : vault[_vault]._borrow[_token].pastBorrowID;
            
            for(uint i=_start;i <= _workUntill;i++){
                if((vault[_vault]._borrow[_token].listOfBorrows[i].pastBorrowTime.add(borrowTimeStamp) < block.timestamp) && (vault[_vault]._borrow[_token].listOfBorrows[i].pastBorrowTime != 0)){
                    if(vault[_vault]._borrow[_token].listOfBorrows[i].borrows > 0){
                        vault[_vault]._borrow[_token].pastLalaBorrows = vault[_vault]._borrow[_token].pastLalaBorrows.add(vault[_vault]._borrow[_token].listOfBorrows[i].lalaBorrows);
                        vault[_vault]._borrow[_token].recentBorrows = vault[_vault]._borrow[_token].recentBorrows.sub(vault[_vault]._borrow[_token].listOfBorrows[i].borrows);
                        vault[_vault]._borrow[_token].pastBorrows = vault[_vault]._borrow[_token].pastBorrows.add(vault[_vault]._borrow[_token].listOfBorrows[i].borrows);
                        vault[_vault]._borrow[_token].listOfBorrows[i].isExpired = true;
                    }
                }
                else break;
                
                vault[_vault]._borrow[_token].pastBorrowID++;
            }
        }
        
        return true;
    }
    
    function liquidateVault( address _vault, address _token) public {
        if(updateTokenVaults( _vault, _token)){
            if(vault[_vault]._borrow[_token].pastBorrows > 0){
                uint _amount = vault[_vault]._borrow[_token].pastBorrows;
                vault[_vault]._borrow[_token].pastBorrows = 0;
                liquidate(_token, _amount);
            }
        }
    }
    
    function liquidate(address _token, uint _amount) internal returns (bool) {
        address _contract = address(this);
        
        if(_token == address(0)){
            if(_contract.balance < _amount) { return false; }
            require(payable(liquidateWallet).send(_amount), "lendingAndBorrow :: liquidate : value send failed");
        }
        else{
            if(IERC20(_token).balanceOf(_contract) < _amount) { return false; }
            require(IERC20(_token).transfer(liquidateWallet,_amount), "lendingAndBorrow :: liquidate : Token transfer failed");
        }
        
        return true;
    }
    
    function cumulativePrice( address _token, uint _amountIn) public view returns (uint){
          return _amountIn.mul(1e18).div(getToken[_token]._tokenPrice);
    }
    
    function cumulativePaybackPrice( address _token, uint _amountIn) public view returns (uint){
          uint _price = _amountIn.mul(1e12).mul(getToken[_token]._tokenPrice).div(1e18);
          return _price.div(1e12);
    }
    
    function getUserCurrentBorrowID( address _vault, address _token) public view returns (uint) {
        return vault[_vault]._borrow[_token].borrowID;
    }
    
    function getBorrowDetails( address _vault, address _token, uint _borrowID) public view returns ( uint pastBorrowID, uint pastBorrows, uint recentBorrows, uint borrowed, uint pastBorrowTime, bool _isexpired) {
        (pastBorrowID, pastBorrows, recentBorrows, borrowed, pastBorrowTime, _isexpired) = (
            vault[_vault]._borrow[_token].pastBorrowID,
            vault[_vault]._borrow[_token].pastBorrows,
            vault[_vault]._borrow[_token].recentBorrows,
            vault[_vault]._borrow[_token].listOfBorrows[_borrowID].borrows,
            vault[_vault]._borrow[_token].listOfBorrows[_borrowID].pastBorrowTime,
            vault[_vault]._borrow[_token].listOfBorrows[_borrowID].isExpired);
    }
}