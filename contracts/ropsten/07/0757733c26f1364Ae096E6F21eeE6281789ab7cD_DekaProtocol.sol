// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./interfaces/IDekaToken.sol";
import "./interfaces/IDekaReceiver.sol";
import "./interfaces/IDekaProtocol.sol";

import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";

contract DekaProtocol is IDekaProtocol {
    using SafeMath for uint256;
    using Address for address;

    struct Stake {
        uint256 amountIn;
        uint256 expiry;
        uint256 expireAfter;
        uint256 mintedAmount;
        address staker;
        address receiver;
    }

    uint256 public constant override TIMELOCK = 3 days;
    address public constant override DEKA_TOKEN = 0xcc043fF110ec01beB2e33C2713Af5924A19aB723; // deka.finance - token

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant MAX_DPY_FOR_1_YEAR = 5e17;
    uint256 internal constant SECONDS_IN_1_YEAR = 365 * 86400;

    uint256 public override matchRatio;
    address public override matchReceiver;

    mapping(bytes32 => Stake) public override stakes;
    mapping(LockedFunctions => uint256) public override timelock;
    mapping(address => uint256) public override balances;

    event Staked(
        bytes32 _id,
        uint256 _amountIn,
        uint256 _expiry,
        uint256 _expireAfter,
        uint256 _mintedAmount,
        address indexed _staker,
        address indexed _receiver
    );

    event Unstaked(bytes32 _id, uint256 _amountIn, address indexed _staker);

    modifier onlyMatchReceiver {
        require(msg.sender == matchReceiver, "DekaProtocol:: NOT_MATCH_RECEIVER");
        _;
    }

    modifier notLocked(LockedFunctions _lockedFunction) {
        require(
            timelock[_lockedFunction] != 0 && timelock[_lockedFunction] <= block.timestamp,
            "DekaProtocol:: FUNCTION_TIMELOCKED"
        );
        _;
    }

    constructor(address _initialMatchReceiver, uint256 _initialMatchRatio) {
        _setMatchRatio(_initialMatchRatio);
        _setMatchReceiver(_initialMatchReceiver);
    }

    function lockFunction(LockedFunctions _lockedFunction) external override onlyMatchReceiver {
        timelock[_lockedFunction] = type(uint256).max;
    }

    function unlockFunction(LockedFunctions _lockedFunction) external override onlyMatchReceiver {
        timelock[_lockedFunction] = block.timestamp + TIMELOCK;
    }

    function setMatchReceiver(address _newMatchReceiver)
        external
        override
        onlyMatchReceiver
        notLocked(LockedFunctions.SET_MATCH_RECEIVER)
    {
        _setMatchReceiver(_newMatchReceiver);
        timelock[LockedFunctions.SET_MATCH_RECEIVER] = 0;
    }

    function _setMatchReceiver(address _newMatchReceiver) internal {
        matchReceiver = _newMatchReceiver;
    }

    function setMatchRatio(uint256 _newMatchRatio)
        external
        override
        onlyMatchReceiver
        notLocked(LockedFunctions.SET_MATCH_RATIO)
    {
        _setMatchRatio(_newMatchRatio);
        timelock[LockedFunctions.SET_MATCH_RATIO] = 0;
    }

    function _setMatchRatio(uint256 _newMatchRatio) internal {
        require(_newMatchRatio >= 0 && _newMatchRatio <= 2000, "DekaProtocol:: INVALID_MATCH_RATIO");
        // can be 0 and cannot be above 20%
        require(_newMatchRatio <= 2000, "DekaProtocol:: INVALID_MATCH_RATIO");
        matchRatio = _newMatchRatio;
    }

    function stake(
        uint256 _amountIn,
        uint256 _expiry,
        address _receiver,
        bytes calldata _data
    )
        external
        override
        returns (
            uint256,
            uint256,
            bytes32
        )
    {
        return _stake(_amountIn, _expiry, _receiver, _data);
    }

    function stakeWithPermit(
        address _receiver,
        uint256 _amountIn,
        uint256 _expiry,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes calldata _data
    )
        external
        override
        returns (
            uint256,
            uint256,
            bytes32
        )
    {
        IDekaToken(DEKA_TOKEN).permit(msg.sender, address(this), type(uint256).max, _deadline, _v, _r, _s);
        return _stake(_amountIn, _expiry, _receiver, _data);
    }

    function _stake(
        uint256 _amountIn,
        uint256 _expiry,
        address _receiver,
        bytes calldata _data
    )
        internal
        returns (
            uint256 mintedAmount,
            uint256 matchedAmount,
            bytes32 id
        )
    {
        require(_amountIn > 0, "DekaProtocol:: INVALID_AMOUNT");
        require(_receiver != address(this), "DekaProtocol:: INVALID_ADDRESS");
        require(_expiry <= calculateMaxStakePeriod(_amountIn), "DekaProtocol:: MAX_STAKE_PERIOD_EXCEEDS");

        address staker = msg.sender;

        uint256 expiration = block.timestamp.add(_expiry);
        balances[staker] = balances[staker].add(_amountIn);

        id = keccak256(abi.encodePacked(_amountIn, _expiry, _receiver, staker, block.timestamp));

        require(stakes[id].staker == address(0), "DekaProtocol:: STAKE_EXISTS");

        mintedAmount = getMintAmount(_amountIn, _expiry);
        matchedAmount = getMatchedAmount(mintedAmount);

        IDekaToken(DEKA_TOKEN).transferFrom(staker, address(this), _amountIn);

        IDekaToken(DEKA_TOKEN).mint(_receiver, mintedAmount);
        IDekaToken(DEKA_TOKEN).mint(matchReceiver, matchedAmount);

        stakes[id] = Stake(_amountIn, _expiry, expiration, mintedAmount, staker, _receiver);

        if (_receiver.isContract()) {
            IDekaReceiver(_receiver).receiveDeka(id, _amountIn, expiration, mintedAmount, staker, _data);
        }

        emit Staked(id, _amountIn, _expiry, expiration, mintedAmount, staker, _receiver);
    }

    function unstake(bytes32 _id) external override returns (uint256 withdrawAmount) {
        Stake memory s = stakes[_id];
        require(block.timestamp >= s.expireAfter, "DekaProtocol:: STAKE_NOT_EXPIRED");
        balances[s.staker] = balances[s.staker].sub(s.amountIn);
        withdrawAmount = s.amountIn;
        delete stakes[_id];
        IDekaToken(DEKA_TOKEN).transfer(s.staker, withdrawAmount);
        emit Unstaked(_id, s.amountIn, s.staker);
    }

    function unstakeEarly(bytes32 _id) external override returns (uint256 withdrawAmount) {
        Stake memory s = stakes[_id];
        address staker = msg.sender;
        require(s.staker == staker, "DekaProtocol:: INVALID_STAKER");
        uint256 remainingTime = (s.expireAfter.sub(block.timestamp));
        require(s.expiry > remainingTime, "DekaProtocol:: INVALID_UNSTAKE_TIME");
        uint256 burnAmount = _calculateBurn(s.amountIn, remainingTime, s.expiry);
        assert(burnAmount <= s.amountIn);
        balances[staker] = balances[staker].sub(s.amountIn);
        withdrawAmount = s.amountIn.sub(burnAmount);
        delete stakes[_id];
        IDekaToken(DEKA_TOKEN).burn(burnAmount);
        IDekaToken(DEKA_TOKEN).transfer(staker, withdrawAmount);
        emit Unstaked(_id, withdrawAmount, staker);
    }

    function getMatchedAmount(uint256 _mintedAmount) public view override returns (uint256) {
        return _mintedAmount.mul(matchRatio).div(10000);
    }

    function getMintAmount(uint256 _amountIn, uint256 _expiry) public view override returns (uint256) {
        return _amountIn.mul(_expiry).mul(getDPY(_amountIn)).div(PRECISION * SECONDS_IN_1_YEAR);
    }

    function getDPY(uint256 _amountIn) public view override returns (uint256) {
        return (PRECISION.sub(getPercentageStaked(_amountIn))).div(2);
    }

    function getPercentageStaked(uint256 _amountIn) public view override returns (uint256) {
        uint256 locked = IDekaToken(DEKA_TOKEN).balanceOf(address(this)).add(_amountIn);
        return locked.mul(PRECISION).div(IDekaToken(DEKA_TOKEN).totalSupply());
    }

    function calculateMaxStakePeriod(uint256 _amountIn) public view override returns (uint256) {
        return MAX_DPY_FOR_1_YEAR.mul(SECONDS_IN_1_YEAR).div(getDPY(_amountIn));
    }

    function _calculateBurn(
        uint256 _amount,
        uint256 _remainingTime,
        uint256 _totalTime
    ) private pure returns (uint256) {
        return _amount.mul(_remainingTime).div(_totalTime);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IDekaToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);

    function burn(uint256 value) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IDekaReceiver {
    function receiveDeka(
        bytes32 id,
        uint256 amountIn,
        uint256 expireAfter,
        uint256 mintedAmount,
        address staker,
        bytes calldata data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IDekaProtocol {
    enum LockedFunctions { SET_MATCH_RATIO, SET_MATCH_RECEIVER }

    function TIMELOCK() external view returns (uint256);

    function DEKA_TOKEN() external view returns (address);

    function matchRatio() external view returns (uint256);

    function matchReceiver() external view returns (address);

    function stakes(bytes32 _id)
        external
        view
        returns (
            uint256 amountIn,
            uint256 expiry,
            uint256 expireAfter,
            uint256 mintedAmount,
            address staker,
            address receiver
        );

    function stake(
        uint256 _amountIn,
        uint256 _days,
        address _receiver,
        bytes calldata _data
    )
        external
        returns (
            uint256 mintedAmount,
            uint256 matchedAmount,
            bytes32 id
        );

    function lockFunction(LockedFunctions _lockedFunction) external;

    function unlockFunction(LockedFunctions _lockedFunction) external;

    function timelock(LockedFunctions _lockedFunction) external view returns (uint256);

    function balances(address _staker) external view returns (uint256);

    function unstake(bytes32 _id) external returns (uint256 withdrawAmount);

    function unstakeEarly(bytes32 _id) external returns (uint256 withdrawAmount);

    function getDPY(uint256 _amountIn) external view returns (uint256);

    function setMatchReceiver(address _newMatchReceiver) external;

    function setMatchRatio(uint256 _newMatchRatio) external;

    function getMatchedAmount(uint256 mintedAmount) external view returns (uint256);

    function getMintAmount(uint256 _amountIn, uint256 _expiry) external view returns (uint256);

    function getPercentageStaked(uint256 _amountIn) external view returns (uint256 percentage);

    function calculateMaxStakePeriod(uint256 _amountIn) external view returns (uint256);

    function stakeWithPermit(
        address _receiver,
        uint256 _amountIn,
        uint256 _expiry,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes calldata _data
    )
        external
        returns (
            uint256 mintedAmount,
            uint256 matchedAmount,
            bytes32 id
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:: ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:: SUB_UNDERFLOW");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MATH:: MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MATH:: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

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
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}