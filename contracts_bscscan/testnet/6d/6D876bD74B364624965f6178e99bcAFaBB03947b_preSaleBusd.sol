pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IHodlStake{
    
    function stake(uint256 amount) external;

    function unstake() external;

    function withdrawunstake() external;

    function setweights(uint256 Bronze, uint256 Silver , uint256 Gold) external;

    function distributioncalculation(uint256 _amount)external view returns(uint256 [4] memory);

    function usertier(address user) external view returns(uint256);

    function checktier(address us,uint256 val) external ;
    
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier:MIT

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import './IERC20.sol';
import '../Libraries/SafeMath.sol';
import '../Interfaces/IPancakeRouter02.sol';
import '../Interfaces/IHodlStake.sol';
import '../AbstractContracts/ReentrancyGuard.sol';

interface IPreSale{

    function owner() external view returns(address);
    function tokenOwner() external view returns(address);
    function deployer() external view returns(address);
    function token() external view returns(address);
    function busd() external view returns(address);

    function tokenPrice() external view returns(uint256);
    function preSaleTime() external view returns(uint256);
    function claimTime() external view returns(uint256);
    function minAmount() external view returns(uint256);
    function maxAmount() external view returns(uint256);
    function softCap() external view returns(uint256);
    function hardCap() external view returns(uint256);
    function listingPrice() external view returns(uint256);
    function liquidityPercent() external view returns(uint256);

    function allow() external view returns(bool);

    function initialize(
        address _tokenOwner,
        IERC20 _token,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent,
        address _routerAddress
    ) external ;

    
}

pragma solidity ^0.8.4;

//  SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import './Interfaces/IPreSale.sol';

contract preSaleBusd is ReentrancyGuard {

    using SafeMath for uint256;
    
    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IERC20 public busd;
    IPancakeRouter02 public routerAddress;
    IHodlStake public stake;

    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public adminFeePercent;
    uint256 public soldTokens;
    uint256 public preSaleTokens;
    uint256 public totalUser;
    uint256 public amountRaised;

    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public bnbBalance;

    bool public allow;
    bool public canClaim;

    modifier onlyAdmin(){
        require(msg.sender == admin,"HODL: Not an admin");
        _;
    }

    modifier onlyTokenOwner(){
        require(msg.sender == tokenOwner,"HODL: Not a token owner");
        _;
    }

    modifier allowed(){
        require(allow == true,"HODL: Not allowed");
        _;
    }
    
    event tokenBought(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);

    event tokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event tokenUnSold(address indexed user, uint256 indexed numberOfTokens);
    
    constructor() {
        deployer = msg.sender;
        allow = true;
        admin = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
        busd = IERC20(0xEF5476A98aE30eb71241780ED83BF53ca00C2f5c);
        stake = IHodlStake(0xA5e4D379be259e684E80cF5a6e65113f6D6316f5);
        adminFeePercent = 2;
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _tokenOwner,
        IERC20 _token,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent,
        address _routerAddress
    ) external {
        require(msg.sender == deployer, "HODL: FORBIDDEN"); // sufficient check
        tokenOwner = payable(_tokenOwner);
        token = _token;
        tokenPrice = _tokenPrice;
        preSaleTime = _presaleTime;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        hardCap = _hardCap;
        softCap = _softCap;
        listingPrice = _listingPrice;
        liquidityPercent = _liquidityPercent;
        routerAddress = IPancakeRouter02(_routerAddress);
        preSaleTokens = busdToToken(hardCap);
    }
    
    // to buy token during preSale time => for web3 use
    function buyToken(uint256 _amountBusd) public allowed isHuman{
        require(block.timestamp < preSaleTime,"HODL: Presale time over"); // time check
        require(getContractBusdBalance() <= hardCap,"HODL: Hardcap reached");
        uint256 numberOfTokens = busdToToken(_amountBusd);
        uint256 maxBuy = busdToToken(maxAmount);
        require(_amountBusd >= minAmount && _amountBusd <= maxAmount,"HODL: Invalid Amount");
        require(numberOfTokens.add(tokenBalance[msg.sender]) <= maxBuy,"HODL: Amount exceeded");

        uint256[4] memory tierAmount = stake.distributioncalculation(preSaleTokens);
        uint256 userTier = stake.usertier(msg.sender);
        require(numberOfTokens.add(tokenBalance[msg.sender]) <= tierAmount[userTier],"HODL: Amount exceeded tier limit");
        
        if(tokenBalance[msg.sender] == 0){
            totalUser++;
        }
        busd.transferFrom(msg.sender, address(this), _amountBusd);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        bnbBalance[msg.sender] = bnbBalance[msg.sender].add(_amountBusd);
        soldTokens = soldTokens.add(numberOfTokens);
        amountRaised = amountRaised.add(_amountBusd);

        emit tokenBought(msg.sender, numberOfTokens, _amountBusd);
    }
    
    function claim() public allowed isHuman{
        require(block.timestamp > preSaleTime,"HODL: Presale not over");
        require(canClaim == true,"HODL: pool not initialized yet");

        if(amountRaised < softCap){
            uint256 numberOfTokens = bnbBalance[msg.sender];
            require(numberOfTokens > 0,"HODL: Zero balance");
        
            payable(msg.sender).transfer(numberOfTokens);
            bnbBalance[msg.sender] = 0;

            emit tokenClaimed(msg.sender, numberOfTokens);
        }else {
            uint256 numberOfTokens = tokenBalance[msg.sender];
            require(numberOfTokens > 0,"HODL: Zero balance");
        
            token.transfer(msg.sender, numberOfTokens);
            tokenBalance[msg.sender] = 0;

            emit tokenClaimed(msg.sender, numberOfTokens);
        }
    }
    
    function withdrawAndInitializePool() public onlyTokenOwner allowed isHuman{
        require(block.timestamp > preSaleTime,"HODL: PreSale not over yet");
        if(amountRaised > softCap){
            canClaim = true;
            uint256 busdAmountForLiquidity = amountRaised.mul(liquidityPercent).div(100);
            uint256 tokenAmountForLiquidity = listingTokens(busdAmountForLiquidity);
            addLiquidity(tokenAmountForLiquidity, busdAmountForLiquidity);
            busd.transfer(admin, amountRaised.mul(adminFeePercent).div(100));
            token.transfer(admin, getContractTokenBalance().mul(adminFeePercent).div(100));
            busd.transfer(tokenOwner, getContractBusdBalance());
            uint256 refund = getContractTokenBalance().sub(soldTokens);
            if(refund > 0)
                token.transfer(tokenOwner, refund);
        
            emit tokenUnSold(tokenOwner, refund);
        }else{
            canClaim = true;
            busd.transfer(admin, amountRaised.mul(adminFeePercent).div(100));
            token.transfer(admin, getContractTokenBalance().mul(adminFeePercent).div(100));
            token.transfer(tokenOwner, getContractBusdBalance());

            emit tokenUnSold(tokenOwner, getContractBusdBalance());
        }
        
    }
    
    function addLiquidity(
        uint256 tokenAmount,
        uint256 busdAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidity(
            address(token),
            address(busd),
            tokenAmount,
            busdAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tokenOwner,
            block.timestamp + 360
        );
    }

    // to check number of token for buying
    function busdToToken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(1000).div(1e18);
        return numberOfTokens.mul(10 ** (token.decimals())).div(1000);
    }
    
    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(listingPrice).mul(1000).div(1e18);
        return numberOfTokens.mul(10 ** (token.decimals())).div(1000);
    }

    // to check contribution
    function userContribution(address _user) public view returns(uint256){
        uint256 busdAmount = tokenBalance[_user].mul(1000).div(tokenPrice).div(10 ** token.decimals());
        return busdAmount.mul(1e18).div(1000);
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin{
        allow = _enable;
    }
    
    function getContractBusdBalance() public view returns(uint256){
        return busd.balanceOf(address(this));
    }
    
    function getContractTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }

    function setTime(uint256 _time) external onlyAdmin{
        preSaleTime  = _time;
    }
    
}