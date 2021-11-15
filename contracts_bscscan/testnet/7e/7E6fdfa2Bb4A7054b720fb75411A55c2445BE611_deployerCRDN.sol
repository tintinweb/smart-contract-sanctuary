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

import './PreSaleBnb.sol';

contract deployerCRDN is ReentrancyGuard {

    using SafeMath for uint256;  
    address payable public admin;
    IERC20 private token;

    uint256 private hundred;
    uint256 totalClaimCycle;

    mapping(address => mapping(uint256 => bool)) public isInitialized;
    mapping(address => mapping(uint256 => address)) public getPreSale;
    mapping(address => uint256) public getPreSaleCount;
    address[] public allPreSales;

    modifier onlyAdmin(){
        require(msg.sender == admin,"CRDN: Not an admin");
        _;
    }

    event PreSaleCreated(address indexed _token, address indexed _preSale, uint256 indexed _length);

    constructor() {
        admin = payable(msg.sender);
        hundred = 100;
    }

    receive() payable external{}

    function createPreSaleBNB(
        IERC20 _token,
        uint256 _initialClaimPercent,
        uint256 _totalClaimCycle,
        uint256 _refPercent,
        uint256 _minAmount,
        uint256 _maxAmount
    ) external isHuman returns (address preSaleContract) {
        token = _token;
        totalClaimCycle = _totalClaimCycle;

        require(address(token) != address(0), 'CRDN: ZERO_ADDRESS');
        
        uint256 _vestingPercent = hundred.sub(_initialClaimPercent).mul(100).div(_totalClaimCycle);
            
        bytes memory bytecode = type(preSaleBnb).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender, allPreSales.length));

        assembly {
            preSaleContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPreSale(preSaleContract).initialize(
            msg.sender,
            token,
            _initialClaimPercent,
            _vestingPercent,
            _refPercent,
            _minAmount,
            _maxAmount,
            totalClaimCycle
        );
        
        getPreSale[address(token)][++getPreSaleCount[address(token)]] = preSaleContract;
        allPreSales.push(preSaleContract);

        emit PreSaleCreated(address(token), preSaleContract, allPreSales.length);
    }

    function setPreSaleBNB(
        IERC20 _token,
        uint256 _tokenAmount,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent
    ) external isHuman () {
        require(getPreSale[address(_token)][getPreSaleCount[address(token)]] != address(0),"CRDN: No preSale found");
        require(!isInitialized[address(token)][getPreSaleCount[address(token)]],"CRDN: Already initialized");

        (uint256 tokenAmountToSend, uint256 _hardCap) = getTotalNumberOfTokens(
            _tokenPrice,
            _listingPrice,
            _tokenAmount,
            _liquidityPercent
        );
        tokenAmountToSend = tokenAmountToSend.mul(10 ** (token.decimals()));
        token.transferFrom(msg.sender, getPreSale[address(_token)][getPreSaleCount[address(_token)]], tokenAmountToSend);
        IPreSale(getPreSale[address(_token)][getPreSaleCount[address(_token)]]).initializeRemaining(
            _tokenPrice,
            _presaleTime,
            _hardCap,
            _softCap,
            _listingPrice,
            _liquidityPercent
        );
        isInitialized[address(token)][++getPreSaleCount[address(token)]] = true;
    }

    function getTotalNumberOfTokens(
        uint256 _tokenPrice,
        uint256 _listingPrice,
        uint256 _tokenAmount,
        uint256 _liquidityPercent
    ) public pure returns(uint256 amountToSend, uint256 hardCap){
        uint256 _hardCap = _tokenAmount.mul(1e18).div(_tokenPrice);
        uint256 tokensForSell = _tokenAmount.add(_tokenAmount.mul(2).div(100));
        uint256 tokensForListing = (_hardCap.mul(_liquidityPercent).div(100)).mul(_listingPrice).div(1e18);
        return (tokensForSell.add(tokensForListing), _hardCap);
    }

    function setAdmin(address payable _admin) external onlyAdmin{
        admin = _admin;
    }
    
    function getAllPreSalesLength() external view returns (uint) {
        return allPreSales.length;
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
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
import './IPancakeRouter02.sol';
import '../AbstractContracts/ReentrancyGuard.sol';

interface IPreSale{

    function admin() external view returns(address);
    function tokenOwner() external view returns(address);
    function deployer() external view returns(address);
    function token() external view returns(address);

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
        // uint256[] memory parameters
        // uint256 _tokenPrice,
        // uint256 _presaleTime,
        uint256 _initialClaimPercent,
        uint256 _vestingPercent,
        uint256 _refPercent,
        uint256 _minAmount,
        uint256 _maxAmount,
        // uint256 _hardCap,
        // uint256 _softCap,
        // uint256 _listingPrice,
        // uint256 _liquidityPercent
        uint256 _totalClaimCycle
    ) external ;

    function initializeRemaining(
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent
    ) external ;
    
}

