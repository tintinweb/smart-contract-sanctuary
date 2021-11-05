/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

/**
 * SPDX-License-Identifier: MIT
 */ 
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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
interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IPancakeV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * Fee Breakdown:
 * 
 * Liquidity           1.57%
 * Holder Reward        1.57%
 * Charity             1.57%
 * Operations          1.57%
 * 
 */

abstract contract Tokenomics {
    
    using SafeMath for uint256;
    
    // --------------------- Token Settings ------------------- //

    string internal constant NAME = "Gigawatt Token";
    string internal constant SYMBOL = "$GGWTT";
    
    uint256 internal constant FEES_DIVISOR = 10**6;
    uint8 internal constant DECIMALS = 18;
    uint256 internal constant ZEROES = 10**DECIMALS;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 2971215073 * ZEROES;
    uint256 internal constant REWARD_SUPPLY = 11439178031050 * (ZEROES / 10000);

    /**
     * @dev Set the maximum transaction amount allowed in a transfer.
     * 
     * The default value is 1% of the total supply. 
     * 
     * NOTE: set the value to `TOTAL_SUPPLY` to have an unlimited max, i.e.
     * `maxTransactionAmount = TOTAL_SUPPLY;`
     */
    uint256 internal constant maxTransactionAmount = TOTAL_SUPPLY / 33; // 3% of the total supply
    
    /**
     * @dev Set the number of tokens to swap and add to liquidity. 
     * 
     * Whenever the contract's balance reaches this number of tokens, swap & liquify will be 
     * executed in the very next transfer (via the `_beforeTokenTransfer`)
     * 
     * If the `FeeType.Liquidity` is enabled in `FeesSettings`, the given % of each transaction will be first
     * sent to the contract address. Once the contract's balance reaches `numberOfTokensToSwapToLiquidity` the
     * `swapAndLiquify` of `Liquifier` will be executed. Half of the tokens will be swapped for ETH 
     * (or BNB on BSC) and together with the other half converted into a Token-ETH/Token-BNB LP Token.
     * 
     * See: `Liquifier`
     */
    uint256 internal constant numberOfTokensToSwapToLiquidity = TOTAL_SUPPLY / 1000; // 0.1% of the total supply

    // --------------------- Fees Settings ------------------- //

    /**
     * @dev To add/edit/remove fees scroll down to the `addFees` function below
     */
    // @TODO Change addresses
    address public rewardsAddress = 0x655D9Fc9cae33dc373d7871A83D0A1f14425c783; 
    address public charityAddress = 0x2b6600486FD4D2eD5d873EBAf57CAE2C56F17268; 
    address public operationsAddress = 0xAc67680538F7e357302E77F6d67A4Fca505311C5; 
    
    /**
     * @dev You can change the value of the burn address to pretty much anything
     * that's (clearly) a non-random address, i.e. for which the probability of 
     * someone having the private key is (virtually) 0. For example, 0x00.....1, 
     * 0x111...111, 0x12345.....12345, etc.
     *
     * NOTE: This does NOT need to be the zero address, adress(0) = 0x000...000;
     *
     * Trasfering tokens to the burn address is good for optics/marketing. Nevertheless
     * if the burn address is excluded from rewards (unlike in Safemoon), sending tokens
     * to the burn address actually improves redistribution to holders (as they will
     * have a larger % of tokens in non-excluded accounts)
     *
     * p.s. the address below is the speed of light in vacuum in m/s (expressed in decimals),
     * the hex value is 0x0000000000000000000000000000000011dE784A; :)
     *
     * Here are the values of some other fundamental constants to use:
     * 0x0000000000000000000000000000000602214076 (Avogardo constant)
     * 0x0000000000000000000000000000000001380649 (Boltzmann constant)
     * 0x2718281828459045235360287471352662497757 (e)
     * 0x0000000000000000000000000000001602176634 (elementary charge)
     * 0x0000000000000000000000000200231930436256 (electron g-factor)
     * 0x0000000000000000000000000000091093837015 (electron mass)
     * 0x0000000000000000000000000000137035999084 (fine structure constant)
     * 0x0577215664901532860606512090082402431042 (Euler-Mascheroni constant)
     * 0x1618033988749894848204586834365638117720 (golden ratio)
     * 0x0000000000000000000000000000009192631770 (hyperfine transition fq)
     * 0x0000000000000000000000000000010011659208 (muom g-2)
     * 0x3141592653589793238462643383279502884197 (pi)
     * 0x0000000000000000000000000000000662607015 (Planck's constant)
     * 0x0000000000000000000000000000001054571817 (reduced Planck's constant)
     * 0x1414213562373095048801688724209698078569 (sqrt(2))
     */
    address internal burnAddress = 0x0000000000000000000000000000000000000000;

    /**
     * FeeType:
     * name: An enum for the type of fee
     * value: The percentage of the transaction that will get taxed 
     * recipient: The address that will recieve the fee from transactions
     * total: 
     */
    enum FeeType { Burn, Liquidity, External}
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    /**
     * _addFee:
     * Takes in the name of the fee, the amount this fee will tax, and the recipient of the fee
     * Returns nothing
     * Used for setting all of the fees upon creation of the contract. 
     * Called by _addFees for each fee in it's function
     */
    function _addFee(FeeType name, uint256 value, address recipient) private {
        fees.push( Fee(name, value, recipient, 0 ) );
        sumOfFees += value;
    }

    function _addFees() private {

    /**
     * These setters determine the fees that will be taken when each feeable transaction occurs
     * Some addresses are excluded from this (Owner and contracts to support ecosystem). 
     * Check isUnlimitedAddress to check what addresses are included
     */
        _addFee(FeeType.Liquidity, 15700, address(this) );
        _addFee(FeeType.External, 15700, rewardsAddress );
        _addFee(FeeType.External, 15700, charityAddress );
        _addFee(FeeType.External, 15700, operationsAddress );

    }

    /**
     * _getFeesCount:
     * Takes in nothing
     * Returns the total number of indexable fees the transfer will collected
     * Used for iterating through the fees
     * 
     * _getFeeStruct:
     * Takes in the index of the fee in question
     * Returns the storage object that holds the information on this fee
     * Used for interacting and accessing the information of fees
     * 
     * _getFee:
     * Takes in the index of the fee in question
     * Returns the name of the fee, the value of the fee, the address the fee will go too, and the total token amount collected for the fee
     * Used for getting the information about the fee for the index that was passed in
     * 
     * _addFeeCollectedAmount:
     * Takes in the index of the fee to update and the ammount of tokens to add
     * Returns nothing
     * Used for adding all the tokens taken to their respective fee for accounting
     * 
     * getCollectedFeeTotal:
     * Takes in the index of the fee in question
     * Returns the total tokens collected for the index passed in
     * Used for viewing the total tokens that have gone to various fees
     */
    function _getFeesCount() internal view returns (uint256){ return fees.length; }

    function _getFeeStruct(uint256 index) private view returns(Fee storage){
        require( index >= 0 && index < fees.length, "FeesSettings._getFeeStruct: Fee index out of bounds");
        return fees[index];
    }
    function _getFee(uint256 index) internal view returns (FeeType, uint256, address, uint256){
        Fee memory fee = _getFeeStruct(index);
        return ( fee.name, fee.value, fee.recipient, fee.total );
    }
    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    function getCollectedFeeTotal(uint256 index) external view returns (uint256){
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
    function _getCollectedFeeTotal(uint256 index) internal view returns (uint256){
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}

abstract contract Presaleable is Manageable {
    bool internal isInPresale = true;
    function setPreseableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}

pragma solidity ^0.8.0;

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
abstract contract GigaERC20 is IERC20, IERC20Metadata, Ownable, Presaleable, Tokenomics {
    
    using SafeMath for uint256;
    uint256 internal _burnSupply;
    bool internal giveawayLive = true;
    uint256 private reward_trigger;
    uint256 internal reward_count;
    uint256 internal _rewardStartBlock;
    uint256 internal _tokenDistributionTimer;
    uint256 internal _tokenDistributionStartBlock;
    HolderReward internal rewardContract;
    
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    
    address[] private _excluded;
    bool private haltTransfers;
    
    /**
     * @dev A delegate which should return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns(bool);
    
     /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     * 
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _takeTransactionFees(uint256 amount) internal virtual; 
    
    
    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     * 
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _takeFees(uint256 amount, uint256 sumOfFees ) internal virtual;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        
        // This handles the initial distribution of tokens
        _balances[owner()] = TOTAL_SUPPLY - REWARD_SUPPLY;
        _balances[rewardsAddress] = REWARD_SUPPLY;
        emit Transfer(address(this), owner(), TOTAL_SUPPLY);
        emit Transfer(address(this), rewardsAddress, REWARD_SUPPLY);
        
        _burnSupply = 0;
        reward_count = 0;
        reward_trigger = 420;
        _rewardStartBlock = block.timestamp + 61 days; 
        _tokenDistributionStartBlock = block.timestamp + 52 weeks; 
        _tokenDistributionTimer = block.timestamp + 52 weeks; 
        
        // Exclude the owner, rewards contract, and this contract from fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[rewardsAddress] = true;

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return NAME;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return SYMBOL;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return TOTAL_SUPPLY - _burnSupply;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    /**
     * _isUnlimitedAddress:
     * Takes in account in question
     * Returns true if address passed in is able to send and/or receive unlimited quantities in a transfer, false otherwise
     * Used for allowing certain contract addresses to send or receive large amounts while stopping others from doing so (Anti-Whale)
     * 
     * isUnlimitedAddress:
     * Takes in account in question
     * Returns true if address passed in is able to send and/or receive unlimited quantities in a transfer, false otherwise
     * Used for users of this contract to see what addresses are and are not able to avoid the AntiWhale features (Sending large amount of tokens)
     */
    function _isUnlimitedAddress(address account) internal view returns(bool){

        return _isExcludedFromFee[account];
    }
    
    function isUnlimitedAddress(address account) public view returns(bool){

        return _isExcludedFromFee[account];
    }

    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee) private {
        require(!haltTransfers, "GigaWattToken: Transfers are currently halted.");

        // Create local variable to not change the global one
        uint256 feeAmount = sumOfFees;
        if ( !takeFee ){ feeAmount = 0; }
        
         uint256 totalFees = amount.mul(feeAmount).div(FEES_DIVISOR);
         uint256 transferAmount = amount.sub(totalFees);
         
         _balances[sender] = _balances[sender].sub(amount);
         _balances[recipient] = _balances[recipient].add(transferAmount);
        
        // This calls the functions to take the fees 
        _takeFees( amount, feeAmount );
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        // Indicates whether or not fee should be deducted from the transfer
        bool takeFee = true;

        if ( isInPresale ){ takeFee = false; }
        else {
            /**
            * Check the amount is within the max allowed limit as long as a
            * unlimited sender/recipient is not involved in the transaction
            * If an unlimited sender/recipient is involved, any amount can be sent
            */
            if ( amount > maxTransactionAmount && !isUnlimitedAddress(sender) && !isUnlimitedAddress(recipient) && !_isV2Pair(recipient) ){
                revert("Transfer amount exceeds the maxTxAmount.");
            }
        }
        
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){ takeFee = false; }
        
        // These variables are used to calculate whether to Add/Remove the Sender/Receiver
        // based off their holdings crossing over the threshold 
        uint _senderBefore = balanceOf(sender);
        uint _recipientBefore = balanceOf(recipient);
        
        // This checks if the sender has enough tokens to send the amount they are trying to send
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        // These call the functions to calculate fees, send the funds, and take the fees 
        _beforeTokenTransfer(sender);
        _transferTokens(sender, recipient, amount, takeFee);

        emit Transfer(sender, recipient, amount);

        // This checks to see if enough time hass passed to start the reward
        if(block.timestamp > _rewardStartBlock){
            reward_count += 1;
            
            // If enough time has passed and enough transactions have happened then a reward is triggered
            if(reward_count % reward_trigger == 0){
                rewardContract.reward();
            }
        }
        
        // This determines if it is time for an token distribution
        // It activates one if it is time, and resets the timer
        if(block.timestamp > _tokenDistributionStartBlock && giveawayLive){
            if (_tokenDistributionTimer <= block.timestamp){
                _tokenDistributionTimer = _tokenDistributionTimer + 1 weeks;
                giveawayLive = rewardContract.giveaway();
            }
        }
        
        //Case 1: receiver before is under Requirement and after is over (Add to list)
        if((_recipientBefore < rewardContract.getRequiredHolding()) && (balanceOf(recipient) >= rewardContract.getRequiredHolding())){
            rewardContract.addAddressToList(recipient);
        }
        
        //Case 2: sender before is over Requirement and after is under (Remove from list)
        if((_senderBefore >= rewardContract.getRequiredHolding()) && (balanceOf(sender) < rewardContract.getRequiredHolding())){
            rewardContract.removeAddressFromList(sender);
        }
    }

    /**
     * @dev Destroys `amount` tokens from msg.sender, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - msg.sender must have at least `amount` tokens.
     */
    function _burn(uint256 amount) external virtual {
        
        _beforeTokenTransfer(msg.sender);

        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[msg.sender] = accountBalance - amount;
        }
        _burnSupply += amount;

        emit Transfer(msg.sender, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from
    ) internal virtual {}

    /**
     * circuitBreaker:
     * Takes in a boolean
     * Returns nothing
     * Used for halting all transactions
     *
     */
    function circuitBreaker(bool halt) external onlyOwner {
        haltTransfers = halt;
    }
    
    /**
     * changeRewardTrigger:
     * Takes in the desired amount of transactions inbetween a token reward bonus
     * Returns nothing
     * Used for changing the transactions required for the reward bonus to execute
     * 
     */
    function changeRewardTrigger(uint256 newValue) external onlyOwner {
        reward_trigger = newValue;
    }
    
    /**
     * addEcosystemAddress:
     * Taken in an address
     * Returns nothing
     * Used for adding addresses to the _isExcludedFromFee mapping
     * Used to add future ecosystem contracts  
     */
    function addEcosystemAddress(address contractAddress) public onlyOwner {
        _isExcludedFromFee[contractAddress] = true;
    }
    
    /**
     * removeEcosystemAddress:
     * Taken in an address
     * Returns nothing
     * Used for removing addresses to the _isExcludedFromFee mapping
     * Used to remove future ecosystem contracts  
     */
    function removeEcosystemAddress(address contractAddress) public onlyOwner {
        _isExcludedFromFee[contractAddress] = false;
    }
    
}

