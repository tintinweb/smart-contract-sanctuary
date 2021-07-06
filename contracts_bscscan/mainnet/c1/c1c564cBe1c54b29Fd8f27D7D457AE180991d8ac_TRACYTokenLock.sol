/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IERC20Expanded {
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a);
        return c;
    }
}


// File contracts/interfaces/IStakingPool.sol

pragma solidity ^0.6.12;

interface IStakingPool {
    function computeUserWeight(address user) external view returns (uint256);
}


pragma solidity ^0.6.12;



contract TRACYTokenLock {

    // Using SafeMath library for uint256 operations
    using SafeMath for *;

    // Contract state in terms of deposit
    enum ContractState {PENDING_SUPPLY, TOKENS_SUPPLIED, SALE_ENDED}

    // State in which is contract
    ContractState state;

    // Participation structure
    struct Participation {
        uint amountBNBPaid;
        uint amountOfTokensReceived;
        uint timestamp;
        bool isWithdrawn;
    }

    
    // Amount of tokens user wants to sell
    uint256 amountOfTokensToSell;

    // Time at which tokens are getting unlocked
    uint256 tokensUnlockingTime;

    // Token which is being sold
    IERC20Expanded tokenSold;

    // Wallet address of project owner
    address projectOwnerWallet;

    // Address of staking pool contract
    IStakingPool stakingPool;

   
    // Constructor to create contract
    constructor(
        uint256 _tokensUnlockingTime,
        address _tokenAddress,
        address _projectOwnerWallet,
        address _stakingPool,
        uint256 _amountOfTokensToSell
    )
    public
    {
        // Requirements for contract creation
        require(_projectOwnerWallet != address(0x0));

        
        // Set time after which tokens can be withdrawn
        tokensUnlockingTime = _tokensUnlockingTime;

        // Token price and amount of tokens selling
        tokenSold = IERC20Expanded(_tokenAddress);

        
        // Allow selling only tokens with 9 decimals
        require(tokenSold.decimals() == 9);

        amountOfTokensToSell = _amountOfTokensToSell;

        // Wallet of project owner
        projectOwnerWallet = _projectOwnerWallet;

        // Set staking pool address inside contract
        stakingPool = IStakingPool(_stakingPool);

        // Set initial state to pending supply
        state = ContractState.PENDING_SUPPLY;
    }


    // Function for project owner or anyone who's in charge to deposit initial amount of tokens
    function depositTokensToLock()
    public
    {
        // This can be called only once, while contract is in the state of PENDING_SUPPLY
        require(state == ContractState.PENDING_SUPPLY, "Fund Contract : Must be in PENDING_SUPPLY state");

        // Make sure all tokens to be sold are deposited to the contract
        tokenSold.transferFrom(msg.sender, address(this), amountOfTokensToSell);

        // Mark contract state to SUPPLIED
        state = ContractState.TOKENS_SUPPLIED;
    }


    // Internal function to handle safe transfer
    function safeTransferBNB(
        address to,
        uint value
    )
    internal
    {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }

    function withdrawEarningsAndLeftover()
    public
    {
        require(msg.sender == projectOwnerWallet);

        // Make sure Lock timee xpired
        require(block.timestamp >= tokensUnlockingTime, "Time to unlock not reached yet");

      
        // Amount of tokens which are not sold
        uint leftover = amountOfTokensToSell;

        if(leftover > 0) {
            tokenSold.transfer(msg.sender, leftover);
        }

        // Set state of the contract to ENDED
        state = ContractState.SALE_ENDED;
    }

    

    // Function to check in which state is the contract at the moment
    function getInventoryState()
    public
    view
    returns (string memory)
    {
        if(state == ContractState.PENDING_SUPPLY) {
            return "PENDING_SUPPLY";
        }
        return "TOKENS_SUPPLIED";
    }

    // Function to return when purchased tokens can be withdrawn
    function getTokensUnlockingTime()
    public
    view
    returns (uint)
    {
        return tokensUnlockingTime;
    }
}