/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
}

/**
 * @dev Requires the token contract to be used, ie. token transfers to be initiated, in order for new tokens 
 * to be minted and rewarded to the community
 */
contract Miner {
    using SafeMath for uint256;

    // The last checked block to compare with latest block number
    uint256 private _lastCheckedBlock;

    // Polygon/Matic generates 1 block roughly every 2 seconds. There are 86400 seconds in a day, divide this by 2 since its a 2 second block time and we get 43,200 blocks added per day at 1 block every 2 seconds. 
    // This should be roughly 20,056,896,000 minted a year, of which the community will receive roughly 10.5 billion or less (based on the burned accounts % of tokens)
    uint256 private constant _increasePerBlock = 1272 * 10**9;

    event TokensMinted(uint256 oldSupply, uint256 newSupply);

    constructor(){
        _lastCheckedBlock = block.number;
    }

    // Updates the last recorded block and mints new tokens
    function mine() internal returns (uint256) {
        uint256 newBlockNumber = block.number;

        // Getting our newly minted tokens
        uint256 mintedTokens = mintTokens(newBlockNumber);

        // Setting the last checked block to the new block
        _lastCheckedBlock = newBlockNumber;

        return mintedTokens;
    }

    // Mints new tokens
    function mintTokens(uint256 newBlockNumber) private view returns(uint256){
        // Safety check here in case some one tries to get cheeky or we have some weird issue to prevent transfers from breaking and reverting everything.
        uint256 numberOfNewBlocks;
        if(newBlockNumber < _lastCheckedBlock)
            numberOfNewBlocks = 1;
        else
            numberOfNewBlocks = newBlockNumber.sub(_lastCheckedBlock);

        uint256 mintedTokens = numberOfNewBlocks.mul(_increasePerBlock);

        return mintedTokens;
    }
}

