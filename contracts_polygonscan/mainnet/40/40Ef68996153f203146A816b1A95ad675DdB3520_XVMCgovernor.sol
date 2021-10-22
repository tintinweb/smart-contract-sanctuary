/**
 *Submitted for verification at polygonscan.com on 2021-10-21
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


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
}


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

interface IacPool {
    function setCallFee(uint256 _callFee, uint256 _callFeeWithBonus) external;
    function totalShares() external returns (uint256);
    function totalVotesFor(uint256 proposalID) external returns (uint256);
    function setAdmin(address _admin) external;
    function setTreasury(address _treasury) external;
	//function giftDeposit(uint256 _amount, address _recipientAddress) external;
	//the above will not work due to notContract modifier
}

interface IMasterChef {
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external;
    function updateEmissionRate(uint256 _gajPerBlock) external;
    function setFeeAddress(address _feeAddress) external;
    function dev(address _devaddr) external;
    function transferOwnership(address newOwner) external;
    function XVMCPerBlock() external returns (uint256);
    function totalAllocPoint() external returns (uint256);
    function updatePool(uint256 _pid) external;
}

interface IXVMCtreasury {
    function setOwner(address _owner) external;
    function setDelay(uint256 _delay) external;
	function requestWithdraw(uint256 _value) external;
	function requestWithdrawToken(address _token, address _receiver, uint _value) external;
	function executeWithdrawal(uint256 _ID) external;
}

//for now only function for transfer ownership
//could be updated with ability to approve NFTs to make it work as a NFT marketplace
interface IwalletForNFT {
    function setOwner(address _newOwner) external;
}

    /**
     * XVMC governor is a decentralized masterchef governed by it's users
     * The desired effect is to create an "INVERSE-yield farm"
     * Works as a decentralized cryptocurrency with no third-party control
     * 
     * The protocol is designed to create scarcity, attract liquidity and increase it's value
     * 
     * Scarcity: Time Deposits -> Users get paid for staking their
     *          tokens for longer, removing supply from the market
     * Attract Liquidity: Innovative inflation model, where the global inflation is decreasing forever
     *           and on every decrease there is a period of boosted inflation(APY) that attracts new users
     * 
     * It solves the oracle issue. The inflation of the system is effectively governed
     * by the users who act as oracles that decide the best rate of inflation.
     * There is an economic cost to voting guaranteeing responsibility for actions taken.
     * Voting works as an auction, which will probably result in bigger and smarter
     * players taking the responsibility. They will have the highest vested interest,
     * and as they act for their own benefit, it just so happens they act in the best interest of all the other holders.
     * 
     * The protocol has full upgradeability. The most adaptible species are the ones to survive.
     * XVMC has probably one of the best consensus systems in the entire world.
     * Consensus is reached by the votes of long term stakers, whose tokens are locked-in from 6 months and up to 5 years
     * Anything can be changed, from time-locked deposits to the entire smart contract and governance if 90% of stakers agree
     * Time-locked deposits can be migrated to new pools, allowing for migration without paying the penalty
     * 
     * Instead of enrichening devs or creators, the XVMC protocol holds the MEME tokens(DOGE2, DOGE420, DOGE69),
     * As well as CryptoMacaronis NFT collection, with the potential for other assets and NFTs to be added to the treasury
     * It's a wonderful concept because it makes XVMC an appealing asset to those looking for exposure to
     * NFTs and MEME tokens, without actually having to own the assets.
     * The average consumers are the ones shaping the markets with dogecoin being one of the best performers of 2021
     * If you can't beat them, join them
     * 
     * It's the most transparent and fairly distributed system, ever. It also gives the possibility
     * for anyone to plug into the system. The protocol could act as an marketplace for NFTs and MEME tokens or as an OTC dealer.
     * 
     * The goal was to create something that would increase in value, ended up with something truly innovative
     * There is nothing like it and it very well might be one of the biggest opportunities in cryptocurrencies, ever
     * It is the perfect altcoin that i wanted to own, but didn't exist.
     * It truly is the culmination of 10 years of cryptocurrency innovation and market psychology
     * It creates the best possible system into things that we can not foresee in advance
     * Anything that has been proven to work, has been integrated into XVMC. There should be no shame in adopting great ideas.
     * 
     * The code can be copied, but the model is impossible to replicate. Many will try, all will fail.
     * 
     * The immutability and decentralization will be fully enforced after November 8
     * Most of the functions can only be called after that date
     * The goal is to have YOU, the developers act as auditors, to report the bugs and propose potential improvements
     * There is little to nothing to be gained from malicious act, but you can get rewarded for participating
     * An official security audit might be available by November 8
     * Designed to grow as a decentralized network without any early investors. Everyone gets an equal chance.
     * 
     * https://macncheese.finance/
    */

    
