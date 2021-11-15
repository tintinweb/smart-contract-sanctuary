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

// import './PreSaleEth.sol';
import './PreSaleBnb.sol';
import './TokenContract.sol';

contract OPTLdeployer is ReentrancyGuard {

    using SafeMath for uint256;
    address payable public admin;
    IERC20 public opttoken;
    IERC20 private token;
    address public routerAddress;
    uint256 public adminFee;
    uint256 public adminFeePercent;

    mapping(address => bool) public isPreSaleExist;
    mapping(address => bool) public isInitialized;
    mapping(address => mapping(address => address)) private getPreSale;
    mapping(address => address[]) public getToken;
    address[] public allPreSales;
    address[] public allTokens;

    modifier onlyAdmin(){
        require(msg.sender == admin,"OPT: Not an admin");
        _;
    }

    event PreSaleCreated(address indexed _token, address indexed _preSale, uint256 indexed _length);
    event newTokenCreated(address indexed _token, uint256 indexed _length);

    constructor(address payable _admin) {
        admin = _admin;
        opttoken = IERC20(0xEF5476A98aE30eb71241780ED83BF53ca00C2f5c);
        adminFee = 10000e18;
        adminFeePercent = 3;
        routerAddress = (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);  //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    }

    receive() payable external{}

    function createPreSale(
        IERC20 _token,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint8 _saleNo
    ) external returns (address preSaleContract) {
        require(opttoken.balanceOf(tx.origin)>=adminFee,"OPT: you have insufficient amount of opt tokens to create presale");
        require(address(_token) != address(0), 'OPT: ZERO_ADDRESS');
        require(isPreSaleExist[address(_token)] == false, 'OPT: PRESALE_EXISTS'); // single check is sufficient
        token = _token;
        opttoken.transferFrom(msg.sender, admin, adminFee);

        bytes memory bytecode = type(preSaleBnb).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token, msg.sender));

        assembly {
            preSaleContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPreSale(preSaleContract).initialize(
            msg.sender,
            token,
            _minAmount,
            _maxAmount,
            routerAddress,
            adminFeePercent,
            _saleNo
        );
        getPreSale[msg.sender][address(token)] = preSaleContract;
        isPreSaleExist[address(token)] = true; // setting preSale for this token to aviod duplication
        allPreSales.push(preSaleContract);

        emit PreSaleCreated(address(token), preSaleContract, allPreSales.length);
    }

    function initializePreSale(
        address _token,
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _liquidityPercent
    ) external isHuman () {
        require(getPreSale[msg.sender][_token] != address(0),"OPT: No preSale found");
        require(!isInitialized[_token],"OPT: Already initialized");
        
        uint256 tokenAmount = getTotalNumberOfTokens(
            _tokenPrice,
            _listingPrice,
            _hardCap,
            _liquidityPercent
        );
        tokenAmount = tokenAmount.mul(10 ** (IERC20(_token).decimals()));
        token.transferFrom(msg.sender, getPreSale[msg.sender][address(_token)], tokenAmount);
        IPreSale(getPreSale[msg.sender][address(_token)]).initializeRemaining(
            _tokenPrice,
            _presaleTime,
            _hardCap,
            _softCap,
            _listingPrice,
            _liquidityPercent
        );
        isInitialized[_token] = true;
    }



    function createToken(
        address payable _tokenOwner,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol
    ) external isHuman returns (address tokenContract) {

        require(opttoken.balanceOf(tx.origin)>=adminFee,"you have insufficient amount of opt tokens to create presale");
        
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
        getToken[msg.sender].push(tokenContract);
        emit newTokenCreated(tokenContract , allTokens.length);
    }

    function getTotalNumberOfTokens(
        uint256 _tokenPrice,
        uint256 _listingPrice,
        uint256 _hardCap,
        uint256 _liquidityPercent
    ) public view returns(uint256){
        uint256 tokensForSell = _hardCap.mul(_tokenPrice).mul(1000).div(1e18);
        tokensForSell = tokensForSell.add(tokensForSell.mul(adminFeePercent).div(100));
        uint256 tokensForListing = (_hardCap.mul(_liquidityPercent).div(100)).mul(_listingPrice).mul(1000).div(1e18);
        return tokensForSell.add(tokensForListing).div(1000);
    }

    function setAdmin(address payable _admin) external onlyAdmin{
        admin = _admin;
    }

    function setAdminFee(uint256 _fee) external onlyAdmin{
        adminFee = _fee;
    }

    function setAdminFeePercent(uint256 _percent) external onlyAdmin{
        adminFeePercent = _percent;
    }
    
    function getAllPreSalesLength() external view returns (uint) {
        return allPreSales.length;
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    function setRouter(address _router) public onlyAdmin{
        routerAddress=_router;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import '../TokenContract.sol';
import '../Interfaces/IUniswapV2Router02.sol';
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
        uint256 _minAmount,
        uint256 _maxAmount,
        address _routerAddress,
        uint256 _adminFeePercent,
        uint8 _choice
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

import './Interfaces/IPreSale.sol';

contract preSaleBnb is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeMath for uint8;
    
    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IUniswapV2Router02 public routerAddress;

    uint256 public adminFeePercent;
    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public saleType;
    uint256 public soldTokens;
    uint256 public totalUser;
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
        require(!allow,"PRESALE: Not allowed");
        _;
    }
    
    event TokenBought(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event BnbClaimed(address indexed user, uint256 indexed numberOfBnb);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        admin = payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _tokenOwner,
        IERC20 _token,
        uint256 _minAmount,
        uint256 _maxAmount,
        address _routerAddress,
        uint256 _adminFeePercent,
        uint8 _choice
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        tokenOwner = payable(_tokenOwner);
        token = _token;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        routerAddress = IUniswapV2Router02(_routerAddress);
        adminFeePercent = _adminFeePercent;
        saleType = _choice;
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
    function buyToken() public isHuman payable allowed{
        require(block.timestamp < preSaleTime,"PRESALE: Time over"); // time check
        require(getContractBnbBalance().add(msg.value) <= hardCap,"PRESALE: Hardcap reached");
        uint256 numberOfTokens = bnbToToken(msg.value);
        require(msg.value >= minAmount && bnbBalance[msg.sender].add(msg.value) <= maxAmount,"PRESALE: Invalid Amount");
        
        if(tokenBalance[msg.sender] == 0){
            totalUser++;
        }
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);
        bnbBalance[msg.sender] = bnbBalance[msg.sender].add(msg.value);

        emit TokenBought(msg.sender, numberOfTokens, msg.value);
    }
    
    // to claim token after launch => for web3 use
    function claim() public isHuman allowed{
        require(canClaim,"PRESALE: Wait for the owner to end preSale");
        require(block.timestamp > preSaleTime,"PRESALE: Presale time not over");
        if(amountRaised >= softCap){
            uint256 numberOfTokens = tokenBalance[msg.sender];
            require(numberOfTokens > 0,"PRESALE: Zero balance");
        
            token.transfer(msg.sender, numberOfTokens);
            tokenBalance[msg.sender] = 0;

            emit TokenClaimed(msg.sender, numberOfTokens);
        }else {
            uint256 numberOfTokens = bnbBalance[msg.sender];
            require(numberOfTokens > 0,"PRESALE: Zero balance");
        
            payable(msg.sender).transfer(numberOfTokens);
            bnbBalance[msg.sender] = 0;

            emit BnbClaimed(msg.sender, numberOfTokens);
        }
    }

    // withdraw the funds and initialize the liquidity pool
    function endPreSale() public onlyTokenOwner isHuman allowed{
        require(block.timestamp > preSaleTime,"PRESALE: PreSale not over yet");
        if(saleType == 1){
            if(amountRaised >= softCap){
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
        }else{
            if(amountRaised >= softCap){
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
        }
        canClaim = true;
    }    
    
    function addLiquidity(
        uint256 tokenAmount,
        uint256 bnbAmount
    ) internal {
        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(routerAddress);

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
    address payable public  deployer;
    address payable public  owner;
    address payable private  _previousOwner;
    // uint256 public  lockTime;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Mint(address _addr,uint256 _value);
    event Burn(address target, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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

    // function geUnlockTime() public view returns (uint256) {
    //     return lockTime;
    // }

    //Locks the contract for owner for the amount of time provided
    // function lock(uint256 time) public virtual onlyOwner {
    //     _previousOwner = owner;
    //     owner = payable(address(0));
    //     lockTime = block.timestamp + time;
    //     emit OwnershipTransferred(owner, address(0));
    // }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    // function unlock() public virtual{
    //     require(_previousOwner == msg.sender, "You don't have permission to unlock");
    //     require(block.timestamp > lockTime , "Contract is locked until 7 days");
    //     emit OwnershipTransferred(owner, _previousOwner);
    //     owner = _previousOwner;
    //     _previousOwner = payable(address(0));
    // }
    
    function balanceOf(address _owner) view public override returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public  override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public override {
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public override{
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
  
    function approve(address _spender, uint256 _amount) public override {
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
    }
    
    function burn(uint256 _value) public {
        require(balances[msg.sender] >= _value, "BEP20: user balance is insufficient");   
        
        balances[msg.sender] =balances[msg.sender].sub(_value);
        totalSupply =totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
    

    function mint(address _addr,uint256 _value) public onlyOwner{
        
        balances[_addr] =balances[_addr].add(_value);
        totalSupply =totalSupply.add(_value);
        emit Mint(_addr, _value);
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

