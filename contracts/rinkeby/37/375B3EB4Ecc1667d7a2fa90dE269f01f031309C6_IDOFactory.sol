// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IDO.sol";

contract IDOFactory is Ownable {

    address private operator;
    event IDOCreated(address indexed idoAddress);
    
    function createIDO(
        uint256[15] memory data,
        address _idoToken,
        address _staking,
        address _swapToken,
        uint256 _swapTokenPrice
    ) public ownerOrOperator returns (address) {
        IKSTStaking staking;
        IDO ido = new IDO(data, _idoToken, _staking, _swapToken);
        ido.setSwapPrice(_swapTokenPrice);
        ido.transferOwnership(msg.sender);
        staking = IKSTStaking(_staking);
        staking.addIDO(address(ido));
        emit IDOCreated(address(ido));
        return address(ido);
    }

    function setOperator(address _operator) public onlyOwner {
        require(_operator != address(0));
        operator = _operator;

    }

    modifier ownerOrOperator(){
        require(msg.sender == owner() || msg.sender == operator,"Not admin or operator");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IKSTStaking.sol";

contract IDO is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable idoToken;
    IERC20 public immutable swapToken; //any erc20 token
    IKSTStaking private immutable staking;

    uint256 public immutable swapStartDate; // swap start time
    uint256 public immutable regStartDate;
    uint256 public immutable regEndDate;
    uint256 public immutable claimStartTime;
    uint256 public immutable totalIdoTokens;
    uint256 public swapPrice; // ido token swap price --> 1 ido token == x swap token
    uint256 private constant MINTIERAMOUNT = 100 ether;
    uint256 public immutable swapTokenDecimals;
    uint256 public immutable idoTokenDecimals;
    uint256 public idoParticipants;
    address[] private t1Registrants;
    bool private priceSet;

    address private operator;
    Tier public t1;
    Tier public t2;
    Tier public t3;
    Tier public t4;
    Tier public t5;

    mapping(address => bool) public _registered;
    mapping(address => bool) public _swapped;
    mapping(address => Claimable) public claimed;
    enum Tiers {TIER1, TIER2, TIER3, TIER4, TIER5, NONE}

    struct Claimable {
        uint256 swapTokenAmount;
        uint256 idoTokenAmount;
        uint256 claimedAmount;
    }

    struct Tier {
        Tiers tier;
        uint256 totalLocked;
        uint256 totalSwapped;
        uint256 perc;
        uint256 swapStart;
        uint256 swapEnd;
        uint256 raised;
        mapping(address => uint256) participant;
        mapping(address => bool) allowedSwap;
    }

    event Registered(
        address indexed user,
        uint256 unlockTime,
        uint256 lockedBalance,
        Tiers tier
    );

    event Swapped(address indexed user, uint256 swapTokenAmount);

    event Claimed(address indexed user, uint256 idoTokenAmount);

    constructor(
        uint256[15] memory data,
        address _idoToken,
        address _staking,
        address _swapToken
    ) {
        require(_idoToken != address(0), "IDO: ido token incorrect address");
        require(_staking != address(0), "IDO: staking incorrect address");
        require(_swapToken != address(0), "IDO: swap token incorrect address");
        require(data[9] > 0, "IDO: total ido tokens not higher than 0");
        require(
            data[2] > data[1],
            "IDO: reg end date must be higher than reg start"
        );
        require(
            data[3] > data[0],
            "IDO: claim date must be higher than swap start date"
        );

        require(
            data[4].add(data[5]).add(data[6]).add(data[7]).add(data[8]) == 1000,
            "IDO: tier percentages are not correct"
        );

        swapStartDate = data[0];
        idoToken = IERC20(_idoToken);
        regStartDate = data[1];
        staking = IKSTStaking(_staking);
        regEndDate = data[2];
        swapToken = IERC20(_swapToken);
        claimStartTime = data[3];
        totalIdoTokens = data[9];
        t1.tier = Tiers.TIER1;
        t2.tier = Tiers.TIER2;
        t3.tier = Tiers.TIER3;
        t4.tier = Tiers.TIER4;
        t5.tier = Tiers.TIER5;
        t1.perc = data[4];
        t2.perc = data[5];
        t3.perc = data[6];
        t4.perc = data[7];
        t5.perc = data[8];

        uint256 dateEnd = data[0].add(data[10]);
        t1.swapStart = data[0];
        t1.swapEnd = dateEnd;
        //  t1.swapEnd = t1.swapStart.add(data[10]);

        t2.swapStart = dateEnd;
        dateEnd = dateEnd.add(data[11]);
        t2.swapEnd = dateEnd;
        // t2.swapStart = t1.swapEnd;
        // t2.swapEnd = t2.swapStart.add(data[11]);

        t3.swapStart = dateEnd;
        dateEnd = dateEnd.add(data[12]);
        t3.swapEnd = dateEnd;

        //  t3.swapStart = t2.swapEnd;
        //  t3.swapEnd = t3.swapStart.add(data[12]);

        t4.swapStart = dateEnd;
        dateEnd = dateEnd.add(data[13]);
        t4.swapEnd = dateEnd;
        // t4.swapStart = t3.swapEnd;
        // t4.swapEnd = t4.swapStart.add(data[13]);

        t5.swapStart = dateEnd;
        t5.swapEnd = dateEnd.add(data[14]);
        // t5.swapStart = t4.swapEnd;
        //  t5.swapEnd = t5.swapStart.add(data[14]);

        swapTokenDecimals = IERC20Metadata(_swapToken).decimals();
        idoTokenDecimals = IERC20Metadata(_idoToken).decimals();
    }

    /* 
    data[0] = swapStartDate -unix time in seconds when Tier1 starts with swapping
    data[1] = regStartDate - unix time in seconds when registration opens
    data[2] = regEndDate - unix time in seconds when registration closes
    data[3] = claimStartTime - unix time in seconds when IDO token claim starts
    data[4] = t1perc 10 == 1% - Tier 1 allocation of totalIdoTokens in percent. 10 is 1 %
    data[5] = t2perc 10 == 1% - Tier 2 allocation of totalIdoTokens in percent. 10 is 1 %
    data[6] = t3perc 10 == 1% - Tier 3 allocation of totalIdoTokens in percent. 10 is 1 %
    data[7] = t4perc 10 == 1% - Tier 4 allocation of totalIdoTokens in percent. 10 is 1 %
    data[8] = t5perc 10 == 1% - Tier 5 allocation of totalIdoTokens in percent. 10 is 1 %
    data[9] = totalIdoTokens - amount of IDO tokens that are for sale in wei
    data[10] = swap time duration in seconds for t1 - swap time duration for T1 in seconds
    data[11] = swap time duration in seconds for t2 - swap time duration for T2 in seconds
    data[12] = swap time duration in seconds for t3 - swap time duration for T3 in seconds
    data[13] = swap time duration in seconds for t4 - swap time duration for T4 in seconds
    data[14] = swap time duration in seconds for t5 - swap time duration for T5 in seconds
    */

    function registered(address account) external view returns (bool) {
        return _registered[account];
    }

    function addTier1Users(address[] calldata users) external ownerOrOperator {
        for (uint256 i = 0; i < users.length; i++) {
            require(_registered[users[i]], "IDO: T1 user did not register");
            t1.allowedSwap[users[i]] = true;
        }
    }

    function getTier1SelectedUser(address user) external view returns (bool) {
        return t1.allowedSwap[user];
    }

    function register() public inRegistrationWindow {
        require(!_registered[msg.sender], "IDO: Already registered");

        _registered[msg.sender] = true;
        uint256 lockedBal = getLockedBalance();
        require(
            lockedBal >= MINTIERAMOUNT,
            "IDO: Minimum registration amount not reached"
        );
        Tiers tier = getTier(lockedBal);

        if (tier == Tiers.TIER1) {
            t1.participant[msg.sender] = lockedBal;
            t1.totalLocked = t1.totalLocked.add(lockedBal);
            t1Registrants.push(msg.sender);
        } else if (tier == Tiers.TIER2) {
            t2.participant[msg.sender] = lockedBal;
            //  t2.allowedSwap[msg.sender] = true;
            t2.totalLocked = t2.totalLocked.add(lockedBal);
        } else if (tier == Tiers.TIER3) {
            t3.participant[msg.sender] = lockedBal;
            //  t3.allowedSwap[msg.sender] = true;
            t3.totalLocked = t3.totalLocked.add(lockedBal);
        } else if (tier == Tiers.TIER4) {
            t4.participant[msg.sender] = lockedBal;
            //  t4.allowedSwap[msg.sender] = true;
            t4.totalLocked = t4.totalLocked.add(lockedBal);
        } else {
            t5.participant[msg.sender] = lockedBal;
            //  t5.allowedSwap[msg.sender] = true;
            t5.totalLocked = t5.totalLocked.add(lockedBal);
        }

        staking.lock(msg.sender, claimStartTime); // locks users staked balance
        idoParticipants = idoParticipants.add(1);
        emit Registered(msg.sender, claimStartTime, lockedBal, tier);
    }

    function swapTokens() public {
        require(_registered[msg.sender], "IDO: Not registered.");
        Tiers tier = getUsersTier();

        (
            uint256 idoTokenAmount,
            uint256 swapTokenAmount,
            uint256 tierTokenAlloc,

        ) = calcSwapAmount(tier);
        if (tier == Tiers.TIER1) {
            require(
                t1.allowedSwap[msg.sender],
                "IDO: T1 not selected for swap"
            );
            require(
                idoTokenAmount.add(t1.totalSwapped) <= tierTokenAlloc,
                "IDO: T1 swap amount too big."
            );
            require(
                block.timestamp >= t1.swapStart &&
                    block.timestamp <= t1.swapEnd,
                "IDO: t1 swap start/end not time"
            );
            require(swap(swapTokenAmount), "IDO: t1 swap error.");
            t1.raised = t1.raised.add(swapTokenAmount);
            claimed[msg.sender] = Claimable(swapTokenAmount, idoTokenAmount, 0);
            t1.totalSwapped = t1.totalSwapped.add(idoTokenAmount);
        } else if (tier == Tiers.TIER2) {
            require(
                block.timestamp >= t2.swapStart &&
                    block.timestamp <= t2.swapEnd,
                "IDO: t2 swap start/end not time"
            );
            require(
                idoTokenAmount.add(t2.totalSwapped) <= tierTokenAlloc,
                "IDO: T2 swap amount too big."
            );
            require(swap(swapTokenAmount), "IDO: t2 swap error.");
            t2.raised = t2.raised.add(swapTokenAmount);
            claimed[msg.sender] = Claimable(swapTokenAmount, idoTokenAmount, 0);
            t2.totalSwapped = t2.totalSwapped.add(idoTokenAmount);
        } else if (tier == Tiers.TIER3) {
            require(
                idoTokenAmount.add(t3.totalSwapped) <= tierTokenAlloc,
                "IDO: T3 swap amount too big."
            );
            require(
                block.timestamp >= t3.swapStart &&
                    block.timestamp <= t3.swapEnd,
                "IDO: t3 swap start/end not time"
            );
            require(swap(swapTokenAmount), "IDO: t3 swap error.");
            claimed[msg.sender] = Claimable(swapTokenAmount, idoTokenAmount, 0);
            t3.raised = t3.raised.add(swapTokenAmount);
            t3.totalSwapped = t3.totalSwapped.add(idoTokenAmount);
        } else if (tier == Tiers.TIER4) {
            require(
                block.timestamp >= t4.swapStart &&
                    block.timestamp <= t4.swapEnd,
                "IDO: t4 swap start/end not time"
            );
            require(
                idoTokenAmount.add(t4.totalSwapped) <= tierTokenAlloc,
                "IDO: T4 swap amount too big."
            );
            require(swap(swapTokenAmount), "IDO: t4 swap error.");
            t4.raised = t4.raised.add(swapTokenAmount);
            claimed[msg.sender] = Claimable(swapTokenAmount, idoTokenAmount, 0);
            t4.totalSwapped = t4.totalSwapped.add(idoTokenAmount);
        } else {
            require(
                block.timestamp >= t5.swapStart &&
                    block.timestamp <= t5.swapEnd,
                "IDO: t5 swap start/end not time"
            );
            require(
                idoTokenAmount.add(t5.totalSwapped) <= tierTokenAlloc,
                "IDO: T5 swap amount too big."
            );
            require(swap(swapTokenAmount), "IDO: t5 swap error.");
            claimed[msg.sender] = Claimable(swapTokenAmount, idoTokenAmount, 0);
            t5.raised = t5.raised.add(swapTokenAmount);
            t5.totalSwapped = t5.totalSwapped.add(idoTokenAmount);
        }
    }

    function claimTokens() public {
        Claimable memory claimable = claimed[msg.sender];
        require(_swapped[msg.sender], "IDO: Did not swap");
        require(block.timestamp >= claimStartTime, "IDO: Claim start not yet.");
        require(claimable.claimedAmount == 0, "IDO: Already claimed");
        claimed[msg.sender].claimedAmount = claimable.idoTokenAmount;
        idoToken.safeTransfer(msg.sender, claimable.idoTokenAmount);
        emit Claimed(msg.sender, claimable.idoTokenAmount);
    }

    function swap(uint256 swapTokenAmount) internal returns (bool) {
        require(!_swapped[msg.sender], "IDO: Already swapped");
        _swapped[msg.sender] = true;
        swapToken.safeTransferFrom(msg.sender, address(this), swapTokenAmount); // user sends swap token to ido contract
        emit Swapped(msg.sender, swapTokenAmount);
        return true;
    }

    function getUsersTier() public view returns (Tiers) {
        uint256 lockedBal = getLockedBalance();
        Tiers tier = getTier(lockedBal);
        return tier;
    }

    function calcSwapAmount(Tiers tier)
        public
        view
        returns (
            uint256 idoTokenAmount,
            uint256 swapTokenAmount,
            uint256 tierAlloc,
            uint256 userPerc
        )
    {
        if (tier == Tiers.TIER1) {
            tierAlloc = totalIdoTokens.mul(t1.perc).div(1000);
            userPerc = t1.participant[msg.sender].mul(100000).div(
                t1.totalLocked
            );
            // userPerc = t1.totalLocked.div(t1.participant[msg.sender]).mul(100);
            // userPerc = t1.totalLocked.mul(100).div(t1.participant[msg.sender]);
            idoTokenAmount = tierAlloc.mul(userPerc).div(100000);
            swapTokenAmount = idoTokenAmount.div(swapPrice);
            // swapTokenAmount = idoTokenAmount.mul(swapPrice).div(10 ** idoTokenDecimals).mul(10 ** swapTokenDecimals);
            return (idoTokenAmount, swapTokenAmount, tierAlloc, userPerc);
        } else if (tier == Tiers.TIER2) {
            tierAlloc = totalIdoTokens.mul(t2.perc).div(1000);
            userPerc = t2.participant[msg.sender].mul(100000).div(
                t2.totalLocked
            );
            // userPerc = t2.totalLocked.div(t2.participant[msg.sender]).mul(100);
            // userPerc = t2.totalLocked.mul(100).div(t2.participant[msg.sender]);
            idoTokenAmount = tierAlloc.mul(userPerc).div(100000);
            swapTokenAmount = idoTokenAmount.div(swapPrice);
            //   swapTokenAmount = idoTokenAmount.mul(swapPrice).div(10 ** idoTokenDecimals).mul(10 ** swapTokenDecimals);
            return (idoTokenAmount, swapTokenAmount, tierAlloc, userPerc);
        } else if (tier == Tiers.TIER3) {
            tierAlloc = totalIdoTokens.mul(t3.perc).div(1000);
            userPerc = t3.participant[msg.sender].mul(100000).div(
                t3.totalLocked
            );
            // userPerc = t3.totalLocked.div(t3.participant[msg.sender]).mul(100);
            //  userPerc = t3.totalLocked.mul(100).div(t3.participant[msg.sender]);
            idoTokenAmount = tierAlloc.mul(userPerc).div(100000);
            swapTokenAmount = idoTokenAmount.div(swapPrice);
            // swapTokenAmount = idoTokenAmount.mul(swapPrice).div(10 ** idoTokenDecimals).mul(10 ** swapTokenDecimals);
            return (idoTokenAmount, swapTokenAmount, tierAlloc, userPerc);
        } else if (tier == Tiers.TIER4) {
            tierAlloc = totalIdoTokens.mul(t4.perc).div(1000);
            userPerc = t4.participant[msg.sender].mul(100000).div(
                t4.totalLocked
            );
            // userPerc = t4.totalLocked.div(t4.participant[msg.sender]).mul(100);
            // userPerc = t4.totalLocked.mul(100).div(t4.participant[msg.sender]);
            idoTokenAmount = tierAlloc.mul(userPerc).div(100000);
            swapTokenAmount = idoTokenAmount.div(swapPrice);
            // swapTokenAmount = idoTokenAmount.mul(swapPrice).div(10 ** idoTokenDecimals).mul(10 ** swapTokenDecimals);
            return (idoTokenAmount, swapTokenAmount, tierAlloc, userPerc);
        } else {
            tierAlloc = totalIdoTokens.mul(t5.perc).div(1000);
            userPerc = t5.participant[msg.sender].mul(100000).div(
                t5.totalLocked
            );
            //  userPerc = t5.totalLocked.div(t5.participant[msg.sender]).mul(100);
            // userPerc = t5.totalLocked.mul(100).div(t5.participant[msg.sender]);
            idoTokenAmount = tierAlloc.mul(userPerc).div(100000);
            swapTokenAmount = idoTokenAmount.div(swapPrice);
            // swapTokenAmount = idoTokenAmount.mul(swapPrice).div(10 ** idoTokenDecimals).mul(10 ** swapTokenDecimals);
            return (idoTokenAmount, swapTokenAmount, tierAlloc, userPerc);
        }
    }

    function getLockedBalance() public view returns (uint256) {
        return staking.stakedBalance(msg.sender); // gets locked balance
    }

    function getTier1Registrants() public view returns (address[] memory) {
        return t1Registrants;
    }

    function getTotalSwapped() public view returns (uint256) {
        return
            t1
                .totalSwapped
                .add(t2.totalSwapped)
                .add(t3.totalSwapped)
                .add(t4.totalSwapped)
                .add(t5.totalSwapped);
    }

    function getTotalRaised() public view returns (uint256) {
        return
            t1.raised.add(t2.raised).add(t3.raised).add(t4.raised).add(
                t5.raised
            );
    }

    function getTier(uint256 _amount) public pure returns (Tiers) {
        if (_amount < MINTIERAMOUNT) return Tiers.NONE;

        if (_amount >= 100 ether && _amount < 3500 ether) {
            return Tiers.TIER1;
        } else if (_amount >= 3500 ether && _amount < 8500 ether) {
            return Tiers.TIER2;
        } else if (_amount >= 8500 ether && _amount < 17000 ether) {
            return Tiers.TIER3;
        } else if (_amount >= 17000 ether && _amount < 25500 ether) {
            return Tiers.TIER4;
        } else {
            return Tiers.TIER5;
        }
    }

    function setSwapPrice(uint256 _price) external ownerOrOperator {
        require(!priceSet, "IDO: price already set.");
        priceSet = true;
        swapPrice = _price;
    }

    function withdrawSwapToken() external ownerOrOperator {
        //withdraws swap token to admin
        swapToken.safeTransfer(owner(), swapToken.balanceOf(address(this)));
    }

    function withdrawIDOToken() external ownerOrOperator {
        require(block.timestamp >= t5.swapEnd, "IDO: Swap time not done yet");
        uint256 totalSwapped = getTotalSwapped();
        if (totalSwapped < totalIdoTokens) {
            idoToken.safeTransfer(owner(), totalIdoTokens.sub(totalSwapped));
        } else return;
    }

    function setOperator(address _operator) public ownerOrOperator {
        require(_operator != address(0));
        operator = _operator;
    }

    modifier ownerOrOperator() {
        require(
            msg.sender == owner() || msg.sender == operator,
            "Not admin or operator"
        );
        _;
    }
    modifier inRegistrationWindow() {
        require(
            block.timestamp >= regStartDate && block.timestamp <= regEndDate,
            "IDO: Not in registration window."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IKSTStaking {
    function lock(address user, uint256 userUnlockTime) external;

    function addIDO(address account) external;

    function stakedBalance(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

