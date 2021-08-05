/**
 *Submitted for verification at Etherscan.io on 2020-11-24
*/

pragma solidity ^0.6.12;

// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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


// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

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

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

library Address {

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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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


// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

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


// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}

// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

contract ERC20 is IERC20, Whitelist {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    uint256 _totalSupply;
    uint256 INITIAL_SUPPLY = 100000e18; //available supply
    uint256 BURN_RATE = 1; //burn every per txn
	uint256 SUPPLY_FLOOR = 50; // % of supply
	uint256 DEFLATION_START_TIME = now + 30 days;

    string  _name;
    string  _symbol;
    uint8 _decimals;


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        
		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		
		if(now >= DEFLATION_START_TIME){
		    uint256 _burnedAmount = amount * BURN_RATE / 100;
    		if (_totalSupply - _burnedAmount < INITIAL_SUPPLY * SUPPLY_FLOOR / 100 || isWhitelisted(sender)) {
    			_burnedAmount = 0;
    		}
    		if (_burnedAmount > 0) {
    			_totalSupply = _totalSupply.sub(_burnedAmount);
    		}
    		amount = amount.sub(_burnedAmount);
		}
		
		_balances[recipient] = _balances[recipient].add(amount);
		
        emit Transfer(sender, recipient, amount);
    }

  
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

contract Token is ERC20{

	constructor (string memory name, string memory symbol) public {
        _name = "Buffalo Finance";
        _symbol = "BUFF";
        _decimals = 18;
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = _balances[msg.sender].add(INITIAL_SUPPLY);
    }

	
}

contract Staking is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for Token;
    using Address for address;

    Token public token;
    mapping(address => uint256) public _stakerTokenBalance;
    uint public _totalTokenBalance;

// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------

    // annual yield period
    uint256 public constant DURATION = 365 days;
    uint256 public constant MINIMUM_AMOUNT = 1e16;
    uint256 public _poolAmount = 0;
    mapping(address => uint256) public _stakerRewardRate;
    mapping(address => uint256) public _stakerStakingProgram;
    
    bool public haveStarted = false;
    mapping(address => uint256) public _stakerLastClaimTime;
    mapping(address => uint256) public _stakerStakingTime;
    mapping(address => uint256) public _stakerTokenRewards;
    mapping(address => uint256) public _stakerTokenRewardsClaimed;

    event Stake(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);
    event Claim(address indexed to, uint amount);


    constructor(address _token) public{
        token = Token(_token);
    }


    function stake(uint program, uint amount) public shouldStarted {
        
        require(_stakerStakingProgram[msg.sender] == 0, "Withdraw your current program.");

        _stakerStakingTime[msg.sender] = now;
        _stakerStakingProgram[msg.sender] = program;

        updateRewards(msg.sender);
        
        require(!address(msg.sender).isContract(), "Please use your individual account.");
        require(amount >= MINIMUM_AMOUNT, "Should stake at least 0.01 Token.");
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        _totalTokenBalance = _totalTokenBalance.add(amount);
        _stakerTokenBalance[msg.sender] = _stakerTokenBalance[msg.sender].add(amount);
        _stakerLastClaimTime[msg.sender] = now;
        
        emit Stake(msg.sender, amount);
    }

    function withdraw(uint amount) public shouldStarted {
        updateRewards(msg.sender);
        
        require(amount <= _stakerTokenBalance[msg.sender] && _stakerTokenBalance[msg.sender] > 0, "Bad withdraw.");

        if(_stakerStakingProgram[msg.sender] == 1){
            require(now >= _stakerStakingTime[msg.sender] + 7 days, "Early withdrawal available after 7 days and no reward.");
        }else if (_stakerStakingProgram[msg.sender] == 2){
            require(now >= _stakerStakingTime[msg.sender] + 30 days, "Early withdrawal available after 30 days and no reward.");
        }else if (_stakerStakingProgram[msg.sender] == 3){
            require(now >= _stakerStakingTime[msg.sender] + 60 days, "Early withdrawal available after 60 days and no reward.");
        }
        
        _totalTokenBalance = _totalTokenBalance.sub(amount);
        _stakerTokenBalance[msg.sender] = _stakerTokenBalance[msg.sender].sub(amount);
        _stakerTokenRewardsClaimed[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function claim(uint amount) public shouldStarted {
        updateRewards(msg.sender);
        
        require( _stakerTokenRewards[msg.sender] > 0, "Bad claim.");
        require( amount <= _poolAmount && _poolAmount > 0, "The Pool is Empty.");
        
        _stakerTokenRewards[msg.sender] = _stakerTokenRewards[msg.sender].sub(amount);
        _stakerTokenRewardsClaimed[msg.sender] = _stakerTokenRewardsClaimed[msg.sender].add(amount);
        _poolAmount = _poolAmount.sub(amount);
        _stakerLastClaimTime[msg.sender] = now;
        token.safeTransfer(msg.sender, amount);
    
        emit Claim(msg.sender, amount);
    }

    modifier shouldStarted() {
        require(haveStarted == true, "Have not started.");
        _;
    }

    function getRewardsAmountPerSeconds(address account) public view returns(uint256) {
        return balanceOf(account).mul(_stakerRewardRate[msg.sender]).div(100)
                .div(DURATION);
    }
    
    function balanceOf(address account) public view returns(uint256) {
        return _stakerTokenBalance[account];
    }
    
    function getTotalRewardsAmount(address account) public view returns (uint256) {
   
        return block.timestamp.sub(_stakerStakingTime[account]).mul(getRewardsAmountPerSeconds(account));
    }
    
    function addPoolAmount(uint amount) external payable onlyOwner{
        
        require(amount > 0, "Should add be more than 0 Token.");
        _poolAmount = _poolAmount.add(amount);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }
    
    function updatePoolAmount(uint amount) public onlyOwner{
        _poolAmount = amount;
    }

    function withdrawPoolAmount(uint amount) public onlyOwner{
        require( amount <= _poolAmount && _poolAmount > 0, "The Pool is Empty.");
        _poolAmount = _poolAmount.sub(amount);
        token.safeTransfer(msg.sender, amount);
    }


    function updateRewards(address account) internal {
        
        if(_stakerStakingProgram[msg.sender] == 1 && now >= _stakerStakingTime[msg.sender] + 30 days){
             _stakerRewardRate[msg.sender] = 35;
        }else if(_stakerStakingProgram[msg.sender] == 2 && now >= _stakerStakingTime[msg.sender] + 90 days){
            _stakerRewardRate[msg.sender] = 55;
        }else if(_stakerStakingProgram[msg.sender] == 3 && now >= _stakerStakingTime[msg.sender] + 180 days){
            _stakerRewardRate[msg.sender] = 75;
        }

        if (account != address(0)) {
            _stakerTokenRewards[account] = getTotalRewardsAmount(account) - _stakerTokenRewardsClaimed[account];
        }
    }



    function startStaking() external onlyOwner {
        updateRewards(address(0));
        haveStarted = true;
    }


}

// ----------------------------------------------------------------------------
// Buffalo Finance NEXT GENERATION DEFLATIONARY DEFI PLATFORM
// Buffalo Finance is a useful, deflationary, next generation DeFi platform where users can easily stake, farm, lend/borrow, and swap crypto assets. Buffalo Finance Platform offers you a variety of facilities for keeping securely and managing your crypto assets, as well as high returns with advantageous rates for your assets.
// Symbol       : BUFF
// Name         : Buffalo Finance
// Total supply : 100,000
// www.buffalodefi.com
// www.twitter.com/buffalo_finance
// https://t.me/buffalofinanceann
// https://t.me/buffalofinance
// www.medium.com/@buffalofinance
// ----------------------------------------------------------------------------