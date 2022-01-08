/**
 *Submitted for verification at FtmScan.com on 2022-01-07
*/

// SPDX-License-Identifier: non

interface IERC20 {
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

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

 
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
  
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

abstract contract Ownable is Context {
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

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public override view returns (string memory) {
        return _name;
    }


    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }


    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
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
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }


    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }
}

pragma solidity  0.6.12;

// SmurfBond Token
contract SmurfBond is ERC20('SmurfBond', 'SBOND') {

    address public dev = 0x2096aFDaA68EEaE1EbF95DFdf565eE6d9B1fbA37;
    address public minter1 = 0x000000000000000000000000000000000000dEaD;
    address public minter2 = 0x000000000000000000000000000000000000dEaD;

    // Set Address/Contract with permission to mint Bonds
    function setMinterAddress(address _minter1, address _minter2) public {
        require(msg.sender == dev, "setAddress: no permission to set Address");       
        minter1 = _minter1;
        minter2 = _minter2;
    }  

    // Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == dev || msg.sender == minter1 || msg.sender == minter2, "BondMint: no permission to mint");
        _mint(_to, _amount);
    }    
}


pragma solidity 0.6.12;

contract SmurfBondFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amountCleverFtm;
        uint256 amountCleverUsdc;
        uint256 amountCleverEth;
        uint256 amountMushyFtm;
        uint256 amountMushyUsdc;
        uint256 amountClever;
        uint256 amountMushy;
        uint256 userUnlockTime;
        uint256 userAmountBonds;
    }

    // The Smurf Bond Token
    SmurfBond public sbond;

    // Addresses    
    address public Clever = 0x465BC6D1AB26EFA74EE75B1E565e896615B39E79;
    address public Mushy = 0x53a5F9d5adC34288B2BFF77d27F55CbC297dF2B9;
    address public Ftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public Usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;  // 6 decimals!
    address public Eth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address public Burn = 0x000000000000000000000000000000000000dEaD;
    
    address public FtmUsdcLp = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;
    address public EthFtmLp = 0xf0702249F4D3A25cD3DED7859a165693685Ab577;

    address public CleverFtmLp = 0x6a738109438a22bE0536C01459587b68356C67b9;
    address public CleverUsdcLp = 0x0643c70a5Ee3b49568df239827645Dd6cE6536F3;
    address public CleverEthLp = 0x545c68Cf3682c69F51B371E460F3C37Aeb824622;
    address public MushyFtmLp = 0xb65cdd027ac9799892E0FC4912a3447e211eb167;
    address public MushyUsdcLp = 0xc5Dc8E913AFdD5Cb53B85c2e67C3cf407975f276;

    // Dev/Operator address
    address payable public dev = 0x2096aFDaA68EEaE1EbF95DFdf565eE6d9B1fbA37;

    // Seconds per Month
    uint256 public secondsPerMonth = 180; // 1 month (30 days, 2592000 seconds)

    // Multiplier of Deposit Value
    uint16 public lockTimeMultiplier = 1500; // 1500 = 0.15
    uint16 public baseDepositValue = 10000; // 10000 = 1

    // public counters
    uint16 public totalDeposits;
    uint256 public totalValueDeposited;  // USD value * 1e18
    uint256 public totalBondsMinted;
    uint256 public totalBondsBurned;

    constructor (SmurfBond _sbond) public {
        sbond = _sbond;
    }
   
    event MintBonds (address indexed user, address DepositedTokenAddress, uint256 AmountDepositToken, uint256 ValueDeposit, uint256 AmountBondsMinted, uint256 UnlockTimestamp);
    event WithdrawLps (address indexed user, uint256 AmountBondsBurned);

    // Info of each user that deposits LP tokens.
    mapping(address => UserInfo) public userInfo;

    receive() external payable {}

    // Pay out any token from Contract
    function receiveAnyToken(address _token, uint256 _amount) public {
        require(msg.sender == dev, "setChainTokenAddress: no permission");
        IERC20(_token).safeTransfer(dev, _amount);
    }
    
    // Pay out ETH from Contract
    function receiveETH() public {
        require(msg.sender == dev, "setChainTokenAddress: no permission");
        dev.transfer(address(this).balance);
    }

    // Update Chain TOKEN Addresses
    function setChainTokenAddress(address _Ftm, address _Usdc, address _Eth) public {
        require(msg.sender == dev, "setChainTokenAddress: no permission to set");
        Ftm = _Ftm;
        Usdc = _Usdc;
        Eth = _Eth;
    }

    // Update LP TOKEN Addresses for Price Calculation
    function setPriceTokenAddress(address _FtmUsdcLp, address _EthFtmLp) public {
        require(msg.sender == dev, "setPriceTokenAddress: no permission to set");
        FtmUsdcLp = _FtmUsdcLp;
        EthFtmLp = _EthFtmLp;
    }

    // Update Farm TOKEN Addresses
    function setFarmTokenAddress(address _Clever, address _Mushy) public {
        require(msg.sender == dev, "setFarmTokenAddress: no permission to set");
        Clever = _Clever;
        Mushy = _Mushy;
    }

    // Update Deposit TOKEN Addresses
    function setDepositokenAddress(address _CleverFtmLp, address _CleverUsdcLp, address _CleverEthLp, address _MushyFtmLp, address _MushyUsdcLp) public {
        require(msg.sender == dev, "setDepositokenAddress: no permission to set");
        CleverFtmLp = _CleverFtmLp;
        CleverUsdcLp = _CleverUsdcLp;
        CleverEthLp = _CleverEthLp;
        MushyFtmLp = _MushyFtmLp;
        MushyUsdcLp = _MushyUsdcLp;
    }

    // Update Multiplier
    function setMultiplier(uint16 _lockTimeMultiplier, uint16 _baseDepositValue) public {
        require(msg.sender == dev, "setmultiplier: no permission to set");
        lockTimeMultiplier = _lockTimeMultiplier;
        baseDepositValue = _baseDepositValue;
    }

    // Update Seconds Per Month
    function setSecondsPerMonth(uint256 _secondsPerMonth) public {
        require(msg.sender == dev, "setmultiplier: no permission to set");
        secondsPerMonth = _secondsPerMonth;
    }

    // Function to burn all collected Bonds
    function burnAllBonds() public {
        require(msg.sender == dev, "setmultiplier: no permission to Brun");
        uint256 bondBalance = IERC20(sbond).balanceOf(address(this));
        IERC20(sbond).transfer(Burn, bondBalance);
    }
    

    function getPriceFtm() public view returns (uint256) {
        uint256 FtmInFtmUsdcLp = IERC20(Ftm).balanceOf(address(FtmUsdcLp));
        uint256 UsdcInFtmUsdcLp = IERC20(Usdc).balanceOf(address(FtmUsdcLp));
        return ((UsdcInFtmUsdcLp * 1e12 * 1e18) / FtmInFtmUsdcLp);
    }

    function getPriceClever() public view returns (uint256) {
        uint256 CleverInCleverFtmLP = IERC20(Clever).balanceOf(address(CleverFtmLp));
        uint256 FtmInCleverFtmLP = IERC20(Ftm).balanceOf(address(CleverFtmLp));
        uint256 PriceFtm = getPriceFtm();
        return ((FtmInCleverFtmLP * PriceFtm) / CleverInCleverFtmLP);
    }

    function getPriceMushy() public view returns (uint256) {
        uint256 MushyInMushyFtmLP = IERC20(Mushy).balanceOf(address(MushyFtmLp));
        uint256 FtmInMushyFtmLP = IERC20(Ftm).balanceOf(address(MushyFtmLp));
        uint256 PriceFtm = getPriceFtm();
        return ((FtmInMushyFtmLP * PriceFtm) / MushyInMushyFtmLP);
    }

    function getPriceEth() public view returns (uint256) {
        uint256 EthInEthFtmLP = IERC20(Eth).balanceOf(address(EthFtmLp));
        uint256 FtmInEthFtmLP = IERC20(Ftm).balanceOf(address(EthFtmLp));
        uint256 PriceFtm = getPriceFtm();
        return ((FtmInEthFtmLP * PriceFtm) / EthInEthFtmLP);
    }

    function getTokenSupply(address tokenAddress) public view returns(uint256) {
        return IERC20(tokenAddress).totalSupply();
    }

    function getTokenBalanceOfContract(address tokenAddress, address contractAddress) public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(contractAddress));
    }

    // Deposit LPs to receive Bonds
    function mintBonds(address _depositToken, uint256 _inputAmt, uint256 _lockTimeMonth) public {
        require (_lockTimeMonth <= 14, "mintBonds: loking time must be below 15 Month" );
        require (_inputAmt > 0, "mintBonds: no valid deposit amount" );
        UserInfo storage user = userInfo[msg.sender];

        uint256 valueTokens;
        uint256 unlocktime;
        uint256 mintAmount;

        // Calculate users unlock date as timestamp
        uint256 lockSeconds = _lockTimeMonth * secondsPerMonth;
        unlocktime = (block.timestamp + lockSeconds);
        uint256 valueFactor = ((baseDepositValue + (_lockTimeMonth * lockTimeMultiplier)) * 1e18 / 10000);

        // Set users unlocktimestamp
        if (user.userUnlockTime <= unlocktime) 
            {user.userUnlockTime = unlocktime;}

        // Transfer users LP Tokens and determine users depostit value
        if (_depositToken == CleverFtmLp) {
            IERC20(CleverFtmLp).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            user.amountCleverFtm = user.amountCleverFtm + _inputAmt;
            
            uint256 lpSupply = getTokenSupply(CleverFtmLp);
            uint256 lpDepositShare = (_inputAmt * 1e18 / lpSupply);
            uint256 token1DepositAmount = (getTokenBalanceOfContract(Clever, CleverFtmLp) * lpDepositShare) / 1e18;
            uint256 token2DepositAmount = (getTokenBalanceOfContract(Ftm, CleverFtmLp) * lpDepositShare) / 1e18;
            valueTokens = ((token1DepositAmount * getPriceClever()) + (token2DepositAmount * getPriceFtm())) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }
            else if (_depositToken == CleverUsdcLp) {
            IERC20(CleverUsdcLp).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            user.amountCleverUsdc = user.amountCleverUsdc + _inputAmt;
            
            uint256 lpSupply = getTokenSupply(CleverUsdcLp);
            uint256 lpDepositShare = (_inputAmt * 1e18 / lpSupply);
            uint256 token1DepositAmount = (getTokenBalanceOfContract(Clever, CleverUsdcLp) * lpDepositShare) / 1e18;
            uint256 token2DepositAmount = (getTokenBalanceOfContract(Usdc, CleverUsdcLp) * 1e12 * lpDepositShare) / 1e18;
            valueTokens = ((token1DepositAmount * getPriceClever()) + (token2DepositAmount * 1e18)) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }
        else if (_depositToken == CleverEthLp) {
            IERC20(CleverEthLp).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            user.amountCleverEth = user.amountCleverEth + _inputAmt;

            uint256 lpSupply = getTokenSupply(CleverEthLp);
            uint256 lpDepositShare = (_inputAmt * 1e18 / lpSupply);
            uint256 token1DepositAmount = (getTokenBalanceOfContract(Clever, CleverEthLp) * lpDepositShare) / 1e18;
            uint256 token2DepositAmount = (getTokenBalanceOfContract(Eth, CleverEthLp) * lpDepositShare) / 1e18;
            valueTokens = ((token1DepositAmount * getPriceClever()) + (token2DepositAmount * getPriceEth())) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }
        else if (_depositToken == MushyFtmLp) {
            IERC20(MushyFtmLp).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            user.amountMushyFtm = user.amountMushyFtm + _inputAmt;

            uint256 lpSupply = getTokenSupply(MushyFtmLp);
            uint256 lpDepositShare = (_inputAmt * 1e18 / lpSupply);
            uint256 token1DepositAmount = (getTokenBalanceOfContract(Mushy, MushyFtmLp) * lpDepositShare) / 1e18;
            uint256 token2DepositAmount = (getTokenBalanceOfContract(Ftm, MushyFtmLp) * lpDepositShare) / 1e18;
            valueTokens = ((token1DepositAmount * getPriceMushy()) + (token2DepositAmount * getPriceFtm())) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }
        else if (_depositToken == MushyUsdcLp) {
            IERC20(MushyUsdcLp).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            user.amountMushyUsdc = user.amountMushyUsdc + _inputAmt;

            uint256 lpSupply = getTokenSupply(MushyUsdcLp);
            uint256 lpDepositShare = (_inputAmt * 1e18 / lpSupply);
            uint256 token1DepositAmount = (getTokenBalanceOfContract( Mushy, MushyUsdcLp) * lpDepositShare) / 1e18;
            uint256 token2DepositAmount = (getTokenBalanceOfContract(Usdc, MushyUsdcLp)  * 1e12 * lpDepositShare) / 1e18;
            valueTokens = ((token1DepositAmount * getPriceMushy()) + (token2DepositAmount * 1e18)) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }
        else if (_depositToken == Clever) {
            uint256 cleverContractBalnanceBefore = getTokenBalanceOfContract( Clever, address(this));
            IERC20(Clever).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            _inputAmt = getTokenBalanceOfContract( Clever, address(this)) - cleverContractBalnanceBefore;
            user.amountClever = user.amountClever + _inputAmt;

            valueTokens = (_inputAmt * getPriceClever()) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }
        else if (_depositToken == Mushy) {
            uint256 mushyContractBalnanceBefore = getTokenBalanceOfContract( Mushy, address(this));
            IERC20(Mushy).safeTransferFrom(address(msg.sender), address(this), _inputAmt);
            _inputAmt = getTokenBalanceOfContract( Mushy, address(this)) - mushyContractBalnanceBefore;
            user.amountMushy = user.amountMushy + _inputAmt;

            valueTokens = (_inputAmt * getPriceMushy()) / 1e18;
                
            mintAmount = (valueTokens * valueFactor) / 1e18;        
        }


        totalValueDeposited = totalValueDeposited + valueTokens;
        totalDeposits = totalDeposits + 1;

        // mint and transfer Bonds to user
        sbond.mint(address(msg.sender), mintAmount);
        user.userAmountBonds = user.userAmountBonds + mintAmount;
        totalBondsMinted = totalBondsMinted + mintAmount;

        
    emit MintBonds (msg.sender, _depositToken, _inputAmt, totalValueDeposited, mintAmount, user.userUnlockTime);        
    }

    // Withdraw LPs by depositing Bonds
    function withdrawLps(uint256 _burnAmt) public {
        UserInfo storage user = userInfo[msg.sender];
        require (user.userUnlockTime <= block.timestamp, "withdrawLps: LPs are still locked");
        require (user.userAmountBonds > 0, "withdrawLps: No Bonds in your Wallet");
        require (_burnAmt <= user.userAmountBonds, "withdrawLps: output amount to high");
        require (_burnAmt > 0, "withdrawLps: invalid output amount");

        // Calculate share of paid back Bonds
        uint256 sharePaidBack = (_burnAmt * 1e18) / user.userAmountBonds;

        // Transfer Bonds to Burn Address    
        IERC20(sbond).transferFrom(address(msg.sender), address(this), _burnAmt);
        user.userAmountBonds = user.userAmountBonds - _burnAmt;
        totalBondsBurned = totalBondsBurned + _burnAmt;

   
    emit WithdrawLps (msg.sender, sharePaidBack);
    }

}