abstract contract Liquifier is Ownable, Manageable {

    using SafeMath for uint256;

    uint256 private withdrawableBalance;
    
    // Sushiswap V2
    address private _mainnetRouterV2Address = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    IPancakeV2Router internal _router;
    address internal _pair;
    
    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToLiquidity;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    receive() external payable {}

    function initializeLiquiditySwapper(uint256 maxTx, uint256 liquifyAmount) internal {
        
        // Sets the router address we will be using for the auto liquidity functions
        _setRouterAddress(_mainnetRouterV2Address);
        
        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToLiquidity = liquifyAmount;

    }

    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function liquify(uint256 contractTokenBalance, address sender) internal {

        if (contractTokenBalance >= maxTransactionAmount) contractTokenBalance = maxTransactionAmount;
        
        bool isOverRequiredTokenBalance = ( contractTokenBalance >= numberOfTokensToSwapToLiquidity );
        
        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the uniswap pair
         */
        if ( isOverRequiredTokenBalance && swapAndLiquifyEnabled && !inSwapAndLiquify && (sender != _pair) ){

            _swapAndLiquify(contractTokenBalance);            
        }

    }

    /**
     * @dev sets the router address and created the router, factory pair to enable
     * swapping and liquifying (contract) tokens
     */
    function _setRouterAddress(address router) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }
    
    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        
        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private {
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approveDelegate(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            // The minimum amount of output tokens that must be received for the transaction not to revert.
            // 0 = accept any amount (slippage is inevitable)
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approveDelegate(address(this), address(_router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            // Bounds the extent to which the WETH/token price can go up before the transaction reverts. 
            // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
            0,
            // Bounds the extent to which the token/WETH price can go up before the transaction reverts.
            // 0 = accept any amount (slippage is inevitable)
            0,
            // this is a centralized risk if the owner's account is ever compromised (see Certik SSL-04)
            owner(),
            block.timestamp
        );

        withdrawableBalance = address(this).balance;
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }
    
    /**
    * @dev Sets the uniswapV2 pair (router & factory) for swapping and liquifying tokens
    */
    function setRouterAddress(address router) external onlyManager() {
        _setRouterAddress(router);
    }

    /**
     * @dev Sends the swap and liquify flag to the provided value. If set to `false` tokens collected in the contract will
     * NOT be converted into liquidity.
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyManager {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    /**
     * @dev The owner can withdraw MATIC collected in the contract from `swapAndLiquify`
     * or if someone (accidentally) sends MATIC directly to the contract.
     *
     * 
     * The swapAndLiquify function converts half of the contractTokenBalance tokens to MATIC. 
     * For every swapAndLiquify function call, a small amount of MATIC remains in the contract. 
     * This amount grows over time with the swapAndLiquify function being called 
     * throughout the life of the contract. The contract does not contain a method 
     * to withdraw these funds, and the MATIC will be locked in the contract forever.
     * 
     * NOTE: This does not remove tokens stored up for liquidity creation. 
     * (Stored tokens are sold, paired into LP, and LP burned in one transaction)
     * It only withdraws the leftover MATIC that is not used when actualy creating the LP pair.
     */
    function withdrawLockedEth(address payable recipient) external onlyManager(){
        require(recipient != address(0), "Cannot withdraw the ETH balance to the zero address");
        require(withdrawableBalance > 0, "The ETH balance must be greater than 0");

        // Prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }

    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `GigaERC20` to gained access 
     * to the `_approve` function.
     */
    function _approveDelegate(address owner, address spender, uint256 amount) internal virtual;

}

abstract contract GigaBase is GigaERC20, Liquifier{
    
    using SafeMath for uint256;

    constructor(){
        rewardContract = HolderReward(rewardsAddress);
        initializeLiquiditySwapper( maxTransactionAmount, numberOfTokensToSwapToLiquidity);
    }
    
    /**
     * _isV2Pair:
     * Takes in address in question
     * Returns boolean for if the address passed in is the address of the router address used for auto liquidity 
     * (Address should be able to not be capped on the amount it can send)
     * Used for allowing this address to send/receive large amount of tokens so that it can save gas on creating liquidity
     */
    function _isV2Pair(address account) internal view override returns(bool){
        return (account == _pair);
    }

    /**
     * _beforeTokenTransfer:
     * Takes in the address of the sender of the transaction
     * Returns nothing
     * Used for checking if enough tokens have been stored up to liquify and create more LP for the token
     * The sender is passed in to make sure that the address is not the address of the pair contract
     */
    function _beforeTokenTransfer(address sender) internal override {
        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            liquify( contractTokenBalance, sender );
        }
    }
    
    /**
     * _takeFees:
     * Takes in the amount being sent and the fees being applied
     * Returns nothing
     * Used for processing the fees and distributing them properly
     */
    function _takeFees(uint256 amount, uint256 sumOfFees ) override internal {
        if ( sumOfFees > 0 && !isInPresale ){
            _takeTransactionFees(amount);
        }
    }
    
    /**
     * _takeTransactionFees:
     * Takes in the amount being transferred
     * Returns nothing
     * Used for determining if fees should be taken then loops through all fees and sends amounts
     */
    function _takeTransactionFees(uint256 amount) internal override {
        
        if( isInPresale ){ return; }

        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++ ){
            (FeeType name, uint256 value, address recipient,) = _getFee(index);
            // No need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            name;
            if ( value == 0 ) continue;
            else {
                // FeeType.External & FeeType.Liquidity are collected here
                _takeFee( amount, value, recipient, index );
            }
        }
    }

    /**
     * _takeFee:
     * Takes in the amount sent, the fee to take, the recipient of the fee, and the index of the fee object
     * Returns nothing
     * Used for actual processing of the fees
     */
    function _takeFee(uint256 amount, uint256 fee, address recipient, uint256 index) private {

        uint256 feeAmount = amount.mul(fee).div(FEES_DIVISOR);
        _balances[recipient] = _balances[recipient].add(feeAmount);
        
        emit Transfer(address(this), recipient, feeAmount);
        _addFeeCollectedAmount(index, feeAmount);
    }

    /**
     * _approveDelegate:
     * Takes in the address in question, the address to approve, and the amount to approve
     * Returns nothing
     * Used for approving funds to be spent by another party
     */
    function _approveDelegate(address owner, address spender, uint256 amount) internal override {
        _approve(owner, spender, amount);
    }
}


