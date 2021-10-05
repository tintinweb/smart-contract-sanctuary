// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC20} from "../../../lib/erc20-proxy/interface/IERC20.sol";
import {IERC20Events} from "../../../external/interface/IERC20.sol";
import {MirrorProxy} from "../MirrorProxy.sol";
import {IMirrorERC20ProxyStorage} from "../../../lib/erc20-proxy/interface/IMirrorERC20ProxyStorage.sol";
import {IMirrorERC20FactoryEvents} from "../../../lib/erc20-proxy/interface/IMirrorERC20Factory.sol";
import {IMirrorERC20RelayerEvents} from "../../../lib/erc20-proxy/interface/IMirrorERC20Relayer.sol";
import {IMirrorCrowdfundProxyStorageEvents} from "../crowdfund/interface/IMirrorCrowdfundProxyStorage.sol";
import {ITributaryRegistry} from "../../../interface/ITributaryRegistry.sol";
import {IMirrorCrowdfundRelayer} from "../crowdfund/interface/IMirrorCrowdfundRelayer.sol";
import {IMirrorFactoryEvents} from "../interface/IMirrorFactory.sol";
import {IMirrorTokenAndCrowdfundFactory} from "./interface/IMirrorTokenAndCrowdfundFactory.sol";

/**
 * @title MirrorTokenAndCrowdfundFactory
 * @author MirrorXYZ
 */
