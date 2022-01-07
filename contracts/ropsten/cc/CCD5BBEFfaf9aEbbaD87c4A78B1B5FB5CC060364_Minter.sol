pragma solidity 0.8.7;

/***
 *@title Token Minter
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Used to mint InsureToken
 */

//dao-contracts
import "./interfaces/dao/IInsureToken.sol";
import "./interfaces/dao/ILiquidityGauge.sol";
import "./interfaces/dao/IGaugeController.sol";
import "./interfaces/dao/IEmergencyMintModule.sol";

//libraries
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Minter is ReentrancyGuard {
    event EmergencyMint(uint256 minted);
    event Minted(address indexed recipient, address gauge, uint256 minted);
    event SetAdmin(address admin);
    event SetConverter(address converter);

    IInsureToken public insure_token;
    IGaugeController public gauge_controller;
    IEmergencyMintModule public emergency_module;

    address public admin;

    // user -> gauge -> value
    mapping(address => mapping(address => uint256)) public minted; //INSURE minted amount of user from specific gauge.

    // minter -> user -> can mint?
    mapping(address => mapping(address => bool)) public allowed_to_mint_for; // A can mint for B if [A => B => true].

    constructor(address _token, address _controller) {
        insure_token = IInsureToken(_token);
        gauge_controller = IGaugeController(_controller);
        admin = msg.sender;
    }

    function _mint_for(address gauge_addr, address _for) internal {
        require(
            gauge_controller.gauge_types(gauge_addr) > 0,
            "dev: gauge is not added"
        );

        ILiquidityGauge(gauge_addr).user_checkpoint(_for);
        uint256 total_mint = ILiquidityGauge(gauge_addr).integrate_fraction(
            _for
        ); //Total amount of both mintable and minted.
        uint256 to_mint = total_mint - minted[_for][gauge_addr]; //mint amount for this time. (total_amount - minted = mintable)

        if (to_mint != 0) {
            insure_token.mint(_for, to_mint);
            minted[_for][gauge_addr] = total_mint;

            emit Minted(_for, gauge_addr, total_mint);
        }
    }

    function mint(address gauge_addr) external nonReentrant {
        /***
         *@notice Mint everything which belongs to `msg.sender` and send to them
         *@param gauge_addr `LiquidityGauge` address to get mintable amount from
         */

        _mint_for(gauge_addr, msg.sender);
    }

    function mint_many(address[8] memory gauge_addrs) external nonReentrant {
        /***
         *@notice Mint everything which belongs to `msg.sender` across multiple gauges
         *@param gauge_addrs List of `LiquidityGauge` addresses
         *@dev address[8]: 8 has randomly decided and has no meaning.
         */

        for (uint256 i; i < 8; i++) {
            if (gauge_addrs[i] == address(0)) {
                break;
            }
            _mint_for(gauge_addrs[i], msg.sender);
        }
    }

    function mint_for(address gauge_addr, address _for) external nonReentrant {
        /***
         *@notice Mint tokens for `_for`
         *@dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
         *@param gauge_addr `LiquidityGauge` address to get mintable amount from
         *@param _for Address to mint to
         */

        if (allowed_to_mint_for[msg.sender][_for]) {
            _mint_for(gauge_addr, _for);
        }
    }

    function toggle_approve_mint(address minting_user) external {
        /***
         *@notice allow `minting_user` to mint for `msg.sender`
         *@param minting_user Address to toggle permission for
         */

        allowed_to_mint_for[minting_user][msg.sender] = !allowed_to_mint_for[
            minting_user
        ][msg.sender];
    }

    //-----------------emergency mint-----------------/
    function set_admin(address _admin) external {
        /***
         *@notice Set the new admin.
         *@dev After all is set up, admin only can change the token name
         *@param _admin New admin address
         */
        require(msg.sender == admin, "dev: admin only");
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function set_emergency_mint_module(address _emergency_module) external {
        require(msg.sender == admin, "dev: admin only");
        emergency_module = IEmergencyMintModule(_emergency_module);
    }

    function emergency_mint(uint256 _mint_amount) external {
        /**
         *@param mint_amount amount of INSURE to be minted
         */
        require(msg.sender == address(emergency_module), "dev: admin only");

        //mint
        insure_token.emergency_mint(_mint_amount, address(emergency_module));

        emit EmergencyMint(_mint_amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IInsureToken {
    function mint(address _to, uint256 _value)external returns(bool);
    function emergency_mint(uint256 _amountOut, address _to)external;
    function approve(address _spender, uint256 _value)external;
    function rate()external view returns(uint256);
    function future_epoch_time_write() external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ILiquidityGauge {
    function user_checkpoint(address _addr) external returns (bool);

    function integrate_fraction(address _addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IGaugeController {
    function gauge_types(address _addr)external view returns(uint256);
    function get_voting_escrow()external view returns(address);
    function checkpoint_gauge(address addr)external;
    function gauge_relative_weight(address addr, uint256 time)external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IEmergencyMintModule {
    function mint(address _amount) external;

    function repayDebt() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}