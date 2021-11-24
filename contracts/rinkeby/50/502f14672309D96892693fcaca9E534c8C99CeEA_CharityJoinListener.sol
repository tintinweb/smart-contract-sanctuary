// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mock/DataUnionModule.sol";
import "./mock/IJoinListener.sol";

contract CharityJoinListener is DataUnionModule, IJoinListener {

    event CharityWalletSet(address);
    event TokenAddressSet(address);
    event JoinPartForCharitySet(uint256);
    event MonthlyLimitSet(uint256);
    event DataUnionAddressSet(address);
    event Withdrawn(uint256);
    event CharityPaid(address, address, uint256);

    address public charityWallet;
    address public tokenAddress;
    uint256 public joinShareForCharity;

    uint256 public monthlyLimit;
    uint256 public lastMonthDate;
    uint256 public lastMonthPaid;

    constructor(address _charityWallet, address _tokenAddress, uint256 _joinShareForCharity, uint256 _monthlyLimit,
        address dataUnionAddress) DataUnionModule(dataUnionAddress){

        require(_charityWallet != address(0), "_charityWallet can not be 0");
        require(_tokenAddress != address(0), "_tokenAddress can not be 0");
        require(_joinShareForCharity > 0, "_joinShareForCharity can not be 0");
        require(_monthlyLimit > 0, "_monthlyLimit can not be 0");
        require(dataUnionAddress != address(0), "dataUnionAddress can not be 0");

        charityWallet = _charityWallet;
        tokenAddress = _tokenAddress;
        joinShareForCharity = _joinShareForCharity;
        monthlyLimit = _monthlyLimit;

    }

    function setCharityWallet(address _charityWallet) external onlyOwner {
        require(_charityWallet != address(0), "_charityWallet can not be 0");
        emit CharityWalletSet(_charityWallet);
        charityWallet = _charityWallet;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "_tokenAddress can not be 0");
        emit TokenAddressSet(_tokenAddress);
        tokenAddress = _tokenAddress;
    }

    function setJoinPartForCharity(uint256 _joinShareForCharity) external onlyOwner {
        require(_joinShareForCharity > 0, "_joinShareForCharity can not be 0");
        emit JoinPartForCharitySet(_joinShareForCharity);
        joinShareForCharity = _joinShareForCharity;
    }

    function setMonthlyLimit(uint256 _monthlyLimit) external onlyOwner {
        require(_monthlyLimit > 0, "_monthlyLimit can not be 0");
        //if this will not checked, we would have an error in onJoin method; cause the _monthlyLimit - lastMonthPaid is negative!
        require(_monthlyLimit > lastMonthPaid, "_monthlyLimit should be greater than lastMonthPaid");
        emit MonthlyLimitSet(_monthlyLimit);
        monthlyLimit = _monthlyLimit;
    }

    function setDataUnionAddress(address dataUnionAddress) external onlyOwner {
        require(dataUnionAddress != address(0), "dataUnionAddress can not be 0");
        emit DataUnionAddressSet(dataUnionAddress);
        dataUnion = dataUnionAddress;
    }

    function withdraw() external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        emit Withdrawn(balance);
        IERC20(tokenAddress).transfer(msg.sender, balance);
    }

    function onJoin(address newMember) override external onlyDataUnion {
        uint256 payment;

        //this also work for the first time that lastMonthDate is 0
        if(block.timestamp - lastMonthDate > 30 days){
            lastMonthDate = block.timestamp;
            lastMonthPaid = 0;
        }

        if(lastMonthPaid + joinShareForCharity <= monthlyLimit){
            payment = joinShareForCharity;
        }
        else {
            payment = monthlyLimit - lastMonthPaid;
        }
        lastMonthPaid = lastMonthPaid + payment;

        emit CharityPaid(charityWallet, newMember, payment);
        IERC20(tokenAddress).transfer(charityWallet, payment);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC677.sol";
import "./LeaveConditionCode.sol";

interface IDataUnion {
    function owner() external returns (address);
    function removeMember(address member, LeaveConditionCode leaveCondition) external;
    function addMember(address newMember) external;
    function isMember(address member) external view returns (bool);
    function isJoinPartAgent(address agent) external view returns (bool) ;
}

contract DataUnionModule {
    address public dataUnion;

    modifier onlyOwner() {
        require(msg.sender == IDataUnion(dataUnion).owner(), "error_onlyOwner");
        _;
    }

    modifier onlyJoinPartAgent() {
        require(IDataUnion(dataUnion).isJoinPartAgent(msg.sender), "error_onlyJoinPartAgent");
        _;
    }

    modifier onlyDataUnion() {
        require(msg.sender == dataUnion, "error_onlyDataUnionContract");
        _;
    }

    constructor(address dataUnionAddress) {
        dataUnion = dataUnionAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IJoinListener {
    function onJoin(address newMember) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677 is IERC20 {
    function transferAndCall(
        address to,
        uint value,
        bytes calldata data
    ) external returns (bool success);

    event Transfer(
        address indexed from,
        address indexed to,
        uint value,
        bytes data
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * Describes how the data union member left
 * For the base DataUnion contract this isn't important, but modules/extensions can find it very helpful
 * See e.g. LimitWithdrawModule
 */
enum LeaveConditionCode {
    SELF,   // self remove using partMember()
    AGENT,  // removed by joinPartAgent using partMember()
    BANNED  // removed by BanModule
}