// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IMirrorCrowdfundRelayer, IMirrorCrowdfundRelayerEvents, IERC20} from "./interface/IMirrorCrowdfundRelayer.sol";
import {IMirrorCrowdfundProxyStorage, IMirrorCrowdfundProxyStorageEvents} from "./interface/IMirrorCrowdfundProxyStorage.sol";
import {ITreasuryConfig} from "../../../interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../../interface/IMirrorTreasury.sol";
import {Reentrancy} from "../../../lib/Reentrancy.sol";

/**
 * @title MirrorCrowdfundRelayer
 * @author MirrorXYZ
 * @notice This contract implements the logic for crowdfunding proxies. 
 */
contract MirrorCrowdfundRelayer is
    Reentrancy,
    IMirrorCrowdfundRelayer,
    IMirrorCrowdfundRelayerEvents,
    IMirrorCrowdfundProxyStorageEvents
{
    /// @notice The address for crowdfund storage
    address public immutable proxyStorage;

    /// @notice The address treasury configuration
    address public immutable treasuryConfig;

    /**
     * @notice Assign immutable proxy storage address.
     * @param proxyStorage_ - the address that holds the proxy's storage
     */
    constructor(
        address treasuryConfig_,
        address proxyStorage_
    ) {
        treasuryConfig = treasuryConfig_;
        proxyStorage = proxyStorage_;
    }

    function initializeAndCreateCrowdfund(
        address operator_,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external override returns (uint256 crowdfundId) {
        // Ensure that this function is only callable during contract deployment
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }
        
        // register crowdfund
        crowdfundId = IMirrorCrowdfundProxyStorage(proxyStorage).initializeAndCreateCrowdfund(
            operator_,
            crowdfund
        );

    }

    function createCrowdfund(
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external override returns (uint256 crowdfundId) {
        // create crowdfund
        crowdfundId = IMirrorCrowdfundProxyStorage(proxyStorage).createCrowdfund(
            msg.sender,
            crowdfund
        );
    }

    function operator() external view override returns (address) {
        return IMirrorCrowdfundProxyStorage(proxyStorage).operator(address(this));
    }

    // ============ Crowdfund Methods ============

    /**
     * @notice Used to contirbute to a crowdfund. This function automatically rejects funding
     * when the funding cap is met, regardless of crowdfund status (open/closed).
     */
    function contributeToCrowdfund(
        uint256 crowdfundId,
        address backer
    ) external payable {
        require(msg.value > 0, "value must be greater than 0");

        IMirrorCrowdfundProxyStorage.Crowdfund memory crowdfund = IMirrorCrowdfundProxyStorage(
            proxyStorage
        ).getCrowdfund(address(this), crowdfundId);

        require(!crowdfund.closed || crowdfund.funding < crowdfund.fundingCap, "funding closed");

        // calculate contribution amount
        uint256 contributionAmount = msg.value;
        uint256 refundAmount = 0;
        uint256 fundsAfterContribution = msg.value + crowdfund.funding;

        if (fundsAfterContribution > crowdfund.fundingCap) {
            contributionAmount = crowdfund.fundingCap - crowdfund.funding;
            refundAmount = msg.value - contributionAmount;
        }

        // contribute
        IMirrorCrowdfundProxyStorage(
            proxyStorage
        ).contributeToCrowdfund(crowdfundId, contributionAmount);

        // send tokens
        if (crowdfund.token != address(0)) {
            uint256 tokenAmount = contributionAmount * crowdfund.exchangeRate;
            IERC20(crowdfund.token).transferFrom(crowdfund.faucet, backer, tokenAmount);
        }

        // send refund
        if (refundAmount > 0) {
            _send(payable(msg.sender), refundAmount);
        }

        emit CrowdfundContribution(crowdfundId, backer, contributionAmount);
    }

    /**
     * @notice Close funding is only necessary when funding cap is not met and the
     * operator wished to close funding. It automatically withdraws all the funds and
     * pays the fee to the treasury. If funding cap is met, the operator can simply call
     * withdraw.
     */
    function closeFunding(uint256 crowdfundId, uint256 feePercentage_) external override Reentrancy.nonReentrant {
        address operator_ = IMirrorCrowdfundProxyStorage(proxyStorage).operator(address(this));

        require(msg.sender == operator_, "not operator");

        // Only necessary when closing funding before funding cap is met.
        IMirrorCrowdfundProxyStorage(proxyStorage).closeFunding(crowdfundId);

        _withdraw(crowdfundId, feePercentage_);
    }
    
    // ============ Relayer Only Methods ============

    /**
     * @notice Withdraws funds on the current proxy to the operator,
     * and transfer fee to treasury.
     */
    function withdraw(uint256 crowdfundId, uint256 feePercentage) external override Reentrancy.nonReentrant {
        _withdraw(crowdfundId, feePercentage);
    }

    function feeAmount(uint256 amount, uint256 fee)
        public
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    // ============ Internal Methods ============
    function _withdraw(uint256 crowdfundId, uint256 feePercentage_) internal {
        require(feePercentage_ >= 250, "fee must be >= 2.5%");

        IMirrorCrowdfundProxyStorage.Crowdfund memory crowdfund = IMirrorCrowdfundProxyStorage(proxyStorage)
            .getCrowdfund(address(this), crowdfundId);

        uint256 fee = feeAmount(crowdfund.balance, feePercentage_);

        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury()).contribute{
            value: fee
        }(fee);

        // transfer the remaining available balance to the operator.
        uint256 withdrawalAmount = crowdfund.balance - fee;
        _send(payable(crowdfund.fundingRecipient), withdrawalAmount);

        // reset balance
        IMirrorCrowdfundProxyStorage(proxyStorage).resetBalance(crowdfundId);

        emit Withdrawal(
            crowdfundId,
            crowdfund.fundingRecipient,
            withdrawalAmount,
            fee
        );
    }

    function _send(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IMirrorCrowdfundProxyStorage} from "./IMirrorCrowdfundProxyStorage.sol";

interface IMirrorCrowdfundRelayerEvents {
    event CrowdfundContribution(
        uint256 indexed crowdfundId,
        address indexed backer,
        uint256 contributionAmount
    );

    event Withdrawal(
        uint256 indexed crowdfundId,
        address indexed fundingRecipient,
        uint256 amount,
        uint256 fee
    );
}

interface IMirrorCrowdfundRelayer {
    function initializeAndCreateCrowdfund(
        address operator_,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function createCrowdfund(
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function operator() external view returns (address);

    function closeFunding(uint256 crowdfundId, uint256 feePercentage_) external;

    function withdraw(uint256 crowdfundId, uint256 feePercentage) external;
}

interface IERC20 {
    /// @notice EIP-20 transfer _value_ to _to_ from _from_
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorCrowdfundProxyStorageEvents {
    /// @notice Emitted when a new proxy is registered
    event NewCrowdfundProxy(address indexed proxy, address indexed operator);

    /// @notice Create edition
    event CrowdfundCreated(
        address indexed proxy,
        uint256 fundingCap,
        address token,
        uint256 exchangeRate,
        address faucet,
        uint256 indexed crowdfundId,
        address indexed fundingRecipient
    );
}

interface IMirrorCrowdfundProxyStorage {
    struct Crowdfund {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        uint256 funding;
        address fundingRecipient;
        uint256 balance;
        bool closed;
    }

    struct CrowdfundConfig {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        address fundingRecipient;
    }

    function operator(address account) external view returns (address);

    function initializeAndCreateCrowdfund(
        address operator_,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function createCrowdfund(
        address sender,
        IMirrorCrowdfundProxyStorage.CrowdfundConfig memory crowdfund
    ) external returns (uint256 crowdfundId);

    function contributeToCrowdfund(uint256 crowdfundId, uint256 amount)
        external;

    function getCrowdfund(address proxy, uint256 crowdfundId)
        external
        view
        returns (Crowdfund memory);

    function resetBalance(uint256 crowdfundId) external;

    function closeFunding(uint256 crowdfundId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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