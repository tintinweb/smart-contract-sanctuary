pragma solidity ^0.8.6;
// SPDX-License-Identifier: MIT

import './PreSaleBnb.sol';

contract deployerCRDN {

    using SafeMath for uint256; 
     
    address payable public admin;
    IPancakeRouter02 public routerAddress;

    uint256 hundred;
    uint8 public adminFeePercent;

    mapping(address => mapping(uint256 => address)) public getPreSale;
    mapping(address => uint256) public getPreSaleCount;
    address[] public allPreSales;

    modifier onlyAdmin(){
        require(msg.sender == admin,"CRDN: Not an admin");
        _;
    }

    event PreSaleCreated(address indexed _token, address indexed _preSale, uint256 indexed _length);

    constructor() {
        admin = payable(0xE34216F38531F96f14FCC276e689430EBfd22496);
        routerAddress = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        adminFeePercent = 3;
        hundred = 100;
    }

    receive() payable external{}

    function createPreSaleBNB(
        IERC20 _token,
        uint256 _tokenAmount,
        uint256[] memory _preSaleData
    ) external returns (address preSaleContract) {

        require(address(_token) != address(0), 'CRDN: ZERO_ADDRESS');
        
        uint256 _vestingPercent = hundred.sub(_preSaleData[0]).mul(100).div(_preSaleData[1]);
            
        bytes memory bytecode = type(preSaleBnb).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender, allPreSales.length));

        assembly {
            preSaleContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        (uint256 tokenAmountToSend, uint256 _hardCap) = getTotalNumberOfTokens(
            _preSaleData[5],
            _preSaleData[6],
            _tokenAmount,
            _preSaleData[7]
        );
        tokenAmountToSend = tokenAmountToSend.mul(10 ** (_token.decimals()));
        _token.transferFrom(msg.sender, preSaleContract, tokenAmountToSend);

        IPreSale(preSaleContract).initialize(
            admin,
            msg.sender,
            _token,
            routerAddress,
            adminFeePercent,
            _preSaleData,
            _vestingPercent,
            _hardCap
        );
        
        getPreSale[address(_token)][++getPreSaleCount[address(_token)]] = preSaleContract;
        allPreSales.push(preSaleContract);

        emit PreSaleCreated(address(_token), preSaleContract, allPreSales.length);
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

    function setAdminFee(uint8 _adminFee) external onlyAdmin{
        adminFeePercent = _adminFee;
    }

    function setRouter(address _router) external onlyAdmin{
        routerAddress = IPancakeRouter02(_router);
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

pragma solidity ^0.8.6;

// SPDX-License-Identifier:MIT

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

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

interface IPreSale{

    function admin() external view returns(address);
    function tokenOwner() external view returns(address);
    function deployer() external view returns(address);
    function token() external view returns(address);
    function allow() external view returns(bool);

    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _token,
        IPancakeRouter02 _routerAddress,
        uint8 _adminFeePercent,
        uint256[] memory _preSaleData,
        uint256 _vestingPercent,
        uint256 _hardCap
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

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

import "./Interfaces/IPreSale.sol";

contract preSaleBnb {
    using SafeMath for uint256;
    using SafeMath for uint8;

    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IPancakeRouter02 public routerAddress;
    address public pancakePair;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public adminFeePercent;
    uint256 public tokenPrice;
    uint256 public preSaleTime;
    uint256 public nextClaimTime;
    uint256 public initialClaimPercent;
    uint256 public vestingPercent; // with 2 decimal places
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
    uint256 public lpLockTime;

    bool public allow;
    bool public canClaim;
    bool public preSaleCanceled;

    mapping(address => uint256) public bnbBalance;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public activePercentAmount;
    mapping(address => uint256) public claimCount;

    modifier onlyAdmin() {
        require(msg.sender == admin, "PRESALE: Not an admin");
        _;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner, "PRESALE: Not a token owner");
        _;
    }

    modifier allowed() {
        require(allow, "PRESALE: Not allowed");
        _;
    }

    event TokenBought(
        address indexed user,
        uint256 indexed numberOfTokens,
        uint256 indexed amountBusd
    );

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event BnbClaimed(address indexed user, uint256 indexed numberOfBnb);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        allow = true;
    }

    //0- _initialClaimPercent
    //1- _totalClaimCycle
    //2- _preSaleTime
    //3- _minAmount
    //4- _maxAmount
    //5- _tokenPrice
    //6- _listingPrice
    //7- _liquidityPercent
    //8- _refPercent
    //9- _softCap
    //10- _lpLockTime

    // called once by the deployer contract at time of deployment
    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _token,
        IPancakeRouter02 _routerAddress,
        uint8 _adminFeePercent,
        uint256[] memory _preSaleData,
        uint256 _vestingPercent,
        uint256 _hardCap
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        admin = payable(_admin);
        tokenOwner = payable(_tokenOwner);
        token = _token;
        routerAddress = _routerAddress;
        adminFeePercent = _adminFeePercent;
        initialClaimPercent = _preSaleData[0];
        totalClaimCycle = _preSaleData[1];
        preSaleTime = _preSaleData[2];
        minAmount = _preSaleData[3];
        maxAmount = _preSaleData[4];
        tokenPrice = _preSaleData[5];
        listingPrice = _preSaleData[6];
        liquidityPercent = _preSaleData[7];
        refPercent = _preSaleData[8];
        softCap = _preSaleData[9];
        lpLockTime = _preSaleData[10];
        vestingPercent = _vestingPercent;
        hardCap = _hardCap;
    }

    receive() external payable {}

    // to buy token during preSale time => for web3 use
    function buyToken(address _referrer) public payable allowed {
        require(block.timestamp < preSaleTime, "PRESALE: Time over"); // time check
        require(
            getContractBnbBalance().add(msg.value) <= hardCap,
            "PRESALE: Hardcap reached"
        );
        uint256 numberOfTokens = bnbToToken(msg.value);
        require(
            msg.value >= minAmount &&
                bnbBalance[msg.sender].add(msg.value) <= maxAmount,
            "PRESALE: Invalid Amount"
        );
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PRESALE: Invalid referrer"
        );

        if (tokenBalance[msg.sender] == 0) {
            totalUser++;
        }
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);
        if (refPercent != 0) {
            tokenBalance[_referrer] = tokenBalance[_referrer].add(
                numberOfTokens.mul(refPercent).div(100)
            );
            soldTokens = soldTokens.add(
                numberOfTokens.mul(refPercent).div(100)
            );
        }
        bnbBalance[msg.sender] = bnbBalance[msg.sender].add(msg.value);
        amountRaised = amountRaised.add(msg.value);

        emit TokenBought(msg.sender, numberOfTokens, msg.value);
    }

    // to claim token after launch => for web3 use
    function claim() public allowed {
        require(canClaim, "PRESALE: Wait for owner to end preSale");
        if (amountRaised >= softCap && !preSaleCanceled) {
            require(
                block.timestamp >= preSaleTime + nextClaimTime &&
                    claimCount[msg.sender] <= currentClaimCycle,
                "PRESALE: Wait for next claim date"
            );
            require(
                tokenBalance[msg.sender] > 0,
                "PRESALE: Do not have any tokens to claim"
            );

            uint256 transferAmount;
            uint256 multiplier = currentClaimCycle.sub(claimCount[msg.sender]);

            if (claimCount[msg.sender] == 0) {
                transferAmount = tokenBalance[msg.sender]
                    .mul(initialClaimPercent)
                    .div(100);
                activePercentAmount[msg.sender] = tokenBalance[msg.sender]
                    .mul(vestingPercent)
                    .div(10000);
                token.transfer(msg.sender, transferAmount);
                tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(
                    transferAmount
                );
                claimCount[msg.sender]++;
            } else if (claimCount[msg.sender] < totalClaimCycle) {
                transferAmount = activePercentAmount[msg.sender].mul(
                    multiplier
                );
                token.transfer(msg.sender, transferAmount);
                tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(
                    transferAmount
                );
                claimCount[msg.sender] = claimCount[msg.sender].add(multiplier);
            } else {
                transferAmount = tokenBalance[msg.sender];
                token.transfer(msg.sender, transferAmount);
                tokenBalance[msg.sender] = 0;
                claimCount[msg.sender] = claimCount[msg.sender].add(multiplier);
            }

            emit TokenClaimed(msg.sender, transferAmount);
        } else {
            uint256 numberOfTokens = bnbBalance[msg.sender];
            require(numberOfTokens > 0, "CRDN: Zero balance");

            payable(msg.sender).transfer(numberOfTokens);
            bnbBalance[msg.sender] = 0;

            emit BnbClaimed(msg.sender, numberOfTokens);
        }
    }

    // withdraw the funds and initialize the liquidity pool
    function withdrawAndInitializePool() public onlyTokenOwner allowed {
        require(block.timestamp > preSaleTime, "CRDN: PreSale not over yet");
        require(!canClaim, "CRDN: Already intialized");
        if (amountRaised > softCap) {
            
            // Create a pancake pair for this new token
            pancakePair = IPancakeFactory(routerAddress.factory()).createPair(
                address(this),
                routerAddress.WETH()
            );
            uint256 bnbAmountForLiquidity = amountRaised
                .mul(liquidityPercent)
                .div(100);
            uint256 tokenAmountForLiquidity = listingTokens(
                bnbAmountForLiquidity
            );
            token.approve(address(routerAddress), tokenAmountForLiquidity);
            addLiquidity(tokenAmountForLiquidity, bnbAmountForLiquidity);
            admin.transfer(amountRaised.mul(adminFeePercent).div(100));
            token.transfer(admin, soldTokens.mul(adminFeePercent).div(100));
            tokenOwner.transfer(getContractBnbBalance());
            uint256 refund = getContractTokenBalance().sub(soldTokens);
            if (refund > 0) token.transfer(deadAddress, refund);

            emit TokenUnSold(deadAddress, refund);
        } else {
            token.transfer(tokenOwner, getContractTokenBalance());

            emit TokenUnSold(tokenOwner, getContractBnbBalance());
        }
        canClaim = true;
    }

    // cancel the presale and return funds to owner and users
    function cancelPreSale() public onlyTokenOwner allowed {
        require(block.timestamp < preSaleTime, "CRDN: PreSale not over yet");
        require(!preSaleCanceled, "CRDN: PreSale already canceled");

        token.transfer(tokenOwner, getContractTokenBalance());
        preSaleCanceled = true;
        canClaim = true;
    }

    // claim funds if presale get canceled
    function claimBackFunds() public allowed {
        require(preSaleCanceled, "CRDN: PreSale not canceled");
        uint256 numberOfTokens = bnbBalance[msg.sender];
        require(numberOfTokens > 0, "CRDN: Zero balance");

        payable(msg.sender).transfer(numberOfTokens);
        bnbBalance[msg.sender] = 0;

        emit BnbClaimed(msg.sender, numberOfTokens);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal {

        // add the liquidity
        routerAddress.addLiquidityETH{value: bnbAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 300
        );
    }

    function unLockLiquidity() public onlyTokenOwner {
        require(block.timestamp >= lpLockTime,"CRDN: Wait for claim date");
        
        uint256 lpBalance = IPancakePair(pancakePair).balanceOf(address(this));
        IPancakePair(pancakePair).transfer(tokenOwner, lpBalance);
    }

    // to check number of token for buying
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(1000).div(1e18);
        return numberOfTokens.mul(10**(token.decimals())).div(1000);
    }

    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(listingPrice).mul(1000).div(1e18);
        return numberOfTokens.mul(10**(token.decimals())).div(1000);
    }

    // to check contribution
    function userContribution(address _user) public view returns (uint256) {
        return bnbBalance[_user];
    }

    // to check token balance of user
    function userTokenBalance(address _user) public view returns (uint256) {
        return tokenBalance[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin {
        allow = _enable;
    }

    // start next cycle of claim
    function startNextCycle() external onlyTokenOwner {
        nextClaimTime = nextClaimTime.add(30 days);
        currentClaimCycle++;
    }

    function getContractBnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function setTime(uint256 _presaleTime) external onlyTokenOwner {
        preSaleTime = _presaleTime;
    }
}