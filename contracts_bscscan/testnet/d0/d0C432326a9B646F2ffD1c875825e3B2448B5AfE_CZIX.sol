// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address payable msgSender = payable(_msgSender());
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address payable) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IDEXV2Factory {
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
interface IDEXV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
interface IDEXV2Router01 {
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


interface IDEXV2Router02 is IDEXV2Router01 {
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
contract CZIX is Ownable{

    IDEXV2Router02 public Router;
    address public Pair;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public accountLimit;
    uint256 public singleTransferLimit;
    uint256 public swapCooldownDuration;


    struct AccountStatus {
        bool feeExcluded;
        bool accountLimitExcluded;
        bool transferLimitExcluded;
        bool blacklistedBot;
        uint256 swapCooldown;
    }

    mapping(address => AccountStatus) public statuses;
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Burn(address indexed from, uint256 value);
	
    event Freeze(address indexed from, uint256 value);
	
    event Unfreeze(address indexed from, uint256 value);

    event FeeExclusion(address indexed account, bool isExcluded);

    event AccountLimitExclusion(address indexed account, bool isExcluded);

    event TransferLimitExclusion(address indexed account, bool isExcluded);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        address _router
        ) {
        
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        totalSupply = initialSupply * 10 ** decimals;                        // Update total supply

        // Set router and create swap pair
        _setRouterAddress(_router);

        // Exclude the owner and this contract from transfer restrictions
        statuses[owner()] = AccountStatus(true, true, true, false, 0);
        statuses[address(this)] = AccountStatus(true, true, true, false, 0);

        // Exclude swap pair and swap router from account limit
        statuses[Pair].accountLimitExcluded = true;
        statuses[address(Router)].accountLimitExcluded = true;

        // Set initial settings
        accountLimit = SafeMath.div(totalSupply, 100);
        singleTransferLimit = SafeMath.div(totalSupply, 1000);
        swapCooldownDuration = 1 minutes;

        balanceOf[msg.sender] = initialSupply ;              // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address recipient, uint256 _value) public {
        require(recipient != address(0));                                // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0); 
        require(balanceOf[msg.sender] >= _value);                 // Check if the sender has enough
        require(balanceOf[recipient] + _value >= balanceOf[recipient]);  // Check for overflows
        _checkBotBlacklisting(msg.sender, recipient);
        _checkTransferLimit(msg.sender, recipient, _value);
        _checkAccountLimit(msg.sender, _value, balanceOf[recipient]);
        _checkSwapCooldown(msg.sender, recipient);
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[recipient] = SafeMath.add(balanceOf[recipient], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, recipient, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address sender, address recipient, uint256 _value) public returns (bool success) {
        require(recipient != address(0));                                // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0); 
        require(balanceOf[sender] >= _value);                 // Check if the sender has enough
        require(balanceOf[recipient] + _value >= balanceOf[recipient]);  // Check for overflows
        require(_value <= allowance[sender][msg.sender]);     // Check allowance
        _checkBotBlacklisting(sender, recipient);
        _checkTransferLimit(sender, recipient, _value);
        _checkAccountLimit(sender, _value, balanceOf[recipient]);
        _checkSwapCooldown(sender, recipient);
        balanceOf[sender] = SafeMath.sub(balanceOf[sender], _value);                           // Subtract from the sender
        balanceOf[recipient] = SafeMath.add(balanceOf[recipient], _value);                             // Add the same to the recipient
        allowance[sender][msg.sender] = SafeMath.sub(allowance[sender][msg.sender], _value);
        emit Transfer(sender, recipient, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
		require(_value > 0); 
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.sub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
		require(_value > 0);  
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.add(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);            // Check if the sender has enough
		require(_value > 0); 
        freezeOf[msg.sender] = SafeMath.sub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	
	
    function setFeeExclusion(address account, bool isExcluded) public onlyOwner {
        statuses[account].feeExcluded = isExcluded;
        emit FeeExclusion(account, isExcluded);
    }

    function setAccountLimitExclusion(address account, bool isExcluded) public onlyOwner {
        statuses[account].accountLimitExcluded = isExcluded;
        emit AccountLimitExclusion(account, isExcluded);
    }

    function setTransferLimitExclusion(address account, bool isExcluded) public onlyOwner {
        statuses[account].transferLimitExcluded = isExcluded;
        emit TransferLimitExclusion(account, isExcluded);
    }

    function setBotsBlacklisting(address[] memory bots, bool isBlacklisted) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            statuses[bots[i]].blacklistedBot = isBlacklisted;
        }
    }

    function _checkBotBlacklisting(address sender, address recipient) internal view {
        require(!statuses[sender].blacklistedBot, 'Sender is blacklisted');
        require(!statuses[recipient].blacklistedBot, 'Recipient is blacklisted');
    }

    function _checkTransferLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (!statuses[sender].transferLimitExcluded && !statuses[recipient].transferLimitExcluded) {
            require(amount <= singleTransferLimit, 'Transfer amount exceeds the limit');
        }
    }

    function _checkAccountLimit(
        address recipient,
        uint256 amount,
        uint256 recipientBalance
    ) internal view {
        if (!statuses[recipient].accountLimitExcluded) {
            require(recipientBalance + amount <= accountLimit, 'Recipient has reached account tokens limit');
        }
    }

    function _checkSwapCooldown(address sender, address recipient) internal {
        if (swapCooldownDuration > 0 && sender == Pair && recipient != address(Router)) {
            require(statuses[recipient].swapCooldown < block.timestamp, 'Swap is cooling down');
            statuses[recipient].swapCooldown = block.timestamp + swapCooldownDuration;
        }
    }
    //set Router address
    function _setRouterAddress(address routerAddress_) internal {
        IDEXV2Router02 _Router = IDEXV2Router02(routerAddress_);
        Pair = IDEXV2Factory(_Router.factory()).createPair(address(this), _Router.WETH());
        Router = _Router;
    }

    // set router owner just incase
    function ChangeRouter(address _router) public onlyOwner {
        require(IDEXV2Router02(_router) != Router,"Already Set");
        _setRouterAddress(_router);
    }

    function setAccountLimit(uint256 amount) public onlyOwner {
        accountLimit = amount;
    }

    function setSingleTransferLimit(uint256 amount) public onlyOwner {
        singleTransferLimit = amount;
    }

    function setSwapCooldownDuration(uint256 duration) public onlyOwner {
        swapCooldownDuration = duration;
    }

	// can accept ether
	receive() external payable {}

    // transfer balance to owner
	function withdrawEther(uint256 amount) public onlyOwner{
		owner().transfer(amount);
	}

}