contract Mooniverse is Context, IERC20, Ownable, Miner {
    using SafeMath for uint256;
    using Address for address;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Ownership for reflection owned and tokens owned
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    // Allowances allotted
    mapping (address => mapping (address => uint256)) private _allowances;

    // Excluded accounts.
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    // Our starting reflection, token, and token fee total amounts. 
    uint256 private constant MAX = ~uint256(0); //115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,935
    uint256 private constant _tTotal = 1 * 10**12 * 10**9; // 1 trillion with 9 decimals
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public minimumCirculatingSupply = 21 * 10**6 * 10**9; // 21 million with 9 decimals as the initial minimum circulating supply
    uint256 private amountToAddToCircSupply = 300853440000 * 10**9; // 300,853,440,000 15 years worth of minted tokens

    // Used as a metric to see how many total tokens have been distributed and how many t and r tokens have been minted
    uint256 private _tFeeTotal;
    uint256 public _tMintTotal;
    uint256 private _rMintTotal;

    // Token Info
    string private constant _name = '0xMooniverse';
    string private constant _symbol = 'MOONI';
    uint8  private constant _decimals = 9;

    uint256 public genesisBlock;
    uint256 public lastOwnerBlockCheck;
    uint256 constant private blocksUntilMinimumCirculationIncrease = 236520000; // 15 years worth of blocks

    constructor() {
        genesisBlock = block.number;
        lastOwnerBlockCheck = getNewBlockCheckInTime();

        _rOwned[_msgSender()] = _rTotal;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // BEGIN Our token info read only functions
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // Returns the total supply including burned tokens
    function totalSupply() public view override returns (uint256) {
        unchecked{
            if(_tTotal + _tMintTotal < _tTotal)
                return MAX;
            else
                return _tTotal.add(_tMintTotal);
        }
    }

    // Returns the total supply minus burned tokens
    function totalCirculatingSupply() public view returns (uint256) {
        return totalSupply().sub(getBurnedSupply());
    }

    // Returns the amount of burned tokens
    function getBurnedSupply() public view returns(uint256){
        return balanceOf(burnAddress);
    }

    // Gets the accounts total reflection amount 
    function getRBalance(address account) public view returns(uint256) {
        return _rOwned[account];
    }

    // Returns the token balance for an account by using the accounts rAmount for included accounts and tAmount for excluded accounts.
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account])
            return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);
    }

    // Checks to see if an individual account is excluded. Excluded account balances are checked using their token balance
    // instead of their reflection amount since the reflection amounts will always be increased/accumulated with more transfers and minting.
    // Once re-included the reflection amount will be updated immediately based on the total token amount owned by the account. 
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    // Returns the total reflection amount - 1
    function _getRTotalWithMinted() public view returns(uint256) {
        // Subtracting 1 here to prevent an error when getting the rAmount.
        return reflectionFromToken(_tTotal.sub(1).add(_tMintTotal), false);
    }

    // Gets total token fees that have been distributed
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    //END Our token info read only functions

    //BEGIN our basic interactive functions
    // Transfers tokens, mints new tokens, and then checks to see if the minimum circulating supply is correct
    // Burn account is excluded/included based on minimumCirculatingSupply to ensure available tokens don't dwindle down to almost 0 in the future.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        mint();
        checkMinimumCirculatingSupply();

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Returns the current block timestamp + timeUntilMinimumCirculationIncrease (set to 15 years)
    function getNewBlockCheckInTime() private view returns (uint256) {
        return block.number.add(blocksUntilMinimumCirculationIncrease);
    }

    // Used to increase/decrease the minimumCirculatingSupply as needed for economic purposes.
    // Ex. 1 million token minimum to start is great for adoption but unrealistic for long term use as adoption increases
    // This allows the minimum to be increased or decreased as needed which in turn includes or excludes the burn wallet automatically during transfers.
    // Be sure to add the needed decimals to the newMinimum amount
    function setNewMinimumCirculatingSupply(uint256 newMinimum) external onlyOwner() {
        minimumCirculatingSupply = newMinimum;
        lastOwnerBlockCheck = getNewBlockCheckInTime();
    }

    // Includes/Excludes the burn account based on circulating supply and the set minimum circulating supply
    function checkMinimumCirculatingSupply() private {
        // Uses total supply of tTokens - tTokens from rTokens from the burn
        if(totalCirculatingSupply() >= minimumCirculatingSupply)
            includeBurnAccount();
        else
            excludeBurnAccount();
    }

    // Function for owner to strictly "check in" with the contract to show they are still alive
    function setLastOwnerBlockForOwnerCheckin() external onlyOwner() returns (bool) {
        lastOwnerBlockCheck = getNewBlockCheckInTime();

        return true;
    }

    // In case the contract owner dies while still in ownership, check the last recorded block and compare with current block. 
    // Every 15 years worth of blocks adjust the minimum circulating supply by adding 15 years worth of minted tokens to the minimum circulating supply to compensate for user adoption and inflation
    function checkLastOwnerBlockCheckin() private {
        if(block.number > lastOwnerBlockCheck)
        {
            lastOwnerBlockCheck = getNewBlockCheckInTime();

            unchecked {
                if(minimumCirculatingSupply + amountToAddToCircSupply > minimumCirculatingSupply)
                    minimumCirculatingSupply = minimumCirculatingSupply.add(amountToAddToCircSupply);
            }
        }
    }
    //END our basic interactive functions

    //BEGIN transfer and mint functions
    function mint() private {
        // Getting our old supply to log with the new supply
        uint256 oldTokenSupply = _tTotal.add(_tMintTotal);

        // Minting new t and r tokens
        uint256 mintedTokens = mine();
        uint256 mintedRTokens = MAX % mintedTokens;

        // Checking to see if adding minted tokens to _tMintTotal or _rMintTotal causes an overflow, if so dont mint any more tokens
        unchecked {
            if(_tMintTotal + mintedTokens < _tMintTotal || _tMintTotal + _tTotal < _tMintTotal || _tMintTotal + mintedTokens + _tTotal < _tMintTotal)
                return;
    
            if(_rMintTotal + mintedRTokens < _rMintTotal || _rMintTotal + _rTotal < _rMintTotal || _rMintTotal + mintedRTokens + _rTotal < _rMintTotal)
                return;
        }

        _tMintTotal = _tMintTotal.add(mintedTokens);
        _rMintTotal = _rMintTotal.add(mintedRTokens);

        uint256 rate = _getTransferRate();
        uint256 rFee = mintedTokens.mul(rate);

        _rTotal = _rTotal.sub(rFee);

        uint256 newTokenSupply = _tTotal.add(_tMintTotal);

        // Logging the minting process with our old and new token supplies
        emit TokensMinted(oldTokenSupply, newTokenSupply);
    }

    // Main transfer function
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(_isExcluded[sender])
            require(_tOwned[sender] >= amount, "Transfer amount exceeds current balance");
        else
            require(tokenFromReflection(_rOwned[sender]) >= amount, "Transfer amount exceeds current balance");

        if (_isExcluded[sender] && !_isExcluded[recipient])
            _transferFromExcluded(sender, recipient, amount);
        else if (!_isExcluded[sender] && _isExcluded[recipient])
            _transferToExcluded(sender, recipient, amount);
        else if (_isExcluded[sender] && _isExcluded[recipient])
            _transferBothExcluded(sender, recipient, amount);
        else
            _transferStandard(sender, recipient, amount);
    }

    // Used for transfers between regular non excluded accounts.
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Used for transfers between non excluded accounts to an excluded account
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Used for transfers from an excluded account to a non excluded account
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Used for transfers between 2 excluded accounts
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    //END transfer functions

    //BEGIN get reflection and token supply functions
    // Gets our needed values to execute the transfer
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);

        uint256 currentRateForTransferAmount = _getTransferRate();
        uint256 currentRateForCommunityFees = _getRate();

        (,,uint256 rFee) = _getRValues(tAmount, tFee, currentRateForTransferAmount);
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, currentRateForCommunityFees);

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    // Gets the token transfer amount minus the fee and returns it along with the token fee amount, 2% of tAmount
    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(2).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    // Gets the reflection transfer and fee amounts by multiplying both of the amounts by the current transfer or supply rate
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    // Getting the rate to determine how much reflection there is based on supply
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    // Getting the rate to determine how much reflection is needed for transfers 
    function _getTransferRate() private view returns(uint256) {
        return _rTotal.add(_rMintTotal).div(_tTotal.add(_tMintTotal));
    }

    // Gets the current supply of reflections and tokens
    function _getCurrentSupply() private view returns(uint256, uint256) {
        return (_rTotal, _tTotal);
    }
    //END get reflection and token supply functions

    //BEGIN reflection functions
    // Can be used to give the community free tokens as an airdrop by reflecting your own tokens
    function reflect(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        uint256 rAmount = reflectionFromToken(tAmount, false);
        require(rAmount <= _rOwned[sender], "Amount must be less than or equal to your current balance");

        uint256 currentRateForTransferAmount = _getTransferRate();
        (,,uint256 rFee) = _getRValues(tAmount, tAmount, currentRateForTransferAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _reflectFee(rFee, tAmount);
    }

    // Used to see how much reflection, with or with out the fee, would be sent in a transaction based on tAmount. 
    // tAmount must be 1 less than total supply or this will break. Note that at 9 decimals this is only off by 0.000000001
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        uint256 tTotalWithMinted;

        unchecked{
            if(_tTotal + _tMintTotal < _tTotal)
                tTotalWithMinted = MAX;
            else
                tTotalWithMinted = _tTotal.add(_tMintTotal);
        }

        require(tAmount < tTotalWithMinted, "Amount must be less than the supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    // Uses the reflection amount for the current caller, gets the current rate and then divides the reflection amount 
    // by the rate to get our token total for the account
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    // Called during token transfers and when subtracting reflection from an account to give to the community. 
    // Reduces the reflection total by the rFee and increases the tFeeTotal by the tFee
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    //END reflection functions

    //BEGIN exclude/include accounts
    // Records the accounts token balance from their reflection amount and uses the token amount for all transfers. 
    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0)
            _tOwned[account] = tokenFromReflection(_rOwned[account]);

        _isExcluded[account] = true;
        _excluded.push(account);
        lastOwnerBlockCheck = getNewBlockCheckInTime();
    }

    // Includes the account so its accumulated reflections count towards its total again. 
    // Any reflections accumulated that is more than the recorded token balance is removed and reflected back to the community.
    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];

                includeAccountInnerLogic(account, false);

                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        lastOwnerBlockCheck = getNewBlockCheckInTime();
    }

    // Excludes the burn account in order to record its current token supply
    function excludeBurnAccount() private {
        if(_isExcluded[burnAddress])
            return;

        if(_rOwned[burnAddress] > 0) {
            _tOwned[burnAddress] = tokenFromReflection(_rOwned[burnAddress]);
        }

        _isExcluded[burnAddress] = true;
        _excluded.push(burnAddress);
    }

    // Includes the burn account in order for tokens to be burned again. 
    // Invoking this returns the difference between its reflection amount and recorded 
    // token amount and distributes the difference back to the community through the faucet.
    function includeBurnAccount() private {
        if(!_isExcluded[burnAddress])
            return;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == burnAddress) {
                _excluded[i] = _excluded[_excluded.length - 1];

                includeAccountInnerLogic(burnAddress, true);

                _isExcluded[burnAddress] = false;
                _excluded.pop();
                break;
            }
        }
    }

    // Inner logic for the include account and include burn account functions. 
    function includeAccountInnerLogic(address account, bool isAutoBurn) private {
        uint256 currentRate = _getRate();
        uint256 currentTransferRate = _getTransferRate();

        uint256 totalTokens = tokenFromReflection(_rOwned[account]);
        uint256 actualTokens = _tOwned[account];

        // Setting the accounts rAmount equal to the amount of tokens they actually have
        // This prevents the account from acquiring tokens they shouldn't have received while being excluded
        _rOwned[account] = _tOwned[account].mul(currentRate);
        _tOwned[account] = 0;

        // If the account had more tokens than they were supposed to then redistribute the difference to the community
        if(totalTokens > actualTokens){
            uint256 tokensToDistribute = totalTokens.sub(actualTokens);
            uint256 rAmountForTokenDistribution;

            if(isAutoBurn)
                rAmountForTokenDistribution = tokensToDistribute.mul(currentRate);
            else
                rAmountForTokenDistribution = tokensToDistribute.mul(currentTransferRate);

            // When including the burn wallet, transfer the difference from the burn wallet to the community faucet else reflect the amount back to the community
            if(account == burnAddress)
                transferFromBurnToFaucet(rAmountForTokenDistribution, tokensToDistribute);
            else
                _reflectFee(rAmountForTokenDistribution, tokensToDistribute);
        }
    }

    // Gets all excluded addresses
    function getExcludedAddresses() public view returns(address[] memory){
        return _excluded;
    }
    //END exclude/include accounts

    //BEGIN Faucet functions
    // How much is transferred from the faucet to the requesting address
    uint256 public faucetTransferAmount = 100 * 10**9;
    // How long an account has to wait before being able to access the faucet again. Set to 1 day
    uint256 constant private waitTimeInBlocks = 43200; // 1 day worth of blocks

    mapping(address => uint256) lastAccessTime;

    // Used to adjust the faucet giveaway as needed.
    function setFaucetTokenTransferAmount(uint256 newFaucetTransferAmount) external onlyOwner() {
        faucetTransferAmount = newFaucetTransferAmount;
        lastOwnerBlockCheck = getNewBlockCheckInTime();
    }

    // Transfers faucetTransferAmount to the requesting address
    function activateFaucet() external {
        require(tokenFromReflection(_rOwned[address(this)]) >= faucetTransferAmount, "Faucet is empty or doesn't have enough tokens!");
        require(allowedToWithdraw(msg.sender), "You have requested too many times today. Please come back tomorrow.");

        faucetTransfer(msg.sender, faucetTransferAmount);
        lastAccessTime[msg.sender] = block.number.add(waitTimeInBlocks);

        // Checking last owner checkin here to preserve gas on regular transfers and to leave it to the community to decide to interact with the faucet in order to 
        // provoke the check that will cause the circulating supply to increase if owner hasn't interacted with contract in over 15 years worth of blocks
        checkLastOwnerBlockCheckin();
    }

    // Used to see if the requested account is allowed to access the faucet yet or if they still have to wait.
    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0 || block.number >= lastAccessTime[_address])
            return true;

        return false;
    }

    // Transfers without minting or checking burned supply
    function faucetTransfer(address recipient, uint256 amount) private returns (bool) {
        _transfer(address(this), recipient, amount);

        return true;
    }

    // Transfers excess tokens from the burn wallet to the faucet without minting or re checking burned supply 
    // Note** burned supply has its amount subtracted before this and this by-passes the 2% fee and re distribution of the tokens
    // Note** this is implemented so the inclusion of the burn wallet doesn't reflect as the burn wallet will end up getting the 
    // majority of the reflection since it will still have a majority of the tokens.
    function transferFromBurnToFaucet(uint256 rTransferAmount, uint256 tTransferAmount) private returns (bool) {
        _rOwned[address(this)] = _rOwned[address(this)].add(rTransferAmount);
        emit Transfer(burnAddress, address(this), tTransferAmount);

        return true;
    }
    //END Faucet Functions
}