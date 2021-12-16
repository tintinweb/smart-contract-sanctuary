// SPDX-License-Identifier: MIT
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

/**
 * @dev 
 */

import './abstracts/Context.sol';
import './abstracts/ReentrancyGuard.sol';
import './abstracts/Democratic.sol';

import './libraries/SafeERC20.sol';

import './interfaces/IPairToken.sol';
import './interfaces/IERC20.sol';
import './interfaces/ISwapFactory.sol';
import './interfaces/ISwapRouter.sol';

contract CommunityIDO is Context, ReentrancyGuard, Democratic{
    
    using SafeERC20 for IERC20;

    bool public openIDO;
    bool public successIDO;
    bool public abortedIDO;
    bool public pauseIDO;
    
    uint256 public immutable tokenProvided;
    uint256 public immutable tokenSoldOnDate;
    uint256 public immutable tokenLocked;

    uint256 public remainingOnDate;
    uint256 public remainingOnLocked;

    uint256 public availableContribution;
    uint256 public contributionBalance;

    uint256 public immutable maxPurchasePerAddress;
    uint256 public immutable goalSuccess;

    uint256 public initialLiquidityToken;
    uint256 public pairTokenToDistribute;

    uint32 public contractClaimId;
    uint32 public claimIdDev;

    bool public liquidityDeployed;
    bool public liquidityPairCreated;
    bool public liquidityPoolCreated;
    uint256 public timeBeforeClaim;
    uint256 public immutable claimLatency;

    address public tokenAdd;
    address public contTokenAdd;
    address public swapRouterAdd;
    address public swapFactoryAdd;
    address public pairAdd;

    struct Contribution {
        address participant;
        uint256 contributionAmount;
        bool tokensWithdrawn;
        uint32 claimId;
    }

    struct Claim {
        uint32 claimId;
        uint256 amountToken;
        uint256 amountPairToken;
        uint256 date;
    }

    mapping(address => Contribution) private contributions;
    mapping(uint32 => Claim) private claims;

    event ClaimCreated(uint32 id, uint256 amountToken, uint256 amountPairToken);
    event ContributionConfirmed (address participant, uint contributionAmount);
    event RemovalConfirmed (address participant, uint removalAmount);
    event TokenClaimedConfirmed (address participant, uint tokenClaimed);
    event PairClaimedConfirmed (address participant, uint pairTokenClaimed);

    receive() external payable {
    }

    function CheckParticipantInfo(address account) external view returns(Contribution memory){
        return contributions[account];
    }

    function CheckClaimInfo(uint32 claimNumber) external view returns(Claim memory){
        return claims[claimNumber];
    }

    function setContractAddresses(
        address tokenAddress, 
        address contTokenAddress, 
        address swapFactoryAddress, 
        address swapRouterAddress
    ) external demokratia() {
        require(tokenAddress != address(0), 'token address must be a none 0 address');
        tokenAdd = tokenAddress;
        require(contTokenAddress != address(0), 'contribution token address must be a none 0 address');
        contTokenAdd = contTokenAddress;
        require(swapFactoryAddress != address(0), 'swap factory address must be a none 0 address');
        swapFactoryAdd = swapFactoryAddress;
        require(swapRouterAddress != address(0), 'swap router address must be a none 0 address');
        swapRouterAdd = swapRouterAddress;
    }

    function start() external demokratia() preIDO() {
        openIDO = true;
    }

    function participate(uint256 amount) external activeIDO() isPaused(){

        IERC20 contTokenSC = IERC20(contTokenAdd);
        uint amountDecimals = amount * 10 ** contTokenSC.decimals();
        uint balanceToken = contTokenSC.balanceOf(_msgSender());
        require(balanceToken>=amountDecimals, "Not enough token");

        Contribution storage  currentStatus = contributions[_msgSender()];
        uint remainingContribution = maxPurchasePerAddress - currentStatus.contributionAmount;

        require(remainingContribution > 0, 'You exceed the maximum contribution');

        uint tokenAmount = amount;

        if(tokenAmount > remainingContribution){
            tokenAmount = remainingContribution;
        }

        if(tokenAmount >= availableContribution){
            tokenAmount = availableContribution;
            successIDO = true;
            timeBeforeClaim = block.timestamp + claimLatency;
        }

        uint tokenAmountDecimals = tokenAmount * 10 ** contTokenSC.decimals();

        uint totalContribution = tokenAmount + currentStatus.contributionAmount;
        contributions[_msgSender()] = Contribution(_msgSender(), totalContribution, false, 0);
        contributionBalance += tokenAmount;
        availableContribution -= tokenAmount;

        contTokenSC.safeTransferFrom(_msgSender(), address(this), tokenAmountDecimals);
        emit ContributionConfirmed(_msgSender(), tokenAmount);
    }

    function removeParticipation (uint256 amount) external activeIDO() isPaused() nonReentrant() {

        Contribution storage currentStatus = contributions[_msgSender()];
 
        require(currentStatus.contributionAmount > 0, 'only Participants');
        require(amount <= currentStatus.contributionAmount, 'you claim more than you participated');

        IERC20 contTokenSC = IERC20(contTokenAdd);

        uint amountDecimals = amount * 10 ** contTokenSC.decimals();

        contributions[_msgSender()].contributionAmount -= amount;

        contributionBalance -= amount;
        availableContribution += amount;

        contTokenSC.safeTransfer(currentStatus.participant, amountDecimals);
        emit RemovalConfirmed(_msgSender(), amount);

    }

    function createLiquidityPair () external successfulIDO() demokratia() {
        require(!liquidityPairCreated, 'Liquidity Pair has already been created');
        liquidityPairCreated = true;
        ISwapFactory factorySC = ISwapFactory(swapFactoryAdd);
        pairAdd = factorySC.createPair(tokenAdd, contTokenAdd);
    }

    function createLiquidityPool () external successfulIDO() demokratia() {
        require(!liquidityPoolCreated, 'Liquidity Pool already created');
        require(liquidityPairCreated, 'Liquidity Pair not yet created');

        ISwapRouter routerSC = ISwapRouter(swapRouterAdd);
        IERC20 contTokenSC = IERC20(contTokenAdd);
        IERC20 tokenSC = IERC20(tokenAdd);

        uint decimalsContribution = contributionBalance * 10 ** contTokenSC.decimals();
        uint decimalsTokenProvided = tokenProvided * 10 ** tokenSC.decimals();
        liquidityPoolCreated = true;

        contTokenSC.safeIncreaseAllowance(swapRouterAdd, decimalsContribution*2);
        tokenSC.safeIncreaseAllowance(swapRouterAdd, decimalsTokenProvided*2);
        
        uint time = block.timestamp + 300;
        
        routerSC.addLiquidity(
            tokenAdd, contTokenAdd,
            decimalsTokenProvided, decimalsContribution,
            0, 0,
            address(this),
            time
        );
    }

    function initializeLPToken(uint toRoundUp) external successfulIDO() demokratia() {
        require(!liquidityDeployed, 'Deployment already done');
        require(liquidityPoolCreated, 'Liquidity Pool not yet created');

        IPairToken pair = IPairToken(pairAdd);

        uint moduloValue = 10 ** 19;

        uint  newBalance = pair.balanceOf(address(this)) - toRoundUp;
        require (newBalance % moduloValue == 0, "newBalance modulo 100  has to be 0");
        require (toRoundUp < moduloValue, "Round up has to be less than the modulo value");
        
        initialLiquidityToken = newBalance;

        timeBeforeClaim = block.timestamp + claimLatency;
        liquidityDeployed = true;

        IERC20 tokenSC = IERC20(tokenAdd);
        remainingOnDate = tokenSoldOnDate * 10 ** tokenSC.decimals();
        
        bool isTransfered = pair.transfer(_msgSender(), toRoundUp);
        
        if(isTransfered){
            emit PairClaimedConfirmed(_msgSender(), toRoundUp);
        }
    }

    function withdrawToken() external successfulIDO() nonReentrant() {
        require(liquidityDeployed, 'liquidity pool is not yet deployed');
        require(remainingOnDate > 0, 'All liquidity has been taken');
        Contribution storage currentStatus = contributions[_msgSender()];
        require(currentStatus.contributionAmount > 0, 'only participants');
        require(!currentStatus.tokensWithdrawn, 'tokens already withdrawned');

        IERC20 tokenSC = IERC20(tokenAdd);
        uint decimalsToken = tokenSoldOnDate * 10 ** tokenSC.decimals();
        uint256 withdrawingAmount =  decimalsToken * currentStatus.contributionAmount  / contributionBalance;
        
        currentStatus.tokensWithdrawn = true;
        remainingOnDate -= withdrawingAmount;

        bool isTransfered = tokenSC.transfer(currentStatus.participant, withdrawingAmount);
        
        if(isTransfered){
            emit TokenClaimedConfirmed(_msgSender(), withdrawingAmount);
        }
    }

    function createClaim () external successfulIDO() {
        require(block.timestamp > timeBeforeClaim, 'You can not create claim yet');
        uint pairTokenToRemove = initialLiquidityToken / 10;
        
        IERC20 tokenSC = IERC20(tokenAdd);

        uint tokenToRemove = tokenLocked * 10 ** tokenSC.decimals() / 10;

        pairTokenToDistribute += pairTokenToRemove;
        remainingOnLocked += tokenToRemove;

        contractClaimId += 1;
        claims[contractClaimId] = Claim(contractClaimId, tokenToRemove, pairTokenToRemove, block.timestamp);
        timeBeforeClaim = block.timestamp + claimLatency;

        emit ClaimCreated(contractClaimId, tokenToRemove, pairTokenToRemove);
    }

    function claimTokensDev () external successfulIDO() demokratia() nonReentrant() {
        require(pairTokenToDistribute>0, 'No Tokens to redistribute');
        require(contractClaimId > claimIdDev, 'dev team already got the claim');

        // identify the claim id
        uint32 newClaim = claimIdDev + 1;
        Claim storage claimStatus = claims[newClaim];

        // detrmine the amount for the dev Team
        uint pairTokenToClaim = 2 * claimStatus.amountPairToken / 5 ;

        // send the LP token to the dev team personal address
        IPairToken pair = IPairToken(pairAdd);
        pairTokenToDistribute -= pairTokenToClaim;
        claimIdDev = newClaim;

        bool isTransfered = pair.transfer(_msgSender(), pairTokenToClaim);
        if(isTransfered){
            emit PairClaimedConfirmed(_msgSender(), pairTokenToClaim);
        }
    }

    function claimTokens () external successfulIDO() nonReentrant() {
        require(pairTokenToDistribute>0, 'No Tokens to redistribute');

        Contribution storage currentStatus = contributions[_msgSender()];
        require(currentStatus.contributionAmount > 0, 'only Participants');
        require(contractClaimId > currentStatus.claimId, 'You already got your claims');

        // identify the claim id
        uint32 newClaim = currentStatus.claimId + 1;
        Claim storage claimInfo = claims[newClaim];

        // detrmine the amount to claim
        uint pairTokenToClaim =  claimInfo.amountPairToken * (3 * currentStatus.contributionAmount) / (contributionBalance * 5);
        uint tokenToClaim =  claimInfo.amountToken * currentStatus.contributionAmount / contributionBalance;

        // Claim tokens
        IPairToken pair = IPairToken(pairAdd);
        IERC20 tokenSC = IERC20(tokenAdd);

        pairTokenToDistribute -= pairTokenToClaim;
        contributions[_msgSender()].claimId = newClaim;

        remainingOnLocked -= tokenToClaim;

        bool isPairTransfered = pair.transfer(_msgSender(), pairTokenToClaim);
        tokenSC.safeTransfer(_msgSender(), tokenToClaim);

        if(isPairTransfered){
            emit PairClaimedConfirmed(_msgSender(), pairTokenToClaim);
        }
        emit TokenClaimedConfirmed(_msgSender(), tokenToClaim);          
        
    }

    // security function
    function exitCIDO () external failedIDO() nonReentrant() {

        Contribution storage currentStatus = contributions[_msgSender()];
 
        require(currentStatus.contributionAmount > 0, 'only Participants');
        require(!currentStatus.tokensWithdrawn, 'tokens already withdrawned');

        IERC20 contTokenSC = IERC20(contTokenAdd);
        uint amountDecimals = currentStatus.contributionAmount * 10 ** contTokenSC.decimals();

        currentStatus.tokensWithdrawn = true;
        
        contTokenSC.safeTransfer(currentStatus.participant, amountDecimals);
        
        emit RemovalConfirmed(_msgSender(), amountDecimals);


    }

    function sendBackCoin(address payable recipient, uint amount) external demokratia() {
        require(recipient != address(0), 'None 0 Address');
        payable(recipient).transfer(amount);
    }

    function sendBackAnyToken(address wrongTokenAddress, address recipient, uint amount) external demokratia() {
        require(wrongTokenAddress != tokenAdd, 'Can not send Lenny Through this function');
        require(wrongTokenAddress != contTokenAdd, 'Can not send BUSD Through this function');
        require(recipient != address(0), 'None 0 Address');
        IERC20 tokenSC = IERC20(wrongTokenAddress);
        tokenSC.safeTransfer(recipient, amount);
    }

    function stopIDO() external demokratia() activeIDO() {
        pauseIDO = !pauseIDO;
    }

    function abortIDO() external demokratia() activeIDO() {
        abortedIDO = !abortedIDO;
    }

    function getDeployment() external view returns(bool) {
        return liquidityDeployed;
    }

    modifier preIDO() {
        require(!openIDO, 'ido already active');
        _;
    }

    modifier activeIDO() {
        require(openIDO, 'ido must be active');
        require(!successIDO, 'goal already reached');
        _;
    }

    modifier successfulIDO() {
        require(successIDO, 'ido must be a success');
        _;
    }

    modifier failedIDO() {
        require(abortedIDO, 'ido must have been aborded');
        _;
    }

    modifier isPaused() {
        require(!pauseIDO, 'ido has been pause');
        _;
    }

    constructor(uint _tokenProvided,
                uint _tokenSoldOnDate,
                uint _tokenLocked,
                uint _goalSuccess,
                uint _maxPurchasePerAddress,
                uint _claimLatency,
                address _doscAddress
                ) Democratic(_doscAddress) {
                tokenProvided = _tokenProvided;
                tokenSoldOnDate = _tokenSoldOnDate;
                tokenLocked = _tokenLocked;
                goalSuccess = _goalSuccess;
                availableContribution = _goalSuccess;
                maxPurchasePerAddress = _maxPurchasePerAddress;
                claimLatency = _claimLatency;
                }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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


    constructor() {
        _status = _NOT_ENTERED;
     }
     


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

import '../interfaces/IDOSC.sol';
import './Context.sol';
/**
 * @dev Provides implementation on the democratic ownership smart contract
 * and allows the child contract that inherites from the Democratic abstact 
 * to interact with the DemocraticOwnership smart contract. The address of 
 * the DemocraticOwnership smart contact address is set within the constructor
 * and can not be change through the lifetime of the child smart contract.
 *
 */

abstract contract Democratic is Context {
    address public immutable doscAdd;
    address public lastAuthorizedAddress;
    uint256 public lastChangingTime;

    constructor(address _doscAdd) {
        doscAdd = _doscAdd;
    }

    function updateSC() external {
        IDOSC dosc = IDOSC(doscAdd);
        lastAuthorizedAddress = dosc.readAuthorizedAddress();
        lastChangingTime = dosc.readEndChangeTime();
    }

    modifier demokratia() {
        require(lastAuthorizedAddress == _msgSender(), "You are not authorized to change");
        require(lastChangingTime >= block.timestamp, "Time for changes expired");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// Compiling the interface with solidity 0.8 => using Uniswap V2 Factory implementation

pragma solidity ^0.8.0;

interface IPairToken {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// Compiling the interface with solidity 0.8 => using Uniswap V2 Factory implementation

pragma solidity ^0.8.0;

interface ISwapFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
// Compiling the interface with solidity 0.8 => using Uniswap V2 Factory implementation

pragma solidity ^0.8.0;

interface ISwapRouter {
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
    

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

/**
 * @dev Provides the interface of democratic ownership smart contract
 * to interact with. The callable functions are readAuthorizedAddress,
 * readEndChangeTime and RegisterCall.
 */

interface IDOSC {
    function readAuthorizedAddress() external view returns (address);
    function readEndChangeTime() external view returns (uint);
    function registerCall(string memory scname, string memory funcname) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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