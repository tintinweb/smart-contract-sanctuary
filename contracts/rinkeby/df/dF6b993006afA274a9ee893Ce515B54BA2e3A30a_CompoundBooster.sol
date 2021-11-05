// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/SafeERC20.sol";
import "./libs/Clones.sol";
import "./compound/CompoundInterfaces.sol";
import "./common/IVirtualBalanceWrapper.sol";

contract CompoundBooster {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public compoundComptroller;
    address public compoundProxyUserTemplate;
    address public virtualBalanceWrapperFactory;
    address public compoundPoolFactory;
    address public rewardCompToken;
    address public lendflareVotingEscrow;
    address public lendflareMinter;

    address public Lending;

    struct PoolInfo {
        address lpToken;
        address rewardCompPool;
        address rewardVeLendFlarePool;
        address rewardInterestPool;
        address treasuryFund;
        address virtualBalance;
        address lendflareGauge;
        bool isErc20;
        bool shutdown;
    }

    enum LendingInfoState {
        NONE,
        LOCK,
        UNLOCK,
        LIQUIDATE
    }

    struct LendingInfo {
        uint256 pid;
        address payable proxyUser;
        uint256 cTokens;
        address underlyToken;
        uint256 amount;
        uint256 borrowNumbers;
        uint256 startedBlock;
        LendingInfoState state;
    }

    PoolInfo[] public poolInfo;

    mapping(uint256 => uint256) public frozenCTokens;
    mapping(bytes32 => LendingInfo) public lendingInfos;
    mapping(uint256 => uint256) public interestTotal;

    event Minted(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    event Borrow(
        address indexed user,
        uint256 indexed pid,
        bytes32 indexed lendingId,
        uint256 lendingAmount,
        uint256 collateralAmount,
        uint256 interestAmount,
        uint256 borrowNumbers
    );
    event RepayBorrow(
        bytes32 indexed lendingId,
        address indexed user,
        uint256 amount,
        uint256 interestValue,
        bool isErc20
    );
    event Liquidate(
        bytes32 indexed lendingId,
        uint256 lendingAmount,
        uint256 interestValue
    );

    modifier onlyLending() {
        _;
    }

    function init(
        address _virtualBalanceWrapperFactory,
        address _compoundPoolFactory,
        address _rewardCompToken,
        address _lendflareVotingEscrow,
        address _compoundProxyUserTemplate
    ) public {
        virtualBalanceWrapperFactory = _virtualBalanceWrapperFactory;
        compoundPoolFactory = _compoundPoolFactory;
        rewardCompToken = _rewardCompToken;
        lendflareVotingEscrow = _lendflareVotingEscrow;

        compoundProxyUserTemplate = _compoundProxyUserTemplate;
    }

    function addPool(address _lpToken, bool _isErc20) public returns (bool) {
        address virtualBalance = IVirtualBalanceWrapperFactory(
            virtualBalanceWrapperFactory
        ).CreateVirtualBalanceWrapper(address(this));

        address rewardCompPool = ICompoundPoolFactory(compoundPoolFactory)
            .CreateRewardPool(
                rewardCompToken,
                address(virtualBalance),
                address(this)
            );

        address rewardVeLendFlarePool;
        address rewardInterestPool;

        if (_isErc20) {
            address underlyToken = ICompoundCErc20(_lpToken).underlying();
            rewardInterestPool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(underlyToken, virtualBalance, address(this));

            rewardVeLendFlarePool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(
                    underlyToken,
                    lendflareVotingEscrow,
                    address(this)
                );
        } else {
            rewardInterestPool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(address(0), virtualBalance, address(this));

            rewardVeLendFlarePool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(
                    address(0),
                    lendflareVotingEscrow,
                    address(this)
                );
        }

        address treasuryFundPool = ICompoundPoolFactory(compoundPoolFactory)
            .CreateTreasuryFundPool(address(this));

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardCompPool: rewardCompPool,
                rewardVeLendFlarePool: rewardVeLendFlarePool,
                rewardInterestPool: rewardInterestPool,
                treasuryFund: treasuryFundPool,
                virtualBalance: virtualBalance,
                lendflareGauge: address(0),
                isErc20: _isErc20,
                shutdown: false
            })
        );

        return true;
    }

    function _mintEther(address lpToken, uint256 _amount) internal {
        ICompoundCEther(lpToken).mint{value: _amount}();
    }

    function _mintErc20(address lpToken, uint256 _amount) internal {
        ICompoundCErc20(lpToken).mint(_amount);
    }

    /**
        @param _amount 质押金额,将转入treasuryFunds
        @param _isCToken 是否参与转化为cToken,如果开启，_amount 将为 erc20的转化金额
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _isCToken
    ) public payable returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        if (!_isCToken) {
            if (pool.isErc20) {
                require(_amount > 0);

                address underlyToken = ICompoundCErc20(pool.lpToken)
                    .underlying();

                IERC20(underlyToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amount
                );

                IERC20(underlyToken).safeApprove(pool.lpToken, 0);
                IERC20(underlyToken).safeApprove(pool.lpToken, _amount);

                _mintErc20(pool.lpToken, _amount);
            } else {
                require(msg.value > 0 && _amount == 0);

                _mintEther(pool.lpToken, msg.value);
            }
        } else {
            IERC20(pool.lpToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        uint256 mintToken = IERC20(pool.lpToken).balanceOf(address(this));

        require(mintToken > 0, "mintToken = 0");

        IERC20(pool.lpToken).safeTransfer(pool.treasuryFund, mintToken);

        ICompoundInterestRewardPool(pool.rewardCompPool).updateRewardState(
            msg.sender
        );
        ICompoundInterestRewardPool(pool.rewardInterestPool).updateRewardState(
            msg.sender
        );


        IVirtualBalanceWrapper(pool.virtualBalance).stakeFor(
            msg.sender,
            mintToken
        );

        if (pool.lendflareGauge != address(0)) {
            ILendFlareGague(pool.lendflareGauge).user_checkpoint(msg.sender);
        }

        emit Deposited(msg.sender, _pid, mintToken);

        return true;
    }

    function withdraw(uint256 _pid, uint256 _amount) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 depositAmount = IRewardPool(pool.rewardCompPool).balanceOf(
            msg.sender
        );

        require(
            IERC20(pool.lpToken).balanceOf(pool.treasuryFund) >= _amount,
            "!Insufficient balance"
        );
        require(_amount <= depositAmount, "!depositAmount");

        ICompoundTreasuryFund(pool.treasuryFund).withdrawTo(
            pool.lpToken,
            _amount,
            msg.sender
        );

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(
            msg.sender,
            _amount
        );

        ICompoundInterestRewardPool(pool.rewardCompPool).updateRewardState(
            msg.sender
        );
        ICompoundInterestRewardPool(pool.rewardInterestPool).updateRewardState(
            msg.sender
        );

        return true;
    }

    function claimComp() external returns (bool) {
        address compAddress = ICompoundComptroller(compoundComptroller)
            .getCompAddress();

        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].shutdown) {
                continue;
            }

            (uint256 rewards, bool claimed) = ICompoundTreasuryFund(
                poolInfo[i].treasuryFund
            ).claimComp(
                    compAddress,
                    compoundComptroller,
                    poolInfo[i].rewardCompPool
                );

            if (claimed) {
                ICompoundInterestRewardPool(poolInfo[i].rewardCompPool)
                    .queueNewRewards(rewards);
            }
        }

        return true;
    }

    function setCompoundComptroller(address _v) public {
        require(_v != address(0), "!_v");

        compoundComptroller = _v;
    }

    function setLendflareMinter(address _v) public {
        require(_v != address(0), "!_v");

        lendflareMinter = _v;
    }

    function setLendFlareGauge(uint256 _pid, address _v) public {
        PoolInfo storage pool = poolInfo[_pid];

        require(pool.lendflareGauge == address(0), "!lendflareGauge");

        pool.lendflareGauge = _v;
    }

    receive() external payable {}

    function getRewards(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];

        if (IRewardPool(pool.rewardCompPool).earned(msg.sender) > 0) {
            IRewardPool(pool.rewardCompPool).getReward(msg.sender);
        }

        if (IRewardPool(pool.rewardInterestPool).earned(msg.sender) > 0) {
            IRewardPool(pool.rewardInterestPool).getReward(msg.sender);
        }

        ILendFlareMinter(lendflareMinter).mint_for(
            pool.lendflareGauge,
            msg.sender
        );
    }

    // function getVeLFTUserRewards(uint256 _pid) public {
    //     PoolInfo memory pool = poolInfo[_pid];

    //     if (IRewardPool(pool.rewardVeLendFlarePool).earned(msg.sender) > 0) {
    //         IRewardPool(pool.rewardVeLendFlarePool).getReward(msg.sender);
    //     }
    // }

    function getVeLFTUserRewards() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            PoolInfo memory pool = poolInfo[pid];

            if (
                IRewardPool(pool.rewardVeLendFlarePool).earned(msg.sender) > 0
            ) {
                IRewardPool(pool.rewardVeLendFlarePool).getReward(msg.sender);
            }
        }
    }

    /* lending interfaces */
    function cloneUserTemplate(
        uint256 _pid,
        bytes32 _lendingId,
        address _treasuryFund,
        address _sender
    ) internal {
        LendingInfo memory lendingInfo = lendingInfos[_lendingId];

        if (lendingInfo.startedBlock == 0) {
            address payable template = payable(
                Clones.clone(compoundProxyUserTemplate)
            );

            ICompoundProxyUserTemplate(template).init(
                address(this),
                _treasuryFund,
                _lendingId,
                _sender,
                rewardCompToken
            );

            lendingInfos[_lendingId] = LendingInfo({
                pid: _pid,
                proxyUser: template,
                cTokens: 0,
                underlyToken: address(0),
                amount: 0,
                startedBlock: 0,
                borrowNumbers: 0,
                state: LendingInfoState.NONE
            });
        }
    }

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _collateralAmount,
        uint256 _interestValue,
        uint256 _borrowNumbers
    ) public {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 exchangeRateStored = ICompound(pool.lpToken)
            .exchangeRateStored();
        uint256 cTokens = _collateralAmount.mul(1e18).div(exchangeRateStored);

        require(
            IERC20(pool.lpToken).balanceOf(pool.treasuryFund) >= cTokens,
            "!Insufficient balance"
        );

        frozenCTokens[_pid] = frozenCTokens[_pid].add(cTokens);
        interestTotal[_pid] = interestTotal[_pid].add(_interestValue);

        cloneUserTemplate(_pid, _lendingId, pool.treasuryFund, _user);

        LendingInfo storage lendingInfo = lendingInfos[_lendingId];

        lendingInfo.cTokens = cTokens;
        lendingInfo.amount = _lendingAmount;
        lendingInfo.startedBlock = block.number;
        lendingInfo.borrowNumbers = _borrowNumbers;
        lendingInfo.state = LendingInfoState.LOCK;

        ICompoundTreasuryFund(pool.treasuryFund).withdrawTo(
            pool.lpToken,
            cTokens,
            lendingInfo.proxyUser
        );

        if (pool.isErc20) {
            address underlyToken = ICompoundCErc20(pool.lpToken).underlying();

            lendingInfo.underlyToken = underlyToken;

            ICompoundProxyUserTemplate(lendingInfo.proxyUser).borrowErc20(
                pool.lpToken,
                underlyToken,
                _user,
                _lendingAmount,
                _interestValue
            );

            uint256 bal = IERC20(lendingInfo.underlyToken).balanceOf(
                address(this)
            );

            if (bal > 0) {
                uint256 exchangeReward = bal.mul(50).div(100);
                uint256 lendflareDeposterReward = bal.sub(exchangeReward);

                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardInterestPool,
                    exchangeReward
                );
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardVeLendFlarePool,
                    lendflareDeposterReward
                );

                ICompoundInterestRewardPool(pool.rewardInterestPool)
                    .queueNewRewards(exchangeReward);

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(lendflareDeposterReward);
            }
        } else {
            lendingInfo.underlyToken = address(0);

            ICompoundProxyUserTemplate(lendingInfo.proxyUser).borrow(
                pool.lpToken,
                payable(_user),
                _lendingAmount,
                _interestValue
            );

            uint256 bal = address(this).balance;

            if (bal > 0) {
                uint256 exchangeReward = bal.mul(50).div(100);
                uint256 lendflareDeposterReward = bal.sub(exchangeReward);

                payable(pool.rewardInterestPool).transfer(exchangeReward);
                payable(pool.rewardVeLendFlarePool).transfer(
                    lendflareDeposterReward
                );
                ICompoundInterestRewardPool(pool.rewardInterestPool)
                    .queueNewRewards(exchangeReward);

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(lendflareDeposterReward);
            }
        }

        emit Borrow(
            _user,
            _pid,
            _lendingId,
            _lendingAmount,
            _collateralAmount,
            _interestValue,
            _borrowNumbers
        );
    }

    function _repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _interestValue,
        bool _isErc20
    ) internal {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];
        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        require(lendingInfo.state == LendingInfoState.LOCK, "!LOCK");

        frozenCTokens[lendingInfo.pid] = frozenCTokens[lendingInfo.pid].sub(
            lendingInfo.cTokens
        );
        interestTotal[lendingInfo.pid] = interestTotal[lendingInfo.pid].sub(
            _interestValue
        );

        if (_isErc20) {
            uint256 bal = ICompoundProxyUserTemplate(lendingInfo.proxyUser)
                .repayBorrowErc20(
                    pool.lpToken,
                    lendingInfo.underlyToken,
                    _user,
                    _amount
                );

            if (bal > 0) {
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardVeLendFlarePool,
                    bal
                );

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(bal);
            }
        } else {
            uint256 bal = ICompoundProxyUserTemplate(lendingInfo.proxyUser)
                .repayBorrow{value: _amount}(pool.lpToken, payable(_user));

            if (bal > 0) {
                payable(pool.rewardVeLendFlarePool).transfer(bal);

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(bal);
            }
        }

        // ICompoundProxyUserTemplate(lendingInfo.proxyUser).recycle(
        //     pool.lpToken,
        //     lendingInfo.underlyToken
        // );

        lendingInfo.state = LendingInfoState.UNLOCK;

        emit RepayBorrow(_lendingId, _user, _amount, _interestValue, _isErc20);
    }

    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _interestValue
    ) external payable {
        _repayBorrow(_lendingId, _user, msg.value, _interestValue, false);
    }

    function repayBorrowErc20(
        bytes32 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _interestValue
    ) external {
        _repayBorrow(_lendingId, _user, _amount, _interestValue, true);
    }

    function liquidate(
        bytes32 _lendingId,
        uint256 _lendingAmount,
        uint256 _interestValue
    ) public payable returns (address) {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];
        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        require(lendingInfo.state == LendingInfoState.LOCK, "!LOCK");

        frozenCTokens[lendingInfo.pid] = frozenCTokens[lendingInfo.pid].sub(
            lendingInfo.cTokens
        );
        interestTotal[lendingInfo.pid] = interestTotal[lendingInfo.pid].sub(
            _interestValue
        );

        uint256 bal = ICompoundProxyUserTemplate(lendingInfo.proxyUser)
            .repayBorrowBySelf{value: msg.value}(
            pool.lpToken,
            lendingInfo.underlyToken
        );

        if (bal > 0) {
            uint256 exchangeReward = bal.mul(50).div(100);
            uint256 lendflareDeposterReward = bal.sub(exchangeReward);

            if (pool.isErc20) {
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardInterestPool,
                    exchangeReward
                );
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardVeLendFlarePool,
                    lendflareDeposterReward
                );
            } else {
                payable(pool.rewardInterestPool).transfer(exchangeReward);
                payable(pool.rewardVeLendFlarePool).transfer(
                    lendflareDeposterReward
                );
            }

            ICompoundInterestRewardPool(pool.rewardInterestPool)
                .queueNewRewards(exchangeReward);
            ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                .queueNewRewards(lendflareDeposterReward);
        }

        lendingInfo.state = LendingInfoState.UNLOCK;

        emit Liquidate(_lendingId, _lendingAmount, _interestValue);
    }

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function totalSupplyOf(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        return IERC20(pool.lpToken).balanceOf(address(this));
    }

    function getUtilizationRate(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 currentBal = IERC20(pool.lpToken).balanceOf(pool.treasuryFund);

        if (currentBal == 0 || frozenCTokens[_pid] == 0) {
            return 0;
        }

        return
            frozenCTokens[_pid].mul(1e18).div(
                currentBal.add(frozenCTokens[_pid])
            );
    }

    function getBorrowRatePerBlock(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        return ICompound(pool.lpToken).borrowRatePerBlock();
    }

    function getExchangeRateStored(uint256 _pid)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];

        return ICompound(pool.lpToken).exchangeRateStored();
    }

    function getCollateralFactorMantissa(uint256 _pid)
        public
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];

        ICompoundComptroller comptroller = ICompound(pool.lpToken)
            .comptroller();
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            pool.lpToken
        );

        return isListed ? collateralFactorMantissa : 800000000000000000;
    }

    function getLendingInfos(bytes32 _lendingId)
        public
        view
        returns (address payable, address)
    {
        LendingInfo memory lendingInfo = lendingInfos[_lendingId];

        return (lendingInfo.proxyUser, lendingInfo.underlyToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt)
        internal
        returns (address instance)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address master,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface ICompound {
    function borrow(uint256 borrowAmount) external returns (uint256);
    // function interestRateModel() external returns (InterestRateModel);
    // function comptroller() external view returns (ComptrollerInterface);
    // function balanceOf(address owner) external view returns (uint256);
    function isCToken(address) external view returns(bool);
    function comptroller() external view returns (ICompoundComptroller);
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function getAccountSnapshot(address account) external view returns ( uint256, uint256, uint256, uint256 );
    function accrualBlockNumber() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function borrowBalanceStored(address user) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function decimals() external view returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint);
    function interestRateModel() external view returns (address);
}

