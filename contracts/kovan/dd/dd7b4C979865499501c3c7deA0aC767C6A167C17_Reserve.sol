/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// File: contracts/common/Context.sol

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/common/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// File: contracts/interface/IERC20.sol

pragma solidity ^0.6.6;

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

// File: contracts/interface/IAToken.sol

pragma solidity ^0.6.6;

interface IaToken {
    function balanceOf(address _user) external view returns (uint256);
    function redeem(uint256 _amount) external;
}

// File: contracts/interface/IAaveLendingPool.sol

pragma solidity ^0.6.6;

interface IAaveLendingPool {
    function deposit(address _reserve, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    event Deposit(address indexed _reserve, address indexed _user, uint256 _amount, uint16 indexed _referral, uint256 _timestamp);
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
}

// File: contracts/interface/IUniswapV2Router02.sol

pragma solidity ^0.6.6;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

// File: contracts/Reserve.sol

pragma solidity ^0.6.6;







contract Reserve is Ownable {

    event Invested(address indexed _usdcAddress, uint256 _usdcAmount, address indexed _aTokenAddress, uint256 _aTokenAmount);
    event Withdrawn(address indexed _aTokenAddress, uint256 _aTokenAmount, address indexed _usdcAddress, uint256 _usdcAmount);
    event Transferred(address indexed _recipientAddress, address indexed _tokenAddress, uint256 _amount);
    event TokenSwapped(address indexed _tokenAddress, uint256 _tokenAmount, address indexed _usdcAddress, uint256 _usdcBalance);
    event OmsTokenConfigured(address indexed _omsToken, uint256 _minReserveAmount);
    event OmsxTokenConfigured(address indexed _omsxToken, uint256 _minReserveAmount);
    event InitialUSDInvestmentConfigured(uint256 _amount);

    address public cascade;
    address public reserveNg;

    IERC20 public usdc;
    IaToken public aToken;
    IAaveLendingPool public aaveLendingPool;
    IUniswapV2Router02 public uniswapRouter;

    IERC20 public oms;
    IERC20 public omsx;

    uint256 MAX_INT = 2**256 - 1;

    address[] omsUsdcPath;
    address[] omsxUsdcPath;

    uint256 initialUSDInvestmentAmount;
    uint256 minOmsReserveAmount;
    uint256 minOmsxReserveAmount;
    
    constructor(address _cascade, address _usdc, address _aToken, address _aaveLendingPool, address _uniswapRouter) public Ownable() {
        cascade = address(_cascade);

        usdc = IERC20(_usdc);
        aToken = IaToken(_aToken);
        aaveLendingPool = IAaveLendingPool(_aaveLendingPool);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        
        // approve Aave Lending Pool to be able to transact on our usdc tokens.
        usdc.approve(address(aaveLendingPool), MAX_INT);
    }

    function setOmsToken(address _omsToken, uint256 _minReserveAmount) external onlyOwner {
        oms = IERC20(_omsToken);
        minOmsReserveAmount = _minReserveAmount;
        omsUsdcPath = [ address(oms), address(usdc) ];
        emit OmsTokenConfigured(_omsToken, _minReserveAmount);
    }

    function setOmsxToken(address _omsxToken, uint256 _minReserveAmount) external onlyOwner {
        omsx = IERC20(_omsxToken);
        minOmsxReserveAmount = _minReserveAmount;
        omsxUsdcPath = [ address(omsx), address(usdc) ];
        emit OmsxTokenConfigured(_omsxToken, _minReserveAmount);
    }

    function setInitialUSDInvestment(uint256 _amount) external onlyOwner {
        initialUSDInvestmentAmount = _amount;
        emit InitialUSDInvestmentConfigured(_amount);
    }

    function updateCascade(address _cascade) external onlyOwner {
        cascade = _cascade;
    }

    function updateReserveNg(address _reserveNg) external onlyOwner {
        reserveNg = _reserveNg;
    }

    function startInvestment() external onlyOwner {
        _invest(initialUSDInvestmentAmount);
    }

    function growInvestment() external onlyOwner {
        _sellExcessOmsTokens();
        _sellExcessOmsxTokens();

        uint256 usdcAmount = this.usdcBalance();
        if (usdcAmount > 0) {
            _invest(usdcAmount);
        }
    }
    
    function withdrawAll() external onlyOwner {
        // get balance
        uint256 investedAmount = this.investmentBalance();
        require(investedAmount > 0, 'Must have some balance in the invested amount to withdraw');

        // withdraw all
        _withdraw(investedAmount);
    }

    function transfer(uint256 _amount) external onlyOwner {
        usdc.transfer(cascade, _amount);
        emit Transferred(address(cascade), address(usdc), _amount);
    }

    function transferReserve() external onlyOwner {
        oms.transfer(reserveNg, minOmsReserveAmount);
        emit Transferred(address(reserveNg), address(oms), minOmsReserveAmount);

        omsx.transfer(reserveNg, minOmsxReserveAmount);
        emit Transferred(address(reserveNg), address(omsx), minOmsxReserveAmount);
    }

    function investmentBalance() external view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function usdcBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function _invest(uint256 _amount) internal {
        aaveLendingPool.deposit(address(usdc), _amount, address(this), 0);
        emit Invested(address(usdc), _amount, address(aToken), this.investmentBalance());
    }

    function _withdraw(uint256 _amount) internal {
        aaveLendingPool.withdraw(address(usdc), _amount, address(this));
        emit Withdrawn(address(aToken), _amount, address(usdc), this.usdcBalance());
    }

    function _sellExcessOmsTokens() internal {
        // check balance
        uint256 currentBalance = oms.balanceOf(address(this));
        
        if (currentBalance > minOmsReserveAmount) {
            // determine how many tokens we want to sell off by getting balance and deducting minimum holding amount
            uint256 amount = currentBalance - minOmsReserveAmount;

            // approve Uniswap Router to be able to transact on our oms tokens.
            oms.approve(address(uniswapRouter), amount);
        
            // trigger the swap contract to exchange our token for usdc
            uniswapRouter.swapExactTokensForTokens(
                amount, 
                0, 
                omsUsdcPath, 
                address(this), 
                now + 600);

            emit TokenSwapped(address(oms), amount, address(usdc), this.usdcBalance());
        } else {
            emit TokenSwapped(address(oms), 0, address(usdc), this.usdcBalance());
        }
    }

    function _sellExcessOmsxTokens() internal {
        // check balance
        uint256 currentBalance = omsx.balanceOf(address(this));
        
        if (currentBalance > minOmsxReserveAmount) {
            // determine how many tokens we want to sell off by getting balance and deducting minimum holding amount
            uint256 amount = currentBalance - minOmsxReserveAmount;

            // approve Uniswap Router to be able to transact on our omsx tokens.
            omsx.approve(address(uniswapRouter), amount);
        
            // trigger the swap contract to exchange our token for usdc
            uniswapRouter.swapExactTokensForTokens(
                amount, 
                0, 
                omsxUsdcPath, 
                address(this), 
                now + 600);

            emit TokenSwapped(address(omsx), amount, address(usdc), this.usdcBalance());
        } else {
            emit TokenSwapped(address(omsx), 0, address(usdc), this.usdcBalance());
        }
    }
}