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
        address _admin,
        address _tokenOwner,
        IERC20 _token,
        uint256 _minAmount,
        uint256 _maxAmount,
        address _routerAddress,
        uint256 _adminFeePercent,
        uint256 _vestingTime,
        uint8 _vestingPercent,
        uint8 _choice
    ) external ;

    function initializeRemaining(
        uint256 _tokenPrice,
        uint256 _presaleTime,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _listingTime,
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

contract preSale {

    using SafeMath for uint256;
    using SafeMath for uint8;
    
    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public token;
    IPancakeRouter02 public routerAddress;

    uint256 public adminFeePercent;
    uint256 public tokenPrice;
    uint256 public preSaleEndTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public vestingTime;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public listingPrice;
    uint256 public listingTime;
    uint256 public liquidityPercent;
    uint8 public saleType;
    uint8 public vestingPercent;
    uint8 public currentClaimCycle;
    uint256 public soldTokens;
    uint256 public totalUser;
    uint256 public amountRaised;
    uint256 public voteUp;
    uint256 public voteDown;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint8 public currentVotingCycle;
    uint256 public totalCoinForVesting;
    uint256 public totalTokenForVesting;

    bool public allow;
    bool public profitClaim;
    bool public votingStatus;
    bool public canClaim;

    struct VotingData{
        // uint256 amount;
        bool vote;
        bool voteCasted;
    }

    mapping(address => uint256) private coinBalance;
    mapping(address => uint256) private tokenBalance;
    mapping(address => uint256) public activeClaimAmountCoin;
    mapping(address => uint256) public activeClaimAmountToken;

    mapping(address => uint256) public claimCount;
    mapping(address => mapping(uint8 => VotingData)) internal usersVoting;

    modifier onlyAdmin(){
        require(msg.sender == admin,"PRESALE: Not an admin");
        _;
    }

    modifier onlyTokenOwner(){
        require(msg.sender == tokenOwner,"PRESALE: Not a token owner");
        _;
    }

    modifier allowed(){
        require(allow,"PRESALE: Not allowed");
        _;
    }
    
    event TokenBought(address indexed user, uint256 indexed numberOfTokens, uint256 indexed amountBusd);

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event CoinClaimed(address indexed user, uint256 indexed numberOfCoins);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        voteUp = 1;
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _token,
        uint256 _minAmount,
        uint256 _maxAmount,
        address _routerAddress,
        uint256 _adminFeePercent,
        uint256 _vestingTime,
        uint8 _vestingPercent,
        uint8 _choice
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        admin = payable(_admin);
        tokenOwner = payable(_tokenOwner);
        token = _token;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        routerAddress = IPancakeRouter02(_routerAddress);
        adminFeePercent = _adminFeePercent;
        vestingTime =_vestingTime;
        vestingPercent = _vestingPercent;
        saleType = _choice;
    }

    // called once by the deployer contract at time of deployment
    function initializeRemaining(
        uint256 _tokenPrice,
        uint256 _presaleEndTime,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _listingPrice,
        uint256 _listingTime,
        uint256 _liquidityPercent
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        tokenPrice = _tokenPrice;
        preSaleEndTime = _presaleEndTime;
        hardCap = _hardCap;
        softCap = _softCap;
        listingPrice = _listingPrice;
        listingTime = _listingTime;
        liquidityPercent = _liquidityPercent;
    }

    receive() payable external{}
    
    // to buy token during preSale time => for web3 use
    function buyToken() public payable allowed{
        require(block.timestamp < preSaleEndTime,"PRESALE: Time over"); // time check
        require(getContractcoinBalance().add(msg.value) <= hardCap,"PRESALE: Hardcap reached");
        uint256 numberOfTokens = coinToToken(msg.value);
        require(msg.value >= minAmount && coinBalance[msg.sender].add(msg.value) <= maxAmount,"PRESALE: Invalid Amount");
        
        if(tokenBalance[msg.sender] == 0){
            totalUser++;
        }
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldTokens = soldTokens.add(numberOfTokens);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);
        amountRaised = amountRaised.add(msg.value);

        emit TokenBought(msg.sender, numberOfTokens, msg.value);
    }
    
    // to claim token after launch => for web3 use
    function claim() public allowed{
        require(block.timestamp > preSaleEndTime,"PRESALE: Presale time not over");
        require(canClaim,"PRESALE: Wait for the owner to end preSale");
        if(amountRaised >= softCap && voteUp > voteDown){
            require(block.timestamp >= preSaleEndTime + vestingTime
                && claimCount[msg.sender] <= currentClaimCycle 
                ,"PRESALE: Wait for next claim date");
            uint256 numberOfTokens = tokenBalance[msg.sender];
            require(numberOfTokens > 0,"PRESALE: Zero balance");

            if(claimCount[msg.sender] == 0){
                activeClaimAmountToken[msg.sender] = tokenBalance[msg.sender].mul(vestingPercent).div(100);
                activeClaimAmountToken[msg.sender] = coinBalance[msg.sender].mul(vestingPercent).div(100);

                token.transfer(msg.sender, activeClaimAmountToken[msg.sender]);
                tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(activeClaimAmountToken[msg.sender]);
                coinBalance[msg.sender] = coinBalance[msg.sender].sub(activeClaimAmountCoin[msg.sender]);
                claimCount[msg.sender] ++;
            }else{
                if(activeClaimAmountToken[msg.sender] > tokenBalance[msg.sender]){
                    token.transfer(msg.sender, activeClaimAmountToken[msg.sender]);
                    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(activeClaimAmountToken[msg.sender]);
                    coinBalance[msg.sender] = coinBalance[msg.sender].sub(activeClaimAmountCoin[msg.sender]);
                }else{
                    token.transfer(msg.sender, tokenBalance[msg.sender]);
                    tokenBalance[msg.sender] = 0;
                    coinBalance[msg.sender] = 0;
                }
                claimCount[msg.sender] ++;
            } 

            emit TokenClaimed(msg.sender, activeClaimAmountToken[msg.sender]);
        }else {
            uint256 numberOfTokens = coinBalance[msg.sender];
            require(numberOfTokens > 0,"PRESALE: Zero balance");
        
            payable(msg.sender).transfer(numberOfTokens);
            coinBalance[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }
    }

    // withdraw the funds and initialize the liquidity pool
    function endPreSale() public onlyTokenOwner allowed{
        require(block.timestamp > preSaleEndTime + listingTime,"PRESALE: Listing time not met");
        if(saleType == 1){
            if(amountRaised >= softCap && voteUp > voteDown){
                if(!profitClaim){
                    totalCoinForVesting = amountRaised.mul(liquidityPercent).div(100);
                    totalTokenForVesting = listingTokens(totalCoinForVesting);
                    admin.transfer(amountRaised.mul(adminFeePercent).div(100));
                    token.transfer(admin, soldTokens.mul(adminFeePercent).div(100));
                    uint256 refundToken = getContractTokenBalance().sub(soldTokens);
                    if(refundToken > 0)
                        token.transfer(tokenOwner, refundToken); 
                    uint256 remainingCoin = getContractcoinBalance().sub(totalCoinForVesting);
                    if(remainingCoin > 0)
                        tokenOwner.transfer(remainingCoin); 
                    profitClaim = true;
                    emit TokenUnSold(tokenOwner, refundToken);
                }else{
                    require(block.timestamp >= preSaleEndTime + vestingTime
                        && claimCount[msg.sender] <= currentClaimCycle 
                        , "PRESALE: Wait for next claim date");
                }
                uint256 coinAmountForLiquidity = totalCoinForVesting.mul(vestingPercent).div(100);
                uint256 tokenAmountForLiquidity = totalTokenForVesting.mul(vestingPercent).div(100);
                token.approve(address(routerAddress), tokenAmountForLiquidity);
                addLiquidity(tokenAmountForLiquidity, coinAmountForLiquidity);

            }else{
                token.transfer(tokenOwner, getContractTokenBalance());
                emit TokenUnSold(tokenOwner, getContractcoinBalance());
            }
        }else{
            if(amountRaised >= softCap && voteUp > voteDown){
                if(!profitClaim){
                    admin.transfer(amountRaised.mul(adminFeePercent).div(100));
                    token.transfer(admin, soldTokens.mul(adminFeePercent).div(100));
                    totalCoinForVesting = getContractcoinBalance();
                    uint256 refundToken = getContractTokenBalance().sub(soldTokens);
                    if(refundToken > 0)
                        token.transfer(tokenOwner, refundToken); 
                    profitClaim = true;
                    emit TokenUnSold(tokenOwner, refundToken);
                }
                else{
                    require(block.timestamp >= preSaleEndTime + vestingTime
                        && claimCount[msg.sender] <= currentClaimCycle 
                        , "PRESALE: Wait for next claim date");
                }
                uint256 coinAmountForLiquidity = totalCoinForVesting.mul(vestingPercent).div(100);
                token.transfer(tokenOwner, coinAmountForLiquidity);
            }else{
                token.transfer(tokenOwner, getContractTokenBalance());
                emit TokenUnSold(tokenOwner, getContractcoinBalance());
            }
        }
        canClaim = true;
    }

    function vote(bool _vote) public {
        // require(token.balanceOf(msg.sender) > 0,"VOTING: Voter must be a holder");
        require(!usersVoting[msg.sender][currentVotingCycle].voteCasted,"VOTING: Already cast a vote");
        require(votingStatus,"VOTING: Not Allowed");
        require(block.timestamp >= votingStartTime && block.timestamp < votingEndTime,"VOTING: Wrong Timing");

        // usersVoting[msg.sender].amount = _amount;
        usersVoting[msg.sender][currentVotingCycle].vote = _vote;
        usersVoting[msg.sender][currentVotingCycle].voteCasted = true;

        // token.transferFrom(msg.sender, address(this), _amount);
        
        if(_vote){
            voteUp = voteUp.add(1);
        }else{
            voteDown = voteDown.add(1);
        }

    }

    // function claimBackVotingTokens() public {
    //     require(usersVoting[msg.sender].amount > 0);
    //     require(!votingStatus,"VOTING: Not Allowed");
    //     require(block.timestamp > votingEndTime,"VOTING: Wrong timing");

    //     token.transfer(msg.sender, usersVoting[msg.sender].amount);
    //     usersVoting[msg.sender].amount = 0;
    //     usersVoting[msg.sender].voteCasted = false;
    // } 
    
    function addLiquidity(
        uint256 tokenAmount,
        uint256 coinAmount
    ) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : coinAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tokenOwner,
            block.timestamp + 360
        );
    }

    function startVoting(uint256 _endTime) external onlyAdmin{
        require(!votingStatus,"VOTING: Already started");
        require(block.timestamp > preSaleEndTime.add(vestingTime),"VOTING: Presale not end");
        votingStatus  = true;
        voteUp = 0;
        voteDown = 0;
        votingStartTime = block.timestamp;
        votingEndTime = block.timestamp.add(_endTime);
        currentVotingCycle++;
    }

    function endVoting() external onlyAdmin{
        require(votingStatus,"VOTING: Already ended");
        votingStatus = false;
        vestingTime = vestingTime.add(vestingTime);
        currentClaimCycle ++;
    }

    // to check number of token for buying
    function coinToToken(uint256 _amount) public view returns(uint256){
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
        return coinBalance[_user];
    }

    // to check token balance of user
    function userTokenBalance(address _user) public view returns(uint256){
        return tokenBalance[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin{
        allow = _enable;
    }
    
    function getContractcoinBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }

    // get user voting data
    function getUserVotingData(address _user, uint8 _votingIndex) public view returns(bool _vote, bool _voteCasted){

        return (usersVoting[_user][_votingIndex].vote, usersVoting[_user][_votingIndex].voteCasted);
    }

    function setTime(uint256 _presaleEndTime) external onlyTokenOwner{
        preSaleEndTime  = _presaleEndTime;
    }
    
}

