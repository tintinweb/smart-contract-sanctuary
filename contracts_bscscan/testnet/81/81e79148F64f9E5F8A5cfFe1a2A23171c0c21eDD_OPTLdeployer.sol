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
import './PreSaleEth.sol';
import './Interfaces/IPreSale.sol';
import './TokenContract.sol';
import './AbstractContracts/ReentrancyGuard.sol';

contract OPTLdeployer is ReentrancyGuard {

    using SafeMath for uint256;
    address payable public admin;
    IERC20 public opttoken;
    IERC20 private _token;

    uint256 public adminFee;

    mapping(address => bool) public isPreSaleExist;
    mapping(address => address) public getPreSale;
    address[] public allPreSales;
    address[] public allTokens;

    modifier onlyAdmin(){
        require(msg.sender == admin,"OPT: Not an admin");
        _;
    }

    event PreSaleCreated(address indexed _token, address indexed _preSale, uint256 indexed _length);
    event newTokenCreated(address indexed _token, uint256 indexed _length);

    constructor(address payable _admin,
    
     IERC20 _opttoken) {
        admin = _admin;

        opttoken=_opttoken;
        adminFee = 10000e18;
    }

    receive() payable external{}

    function createPreSaleBNB(
        IERC20 token,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _claimTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _hardCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent,
        string memory saleName
    ) external returns (address preSaleContract) {
        require(opttoken.balanceOf(tx.origin)>=adminFee,"you have insufficient amount of opt tokens to create presale");
        require(address(_token) != address(0), 'OPT: ZERO_ADDRESS');
        require(isPreSaleExist[address(_token)] == false, 'OPT: PRESALE_EXISTS'); // single check is sufficient
        _token = token;
        opttoken.transferFrom(msg.sender, admin, adminFee);

        bytes memory bytecode = type(preSaleBnb).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender));

        assembly {
            preSaleContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPreSale(preSaleContract).initialize(
            msg.sender,
            _token,
            _tokenPrice,
            _presaleTime,
            _claimTime,
            _minAmount,
            _maxAmount,
            _hardCap,
            _listingPrice,
            _liquidityPercent,
            saleName
        );
        
        uint256 tokenAmount = getTotalNumberOfTokens(
            _tokenPrice,
            _listingPrice,
            _hardCap.div(1e18),
            _liquidityPercent
        );

        tokenAmount = tokenAmount.mul(10 ** (_token.decimals()));
        _token.transferFrom(msg.sender, preSaleContract, tokenAmount);
        getPreSale[address(_token)] = preSaleContract;
        isPreSaleExist[address(_token)] = true; // setting preSale for this token to aviod duplication
        allPreSales.push(preSaleContract);

        emit PreSaleCreated(address(_token), preSaleContract, allPreSales.length);
    }



    function createToken(
        address payable _tokenOwner,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol
    ) external isHuman returns (address tokenContract) {

        require(opttoken.balanceOf(tx.origin)>=adminFee,"you have insufficient amount of opt tokens to create presale");
        // require(address(_token) != address(0), 'OPT: ZERO_ADDRESS');
        // require(isPreSaleExist[address(_token)] == false, 'OPT: PRESALE_EXISTS'); // single check is sufficient
        
        opttoken.transferFrom(msg.sender, admin, adminFee);

        bytes memory bytecode = type(Bep20).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(opttoken, msg.sender));

        assembly {
            tokenContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IERC20(tokenContract).initialize(
         _tokenOwner,
         _totalSupply,
         _name,
         _symbol
        
        );
        allTokens.push(tokenContract);
        emit newTokenCreated(tokenContract , allTokens.length);
    }

    function getTotalNumberOfTokens(
        uint256 _tokenPrice,
        uint256 _listingPrice,
        uint256 _hardCap,
        uint256 _liquidityPercent
    ) public pure returns(uint256){
        uint256 tokensForSell = _hardCap.mul(_tokenPrice);
        tokensForSell = tokensForSell.add(tokensForSell.mul(2).div(100));
        uint256 tokensForListing = (_hardCap.mul(_liquidityPercent).div(100)).mul(_listingPrice);
        return tokensForSell.add(tokensForListing);
    }

    function setAdmin(address payable _admin) external onlyAdmin{
        admin = _admin;
    }

    function setAdminFee(uint256 _fee) external onlyAdmin{
        adminFee = _fee;
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

import '../TokenContract.sol';

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
        uint256 _claimTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _hardCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent,
        string memory saleName
    ) external ;

    
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.8.4;