contract MirrorTokenAndCrowdfundFactory is
    IMirrorTokenAndCrowdfundFactory,
    IMirrorFactoryEvents,
    IMirrorERC20FactoryEvents,
    IMirrorERC20RelayerEvents,
    IMirrorCrowdfundProxyStorageEvents,
    IERC20Events
{
    /// @notice Address that holds the relay logic for proxies
    address public immutable erc20Relayer;
    address public immutable crowdfundRelayer;

    address immutable tributaryRegistry;

    //======== Constructor =========

    constructor(
        address erc20Relayer_,
        address crowdfundRelayer_,
        address tributaryRegistry_
    ) {
        erc20Relayer = erc20Relayer_;
        crowdfundRelayer = crowdfundRelayer_;
        tributaryRegistry = tributaryRegistry_;
    }

    //======== Deploy function =========

    /**
     * @notice Deploys token proxy, crowdfund proxy, creates a
     * crowdfund and set allowance. This function should be used
     * when neither the token nor the crowdfund have been deployed.
     */
    function deployTokenAndCrowdfundWithPermit(
        TokenConfig memory tokenConfig,
        CrowdfundConfig memory crowdfundConfig,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // Set the owner of the crowdfund and token.
        address payable operator = payable(msg.sender);

        // Deploy Token
        address token = _deployToken(
            operator,
            tokenConfig.name,
            tokenConfig.symbol,
            tokenConfig.totalSupply,
            tokenConfig.decimals
        );

        // Deploy and initialize the crowdfund.
        address crowdfund = _deployAndCreateCrowdfund(
            crowdfundConfig.tributary,
            crowdfundConfig.fundingCap,
            crowdfundConfig.exchangeRate,
            crowdfundConfig.fundingRecipient,
            crowdfundConfig.faucet,
            token
        );

        // Set allowance on the token for the crowdfund
        _setAllowance(
            token,
            operator,
            crowdfund,
            crowdfundConfig.fundingCap * crowdfundConfig.exchangeRate,
            v,
            r,
            s
        );
    }

    /**
     * @notice Deploys crowdfund proxy, creates a crowdfund and
     * set allowance. This function should be used when a token is
     * already deployed.
     */
    function deployCrowdfundWithPermit(
        CrowdfundConfig memory crowdfundConfig,
        address token,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        address payable operator = payable(msg.sender);

        address proxy = _deployAndCreateCrowdfund(
            crowdfundConfig.tributary,
            crowdfundConfig.fundingCap,
            crowdfundConfig.exchangeRate,
            crowdfundConfig.fundingRecipient,
            crowdfundConfig.faucet,
            token
        );

        // Set allowance on the token for the crowdfund
        _setAllowance(
            token,
            operator,
            proxy,
            crowdfundConfig.fundingCap * crowdfundConfig.exchangeRate,
            v,
            r,
            s
        );
    }

    /**
     * @notice Deploys token proxy, set allowance. This function should
     * be used when a crowdfund is already deployed.
     */
    function deployTokenWithPermit(
        TokenConfig memory tokenConfig,
        address crowdfundProxy,
        uint256 fundingCap,
        uint256 exchangeRate,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // Set the owner of the crowdfund and token.
        address payable operator = payable(msg.sender);

        // Deploy Token
        address token = _deployToken(
            operator,
            tokenConfig.name,
            tokenConfig.symbol,
            tokenConfig.totalSupply,
            tokenConfig.decimals
        );

        // Set allowance on the token for the crowdfund
        _setAllowance(
            token,
            operator,
            crowdfundProxy,
            fundingCap * exchangeRate,
            v,
            r,
            s
        );
    }

    /// @notice Deploy and initialize a token proxy.
    function _deployToken(
        address payable operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) private returns (address erc20Proxy) {
        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorERC20ProxyStorage.initialize.selector,
            operator_,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        erc20Proxy = address(
            new MirrorProxy{
                salt: keccak256(abi.encode(operator_, name_, symbol_))
            }(erc20Relayer, initializationData)
        );

        emit ERC20ProxyDeployed(erc20Proxy, name_, symbol_, operator_);
    }

    /**
     * @notice Deploys a crowdfund proxy, creates a crowdfund, and
     * registers the new proxies tributary. Emits a MirrorProxyDeployed
     * event with the crowdfund-relayer address.
     */
    function _deployAndCreateCrowdfund(
        address tributary,
        uint256 fundingCap,
        uint256 exchangeRate,
        address fundingRecipient,
        address faucet,
        address token
    ) private returns (address proxy) {
        address operator = msg.sender;

        Crowdfund memory crowdfund = Crowdfund({
            fundingCap: fundingCap,
            token: token,
            exchangeRate: exchangeRate,
            faucet: faucet,
            fundingRecipient: fundingRecipient
        });

        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorCrowdfundRelayer.initializeAndCreateCrowdfund.selector,
            operator,
            crowdfund
        );

        proxy = address(
            new MirrorProxy{salt: keccak256(abi.encode(operator))}(
                crowdfundRelayer,
                initializationData
            )
        );

        emit MirrorProxyDeployed(proxy, operator, crowdfundRelayer);

        ITributaryRegistry(tributaryRegistry).registerTributary(
            proxy,
            tributary
        );
    }

    /// @notice Set allowance using the permit function.
    function _setAllowance(
        address token,
        address owner,
        address proxy,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        IERC20(token).permit(owner, proxy, value, type(uint256).max, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IERC20 {
    function operator() external view returns (address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IERC20 {
    /// @notice EIP-20 token name for this token
    function name() external returns (string calldata);

    /// @notice EIP-20 token symbol for this token
    function symbol() external returns (string calldata);

    /// @notice EIP-20 token decimals for this token
    function decimals() external returns (uint8);

    /// @notice EIP-20 total number of tokens in circulation
    function totalSupply() external returns (uint256);

    /// @notice EIP-20 official record of token balances for each account
    function balanceOf(address account) external returns (uint256);

    /// @notice EIP-20 allowance amounts on behalf of others
    function allowance(address owner, address spender)
        external
        returns (uint256);

    /// @notice EIP-20 approves _spender_ to transfer up to _value_ multiple times
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice EIP-20 transfer _value_ to _to_ from _msg.sender_
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice EIP-20 transfer _value_ to _to_ from _from_
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Events {
    /// @notice EIP-20 Mint event
    event Mint(address indexed to, uint256 amount);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MirrorProxy
 * @author MirrorXYZ
 * The MirrorProxy contract is used to deploy minimal contracts for multiple
 * economic producers on the Mirror ecosystem (e.g. crowdfunds, editions). The
 * proxies are used with the proxy-relayer pattern. The proxy delegates calls
 * to a relayer contract that calls into the storage contract. The proxy uses the
 * EIP-1967 standard to store the "implementation" logic, which in our case is
 * the relayer contract. The relayer logic is directly stored into the standard
 * slot using `sstore` in the constructor, and read using `sload` in the fallback
 * function.
 */
contract MirrorProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Initializes a proxy by delegating logic to the relayer,
     * and reverts if the call is not successful. Stores relayer logic.
     * @param relayer - the relayer holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address relayer, bytes memory initializationData) {
        // Delegatecall into the relayer, supplying initialization calldata.
        (bool ok, ) = relayer.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, relayer)
        }
    }

    /**
     * @notice When any function is called on this contract, we delegate to
     * the logic contract stored in the implementation storage slot.
     */
    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorERC20ProxyStorage {
    function operator() external view returns (address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(
        address sender,
        address spender,
        uint256 value
    ) external returns (bool);

    function transfer(
        address sender,
        address to,
        uint256 value
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function mint(
        address sender,
        address to,
        uint256 amount
    ) external;

    function setOperator(address sender, address newOperator) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorERC20FactoryEvents {
    event ERC20ProxyDeployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IMirrorERC20Factory {
    /// @notice Deploy a new proxy
    function deploy(
        address payable operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address erc20Proxy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorERC20RelayerEvents {
    /// @notice Emitted when a new proxy is registered
    event NewProxy(address indexed proxy, address indexed operator);
}

interface IMirrorERC20Relayer {
    function operator() external view returns (address);

    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external;

    function mint(address to, uint256 value) external;
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

import {IMirrorEditionsProxyStorage} from "../editions/interface/IMirrorEditionsProxyStorage.sol";
import {IMirrorCrowdfundEditionsProxyStorage} from "../crowdfund-editions/interface/IMirrorCrowdfundEditionsProxyStorage.sol";
import {IMirrorDroppableEditionsProxyStorage} from "../droppable-editions/interface/IMirrorDroppableEditionsProxyStorage.sol";

interface IMirrorFactoryEvents {
    event Upgraded(address indexed implementation);

    event MirrorProxyDeployed(address proxy, address operator, address relayer);
}

interface IMirrorFactory {
    struct TributaryConfig {
        address tributary;
        uint256 feePercentage;
    }

    struct EditionConfig {
        string name;
        string symbol;
        string baseURI;
    }

    struct CrowdfundConfig {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        address fundingRecipient;
    }

    struct DroppableEditionConfig {
        string name;
        string symbol;
        string baseURI;
    }

    function counter(address account) external returns (uint256);

    function deployAndCreateEditions(
        TributaryConfig calldata tributaryConfig,
        EditionConfig calldata editionConfig,
        IMirrorEditionsProxyStorage.EditionTier[] memory tiers
    ) external returns (address proxy);

    function deployAndCreateCrowdfundWithEditions(
        TributaryConfig calldata tributaryConfig,
        EditionConfig calldata editionConfig,
        IMirrorCrowdfundEditionsProxyStorage.CrowdfundConfig memory crowdfund,
        IMirrorCrowdfundEditionsProxyStorage.EditionTier[] memory tiers
    ) external returns (address proxy);

    function deployAndCreateCrowdfund(
        TributaryConfig memory tributaryConfig,
        CrowdfundConfig memory crowdfund
    ) external returns (address proxy);

    function deployAndCreateDroppableEdition(
        TributaryConfig memory tributaryConfig,
        EditionConfig memory editionConfig,
        IMirrorDroppableEditionsProxyStorage.EditionTier memory tier
    ) external returns (address proxy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorTokenAndCrowdfundFactory {
    struct Crowdfund {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        address fundingRecipient;
    }

    struct TokenConfig {
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
    }

    struct CrowdfundConfig {
        uint256 fundingCap;
        uint256 exchangeRate;
        address fundingRecipient;
        address tributary;
        address faucet;
    }

    function deployTokenAndCrowdfundWithPermit(
        TokenConfig memory tokenConfig,
        CrowdfundConfig memory crowdfundConfig,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deployCrowdfundWithPermit(
        CrowdfundConfig memory crowdfundConfig,
        address token,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deployTokenWithPermit(
        TokenConfig memory tokenConfig,
        address crowdfundProxy,
        uint256 fundingCap,
        uint256 exchangeRate,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorEditionsProxyStorageEvents {
    /// @notice Emitted when a new proxy is registered
    event NewEditionProxy(address indexed proxy, address indexed operator);

    /// @notice Create edition
    event EditionCreated(uint256 quantity, uint256 price, uint256 editionId);

    event EditionPurchased(
        uint256 editionId,
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );
}

interface IMirrorEditionsProxyStorage {
    struct Edition {
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
        uint256 numSold;
        bool paused;
        uint256 balance;
        address fundingRecipient;
        uint256 startTokenId;
    }

    struct EditionTier {
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
        bool paused;
        address fundingRecipient;
    }

    function operator(address account) external view returns (address);

    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) external;

    function initializeAndCreateEditions(
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        EditionTier[] memory tiers
    ) external;

    function getEdition(address proxy, uint256 editionId)
        external
        view
        returns (Edition memory);

    /// @notice Create edition
    function createEditions(address sender, EditionTier[] memory tiers)
        external;

    function unpause(address sender, uint256 editionId) external;

    function pause(address sender, uint256 editionId) external;

    function resetBalance(uint256 editionId) external;

    function purchase(
        uint256 editionId,
        address sender,
        address recipient
    ) external returns (uint256 tokenId);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function approve(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function transferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorCrowdfundEditionsProxyStorageEvents {
    /// @notice Emitted when a new proxy is registered
    event NewCrowdfundProxy(address indexed proxy, address indexed operator);

    /// @notice Create edition
    event EditionCreated(
        uint256 quantity,
        uint256 price,
        uint256 editionId,
        uint256 crowdfundId
    );

    event EditionPurchased(
        uint256 editionId,
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver,
        uint256 crowdfundId
    );

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

interface IMirrorCrowdfundEditionsProxyStorage {
    struct Edition {
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
        uint256 numSold;
        uint256 crowdfundId;
        bool paused;
        uint256 startTokenId;
    }

    struct EditionTier {
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
        bool paused;
    }

    struct Crowdfund {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        uint256 funding;
        address fundingRecipient;
        uint256 balance;
    }

    struct CrowdfundConfig {
        uint256 fundingCap;
        address token;
        uint256 exchangeRate;
        address faucet;
        address fundingRecipient;
    }

    function operator(address account) external view returns (address);

    function initializeAndCreateCrowdfundWithEditions(
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        IMirrorCrowdfundEditionsProxyStorage.CrowdfundConfig memory crowdfund,
        IMirrorCrowdfundEditionsProxyStorage.EditionTier[] memory tiers
    ) external returns (uint256 crowdfundId);

    function contributeToCrowdfund(uint256 crowdfundId, uint256 amount)
        external;

    function getCrowdfund(address proxy, uint256 crowdfundId)
        external
        view
        returns (Crowdfund memory);

    function getEdition(address proxy, uint256 editionId)
        external
        view
        returns (Edition memory);

    /// @notice Create edition
    function createEditions(
        address sender,
        EditionTier[] memory tiers,
        uint256 crowdfundId
    ) external;

    function resetBalance(uint256 crowdfundId) external;

    function unpause(address sender, uint256 editionId) external;

    function pause(address sender, uint256 editionId) external;

    function purchase(
        uint256 editionId,
        address sender,
        address recipient,
        uint256 crowdfundId
    ) external returns (uint256 tokenId);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function approve(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function transferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorDroppableEditionsProxyStorageEvents {
    /// @notice Emitted when a new proxy is registered
    event NewEditionProxy(address indexed proxy, address indexed operator);

    event EditionPurchased(
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );
}

interface IMirrorDroppableEditionsProxyStorage {
    struct Edition {
        uint256 quantity;
        uint256 price;
        uint256 allocation;
        bytes32 root;
        bytes32 contentHash;
        bool paused;
        uint256 numSold;
    }

    struct EditionTier {
        uint256 quantity;
        uint256 price;
        uint256 allocation;
        bytes32 root;
        bytes32 contentHash;
        bool paused;
        address fundingRecipient;
    }

    function operator(address account) external view returns (address);

    function fundingRecipients(address account) external view returns (address);

    /// @notice Register new proxy and initialize metadata
    function initializeAndCreateEdition(
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        EditionTier memory tier
    ) external;

    function getEdition(address proxy) external view returns (Edition memory);

    function purchase(address sender, address recipient)
        external
        returns (uint256 tokenId);

    function purchaseWithProof(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function approve(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function transferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
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