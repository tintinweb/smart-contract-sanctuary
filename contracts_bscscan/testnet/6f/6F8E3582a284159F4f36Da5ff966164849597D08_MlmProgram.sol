/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.8.7;
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./Vault1.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external;

    function balanceOf(address dst) external view returns (uint256);

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
contract SquidToken is ERC20 , Ownable {
    uint256 _totalSupplyLimit = 400000000000000000000000000; // 400 million supply limit
    uint256 _initialTotalSupply = 90000000000000000000000000; // 90 million initial supply
    address _tokenB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // initially wbnb from testnet
    // address _tokenB = 0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692; // just for local
    address public _farmAddress = address(0);
    address public _mlmAddress = address(0);
    uint256 _endTime = 0;
    uint256 _vaultSupply = 0;
    uint256 public _devSupply = 0;
    uint256 _poolSupply = 0;
    uint256 public _dailySupply = 0;
    uint public totalVaults = 1; // must have 1 vault
    uint256 _vaultPercentage = 60;
    uint256 _poolPercentage = 40;
    uint256 _devPercentage = 15;
    address _initialVault = address(0);
    mapping(uint256 => address) public _vaultAddresses;
    mapping(address => bool) private _vaultExists;

    Farm _farm;
    constructor (string memory _tokenName,string memory _tokenSymbol,address farmAddress,address initialVault,address mlmAddress) ERC20(_tokenName,_tokenSymbol){
        setFarmAddress(farmAddress); // setting up farm address
        setMlmAddress(mlmAddress);// setting up mlm address
        _initialVault = initialVault; // setting up initial vault address
        mint(msg.sender, _initialTotalSupply);
        createPair(_tokenB);
        approve(address(this),_totalSupplyLimit);
        _vaultAddresses[1] = _initialVault; //setting up initial vault address
        _vaultExists[_initialVault] = true; // setting check for vault
        splitTokens(_initialTotalSupply);


    }

    //function to set _farmAddress
    function setFarmAddress(address farmAddress) public onlyOwner{
        _farmAddress = farmAddress;
        _farm = Farm(_farmAddress);

    }

    // function to set _mlmAddress
    function setMlmAddress(address mlmAddress) public onlyOwner{
        _mlmAddress = mlmAddress;
    }

    function setTokenB(address tokenB) public onlyOwner {
        _tokenB = tokenB;
    }


    function mint(address _to, uint256 _amount) private onlyOwner {
        require(_to != address(0));
        require(_amount > 0);
        _mint(_to,_amount);
    }

    function dailyMint() internal{
        require(_totalSupplyLimit > totalSupply());
        _mint(owner(),_dailySupply);
    }

    function createPair(address tokenB) onlyOwner public {
        _farm.createPair(address(this),tokenB,msg.sender);
    }

    function provideLiquidity(uint amountADesired,uint amountBDesired) onlyOwner public payable returns (uint amountA, uint amountB, uint liquidity) {
        approve(address(this),amountADesired);
        _transfer(msg.sender,_farmAddress,amountADesired);
        IERC20(_tokenB).transferFrom(msg.sender, _farmAddress, amountBDesired);
        return _farm.addLiquidity(address(this),_tokenB,amountADesired,amountBDesired,amountADesired,amountBDesired);
    }

    function getPair(address tokenB) public view returns(address){
        return _farm.getPair(address(this),tokenB);
    }

    function setEndTime(uint256 endTime) public onlyOwner{
        require(_endTime > block.timestamp);
        _endTime = endTime;
    }

    // function to set values for _vaultAddresses
    function addNewVault(address newVaultAddress) public onlyOwner returns (bool) {
        uint _newVaultNumber = totalVaults+1;
        _vaultAddresses[_newVaultNumber] = newVaultAddress;
        _vaultExists[newVaultAddress] = true;
        totalVaults+=1;
        return true;
    }


//    <------------------Helpers------------------->




    // function to divide uint256 to uint256
    function getDailySupplyLimit() internal view returns (uint256){
        return divide(_totalSupplyLimit , _endTime);
    }

    // function to divide uint256 to uint256
    function divide(uint256 _a, uint256 _b) internal pure returns (uint256){
        uint256 c = _a / _b;
        return c;
    }

    // function to calculate percentage
    function calculatePercentage(uint256 amount,uint percentage) private pure returns (uint256) {
        return amount * percentage / 100;
    }

    function splitTokens(uint256 amount) internal {
        _devSupply += calculatePercentage(amount,_devPercentage);
        uint256 _afterDevSupply = amount - _devSupply; // removing dev's cut
        _vaultSupply += calculatePercentage(_afterDevSupply,_vaultPercentage);
        _poolPercentage += calculatePercentage(_afterDevSupply,_poolPercentage);
        // transferring values
        uint256 amountPerVault = divide(_vaultSupply,totalVaults);
        for (uint i = 1; i <= totalVaults; i++) {
            transfer(_vaultAddresses[i],amountPerVault);
            _vaultExists[_vaultAddresses[i]] = true;
        }

    }

    function buyAndBurn (uint256 amount) external {
        require(amount > 0,'ERC20::Amount must be greator than 0');
        _transfer(address(this),_farmAddress,amount);
        _burn(address(this),amount);
    }

    function sendTokens(address from,address to,uint256 amount) external {
        _transfer(from,to,amount);
    }


//    <------------------Modifiers------------------->


    // modifier to check EndTime
    modifier checkEndTime() {
        require(block.timestamp < _endTime, "ERC20::End time reached");
        _;
    }

    modifier onlyValut() {
        require(msg.sender == owner() || _vaultExists[msg.sender],'ERC20::onlyValut can use this function');
        _;
    }







}
contract Farm is Ownable{

    address _router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address _factory = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
    IUniswapV2Router02 public iUniswapV2Router02;
    IUniswapV2Factory public iUniswapV2Factory;
    SquidToken public squidToken;
    address squidTokenAddress = address(0);
    address public WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    constructor () {
        setRouter(_router);
        setFactory(_factory);

    }

    //function to set squidToken address
    function setSquidTokenAddress(address _squidTokenAddress) public {
        squidTokenAddress = _squidTokenAddress;
        squidToken = SquidToken(squidTokenAddress);
    }

// function to set WETH address
    function setWETH(address wethAddress) public {
        WETH = wethAddress;
    }
//    function to set _router
    function setRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0),'invalid router address');
        _router = routerAddress;
        iUniswapV2Router02 = IUniswapV2Router02(routerAddress);
    }

    // function to set _factory
    function setFactory(address factoryAddress) public onlyOwner{
         require(factoryAddress != address(0),'invalid factory address');
        _factory = factoryAddress;
        iUniswapV2Factory = IUniswapV2Factory(_factory);
    }

    function createPair(address tokenA, address tokenB,address creator) public payable returns (address){
        require(creator == owner(),'invalid tokenA address');
        require(_factory != address(0), "factory address is invalid");
        require(tokenA != address(0), "tokenA address is invalid");
        require(tokenB != address(0),"tokenB address is invalid");
        require(tokenA != tokenB, "tokenA and tokenB cannot be the same");
        return iUniswapV2Factory.createPair(tokenA, tokenB);
    }

    function getPair (address tokenA, address tokenB) public view  returns (address) {
        require(_factory != address(0), "factory address is invalid");
        require(tokenA != address(0), "tokenA address is invalid");
        require(tokenB != address(0),"tokenB address is invalid");
        require(tokenA != tokenB, "tokenA and tokenB cannot be the same");
        return iUniswapV2Factory.getPair(tokenA, tokenB);
    }

    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin) public returns (uint amountA, uint amountB, uint liquidity) {
        // IERC20(squidTokenAddress).approve(address(this), amountADesired);
        // IERC20(squidTokenAddress).transferFrom(msg.sender,address(this),amountADesired);
        IERC20(WETH).approve(address(this), amountBDesired);
        IERC20(WETH).approve(_router, amountBDesired);
        IERC20(squidTokenAddress).approve(_router, amountADesired);
        require(tokenA != address(0), "tokenA address is invalid");
        require(tokenB != address(0),"tokenB address is invalid");
        require(tokenA != tokenB, "tokenA and tokenB cannot be the same");
        require(amountADesired > 0, "amountADesired must be greater than 0");
        return iUniswapV2Router02.addLiquidity(tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin,owner(),block.timestamp + 86400);
    }
    function addLiquidityETH(address token,uint256 amountTokenDesired,uint256 amountTokenMin,uint256 amountEthMin,address _investor) public returns (uint amountToken, uint amountETH, uint liquidity) {
        IERC20(WETH).approve(address(this), amountTokenDesired);
        IERC20(squidTokenAddress).approve(_router, amountTokenDesired);
        require(token != address(0), "tokenA address is invalid");
        require(amountTokenDesired > 0, "amountADesired must be greater than 0");
        return iUniswapV2Router02.addLiquidityETH(token,amountTokenDesired,amountTokenMin,amountEthMin,_investor,block.timestamp + 86400);
    }


    function _addLiquidityForOwner(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin) private returns (uint amountToken, uint amountETH, uint liquidity) {
        return iUniswapV2Router02.addLiquidityETH(token, amountTokenDesired, amountTokenMin, amountETHMin,owner(), block.timestamp + 86400);
    }

   

    function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _to) external {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(address(this), _amountIn);
        IERC20(_tokenIn).approve(_router, _amountIn);
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router02(iUniswapV2Router02).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

   function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
    ) external view returns (uint) {
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        // same length as path
        uint[] memory amountOutMins = IUniswapV2Router02(iUniswapV2Router02).getAmountsOut(
            _amountIn,
            path
        );

        return amountOutMins[path.length - 1];
    }

}
contract Vault1 is Ownable {
  address public _farmAddress;
  address public _rewardTokenAddress;
  address public _mlmAddress = address(0);
  address WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  uint rewardPerBlock = 100000000000000000; // 0.1 reward token per block
  uint rewardMultiplierOnInvestment = 3; //reward Multiplier
  Farm farm;
  address _router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  IUniswapV2Router02 public iUniswapV2Router02;
  SquidToken squidToken;
  uint _buyAndBurnPercentage = 10;
  uint _vaultPercentage = 45;
  uint _investmentPercentageAndMlm = 45;
  uint256 _amountInvestedInVault = 0;
  uint256 public _lockedBalance;
  MlmProgram mlm;
  

    //function to set reward per block
    function setRewardPerBlock(uint _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }
    // function to set _mlmAddress
    function setMlmAddress(address mlmAddress) public onlyOwner {
        require(mlmAddress != address(0),'Valut::invalid MLM address');
        _mlmAddress = mlmAddress;
        mlm = MlmProgram(payable(mlmAddress));
    }

    // set the farm address
    function setFarm(address farmAddress) public onlyOwner {
        require(farmAddress != address(0),'Vault::invalid farm address');
        _farmAddress = farmAddress;
        farm = Farm(farmAddress);
    }
    //function to set the reward token address
    function setRewardToken(address rewardTokenAddress) public onlyOwner {
        require(rewardTokenAddress != address(0),'Vault::invalid reward token address');
        _rewardTokenAddress = rewardTokenAddress;
        squidToken = SquidToken(rewardTokenAddress);
    }

    //function to set _amountInvestedInVault
    function setAmountInvestedInVault(uint256 amountInvestedInVault) internal onlyOwner {
        require(amountInvestedInVault != 0);
        _amountInvestedInVault += amountInvestedInVault;
    }

  mapping (address => uint256) public investedAmount; // how much user has invested
  mapping (address => uint256) public stakedAmount; // how much user has invested
  mapping (address => uint256) public rewardDepth; // amount that user will be rewarded overtime
  mapping (address => uint256) public earningBlock; // how much Squid Token investor has earned till now (address ,blockNumber)
  mapping (address => uint256) public amountToBeRewarded; // amount that user has earned
  mapping (address => bool) public userInvested; // if user has invested



  function Invest(address _investor, uint amount,address _referal) public payable returns (uint256 , uint256) {
      require(amount > 0, 'Vault::invalid amount');
      if(_referal == address(0) || !userInvested[_referal]) _referal = owner();
      mlm.addMLM(_investor,mlm.addressToId(_referal)); //getting referal id
      IERC20(WETH).transferFrom(msg.sender,address(this),amount);
      uint256 amountIn = calculatePercentage(amount,_buyAndBurnPercentage);
      uint256 amountOutEst = farm.getAmountOutMin(WETH,_rewardTokenAddress,amountIn);
      swap(WETH,_rewardTokenAddress,amountIn,amountOutEst,address(this)); // doing it for buyAndBurn user will get tokens on point
      IERC20(WETH).transfer(_mlmAddress,calculatePercentage(amount,_investmentPercentageAndMlm)); //45 send amount to mlm
      IERC20(WETH).transfer(owner(),calculatePercentage(amount,_investmentPercentageAndMlm)); //45 send amount to mlm
      rewardDepth[_investor] += rewardMultiplier(amountOutEst);
      investedAmount[_investor] += calculatePercentage(amount,_investmentPercentageAndMlm);
      userInvested[_investor] = true;
      earningBlock[_investor] = block.number - 1; // just to be safe
      amountToBeRewarded[_investor] = amountOutEst;
      _lockedBalance+=calculatePercentage(amount,_investmentPercentageAndMlm);
      return (rewardDepth[_investor],investedAmount[_investor]);
  }


    //when user stakes then 10 amount is used to buy and burn but is swapped from pancake swap so he can earn rewards
//   function Stake(address _investor ,uint256 amount) public payable returns (uint256 ,uint256) {
//     //   require(userInvested[_investor],'Vault::user has not invested yet');
//       // 10 % buyAndBurn
//       uint256 buyAndBurnAmount = calculatePercentage(amount,_buyAndBurnPercentage);
//       // now purchase gym
//       uint256 rewardToGet = farm.getAmountOutMin(WETH,_rewardTokenAddress,buyAndBurnAmount); // estimated rewards
//       rewardDepth[_investor] += rewardToGet; // tokens from vault to user
//       // split amount into 2 equals;
//       amount = amount - buyAndBurnAmount;
//       uint256 wbnbAmount = calculatePercentage(amount,50); // wbnb amount
//       uint256 expectedOutRewards = amount - wbnbAmount;
//       uint256 rewardToAddInPool = farm.getAmountOutMin(WETH,_rewardTokenAddress,wbnbAmount);
//       uint256 wbnbToAddInPool = farm.getAmountOutMin(_rewardTokenAddress,WETH,expectedOutRewards);
//       IERC20(WETH).transferFrom(msg.sender,_farmAddress,wbnbToAddInPool);
//       squidToken.sendTokens(msg.sender,_farmAddress,rewardToAddInPool);

//       farm.addLiquidityETH(_rewardTokenAddress,rewardToAddInPool,rewardToAddInPool,wbnbToAddInPool,_investor);

//       stakedAmount[_investor] += amount;


//       return (rewardDepth[_investor],stakedAmount[_investor]);


//   }


  function WithdrawInvestments(address _investor) public payable returns (bool) {
    require(userInvested[_investor],'Vault::user has not invested yet');
    IERC20(WETH).transferFrom(owner(),_investor,investedAmount[_investor]);// send back the amount invested
    _lockedBalance-=investedAmount[_investor];
    investedAmount[_investor] = 0;
    rewardDepth[_investor] = 0; // resetting rewardDepth for user
    userInvested[_investor] = false;
    return true;
  }

//   function WithdrawStake(address _investor) public payable {
//     // actually removing liquidity
//       return;
//   }

  function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _to) internal returns (uint[] memory amounts) {
        // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(address(this), _amountIn);
        IERC20(_tokenIn).approve(_router, _amountIn);
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        iUniswapV2Router02 = IUniswapV2Router02(_router);
       return IUniswapV2Router02(iUniswapV2Router02).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

  function claimRewards() public payable returns (bool){
    require(rewardDepth[msg.sender] != 0,'Vault::user has not earned rewards yet');
    squidToken.sendTokens(address(this),msg.sender,amountToBeRewarded[msg.sender]);
    rewardDepth[msg.sender] -= showRewardsEarned(msg.sender); // remaining amount
    earningBlock[msg.sender] = block.number;
    return true;
  }

//   function claimRewardsAndInvest() public payable returns (bool){
//      uint256 expectedOutAmount = farm.getAmountOutMin(_rewardTokenAddress,farm.WETH(),rewardDepth[msg.sender]);
//       farm.swap(_rewardTokenAddress,farm.WETH(),calculatePercentage(rewardDepth[msg.sender],50),expectedOutAmount,msg.sender);
//       farm.addLiquidity(_rewardTokenAddress,farm.WETH(),rewardDepth[msg.sender],50,expectedOutAmount,50);
//       return true;
//   }


  function rewardMultiplier (uint256 amount) internal view returns (uint256) {
      return amount * rewardMultiplierOnInvestment;
  }


  function calculatePercentage(uint256 amount,uint percentage) private pure returns (uint256) {
        return amount * percentage / 100;
  }

  function showRewardsEarned(address _investor) public view returns (uint256) {
      uint256 totalBlocks = block.number - earningBlock[_investor];
      uint256 rewards = totalBlocks * rewardPerBlock;
      rewards += amountToBeRewarded[_investor];
      if (rewards > rewardDepth[_investor]) rewards = rewardDepth[_investor];
      return rewards;
  }



  function balanceOfTokens() public view returns (uint256) {
      return squidToken.balanceOf(address(this));
  }


}
contract MlmProgram is Ownable {
    uint256 public constant denominator = 1e12;
    address deployerAddress = owner();
    address wbnbAddress = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public bankAddress = address(0);
    uint256 public currentId;
    uint8[15] public directReferralBonuses;
    uint256[15] public levels;
    mapping(address => uint256) public addressToId; //refferal id to address
    mapping(uint256 => address) public idToAddress; //refferal address to id
    mapping(address => uint256) public investment;
    mapping(address => address) public userToReferrer;
    mapping(address => uint256) public scoring; // user scores;
    
    event NewReferral(address indexed user, address indexed referral);
    event ReferralRewardReceived(address indexed user, address indexed referral, uint256 level, uint256 amount, address wantAddress);

    constructor () {
        directReferralBonuses = [10, 7, 5, 4, 4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 1];
        addressToId[owner()] = 1;
        idToAddress[1] = owner();
        userToReferrer[owner()] = owner();
        currentId = 2;
        levels = [0.12 ether, 2 ether, 3 ether, 4 ether, 5 ether, 6 ether, 7 ether, 8 ether, 9 ether, 10 ether, 11 ether, 12 ether, 13 ether, 14 ether,15 ether];
    }
    
    receive() external payable {}

    fallback() external payable {}

    function updateScoring(address _token, uint256 _score) external {
        scoring[_token] = _score;
    }

    function _addUser(address _user, address _referrer) private {
        addressToId[_user] = currentId;
        idToAddress[currentId] = _user;
        userToReferrer[_user] = _referrer;
        currentId++;
        emit NewReferral(_referrer, _user);
    }
    
    function addMLM(address _user, uint256 _referrerId) external {
        address _referrer = userToReferrer[_user];

        if (_referrer == address(0)) {
            _referrer = idToAddress[_referrerId];
        }

        require(_user != address(0), "MLM::user is zero address");

        require(_referrer != address(0), "MLM::referrer is zero address");

        require(
            userToReferrer[_user] == address(0) || userToReferrer[_user] == _referrer,
            "MLM::referrer is zero address"
        );

        // If user didn't exsist before
        if (addressToId[_user] == 0) {
            _addUser(_user, _referrer);
        }
        
        
        
    }
    
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user
    ) public  {
        uint256 index;
        uint256 length = directReferralBonuses.length;

        investment[_user] += (_wantAmt * scoring[_wantAddr]) / denominator;
        IERC20 token = IERC20(_wantAddr);

        if (_wantAddr != wbnbAddress) {
            while (index < length && addressToId[userToReferrer[_user]] != 1) {
                address referrer = userToReferrer[_user];
                if (investment[referrer] >= levels[index]) {
                    uint256 reward = (_wantAmt * directReferralBonuses[index]) / 100;
                    token.transfer(referrer, reward);
                    emit ReferralRewardReceived(referrer, _user, index, reward, _wantAddr);
                }
                _user = userToReferrer[_user];
                index++;
            }

            if (index != length) {
                token.transfer(owner(), token.balanceOf(address(this)));
            }

            return;
        }

        while (index < length && addressToId[userToReferrer[_user]] != 1) {
            address referrer = userToReferrer[_user];
            if (investment[referrer] >= levels[index]) {
                uint256 reward = (_wantAmt * directReferralBonuses[index]) / 100;
                IWETH(wbnbAddress).withdraw(reward);
                payable(referrer).transfer(reward);
                emit ReferralRewardReceived(referrer, _user, index, reward, _wantAddr);
            }
            _user = userToReferrer[_user];
            index++;
        }

        if (index != length) {
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }
    
    function setVaultAddress(address _bank) external onlyOwner {
        bankAddress = _bank;
    }
    
     modifier onlyValut() {
        require(msg.sender == owner() || msg.sender == bankAddress ,'ERC20::onlyValut can use this function');
        _;
    }
    
}