// SPDX-License-Identifier:MIT
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

interface IUniswapV2Pair {
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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

// import './Libraries/SafeMath.sol';
// import './Interfaces/IERC20.sol';
import './TokenContract.sol';
import './Interfaces/IUniswapV2Router02.sol';
import './Interfaces/IPriceFeed.sol';

contract preSaleBnb {

    using SafeMath for uint256;
    
    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IUniswapV2Router02 public routerAddressPancake;
    IUniswapV2Router02 public routerAddressSushi;
    address public pairAdress;
    AggregatorV3Interface public priceFeedBnb;

    uint256 public adminFeePercent;
    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public claimTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public soldTokens;
    uint256 public preSaleTokens;
    string  public saleName;

    bool public allow;

    mapping(address => uint256) public balances;

    modifier onlyAdmin(){
        require(msg.sender == admin,"OPT: Not an admin");
        _;
    }

    modifier onlyTokenOwner(){
        require(msg.sender == tokenOwner,"OPT: Not a token owner");
        _;
    }

    modifier allowed(){
        require(allow == true,"OPT: Not allowed");
        _;
    }
    
    event tokenBought(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);

    event tokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event tokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        allow = true;
        admin = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
        routerAddressPancake = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        routerAddressSushi = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        
        priceFeedBnb = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        adminFeePercent = 2;
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _tokenOwner,
        IERC20 _token,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _claimTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _hardCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent,
        string memory _saleName
    ) external {
        require(msg.sender == deployer, "OPT: FORBIDDEN"); // sufficient check
        tokenOwner = payable(_tokenOwner);
        token = _token;
        tokenPrice = _tokenPrice;
        preSaleTime = _presaleTime;
        claimTime = _claimTime;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        hardCap = _hardCap;
        listingPrice = _listingPrice;
        liquidityPercent = _liquidityPercent;
        preSaleTokens = bnbToToken(hardCap);
        saleName=_saleName;
    }
    
    // to buy token during preSale time => for web3 use
    function buyToken() public payable allowed{
        require(block.timestamp < preSaleTime,"OPT: Time over"); // time check
        require(getContractBnbBalance() <= hardCap,"OPT: Hardcap reached");
        
        uint256 numberOfTokens = bnbToToken(msg.value);
        require(msg.value >= minAmount && numberOfTokens.add(balances[msg.sender]) <= maxAmount,"OPT: Invalid Amount");

        balances[msg.sender] = balances[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);

        emit tokenBought(msg.sender, numberOfTokens, msg.value);
    }

    function claim() public allowed{
        uint256 numberOfTokens = balances[msg.sender];
        require(numberOfTokens > 0,"OPT: Zero balance");
        require(block.timestamp > preSaleTime.add(claimTime),"OPT: Presale time not over");
        
        token.transfer(msg.sender, numberOfTokens);
        balances[msg.sender] = 0;

        emit tokenClaimed(msg.sender, numberOfTokens);
    }
    
    function withdrawAndInitializePool(uint256 _num) public onlyTokenOwner allowed{
        IUniswapV2Router02 routerAddress;

        if(_num==1){
            routerAddress=routerAddressPancake;
        }
        else{
            routerAddress=routerAddressSushi;
        }
        pairAdress = IUniswapV2Factory(routerAddress.factory())
            .createPair(address(token),routerAddress.WETH());
        require(block.timestamp > preSaleTime,"OPT: PreSale not over yet");
        uint256 amountRaised = getContractBnbBalance();
        require(amountRaised>0,"raised amount is 0");
        uint256 bnbAmountForLiquidity = amountRaised.mul(liquidityPercent).div(100);
        uint256 tokenAmountForliquidity = listingTokens(bnbAmountForLiquidity);
        addLiquidity(tokenAmountForliquidity, bnbAmountForLiquidity,routerAddress);
        admin.transfer(amountRaised.mul(adminFeePercent).div(100));
        token.transfer(admin, getContractTokenBalance().mul(adminFeePercent).div(100));
        tokenOwner.transfer(getContractBnbBalance());
        uint256 refund = getContractTokenBalance().sub(soldTokens);
        if(refund > 0)
            token.transfer(tokenOwner, refund);
        
        emit tokenUnSold(tokenOwner, refund);
    }
    
