/**
 *Submitted for verification at polygonscan.com on 2021-12-12
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
    function setAdmin(address _admin, address _treasury) external;
    function setTreasury(address _treasury) external;
	function addAndExtendStake(address _recipientAddr, uint256 _amount, uint256 _stakeID, uint256 _lockUpTokensInSeconds) external;
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
    function requestWithdraw(address _token, address _receiver, uint _value) external;
}

//can only hold NFTs for now, future upgrades could transfer/trade them too

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
     * The immutability and decentralization will be fully enforced after November 3rd December
     * Most of the functions can only be called after that date
     * The goal is to have YOU, the developers act as auditors, to report the bugs and propose potential improvements
     * There is little to nothing to be gained from malicious act, but you can get rewarded for participating
     * Designed to grow as a decentralized network without any early investors. Everyone gets an equal chance.
     * 
     * https://macncheese.finance/
    */

    
contract XVMCgovernor {
    using SafeERC20 for IERC20;
    
    struct RollBonus {
        uint256 bonusPoints;
    }
    
    uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    //masterchef address
    address public immutable masterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
    
	
    address public immutable consensusContract = 0x65671eeF95BEc99Be3729C3f25329b0f5A96c5E7;
    address public immutable fibonacceningContract = 0x486DCcdFC03B25Bddda24E53aF908D64970A63Bc;
    address public immutable raContract = 0x131DA2F8FBc014E76Fde92b49966612f497EDf14;
    address public immutable farmContract = 0x108E0e38acCadE1829809e00238fe73c9e4F1e9b; //for setpool
    address public immutable basicContract = 0xE211Ed823aD18f9658b0Df24B51b3634381892f0; //setCallfee, rolloverbonus
    
    //Addresses for treasuryWallet and NFT wallet
    address public treasuryWallet = 0xeF8470c63d4597A401993E02709847620dbd6778;
    address public nftWallet = 0xF803e35A79ea815980D1e6bbC87450D2476d2441;
    
    //addresses for time-locked deposits(autocompounding pools)
    address public immutable acPool1 = 0xD00a313cAAe665c4a828C80fF2fAb3C879f7B08B;
    address public immutable acPool2 = 0xa999A93221042e4Ecc1D002E0935C4a6c67FD242;
    address public immutable acPool3 = 0x0E6f5D3e65c0D3982275EE2238eb7452EBf8F31D;
    address public immutable acPool4 = 0x0e4f23dE638bd6032ab0146B02f82F5Da0c407aF;
    address public immutable acPool5 = 0xEa76E32F7626B3A1bdA8C2AB2C70A85A8fdebaAB;
    address public immutable acPool6 = 0xD582d1DF416F421288aa4E8E5813661E1d5b3D5f;
    
    //addresses for DummyTokens that are backed 1:1 to the real token for the respective acPool
    address public immutable token1 = 0x02c957Ff01aA3A4B36F632A0540667548938818C;
    address public immutable token2 = 0x97102d1Db432230f2AeC9049d651550a43CCc5bD;
    address public immutable token3 = 0x7b7f3E2FBc517a9A94E2F0BC3E65f8910a66511b;
    address public immutable token4 = 0x7b74CF771Be0AE35252a790875d92F5d78305c61;
    address public immutable token5 = 0x780F90E9c50369591EFC46120bF1afe4EcAd0CB9;
    address public immutable token6 = 0xC515c83F492a522EF231601A394a8CCd26612f88;
        
    //pool ID in the masterchef for respective Pool address and dummy token
    uint256 public immutable acPool1ID = 44;
    uint256 public immutable acPool2ID = 39;
    uint256 public immutable acPool3ID = 40;
    uint256 public immutable acPool4ID = 41;
    uint256 public immutable acPool5ID = 42;
    uint256 public immutable acPool6ID = 43;
    
    mapping(address => RollBonus) public rollBonus;
    //potential problem: you could migrate into the old pool, collect bonus, then for free travel back?
    //but you can't beenfit so it's okay imo
    
    uint256 costToVote = 99 * 1e18;  //all proposals are valid unless rejected. This is a minimum to prevent spam
    uint256 delayBeforeEnforce = 5 days; //minimum number of TIME between when costToVote is proposed and executed

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
	uint256 newGovernorRequestBlock2; //one for voting, one for trustee
	
    address eligibleNewGovernor; //used for changing smart contract
    address eligibleNewGovernor2;
	
    bool changeGovernorActivated;
	bool changeGovernorActivated2;
    
	
	bool fibonacciDelayed; //used to delay fibonaccening events through vote

    event SetInflation(uint256 rewardPerBlock);
    
    event TransferOwner(address newOwner, uint256 timestamp);
    
    event EnforceGovernor(address _newGovernor, address indexed enforcer);
    
    event GiveRolloverBonus(address recipient, uint256 amount, address poolInto);
    
    constructor(
        IERC20 _token
    ) {
        rollBonus[0xD00a313cAAe665c4a828C80fF2fAb3C879f7B08B].bonusPoints = 50;
        rollBonus[0xa999A93221042e4Ecc1D002E0935C4a6c67FD242].bonusPoints = 69;
        rollBonus[0x0E6f5D3e65c0D3982275EE2238eb7452EBf8F31D].bonusPoints = 82;
        rollBonus[0x0e4f23dE638bd6032ab0146B02f82F5Da0c407aF].bonusPoints = 130;
        rollBonus[0xEa76E32F7626B3A1bdA8C2AB2C70A85A8fdebaAB].bonusPoints = 150;
        rollBonus[0xD582d1DF416F421288aa4E8E5813661E1d5b3D5f].bonusPoints = 200;
        // Infinite approve
        IERC20(_token).safeApprove(address(0xD00a313cAAe665c4a828C80fF2fAb3C879f7B08B), type(uint256).max); //vaults
        IERC20(_token).safeApprove(address(0xa999A93221042e4Ecc1D002E0935C4a6c67FD242), type(uint256).max);
        IERC20(_token).safeApprove(address(0x0E6f5D3e65c0D3982275EE2238eb7452EBf8F31D), type(uint256).max);
        IERC20(_token).safeApprove(address(0x0e4f23dE638bd6032ab0146B02f82F5Da0c407aF), type(uint256).max);
        IERC20(_token).safeApprove(address(0xEa76E32F7626B3A1bdA8C2AB2C70A85A8fdebaAB), type(uint256).max);
        IERC20(_token).safeApprove(address(0xD582d1DF416F421288aa4E8E5813661E1d5b3D5f), type(uint256).max);
        IERC20(_token).safeApprove(address(0x108E0e38acCadE1829809e00238fe73c9e4F1e9b), type(uint256).max);
    }


     /**
     * System can be ran without any one party(can be upgraded through voting)
	 * It should be tested first to confirm reliability
	 * Change the governor through the process and remove admin keys
     */
    modifier onlyTrustee {
      require(block.timestamp < 1640995199, "Contract is immutable after Dec 31");
      require(msg.sender == 0x9c36BC6b8C107014B6E86536D809b74C6fdB8cE9);
      _;
    }
    

    
    /**
     * Updates circulating supply and maximum vote token variables
     */
    function updateMaximumVotetokens() external {
        maximumVoteTokens = getTotalSupply() * 5 / 10000;
    }
    

    /**
     * Calculates average block time
     * No decimals so we keep track of "100blocks" per second
     */
    function startCountingBlocks() external {
        require(!countingBlocks, "already counting blocks");
        countingBlocks = true;
        lastBlockHeight = block.number;
        recordTimeStart = block.timestamp;
    } 
    function calculateAverageBlockTime() external {
        require(countingBlocks && (recordTimeStart + durationForCalculation) <= block.timestamp);
        blocks100PerSecond = 100 * (block.number - lastBlockHeight) / (block.timestamp - recordTimeStart);
        countingBlocks = false;
    }
    
    function getRollBonus(address _bonusForPool) external view returns (uint256) {
        return rollBonus[_bonusForPool].bonusPoints;
    }
    
    /**
     * Return total(circulating) supply.
     * Deducts balance of tokens in dead address
    */
    function getTotalSupply() public view returns(uint256) {
        return IERC20(token).totalSupply() - IERC20(token).balanceOf(deadAddress);
    }
    
    /**
     * Mass equivalent to massUpdatePools in masterchef, but only for relevant pools
    */
    function updateAllPools() external {
        IMasterChef(masterchef).updatePool(0); // XVMC-USDC and XVMC-wmatic
    	IMasterChef(masterchef).updatePool(1); 
    	IMasterChef(masterchef).updatePool(11); //meme pool 11,34,35
    	IMasterChef(masterchef).updatePool(34);
    	IMasterChef(masterchef).updatePool(35);
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
     * Mechanism, where the governor gives the bonus 
     * to user for extending(re-commiting) their stake
     * tldr; sends the gift deposit, which resets the timer
     * the pool is responsbile for calculating the bonus
     */
    function stakeRolloverBonus(address _toAddress, address _depositToPool, uint256 _bonusToPay, uint256 _stakeID) external {
        require(
            msg.sender == acPool1 || msg.sender == acPool2 || msg.sender == acPool3 ||
            msg.sender == acPool4 || msg.sender == acPool5 || msg.sender == acPool6);
        
        IacPool(_depositToPool).addAndExtendStake(_toAddress, _bonusToPay, _stakeID, 0);
        
        emit GiveRolloverBonus(_toAddress, _bonusToPay, _depositToPool);
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
    
    
    function enforceGovernor() external {
        require(msg.sender == consensusContract);

        IMasterChef(masterchef).transferOwnership(eligibleNewGovernor); //transfer masterchef ownership
        IMasterChef(masterchef).setFeeAddress(eligibleNewGovernor);
        IMasterChef(masterchef).dev(eligibleNewGovernor);
		
		IERC20(token).safeTransfer(eligibleNewGovernor, IERC20(token).balanceOf(address(this))); // send collected XVMC tokens to new governor
        
      emit EnforceGovernor(eligibleNewGovernor, msg.sender);
    }
	
    function setNewGovernor(address beneficiary) external {
        require(msg.sender == consensusContract);
        newGovernorRequestBlock = block.number;
        eligibleNewGovernor = beneficiary;
        if(!changeGovernorActivated) {
            changeGovernorActivated = true;
        }
    }

	function treasuryRequest(address _tokenAddr, address _recipient, uint256 _amountToSend) external {
		require(msg.sender == consensusContract);
		IXVMCtreasury(treasuryWallet).requestWithdraw(
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
	    require(msg.sender == farmContract);
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
	
	function updateCostToVote(uint256 newCostToVote) external {
	    require(msg.sender == basicContract);
	    costToVote = newCostToVote;
	}
	
	function updateRolloverBonus(address _forPool, uint256 _bonus) external {
	    require(msg.sender == basicContract);
	    rollBonus[_forPool].bonusPoints = _bonus;
	}
	    
	
    /**
     * Transfers collected fees into treasury wallet(but not XVMC...for now)
     */
    function transferCollectedFees(address _tokenContract) external {
        require(msg.sender == tx.origin);
		require(_tokenContract != token, "not XVMC!");
		
        uint256 amount = IERC20(_tokenContract).balanceOf(address(this));
        
        IERC20(_tokenContract).safeTransfer(treasuryWallet, amount);
    }

    /**
     * Decentralized voting should be tested, and admin keys removed ASAP
	 * If the governance is not working as intended, trustee can fix it up
     */
    function gracePeriodTransferOwner(address newOwnerAddress) external onlyTrustee {
        require(!changeGovernorActivated2, "already activated");
        changeGovernorActivated2 = true;
        newGovernorRequestBlock2 = block.number;
        eligibleNewGovernor2 = newOwnerAddress;
        
        emit TransferOwner(eligibleNewGovernor2, newGovernorRequestBlock2); //explicit
    }
    
    /**
     * Timelock-equivalent (require delay of roughly 48hours before transferring ownership of masterchef)
     */
    function afterDelayOwnership() external onlyTrustee {
        require(changeGovernorActivated2, "grace transfer not requested");
        if(block.timestamp > 1639353572) {
			require(newGovernorRequestBlock2 + 69420 < block.number, "Pending timelock");
		} else {
            //in case something needs to be modified(farm&meme pool reward reduction OR inflation overall)
            require(newGovernorRequestBlock2 + 690 < block.number, "Pending timelock");
        }
        
        IMasterChef(masterchef).transferOwnership(eligibleNewGovernor2);
        IMasterChef(masterchef).setFeeAddress(eligibleNewGovernor2);
        IMasterChef(masterchef).dev(eligibleNewGovernor2);
    }

    
    /**
     * Transfer tokens collected(XVMC) in this contract to the new owner(contract)
     */
    function transferXVMC() external onlyTrustee {
        require(changeGovernorActivated, "grace transfer not requested");
        require(newGovernorRequestBlock + 69420 < block.number, "Pending timelock");
        
        IERC20(token).safeTransfer(eligibleNewGovernor, IERC20(token).balanceOf(address(this)));
    }

    /**
     * Need smaller threshold to distribute free-claims, after which the limit can be raised
     */
    function initializeCostToVote() external {
        require(block.timestamp > 1639296092);
        costToVote = 5000 * 1e18;
    }
}