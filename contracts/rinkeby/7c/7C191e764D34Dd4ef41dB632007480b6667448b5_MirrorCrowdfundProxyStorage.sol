// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IMirrorCrowdfundProxyStorage, IMirrorCrowdfundProxyStorageEvents} from "./interface/IMirrorCrowdfundProxyStorage.sol";
import {IERC721Events, IERC721Receiver} from "../../../external/interface/IERC721.sol";
import {IERC2309} from "../../../external/interface/IERC2309.sol";

/**
 * @title MirrorCrowdfundProxyStorage
 * @author MirrorXYZ
 */
contract MirrorCrowdfundProxyStorage is
    IMirrorCrowdfundProxyStorage,
    IMirrorCrowdfundProxyStorageEvents,
    IERC721Events,
    IERC2309
{
    // ============ Proxy data ============

    /// @notice Proxies to operator
    mapping(address => address) public override operator;

    // ============ Crowdfund Data ============

    mapping(address => uint256) internal nextCrowdfundId;

    mapping(address => mapping(uint256 => Crowdfund)) internal crowdfunds;

    // ============ Modifiers ============

    modifier onlyOperator(address proxy, address account) {
        require(operator[proxy] == account, "non approved");
        _;
    }

    // ============ Registry Methods ============

    /// @notice Register new proxy and create crowdfund
    function initializeAndCreateCrowdfund(
        address operator_,
        CrowdfundConfig memory crowdfund
    ) external override returns (uint256 crowdfundId) {
        address proxy = msg.sender;

        operator[proxy] = operator_;

        crowdfundId = _createCrowdfund(
            proxy,
            crowdfund.fundingCap,
            crowdfund.token,
            crowdfund.exchangeRate,
            crowdfund.faucet,
            crowdfund.fundingRecipient
        );
    }

    function createCrowdfund(address sender, CrowdfundConfig memory crowdfund)
        external
        override
        onlyOperator(msg.sender, sender)
        returns (uint256 crowdfundId)
    {
        address proxy = msg.sender;

        crowdfundId = _createCrowdfund(
            proxy,
            crowdfund.fundingCap,
            crowdfund.token,
            crowdfund.exchangeRate,
            crowdfund.faucet,
            crowdfund.fundingRecipient
        );
    }

    function contributeToCrowdfund(uint256 crowdfundId, uint256 amount)
        external
        override
    {
        address proxy = msg.sender;

        crowdfunds[proxy][crowdfundId].funding += amount;
        crowdfunds[proxy][crowdfundId].balance += amount;
    }

    function resetBalance(uint256 crowdfundId) external override {
        crowdfunds[msg.sender][crowdfundId].balance = 0;
    }

    function closeFunding(uint256 crowdfundId) external override {
        crowdfunds[msg.sender][crowdfundId].closed = true;
    }

    function getCrowdfund(address proxy, uint256 crowdfundId)
        external
        view
        override
        returns (Crowdfund memory)
    {
        return crowdfunds[proxy][crowdfundId];
    }

    // ============ Internal Methods ============
    function _createCrowdfund(
        address proxy,
        uint256 fundingCap,
        address token,
        uint256 exchangeRate,
        address faucet,
        address fundingRecipient
    ) internal returns (uint256 crowdfundId) {
        crowdfundId = nextCrowdfundId[proxy] + 1;

        crowdfunds[proxy][crowdfundId] = Crowdfund({
            fundingCap: fundingCap,
            token: token,
            exchangeRate: exchangeRate,
            faucet: faucet,
            fundingRecipient: fundingRecipient,
            balance: 0,
            funding: 0,
            closed: false
        });

        emit CrowdfundCreated(
            proxy,
            fundingCap,
            token,
            exchangeRate,
            faucet,
            crowdfundId,
            fundingRecipient
        );

        nextCrowdfundId[proxy] += 1;
    }
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

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
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