// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC755.sol";
import "./Structs.sol";
import "./Constants.sol";
import "./PaymentSplitter.sol";

contract Artwork is ERC755 {
    address private _owner;

    mapping(uint256 => PaymentSplitter) private _paymentSplittersByTokenId;

    string[] private _supportedActions;
    mapping(string => string) private _actionGroup;
    mapping(string => bool) _supportedRolesMap;
    string[] private _supportedRoles;
    uint256 private _supportedActionsNum;

    mapping(string => uint256) private _paymentsReceived;

    mapping(uint256 => bool) private _signedTimestamp;

    mapping(address => bool) private _canMint;

    mapping(uint256 => string) private _tokenCertificate;

    function initialize(
        Structs.SupportedAction[] memory supportedActionsList,
        string[] memory supportedRolesList
    ) external initializer {
        __ERC755_init("LiveArt", "LIVEART");

        _owner = _msgSender();
        _canMint[_owner] = true;

        _updateSupportedRoles(supportedRolesList);
        _updateSupportedActions(supportedActionsList);
    }

    function updateSupportedActions(
        Structs.SupportedAction[] memory supportedActionsList,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV,
        uint256 timestamp
    ) public onlyOwner {
        _requireMessageSigned(sigR, sigS, sigV, timestamp);
        _updateSupportedActions(supportedActionsList);
    }

    function _updateSupportedActions(
        Structs.SupportedAction[] memory supportedActionsList
    ) private {
        require(
            supportedActionsList.length > 0,
            "no supported actions"
        );
        for (uint256 i = 0; i < _supportedActions.length; i++) {
            delete _actionGroup[_supportedActions[i]];
        }
        delete _supportedActions;

        for (uint256 i = 0; i < supportedActionsList.length; i++) {
            _actionGroup[supportedActionsList[i].action] =
            supportedActionsList[i].group;
            _supportedActions.push(supportedActionsList[i].action);
        }
        _supportedActionsNum = supportedActionsList.length;
    }

    function updateSupportedRoles(
        string[] memory supportedRolesList,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV,
        uint256 timestamp
    ) public onlyOwner {
        _requireMessageSigned(sigR, sigS, sigV, timestamp);
        _updateSupportedRoles(supportedRolesList);
    }

    function _updateSupportedRoles(
        string[] memory supportedRolesList
    ) private {
        require(
            supportedRolesList.length > 0,
            "no supported roles"
        );

        for (uint256 i = 0; i < _supportedRoles.length; i++) {
            delete _supportedRolesMap[_supportedRoles[i]];
        }
        delete _supportedRoles;

        bool ownerIsSupported = false;
        bool creatorIsSupported = false;
        for (uint256 i = 0; i < supportedRolesList.length; i++) {
            _supportedRolesMap[supportedRolesList[i]] = true;
            if (keccak256(bytes(supportedRolesList[i])) == Constants.ROLE_OWNER) {
                ownerIsSupported = true;
            }
            if (keccak256(bytes(supportedRolesList[i])) == Constants.ROLE_CREATOR) {
                creatorIsSupported = true;
            }
        }
        _supportedRoles = supportedRolesList;
        require(ownerIsSupported, "owner role should be supported");
        require(ownerIsSupported, "creator role should be supported");
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function _requireMessageSigned(
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) private {
        require(
            !_signedTimestamp[timestamp],
            "timestamp already signed"
        );
        require(
            _msgSender() == ecrecover(
                keccak256(abi.encodePacked(
                    "\x19\x01",
                    Constants._DOMAIN_SEPARATOR,
                    keccak256(abi.encode(
                        keccak256("BasicOperation(uint256 timestamp)"),
                        timestamp
                    ))
                )),
                v,
                r,
                s
            ),
            "invalid sig"
        );

        _signedTimestamp[timestamp] = true;
    }

    function _requireCanMint() private view {
        require(
            _canMint[_msgSender()],
            "can't mint"
        );
    }

    function _actionSupported(string memory action) private view returns (bool) {
        return bytes(_actionGroup[action]).length > 0;
    }

    function supportedActions() external view override returns (string[] memory) {
        return _supportedActions;
    }

    function supportedRoles() external view returns (string[] memory) {
        return _supportedRoles;
    }

    function createArtwork(
        Structs.RoyaltyReceiver[] memory royaltyReceivers,
        Structs.Policy[] memory creationRights,
        string memory metadataURI,
        uint256 editionOf,
        uint256 maxTokenSupply,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV,
        uint256 timestamp
    ) external returns(uint256) {
        _requireMessageSigned(sigR, sigS, sigV, timestamp);
        _requireCanMint();
        require(
            creationRights.length >= _supportedActionsNum,
            "all rights should be set"
        );
        if (editionOf > 0) {
            require(
                maxTokenSupply == 1,
                "invalid token supply for edition"
            );
        }

        _tokenId++;

        uint256 newItemId = _tokenId;

        if (maxTokenSupply > 0) {
            _tokenSupply[newItemId] = maxTokenSupply;
            _tokenEditions[newItemId].push(newItemId);
        }
        if (editionOf > 0) {
            require(
                _exists(editionOf),
                "original token does not exist"
            );
            _tokenEditions[editionOf].push(newItemId);
            require(
                _tokenSupply[editionOf] >= _tokenEditions[editionOf].length,
                "editions limit reached"
            );
        }

        Structs.Policy[] storage tokenRights = _rightsByToken[newItemId];
        for (uint256 i = 0; i < creationRights.length; i++) {
            creationRights[i].target = newItemId;
            require(
                _actionSupported(creationRights[i].action),
                "unsupported action"
            );
            require(
                _supportedRolesMap[creationRights[i].permission.role],
                "unsupported role"
            );
            tokenRights.push(creationRights[i]);
        }

        PaymentSplitter paymentSplitterAddress = new PaymentSplitter(
            royaltyReceivers,
            newItemId
        );
        _paymentSplittersByTokenId[newItemId] = paymentSplitterAddress;
        _setTokenURI(newItemId, metadataURI);

        for (uint256 i = 0; i < creationRights.length; i++) {
            if (
                keccak256(bytes(creationRights[i].permission.role)) ==
                Constants.ROLE_CREATOR
            ) {
                if (
                    !isApprovedForAll(
                        creationRights[i].permission.wallet,
                        _msgSender()
                    )
                ) {
                    _setApprovalForAll(
                        creationRights[i].permission.wallet,
                        _msgSender(),
                        true
                    );
                }
            }
        }

        emit ArtworkCreated(
            newItemId,
            creationRights,
            metadataURI,
            editionOf,
            maxTokenSupply,
            block.timestamp
        );

        return newItemId;
    }

    function _generatePaymentReceivedKey(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) private pure returns (string memory) {
        string memory actions;

        for (uint256 i = 0; i < policies.length; i++) {
            actions = string(abi.encodePacked(actions, policies[i].action));
        }

        return string(abi.encodePacked(from, to, tokenId, actions));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal view override {
        if (_paymentSplittersByTokenId[tokenId].hasRoyaltyReceivers()) {
            require(
                _paymentsReceived[
                    _generatePaymentReceivedKey(from, to, tokenId, policies)
                ] > 0,
                "payment not received"
            );
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal override {
        delete _paymentsReceived[
            _generatePaymentReceivedKey(from, to, tokenId, policies)
        ];
    }

    function payForTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) external override payable {
        require(
            _exists(tokenId),
            "no token to pay for"
        );
        require(
            msg.value > 0,
            "no payment received"
        );

        for (uint256 i = 0; i < policies.length; i++) {
            policies[i].target = tokenId;
        }
        emit PaymentReceived(
            from,
            to,
            tokenId,
            msg.value,
            policies,
            block.timestamp
        );

        _paymentsReceived[
            _generatePaymentReceivedKey(from, to, tokenId, policies)
        ] = msg.value;

        AddressUpgradeable.sendValue(
            payable(address(_paymentSplittersByTokenId[tokenId])),
            msg.value
        );
        _paymentSplittersByTokenId[tokenId].releasePayment(
            msg.value,
            payable(from)
        );
    }

    function paymentSplitter(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId));
        return address(_paymentSplittersByTokenId[tokenId]);
    }

    function version() external virtual pure returns (uint256) {
        return 1;
    }

    function rightsOwned(
        address owner,
        Structs.Policy[] memory policies,
        uint256 tokenId
    ) external override view returns (bool) {
        require(_exists(tokenId), "token does not exist");

        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].permission.wallet != owner) {
                return false;
            }

            bool foundTokenRight = false;
            for (uint256 j = 0; j < _rightsByToken[tokenId].length; j++) {
                if (
                    compareStrings(_rightsByToken[tokenId][j].action, policies[i].action) &&
                    _rightsByToken[tokenId][j].permission.wallet == owner
                ) {
                    foundTokenRight = true;
                }
            }
            if (!foundTokenRight) {
                return false;
            }
        }

        return true;
    }

    function approveByOperator(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(
            isApprovedForAll(
                from,
                _msgSender()
            ),
            "not operator for a token"
        );

        _approve(
            from,
            to,
            tokenId
        );
    }

    function addMinter(
        address minter,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external onlyOwner {
        _requireMessageSigned(r, s, v, timestamp);

        _canMint[minter] = true;
    }

    function removeMinter(
        address minter,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external onlyOwner {
        _requireMessageSigned(r, s, v, timestamp);
        require(minter != _owner, "can't remove owner");

        delete _canMint[minter];
    }

    function setTokenCertificate(
        uint256 tokenId,
        string memory certificateURI
    ) external {
        _requireCanMint();
        require(
            bytes(_tokenCertificate[tokenId]).length == 0,
            "can't change certificate"
        );

        _tokenCertificate[tokenId] = certificateURI;
    }

    function getTokenCertificate(
        uint256 tokenId
    ) external view returns (string memory) {
        return _tokenCertificate[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    bytes32 constant ROLE_OWNER = keccak256(bytes("ROLE_OWNER"));
    bytes32 constant ROLE_CREATOR = keccak256(bytes("ROLE_CREATOR"));
    bytes32 constant _DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version)"),
        keccak256("LiveArt"),
        keccak256("1")
    ));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./IERC755.sol";
import "./IERC755Receiver.sol";

abstract contract ERC755 is IERC755, Context, Initializable {
    using AddressUpgradeable for address;

    uint256 internal _tokenId;

    string private _name;
    string private _symbol;
    mapping (uint256 => string) private _tokenURIs;

    mapping (address => mapping(uint256 => address)) private _tokenApprovals;
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    mapping (uint256 => uint256[]) internal _tokenEditions;
    mapping (uint256 => uint256) internal _tokenSupply;

    mapping (uint256 => Structs.Policy[]) internal _rightsByToken;

    function __ERC755_init(string memory tokenName, string memory tokenSymbol) internal {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC755).interfaceId;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId));

        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _haveTokenRights(address owner, uint256 tokenId) internal view returns (bool) {
        for (uint256 i = 0; i < _rightsByToken[tokenId].length; i++) {
            if (_rightsByToken[tokenId][i].permission.wallet == owner) {
                return true;
            }
        }
        return false;
    }

    function approve(
        address to,
        uint256 tokenId
    ) external override payable {
        require(
            _exists(tokenId),
            "no token to approve"
        );
        require(
            _haveTokenRights(_msgSender(), tokenId),
            "no rights to approve"
        );

        _approve(_msgSender(), to, tokenId);
    }

    function _approve(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _tokenApprovals[from][tokenId] = to;
        emit Approval(from, to, tokenId);
    }

    function getApproved(
        address from,
        uint256 tokenId
    ) public view override returns (address operator) {
        require(_exists(tokenId), "token does not exist");

        return _tokenApprovals[from][tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(_msgSender(), operator, approved);
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        _operatorApprovals[owner][operator] = approved;
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= _tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal virtual {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes memory data
    ) external override payable {
        require(_exists(tokenId), "token does not exist");
        require(policies.length > 0, "no rights to transfer");
        require(
            _haveTokenRights(from, tokenId),
            "from has no rights to transfer"
        );
        require(
            from != to,
            "can't transfer to self"
        );
        if (_msgSender() != from) {
            require(
                getApproved(from, tokenId) == _msgSender() ||
                isApprovedForAll(from, _msgSender()),
                "msg sender is not approved nor operator"
            );
        }

        _beforeTokenTransfer(from, to, tokenId, policies);

        for (uint256 i = 0; i < policies.length; i++) {
            require(
                policies[i].permission.wallet == from,
                "right is not owned"
            );

            bool foundTransferRight = false;
            for (uint256 j = 0; j < _rightsByToken[tokenId].length; j++) {
                if (
                    compareStrings(_rightsByToken[tokenId][j].action, policies[i].action) &&
                    _rightsByToken[tokenId][j].permission.wallet == from
                ) {
                    policies[i].target = tokenId;
                    policies[i].permission.role = "ROLE_OWNER";
                    policies[i].permission.wallet = to;
                    _rightsByToken[tokenId][j] = policies[i];
                    foundTransferRight = true;
                }
            }
            require(foundTransferRight, "transfer right is not owned");
        }

        emit Transfer(
            from,
            to,
            tokenId,
            policies,
            block.timestamp
        );
        _afterTokenTransfer(from, to, tokenId, policies);

        if (!_haveTokenRights(from, tokenId)) {
            _tokenApprovals[from][tokenId] = address(0);
        }

        _checkOnERC755Received(from, to, tokenId, policies, data);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal virtual {}

    function editions(uint256 tokenId) external override view returns (uint256[] memory) {
        require(_exists(tokenId), "token does not exist");

        return _tokenEditions[tokenId];
    }

    function totalSupply() external override view returns (uint256) {
        return _tokenId;
    }

    function tokenSupply(uint256 tokenId) external override view returns (uint256) {
        require(_exists(tokenId), "token does not exist");

        return _tokenSupply[tokenId];
    }

    function rights(uint256 tokenId) external override view returns (Structs.Policy[] memory) {
        require(_exists(tokenId), "token does not exist");

        return _rightsByToken[tokenId];
    }

    function _checkOnERC755Received(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes memory _data
    ) private {
        if (to.isContract()) {
            require(
                IERC755Receiver(to).onERC755Received(
                    _msgSender(),
                    from,
                    tokenId,
                    policies,
                    _data
                ) == IERC755Receiver(to).onERC755Received.selector,
                    "receiver is not a IERC755Receiver"
            );
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./Structs.sol";

interface IERC755 is IERC165 {
    event PaymentReceived(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        Structs.Policy[] transferRights,
        uint256 timestamp
    );
    event ArtworkCreated(
        uint256 tokenId,
        Structs.Policy[] creationRights,
        string tokenURI,
        uint256 editionOf,
        uint256 maxTokenSupply,
        uint256 timestamp
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        Structs.Policy[] rights,
        uint256 timestamp
    );

    event Approval(
        address indexed approver,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed approver,
        address indexed operator,
        bool approved
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes calldata data
    ) external payable;

    function payForTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) external payable;

    function approve(
        address to,
        uint256 tokenId
    ) external payable;

    function getApproved(
        address from,
        uint256 tokenId
    ) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function editions(uint256 tokenId) external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function tokenSupply(uint256 tokenId) external view returns (uint256);

    function rights(uint256 tokenId) external view returns (Structs.Policy[] memory);

    function supportedActions() external view returns (string[] memory);

    function rightsOwned(
        address owner,
        Structs.Policy[] memory policies,
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";

interface IERC755Receiver {
    function onERC755Received(
        address operator,
        address from,
        uint256 tokenId,
        Structs.Policy[] memory rights,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Structs.sol";

contract PaymentSplitter is Context {
    using AddressUpgradeable for address;

    address private _owner;

    event PayeeAdded(address account, string role);

    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(uint256 amount, uint256 tokenId);

    Structs.RoyaltyReceiver[] private _royaltyReceivers;
    uint256 private _tokenId;

    uint256 private highestPrice;

    constructor(
        Structs.RoyaltyReceiver[] memory royaltyReceivers,
        uint256 tokenId
    ) payable {
        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            require(
                bytes(royaltyReceivers[i].role).length > 0,
                "role is empty"
            );
            require(
                royaltyReceivers[i].percentage > 0 ||
                royaltyReceivers[i].fixedCut > 0,
                "no royalties"
            );
            _royaltyReceivers.push(
                royaltyReceivers[i]
            );
        }
        _tokenId = tokenId;

        _owner = _msgSender();
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "PS: caller is not the owner");
        _;
    }

    function hasRoyaltyReceivers() external view onlyOwner returns (bool) {
        return _royaltyReceivers.length > 0;
    }

    function addPayee(
        Structs.RoyaltyReceiver memory royaltyReceiver
    ) external onlyOwner {
        require(royaltyReceiver.wallet != address(0),
            "addPayee: wallet is the zero address"
        );
        require(
            royaltyReceiver.percentage > 0 || royaltyReceiver.fixedCut > 0,
            "addPayee: shares are 0"
        );

        _royaltyReceivers.push(
            royaltyReceiver
        );

        emit PayeeAdded(royaltyReceiver.wallet, royaltyReceiver.role);
    }

    function _removeRoyaltyReceiver(
        address payee
    ) private {
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            if (_royaltyReceivers[i].wallet == payee) {
                if (i == _royaltyReceivers.length - 1) {
                    _royaltyReceivers.pop();
                } else {
                    for (uint256 j = i; j < _royaltyReceivers.length - 1; j++) {
                        _royaltyReceivers[j] = _royaltyReceivers[j + 1];
                    }
                    _royaltyReceivers.pop();
                }
            }
        }
    }

    receive() external payable {
        emit PaymentReceived(msg.value, _tokenId);
    }

    function _calculatePercentage(
        uint256 number,
        uint256 percentage
    ) private pure returns (uint256) {
        // https://ethereum.stackexchange.com/a/55702
        // https://www.investopedia.com/terms/b/basispoint.asp
        return number * percentage / 10000;
    }

    function calculatePayment(
        uint256 totalReceived,
        uint256 percentage,
        uint256 fixedCut,
        uint256 CAPPS
    ) private pure returns (uint256) {
        require(totalReceived > 0, "release amount == 0");
        require(
            percentage > 0 || fixedCut > 0 || CAPPS > 0,
            "no royalties to send"
        );

        return _calculatePercentage(totalReceived, percentage) + fixedCut + CAPPS;
    }

    function releasePayment(
        uint256 currentPaymentFunds,
        address payable paymentReceiver
    ) external onlyOwner {
        uint256 released = 0;

        if (_royaltyReceivers.length > 0) {
            uint256 CAPPS = 0;
            if (currentPaymentFunds > highestPrice && highestPrice > 0) {
                CAPPS = currentPaymentFunds - highestPrice;
            }

            for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
                uint256 CAPPSShare = 0;
                if (CAPPS > 0) {
                    CAPPSShare = _calculatePercentage(
                        CAPPS,
                        _royaltyReceivers[i].CAPPS
                    );
                }

                Structs.RoyaltyReceiver memory currentRoyaltyReceiver = _royaltyReceivers[i];

                if (
                    _royaltyReceivers[i].percentage !=
                    _royaltyReceivers[i].resalePercentage
                ) {
                    _royaltyReceivers[i].percentage =
                        _royaltyReceivers[i].resalePercentage;
                    if (
                        _royaltyReceivers[i].percentage == 0 &&
                        _royaltyReceivers[i].fixedCut == 0 &&
                        _royaltyReceivers[i].CAPPS == 0
                    ) {
                        _removeRoyaltyReceiver(_royaltyReceivers[i].wallet);
                    }
                }

                if (
                    currentRoyaltyReceiver.percentage > 0 ||
                    currentRoyaltyReceiver.fixedCut > 0 ||
                    CAPPSShare > 0
                ) {
                    uint256 payment = calculatePayment(
                        currentPaymentFunds,
                        currentRoyaltyReceiver.percentage,
                        currentRoyaltyReceiver.fixedCut,
                        CAPPSShare
                    );
                    released += payment;

                    emit PaymentReleased(currentRoyaltyReceiver.wallet, payment);
                    AddressUpgradeable.sendValue(currentRoyaltyReceiver.wallet, payment);
                }
            }

            if (currentPaymentFunds > highestPrice) {
                highestPrice = currentPaymentFunds;
            }
        }

        if (currentPaymentFunds - released > 0) {
            emit PaymentReleased(paymentReceiver, currentPaymentFunds - released);
            AddressUpgradeable.sendValue(paymentReceiver, currentPaymentFunds - released);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct RoyaltyReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
        uint256 resalePercentage;
        uint256 CAPPS;
        uint256 fixedCut;
    }

    struct Party {
        string role;
        address wallet;
    }

    struct Policy {
        string action;
        uint256 target;
        Party permission;
    }

    struct SupportedAction {
        string action;
        string group;
    }

    struct BasicOperation {
        string operation;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}