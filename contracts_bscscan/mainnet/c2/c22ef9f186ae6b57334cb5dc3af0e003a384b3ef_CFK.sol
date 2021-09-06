/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-25
*/

pragma solidity ^0.6.12;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

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
}

contract CFKTimelock {
    
    CFK public immutable _cfkToken;
    
    mapping (uint256 => bool) public _monthVested;
    mapping (uint256 => uint256) public _monthVestingTime;
    
    constructor (address cfkTokenAddress) public {
        _cfkToken = CFK(cfkTokenAddress);
        
        uint256 releaseOffsetMonth = 5;
        uint256 releaseTime = 0;
        for(uint256 i = 1; i <= 20; i++){
            releaseOffsetMonth +=1;
            releaseTime = now + releaseOffsetMonth * 4 weeks;
            
            _monthVested[i] = false;
            _monthVestingTime[i] = releaseTime;
        }
    }
    
    function vestTokens(uint256 month) public  {
        require(month >= 1, "Month must >= 1");
        require(month <= 20, "Month must be <= 20");
        require(_monthVested[month] == false, "Tokens for month already vested!");
        require(_monthVestingTime[month] < now, "Too early to vest tokens!"); 
        
        _monthVested[month] = true;
        _cfkToken.disableFees();
        
        //CEO
        _cfkToken.transfer(0x6000DA08E82Ed2159B2250135e607689ba685f5C, 2500000000000000);
        
        //CFK
        _cfkToken.transfer(0x956e3FE099a129B0691b075116f488Dc2AF1174D, 2500000000000000);

        //TEAM
        _cfkToken.transfer(0xd93A7666ade405aDdEFB6716CF77b6fA150aEEe5, 150000000000000);
        _cfkToken.transfer(0xE83c6bb9119D27a16c833f6FdE0826b6043eecf5, 150000000000000);
        _cfkToken.transfer(0x2742e6D37b23Eb3f5FAbFe8451F7E3b73F198630, 150000000000000);
        _cfkToken.transfer(0xcBE71785AFBf9c2b08186b486dDD7385EBc4f475, 150000000000000);
        _cfkToken.transfer(0x3493983208991863eC1447EaE002BdBB0256F30c, 150000000000000);
        _cfkToken.transfer(0x164076ba1f3f03D2545f0197906D93A752af08FF, 150000000000000);
        _cfkToken.transfer(0x9d699a6209aB103592dA8F7D24152D57E0EB089A, 150000000000000);
        _cfkToken.transfer(0x3abCeD16972b9CC78AEe7fe09ae4Ef373F71f2c3, 150000000000000);
        _cfkToken.transfer(0x9654F612a016574478e18fB79F7dbc589c0437fc, 150000000000000);
        _cfkToken.transfer(0xA7c5D1b17072D554f6bD01cb8428d29930C00cca, 150000000000000);
        _cfkToken.transfer(0xF8e094566789b33f09815aa760f5e8896782907B, 150000000000000);
        _cfkToken.transfer(0xA3a0B9c718dB7ce10BD5ec00E3E6403dA66Be764, 150000000000000);
        _cfkToken.transfer(0x12B16D39c855f605A6e9cf0a6a5370aACDA61b16, 150000000000000);
        _cfkToken.transfer(0x27DEb4575363A91c50cebdeEAaD83C31ec4d72Ff, 150000000000000);
        _cfkToken.transfer(0xfB3AE0d1Ab510af16CaD474b0918fB75a2a00eeD, 150000000000000);
        _cfkToken.transfer(0x47dDB8f9D921913cc574EbB05A53514684cC13DC, 150000000000000);
        _cfkToken.transfer(0x950C4a69ba108538369BCe00Ad08b2B88b5147D4, 150000000000000);
        _cfkToken.transfer(0xddCbf79d050C26CCaea5226D598f6B6D9A23f33D, 150000000000000);
        _cfkToken.transfer(0x158072c6cc7D4CDf80f58850Dae6Fd263CDB2173, 150000000000000);
        _cfkToken.transfer(0x56DeC515276671bc31EECAdC3A16F15cFc67206F, 150000000000000);
        _cfkToken.transfer(0xf82aD4f9b19784803ff52a2506F6734F723d7F4d, 150000000000000);
        _cfkToken.transfer(0x540D4870bD72E404E79Dd2cdC9F9d3796BBf10Bd, 150000000000000);
        _cfkToken.transfer(0x40CD6D1210264B82925d239e85aD39B47d720724, 150000000000000);
        _cfkToken.transfer(0xa66AAD78bCdE9D2c39533ed9659350b311569657, 150000000000000);
        _cfkToken.transfer(0x8D3308F847E3354F9b1C9C135FF283B1cee3E94A, 150000000000000);
        _cfkToken.transfer(0x4A21e7e400F14a41471aF182717515c956613125, 150000000000000);
        _cfkToken.transfer(0x56b69CFdEf9e440a6a76EC819DEd9e326fF5F8DA, 150000000000000);
        _cfkToken.transfer(0x071cFD43AA26FA5314BE04A9247047c028aC4185, 150000000000000);
        _cfkToken.transfer(0x97fdb42B53c4A67EcAA6D53FF0684a9B54961399, 150000000000000);
        _cfkToken.transfer(0x555488d27eb294269a3067d1c188c8f643d6f646, 150000000000000);
        _cfkToken.transfer(0xe7b467BE414073c8391AEa643209dEea470d4B2F, 150000000000000);
        _cfkToken.transfer(0x8779f9E829189c8478d67778d26Fc251aD0cf8Db, 150000000000000);
        _cfkToken.transfer(0xb15ad9Fc5F1b811369BC40Ea7c567F90224af130, 150000000000000);
        _cfkToken.transfer(0x6A1F6E19D1D7e8007eDfF2B267E8dc37A80eece1, 150000000000000);
        _cfkToken.transfer(0x414bCC5a4F690e444846ecd21cC8a21cC324c712, 150000000000000);
        _cfkToken.transfer(0x79Bc6005C44720f03Aaaf32DD9295a65c65FE59e, 150000000000000);
        _cfkToken.transfer(0x637fAA8d2667aa8B1Ba58176cc5f9C2e763935A7, 150000000000000);
        _cfkToken.transfer(0x3E923EF827Ce391CF1607f68E786Cac49a7eA5Ef, 150000000000000);
        _cfkToken.transfer(0x3Bab348a6332E8D8a6c86BB7509b6485f925d280, 150000000000000);
        _cfkToken.transfer(0x3607a1886cC79dB60BbB1Af4A927ba1349352000, 150000000000000);
        _cfkToken.transfer(0xCCbe89cb106D51868B2079Ee3b9f1E7983b90E79, 150000000000000);
        _cfkToken.transfer(0x49Fae2f93d59687B42B45edfaA92402FC8De9c72, 150000000000000);
        _cfkToken.transfer(0xfdC7cc87d2C564CA5Ec31c5387D6Ea2E766Fb29c, 150000000000000);
        _cfkToken.transfer(0xc59A7DeDab340Fbe86E871eb1aF1F5B0DD9591cB, 150000000000000);
        _cfkToken.transfer(0x95eDdFFd5Fb4dCB997BC13d7792366F6f64B67AB, 150000000000000);
        _cfkToken.transfer(0x53C4cD27aa44e8Efa4e9f909f5b6e281527C405e, 150000000000000);
        _cfkToken.transfer(0x9e91BD8A64Cff85a4aEf9496E2056ddE69c24F28, 150000000000000);
        _cfkToken.transfer(0x5Cd774529F0C91f2dda92D3B9c6d728C4645fd31, 150000000000000);
        _cfkToken.transfer(0xa3E27FB91a7088C12fd40d1b7B025307a25e4Bb6, 150000000000000);
        _cfkToken.transfer(0x111B8185a69d34E5a0bfB553Ad436C7aB31AAf8e, 150000000000000);
        _cfkToken.transfer(0x45A641A055eaC89760B1Ef141101577Dec6E1f63, 150000000000000);
        _cfkToken.transfer(0x904F5e5Ea803bfe37872B79e77B8b5e58b9B9C9D, 150000000000000);
        _cfkToken.transfer(0xD796764C9952142707da007ED8E78993fA6E9cf4, 150000000000000);
        _cfkToken.transfer(0x9aBbd56EC5b17d85FceB022bfAF048A312705C42, 150000000000000);
        _cfkToken.transfer(0x13e418857F6DDA4f2157FE645A997Ac6C4f3267A, 150000000000000);
        _cfkToken.transfer(0xeB5c81B2fc91F92c81B4c1cc0F8f2364ED08097d, 150000000000000);
        _cfkToken.transfer(0x0a087362a29fadE08a89726Ae490be4A9b046785, 150000000000000);
        _cfkToken.transfer(0x46f5c6E9ffb9eC0CA27AEB9B13DC1d7acae38Cd9, 150000000000000);

            
        _cfkToken.enableFees();                                                           
    }
}