interface ICompoundCEther is ICompound {
    function repayBorrow() external payable;
    function mint() external payable;
}

interface ICompoundCErc20 is ICompound {
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function underlying() external returns(address); // like usdc usdt
}

interface ICompRewardPool {
    function stakeFor(address _for, uint256 amount) external;
    function withdrawFor(address _for, uint256 amount) external;
    function queueNewRewards(uint256 _rewards) external;
    function rewardToken() external returns(address);
    function rewardConvexToken() external returns(address);

    function getReward(address _account, bool _claimExtras) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256);
}

interface ICompRewardFactory {
    function CreateRewards(address _operator) external returns (address);
}

interface ICompoundTreasuryFund {
    function withdrawTo( address _asset, uint256 _amount, address _to ) external;
    // function borrowTo( address _asset, address _underlyAsset, uint256 _borrowAmount, address _to, bool _isErc20 ) external returns (uint256);
    // function repayBorrow( address _asset, bool _isErc20, uint256 _amount ) external payable;
    function claimComp( address _comp, address _comptroller, address _to ) external returns (uint256, bool);
}

interface ICompoundTreasuryFundFactory {
    function CreateTreasuryFund(address _operator) external returns (address);
}

interface ICompoundComptroller {
    /*** Assets You Are In ***/
    // 开启抵押
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    // 关闭抵押
    function exitMarket(address cToken) external returns (uint256);
    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);

    function claimComp(address holder) external;
    function claimComp(address holder, address[] memory cTokens) external;
    function getCompAddress() external view returns (address);
    function getAllMarkets() external view returns (address[] memory);
    function accountAssets(address user) external view returns (address[] memory);
    function markets(address _cToken) external view returns(bool isListed, uint collateralFactorMantissa);
}

