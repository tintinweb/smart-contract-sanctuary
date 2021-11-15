// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "./libs/Ownable.sol";
import "./interfaces/IMoneyPot.sol";

/*
* This contract is used to collect sNova stacking dividends from fee (like swap, deposit on pools or farms)
*/
contract ShibaMoneyPot is Ownable, IMoneyPot {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;


    struct TokenPot {
        uint256 tokenAmount; // Total amount distributing over 1 cycle (updateMoneyPotPeriodNbBlocks)
        uint256 accTokenPerShare; // Amount of dividends per Share
        uint256 lastRewardBlock; // last data update
        uint256 lastUpdateTokenPotBlocks; // last cycle update for this token
    }

    struct UserInfo {
        uint256 rewardDept;
        uint256 pending;
    }

    IBEP20 public sNova;

    uint256 public updateMoneyPotPeriodNbBlocks;
    uint256 public lastUpdateMoneyPotBlocks;
    uint256 public startBlock; // Start block for dividends distribution (first cycle the current money pot will be empty)

    // _token => user => rewardsDebt / pending
    mapping(address => mapping (address => UserInfo)) public sNovaHoldersRewardsInfo;
    // user => LastSNovaBalanceSaved
    mapping (address => uint256) public sNovaHoldersInfo;

    address[] public registeredToken; // List of all token that will be distributed as dividends. Should never be too weight !
    mapping (address => bool )  public tokenInitialized; // List of token already added to registeredToken

    // addressWithoutReward is a map containing each address which are not going to get rewards
    // At least, it will include the masterChef address as masterChef minting continuously sNova for rewards on Nova pair pool.
    // We can add later LP contract if someone initialized sNova LP
    // Those contracts are included as holders on sNova
    // All dividends attributed to those addresses are going to be added to the "reserveTokenAmount"
    mapping (address => bool) addressWithoutReward;
    // address of the feeManager which is allow to add dividends to the pendingTokenPot
    address public feeManager;

    mapping (address => TokenPot) private _distributedMoneyPot; // Current MoneyPot
    mapping (address => uint256 ) public pendingTokenAmount; // Pending amount of each dividends token that will be distributed in next cycle
    mapping (address => uint256) public reserveTokenAmount; // Bonus which is used to add more dividends in the pendingTokenAmount

    uint256 public lastSNovaSupply; // Cache the last totalSupply of sNova

    constructor (IBEP20 _sNova, address _feeManager, address _masterShiba, uint256 _startBlock, uint256 _initialUpdateMoneyPotPeriodNbBlocks) public{
        updateMoneyPotPeriodNbBlocks = _initialUpdateMoneyPotPeriodNbBlocks;
        startBlock = _startBlock;
        lastUpdateMoneyPotBlocks = _startBlock;
        sNova = _sNova;
        addressWithoutReward[_masterShiba] = true;
        feeManager = _feeManager;
    }

    function getRegisteredToken(uint256 index) external virtual override view returns (address){
        return registeredToken[index];
    }

    function distributedMoneyPot(address _token) external view returns (uint256 tokenAmount, uint256 accTokenPerShare, uint256 lastRewardBlock ){
        return (
            _distributedMoneyPot[_token].tokenAmount,
            _distributedMoneyPot[_token].accTokenPerShare,
            _distributedMoneyPot[_token].lastRewardBlock
        );
    }

    function isDividendsToken(address _tokenAddr) external virtual override view returns (bool){
        return tokenInitialized[_tokenAddr];
    }


    function updateAddressWithoutReward(address _contract, bool _unattributeDividends) external onlyOwner {
        addressWithoutReward[_contract] = _unattributeDividends;
    }

    function updateFeeManager(address _feeManager) external onlyOwner{
        // Allow us to update the feeManager contract => Can be upgraded if needed
        feeManager = _feeManager;
    }

    function getRegisteredTokenLength() external virtual override view returns (uint256){
        return registeredToken.length;
    }

    function getTokenAmountPotFromMoneyPot(address _token) external view returns (uint256 tokenAmount){
        return _distributedMoneyPot[_token].tokenAmount;
    }

    // Amount of dividends in a specific token distributed at each block during the current cycle (=updateMoneyPotPeriodNbBlocks)
    function tokenPerBlock(address _token) external view returns (uint256){
        return _distributedMoneyPot[_token].tokenAmount.div(updateMoneyPotPeriodNbBlocks);
    }

    function massUpdateMoneyPot() public {
        uint256 length = registeredToken.length;
        for (uint256 index = 0; index < length; ++index) {
            _updateTokenPot(registeredToken[index]);
        }
    }

    function updateCurrentMoneyPot(address _token) external{
        _updateTokenPot(_token);
    }

    function getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256){
        if(_from >= _to){
            return 0;
        }
        return _to.sub(_from);
    }

    /*
    Update current dividends for specific token
    */
    function _updateTokenPot(address _token) internal {
        TokenPot storage tokenPot = _distributedMoneyPot[_token];
        if (block.number <= tokenPot.lastRewardBlock) {
            return;
        }

        if (lastSNovaSupply == 0) {
            tokenPot.lastRewardBlock = block.number;
            return;
        }

        if (block.number >= tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks)){
            if(tokenPot.tokenAmount > 0){
                uint256 multiplier = getMultiplier(tokenPot.lastRewardBlock, tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks));
                uint256 tokenRewardsPerBlock = tokenPot.tokenAmount.div(updateMoneyPotPeriodNbBlocks);
                tokenPot.accTokenPerShare = tokenPot.accTokenPerShare.add(tokenRewardsPerBlock.mul(multiplier).mul(1e12).div(lastSNovaSupply));
            }
            tokenPot.tokenAmount = pendingTokenAmount[_token];
            pendingTokenAmount[_token] = 0;
            tokenPot.lastRewardBlock = tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks);
            tokenPot.lastUpdateTokenPotBlocks = tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks);
            lastUpdateMoneyPotBlocks = tokenPot.lastUpdateTokenPotBlocks;

            if (block.number >= tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks)){
                // If something bad happen in blockchain and moneyPot aren't able to be updated since
                // return here, will allow us to re-call updatePool manually, instead of directly doing it recursively here
                // which can cause too much gas error and so break all the MP contract
                return;
            }
        }
        if(tokenPot.tokenAmount > 0){
            uint256 multiplier = getMultiplier(tokenPot.lastRewardBlock, block.number);
            uint256 tokenRewardsPerBlock = tokenPot.tokenAmount.div(updateMoneyPotPeriodNbBlocks);
            tokenPot.accTokenPerShare = tokenPot.accTokenPerShare.add(tokenRewardsPerBlock.mul(multiplier).mul(1e12).div(lastSNovaSupply));
        }

        tokenPot.lastRewardBlock = block.number;

        if (block.number >= tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks)){
            lastUpdateMoneyPotBlocks = tokenPot.lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks);
        }
    }

    /*
    Used by front-end to display user's pending rewards that he can harvest
    */
    function pendingTokenRewardsAmount(address _token, address _user) external view returns (uint256){

        if(lastSNovaSupply == 0){
            return 0;
        }

        uint256 accTokenPerShare = _distributedMoneyPot[_token].accTokenPerShare;
        uint256 tokenReward = _distributedMoneyPot[_token].tokenAmount.div(updateMoneyPotPeriodNbBlocks);
        uint256 lastRewardBlock = _distributedMoneyPot[_token].lastRewardBlock;
        uint256 lastUpdateTokenPotBlocks = _distributedMoneyPot[_token].lastUpdateTokenPotBlocks;
        if (block.number >= lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks)){
            accTokenPerShare = (accTokenPerShare.add(
                    tokenReward.mul(getMultiplier(lastRewardBlock, lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks))
                ).mul(1e12).div(lastSNovaSupply)));
            lastRewardBlock = lastUpdateTokenPotBlocks.add(updateMoneyPotPeriodNbBlocks);
            tokenReward = pendingTokenAmount[_token].div(updateMoneyPotPeriodNbBlocks);
        }

        if (block.number > lastRewardBlock && lastSNovaSupply != 0 && tokenReward > 0) {
            accTokenPerShare = accTokenPerShare.add(
                    tokenReward.mul(getMultiplier(lastRewardBlock, block.number)
                ).mul(1e12).div(lastSNovaSupply));
        }
        return (sNova.balanceOf(_user).mul(accTokenPerShare).div(1e12).sub(sNovaHoldersRewardsInfo[_token][_user].rewardDept))
                    .add(sNovaHoldersRewardsInfo[_token][_user].pending);
    }


    /*
    Update tokenPot, user's sNova balance (cache) and pending dividends
    */
    function updateSNovaHolder(address _sNovaHolder) external virtual override {
        uint256 holderPreviousSNovaAmount = sNovaHoldersInfo[_sNovaHolder];
        uint256 holderBalance = sNova.balanceOf(_sNovaHolder);
        uint256 length = registeredToken.length;
        for (uint256 index = 0; index < length; ++index) {
            _updateTokenPot(registeredToken[index]);
            TokenPot storage tokenPot = _distributedMoneyPot[registeredToken[index]];
            if(holderPreviousSNovaAmount > 0 && tokenPot.accTokenPerShare > 0){
                uint256 pending = holderPreviousSNovaAmount.mul(tokenPot.accTokenPerShare).div(1e12).sub(sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].rewardDept);
                if(pending > 0) {
                    if (addressWithoutReward[_sNovaHolder]) {
                        if(sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].pending > 0){
                            pending = pending.add(sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].pending);
                            sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].pending = 0;
                        }
                        reserveTokenAmount[registeredToken[index]] = reserveTokenAmount[registeredToken[index]].add(pending);
                    }
                    else {
                        sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].pending = sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].pending.add(pending);
                    }
                }
            }
            sNovaHoldersRewardsInfo[registeredToken[index]][_sNovaHolder].rewardDept = holderBalance.mul(tokenPot.accTokenPerShare).div(1e12);
        }
        if (holderPreviousSNovaAmount > 0){
            lastSNovaSupply = lastSNovaSupply.sub(holderPreviousSNovaAmount);
        }
        lastSNovaSupply = lastSNovaSupply.add(holderBalance);
        sNovaHoldersInfo[_sNovaHolder] = holderBalance;
    }

    function harvestRewards(address _sNovaHolder) external {
        uint256 length = registeredToken.length;

        for (uint256 index = 0; index < length; ++index) {
            harvestReward(_sNovaHolder, registeredToken[index]);
        }
    }

    /*
    * Allow user to harvest their pending dividends
    */
    function harvestReward(address _sNovaHolder, address _token) public {
        uint256 holderBalance = sNovaHoldersInfo[_sNovaHolder];
        _updateTokenPot(_token);
        TokenPot storage tokenPot = _distributedMoneyPot[_token];
        if(holderBalance > 0 && tokenPot.accTokenPerShare > 0){
            uint256 pending = holderBalance.mul(tokenPot.accTokenPerShare).div(1e12).sub(sNovaHoldersRewardsInfo[_token][_sNovaHolder].rewardDept);
            if(pending > 0) {
                if (addressWithoutReward[_sNovaHolder]) {
                        if(sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending > 0){
                            pending = pending.add(sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending);
                            sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending = 0;
                        }
                        reserveTokenAmount[_token] = reserveTokenAmount[_token].add(pending);
                }
                else {
                    sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending = sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending.add(pending);
                }
            }
        }
        if ( sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending > 0 ){
            safeTokenTransfer(_token, _sNovaHolder, sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending);
            sNovaHoldersRewardsInfo[_token][_sNovaHolder].pending = 0;
        }
        sNovaHoldersRewardsInfo[_token][_sNovaHolder].rewardDept = holderBalance.mul(tokenPot.accTokenPerShare).div(1e12);
    }

    /*
    * Used by feeManager contract to deposit rewards (collected from many sources)
    */
    function depositRewards(address _token, uint256 _amount) external virtual override{
        require(msg.sender == feeManager);
        massUpdateMoneyPot();

        IBEP20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if(block.number < startBlock){
            reserveTokenAmount[_token] = reserveTokenAmount[_token].add(_amount);
        }
        else {
            pendingTokenAmount[_token] = pendingTokenAmount[_token].add(_amount);
        }
    }

    /*
    * Used by dev to deposit bonus rewards that can be added to pending pot at any time
    */
    function depositBonusRewards(address _token, uint256 _amount) external onlyOwner{
        IBEP20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        reserveTokenAmount[_token] = reserveTokenAmount[_token].add(_amount);
    }

    /*
    * Allow token address to be distributed as dividends to sNova holder
    */
    function addTokenToRewards(address _token) external onlyOwner{
        if (!tokenInitialized[_token]){
            registeredToken.push(_token);
            _distributedMoneyPot[_token].lastRewardBlock = lastUpdateMoneyPotBlocks > block.number ? lastUpdateMoneyPotBlocks : lastUpdateMoneyPotBlocks.add(updateMoneyPotPeriodNbBlocks);
            _distributedMoneyPot[_token].accTokenPerShare = 0;
            _distributedMoneyPot[_token].tokenAmount = 0;
            _distributedMoneyPot[_token].lastUpdateTokenPotBlocks = _distributedMoneyPot[_token].lastRewardBlock;
            tokenInitialized[_token] = true;
        }
    }

    /*
    Remove token address to be distributed as dividends to sNova holder
    */
    function removeTokenToRewards(address _token) external onlyOwner{
        require(_distributedMoneyPot[_token].tokenAmount == 0, "cannot remove before end of distribution");
        if (tokenInitialized[_token]){
            uint256 length = registeredToken.length;
            uint256 indexToRemove = length; // If token not found web do not try to remove bad index
            for (uint256 index = 0; index < length; ++index) {
                if(registeredToken[index] == _token){
                    indexToRemove = index;
                    break;
                }
            }
            if(indexToRemove < length){ // Should never be false.. Or something wrong happened
                registeredToken[indexToRemove] = registeredToken[registeredToken.length-1];
                registeredToken.pop();
            }
            tokenInitialized[_token] = false;
            return;
        }
    }

    /*
     Used by front-end to get the next moneyPot cycle update
     */
    function nextMoneyPotUpdateBlock() external view returns (uint256){
        return lastUpdateMoneyPotBlocks.add(updateMoneyPotPeriodNbBlocks);
    }

    function addToPendingFromReserveTokenAmount(address _token, uint256 _amount) external onlyOwner{
        require(_amount <= reserveTokenAmount[_token], "Insufficient amount");
        reserveTokenAmount[_token] = reserveTokenAmount[_token].sub(_amount);
        pendingTokenAmount[_token] = pendingTokenAmount[_token].add(_amount);
    }


    // Safe Token transfer function, just in case if rounding error causes pool to not have enough Tokens.
    function safeTokenTransfer(address _token, address _to, uint256 _amount) internal {
        IBEP20 token = IBEP20(_token);
        uint256 tokenBal = token.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBal) {
            transferSuccess = token.transfer(_to, tokenBal);
        } else {
            transferSuccess = token.transfer(_to, _amount);
        }
        require(transferSuccess, "safeSNovaTransfer: Transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMoneyPot {
    function isDividendsToken(address _tokenAddr) external view returns (bool);
    function getRegisteredTokenLength() external view returns (uint256);
    function depositRewards(address _token, uint256 _amount) external;
    function getRegisteredToken(uint256 index) external view returns (address);
    function updateSNovaHolder(address _sNovaHolder) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import './SafeMath.sol';
import './Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

