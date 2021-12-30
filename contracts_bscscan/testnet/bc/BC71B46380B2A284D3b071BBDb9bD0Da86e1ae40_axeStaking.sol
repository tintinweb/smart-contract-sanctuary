// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/SafeERC20.sol";
import "./types/AccessControlled.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IsAXE.sol";

contract axeStaking is AccessControlled {

    using SafeERC20 for IERC20;
    using SafeERC20 for IsAXE;

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable AXE;
    IsAXE public immutable sAXE;
    Epoch public epoch;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _authority,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime
    ) AccessControlled(IAuthority(_authority)) {
        AXE = IERC20(authority.get('axe'));
        sAXE = IsAXE(authority.get('saxe'));
        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake AXE to enter warmup
     * @param _to address
     * @param _amount uint
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount
    ) external returns (uint256) {
        AXE.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 bounty = rebase();
        return _send(_to, _amount + bounty);
    }

    /**
     * @notice redeem sAXE for AXEs
     * @param _to address
     * @param _amount uint
     * @return amount_ uint
     */
    function unstake(
        address _to,
        uint256 _amount
    ) external returns (uint256 amount_) {
        uint256 bounty = rebase();
        amount_ = _amount + bounty;
        sAXE.safeTransferFrom(msg.sender, address(this), _amount);
        require(_amount <= AXE.balanceOf(address(this)), "Insufficient AXE balance in contract");
        AXE.safeTransfer(_to, _amount);
    }

    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        if (epoch.end <= block.timestamp) {
            sAXE.rebase(epoch.distribute, epoch.number);
            epoch.end = epoch.end + epoch.length;
            epoch.number++;
            uint256 balance = AXE.balanceOf(address(this));
            uint256 staked = sAXE.circulatingSupply();
            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
        return 0;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sAXE or gAXE
     * @param _to address
     * @param _amount uint
     */
    function _send(
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        sAXE.safeTransfer(_to, _amount); // send as sAXE (equal unit as AXE)
        return _amount;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the sAXE index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return sAXE.index();
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        return epoch.end - block.timestamp;
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