    function addLiquidity(
        uint256 tokenAmount,
        uint256 bnbAmount,
        IUniswapV2Router02 router
    ) internal {
       

        // add the liquidity
        router.addLiquidityETH{value : bnbAmount}(
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
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(1000).mul(getLatestPriceBnb()).div(1e18);
        return numberOfTokens.mul(10 ** (token.decimals())).div(1000);
    }
    
    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(listingPrice).mul(1000).mul(getLatestPriceBnb()).div(1e18);
        return numberOfTokens.mul(10 ** (token.decimals())).div(1000);
    }

    // to get real time price of BNB
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin{
        allow = _enable;
    }
    
    // to draw busd funds from preSale
    function migrateBusdFunds() external onlyTokenOwner allowed{
        require(getCurrentTime() > preSaleTime,"HODL: Time error");
        tokenOwner.transfer(getContractBnbBalance());
    }

    // to draw unSold tokens from preSale
    function migrateTokenFunds() external onlyTokenOwner allowed{
        require(getCurrentTime() > preSaleTime,"HODL: Time error");
        tokenOwner.transfer(getContractTokenBalance());
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

    function setTime(uint256 _presaleTime) external onlyAdmin{
        preSaleTime  = _presaleTime;
    }
    
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

// import './Libraries/SafeMath.sol';
// import './Interfaces/IERC20.sol';
import './TokenContract.sol';
import './Interfaces/IUniswapV2Router02.sol';
import './Interfaces/IPriceFeed.sol';
// import './AbstractContracts/ReentrancyGuard.sol';

contract preSaleEth {

    using SafeMath for uint256;
    
    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IUniswapV2Router02 public routerAddressUni;
    IUniswapV2Router02 public routerAddressSushi;
    address public pairAdress;
    AggregatorV3Interface public priceFeedEth;

    uint256 public adminFeePercent;
    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public claimTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public soldTokens;
    uint256 public preSaleTokens;
    string  public saleName;

    bool public allow;

    mapping(address => uint256) public balances;

    modifier onlyAdmin(){
        require(msg.sender == admin,"OPT: Not an admin");
        _;
    }

    modifier onlyTokenOwner(){
        require(msg.sender == tokenOwner,"OPT: Not a token owner");
        _;
    }

    modifier allowed(){
        require(allow == true,"OPT: Not allowed");
        _;
    }
    
    event tokenBought(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);

    event tokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event tokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        allow = true;
        admin = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
        routerAddressUni = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        routerAddressSushi = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        
        priceFeedEth = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        adminFeePercent = 2;
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _tokenOwner,
        IERC20 _token,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _claimTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _hardCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent,
        string memory _saleName
    ) external {
        require(msg.sender == deployer, "OPT: FORBIDDEN"); // sufficient check
        tokenOwner = payable(_tokenOwner);
        token = _token;
        tokenPrice = _tokenPrice;
        preSaleTime = _presaleTime;
        claimTime = _claimTime;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        hardCap = _hardCap;
        listingPrice = _listingPrice;
        liquidityPercent = _liquidityPercent;
        preSaleTokens = EthToToken(hardCap);
        saleName=_saleName;
    }
    
    // to buy token during preSale time => for web3 use
    function buyToken() public payable allowed{
        require(block.timestamp < preSaleTime,"OPT: Time over"); // time check
        require(getContractEthBalance() <= hardCap,"OPT: Hardcap reached");
        
        uint256 numberOfTokens = EthToToken(msg.value);
        require(msg.value >= minAmount && numberOfTokens.add(balances[msg.sender]) <= maxAmount,"OPT: Invalid Amount");

        balances[msg.sender] = balances[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);

        emit tokenBought(msg.sender, numberOfTokens, msg.value);
    }

    function claim() public allowed{
        uint256 numberOfTokens = balances[msg.sender];
        require(numberOfTokens > 0,"OPT: Zero balance");
        require(block.timestamp > preSaleTime.add(claimTime),"OPT: Presale time not over");
        
        token.transfer(msg.sender, numberOfTokens);
        balances[msg.sender] = 0;

        emit tokenClaimed(msg.sender, numberOfTokens);
    }
    
    function withdrawAndInitializePool(uint256 _num) public onlyTokenOwner allowed{
        IUniswapV2Router02 routerAddress;

        if(_num==1){
            routerAddress = routerAddressUni;
        }
        else{
            routerAddress = routerAddressSushi;
        }
        pairAdress = IUniswapV2Factory(routerAddress.factory())
            .createPair(address(token),routerAddress.WETH());
        require(block.timestamp > preSaleTime,"OPT: PreSale not over yet");
        uint256 amountRaised = getContractEthBalance();
        require(amountRaised>0,"raised amount is 0");
        uint256 ethAmountForLiquidity = amountRaised.mul(liquidityPercent).div(100);
        uint256 tokenAmountForliquidity = listingTokens(ethAmountForLiquidity);
        addLiquidity(tokenAmountForliquidity, ethAmountForLiquidity,routerAddress);
        admin.transfer(amountRaised.mul(adminFeePercent).div(100));
        token.transfer(admin, getContractTokenBalance().mul(adminFeePercent).div(100));
        tokenOwner.transfer(getContractEthBalance());
        uint256 refund = getContractTokenBalance().sub(soldTokens);
        if(refund > 0)
            token.transfer(tokenOwner, refund);
        
        emit tokenUnSold(tokenOwner, refund);
    }
    
    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount, IUniswapV2Router02 router
    ) internal {
       

        // add the liquidity
        router.addLiquidityETH{value : ethAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tokenOwner,
            block.timestamp + 360
        );
    }