contract GigaWattToken is GigaBase{
    
    constructor() GigaBase(){
        // Pre-approve the initial liquidity supply (to safe a bit of time)
        _approve(owner(),address(_router), ~uint256(0));
    }
}



contract HolderReward is Context, Ownable {
    // Final deployment 10/31/2021
    mapping(uint256 => address) public valid_addresses;
    IERC20 public tokenContract;
    uint8 internal constant DECIMALS = 18;
    uint256 internal constant ZEROES = 10**DECIMALS;
    uint256 public current_addresses = 0;
    uint256 public requiredHolding = 290000 * ZEROES;
    uint256 public givawayBalance = 1143917803105 * (ZEROES / 1000); 
    uint256 public maxGiveaway =  2200000 * ZEROES; 
    
    uint256 public reward_iterations = 0;
    uint256 public giveaway_iterations = 0;
    
    mapping(address => uint256) public _lastWon;
    
    // Returns the required amount to be eligible for the rewards
    function getRequiredHolding() public view returns (uint256) {
        return requiredHolding;
    }
    
    // Returns if the entered address is eligible to win 
    // This will return true based on last time winning, NOT if the address entered actualy has the required amount
    // Check to see if the address in question is also in valid_addresses to get an accurate metric
    function isAddressWinnable(address userAddress) public view returns (bool) {
        return _lastWon[userAddress] < block.timestamp - 180 days;
    }
    
    // This returns a random number. It is used for the rewards
    function random() private view returns (uint) {
        if(current_addresses == 0){
            return 0;
        }
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, current_addresses))) % current_addresses;
    }
    
    // Used for initial setup, sets the contract of the Stone token
    function setTokenContract(address _tokenContract) public restrictedOwner {
        tokenContract = IERC20(_tokenContract);
    }
    
    // _ammount should be a number out of 10000 to represent a %. For example _ammount = 500 makes there be a 5% holding requirement.
    function changeAndUpdateRequiredHolding(uint256 _ammount) public restrictedOwner{
        
        // Update the current holding requirement.
        requiredHolding = _ammount;
        
        // Goes though entire mapping and check the amount currently held by each address and remove from list of they don't meet requirements
        for (uint i = 0; i < current_addresses; i += 1) {
            if(tokenContract.balanceOf(address(valid_addresses[i])) <  getRequiredHolding()){
                // Once valid address found, call for it to be removed.
                removeHolder(i);
            }
        }
    }
    
    // Add address to the valid_addresses, can only be called by the tokenContract
    function addAddressToList(address _addressToAdd) public restrictedToken {
        if((_addressToAdd != address(this)) && (_addressToAdd != address(0))){
            valid_addresses[current_addresses] = _addressToAdd;
            current_addresses += 1;
        }
    }
    
    // Remove address to the valid_addresses, can only be called by the tokenContract
    function removeAddressFromList(address _addressToRemove) public restrictedToken {
        for (uint i = 0; i < current_addresses; i += 1) {
            
            // Check if current address is the one we want to remove
            if(valid_addresses[i] == _addressToRemove){
                // Once valid address found, call for it to be removed.
                removeHolder(i);
            }
        }
    }
    
    // This function can only be called by changeAndUpdateRequiredHolding and removeHolder
    function removeHolder(uint256 _index) private {
        
        // Replaces the address to be removed with the last address in list then decrement list number.
        valid_addresses[_index] = valid_addresses[current_addresses];
        current_addresses -= 1;
    }
    
    // Runs the givaway (will only be called by token contract every X Blocks)
    function giveaway() public restrictedToken returns (bool) {
        
        // Get random generateRandomNumber
        uint256 randomNumber = random();
        giveaway_iterations += 1;
        
        // Picks and validates winner
        uint256 current_index = randomNumber;
        for (uint i = 0; i < current_addresses; i += 1) {
            // Assign possible winner
            address _winner = valid_addresses[current_index];
            
            // Check if winner is valid
            if(_lastWon[_winner] < block.timestamp - 180 days && _winner != address(0)) {
                
                // Transfer the funds to the winner and set their last win time
                // Also calculate winnings
                // Don't bother sending if the winner has over the max amount
                if(tokenContract.balanceOf(_winner) < maxGiveaway) {
                    uint _winnings = maxGiveaway - tokenContract.balanceOf(_winner);
                    givawayBalance = givawayBalance - _winnings;
                    if(givawayBalance < maxGiveaway) {
                        tokenContract.transfer(_winner, givawayBalance);
                        _lastWon[_winner] = block.timestamp;
                        return false;
                    }
                    tokenContract.transfer(_winner, _winnings);
                    _lastWon[_winner] = block.timestamp;
                    // Break out of loop on next iteration
                    break;
                }

            }else
            {
                // If gets to 0 loop to top of list
                if(current_index == 0) {
                    current_index = current_addresses;
                }
                
                // Address is invalid, so iterate down
                current_index -=1;
            }
        }
        return true;
    }
    
    // Runs the reward (will only be called by token contract every X transactions)
    function reward() public restrictedToken returns (bool){
        
        // Get random generateRandomNumber
        uint256 randomNumber = random(); 
        reward_iterations += 1;
        // Assign the total winnings (subtract the givawayBalance)
        uint _winnings = tokenContract.balanceOf(address(this)) - givawayBalance;
        
        // Picks and validates winner
        uint256 current_index = randomNumber;
        for (uint i = 0; i < current_addresses; i += 1) {
            // Assign possible winner
            address _winner = valid_addresses[current_index];
            
            // Check if winner is valid
            if(_lastWon[_winner] < block.timestamp - 180 days && _winner != address(0)){
                
                // Transfer the funds to the winner and set their last win time
                tokenContract.transfer(_winner, _winnings);
                _lastWon[_winner] = block.timestamp;
                
                // Break out of loop on next iteration
                break;
            }else
            {
                // If gets to 0 loop to top of list
                if(current_index == 0){
                    current_index = current_addresses;
                }
                
                // Address is invalid, so iterate down
                current_index -=1;
            }
        }
        // If no winners are valid, the reward contract keeps the tokens and the next winner will get their winning plus the winnings of this iteration
        return true;
    }
    
    
        // Modifiers
    modifier restrictedToken() {
        require(msg.sender == address(tokenContract));
        _;
    }
        // Modifiers
    modifier restrictedOwner() {
        require(msg.sender == owner());
        _;
    }
}