// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Address.sol";
import "./lib/ERC20.sol";
import "./lib/SafeERC20.sol";

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}

interface IBondCalculator {
    function valuation(address pair_, uint256 amount_)
        external
        view
        returns (uint256 _value);
}

contract TridTreasury is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event ReservesManaged(address indexed token, uint256 amount);
    event ReservesUpdated(uint256 indexed totalReserves);
    event ReservesAudited(uint256 indexed totalReserves);
    event RewardsMinted(
        address indexed caller,
        address indexed recipient,
        uint256 amount
    );
    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(
        MANAGING indexed managing,
        address activated,
        bool result
    );

    enum MANAGING {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        DEBTOR,
        REWARDMANAGER,
        SOHM,
        INNOVATIONFUND
    }

    address public immutable Trid;
    uint32 public immutable secondsNeededForQueue;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping(address => bool) public isReserveToken;
    mapping(address => uint32) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveDepositor;
    mapping(address => uint32) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveSpender;
    mapping(address => uint32) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;
    mapping(address => uint32) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;
    mapping(address => uint32) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveManager;
    mapping(address => uint32) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityManager;
    mapping(address => uint32) public LiquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isDebtor;
    mapping(address => uint32) public debtorQueue; // Delays changes to mapping.
    mapping(address => uint256) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    mapping(address => uint32) public rewardManagerQueue; // Delays changes to mapping.

    address public sTrid;
    mapping(address => uint32) public sOHMQueue; // Delays change to sOHM address

    uint256 public totalReserves; // Risk-free value of all assets
    uint256 public totalDebt;

    address public innovationFund;
    mapping(address => uint32) public innovationFundQueue;

    uint256 public innovationPercent = 1000; // 10 000 = 100%

    constructor(
        address _Trid,
        address _MIM,
        address _innovationFund,
        uint32 _secondsNeededForQueue
    ) {
        require(_Trid != address(0));
        require(_innovationFund != address(0));
        Trid = _Trid;

        isReserveToken[_MIM] = true;
        reserveTokens.push(_MIM);
        innovationFund = _innovationFund;

        secondsNeededForQueue = _secondsNeededForQueue;
        innovationFund = _innovationFund;
    }

    /**
        @notice allow approved address to deposit an asset for OHM
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 send_) {
        require(
            isReserveToken[_token] || isLiquidityToken[_token],
            "Token not accepted as deposit"
        );

        uint256 innovationAmount = _amount.mul(innovationPercent).div(10000);
        IERC20(_token).safeTransferFrom(
            msg.sender,
            innovationFund,
            innovationAmount
        );
        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount - innovationAmount
        );

        if (isReserveToken[_token]) {
            require(isReserveDepositor[msg.sender], "Depositor not approved");
        } else {
            require(
                isLiquidityDepositor[msg.sender],
                "LiquidityDepositor not approved"
            );
        }

        uint256 value = valueOf(_token, _amount);
        // mint OHM needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        IERC20Mintable(Trid).mint(msg.sender, send_);

        totalReserves = totalReserves.add(value);
        emit ReservesUpdated(totalReserves);

        emit Deposit(_token, _amount, value);
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        require(isReserveToken[_token], "Not accepted"); // Only reserves can be used for redemptions
        require(isReserveSpender[msg.sender] == true, "Not approved");

        uint256 value = valueOf(_token, _amount);
        IOHMERC20(Trid).burnFrom(msg.sender, value);

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isReserveToken[_token], "Not accepted");

        uint256 value = valueOf(_token, _amount);

        uint256 maximumDebt = IERC20(sTrid).balanceOf(msg.sender); // Can only borrow against sOHM held
        uint256 availableDebt = maximumDebt.sub(debtorBalance[msg.sender]);
        require(value <= availableDebt, "Exceeds debt limit");

        debtorBalance[msg.sender] = debtorBalance[msg.sender].add(value);
        totalDebt = totalDebt.add(value);

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).transfer(msg.sender, _amount);

        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isReserveToken[_token], "Not accepted");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = valueOf(_token, _amount);
        debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(value);
        totalDebt = totalDebt.sub(value);

        totalReserves = totalReserves.add(value);
        emit ReservesUpdated(totalReserves);

        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with OHM
        @param _amount uint
     */
    function repayDebtWithOHM(uint256 _amount) external {
        require(isDebtor[msg.sender], "Not approved");

        IOHMERC20(Trid).burnFrom(msg.sender, _amount);

        debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(_amount);
        totalDebt = totalDebt.sub(_amount);

        emit RepayDebt(msg.sender, Trid, _amount, _amount);
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage(address _token, uint256 _amount) external {
        if (isLiquidityToken[_token]) {
            require(isLiquidityManager[msg.sender], "Not approved");
        } else {
            require(isReserveManager[msg.sender], "Not approved");
        }

        uint256 value = valueOf(_token, _amount);
        require(value <= excessReserves(), "Insufficient reserves");

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit ReservesManaged(_token, _amount);
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards(address _recipient, uint256 _amount) external {
        require(isRewardManager[msg.sender], "Not approved caller");
        // TODO consider issues when backing does not start with 1:1
        require(_amount <= excessReserves(), "Insufficient reserves");

        IERC20Mintable(Trid).mint(_recipient, _amount);

        emit RewardsMinted(msg.sender, _recipient, _amount);
    }

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns (uint256) {
        return totalReserves.sub(IERC20(Trid).totalSupply().sub(totalDebt));
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyManager {
        uint256 reserves;
        for (uint256 i = 0; i < reserveTokens.length; i++) {
            reserves = reserves.add(
                valueOf(
                    reserveTokens[i],
                    IERC20(reserveTokens[i]).balanceOf(address(this))
                )
            );
        }
        for (uint256 i = 0; i < liquidityTokens.length; i++) {
            reserves = reserves.add(
                valueOf(
                    liquidityTokens[i],
                    IERC20(liquidityTokens[i]).balanceOf(address(this))
                )
            );
        }
        totalReserves = reserves;
        emit ReservesUpdated(reserves);
        emit ReservesAudited(reserves);
    }

    /**
        @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf(address _token, uint256 _amount)
        public
        view
        returns (uint256 value_)
    {
        if (isReserveToken[_token]) {
            // convert amount to match OHM decimals
            value_ = _amount.mul(10**IERC20(Trid).decimals()).div(
                10**IERC20(_token).decimals()
            );
        } else if (isLiquidityToken[_token]) {
            value_ = IBondCalculator(bondCalculator[_token]).valuation(
                _token,
                _amount
            );
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue(MANAGING _managing, address _address)
        external
        onlyManager
        returns (bool)
    {
        require(_address != address(0));
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            reserveDepositorQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            reserveSpenderQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            reserveTokenQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            ReserveManagerQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue.mul32(2)
            );
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            LiquidityDepositorQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            LiquidityTokenQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            LiquidityManagerQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue.mul32(2)
            );
        } else if (_managing == MANAGING.DEBTOR) {
            // 7
            debtorQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            rewardManagerQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.SOHM) {
            // 9
            sOHMQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else if (_managing == MANAGING.INNOVATIONFUND) {
            // 10
            innovationFundQueue[_address] = uint32(block.timestamp).add32(
                secondsNeededForQueue
            );
        } else return false;

        emit ChangeQueued(_managing, _address);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle(
        MANAGING _managing,
        address _address,
        address _calculator
    ) external onlyManager returns (bool) {
        require(_address != address(0));
        bool result;
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            if (
                requirements(
                    reserveDepositorQueue,
                    isReserveDepositor,
                    _address
                )
            ) {
                reserveDepositorQueue[_address] = 0;
                if (!listContains(reserveDepositors, _address)) {
                    reserveDepositors.push(_address);
                }
            }
            result = !isReserveDepositor[_address];
            isReserveDepositor[_address] = result;
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
                reserveSpenderQueue[_address] = 0;
                if (!listContains(reserveSpenders, _address)) {
                    reserveSpenders.push(_address);
                }
            }
            result = !isReserveSpender[_address];
            isReserveSpender[_address] = result;
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            if (requirements(reserveTokenQueue, isReserveToken, _address)) {
                reserveTokenQueue[_address] = 0;
                if (!listContains(reserveTokens, _address)) {
                    reserveTokens.push(_address);
                }
            }
            result = !isReserveToken[_address];
            isReserveToken[_address] = result;
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            if (requirements(ReserveManagerQueue, isReserveManager, _address)) {
                reserveManagers.push(_address);
                ReserveManagerQueue[_address] = 0;
                if (!listContains(reserveManagers, _address)) {
                    reserveManagers.push(_address);
                }
            }
            result = !isReserveManager[_address];
            isReserveManager[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            if (
                requirements(
                    LiquidityDepositorQueue,
                    isLiquidityDepositor,
                    _address
                )
            ) {
                liquidityDepositors.push(_address);
                LiquidityDepositorQueue[_address] = 0;
                if (!listContains(liquidityDepositors, _address)) {
                    liquidityDepositors.push(_address);
                }
            }
            result = !isLiquidityDepositor[_address];
            isLiquidityDepositor[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
                LiquidityTokenQueue[_address] = 0;
                if (!listContains(liquidityTokens, _address)) {
                    liquidityTokens.push(_address);
                }
            }
            result = !isLiquidityToken[_address];
            isLiquidityToken[_address] = result;
            bondCalculator[_address] = _calculator;
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            if (
                requirements(
                    LiquidityManagerQueue,
                    isLiquidityManager,
                    _address
                )
            ) {
                LiquidityManagerQueue[_address] = 0;
                if (!listContains(liquidityManagers, _address)) {
                    liquidityManagers.push(_address);
                }
            }
            result = !isLiquidityManager[_address];
            isLiquidityManager[_address] = result;
        } else if (_managing == MANAGING.DEBTOR) {
            // 7
            if (requirements(debtorQueue, isDebtor, _address)) {
                debtorQueue[_address] = 0;
                if (!listContains(debtors, _address)) {
                    debtors.push(_address);
                }
            }
            result = !isDebtor[_address];
            isDebtor[_address] = result;
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            if (requirements(rewardManagerQueue, isRewardManager, _address)) {
                rewardManagerQueue[_address] = 0;
                if (!listContains(rewardManagers, _address)) {
                    rewardManagers.push(_address);
                }
            }
            result = !isRewardManager[_address];
            isRewardManager[_address] = result;
        } else if (_managing == MANAGING.SOHM) {
            // 9
            require(uint32(block.timestamp) >= sOHMQueue[_address]);
            sOHMQueue[_address] = 0;
            sTrid = _address;
            result = true;
        } else if (_managing == MANAGING.INNOVATIONFUND) {
            // 10
            require(uint32(block.timestamp) >= innovationFundQueue[_address]);
            innovationFundQueue[_address] = 0;
            innovationFund = _address;
            result = true;
        } else return false;

        emit ChangeActivated(_managing, _address, result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool
     */
    function requirements(
        mapping(address => uint32) storage queue_,
        mapping(address => bool) storage status_,
        address _address
    ) internal view returns (bool) {
        if (!status_[_address]) {
            require(queue_[_address] != 0, "Must queue");
            require(
                queue_[_address] <= uint32(block.timestamp),
                "Queue not expired"
            );
            return true;
        }
        return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function setInnovationPercent(uint256 _value) external onlyManager {
        require(_value <= 2500, "Value must be inferior to 2500 (25%)");
        innovationPercent = _value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

//u32
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub32(a, b, "SafeMath: subtraction overflow");
    }

    function sub32(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    /*
     * Expects percentage to be trailed by 00,
     */
    function percentageAmount(uint256 total_, uint8 percentage_)
        internal
        pure
        returns (uint256 percentAmount_)
    {
        return div(mul(total_, percentage_), 1000);
    }

    /*
     * Expects percentage to be trailed by 00,
     */
    function substractPercentage(uint256 total_, uint8 percentageToSub_)
        internal
        pure
        returns (uint256 result_)
    {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_)
        internal
        pure
        returns (uint256 percent_)
    {
        return div(mul(part_, 100), total_);
    }

    /**
     * Taken from Hypersonic https://github.com/M2629/HyperSonic/blob/main/Math.sol
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return mul(multiplier_, supply_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./Counters.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./ERC20Permit.sol";

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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyManager
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./ERC20.sol";
import "./Counters.sol";

interface IERC2612Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 _hash = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(_hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ZeroSwapPermit: Invalid signature"
        );

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./SafeMath.sol";

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./SafeMath.sol";

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;


// TODO(zx): replace with OZ implementation.
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}