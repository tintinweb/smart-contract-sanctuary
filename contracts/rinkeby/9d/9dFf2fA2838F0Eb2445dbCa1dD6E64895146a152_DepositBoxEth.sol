// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBoxEth.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../DepositBox.sol";
import "../../Messages.sol";


// This contract runs on the main net and accepts deposits
contract DepositBoxEth is DepositBox {

    using SafeMathUpgradeable for uint;

    // uint256 public gasConsumption;

    mapping(bytes32 => address) public tokenManagerEthAddresses;

    mapping(address => uint256) public approveTransfers;

    mapping(bytes32 => uint256) public transferredAmount;

    modifier rightTransaction(string memory schainName) {
        require(
            keccak256(abi.encodePacked(schainName)) != keccak256(abi.encodePacked("Mainnet")),
            "SKALE chain name is incorrect"
        );
        _;
    }

    receive() external payable {
        revert("Use deposit function");
    }

    /**
     * @dev Adds a TokenManagerEth address to
     * DepositBoxEth.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or contract owner
     * = or imaLinker contract.
     * - SKALE chain must not already be added.
     * - TokenManager address must be non-zero.
     */
    function addSchainContract(string calldata schainName, address newTokenManagerEthAddress) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(DEPOSIT_BOX_MANAGER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller"
        );
        require(tokenManagerEthAddresses[schainHash] == address(0), "SKALE chain is already set");
        require(newTokenManagerEthAddress != address(0), "Incorrect Token Manager address");

        tokenManagerEthAddresses[schainHash] = newTokenManagerEthAddress;
    }

    /**
     * @dev Allows Owner to remove a TokenManagerEth on SKALE chain
     * from DepositBoxEth.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or contract owner
     * - SKALE chain must already be set.
     */
    function removeSchainContract(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(DEPOSIT_BOX_MANAGER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller"
        );
        require(tokenManagerEthAddresses[schainHash] != address(0), "SKALE chain is not set");

        delete tokenManagerEthAddresses[schainHash];
    }

    function deposit(string memory schainName, address to)
        external
        payable
        whenNotKilled(keccak256(abi.encodePacked(schainName)))
        // receivedEth
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        address tokenManagerAddress = tokenManagerEthAddresses[schainHash];
        require(tokenManagerAddress != address(0), "Unconnected chain");
        require(to != address(0), "Community Pool is not available");
        if (!linker.interchainConnections(schainHash))
            _saveTransferredAmount(schainHash, msg.value);
        messageProxy.postOutgoingMessage(
            schainHash,
            tokenManagerAddress,
            Messages.encodeTransferEthMessage(to, msg.value)
        );
    }

    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        override
        onlyMessageProxy
        whenNotKilled(schainHash)
        returns (address)
    {
        require(
            schainHash != keccak256(abi.encodePacked("Mainnet")) &&
            sender == tokenManagerEthAddresses[schainHash],
            "Receiver chain is incorrect"
        );
        Messages.TransferEthMessage memory message = Messages.decodeTransferEthMessage(data);
        require(
            message.amount <= address(this).balance,
            "Not enough money to finish this transaction"
        );
        approveTransfers[message.receiver] =
            approveTransfers[message.receiver].add(message.amount);
        if (!linker.interchainConnections(schainHash))
            _removeTransferredAmount(schainHash, message.amount);
        return message.receiver;
    }

    /**
     * @dev Transfers a user's ETH.
     *
     * Requirements:
     *
     * - LockAndDataForMainnet must have sufficient ETH.
     * - User must be approved for ETH transfer.
     */
    function getMyEth() external {
        require(
            address(this).balance >= approveTransfers[msg.sender],
            "Not enough ETH. in `DepositBox.getMyEth`"
        );
        require(approveTransfers[msg.sender] > 0, "User has insufficient ETH");
        uint256 amount = approveTransfers[msg.sender];
        approveTransfers[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function getFunds(string calldata schainName, address payable receiver, uint amount)
        external
        onlySchainOwner(schainName)
        whenKilled(keccak256(abi.encodePacked(schainName)))
    {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(transferredAmount[schainHash] >= amount, "Incorrect amount");
        _removeTransferredAmount(schainHash, amount);
        receiver.transfer(amount);
    }

    /**
     * @dev Checks whether depositBoxEth is connected to a SKALE chain TokenManagerEth.
     */
    function hasSchainContract(string calldata schainName) external view override returns (bool) {
        return tokenManagerEthAddresses[keccak256(abi.encodePacked(schainName))] != address(0);
    }

    /// Create a new deposit box
    function initialize(
        IContractManager contractManagerOfSkaleManager,        
        Linker linker,
        MessageProxyForMainnet messageProxy
    )
        public
        override
        initializer
    {
        DepositBox.initialize(contractManagerOfSkaleManager, linker, messageProxy);
    }

    function _saveTransferredAmount(bytes32 schainHash, uint256 amount) private {
        transferredAmount[schainHash] = transferredAmount[schainHash].add(amount);
    }

    function _removeTransferredAmount(bytes32 schainHash, uint256 amount) private {
        transferredAmount[schainHash] = transferredAmount[schainHash].sub(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBox.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;

import "../interfaces/IMainnetContract.sol";
import "./Linker.sol";
import "./MessageProxyForMainnet.sol";


/**
 * @title ProxyConnectorMainnet - connected module for Upgradeable approach, knows ContractManager
 * @author Artem Payvin
 */
abstract contract DepositBox is SkaleManagerClient, IMainnetContract {

    bytes32 public constant DEPOSIT_BOX_MANAGER_ROLE = keccak256("DEPOSIT_BOX_MANAGER_ROLE");

    MessageProxyForMainnet public messageProxy;
    Linker public linker;

    modifier onlyMessageProxy() {
        require(msg.sender == address(messageProxy), "Sender is not a MessageProxy");
        _;
    }

    modifier whenNotKilled(bytes32 schainHash) {
        require(linker.isNotKilled(schainHash), "Schain is killed");
        _;
    }

    modifier whenKilled(bytes32 schainHash) {
        require(!linker.isNotKilled(schainHash), "Schain is not killed");
        _;
    }
    
    function initialize(
        IContractManager contractManagerOfSkaleManager,
        Linker newLinker,
        MessageProxyForMainnet newMessageProxy
    )
        public
        virtual
        initializer
    {
        SkaleManagerClient.initialize(contractManagerOfSkaleManager);
        _setupRole(DEPOSIT_BOX_MANAGER_ROLE, address(newLinker));
        messageProxy = newMessageProxy;
        linker = newLinker;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Messages.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaeiv
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


library Messages {
    enum MessageType {
        EMPTY,
        TRANSFER_ETH,
        TRANSFER_ERC20,
        TRANSFER_ERC20_AND_TOTAL_SUPPLY,
        TRANSFER_ERC20_AND_TOKEN_INFO,
        TRANSFER_ERC721,
        TRANSFER_ERC721_AND_TOKEN_INFO,
        FREEZE_STATE,
        INTERCHAIN_CONNECTION,
        TRANSFER_ERC1155,
        TRANSFER_ERC1155_AND_TOKEN_INFO,
        TRANSFER_ERC1155_BATCH,
        TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO
    }

    struct BaseMessage {
        MessageType messageType;
    }

    struct TransferEthMessage {
        BaseMessage message;
        address receiver;
        uint256 amount;
    }

    struct FreezeStateMessage {
        BaseMessage message;
        address receiver;
        bool isUnfrozen;
    }

    struct TransferErc20Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 amount;
    }

    struct Erc20TokenInfo {
        string name;
        uint8 decimals;
        string symbol;
    }

    struct TransferErc20AndTotalSupplyMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
    }

    struct TransferErc20AndTokenInfoMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
        Erc20TokenInfo tokenInfo;
    }

    struct TransferErc721Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 tokenId;
    }

    struct Erc721TokenInfo {
        string name;
        string symbol;
    }

    struct TransferErc721AndTokenInfoMessage {
        TransferErc721Message baseErc721transfer;
        Erc721TokenInfo tokenInfo;
    }

    struct InterchainConnectionMessage {
        BaseMessage message;
        bool isAllowed;
    }

    struct TransferErc1155Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 id;
        uint256 amount;
    }

    struct TransferErc1155BatchMessage {
        BaseMessage message;
        address token;
        address receiver;
        uint256[] ids;
        uint256[] amounts;
    }

    struct Erc1155TokenInfo {
        string uri;
    }

    struct TransferErc1155AndTokenInfoMessage {
        TransferErc1155Message baseErc1155transfer;
        Erc1155TokenInfo tokenInfo;
    }

    struct TransferErc1155BatchAndTokenInfoMessage {
        TransferErc1155BatchMessage baseErc1155Batchtransfer;
        Erc1155TokenInfo tokenInfo;
    }

    function getMessageType(bytes calldata data) internal pure returns (MessageType) {
        uint256 firstWord = abi.decode(data, (uint256));
        if (firstWord % 32 == 0) {
            return getMessageType(data[firstWord:]);
        } else {
            return abi.decode(data, (Messages.MessageType));
        }
    }

    function encodeTransferEthMessage(address receiver, uint256 amount) internal pure returns (bytes memory) {
        TransferEthMessage memory message = TransferEthMessage(
            BaseMessage(MessageType.TRANSFER_ETH),
            receiver,
            amount
        );
        return abi.encode(message);
    }

    function decodeTransferEthMessage(
        bytes calldata data
    ) internal pure returns (TransferEthMessage memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ETH, "Message type is not ETH transfer");
        return abi.decode(data, (TransferEthMessage));
    }

    function encodeTransferErc20Message(
        address token,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc20Message memory message = TransferErc20Message(
            BaseMessage(MessageType.TRANSFER_ERC20),
            token,
            receiver,
            amount
        );
        return abi.encode(message);
    }

    function encodeTransferErc20AndTotalSupplyMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply
    ) internal pure returns (bytes memory) {
        TransferErc20AndTotalSupplyMessage memory message = TransferErc20AndTotalSupplyMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY),
                token,
                receiver,
                amount
            ),
            totalSupply
        );
        return abi.encode(message);
    }

    function decodeTransferErc20Message(
        bytes calldata data
    ) internal pure returns (TransferErc20Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC20, "Message type is not ERC20 transfer");
        return abi.decode(data, (TransferErc20Message));
    }

    function decodeTransferErc20AndTotalSupplyMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTotalSupplyMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY,
            "Message type is not ERC20 transfer and total supply"
        );
        return abi.decode(data, (TransferErc20AndTotalSupplyMessage));
    }

    function encodeTransferErc20AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply,
        Erc20TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc20AndTokenInfoMessage memory message = TransferErc20AndTokenInfoMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOKEN_INFO),
                token,
                receiver,
                amount
            ),
            totalSupply,
            tokenInfo
        );
        return abi.encode(message);
    }

    function decodeTransferErc20AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOKEN_INFO,
            "Message type is not ERC20 transfer with token info"
        );
        return abi.decode(data, (TransferErc20AndTokenInfoMessage));
    }

    function encodeTransferErc721Message(
        address token,
        address receiver,
        uint256 tokenId
    ) internal pure returns (bytes memory) {
        TransferErc721Message memory message = TransferErc721Message(
            BaseMessage(MessageType.TRANSFER_ERC721),
            token,
            receiver,
            tokenId
        );
        return abi.encode(message);
    }

    function decodeTransferErc721Message(
        bytes calldata data
    ) internal pure returns (TransferErc721Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC721, "Message type is not ERC721 transfer");
        return abi.decode(data, (TransferErc721Message));
    }

    function encodeTransferErc721AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 tokenId,
        Erc721TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc721AndTokenInfoMessage memory message = TransferErc721AndTokenInfoMessage(
            TransferErc721Message(
                BaseMessage(MessageType.TRANSFER_ERC721_AND_TOKEN_INFO),
                token,
                receiver,
                tokenId
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    function decodeTransferErc721AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc721AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_AND_TOKEN_INFO,
            "Message type is not ERC721 transfer with token info"
        );
        return abi.decode(data, (TransferErc721AndTokenInfoMessage));
    }

    function encodeFreezeStateMessage(address receiver, bool isUnfrozen) internal pure returns (bytes memory) {
        FreezeStateMessage memory message = FreezeStateMessage(
            BaseMessage(MessageType.FREEZE_STATE),
            receiver,
            isUnfrozen
        );
        return abi.encode(message);
    }

    function decodeFreezeStateMessage(bytes calldata data) internal pure returns (FreezeStateMessage memory) {
        require(getMessageType(data) == MessageType.FREEZE_STATE, "Message type is not Freeze User");
        return abi.decode(data, (FreezeStateMessage));
    }

    function encodeInterchainConnectionMessage(bool isAllowed) internal pure returns (bytes memory) {
        InterchainConnectionMessage memory message = InterchainConnectionMessage(
            BaseMessage(MessageType.INTERCHAIN_CONNECTION),
            isAllowed
        );
        return abi.encode(message);
    }

    function decodeInterchainConnectionMessage(bytes calldata data)
        internal
        pure
        returns (InterchainConnectionMessage memory)
    {
        require(getMessageType(data) == MessageType.INTERCHAIN_CONNECTION, "Message type is not Interchain connection");
        return abi.decode(data, (InterchainConnectionMessage));
    }

    function encodeTransferErc1155Message(
        address token,
        address receiver,
        uint256 id,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc1155Message memory message = TransferErc1155Message(
            BaseMessage(MessageType.TRANSFER_ERC1155),
            token,
            receiver,
            id,
            amount
        );
        return abi.encode(message);
    }

    function decodeTransferErc1155Message(
        bytes calldata data
    ) internal pure returns (TransferErc1155Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC1155, "Message type is not ERC1155 transfer");
        return abi.decode(data, (TransferErc1155Message));
    }

    function encodeTransferErc1155AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 id,
        uint256 amount,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155AndTokenInfoMessage memory message = TransferErc1155AndTokenInfoMessage(
            TransferErc1155Message(
                BaseMessage(MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO),
                token,
                receiver,
                id,
                amount
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    function decodeTransferErc1155AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO,
            "Message type is not ERC1155AndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155AndTokenInfoMessage));
    }

    function encodeTransferErc1155BatchMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchMessage memory message = TransferErc1155BatchMessage(
            BaseMessage(MessageType.TRANSFER_ERC1155_BATCH),
            token,
            receiver,
            ids,
            amounts
        );
        return abi.encode(message);
    }

    function decodeTransferErc1155BatchMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH,
            "Message type is not ERC1155Batch transfer"
        );
        return abi.decode(data, (TransferErc1155BatchMessage));
    }

    function encodeTransferErc1155BatchAndTokenInfoMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchAndTokenInfoMessage memory message = TransferErc1155BatchAndTokenInfoMessage(
            TransferErc1155BatchMessage(
                BaseMessage(MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO),
                token,
                receiver,
                ids,
                amounts
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    function decodeTransferErc1155BatchAndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchAndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO,
            "Message type is not ERC1155BatchAndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155BatchAndTokenInfoMessage));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMainnetContract.sol - Interface of Mainnet Template Contract
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;

interface IMainnetContract {

    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        returns (address);

    function addSchainContract(string calldata schainName, address newSchainContract) external;

    function removeSchainContract(string calldata schainName) external;

    function hasSchainContract(string calldata schainName) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Linker.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../Messages.sol";
import "./SkaleManagerClient.sol";
import "../interfaces/IMainnetContract.sol";

import "./MessageProxyForMainnet.sol";


/**
 * @title Linker For Mainnet
 * @dev Runs on Mainnet, holds deposited ETH, and contains mappings and
 * balances of ETH tokens received through DepositBox.
 */
contract Linker is SkaleManagerClient {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable for uint;

    bytes32 public constant LINKER_ROLE = keccak256("LINKER_ROLE");

    EnumerableSetUpgradeable.AddressSet private _mainnetContracts;
    MessageProxyForMainnet public messageProxy;

    mapping(bytes32 => bool) public interchainConnections;

    enum KillProcess {Active, PartiallyKilledBySchainOwner, PartiallyKilledByContractOwner, Killed}

    mapping(bytes32 => KillProcess) public statuses;
    mapping(bytes32 => address) public schainLinks;

    modifier onlyLinker() {
        require(hasRole(LINKER_ROLE, msg.sender), "Linker role is required");
        _;
    }

    function registerMainnetContract(address newMainnetContract) external onlyLinker {
        _mainnetContracts.add(newMainnetContract);
    }

    function removeMainnetContract(address mainnetContract) external onlyLinker {
        _mainnetContracts.remove(mainnetContract);
    }

    function connectSchain(string calldata schainName, address[] calldata schainContracts) external onlyLinker {
        require(schainContracts.length == _mainnetContracts.length(), "Incorrect number of addresses");
        for (uint i = 0; i < schainContracts.length; i++) {
            IMainnetContract(_mainnetContracts.at(i)).addSchainContract(schainName, schainContracts[i]);
        }
        messageProxy.addConnectedChain(schainName);
    }

    function allowInterchainConnections(string calldata schainName) external onlySchainOwner(schainName) {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(statuses[schainHash] == KillProcess.Active, "Schain is in kill process");
        interchainConnections[schainHash] = true;
        messageProxy.postOutgoingMessage(
            schainHash,
            schainLinks[schainHash],
            // Messages.encodeFreezeStateMessage(address(messageProxy), false)
            Messages.encodeInterchainConnectionMessage(true)
        );
    }

    function kill(string calldata schainName) external {
        require(!interchainConnections[keccak256(abi.encodePacked(schainName))], "Interchain connections turned on");
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        if (statuses[schainHash] == KillProcess.Active) {
            if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
                statuses[schainHash] = KillProcess.PartiallyKilledByContractOwner;
            } else if (isSchainOwner(msg.sender, schainHash)) {
                statuses[schainHash] = KillProcess.PartiallyKilledBySchainOwner;
            } else {
                revert("Not allowed");
            }
        } else if (
            (
                statuses[schainHash] == KillProcess.PartiallyKilledBySchainOwner &&
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
            ) || (
                statuses[schainHash] == KillProcess.PartiallyKilledByContractOwner &&
                isSchainOwner(msg.sender, schainHash)
            )
        ) {
            statuses[schainHash] = KillProcess.Killed;
        } else {
            revert("Already killed or incorrect sender");
        }
    }

    function unconnectSchain(string calldata schainName) external onlyLinker {
        uint length = _mainnetContracts.length();
        for (uint i = 0; i < length; i++) {
            IMainnetContract(_mainnetContracts.at(i)).removeSchainContract(schainName);
        }
        messageProxy.removeConnectedChain(schainName);
    }

    function addSchainContract(string calldata schainName, address contractOnSchain) external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller"
        );
        require(schainLinks[schainHash] == address(0), "SKALE chain is already set");
        require(contractOnSchain != address(0), "Incorrect address for contract on Schain");
        schainLinks[schainHash] = contractOnSchain;
    }

    function removeSchainContract(string calldata schainName) external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller"
        );
        require(schainLinks[schainHash] != address(0), "SKALE chain is not set");
        delete schainLinks[schainHash];
    }

    function hasSchainContract(string calldata schainName) external view returns (bool) {
        return schainLinks[keccak256(abi.encodePacked(schainName))] != address(0);
    }

    function isNotKilled(bytes32 schainHash) external view returns (bool) {
        return statuses[schainHash] != KillProcess.Killed;
    }

    function hasMainnetContract(address mainnetContract) external view returns (bool) {
        return _mainnetContracts.contains(mainnetContract);
    }

    function hasSchain(string calldata schainName) external view returns (bool connected) {
        uint length = _mainnetContracts.length();
        connected = messageProxy.isConnectedChain(schainName);
        for (uint i = 0; connected && i < length; i++) {
            connected = connected && IMainnetContract(_mainnetContracts.at(i)).hasSchainContract(schainName);
        }
    }

    function initialize(
        address messageProxyAddress,
        IContractManager newContractManagerOfSkaleManager
    )
        public
        initializer
    {
        SkaleManagerClient.initialize(newContractManagerOfSkaleManager);
        _setupRole(LINKER_ROLE, msg.sender);
        messageProxy = MessageProxyForMainnet(messageProxyAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxyForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@skalenetwork/skale-manager-interfaces/IWallets.sol";
import "@skalenetwork/skale-manager-interfaces/ISchains.sol";

import "../interfaces/IMessageReceiver.sol";
import "./SkaleManagerClient.sol";

interface ICommunityPool {
    function refundGasByUser(
        bytes32 schainHash,
        address node,
        address user,
        uint256 gas
    ) external;
    function getBalance() external view returns (uint);
}

/**
 * @title Message Proxy for Mainnet
 * @dev Runs on Mainnet, contains functions to manage the incoming messages from
 * `targetSchainName` and outgoing messages to `fromSchainName`. Every SKALE chain with 
 * IMA is therefore connected to MessageProxyForMainnet.
 *
 * Messages from SKALE chains are signed using BLS threshold signatures from the
 * nodes in the chain. Since Ethereum Mainnet has no BLS public key, mainnet
 * messages do not need to be signed.
 */
contract MessageProxyForMainnet is SkaleManagerClient {

    /**
     * 16 Agents
     * Synchronize time with time.nist.gov
     * Every agent checks if it is his time slot
     * Time slots are in increments of 10 seconds
     * At the start of his slot each agent:
     * For each connected schain:
     * Read incoming counter on the dst chain
     * Read outgoing counter on the src chain
     * Calculate the difference outgoing - incoming
     * Call postIncomingMessages function passing (un)signed message array
     * ID of this schain, Chain 0 represents ETH mainnet,
    */

    struct ConnectedChainInfo {
        // message counters start with 0
        uint256 incomingMessageCounter;
        uint256 outgoingMessageCounter;
        bool inited;
    }

    struct Message {
        address sender;
        address destinationContract;
        bytes data;
    }

    struct Signature {
        uint256[2] blsSignature;
        uint256 hashA;
        uint256 hashB;
        uint256 counter;
    }

    bytes32 public constant MAINNET_HASH = keccak256(abi.encodePacked("Mainnet"));
    bytes32 public constant CHAIN_CONNECTOR_ROLE = keccak256("CHAIN_CONNECTOR_ROLE");
    bytes32 public constant DEBUGGER_ROLE = keccak256("DEBUGGER_ROLE");
    bytes32 public constant EXTRA_CONTRACT_REGISTRAR_ROLE = keccak256("EXTRA_CONTRACT_REGISTRAR_ROLE");
    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");

    address public communityPoolAddress;

    mapping(bytes32 => ConnectedChainInfo) public connectedChains;
    mapping(bytes32 => mapping(address => bool)) public registryContracts;

    uint256 public headerMessageGasCost;
    uint256 public messageGasCost;
    uint256 public gasLimit;

    modifier onlyDebugger() {
        require(hasRole(DEBUGGER_ROLE, msg.sender), "Access denied");
        _;
    }

    modifier onlyConstantSetter() {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "Not enough permissions to set constant");
        _;
    }

    /**
     * @dev Emitted for every outgoing message to `dstChain`.
     */
    event OutgoingMessage(
        bytes32 indexed dstChainHash,
        uint256 indexed msgCounter,
        address indexed srcContract,
        address dstContract,
        bytes data
    );

    event PostMessageError(
        uint256 indexed msgCounter,
        bytes message
    );

    /**
     * @dev Allows LockAndData to add a `schainName`.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be SKALE Node address.
     * - `schainName` must not be "Mainnet".
     * - `schainName` must not already be added.
     */
    function addConnectedChain(string calldata schainName) external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            schainHash != MAINNET_HASH,
            "SKALE chain name is incorrect. Inside in MessageProxy"
        );
        require(
            hasRole(CHAIN_CONNECTOR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to add connected chain"
        );
        require(!connectedChains[schainHash].inited,"Chain is already connected");
        connectedChains[schainHash] = ConnectedChainInfo({
            incomingMessageCounter: 0,
            outgoingMessageCounter: 0,
            inited: true
        });
    }

    /**
     * @dev Allows LockAndData to remove connected chain from this contract.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be LockAndData contract.
     * - `schainName` must be initialized.
     */
    function removeConnectedChain(string calldata schainName) external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            connectedChains[schainHash].inited,
            "Chain is not initialized"
        );
        require(
            hasRole(CHAIN_CONNECTOR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to remove connected chain"
        );
        delete connectedChains[schainHash];
    }

    function setCommunityPool(address newCommunityPoolAddress) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller"
        );  
        communityPoolAddress = newCommunityPoolAddress;
    }

    /**
     * @dev Posts message from this contract to `targetSchainName` MessageProxy contract.
     * This is called by a smart contract to make a cross-chain call.
     * 
     * Requirements:
     * 
     * - `targetSchainName` must be initialized.
     */
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes calldata data
    )
        external
    {
        require(connectedChains[targetChainHash].inited, "Destination chain is not initialized");
        require(
            registryContracts[bytes32(0)][msg.sender] || 
            registryContracts[targetChainHash][msg.sender],
            "Sender contract is not registered"
        );
        uint msgCounter = connectedChains[targetChainHash].outgoingMessageCounter;
        emit OutgoingMessage(
            targetChainHash,
            msgCounter,
            msg.sender,
            targetContract,
            data
        );
        connectedChains[targetChainHash].outgoingMessageCounter = msgCounter.add(1);
    }

    function registerExtraContract(string calldata schainName, address contractOnMainnet) external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(contractOnMainnet.isContract(), "Given address is not a contract");
        require(!registryContracts[schainHash][contractOnMainnet], "Extra contract is already registered");
        require(
            !registryContracts[bytes32(0)][contractOnMainnet],
            "Extra contract is already registered for all chains"
        );
        registryContracts[schainHash][contractOnMainnet] = true;
    }

    function registerExtraContractForAll(address contractOnMainnet) external {
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender),
            "Not enough permissions to register extra contract for all chains"
        );
        require(contractOnMainnet.isContract(), "Given address is not a contract");
        require(!registryContracts[bytes32(0)][contractOnMainnet], "Extra contract is already registered");
        registryContracts[bytes32(0)][contractOnMainnet] = true;
    }

    function removeExtraContract(string calldata schainName, address contractOnMainnet) external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to remove extra contract"
        );
        require(contractOnMainnet.isContract(), "Given address is not a contract");
        require(registryContracts[schainHash][contractOnMainnet], "Extra contract does not exist");
        delete registryContracts[schainHash][contractOnMainnet];
    }

    function removeExtraContractForAll(address contractOnMainnet) external {
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender),
            "Not enough permissions to remove extra contract for all chains"
        );
        require(contractOnMainnet.isContract(), "Given address is not a contract");
        require(registryContracts[bytes32(0)][contractOnMainnet], "Extra contract does not exist");
        delete registryContracts[bytes32(0)][contractOnMainnet];
    }

    /**
     * @dev Posts incoming message from `fromSchainName`. 
     * 
     * Requirements:
     * 
     * - `msg.sender` must be authorized caller.
     * - `fromSchainName` must be initialized.
     * - `startingCounter` must be equal to the chain's incoming message counter.
     * - If destination chain is Mainnet, message signature must be valid.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign,
        uint256
    )
        external
    {
        uint256 gasTotal = gasleft();
        bytes32 fromSchainHash = keccak256(abi.encodePacked(fromSchainName));
        require(connectedChains[fromSchainHash].inited, "Chain is not initialized");
        require(
            startingCounter == connectedChains[fromSchainHash].incomingMessageCounter,
            "Starting counter is not equal to incoming message counter");

        require(_verifyMessages(fromSchainName, _hashedArray(messages), sign), "Signature is not verified");
        uint additionalGasPerMessage = 
            (gasTotal.sub(gasleft())
            .add(headerMessageGasCost)
            .add(messages.length * messageGasCost))
            .div(messages.length);
        for (uint256 i = 0; i < messages.length; i++) {
            gasTotal = gasleft();
            if (
                !registryContracts[fromSchainHash][messages[i].destinationContract] &&
                !registryContracts[bytes32(0)][messages[i].destinationContract]
            ) {
                emit PostMessageError(
                    startingCounter + i,
                    bytes("Destination contract is not registered")
                );
                continue;
            }
            address receiver = _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
            if (receiver == address(0)) 
                continue;
            ICommunityPool(communityPoolAddress).refundGasByUser(
                fromSchainHash,
                msg.sender,
                receiver,
                gasTotal.sub(gasleft()).add(additionalGasPerMessage)
            );
        }
        connectedChains[fromSchainHash].incomingMessageCounter = 
            connectedChains[fromSchainHash].incomingMessageCounter.add(uint256(messages.length));
    }

    /**
     * @dev Increments incoming message counter. 
     * 
     * Note: Test function. TODO: remove in production.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be owner.
     */
    function incrementIncomingCounter(string calldata schainName) external onlyDebugger {
        connectedChains[keccak256(abi.encodePacked(schainName))].incomingMessageCounter = 
            connectedChains[keccak256(abi.encodePacked(schainName))].incomingMessageCounter.add(1);
    }

    /**
     * @dev Sets the incoming and outgoing message counters to zero. 
     * 
     * Note: Test function. TODO: remove in production.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be owner.
     */
    function setCountersToZero(string calldata schainName) external onlyDebugger {
        connectedChains[keccak256(abi.encodePacked(schainName))].incomingMessageCounter = 0;
        connectedChains[keccak256(abi.encodePacked(schainName))].outgoingMessageCounter = 0;
    }

    /**
     * @dev Sets headerMessageGasCost to a new value
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewHeaderMessageGasCost(uint256 newHeaderMessageGasCost) external onlyConstantSetter {
        headerMessageGasCost = newHeaderMessageGasCost;
    }

    /**
     * @dev Sets messageGasCost to a new value
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewMessageGasCost(uint256 newMessageGasCost) external onlyConstantSetter {
        messageGasCost = newMessageGasCost;
    }

    /**
     * @dev Sets gasLimit to a new value
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CONSTANT_SETTER_ROLE.
     */
    function setNewGasLimit(uint256 newGasLimit) external onlyConstantSetter {
        gasLimit = newGasLimit;
    }

    /**
     * @dev Checks whether chain is currently connected.
     * 
     * Note: Mainnet chain does not have a public key, and is implicitly 
     * connected to MessageProxy.
     * 
     * Requirements:
     * 
     * - `schainName` must not be Mainnet.
     */
    function isConnectedChain(
        string calldata schainName
    )
        external
        view
        returns (bool)
    {
        require(
            keccak256(abi.encodePacked(schainName)) !=
            keccak256(abi.encodePacked("Mainnet")),
            "Schain id can not be equal Mainnet"); // main net does not have a public key and is implicitly connected
        if ( ! connectedChains[keccak256(abi.encodePacked(schainName))].inited ) {
            return false;
        }
        return true;
    }

    /**
     * @dev Returns number of outgoing messages to some schain
     * 
     * Requirements:
     * 
     * - `targetSchainName` must be initialized.
     */
    function getOutgoingMessagesCounter(string calldata targetSchainName)
        external
        view
        returns (uint256)
    {
        bytes32 dstChainHash = keccak256(abi.encodePacked(targetSchainName));
        require(connectedChains[dstChainHash].inited, "Destination chain is not initialized");
        return connectedChains[dstChainHash].outgoingMessageCounter;
    }

    /**
     * @dev Returns number of incoming messages from some schain
     * 
     * Requirements:
     * 
     * - `fromSchainName` must be initialized.
     */
    function getIncomingMessagesCounter(string calldata fromSchainName)
        external
        view
        returns (uint256)
    {
        bytes32 srcChainHash = keccak256(abi.encodePacked(fromSchainName));
        require(connectedChains[srcChainHash].inited, "Source chain is not initialized");
        return connectedChains[srcChainHash].incomingMessageCounter;
    }

    // Create a new message proxy

    function initialize(IContractManager contractManagerOfSkaleManager) public virtual override initializer {
        SkaleManagerClient.initialize(contractManagerOfSkaleManager);
        headerMessageGasCost = 70000;
        messageGasCost = 8790;
        gasLimit = 1000000;
    }

    /**
     * @dev Returns hash of message array.
     */
    function _hashedArray(Message[] calldata messages) private pure returns (bytes32) {
        bytes memory data;
        for (uint256 i = 0; i < messages.length; i++) {
            data = abi.encodePacked(
                data,
                bytes32(bytes20(messages[i].sender)),
                bytes32(bytes20(messages[i].destinationContract)),
                messages[i].data
            );
        }
        return keccak256(data);
    }

    function _callReceiverContract(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        private
        returns (address)
    {
        try IMessageReceiver(message.destinationContract).postMessage{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) returns (address receiver) {
            return receiver;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                bytes(reason)
            );
            return address(0);
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                revertData
            );
            return address(0);
        }
    }

    /**
     * @dev Converts calldata structure to memory structure and checks
     * whether message BLS signature is valid.
     */
    function _verifyMessages(
        string calldata fromSchainName,
        bytes32 hashedMessages,
        MessageProxyForMainnet.Signature calldata sign
    )
        internal
        view
        returns (bool)
    {
        return ISchains(
            contractManagerOfSkaleManager.getContract("Schains")
        ).verifySchainSignature(
            sign.blsSignature[0],
            sign.blsSignature[1],
            hashedMessages,
            sign.counter,
            sign.hashA,
            sign.hashB,
            fromSchainName
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   SkaleManagerClient.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";


/**
 * @title SkaleManagerClient - contract that knows ContractManager
 * and makes calls to SkaleManager contracts
 * @author Artem Payvin
 * @author Dmytro Stebaiev
 */
contract SkaleManagerClient is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    IContractManager public contractManagerOfSkaleManager;

    modifier onlySchainOwner(string memory schainName) {
        require(
            isSchainOwner(msg.sender, keccak256(abi.encodePacked(schainName))) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Sender is not an Schain owner"
        );
        _;
    }

    /**
     * @dev Checks whether sender is owner of SKALE chain
     */
    function isSchainOwner(address sender, bytes32 schainHash) public view returns (bool) {
        address skaleChainsInternal = contractManagerOfSkaleManager.getContract("SchainsInternal");
        return ISchainsInternal(skaleChainsInternal).isOwnerAddress(sender, schainHash);
    }

    /**
     * @dev initialize - sets current address of ContractManager of SkaleManager
     * @param newContractManagerOfSkaleManager - current address of ContractManager of SkaleManager
     */
    function initialize(
        IContractManager newContractManagerOfSkaleManager
    )
        public
        virtual
        initializer
    {
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        contractManagerOfSkaleManager = newContractManagerOfSkaleManager;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IContractManager.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.7.0;
interface IContractManager {
    function setContractsAddress(string calldata contractsName, address newContractsAddress) external;
    function getContract(string calldata name) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchainsInternal - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.7.0;

interface ISchainsInternal {
    function isNodeAddressesInGroup(bytes32 schainId, address sender) external view returns (bool);
    function isOwnerAddress(address from, bytes32 schainId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IWallets - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.7.0;

interface IWallets {
    function refundGasBySchain(bytes32 schainId, address payable spender, uint spentGas, bool isDebt) external;
    function rechargeSchainWallet(bytes32 schainId) external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchains.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.7.0;

interface ISchains {
    function verifySchainSignature(
        uint256 signA,
        uint256 signB,
        bytes32 hash,
        uint256 counter,
        uint256 hashA,
        uint256 hashB,
        string calldata schainName
    )
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageReceiver.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;


interface IMessageReceiver {
    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        returns (address);
}

