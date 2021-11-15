// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IDistributionLogic} from "../distribution/interface/IDistributionLogic.sol";
import {ITributaryRegistry} from "../interface/ITributaryRegistry.sol";
import {ITreasuryConfig} from "../interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../interface/IMirrorTreasury.sol";
import {Governable} from "../lib/Governable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract MirrorTreasury is IMirrorTreasury, Governable {
    // ============ Treasury Configuration ============

    // Used to pull the active distribution model.
    address public treasuryConfig;

    // ============ Tributary Registry ============

    // Used to find tributary addresses associated with Economic Producers.
    address public tributaryRegistry;

    // ============ Structs ============

    // Allows governance to execute generic functions.
    struct Call {
        // The target of the transaction.
        address target;
        // The value passed into the transaction.
        uint96 value;
        // Any data passed with the call.
        bytes data;
    }

    // ============ Events ============

    // Emitted when the treasury transfers ETH.
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Emitted when the treasury transfers an ERC20 token.
    event ERC20Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // ============ Constructor ============

    // NOTE: Once deployed, tributaryRegistry and treasuryConfig should be set.
    constructor(address owner_) Governable(owner_) {}

    // ============ Treasury Contributions ============

    /**
     * A safe, public function for making contributions to the treasury.
     * If a tributary is registered for the contributor, then governance
     * tokens will be allocated according to the active distribution model.
     */
    function contribute(uint256 amount) public payable override {
        require(msg.value == amount, "msg.value != amount");
        _allocateGovernance(msg.sender, amount);
    }

    // Allows directly contributing with a specify treasury, but the sender
    // must be registered as a "singleton producer" - e.g. auctions house.
    function contributeWithTributary(address tributary)
        public
        payable
        override
    {
        // Here we don't revert, but instead just don't allocate goverance
        // if the call isn't registered as an economic producer.
        if (
            ITributaryRegistry(tributaryRegistry).singletonProducer(msg.sender)
        ) {
            _allocateGovernanceToTributary(tributary, msg.value);
        }
    }

    /**
     * Allows receiving ETH, and can mint treasury governance tokens in
     * exchange. Uses a registry to specify which addresses are allowed
     * to receive gov tokens in exchange for contributing ETH.
     */
    receive() external payable {
        _allocateGovernance(msg.sender, msg.value);
    }

    // ============ Treasury Configuration ============

    function setTreasuryConfig(address treasuryConfig_) public onlyGovernance {
        treasuryConfig = treasuryConfig_;
    }

    // ============ Tributary Registry Configuration ============

    function setTributaryRegistry(address tributaryRegistry_)
        public
        onlyGovernance
    {
        tributaryRegistry = tributaryRegistry_;
    }

    // ============ Funds Administration ============

    function transferFunds(address payable to, uint256 value)
        external
        override
        onlyGovernance
    {
        _sendFunds(to, value);
        emit Transfer(address(this), to, value);
    }

    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyGovernance {
        IERC20(token).transfer(to, amount);
        emit ERC20Transfer(token, address(this), to, amount);
    }

    // ============ Generic Call Execution ============

    function executeGeneric(Call memory call) public onlyGovernance {
        (bool ok, ) = call.target.call{value: uint256(call.value)}(call.data);

        require(ok, "execute transaction failed");
    }

    // ============ Private Utils ============

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }

    function _allocateGovernance(address producer, uint256 amount) private {
        // Get the tributary that was registered for the given producer.
        address tributary = ITributaryRegistry(tributaryRegistry)
            .producerToTributary(producer);

        _allocateGovernanceToTributary(tributary, amount);
    }

    function _allocateGovernanceToTributary(address tributary, uint256 amount)
        private
    {
        // If there is a registered tributary to mint Mirror tokens for,
        // then, here, we go and mint those tokens! Else, just accept ETH, no sweat.
        if (tributary != address(0)) {
            address distributionModel = ITreasuryConfig(treasuryConfig)
                .distributionModel();

            IDistributionLogic(distributionModel).distribute(tributary, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IDistributionLogic {
    function version() external returns (uint256);

    function distribute(address tributary, uint256 contribution) external;

    function claim(address claimant) external;

    function claimable(address claimant) external view returns (uint256);

    function increaseAwards(address member, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITributaryRegistry {
    function addRegistrar(address registrar) external;

    function removeRegistrar(address registrar) external;

    function addSingletonProducer(address producer) external;

    function removeSingletonProducer(address producer) external;

    function registerTributary(address producer, address tributary) external;

    function producerToTributary(address producer)
        external
        returns (address tributary);

    function singletonProducer(address producer) external returns (bool);

    function changeTributary(address producer, address newTributary) external;
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

import {Ownable} from "../lib/Ownable.sol";
import {IGovernable} from "../lib/interface/IGovernable.sol";

contract Governable is Ownable, IGovernable {
    // ============ Mutable Storage ============

    // Mirror governance contract.
    address public override governor;

    // ============ Modifiers ============

    modifier onlyGovernance() {
        require(isOwner() || isGovernor(), "caller is not governance");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "caller is not governor");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_) Ownable(owner_) {}

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        governor = governor_;
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernable {
    function changeGovernor(address governor_) external;

    function isGovernor() external view returns (bool);

    function governor() external view returns (address);
}