    // to check number of token for buying
    function EthToToken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(1000).mul(getLatestPriceEth()).div(1e18);
        return numberOfTokens.mul(10 ** (token.decimals())).div(1000);
    }
    
    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(listingPrice).mul(1000).mul(getLatestPriceEth()).div(1e18);
        return numberOfTokens.mul(10 ** (token.decimals())).div(1000);
    }

    // to get real time price of Eth
    function getLatestPriceEth() public view returns (uint256) {
        (,int price,,,) = priceFeedEth.latestRoundData();
        return uint256(price).div(1e8);
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin{
        allow = _enable;
    }
    
    // to draw busd funds from preSale
    

    // to draw unSold tokens from preSale
    function migrateTokenFunds() external onlyTokenOwner allowed{
        require(getCurrentTime() > preSaleTime,"OPT: Time error");
        tokenOwner.transfer(getContractTokenBalance());
    }
    
    function getContractEthBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }

    function setTime(uint256 _presaleTime) external onlyAdmin{
        preSaleTime  = _presaleTime;
    }
    
}

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';
import './libraries/Address.sol';

// Bep20 standards for token creation

contract Bep20 is IERC20 {
    
    using SafeMath for uint256;
    using Address for address;
    
    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint256 public override totalSupply;
    address payable public deployer;
    address payable public owner;
    address payable private _previousOwner;
    uint256 public lockTime;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
    
    event Freeze(address target, bool frozen);
    event Unfreeze(address target, bool frozen);
    event Burn(address target, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier whenNotFrozen(address target) {
        require(!frozen[target],"BEP20: account is freeze already");
        _;
    }

    modifier whenFrozen(address target){
        require(frozen[target],"BEP20: tokens is not freeze");
        _;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor() {
        deployer=payable(msg.sender);
    }
    
    function initialize(
        address payable _tokenOwner,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol
  
    ) external override {
        require(msg.sender == deployer, "HODL: FORBIDDEN"); // sufficient check
        owner = _tokenOwner;
        totalSupply= _totalSupply;
        name=_name;
        symbol=_symbol;
        balances[owner] = totalSupply;
        emit OwnershipTransferred(address(0), owner);
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = payable(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner;
        owner = payable(address(0));
        lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual{
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
        _previousOwner = payable(address(0));
    }
    
    function balanceOf(address _owner) view public override returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public  override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public override whenNotFrozen(msg.sender){
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public override whenNotFrozen(msg.sender){
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
  
    function approve(address _spender, uint256 _amount) public override whenNotFrozen(msg.sender){
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
    }

    function FreezeAcc(address target) onlyOwner public whenNotFrozen(target) returns (bool) {
        frozen[target]=true;
        emit Freeze(target, true);
        return true;
    }

    function UnfreezeAcc(address target) onlyOwner public whenFrozen(target) returns (bool) {
        frozen[target]=false;
        emit Unfreeze(target, false);
        return true;
    }
    
    function burn(uint256 _value) public whenNotFrozen(msg.sender){
        require(balances[msg.sender] >= _value, "BEP20: user balance is insufficient");   
        
        balances[msg.sender] =balances[msg.sender].sub(_value);
        totalSupply =totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
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
    function initialize(
        address payable _tokenOwner,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol
  
    ) external ;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

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