pragma solidity ^0.8.4;

//  SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import './Interfaces/IPreSale.sol';

contract preSaleBnb is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeMath for uint8;
    
    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IPancakeRouter02 public routerAddress;

    uint256 public adminFeePercent;
    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public nextClaimTime;
    uint256 public initialClaimPercent;
    uint256 public vestingPercent;   // with 2 decimal places
    uint256 public refPercent;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public soldTokens;
    uint256 public totalUser;
    uint256 public currentClaimCycle;
    uint256 public totalClaimCycle;
    uint256 public amountRaised;

    bool public allow;
    bool public canClaim;

    mapping(address => uint256) public bnbBalance;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public activePercentAmount;
    mapping(address => uint256) public claimCount;

    modifier onlyAdmin(){
        require(msg.sender == admin,"PRESALE: Not an admin");
        _;
    }

    modifier onlyTokenOwner(){
        require(msg.sender == tokenOwner,"PRESALE: Not a token owner");
        _;
    }

    modifier allowed(){
        require(allow == true,"PRESALE: Not allowed");
        _;
    }
    
    event TokenBought(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event BnbClaimed(address indexed user, uint256 indexed numberOfBnb);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        allow = true;
        adminFeePercent = 3;
        admin = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
        routerAddress = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _tokenOwner,
        IERC20 _token,
        uint256 _initialClaimPercent,
        uint256 _vestingPercent,
        uint256 _refPercent,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _totalClaimCycle
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        tokenOwner = payable(_tokenOwner);
        token = _token;
        initialClaimPercent = _initialClaimPercent;
        vestingPercent = _vestingPercent;
        refPercent = _refPercent;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        totalClaimCycle = _totalClaimCycle;
    }

    // called once by the deployer contract at time of deployment
    function initializeRemaining(
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        tokenPrice = _tokenPrice;
        preSaleTime = _presaleTime;
        hardCap = _hardCap;
        softCap = _softCap;
        listingPrice = _listingPrice;
        liquidityPercent = _liquidityPercent;
    }

    receive() payable external{}
    
    // to buy token during preSale time => for web3 use
    function buyToken(address _referrer) public payable isHuman allowed{
        require(block.timestamp < preSaleTime,"PRESALE: Time over"); // time check
        require(getContractBnbBalance().add(msg.value) <= hardCap,"PRESALE: Hardcap reached");
        uint256 numberOfTokens = bnbToToken(msg.value);
        require(msg.value >= minAmount && bnbBalance[msg.sender].add(msg.value) <= maxAmount,"PRESALE: Invalid Amount");
        require(_referrer != address(0) && _referrer != msg.sender,"PRESALE: Invalid referrer");
        
        if(tokenBalance[msg.sender] == 0){
            totalUser++;
        }
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);
        if(refPercent != 0){
            tokenBalance[_referrer] = tokenBalance[_referrer].add(numberOfTokens.mul(refPercent).div(100));
            soldTokens = soldTokens.add(numberOfTokens.mul(refPercent).div(100));
        }
        bnbBalance[msg.sender] = bnbBalance[msg.sender].add(msg.value);
        amountRaised = amountRaised.add(msg.value);

        emit TokenBought(msg.sender, numberOfTokens, msg.value);
    }
    
    // to claim token after launch => for web3 use
    function claim() public isHuman allowed{
        require(canClaim,"PRESALE: Wait for owner to end preSale");
        if(amountRaised >= softCap){
            require(block.timestamp >= preSaleTime + nextClaimTime
                && claimCount[msg.sender] < currentClaimCycle 
                ,"PRESALE: Wait for next claim date");
            require(tokenBalance[msg.sender] > 0,"PRESALE: Do not have any tokens to claim");
        
            uint256 transferAmount;
            uint256 multiplier = currentClaimCycle.sub(claimCount[msg.sender]);

            if(claimCount[msg.sender] == 0){
                transferAmount = tokenBalance[msg.sender].mul(initialClaimPercent).div(100);
                activePercentAmount[msg.sender] = tokenBalance[msg.sender].mul(vestingPercent).div(10000);
                token.transfer(msg.sender, transferAmount);
                tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(transferAmount);
                claimCount[msg.sender] ++;
            }else if(claimCount[msg.sender] < totalClaimCycle){
                transferAmount = activePercentAmount[msg.sender].mul(multiplier);
                token.transfer(msg.sender, transferAmount);
                tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(transferAmount);
                claimCount[msg.sender] = claimCount[msg.sender].add(multiplier);
            }else{
                transferAmount = tokenBalance[msg.sender];
                token.transfer(msg.sender, transferAmount);
                tokenBalance[msg.sender] = 0;
                claimCount[msg.sender] = claimCount[msg.sender].add(multiplier);
            }

            emit TokenClaimed(msg.sender, transferAmount);
        }else {
            uint256 numberOfTokens = bnbBalance[msg.sender];
            require(numberOfTokens > 0,"HODL: Zero balance");
        
            payable(msg.sender).transfer(numberOfTokens);
            bnbBalance[msg.sender] = 0;

            emit BnbClaimed(msg.sender, numberOfTokens);
        }
    }

    // withdraw the funds and initialize the liquidity pool
    function withdrawAndInitializePool() public onlyTokenOwner isHuman allowed{
        require(block.timestamp > preSaleTime,"HODL: PreSale not over yet");
        if(amountRaised > softCap){
            uint256 bnbAmountForLiquidity = amountRaised.mul(liquidityPercent).div(100);
            uint256 tokenAmountForLiquidity = listingTokens(bnbAmountForLiquidity);
            token.approve(address(routerAddress), tokenAmountForLiquidity);
            addLiquidity(tokenAmountForLiquidity, bnbAmountForLiquidity);
            admin.transfer(amountRaised.mul(adminFeePercent).div(100));
            token.transfer(admin, soldTokens.mul(adminFeePercent).div(100));
            tokenOwner.transfer(getContractBnbBalance());
            uint256 refund = getContractTokenBalance().sub(soldTokens);
            if(refund > 0)
                token.transfer(tokenOwner, refund);
        
            emit TokenUnSold(tokenOwner, refund);
        }else{
            token.transfer(tokenOwner, getContractTokenBalance());

            emit TokenUnSold(tokenOwner, getContractBnbBalance());
        }
        canClaim = true;
    }    
    
    function addLiquidity(
        uint256 tokenAmount,
        uint256 bnbAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : bnbAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tokenOwner,
            block.timestamp + 360
        );
    }

    // to check number of token for buying
    function bnbToToken(uint256 _amount) public view returns(uint256){
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
        return bnbBalance[_user];
    }

    // to check token balance of user
    function userTokenBalance(address _user) public view returns(uint256){
        return tokenBalance[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin{
        allow = _enable;
    }

    // start next cycle of claim
    function startNextCycle() external onlyTokenOwner{
        nextClaimTime = nextClaimTime.add(30 days);
        currentClaimCycle ++;
    }
    
    function getContractBnbBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }

    function setTime(uint256 _presaleTime) external onlyTokenOwner{
        preSaleTime  = _presaleTime;
    }
    
}

