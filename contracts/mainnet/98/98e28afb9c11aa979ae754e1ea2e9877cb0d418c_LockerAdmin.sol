/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// File: contracts\interfaces\ILockedCvx.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ILockedCvx{
    function lock(address _account, uint256 _amount, uint256 _spendRatio) external;
    function processExpiredLocks(bool _relock, uint256 _spendRatio, address _withdrawTo) external;
    function getReward(address _account, bool _stake) external;
    function balanceAtEpochOf(uint256 _epoch, address _user) view external returns(uint256 amount);
    function totalSupplyAtEpoch(uint256 _epoch) view external returns(uint256 supply);
    function epochCount() external view returns(uint256);
    function checkpointEpoch() external;
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() view external returns(uint256 supply);

    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) external;
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
    function setStakeLimits(uint256 _minimum, uint256 _maximum) external;
    function setBoost(uint256 _max, uint256 _rate, address _receivingAddress) external;
    function setKickIncentive(uint256 _rate, uint256 _delay) external;
    function shutdown() external;
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: contracts\LockerAdmin.sol

pragma solidity 0.6.12;


/*
Admin proxy for locker contract to fix require checks and seal off staking proxy changes
*/
contract LockerAdmin{

    ILockedCvx public constant locker = ILockedCvx(0xD18140b4B819b895A3dba5442F959fA44994AF50);
    address public operator;

    constructor() public {
        operator = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
    }

    modifier onlyOwner() {
        require(operator == msg.sender, "!auth");
        _;
    }

    function setOperator(address _operator) external onlyOwner{
        operator = _operator;
    }


    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) external onlyOwner{
        locker.addReward(_rewardsToken, _distributor, _useBoost);
    }

    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external onlyOwner{
        locker.approveRewardDistributor(_rewardsToken, _distributor, _approved);
    }

    //seal setStakingContract off, make it immutable
    // function setStakingContract(address _staking) external onlyOwner{
    //     locker.setStakingContract(_staking);
    // }

    function setStakeLimits(uint256 _minimum, uint256 _maximum) external onlyOwner {
        require(_minimum <= _maximum, "min range");
        locker.setStakeLimits(_minimum, _maximum);
    }

    function setBoost(uint256 _max, uint256 _rate, address _receivingAddress) external onlyOwner {
        require(_max < 1500, "over max payment"); //max 15%
        require(_rate < 30000, "over max rate"); //max 3x
        locker.setBoost(_max, _rate, _receivingAddress);
    }

    function setKickIncentive(uint256 _rate, uint256 _delay) external onlyOwner {
        locker.setKickIncentive(_rate, _delay);
    }

    function shutdown() external onlyOwner {
        locker.shutdown();
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        locker.recoverERC20(_tokenAddress, _tokenAmount);
        transferToken(_tokenAddress, _tokenAmount);
    }

    function transferToken(address _tokenAddress, uint256 _tokenAmount) public onlyOwner {
        IERC20(_tokenAddress).transfer(operator, _tokenAmount);
    }
}