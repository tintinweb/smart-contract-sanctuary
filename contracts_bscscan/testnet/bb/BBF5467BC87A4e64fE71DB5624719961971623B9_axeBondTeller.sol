// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IsAXE.sol";

import "./types/AccessControlled.sol";

contract axeBondTeller is AccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsAXE;

    /* ========== EVENTS =========== */

    event BondCreated(address indexed bonder, uint256 payout, uint256 expires);
    event Redeemed(address indexed bonder, uint256 payout);

    /* ========== MODIFIERS ========== */

    modifier onlyDepository() {
        require(msg.sender == depository, "Only depository");
        _;
    }

    /* ========== STRUCTS ========== */

    // Info for bond holder
    struct Bond {
        address principal; // token used to pay for bond
        uint256 principalPaid; // amount of principal token paid for bond
        uint256 payout; // sAXE remaining to be paid. agnostic balance
        uint256 vested; // Block when bond is vested
        uint256 created; // time bond was created
        uint256 redeemed; // time bond was redeemed
    }

    /* ========== STATE VARIABLES ========== */

    address internal immutable depository; // contract where users deposit bonds
    IStaking internal immutable staking; // contract to stake payout
    ITreasury internal immutable treasury;
    IERC20 internal immutable AXE;
    IsAXE internal immutable sAXE; // payment token

    mapping(address => Bond[]) public bonderInfo; // user data
    mapping(address => uint256[]) public indexesFor; // user bond indexes

    mapping(address => uint256) public FERs; // front end operator rewards
    uint256 public feReward;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _depository,
        address _staking,
        address _treasury,
        address _AXE,
        address _sAXE,
        address _authority
    ) AccessControlled(IAuthority(_authority)) {
        require(_depository != address(0), "Zero address: Depository");
        depository = _depository;
        require(_staking != address(0), "Zero address: Staking");
        staking = IStaking(_staking);
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_AXE != address(0), "Zero address: AXE");
        AXE = IERC20(_AXE);
        require(_sAXE != address(0), "Zero address: sAXE");
        sAXE = IsAXE(_sAXE);
    }

    /* ========== DEPOSITORY FUNCTIONS ========== */

    /**
     * @notice add new bond payout to user data
     * @param _bonder address
     * @param _principal address
     * @param _principalPaid uint256
     * @param _payout uint256
     * @param _expires uint256
     * @param _feo address
     * @return index_ uint256
     */
    function newBond(
        address _bonder,
        address _principal,
        uint256 _principalPaid,
        uint256 _payout,
        uint256 _expires,
        address _feo
    ) external onlyDepository returns (uint256 index_) {
        uint256 reward = _payout.mul(feReward).div(10_000);
        treasury.mint(address(this), _payout.add(reward));

        AXE.approve(address(staking), _payout);
        staking.stake(address(this), _payout);

        FERs[_feo] = FERs[_feo].add(reward); // front end operator reward

        index_ = bonderInfo[_bonder].length;

        // store bond & stake payout
        bonderInfo[_bonder].push(
            Bond({
                principal: _principal,
                principalPaid: _principalPaid,
                payout: _payout,
                vested: _expires,
                created: block.timestamp,
                redeemed: 0
            })
        );
    }

    /* ========== INTERACTABLE FUNCTIONS ========== */

    /**
     *  @notice redeems all redeemable bonds
     *  @param _bonder address
     *  @return uint256
     */
    function redeemAll(address _bonder) external returns (uint256) {
        updateIndexesFor(_bonder);
        return redeem(_bonder, indexesFor[_bonder]);
    }

    /**
     *  @notice redeem bond for user
     *  @param _bonder address
     *  @param _indexes calldata uint256[]
     *  @return uint256
     */
    function redeem(address _bonder, uint256[] memory _indexes) public returns (uint256) {
        uint256 dues;
        for (uint256 i = 0; i < _indexes.length; i++) {
            Bond memory info = bonderInfo[_bonder][_indexes[i]];

            if (pendingFor(_bonder, _indexes[i]) != 0) {
                bonderInfo[_bonder][_indexes[i]].redeemed = block.timestamp; // mark as redeemed

                dues = dues.add(info.payout);
            }
        }

        emit Redeemed(_bonder, dues);
        pay(_bonder, dues);
        return dues;
    }

    // pay reward to front end operator
    function getReward() external {
        uint256 reward = FERs[msg.sender];
        FERs[msg.sender] = 0;
        AXE.transfer(msg.sender, reward);
    }

    /* ========== OWNABLE FUNCTIONS ========== */

    // set reward for front end operator (4 decimals. 100 = 1%)
    function setFEReward(uint256 reward) external onlyGovernor {
        feReward = reward;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     *  @notice send payout
     *  @param _amount uint256
     */
    function pay(address _bonder, uint256 _amount) internal {
        sAXE.transfer(_bonder, _amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     *  @notice returns indexes of live bonds
     *  @param _bonder address
     */
    function updateIndexesFor(address _bonder) public {
        Bond[] memory info = bonderInfo[_bonder];
        delete indexesFor[_bonder];
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0) {
                indexesFor[_bonder].push(i);
            }
        }
    }

    // PAYOUT

    /**
     * @notice calculate amount of AXE available for claim for single bond
     * @param _bonder address
     * @param _index uint256
     * @return uint256
     */
    function pendingFor(address _bonder, uint256 _index) public view returns (uint256) {
        if (bonderInfo[_bonder][_index].redeemed == 0 && bonderInfo[_bonder][_index].vested <= block.number) {
            return bonderInfo[_bonder][_index].payout;
        }
        return 0;
    }

    /**
     * @notice calculate amount of AXE available for claim for array of bonds
     * @param _bonder address
     * @param _indexes uint256[]
     * @return pending_ uint256
     */
    function pendingForIndexes(address _bonder, uint256[] memory _indexes) public view returns (uint256 pending_) {
        for (uint256 i = 0; i < _indexes.length; i++) {
            pending_ = pending_.add(pendingFor(_bonder, i));
        }
    }

    /**
     *  @notice total pending on all bonds for bonder
     *  @param _bonder address
     *  @return pending_ uint256
     */
    function totalPendingFor(address _bonder) public view returns (uint256 pending_) {
        Bond[] memory info = bonderInfo[_bonder];
        for (uint256 i = 0; i < info.length; i++) {
            pending_ = pending_.add(pendingFor(_bonder, i));
        }
    }

    // VESTING

    /**
     * @notice calculate how far into vesting a depositor is
     * @param _bonder address
     * @param _index uint256
     * @return percentVested_ uint256
     */
    function percentVestedFor(address _bonder, uint256 _index) public view returns (uint256 percentVested_) {
        Bond memory bond = bonderInfo[_bonder][_index];

        uint256 timeSince = block.timestamp.sub(bond.created);
        uint256 term = bond.vested.sub(bond.created);

        percentVested_ = timeSince.mul(1e9).div(term);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthority.sol";

abstract contract AccessControlled {
    event AuthorityUpdated(IAuthority indexed authority);
    string UNAUTHORIZED = "UNAUTHORIZED";
    IAuthority public authority;
    constructor(IAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    modifier onlyGovernor() {
        require(msg.sender == authority.get('governor'), UNAUTHORIZED);
        _;
    }
    modifier onlyTreasury() {
        require(msg.sender == authority.get('treasury'), UNAUTHORIZED);
        _;
    }
    modifier onlyStaking() {
        require(msg.sender == authority.get('staking'), UNAUTHORIZED);
        _;
    }
    function setAuthority(IAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./IERC20.sol";
interface IsAXE is IERC20 {
    function rebase( uint256 profit_, uint epoch_) external returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function gonsForBalance( uint amount ) external view returns ( uint );
    function balanceForGons( uint gons ) external view returns ( uint );
    function index() external view returns ( uint );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(uint256 _amount, address _token, uint256 _profit) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IStaking {
    function stake(address _to, uint256 _amount) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function unstake(address _to, uint256 _amount) external returns (uint256);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
interface IAuthority {
    function get(string memory _role) external view returns (address);
}