// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

contract yAxisMetaVaultManager {
    address public governance;

    address public profitSharer;
    address public yax; // YAX

    mapping(address => bool) public vaults;
    mapping(address => bool) public controllers;
    mapping(address => bool) public strategies;

    address public stakingPool = 0x362Db1c17db4C79B51Fe6aD2d73165b1fe9BaB4a; // this pool will be set up later, so at first we set it to treasury
    address public treasuryWallet = 0x362Db1c17db4C79B51Fe6aD2d73165b1fe9BaB4a;
    address public performanceReward = 0x5661bF295f48F499A70857E8A6450066a8D16400; // set to deploy wallet at start

    /** The following fees are all mutable. They are updated by governance (community vote) with Timelock **/
    uint256 public stakingPoolShareFee = 2000; // 20% of profit go back to staking pool
    uint256 public gasFee = 100; // 1% of profit paid for deployment and execution (gas) fee
    uint256 public insuranceFee = 0; // % of deposits go into an insurance fund (or auto-compounding if called by controller) in-case of negative profits to protect withdrawals
    uint256 public withdrawalProtectionFee = 10; // % of withdrawal go back to vault (for auto-compounding) to protect withdrawals

    constructor (address _yax) public {
        yax = _yax;
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setProfitSharer(address _profitSharer) external {
        require(msg.sender == governance, "!governance");
        profitSharer = _profitSharer;
    }

    function setYax(address _yax) external {
        require(msg.sender == governance, "!governance");
        yax = _yax;
    }

    function setVaultStatus(address _vault, bool _status) external {
        require(msg.sender == governance, "!governance");
        vaults[_vault] = _status;
    }

    function setControllerStatus(address _controller, bool _status) external {
        require(msg.sender == governance, "!governance");
        controllers[_controller] = _status;
    }

    function setStrategyStatus(address _strategy, bool _status) external {
        require(msg.sender == governance, "!governance");
        strategies[_strategy] = _status;
    }

    function setStakingPool(address _stakingPool) public {
        require(msg.sender == governance, "!governance");
        stakingPool = _stakingPool;
    }

    function setTreasuryWallet(address _treasuryWallet) public {
        require(msg.sender == governance, "!governance");
        treasuryWallet = _treasuryWallet;
    }

    function setPerformanceReward(address _performanceReward) public{
        require(msg.sender == governance, "!governance");
        performanceReward = _performanceReward;
    }

    function setStakingPoolShareFee(uint256 _stakingPoolShareFee) public {
        require(msg.sender == governance, "!governance");
        require(_stakingPoolShareFee <= 5000, "_stakingPoolShareFee over 50%");
        stakingPoolShareFee = _stakingPoolShareFee;
    }

    function setGasFee(uint256 _gasFee) public {
        require(msg.sender == governance, "!governance");
        require(_gasFee <= 500, "_gasFee over 5%");
        gasFee = _gasFee;
    }

    function setInsuranceFee(uint256 _insuranceFee) public {
        require(msg.sender == governance, "!governance");
        require(_insuranceFee <= 100, "_insuranceFee over 1%");
        insuranceFee = _insuranceFee;
    }

    function setWithdrawalProtectionFee(uint256 _withdrawalProtectionFee) public {
        require(msg.sender == governance, "!governance");
        require(_withdrawalProtectionFee <= 100, "_withdrawalProtectionFee over 1%");
        withdrawalProtectionFee = _withdrawalProtectionFee;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(_to, _amount);
    }
}