interface ICompoundProxyUserTemplate {
    function init( address _op, address _treasuryFund, bytes32 _lendingId, address _user, address _rewardComp ) external;
    function borrow( address _asset, address payable _for, uint256 _lendingAmount, uint256 _interestAmount ) external;
    function borrowErc20( address _asset, address _token, address _for, uint256 _lendingAmount, uint256 _interestAmount ) external;
    function repayBorrowBySelf(address _asset,address _underlyingToken) external payable returns(uint256);
    function repayBorrow(address _asset, address payable _for) external payable returns(uint256);
    function repayBorrowErc20( address _asset, address _token,address _for, uint256 _amount ) external returns(uint256);
    function op() external view returns (address);
    function asset() external view returns (address);
    function user() external view returns (address);
    function recycle(address _asset,address _underlyingToken) external;
    function borrowBalanceStored(address _asset) external view returns (uint256);
}

interface ICompoundInterestRateModel {
    function blocksPerYear() external view returns (uint256);
}

interface ICompoundPoolFactory {
    // function CreateCompoundRewardPool(address rewardToken,address virtualBalance, address op) external returns (address);
    function CreateRewardPool(address rewardToken, address virtualBalance,address op) external returns (address);
    function CreateTreasuryFundPool(address op) external returns (address);
}

interface ICompoundInterestRewardPool {
    function donate(uint256 _amount) external payable returns (bool);
    function queueNewRewards(uint256 _rewards) external;
    function updateRewardState(address _user) external;
}

interface IRewardPool {
    function earned(address _for) external view returns (uint256);
    function getReward(address _for) external;
    function balanceOf(address _for) external view returns (uint256);
/* function getReward(address _account) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256); */
}

interface ILendFlareGague {
    function user_checkpoint(address addr) external returns (bool);
}

interface ILendFlareMinter {
    function mint_for(address gauge_addr, address _for) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface IVirtualBalanceWrapperFactory {
    function CreateVirtualBalanceWrapper(address op) external returns (address);
}

interface IVirtualBalanceWrapper {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdrawFor(address _for, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


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

pragma solidity =0.6.12;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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