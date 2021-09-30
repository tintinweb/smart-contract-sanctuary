/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

/**
 * CinemaDraft Token
 *
 * author: Solulab Inc. - Umang Ajmera
 * 
 * This is a rewrite of Safemoon contract in the hope to:
 *
 * - make it easier to change the tokenomics
 * - make it easier to maintain the code and develop it further
 * - remove redundant code
 * - fix some of the issues reported in the Safemoon audit
 *      https://www.certik.org/projects/safemoon
 *
 * SPDX-License-Identifier: UNLICENSED
 */
 
pragma solidity 0.8.0;

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
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b; }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) { uint256 size; assembly { size := extcodesize(account) } return size > 0;}
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "Only the previous owner can unlock onwership");
        require(block.timestamp > _lockTime , "The contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

abstract contract Manageable is Context {

    address private _manager;

    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    constructor(){
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    function manager() public view returns(address){ return _manager; }

    modifier onlyManager(){
        require(_manager == _msgSender(), "Manageable: caller is not the manager");
        _;
    }

    function transferManagement(address newManager) external virtual onlyManager {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }

}

/**
 * ****************************************
 *
 * Tokenomics:
 * 
 * Token Name   - CinemaDraft Token
 * Token Symbol - CD3D
 * Token Supply - 100M (Million)
 *
 * Token Distribution:
 *
 *  ICO                    20M (20%)
 *  Dead                   40M (40%)
 *  Team                   2M  (2%) 
 *  Marketing              10M (10%)
 *  Liquidity              20M (20%)
 *  Community Jackpot Fund 8M  (8%)
 *
 * ****************************************
 * 
 * Transaction Fee - 10%
 *
 * Transaction Fee Breakdown:
 *
 *  Dividends              6.0%
 *      CinemaDraft            15%
 *      Holders                75%
 *      Community Rewards      7%
 *      Staking Rewards        3%
 * Burn                    2.4%
 * Buyback & Burn          1.6%
 *
 * ****************************************
 *
 * Anti-Dumping Fee     - 15% on token sale
 * Anti-Whale Mechanism - 0.15% of total token supply
 * 
 * ****************************************
 */

/**
 * 
 * If you wish to disable a particular tax/fee just set it to zero (or comment it out/remove it).
 * 
 * You can add (in theory) as many custom taxes/fees with dedicated wallet addresses if you want. 
 * Nevertheless, I do not recommend using more than a few as the contract has not been tested 
 * for more than the original number of taxes/fees, which is 4 (redistribution, burn, 
 * company and community). Furthermore, exchanges may impose a limit on the total
 * transaction fee (so that, for example, you cannot claim 100%). Usually this is done by limiting the 
 * max value of slippage, for example, PancakeSwap max slippage is 49.9% and the fees total of more than
 * 35% will most likely fail there.
 * 
 * NOTE: You shouldn't really remove the Rfi fee. If you do not wish to use RFI for your token, 
 * you shouldn't be using this contract at all (you're just wasting gas if you do).
 *
 */
abstract contract Tokenomics {
    
    using SafeMath for uint256;
    
    // --------------------- Token Settings ------------------- //

    string internal constant NAME = "CinemaDraft Token";
    string internal constant SYMBOL = "CD3D";
    
    uint16 internal constant FEES_DIVISOR = 10**4;
    uint8 internal constant DECIMALS = 9;
    uint256 internal constant ZEROES = 10**DECIMALS;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 100 * 10**6 * ZEROES; // 100 Million i.e. 100 * 10**6
    uint256 internal _reflectedSupply = (MAX - (MAX % TOTAL_SUPPLY));

    /**
     * @dev Set the maximum transaction amount allowed in a transfer.
     * 
     * The default value is 0.15% of the total supply. 
     * 
     * NOTE: set the value to `TOTAL_SUPPLY` to have an unlimited max, i.e.
     * `maxTransactionAmount = TOTAL_SUPPLY;`
     */
    uint256 internal constant maxTransactionAmount = TOTAL_SUPPLY * 15 / FEES_DIVISOR;

    // --------------------- Fees Settings ------------------- //
    
    /**
     * @dev The anti-dumping fees will be charged after ICO.
     * This fee is differenct from the transaction fees of 1o%. This fee is charged only 
     * when the token is being sold on any external third-party application. The benefit
     * of this fee is shared among all the token holders and this fee also indirectly incentivize 
     * holders to not sell. Also, after deducting this fee, the remaining amount will be used for
     * calculating the 10% fee and the remaining will finally be transferred to the recipient.
     *
     * For Example: If a user sells 100 tokens on Pancake Swap. The following will happen:
     * Anti-dumping     - Deduct 15% of 100 tokens  - remaining quantity 85.0
     * Transaction fees - Deduct 10 %  of 85 tokens - remaining quantity 76.5
     * This remaining quantity of 76.5 will be sold on the Pancake Swap.
     * 
     * The default value is 15% of the transaction amount.
     * 
     * NOTE: The maximum transaction amount will however be checked first to maintain anti-whale
     * mechanism.
     * 
    */
    uint256 internal constant antiDumpingFees = 1500;

    /**
     * @dev To add/edit/remove fees scroll down to the `addFees` function below
     */
    address internal burnAddress = 0x000000000000000000000000000000000000dEaD;
    address internal cinemaDraftWalletAddress = 0x74A892AA1fc6c8C44018cDd16a597fb7151195d8;
    address internal communityJackpotAddress = 0x841eE81FF407Ba5504e103D15D8028116391810d;
    address internal stakingRewardsWalletAddress = 0xaFA6058126D8f48d49A9A4b127ef7e27C5e1DC43;

    enum FeeType { Rfi, Burn, CinemaDraft, CommunityJackpot, StakingRewards }
    
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }
    Fee[] public fees;
    
    uint256 private sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(FeeType name, uint256 value, address recipient) private {
        fees.push( Fee(name, value, recipient, 0 ) );
        sumOfFees += value;
    }

    function _addFees() private {

        /**
         * The RFI recipient is ignored but we need to give a valid address value
         *
         * CAUTION: If you don't want to use RFI this implementation isn't really for you!
         *      There are much more efficient and cleaner token contracts without RFI 
         *      so you should use one of those
         *
         * The value of fees is given in part per 10,000 (based on the value of FEES_DIVISOR),
         * e.g. for 4% use 400, for 0.42% use 42, etc. 
         */ 
        _addFee(FeeType.Rfi, 450, address(this)); 

        _addFee(FeeType.Burn, 400, burnAddress);
        _addFee(FeeType.CinemaDraft, 90, cinemaDraftWalletAddress);
        _addFee(FeeType.CommunityJackpot, 42, communityJackpotAddress);
        _addFee(FeeType.StakingRewards, 18, stakingRewardsWalletAddress);

    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns(Fee storage){
        require( index >= 0 && index < fees.length, "FeesSettings._getFeeStruct: Fee index out of bounds");
        return fees[index];
    }
    
    function _getFee(uint256 index) internal view returns (FeeType, uint256, address, uint256){
        Fee memory fee = _getFeeStruct(index);
        return ( fee.name, fee.value, fee.recipient, fee.total );
    }
    
    function getFeeTotal() internal view returns (uint256) {
        return sumOfFees;
    }
    
    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    function getCollectedFeeTotal(uint256 index) internal view returns (uint256){
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
    
}

/**
 * The fee tokenomics start after the token auction. To achive this, a "isInPresale" flag is used.
 * As soon as the auction ends, the contract manager can set this value to false. This will start 
 * fee deduction as per as per the tokenomics mentioned above.
*/
abstract contract Presaleable is Manageable {
    
    bool public isInPresale = false;
    
    function setPresaleableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}

/**
 * This is the modified version of Safemoon contract.
 * For a modular approach, multiple inheritance is used.
 *
 * @dev This contract implements only the reflection logic as used in deflationary tokens. You can 
 * refer to Reflect Finance at 'https://github.com/reflectfinance'. All the other functionalties
 * as per the business logic of our application have been implemented in the "CinemaDraftToken"
 * contract. 
 */
abstract contract ReflectionToken is IBEP20, Ownable, Presaleable, Tokenomics {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;
    
    mapping (address => bool) internal _isIncludedInAntiDumping;

    mapping (address => bool) internal _isUnlimitedSenderOrRecipient;
    
    constructor() {
        
        _reflectedBalances[owner()] = _reflectedSupply;
        
        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
        
        // set owner and staking rewards wallet as unlimited sender/recipient
        _isUnlimitedSenderOrRecipient[owner()] = true;

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
        
    }
    
    /** Functions required by IBEP20 **/
        
        function name() external pure override returns (string memory) {
            return NAME;
        }
        
        function symbol() external pure override returns (string memory) {
            return SYMBOL;
        }
        
        function decimals() external pure override returns (uint8) {
            return DECIMALS;
        }
        
        function totalSupply() external pure override returns (uint256) {
            return TOTAL_SUPPLY;
        }
        
        function getOwner() external view override returns (address) {
            return owner();
        }
        
        function balanceOf(address account) public view override returns (uint256){
            if (_isExcludedFromRewards[account]) return _balances[account];
            return tokenFromReflection(_reflectedBalances[account]);
        }
        
        function transfer(address recipient, uint256 amount) external override returns (bool){
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        
        function allowance(address owner, address spender) external view override returns (uint256){
            return _allowances[owner][spender];
        }
    
        function approve(address spender, uint256 amount) external override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }
        
        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
    /** Functions required by IBEP20 - END **/

    /**
     * @dev this is really a "soft" burn (total supply is not reduced). RFI holders
     * get two benefits from burning tokens:
     *
     * 1) Tokens in the burn address increase the % of tokens held by holders not
     *    excluded from rewards
     * 2) Tokens in the burn address cannot be sold (which in turn causes deflation)
     *
     *
     * In RFI holders already get % of each transaction so the value of their tokens 
     * increases (in a way). Therefore there is really no need to do a "hard" burn 
     * (reduce the total supply). What matters (in RFI) is to make sure that a large
     * amount of tokens cannot be sold = increasing the intrinsic value of tokens.
     * For this purpose, transfering tokens to a (vanity) burn address is the
     * most appropriate way to "burn". 
     *
     * There is an extra check placed into the `transfer` function to make sure the
     * burn address cannot withdraw the tokens is has (although the chance of someone
     * having/finding the private key is virtually zero).
     */
    function burn(uint256 amount) external {

        address sender = _msgSender();
        require(sender != address(0), "ReflectionToken: burn from the zero address");
        require(sender != address(burnAddress), "ReflectionToken: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "ReflectionToken: burn amount exceeds balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(reflectedAmount);
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens( sender, amount, reflectedAmount );
    }
    
    /**
     * @dev "Soft" burns the specified amount of tokens by sending them 
     * to the burn address
     */
    function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */ 
        _reflectedBalances[burnAddress] = _reflectedBalances[burnAddress].add(rBurn);
        if (_isExcludedFromRewards[burnAddress])
            _balances[burnAddress] = _balances[burnAddress].add(tBurn);

        /**
         * @dev Emit the event so that the burn address balance is updated (on bscscan)
         */
        emit Transfer(sender, burnAddress, tBurn);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Calculates and returns the reflected amount for the given amount with or without 
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= TOTAL_SUPPLY, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, getFeeTotal());
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcludedFromRewards[account], "Account is already excluded from rewards");
        _exclude(account);
    }
    
    function _exclude(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }
    
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }    

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromRewards[account], "Account is already included in rewards");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function setExcludedFromFee(address account, bool value) external onlyOwner {
        _isExcludedFromFee[account] = value;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) { 
        return _isExcludedFromFee[account];
    }
    
    function includeInAntiDumping(address _address, bool value) external onlyOwner {
        _isIncludedInAntiDumping[_address] = value;
        _exclude(_address);
    }
    
    function isIncludedInAntiDumping(address _address) public view returns (bool) {
        return _isIncludedInAntiDumping[_address];
    }
    
    function setIsUnlimitedSenderOrRecipient(address account, bool value) external onlyOwner {
        require(isInPresale, "ReflectionToken: Address can be initialized only during the pre-sale.");
        _isUnlimitedSenderOrRecipient[account] = value;
        _isExcludedFromFee[account];
    }
    
    function isUnlimitedSenderOrRecipient(address account) internal view returns (bool) {
        return _isUnlimitedSenderOrRecipient[account];
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ReflectionToken: approve from the zero address");
        require(spender != address(0), "ReflectionToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ReflectionToken: transfer from the zero address");
        require(recipient != address(0), "ReflectionToken: transfer to the zero address");
        require(sender != address(burnAddress), "ReflectionToken: transfer from the burn address");
        require(amount > 0, "ReflectionToken: Transfer amount must be greater than zero");
        
        // indicates whether or not fee should be deducted from the transfer
        bool takeFee = true;
        
        // holds the fees value as per recipient address, used for anti-dumping mechanism
        uint256 sumOfFees = getFeeTotal();

        if ( isInPresale ) { takeFee = false; }
        else {
            /**
            * Check the amount is within the max allowed limit as long as a
            * unlimited sender/recepient is not involved in the transaction
            */
            if ( amount > maxTransactionAmount && !isUnlimitedSenderOrRecipient(sender) && !isUnlimitedSenderOrRecipient(recipient) ) {
                revert("ReflectionToken: Transfer amount exceeds the maxTxAmount as per anti-whale protocol");
            }
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { takeFee = false; }

        // if the transaction is being performed on third-party application, take anti-dumping fee
        if(_isIncludedInAntiDumping[recipient]) {
            sumOfFees = getFeeTotal().add(antiDumpingFees);
        }
        _transferTokens(sender, recipient, amount, takeFee, sumOfFees);
        
    }

    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee, uint256 sumOfFees) private {
    
        // We don't need to know anything about the individual fees here 
        // (like Safemoon does with `_getValues`). What is required 
        // for transfer is the sum of all fees to calculate the % of the total 
        // transaction amount which should be transferred to the recipient. 
        //
        // The `_takeFees` call will/should take care of the individual fees
         
        // uint256 sumOfFees = getFeeTotal();
        if ( !takeFee ) { sumOfFees = 0; }
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);
        
        /** 
         * Sender's and Recipient's reflected balances must be always updated regardless of
         * whether they are excluded from rewards or not.
         */ 
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);

        /**
         * Update the true/nominal balances for excluded accounts
         */        
        if (_isExcludedFromRewards[sender]) { _balances[sender] = _balances[sender].sub(tAmount); }
        if (_isExcludedFromRewards[recipient] ) { _balances[recipient] = _balances[recipient].add(tTransferAmount); }
        
        _takeFees( amount, currentRate, sumOfFees );
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees ) private {
        if ( sumOfFees > 0 && !isInPresale ) {
            if ( sumOfFees == (getFeeTotal().add(antiDumpingFees)) ) {
                _takeTransactionFees(amount.mul(sumOfFees).div(FEES_DIVISOR).mul(10), currentRate);
            } else {
                _takeTransactionFees(amount, currentRate);   
            }
        }
    }
    
    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = TOTAL_SUPPLY;  

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply) return (_reflectedSupply, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(TOTAL_SUPPLY)) return (_reflectedSupply, TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }
    
    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`. 
     * This is the bit of clever math which allows rfi to redistribute the fee without 
     * having to iterate through all holders. 
     * 
     * Visit our discord at https://discord.gg/dAmr6eUTpM
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        _addFeeCollectedAmount(index, tFee);
    }
    
    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(uint256 amount, uint256 currentRate) internal virtual;

}

contract CinemaDraftToken is ReflectionToken {

    using SafeMath for uint256;

    function _takeTransactionFees(uint256 amount, uint256 currentRate) internal override {
        
        if( isInPresale ) { return; }

        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++ ) {
            (FeeType name, uint256 value, address recipient,) = _getFee(index);
            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if ( value == 0 ) continue;

            if ( name == FeeType.Rfi ) {
                _redistribute( amount, currentRate, value, index );
            }
            else if ( name == FeeType.Burn ) {
                _burn( amount, currentRate, value, index );
            }
            else if ( name == FeeType.CinemaDraft) {
                _takeFee( amount, currentRate, value, recipient, index );
            }
            else if (name == FeeType.StakingRewards) {
                _takeFee( amount, currentRate, value, recipient, index );
            }
            else { // Fees to CommunityJackpot
                _takeFee( amount, currentRate, value, recipient, index );
            }
        }
    }

    function _burn(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) private {
        uint256 tBurn = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rBurn = tBurn.mul(currentRate);

        _burnTokens(address(this), tBurn, rBurn);
        _addFeeCollectedAmount(index, tBurn);
    }

    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient, uint256 index) private {

        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        _addFeeCollectedAmount(index, tAmount);
    }
    
}