contract XVMCgovernor {
    using SafeERC20 for IERC20;
    uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    //masterchef address
    address public immutable masterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
    
    address public immutable consensusContract = 0xF3E3847cdDB08F261F55eF7B54c2243cd002762d;
    address public immutable fibonacceningContract = 0xac62d9bBF6Aeef74d9ed6022C36876e64085a8b5;
    address public immutable raContract = 0x195e32eb3Abd03784C3fab10395E7c56884287b5;
    address public immutable farmContract = 0x238f66A090EB82c2e571fDC17f663E2D189bc3D8; //for setpool
    address public immutable basicContract = 0x1DCF34776f1AeFCdafBBf0aeB5293641638390Cf; //setCallfee
    
    //Addresses for treasuryWallet and NFT wallet
    address public treasuryWallet = 0xaFd9aeCB4227c9d266FAa42A9cb64eba082e786c;
    address public nftWallet = 0x347D99846DF5e7e0b463a21a52780561b08eEB46;
    
    //addresses for time-locked deposits(autocompounding pools)
    address public immutable acPool1 = 0x5E126F2d2483ce77e8c7D51ef1134e078A24849b;
    address public immutable acPool2 = 0x4d13bAD6F93E7bC48884940E66171C0987Ea8362;
    address public immutable acPool3 = 0xA54c234d231DDa3a907B22A18b494a5652B6D4f7;
    address public immutable acPool4 = 0x6ce6D8015BcefcF80FFb04E21965dd011FFd392c;
    address public immutable acPool5 = 0xf79b7cc3c36C150FBF6327be5Df3eE358453d749;
    address public immutable acPool6 = 0x9e24A3Fcc61f24b899be12bBdB4cB1063f3AA387;
    
    //addresses for DummyTokens that are backed 1:1 to the real token for the respective acPool
    address public immutable token1 = 0x722db5754b3de64dE52818d4F33cEF80104704BB;
    address public immutable token2 = 0x05B12dC8f960Bd74cEA911Cf00718b4a3084BF39;
    address public immutable token3 = 0x1C6b33baD63A95FB382d25d7CD75ad16a780566f;
    address public immutable token4 = 0xE01283eAe790A9ae7F1d95D4fA0E50Ee0b0a3701;
    address public immutable token5 = 0x51Aaec949275481820376DE9624fF24ef450749a;
    address public immutable token6 = 0x7ccA17Dc6dDE2e1AF159e7Da4d33AceB5DECF26e;
        
    //pool ID in the masterchef for respective Pool address and dummy token
    uint256 public immutable acPool1ID = 20;
    uint256 public immutable acPool2ID = 21;
    uint256 public immutable acPool3ID = 23;
    uint256 public immutable acPool4ID = 24;
    uint256 public immutable acPool5ID = 27;
    uint256 public immutable acPool6ID = 26;
    
    uint256 costToVote = 10000 * 1e18;  //all proposals are valid unless rejected. This is a minimum to prevent spam
    uint256 delayBeforeEnforce = 3 days; //minimum number of TIME between when costToVote is proposed and executed

    uint256 maximumVoteTokens; // maximum tokens that can be voted with to prevent tyrany
    
    //fibonaccening event can be scheduled once minimum threshold of tokens have been collected
    uint256 thresholdFibonaccening = 5000000000000000000000000; 
    
    //delays for Fibonnaccening Events
    uint256 immutable minDelay = 1 days; // has to be called minimum 1 day in advance
    uint256 immutable maxDelay = 31 days; //1month.. is that good? i think yes
    uint256 currentDelay = 3 days;
    
    uint256 rewardPerBlockPriorFibonaccening; //remembers the last reward used
    bool eventFibonacceningActive; // prevent some functions if event is active ..threshold and durations for fibonaccening
    
    uint256 blocks100PerSecond = 250; //x100 blocks/second
    uint256 durationForCalculation= 12 hours; //period used to calculate block time
    uint256 lastBlockHeight; //block number when counting is activated
    uint256 recordTimeStart; //timestamp when counting is activated
    bool countingBlocks;

    uint256 totalFibonacciEventsAfterGrand; //used for rebalancing inflation after Grand Fib
    
    uint256 newGovernorRequestBlock;
    address eligibleNewGovernor; //used for changing smart contract
    
    bool changeGovernorActivated;
    
    bool changeGovernorEnforced;
	
	bool fibonacciDelayed; //used to delay fibonaccening events through vote


    event SetInflation(uint256 rewardPerBlock);
    
    event TransferOwner(address newOwner, uint256 timestamp);
    
    event EnforceGovernor(address _newGovernor, address indexed enforcer);
    
       
    modifier onlyTrustee {
      require(msg.sender == 0x9c36BC6b8C107014B6E86536D809b74C6fdB8cE9);
      _;
    }
    
    modifier whenReady() {
      require(block.timestamp > 1636384802, "after 8 nov");
      _;
    }

    
    /**
     * Updates circulating supply and maximum vote token variables
     */
    function updateMaximumVotetokens() external whenReady {
        maximumVoteTokens = getTotalSupply() * 5 / 10000;
    }
    

    /**
     * Calculates average block time
     * No decimals so we keep track of "100blocks" per second
     */
    function startCountingBlocks() external whenReady {
        require(!countingBlocks, "already counting blocks");
        countingBlocks = true;
        lastBlockHeight = block.number;
        recordTimeStart = block.timestamp;
    } 
    function calculateAverageBlockTime() external whenReady {
        require(countingBlocks && (recordTimeStart + durationForCalculation) <= block.timestamp);
        blocks100PerSecond = 100 * (block.number - lastBlockHeight) / (block.timestamp - recordTimeStart);
        countingBlocks = false;
    }
    
    /**
     * Return total(circulating) supply.
     * Deducts balance of tokens in this smart contract and tokens in dead address
    */
    function getTotalSupply() private view returns(uint256) {
        return IERC20(token).totalSupply() - IERC20(token).balanceOf(address(this)) - IERC20(token).balanceOf(deadAddress);
    }
    
    /**
     * Mass equivalent to massUpdatePools in masterchef, but only for relevant pools
    */
    function updateAllPools() external {
        IMasterChef(masterchef).updatePool(0);
    	IMasterChef(masterchef).updatePool(1); 
    	IMasterChef(masterchef).updatePool(11); 
        IMasterChef(masterchef).updatePool(acPool1ID);
    	IMasterChef(masterchef).updatePool(acPool2ID); 
    	IMasterChef(masterchef).updatePool(acPool3ID); 
    	IMasterChef(masterchef).updatePool(acPool4ID); 
    	IMasterChef(masterchef).updatePool(acPool5ID); 
    	IMasterChef(masterchef).updatePool(acPool6ID); 
    }
    
     /**
     * Rebalances farms in masterchef
     */
    function rebalanceFarms() external {
    	IMasterChef(masterchef).updatePool(0);
    	IMasterChef(masterchef).updatePool(1); 
    	IMasterChef(masterchef).updatePool(11); 
    }
   
     /**
     * Rebalances Pools and allocates rewards in masterchef
     * Pools with higher time-lock must always pay higher rewards in relative terms
     * Eg. for 1XVMC staked in the pool 6, you should always be receiving
     * 50% more rewards compared to staking in pool 4
     * 
     * QUESTION: should we create a modifier to prevent rebalancing during inflation events?
     * Longer pools compound on their interests and earn much faster?
     * On the other hand it could also be an incentive to hop to pools with longer lockup
	 * Could also make it changeable through voting
     */
    function rebalancePools() external {
    	//get balance for each pool. Our dummyTokens are backed 1:1 to XVMC
    	uint256 balancePool1 = IERC20(token1).totalSupply();
    	uint256 balancePool2 = IERC20(token2).totalSupply();
    	uint256 balancePool3 = IERC20(token3).totalSupply();
    	uint256 balancePool4 = IERC20(token4).totalSupply();
    	uint256 balancePool5 = IERC20(token5).totalSupply();
    	uint256 balancePool6 = IERC20(token6).totalSupply();
    	
   	    uint256 total = balancePool1 + balancePool2 + balancePool3 + balancePool4 + balancePool5 + balancePool6;
    	
		//this PROBABLY needs to get fixed, still
		//I AM PRETTY SURE THIS IS WRONG
    	IMasterChef(masterchef).set(acPool1ID, (balancePool1 * 20000 / total), 0, false);
    	IMasterChef(masterchef).set(acPool2ID, (balancePool2 * 30000 / total), 0, false);
    	IMasterChef(masterchef).set(acPool3ID, (balancePool3 * 45000 / total), 0, false);
    	IMasterChef(masterchef).set(acPool4ID, (balancePool4 * 100000 / total), 0, false);
    	IMasterChef(masterchef).set(acPool5ID, (balancePool5 * 130000 / total), 0, false);
    	IMasterChef(masterchef).set(acPool6ID, (balancePool6 * 150000 / total), 0, false); 
    	
    	//equivalent to massUpdatePools() in masterchef, but we loop just through relevant pools
    	IMasterChef(masterchef).updatePool(acPool1ID);
    	IMasterChef(masterchef).updatePool(acPool2ID); 
    	IMasterChef(masterchef).updatePool(acPool3ID); 
    	IMasterChef(masterchef).updatePool(acPool4ID); 
    	IMasterChef(masterchef).updatePool(acPool5ID); 
    	IMasterChef(masterchef).updatePool(acPool6ID); 
    }
    

    /**
     * Sets inflation in Masterchef
     */
    function setInflation(uint256 rewardPerBlock) external {
        require(
            msg.sender == consensusContract || msg.sender == fibonacceningContract || msg.sender == raContract);
    	IMasterChef(masterchef).updateEmissionRate(rewardPerBlock);
        rewardPerBlockPriorFibonaccening = rewardPerBlock; //remember last inflation
        
        emit SetInflation(rewardPerBlock);
    }
    
    
    function enforceGovernor() external whenReady {
        require(msg.sender == consensusContract);
        changeGovernorEnforced = true;

        IMasterChef(masterchef).transferOwnership(eligibleNewGovernor); //transfer masterchef ownership
        IMasterChef(masterchef).setFeeAddress(eligibleNewGovernor);
        IMasterChef(masterchef).dev(eligibleNewGovernor);
		
		IXVMCtreasury(treasuryWallet).setOwner(eligibleNewGovernor); //transfer treasuryWallet ownership
		
        IwalletForNFT(nftWallet).setOwner(eligibleNewGovernor); //transfer NFT wallet ownership
		
		IERC20(token).safeTransfer(eligibleNewGovernor, IERC20(token).balanceOf(address(this))); // send collected XVMC tokens to new governor

        IacPool(acPool1).setTreasury(eligibleNewGovernor); //set treasury and governance to new governor
        IacPool(acPool2).setTreasury(eligibleNewGovernor);
        IacPool(acPool3).setTreasury(eligibleNewGovernor);
        IacPool(acPool4).setTreasury(eligibleNewGovernor);
        IacPool(acPool5).setTreasury(eligibleNewGovernor);
        IacPool(acPool6).setTreasury(eligibleNewGovernor);

		IacPool(acPool1).setAdmin(eligibleNewGovernor); //set admin of AC pools to new contract
        IacPool(acPool2).setAdmin(eligibleNewGovernor);
        IacPool(acPool3).setAdmin(eligibleNewGovernor);
        IacPool(acPool4).setAdmin(eligibleNewGovernor);
        IacPool(acPool5).setAdmin(eligibleNewGovernor);
        IacPool(acPool6).setAdmin(eligibleNewGovernor);
        
      emit EnforceGovernor(eligibleNewGovernor, msg.sender);
    }
    function setNewGovernor(address beneficiary) external whenReady {
        require(msg.sender == consensusContract);
        newGovernorRequestBlock = block.number;
        eligibleNewGovernor = beneficiary;
        changeGovernorActivated = true;
    }
	
	function treasuryRequest(address _tokenAddr, address _recipient, uint256 _amountToSend) external {
		require(msg.sender == consensusContract);
		IXVMCtreasury(treasuryWallet).requestWithdrawToken(
			_tokenAddr, _recipient, _amountToSend
		);
	}
	
	function setDurationForCalculation(uint256 _newDuration) external {
	    require(msg.sender == farmContract);
	    durationForCalculation = _newDuration;
	}
	
	function delayFibonacci(bool _arg) external {
	    require(msg.sender == consensusContract || msg.sender == fibonacceningContract);
	    fibonacciDelayed = _arg;
	}

	function setPool(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external {
	    require(msg.sender == consensusContract);
	    IMasterChef(masterchef).set(_pid, _allocPoint, _depositFeeBP, _withUpdate);
	}
	
	function setThresholdFibonaccening(uint256 newThreshold) external {
	    require(msg.sender == fibonacceningContract);
	    thresholdFibonaccening = newThreshold;
	}
	
	function setCallFee(address _acPool, uint256 _newCallFee, uint256 _newCallFeeWithBonus) external {
	    require(msg.sender == basicContract);
	    IacPool(_acPool).setCallFee(_newCallFee, _newCallFeeWithBonus);
	}
	    
    /**
     * Calls execute function after delay has been passed
	 * It's a function in treasury wallet contract that executes the requested withdrawal
	 * After time lock passes
	 * Withdraw ID is tied to the transaction in that smart contract
	 * Arguably unncessary considering we could integrate the delay here, but,...
     */
    function executeWithdraw(uint256 withdrawID) external whenReady {
    	IXVMCtreasury(treasuryWallet).executeWithdrawal(withdrawID);
    }
	
    /**
     * Transfers collected DOGE2 into the treasury wallet
     */
    function transferCollectedFees() external whenReady  {
        require(msg.sender == tx.origin);
		
		address doge2 = 0x85eCa3374D7FEA1eCd79BB4D875CF9E220e9fbDB;
		
        uint256 amount = IERC20(doge2).balanceOf(address(this));
        
        IERC20(doge2).safeTransfer(treasuryWallet, (amount * 9995/10000));
        IERC20(doge2).safeTransfer(payable(msg.sender), (IERC20(doge2).balanceOf(address(this))));
    }

    /**
     * Grace period for potential improvements lasts until 8th of Nov
     * Afterwards the contract becomes 100% decentralized and immutable
     */
    function gracePeriodTransferOwner(address newOwnerAddress) external onlyTrustee {
    	require(block.timestamp < 1636384802, "Contract is immutable after Nov 8");
        require(!changeGovernorActivated, "already activated");
        changeGovernorActivated = true;
        newGovernorRequestBlock = block.number;
        eligibleNewGovernor = newOwnerAddress;
        
        emit TransferOwner(eligibleNewGovernor, newGovernorRequestBlock); //explicit
    }
    
    /**
     * Timelock-equivalent (require delay of roughly 24hours before transferring ownership of masterchef)
     */
    function afterDelayOwnership() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 6942 < block.number, "Pending timelock");
        
        IMasterChef(masterchef).transferOwnership(eligibleNewGovernor);
        IMasterChef(masterchef).setFeeAddress(eligibleNewGovernor);
        IMasterChef(masterchef).dev(eligibleNewGovernor);
    }
    /**
     * Timelock-equivalent (require delay of roughly 24hours before transferring ownership of masterchef)
     */
    function transferTreasuryAndAdmin() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 6942 < block.number, "Pending timelock");
        
        IacPool(acPool1).setTreasury(eligibleNewGovernor); 
        IacPool(acPool2).setTreasury(eligibleNewGovernor);
        IacPool(acPool3).setTreasury(eligibleNewGovernor);
        IacPool(acPool4).setTreasury(eligibleNewGovernor);
        IacPool(acPool5).setTreasury(eligibleNewGovernor);
        IacPool(acPool6).setTreasury(eligibleNewGovernor);
        
        IacPool(acPool1).setAdmin(eligibleNewGovernor);
        IacPool(acPool2).setAdmin(eligibleNewGovernor);
        IacPool(acPool3).setAdmin(eligibleNewGovernor);
        IacPool(acPool4).setAdmin(eligibleNewGovernor);
        IacPool(acPool5).setAdmin(eligibleNewGovernor);
        IacPool(acPool6).setAdmin(eligibleNewGovernor);
    }

    /**
     * Transfer Treasury ownership (Meme tokens) to the new contract
     */
    function transferTreasuryOwnership() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 6942 < block.number, "Pending timelock");
   
        IXVMCtreasury(treasuryWallet).setOwner(eligibleNewGovernor);
        IwalletForNFT(nftWallet).setOwner(eligibleNewGovernor);
    }
    
    /**
     * Transfer tokens collected(XVMC) in this contract to the new owner(contract)
     */
    function transferXVMC() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 6942 < block.number, "Pending timelock");
        
        IERC20(token).safeTransfer(eligibleNewGovernor, IERC20(token).balanceOf(address(this)));
    }
}