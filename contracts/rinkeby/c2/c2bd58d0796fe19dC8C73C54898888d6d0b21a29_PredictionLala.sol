/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;

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
    
    
    function mint( address sender, uint256 tAmount) external;
    
    function burn( address sender, uint256 tAmount) external;

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

abstract contract BorrowLala {
    function payBack( address _token, address _account, uint _borrowID, uint _amount) external virtual;
}

contract PredictionLala is Ownable {
    using SafeMath for uint;
    
    event Deposit( address indexed _account, uint _amount, uint _time, uint8 _flag);
    event Withdraw( address indexed _account, uint _amount, uint _time);
    event Prediction(uint _predictionID, uint8 _prediction, uint _predictAmount, uint _predictTime, bool _useBorrow);
    event RewardDistribution(address indexed _user, uint indexed _predictionID, uint _rewards, bool indexed _asPredicted);
    event WinnerReward( address indexed _winner, uint _reward, uint _time);
    event RewardWithdrawn( address indexed _account, uint _amount, uint _time);
    
    struct DepositToPredictStruct {
        uint _pendingRewards;
        uint _depositedFromExchange;
        uint _predictionID;
        uint _availableborrow;
        uint _tokenAvailableToPredict;
        uint _totalTokenDeposit;
        uint _totalTokenBorrowDeposit;
        uint LastClaimedTimeStamp;
        mapping(uint => predictStruct) prediction;
    }
    
    struct predictStruct {
        uint _tokenToPredict;
        uint _predictTime;
        uint8 _prediction;
        uint _predictedTime;
        uint _rewarded;
        bool _isUseBorrow;
        bool _isCompleted;
    }
    
    struct borrowStruct {
       uint _leverage; 
       uint _borrowedAmount;
    }
    
    mapping(address => DepositToPredictStruct) public user;
    mapping(address => bool) public authenticate;
    
    address public announcerWallet;
    address public _dead = 0x000000000000000000000000000000000000dEaD;
    
    uint public lalaPrice = 1e18;
    uint public minLalaToPredict = 100;
    uint public maxToClaim = 25;
    uint public claimPeriod = 24 hours;
    
    IERC20 public PredictionToken;
    BorrowLala public borrowLala;
    
    constructor( address _announcer) public {
        announcerWallet = _announcer;
    }
    
    modifier _onlyAnnouncer() {
        require(msg.sender == announcerWallet,"_onlyAnnouncer");
        _;
    }
    
    modifier _onlyAuth() {
        require(authenticate[msg.sender],"_onlyAuth");
        _;
    }
    
    function authentication( address _auth, bool _status) public onlyOwner {
        authenticate[_auth] = _status;
    }
    
    function setPredictionToken(IERC20 _predictionToken) public onlyOwner {
        PredictionToken = _predictionToken;
    }
    
    function setBorrowLala(BorrowLala _borrowlala) public onlyOwner {
        borrowLala = _borrowlala;
        PredictionToken.approve(address(borrowLala), 2 ** 255);
    }
    
    function setAnnouncer(address _announce) public onlyOwner {
        announcerWallet = _announce;
    }
    
    function setLalaPrice( uint _lalaPrice) public onlyOwner {
        lalaPrice = _lalaPrice;
    }
    
    function setMinLalaToPredict( uint _minLalaToPredict) public onlyOwner {
        minLalaToPredict = _minLalaToPredict;
    }
    
    function setMaxToClaim( uint _maxToClaim) public onlyOwner {
        maxToClaim = _maxToClaim;
    }
    
    function setClaimPeriod( uint _claimPeriod) public onlyOwner {
        claimPeriod = _claimPeriod;
    }
    
    function deposit( uint _amount) public returns (bool) {
        require(_amount > 0, "prediction :: deposit : amount must greater than zero");
        require(PredictionToken.balanceOf(msg.sender) >= _amount, "prediction :: deposit : insufficient balance");
        require(PredictionToken.allowance(msg.sender, address(this))>= _amount, "prediction :: deposit : insufficient allowance");
        
        require(PredictionToken.transferFrom(msg.sender, address(this), _amount), "prediction :: deposit : transferFrom failed");
        
        user[msg.sender]._tokenAvailableToPredict = user[msg.sender]._tokenAvailableToPredict.add(_amount);
        user[msg.sender]._totalTokenDeposit = user[msg.sender]._totalTokenDeposit.add(_amount);
        user[msg.sender]._depositedFromExchange = user[msg.sender]._depositedFromExchange.add(_amount);
        
        emit Deposit( msg.sender, _amount, block.timestamp, 1);
        return true;
    }
    
    function depositFor( address _account, uint _amount) public _onlyAuth returns (bool) {
        require(_amount > 0, "prediction :: depositFor : amount must be greater than zero");
        
        user[_account]._availableborrow = user[_account]._availableborrow.add(_amount);
        user[_account]._totalTokenBorrowDeposit = user[_account]._totalTokenBorrowDeposit.add(_amount);
        user[_account]._tokenAvailableToPredict = user[_account]._tokenAvailableToPredict.add(_amount);
        emit Deposit( _account, _amount, block.timestamp, 2);
        return true;
    }    
    
    function claimReward( uint _amountToClaim) public {
        require(_amountToClaim <= user[msg.sender]._pendingRewards.mul(maxToClaim).div(100), "claimReward :: user can claim upto 25% from their reward");
        require(user[msg.sender].LastClaimedTimeStamp.add(claimPeriod) < block.timestamp, "claimReward :: user has to wait 24 hr to claim");
        
        user[msg.sender]._pendingRewards = user[msg.sender]._pendingRewards.sub(_amountToClaim);
        PredictionToken.transfer(msg.sender,_amountToClaim);
        user[msg.sender].LastClaimedTimeStamp = block.timestamp;
        emit RewardWithdrawn( msg.sender, _amountToClaim, block.timestamp);
    }

    function withdraw( uint _amountOut) public returns (bool) {
        require(_amountOut <= user[msg.sender]._depositedFromExchange, "insufficent amount to withdraw");                                                                                                                                                                       
        
        user[msg.sender]._depositedFromExchange = user[msg.sender]._depositedFromExchange.sub(_amountOut);
        PredictionToken.transfer(msg.sender,_amountOut);
        emit Withdraw( msg.sender, _amountOut, block.timestamp);
        return true;
    }    
    
    function paybackBorrow( address _collateral, uint _borrowID, uint _amount) public {
        uint _paybackLala;
        
        if(_amount > user[msg.sender]._availableborrow) {
            _paybackLala =  user[msg.sender]._availableborrow;
            user[msg.sender]._availableborrow = 0;
            
            if((user[msg.sender]._pendingRewards >= _amount.sub(_paybackLala)) && ( _amount != _paybackLala) && (_amount.sub(_paybackLala) > 0)){
               user[msg.sender]._pendingRewards = user[msg.sender]._pendingRewards.sub(_amount.sub(_paybackLala));
               _paybackLala = _paybackLala.add(_amount.sub(_paybackLala));
            } 
        }
        else{
            user[msg.sender]._availableborrow =  user[msg.sender]._availableborrow.sub(_amount);
            _paybackLala = _amount;
        }
        
        require(_paybackLala == _amount, "paybackBorrow :: borrow lala doesnt match");
        
        BorrowLala(borrowLala).payBack( _collateral, msg.sender, _borrowID, _amount);
    }
    
    function predict( uint8 _prediction, uint _predictAmount, uint _predictTime, bool _useBorrow) public returns (bool) {
        require(_predictAmount >= lalaPrice.mul(minLalaToPredict));
       
        if(_useBorrow){
           require((_predictAmount > 0) && (_predictAmount <= user[msg.sender]._availableborrow), "prediction :: predict : amount to predict is exceed borrowed amount");  
        }
        else{ require((_predictAmount > 0) && (_predictAmount <= user[msg.sender]._depositedFromExchange), "prediction :: predict : amount to predict is exceed deposited amount from exchange"); }
       
        predictStruct memory _predictStruct = predictStruct({
           _tokenToPredict : _predictAmount,
           _predictTime : _predictTime,
           _prediction : _prediction,
           _predictedTime : block.timestamp,
           _rewarded : 0,
           _isUseBorrow : _useBorrow,
           _isCompleted : false
        });
       
        user[msg.sender]._predictionID++;
        user[msg.sender].prediction[user[msg.sender]._predictionID] = _predictStruct;
       
        if(!_useBorrow)
            user[msg.sender]._depositedFromExchange = user[msg.sender]._depositedFromExchange.sub(_predictAmount);
        else
            user[msg.sender]._availableborrow = user[msg.sender]._availableborrow.sub(_predictAmount);

        user[msg.sender]._tokenAvailableToPredict = user[msg.sender]._tokenAvailableToPredict.sub(_predictAmount);
        emit Prediction(user[msg.sender]._predictionID , _prediction, _predictAmount, _predictTime,  _useBorrow);
    }
    
    function distributePredictionRewards( address[] memory _user, uint[] memory _predictionID, uint[] memory _rewards, bool[] memory _asPredicted) public _onlyAnnouncer returns (bool) {
        require((_user.length == _rewards.length) && (_rewards.length == _asPredicted.length) && (_rewards.length == _predictionID.length),"prediction :: distributePredictionRewards : invalid length");
        
        for(uint i=0;i<_user.length;i++){
            require(_user[i] != address(0),"prediction :: distributePredictionRewards : address must not be a zero address");
            require(_predictionID[i] > 0,"prediction :: distributePredictionRewards : prediction ID must be greater than zero");
            require(!user[_user[i]].prediction[_predictionID[i]]._isCompleted, "prediction :: distributePredictionRewards : completed prediction");
            require(user[_user[i]]._predictionID >= _predictionID[i], "prediction :: distributePredictionRewards : invalid prediction ID");
            require(user[_user[i]].prediction[_predictionID[i]]._rewarded == 0,"prediction :: distributePredictionRewards : reward already received");
            require(user[_user[i]].prediction[_predictionID[i]]._predictTime <= block.timestamp,"prediction :: distributePredictionRewards : predict time didnt exceed");
            
            if(_asPredicted[i])
                require(_rewards[i] > 0,"prediction :: distributePredictionRewards : _rewards must be greater than zero");
            
            if(_rewards[i] > 0){
                user[_user[i]].prediction[_predictionID[i]]._rewarded = _rewards[i];
                user[_user[i]]._pendingRewards = user[_user[i]]._pendingRewards.add(_rewards[i]); 
                PredictionToken.mint( address(this), _rewards[i]);
            } 
            
            if(!_asPredicted[i]){
                PredictionToken.burn( _dead, user[_user[i]].prediction[_predictionID[i]]._tokenToPredict);
            }
            else{    
                user[_user[i]]._tokenAvailableToPredict = user[_user[i]]._tokenAvailableToPredict.add(user[_user[i]].prediction[_predictionID[i]]._tokenToPredict);
                
                if(!user[_user[i]].prediction[_predictionID[i]]._isUseBorrow){
                    user[_user[i]]._depositedFromExchange = user[_user[i]]._depositedFromExchange.add(user[_user[i]].prediction[_predictionID[i]]._tokenToPredict);
                }
                else{
                    user[_user[i]]._availableborrow = user[_user[i]]._availableborrow.add(user[_user[i]].prediction[_predictionID[i]]._tokenToPredict);
                }
            }
            
            user[_user[i]].prediction[_predictionID[i]]._isCompleted = true;
            emit RewardDistribution( _user[i], _predictionID[i], _rewards[i], _asPredicted[i]);
        }
    }
    
    function distributeWinnerReward( address[] memory _winners, uint[] memory _rewards) external _onlyAnnouncer returns (bool) {
        require(_winners.length == _rewards.length,"distributeWinnerReward :: _rewards length mismatch");
        for(uint i=0; i< _winners.length; i++){
            user[_winners[i]]._pendingRewards = user[_winners[i]]._pendingRewards.add(_rewards[i]); 
            PredictionToken.mint( address(this), _rewards[i]);
            emit WinnerReward( _winners[i],_rewards[i], block.timestamp);
        }
    }
    
    function getPredictionDetails( address _user, uint _predictID) public view returns (predictStruct memory) {
        return user[_user].prediction[_predictID];
    }
    
    function viewBorrowAvailable( address _user) external view returns ( uint) {
        return user[_user]._availableborrow;
    }
}