contract CFK is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = 'Crypto For Kids';
    string private _symbol = 'CFK';
    uint8 private _decimals = 9;
    
    uint256 public _maxTxAmount = 10**9 * 10**9;
    
    bool public _feesEnabled = false; 
    
    address constant public _marketingWalletAddress = 0x958C7a17F26962CDf6374FEfCC711181F229c5c7;
    address constant public _CFKWalletAddress = 0x956e3FE099a129B0691b075116f488Dc2AF1174D;
    
    CFKTimelock public _cfkTimeLock;
    address public _cfkTimeLockAddress;

    constructor () public {
        _cfkTimeLock = new CFKTimelock(address(this));
        _cfkTimeLockAddress = address(_cfkTimeLock);
        
        _rOwned[_msgSender()] = _rTotal;
        
        //Exclude Timelock
        _isExcluded[_cfkTimeLockAddress] = true;
        _excluded.push(_cfkTimeLockAddress);
        
        //Exclude Marketing Wallet
        _isExcluded[_marketingWalletAddress] = true;
        _excluded.push(_marketingWalletAddress);
        
        //Exclude CFK Wallet
        _isExcluded[_CFKWalletAddress] = true;
        _excluded.push(_CFKWalletAddress);
    
    }
    
    modifier onlyOwnerOrTimelock() {
        require(owner() == _msgSender() || _cfkTimeLockAddress == _msgSender(), "Only Owner or CFKTimelock.");
        _;
    }
    
    function vestTokens(uint256 month) public {
        _cfkTimeLock.vestTokens(month);
    }
    
    function enableFees() onlyOwnerOrTimelock() public{
        require(_feesEnabled == false, "Fees already enabled.");
        _feesEnabled = true;
    }
    
    function disableFees() onlyOwnerOrTimelock() public{
        require(_feesEnabled == true, "Fees already disabled.");
        _feesEnabled = false;
    }
    
    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() public view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(sender != owner() && recipient != owner())
          require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tCFKFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);      
        
        if(_feesEnabled){
            _takeMarketingFee(tMarketingFee);
            _takeCFKFee(tCFKFee);
            _reflectFee(rFee, tFee);           
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tCFKFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        if(_feesEnabled){
            _takeMarketingFee(tMarketingFee);
            _takeCFKFee(tCFKFee);
            _reflectFee(rFee, tFee);           
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tCFKFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        if(_feesEnabled){
            _takeMarketingFee(tMarketingFee);
            _takeCFKFee(tCFKFee);
            _reflectFee(rFee, tFee);           
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tCFKFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        if(_feesEnabled){
            _takeMarketingFee(tMarketingFee);
            _takeCFKFee(tCFKFee);
            _reflectFee(rFee, tFee);           
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tCFKFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, _getRate(), tFee, tMarketingFee, tCFKFee);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketingFee, tCFKFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = 0;           //HODL Fee
        uint256 tMarketingFee = 0 ; //Marketing Fee
        uint256 tCFKFee = 0;        //CFK Wallet Fee
        uint256 tTransferAmount;
        if(_feesEnabled){
            tFee = tAmount.div(100).mul(2);          //HODL Fee
            tMarketingFee = tAmount.div(100).mul(2); //Marketing Fee
            tCFKFee = tAmount.div(100).mul(3);       //CFK Wallet Fee  
            tTransferAmount = tAmount.sub(tFee).sub(tMarketingFee).sub(tCFKFee);
        }
        else{
            tTransferAmount = tAmount;
        }
        
        return (tTransferAmount, tFee, tMarketingFee, tCFKFee);
    }

    function _getRValues(uint256 tAmount, uint256 currentRate, uint256 tFee, uint256 tMarketingFee, uint256 tCFKFee) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rMarketingFee = tMarketingFee.mul(currentRate);
        uint256 rCFKFee = tCFKFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rMarketingFee).sub(rCFKFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeMarketingFee(uint256 tMarketingFee) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketingFee = tMarketingFee.mul(currentRate);
        _rOwned[_marketingWalletAddress] = _rOwned[_marketingWalletAddress].add(rMarketingFee);
        if(_isExcluded[_marketingWalletAddress])
            _tOwned[_marketingWalletAddress] = _tOwned[_marketingWalletAddress].add(tMarketingFee);
        
    }
    
    function _takeCFKFee(uint256 tCFKFee) private {
        uint256 currentRate =  _getRate();
        uint256 rCFKFee = tCFKFee.mul(currentRate);
        _rOwned[_CFKWalletAddress] = _rOwned[_CFKWalletAddress].add(rCFKFee);
        if(_isExcluded[_CFKWalletAddress])
        _tOwned[_CFKWalletAddress] = _tOwned[_CFKWalletAddress].add(tCFKFee);
        
    }
    
}