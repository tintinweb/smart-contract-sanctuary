//SPDX-License-Identifier: UNLICENSED


import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/TokenTimelock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

pragma solidity ^0.7.3;


contract FontsPresale is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //===============================================//
    //          Contract Variables: Mainnet          //
    //===============================================//

    uint256 public MIN_CONTRIBUTION = 0.1 ether;
    uint256 public MAX_CONTRIBUTION = 6 ether;

    uint256 public HARD_CAP = 180 ether; //@change for testing 

    uint256 constant FONTS_PER_ETH_PRESALE = 1111;
    uint256 constant FONTS_PER_ETH_UNISWAP = 700;

    uint256 public UNI_LP_ETH = 86 ether;
    uint256 public UNI_LP_FONT;

    uint256 public constant UNLOCK_PERCENT_PRESALE_INITIAL = 50; //For presale buyers instant release
    uint256 public constant UNLOCK_PERCENT_PRESALE_SECOND = 30; //For presale buyers after 30 days
    uint256 public constant UNLOCK_PERCENT_PRESALE_FINAL = 20; //For presale buyers after 60 days

    uint256 public DURATION_REFUND = 7 days;
    uint256 public DURATION_LIQUIDITY_LOCK = 365 days;

    uint256 public DURATION_TOKEN_DISTRIBUTION_ROUND_2 = 30 days;
    uint256 public DURATION_TOKEN_DISTRIBUTION_ROUND_3 = 60 days;    

    address FONT_TOKEN_ADDRESS = 0x4C25Bdf026Ea05F32713F00f73Ca55857Fbf6342; //FONT Token address

    IUniswapV2Router02 constant UNISWAP_V2_ADDRESS =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 


    //General variables

    IERC20 public FONT_ERC20; //Font token address

    address public ERC20_uniswapV2Pair; //Uniswap Pair address

    TokenTimelock public UniLPTimeLock;

    
    uint256 public tokensBought; //Total tokens bought
    uint256 public tokensWithdrawn;  //Total tokens withdrawn by buyers

    bool public isStopped = false;
    bool public presaleStarted = false;
    bool public uniPairCreated = false;
    bool public liquidityLocked = false;
    bool public bulkRefunded = false;

    bool public isFontDistributedR1 = false;
    bool public isFontDistributedR2 = false;
    bool public isFontDistributedR3 = false;



    uint256 public roundTwoUnlockTime; 
    uint256 public roundThreeUnlockTime; 
    
    bool liquidityAdded = false;

    address payable contract_owner;
    
    
    uint256 public liquidityUnlockTime;
    
    uint256 public ethSent; //ETH Received
    
    uint256 public lockedLiquidityAmount;
    uint256 public refundTime; 

    mapping(address => uint) ethSpent;
    mapping(address => uint) fontBought;
    mapping(address => uint) fontHolding;
    address[] public contributors;

    

    constructor() {
        contract_owner = _msgSender(); 
        //ChangeSettingsForTestnet();
        UNI_LP_FONT = UNI_LP_ETH.mul(FONTS_PER_ETH_UNISWAP);
        FONT_ERC20 = IERC20(FONT_TOKEN_ADDRESS);
    }


    //@done
    receive() external payable {   
        buyTokens();
    }
    


    //@done
    function allowRefunds() external onlyOwner nonReentrant {

        isStopped = true;
    }

    //@done
    function buyTokens() public payable nonReentrant {
        require(_msgSender() == tx.origin);
        require(presaleStarted == true, "Presale is paused");
        require(msg.value >= MIN_CONTRIBUTION, "Less than 0.1 ETH");
        require(msg.value <= MAX_CONTRIBUTION, "More than 6 ETH");
        require(ethSent < HARD_CAP, "Hardcap reached");        
        require(msg.value.add(ethSent) <= HARD_CAP, "Hardcap will reached");
        require(ethSpent[_msgSender()].add(msg.value) <= MAX_CONTRIBUTION, "> 6 ETH");

        require(!isStopped, "Presale stopped"); //@todo

        
        uint256 tokens = msg.value.mul(FONTS_PER_ETH_PRESALE);
        require(FONT_ERC20.balanceOf(address(this)) >= tokens, "Not enough tokens"); //@tod

        if(ethSpent[_msgSender()] == 0) {
            contributors.push(_msgSender()); //Create list of contributors    
        }
        
        ethSpent[_msgSender()] = ethSpent[_msgSender()].add(msg.value);

        tokensBought = tokensBought.add(tokens);
        ethSent = ethSent.add(msg.value);

        fontBought[_msgSender()] = fontBought[_msgSender()].add(tokens); //Add fonts bought by contributor

        fontHolding[_msgSender()] = fontHolding[_msgSender()].add(tokens); //Add fonts Holding by contributor

    }

    //@done, create unipair first. 
    function createUniPair() external onlyOwner {
        require(!liquidityAdded, "liquidity Already added");
        require(!uniPairCreated, "Already Created Unipair");

        ERC20_uniswapV2Pair = uniswapFactory.createPair(address(FONT_ERC20), UNISWAP_V2_ADDRESS.WETH());

        uniPairCreated = true;
    }


   
    //@done
    function addLiquidity() external onlyOwner {
        require(!liquidityAdded, "liquidity Already added");
        require(ethSent >= HARD_CAP, "Hard cap not reached");   
        require(uniPairCreated, "Uniswap pair not created");


        FONT_ERC20.approve(address(UNISWAP_V2_ADDRESS), UNI_LP_FONT);
        
        UNISWAP_V2_ADDRESS.addLiquidityETH{ value: UNI_LP_ETH } (
            address(FONT_ERC20),
            UNI_LP_FONT,
            UNI_LP_FONT,
            UNI_LP_ETH,
            address(contract_owner),
            block.timestamp
        );
       
        liquidityAdded = true;
       
        if(!isStopped)
            isStopped = true;

        //Set duration for FONT distribution 
        roundTwoUnlockTime = block.timestamp.add(DURATION_TOKEN_DISTRIBUTION_ROUND_2); 
        roundThreeUnlockTime = block.timestamp.add(DURATION_TOKEN_DISTRIBUTION_ROUND_3); 
    }

    //Lock the liquidity 
    function lockLiquidity() external onlyOwner {
        require(liquidityAdded, "Add Liquidity");
        require(!liquidityLocked, "Already Locked");
        //Lock the Liquidity 
        IERC20 liquidityTokens = IERC20(ERC20_uniswapV2Pair); //Get the Uni LP token
        if(liquidityUnlockTime <= block.timestamp) {
            liquidityUnlockTime = block.timestamp.add(DURATION_LIQUIDITY_LOCK);
        }
        UniLPTimeLock = new TokenTimelock(liquidityTokens, contract_owner, liquidityUnlockTime);
        liquidityLocked = true;
        lockedLiquidityAmount = liquidityTokens.balanceOf(contract_owner);
    }
    
    //Unlock it after 1 year
    function unlockLiquidity() external onlyOwner  {      
        UniLPTimeLock.release();
    }

    //Check when Uniswap V2 tokens are unlocked
    function unlockLiquidityTime() external view returns(uint256) {      
        return UniLPTimeLock.releaseTime();
    }    

    /*
    //FONT can be claim by investors after sale success, It is optional 
    //@done
    function claimFontRoundOne() external nonReentrant {
        require(liquidityAdded,"FontsCrowdsale: can only claim after listing in UNI");  
        require(fontHolding[_msgSender()] > 0, "FontsCrowdsale: No FONT token available for this address to claim");       
        uint256 tokenAmount_ = fontBought[_msgSender()];

        tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_INITIAL).div(100);
        fontHolding[_msgSender()] = fontHolding[_msgSender()].sub(tokenAmount_);

        // Transfer the $FONTs to the beneficiary
        FONT_ERC20.safeTransfer(_msgSender(), tokenAmount_);
        tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
    }

    //30% of FONT can be claim by investors after 30 days from unilisting
    //@done

    function claimFontRoundTwo() external nonReentrant {
        require(liquidityAdded,"Claimble after UNI list");  
        require(fontHolding[_msgSender()] > 0, "0 FONT");
        require(block.timestamp >= roundTwoUnlockTime, "Timelocked");

        uint256 tokenAmount_ = fontBought[_msgSender()];

        tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_SECOND).div(100);
        fontHolding[_msgSender()] = fontHolding[_msgSender()].sub(tokenAmount_);

        // Transfer the $FONTs to the beneficiary
        FONT_ERC20.safeTransfer(_msgSender(), tokenAmount_);
        tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
    }

    //20% of FONT can be claim by investors after 20 days from unilisting
    //@done
    function claimFontRoundThree() external nonReentrant {
        require(liquidityAdded,"Claimble after UNI list");  
        require(fontHolding[_msgSender()] > 0, "0 FONT");
        require(block.timestamp >= roundThreeUnlockTime, "Timelocked");

        uint256 tokenAmount_ = fontBought[_msgSender()];

        tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_FINAL).div(100);
        fontHolding[_msgSender()] = fontHolding[_msgSender()].sub(tokenAmount_);

        // Transfer the $FONTs to the beneficiary
        FONT_ERC20.safeTransfer(_msgSender(), tokenAmount_);
        tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
    }
    */
    
    //@done distribute first round of tokens
    function distributeTokensRoundOne() external onlyOwner {
        require(liquidityAdded, "Add Uni Liquidity");        
        require(!isFontDistributedR1, "Round 1 done");
        for (uint i=0; i<contributors.length; i++) {          
            if(fontHolding[contributors[i]] > 0) {
                uint256 tokenAmount_ = fontBought[contributors[i]];
                tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_INITIAL).div(100);
                fontHolding[contributors[i]] = fontHolding[contributors[i]].sub(tokenAmount_);
                // Transfer the $FONTs to the beneficiary
                FONT_ERC20.safeTransfer(contributors[i], tokenAmount_);
                tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
            }
        }
        isFontDistributedR1 = true;
    }

    //Let any one call next 30% of distribution
    //@done
    function distributeTokensRoundTwo() external nonReentrant{
        require(liquidityAdded, "Add Uni Liquidity"); 
        require(isFontDistributedR1, "Do Round 1");
        require(block.timestamp >= roundTwoUnlockTime, "Timelocked");
        require(!isFontDistributedR2, "Round 2 done");

        for (uint i=0; i<contributors.length; i++) {
            if(fontHolding[contributors[i]] > 0) {
                uint256 tokenAmount_ = fontBought[contributors[i]];
                tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_SECOND).div(100);
                fontHolding[contributors[i]] = fontHolding[contributors[i]].sub(tokenAmount_);
                // Transfer the $FONTs to the beneficiary
                FONT_ERC20.safeTransfer(contributors[i], tokenAmount_);
                tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
            }
        }
        isFontDistributedR2 = true;
    }

    //Let any one call final 20% of distribution
    //@done
    function distributeTokensRoundThree() external nonReentrant{
        require(liquidityAdded, "Add Uni Liquidity"); 
        require(isFontDistributedR2, "Do Round 2");
        require(block.timestamp >= roundThreeUnlockTime, "Timelocked");
        require(!isFontDistributedR3, "Round 3 done");

        for (uint i=0; i<contributors.length; i++) {
            if(fontHolding[contributors[i]] > 0) {
                uint256 tokenAmount_ = fontBought[contributors[i]];
                tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_FINAL).div(100);
                fontHolding[contributors[i]] = fontHolding[contributors[i]].sub(tokenAmount_);
                // Transfer the $FONTs to the beneficiary
                FONT_ERC20.safeTransfer(contributors[i], tokenAmount_);
                tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
            }
        }
        isFontDistributedR3 = true;
    }
    


    //@done
    //Withdraw the collected remaining eth
    function withdrawEth(uint amount) external onlyOwner returns(bool){
        require(liquidityAdded,"After UNI LP");        
        require(amount <= address(this).balance);
        contract_owner.transfer(amount);
        return true;
    }    

    //@done
    //Allow admin to withdraw any pending FONT after everyone withdraw, 60 days
    function withdrawFont(uint amount) external onlyOwner returns(bool){
        require(liquidityAdded,"After UNI LP");
        require(isFontDistributedR3, "After distribute to buyers");
        FONT_ERC20.safeTransfer(_msgSender(), amount);
        return true;
    }

    //@done
    function userFontBalance(address user) external view returns (uint256) {
        return fontHolding[user];
    }

    //@done
    function userFontBought(address user) external view returns (uint256) {
        return fontBought[user];
    }

    //@done
    function userEthContribution(address user) external view returns (uint256) {
        return ethSpent[user];
    }    

    //@done
    function getRefund() external nonReentrant {
        require(_msgSender() == tx.origin);
        require(isStopped, "Should be stopped");
        require(!liquidityAdded);
        // To get refund it not reached hard cap and 7 days had passed 
        require(ethSent < HARD_CAP && block.timestamp >= refundTime, "Cannot refund");
        uint256 amount = ethSpent[_msgSender()];
        require(amount > 0, "No ETH");
        address payable user = _msgSender();
        
        ethSpent[user] = 0;
        fontBought[user] = 0;
        fontHolding[user] = 0;
        user.transfer(amount);
    }

    //@done let anyone call it
    function bulkRefund() external nonReentrant {
        require(!liquidityAdded);
        require(!bulkRefunded, "Already refunded");
        require(isStopped, "Should be stopped");
        // To get refund it not reached hard cap and 7 days had passed 
        require(ethSent < HARD_CAP && block.timestamp >= refundTime, "Cannot refund");
        for (uint i=0; i<contributors.length; i++) {
            address payable user = payable(contributors[i]);
            uint256 amount = ethSpent[user];
            if(amount > 0) {
                ethSpent[user] = 0;
                fontBought[user] = 0;
                fontHolding[user] = 0;                
                user.transfer(amount);
            }
        }        
        bulkRefunded = true;
    }    
    
    //@done Call this to kickstart fundraise
    function startPresale() external onlyOwner { 
        liquidityUnlockTime = block.timestamp.add(DURATION_LIQUIDITY_LOCK);
        refundTime = block.timestamp.add(DURATION_REFUND);        
        presaleStarted = true;
    }
    
    //@done
    function pausePresale() external onlyOwner { 
        presaleStarted = false;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor (IERC20 token_, address beneficiary_, uint256 releaseTime_) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.3;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.3;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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