pragma solidity ^0.8.0;

import "./CustomERC1155.sol";

contract SimpleERC1155 is CustomERC1155 {

    /*
     * Params
     * address owner_ - Address that will become contract owner
     * address decryptMarketplaceAddress_ - Decrypt Marketplace proxy address
     * string memory uri_ - Base token URI
     * uint256 royalty_ - Base royaly in basis points (1000 = 10%)
     */
    constructor(
        address owner_,
        address decryptMarketplaceAddress_,
        string memory uri_,
        uint256 royalty_
    )
        CustomERC1155(
            owner_,
            decryptMarketplaceAddress_,
            uri_,
            royalty_
        )
    {}

}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import "./RoyaltyDistribution.sol";
import "./PreSale1155.sol";
import "./I_NFT.sol";
import "./IRoyaltyDistribution.sol";

contract CustomERC1155 is RoyaltyDistribution, ERC1155 {

    event UpdatedURI(
        string _uri
    );

    address public decryptMarketplaceAddress;

    modifier onlyDecrypt {
        require(msg.sender == decryptMarketplaceAddress, 'Unauthorized');
        _;
    }

    /*
     * Params
     * address owner_ - Address that will become contract owner
     * address decryptMarketplaceAddress_ - Decrypt Marketplace proxy address
     * string memory uri_ - Base token URI
     * uint256 royalty_ - Base royalty in basis points (1000 = 10%)
     */
    constructor(
        address owner_,
        address decryptMarketplaceAddress_,
        string memory uri_,
        uint256 royalty_
    )
        ERC1155(uri_)
    {
        globalRoyalty = royalty_;
        transferOwnership(owner_);
        royaltyReceiver = owner_;
        decryptMarketplaceAddress = decryptMarketplaceAddress_;
    }



    /*
     * Params
     * string memory uri_ - new base token URI
     *
     * Function sets new base token URI
     */
    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);

        emit UpdatedURI(
            uri_
        );
    }


    /*
     * Params
     * address account - Who will be the owner of this token?
     * uint256 id - ID index of the token you want to mint
     * uint256 amount - Amount of tokens to mint
     *
     * Mints specific amount of tokens with specific ID and sets specific address as their owner
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(account, id, amount,'0x');
    }


    /*
     * Params
     * address to - Who will be the owner of these tokens?
     * uint256[] memory ids - List of IDs to mint
     * uint256[] memory amounts - List of corresponding amounts
     *
     * Mints specific amounts of tokens with specific IDs and sets specific address as their owner
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts,'0x');
    }


    /*
     * Params
     * address to - Who will be the owner of this token?
     * uint256 tokenId - ID index of the token you want to mint
     * uint256 amount - Quantity of tokens to lazy mint
     *
     * Allows Decrypt marketplace to mint tokens
     */
    function lazyMint(address to, uint256 tokenId, uint256 amount) external onlyDecrypt {
        _mint(to, tokenId, amount,'0x');
    }


    /*
     * Params
     * bytes4 interfaceId - interface ID
     *
     * Called to determine interface support
     * Called by marketplace to determine if contract supports IERC2981, that allows royalty calculation.
     * Also called by marketplace to determine if contract supports lazy mint and royalty distribution.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(ILazyMint1155).interfaceId ||
        interfaceId == type(IRoyaltyDistribution).interfaceId ||
        super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC2981.sol";



abstract contract RoyaltyDistribution is Ownable, IERC2981{

    struct RoyaltyShare {
        address collaborator;
        uint256 share;
    }

    bool public globalRoyaltyEnabled = true;

    // if royaltyDistributionEnabled == (false) - all royalties go to royaltyReceiver
    // if royaltyDistributionEnabled == (true) - all royalties
    // are divided between collaborators according to specified shares and rest goes to royaltyReceiver
    // Royalties distribution is not supported by IERC2981 standard and will only work on Decrypt marketplace
    bool public royaltyDistributionEnabled = true;

    //royalty percent in basis points (1000 = 10%)
    uint256 public globalRoyalty;
    //personal token royalty amount - in basis points.
    mapping(uint256 => uint256) public tokenRoyalty;

    //List of collaborators, who will receive the share of royalty. Empty by default
    RoyaltyShare[] private defaultCollaboratorsRoyaltyShare;
    //tokenId => royalty distribution for this token
    mapping(uint256 => RoyaltyShare[]) public tokenCollaboratorsRoyaltyShare;

    address public royaltyReceiver;



    /*
    * Params
    * uint256 _tokenId - the NFT asset queried for royalty information
    * uint256 _salePrice - the sale price of the NFT asset specified by _tokenId
    *
    * Called with the sale price by marketplace to determine the amount of royalty
    * needed to be paid to a wallet for specific tokenId.
    */
    function royaltyInfo
    (
        uint256 _tokenId,
        uint256 _salePrice
    )
    external
    view
    override
    returns (
        address receiver,
        uint256 royaltyAmount
    ){
        uint256 royaltyAmount;
        if(globalRoyaltyEnabled){
            if(tokenRoyalty[_tokenId] == 0){
                royaltyAmount = _salePrice * globalRoyalty / 10000;
            }else{
                royaltyAmount = _salePrice * tokenRoyalty[_tokenId] / 10000;
            }
        }else{
            royaltyAmount = 0;
        }
        return (royaltyReceiver, royaltyAmount);
    }


    /*
     * Params
     * address newRoyaltyReceiver - address of wallet/contract who will receive royalty by default
     *
     * Sets new address of royalty receiver.
     * If royalty distributes among collaborators,
     * this address will receive the rest of the royalty after substraction
     */
    function setRoyaltyReceiver (address newRoyaltyReceiver) external onlyOwner {
        require(newRoyaltyReceiver != address(0), 'Cant set 0 address');
        require(newRoyaltyReceiver != royaltyReceiver, 'This address is already a receiver');
        royaltyReceiver = newRoyaltyReceiver;
    }


    /*
     * Params
     * uint256 _royalty - Royalty amount in basis points (10% = 1000)
     *
     * Sets default royalty amount
     * This amount will be sent to royalty receiver or/and distributed among collaborators
     */
    function setGlobalRoyalty (uint256 _royalty) external onlyOwner {
        require(_royalty <= 9000,'Royalty is over 90%');
        globalRoyalty = _royalty;
    }


    /*
     * Params
     * uint256 _royalty - Royalty amount in basis points (10% = 1000)
     *
     * Sets individual token royalty amount
     * If it's 0 - global royalty amount will be used instead
     * This amount will be sent to royalty receiver or/and distributed among collaborators
     */
    function setTokenRoyalty (uint256 _royalty, uint256 _tokenId) external onlyOwner {
        require(_royalty <= 9000,'Royalty is over 90%');
        tokenRoyalty[_tokenId] = _royalty;
    }


    /*
     * Disables any royalty for all NFT contract
     */
    function disableRoyalty() external onlyOwner {
        globalRoyaltyEnabled = false;
    }


    /*
     * Enables royalty for all NFT contract
     */
    function enableRoyalty() external onlyOwner {
        globalRoyaltyEnabled = true;
    }


    /*
     * Disables distribution of any royalty. All royalties go straight to royaltyReceiver
     */
    function disableRoyaltyDistribution() external onlyOwner {
        royaltyDistributionEnabled = false;
    }


    /*
     * Disables distribution of any royalty. All royalties go straight to royaltyReceiver
     */
    function enableRoyaltyDistribution() external onlyOwner {
        royaltyDistributionEnabled = true;
    }


    /*
     * Params
     * address[] calldata collaborators - array of addresses to receive royalty share
     * uint256[] calldata shares - array of shares in basis points  for collaborators (basis points).
     * Example: 1000 = 10% of royalty
     *
     * Function sets default royalty distribution
     * Royalty distribution is not supported by IERC2981 standard and will only work on Decrypt marketplace
     */
    function setDefaultRoyaltyDistribution(
        address[] calldata collaborators,
        uint256[] calldata shares
    ) external onlyOwner {
        require(collaborators.length == shares.length, 'Arrays dont match');

        uint256 totalShares = 0;
        for (uint i=0; i<shares.length; i++){
            totalShares += shares[i];
        }
        require(totalShares <= 10000, 'Total shares > 10000');


        delete defaultCollaboratorsRoyaltyShare;
        for (uint i=0; i<collaborators.length; i++){
            defaultCollaboratorsRoyaltyShare.push(RoyaltyShare({
            collaborator: collaborators[i],
            share: shares[i]
            }));
        }
    }


    /*
     * Function returns array of default royalties distribution
     * Royalties distribution is not supported by IERC2981 standard and will only work on Decrypt marketplace
     */
    function getDefaultRoyaltyDistribution()
    public
    view
    returns(RoyaltyShare[] memory)
    {
        return defaultCollaboratorsRoyaltyShare;
    }


    /*
     * Params
     * address[] calldata collaborators - array of addresses to receive royalty share
     * uint256[] calldata shares - array of shares in basis points  for collaborators (basis points).
     * Example: 1000 = 10% of royalty
     * uint256 tokenId - Token index ID
     *
     * Function sets default royalty distribution
     * Royalty distribution is not supported by IERC2981 standard and will only work on Decrypt marketplace
     */
    function setTokenRoyaltyDistribution(
        address[] calldata collaborators,
        uint256[] calldata shares,
        uint256 tokenId
    ) external onlyOwner {
        require(collaborators.length == shares.length, 'Arrays dont match');

        uint256 totalShares = 0;
        for (uint i=0; i<shares.length; i++){
            totalShares += shares[i];
        }
        require(totalShares <= 10000, 'Total shares > 10000');


        delete tokenCollaboratorsRoyaltyShare[tokenId];

        for (uint i=0; i<collaborators.length; i++){
            tokenCollaboratorsRoyaltyShare[tokenId].push(RoyaltyShare({
            collaborator: collaborators[i],
            share: shares[i]
            }));
        }
    }


    /*
     * Params
     * uint256 tokenId - ID index of token
     *
     * Function returns array of royalties distribution specified for this token
     * If it's empty, default royalty distribution will be used instead
     * Royalties distribution is not supported by IERC2981 standard and will only work on Decrypt marketplace
     */
    function getTokenRoyaltyDistribution(uint256 tokenId)
    public
    view
    returns(RoyaltyShare[] memory)
    {
        return tokenCollaboratorsRoyaltyShare[tokenId];
    }

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PreSale1155 is Ownable{

    event NewPreSale(
        uint256 _eventId,
        uint256 _maxTokensPerWallet,
        uint256 _maxTokensOfSameIdPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForTier,
        uint256 _price,
        bool _whiteList
    );

    event UpdatedPreSale(
        uint256 _eventId,
        uint256 _maxTokensPerWallet,
        uint256 _maxTokensOfSameIdPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForTier,
        uint256 _price,
        bool _whiteList
    );

    struct PreSaleEventInfo {
        uint256 maxTokensPerWallet;
        uint256 maxTokensOfSameIdPerWallet;
        uint256 startTime;
        uint256 endTime;
        uint256 maxTokensForEvent;
        uint256 tokensSold;
        uint256 price;
        bool whiteList;
    }

    // eventId => tokenId => token price
    mapping(uint256 => mapping(uint256 => uint256)) public specialPrice;
    // eventId => user address => quantity
    mapping(uint256 => mapping(address => uint256)) private tokensBoughtDuringEvent;
    // eventId => token ID => user address => quantity
    mapping (uint256 => mapping(uint256 => mapping(address => uint256))) private tokensOfSameIdBoughtDuringEvent;
    // user address => eventId => whitelisted
    mapping(address => mapping(uint256 => bool)) public isAddressWhitelisted;
    // eventId => PreSaleEventInfo
    // Contains all Event information. Should be called on Front End to receive up-to-date information
    PreSaleEventInfo[] public preSaleEventInfo;
    //address(0) for ETH, anything else - for ERC20
    address public preSalePaymentToken;


    /*
     * Params
     * address buyer - Buyer address
     * uint256 tokenId - ID index of tokens, user wants to buy
     * uint256 quantity - Quantity of tokens, user wants to buy
     * uint256 eventId - Event ID index
     *
     * Function returns price of single token for specific buyer, event ID and quantity
     * and decides if user can buy these tokens
     * {availableForBuyer} return param decides if buyer can purchase right now
     * This function should be called on Front End before any pre purchase transaction
     */
    function getTokenInfo
    (
        address buyer,
        uint256 tokenId,
        uint256 quantity,
        uint256 eventId
    )
        external
        view
        returns (uint256 tokenPrice, address paymentToken, bool availableForBuyer)
    {
        uint256 tokenPrice = preSaleEventInfo[eventId].price;
        bool availableForBuyer = true;

        //Special price check
        if(specialPrice[eventId][tokenId] != 0){
            tokenPrice = specialPrice[eventId][tokenId];
        }


        if((    //Whitelist check
            preSaleEventInfo[eventId].whiteList
            && isAddressWhitelisted[buyer][eventId] == false
            )||( //Time check
            block.timestamp < preSaleEventInfo[eventId].startTime
            || block.timestamp > preSaleEventInfo[eventId].endTime
            )||( //Maximum tokens for event check
            preSaleEventInfo[eventId].maxTokensForEvent != 0 &&
            (preSaleEventInfo[eventId].tokensSold + quantity) > preSaleEventInfo[eventId].maxTokensForEvent
            )||( //Maximum tokens per wallet
            preSaleEventInfo[eventId].maxTokensPerWallet != 0
            && tokensBoughtDuringEvent[eventId][buyer] + quantity > preSaleEventInfo[eventId].maxTokensPerWallet
            )||( //Maximum tokens of same ID per wallet
            preSaleEventInfo[eventId].maxTokensPerWallet != 0
            && tokensOfSameIdBoughtDuringEvent[eventId][tokenId][buyer] + quantity > preSaleEventInfo[eventId].maxTokensOfSameIdPerWallet
        ))
        {
            availableForBuyer = false;
        }

        return (tokenPrice, preSalePaymentToken, availableForBuyer);
    }

    /*
     * Params
     * uint256 _maxTokensPerWallet - How many tokens in total a wallet can buy?
     * uint256 _maxTokensOfSameIdPerWallet - How many tokens of same ID in total a wallet can buy?
     * uint256 _startTime - When does the sale for this event start?
     * uint256 _startTime - When does the sale for this event end?
     * uint256 _maxTokensForEvent - What is the total amount of tokens sold in this Event?
     * uint256 _price - What is the price per one token?
     * bool _whiteList - Will event allow to participate only whitelisted addresses?
     *
     * Adds new presale event to the list (array)
     */
    function createPreSaleEvent(
        uint256 _maxTokensPerWallet,
        uint256 _maxTokensOfSameIdPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForEvent,
        uint256 _price,
        bool _whiteList
    )
        external
        onlyOwner
    {
        require(_startTime < _endTime, 'Wrong timeline');

        preSaleEventInfo.push(
            PreSaleEventInfo({
                maxTokensPerWallet: _maxTokensPerWallet,
                maxTokensOfSameIdPerWallet: _maxTokensOfSameIdPerWallet,
                startTime: _startTime,
                endTime: _endTime,
                maxTokensForEvent: _maxTokensForEvent,
                tokensSold: 0,
                price: _price,
                whiteList: _whiteList
            })
        );

        emit NewPreSale(
            (preSaleEventInfo.length - 1),
            _maxTokensPerWallet,
            _maxTokensOfSameIdPerWallet,
            _startTime,
            _endTime,
            _maxTokensForEvent,
            _price,
            _whiteList
        );
    }


    /*
     * Params
     * uint256 _eventId - ID index of event
     * uint256 _maxTokensPerWallet - How many tokens in total a wallet can buy?
     * uint256 _maxTokensOfSameIdPerWallet - How many tokens of same ID in total a wallet can buy?
     * uint256 _startTime - When does the sale for this event start?
     * uint256 _startTime - When does the sale for this event end?
     * uint256 _maxTokensForEvent - What is the total amount of tokens sold in this Event?
     * uint256 _price - What is the price per one token?
     * bool _whiteList - Will event allow to participate only whitelisted addresses?
     *
     * Updates presale event in the list (array)
     */
    function updatePreSaleEvent(
        uint256 _eventId,
        uint256 _maxTokensPerWallet,
        uint256 _maxTokensOfSameIdPerWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensForEvent,
        uint256 _price,
        bool _whiteList
    )
        external
        onlyOwner
    {
        require(_startTime < _endTime, 'Wrong timeline');
        require(preSaleEventInfo[_eventId].startTime > block.timestamp, 'Event is already in progress');

        preSaleEventInfo[_eventId].maxTokensPerWallet = _maxTokensPerWallet;
        preSaleEventInfo[_eventId].maxTokensOfSameIdPerWallet = _maxTokensOfSameIdPerWallet;
        preSaleEventInfo[_eventId].startTime = _startTime;
        preSaleEventInfo[_eventId].endTime = _endTime;
        preSaleEventInfo[_eventId].maxTokensForEvent = _maxTokensForEvent;
        preSaleEventInfo[_eventId].price = _price;
        preSaleEventInfo[_eventId].whiteList = _whiteList;

        emit UpdatedPreSale(
            _eventId,
            _maxTokensPerWallet,
            _maxTokensOfSameIdPerWallet,
            _startTime,
            _endTime,
            _maxTokensForEvent,
            _price,
            _whiteList
        );
    }


    /*
     * Params
     * uint256 eventId - Event ID index
     * address buyer - User that should be whitelisted
     *
     * Function add user to whitelist of private event
     */
    function addToWhitelist(
        uint256 eventId,
        address buyer
    ) external onlyOwner {
        require(preSaleEventInfo[eventId].whiteList, 'Event is not private');
        isAddressWhitelisted[buyer][eventId] = true;
    }


    /*
     * Params
     * uint256 eventId - Event ID index
     * uint256 tokenId - Index ID of token, that should have special price
     * uint256 price - Price for this token ID during this event
     *
     * Function sets special price for a token of specific ID for a specific event
     */
    function setSpecialPriceForToken(
        uint256 eventId,
        uint256 tokenId,
        uint256 price
    ) external onlyOwner{
        specialPrice[eventId][tokenId] = price;
    }


    /*
     * Params
     * address buyer - User address, who bought the tokens
     * uint256 tokenId - Index ID of token sold
     * uint256 amount - Amount of tokens sold
     * uint256 eventId - Event ID index
     *
     * Function counts tokens bought for different counters
     */
    function _countTokensBought(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        uint256 eventId
    ) internal {
        if(preSaleEventInfo[eventId].maxTokensPerWallet != 0){
            tokensBoughtDuringEvent[eventId][buyer] += amount;

            if(preSaleEventInfo[eventId].maxTokensOfSameIdPerWallet != 0){
                tokensOfSameIdBoughtDuringEvent[eventId][tokenId][buyer] += amount;
            }
        }
        preSaleEventInfo[eventId].tokensSold += amount;
    }


    /*
     * Params
     * address _preSalePaymentToken - ERC20 address for payment token/ 0 address for ETH
     *
     * Function sets payment token address for pre sale transactions
     */
    function setPreSalePaymentToken (address _preSalePaymentToken) external onlyOwner{
        preSalePaymentToken = _preSalePaymentToken;
    }
}

pragma solidity ^0.8.0;

interface ICreator {
    function deployedTokenContract(address) external view returns(bool);
}

interface ILazyMint721 {
    function exists(uint256 tokenId) external view returns (bool);
    function owner() external view returns (address);
    function lazyMint(address to, uint256 tokenId) external;
}

interface ILazyMint1155 {
    function owner() external view returns (address);
    function lazyMint(address to, uint256 tokenId, uint256 amount) external;
}

interface IPreSale721 {
    function getTokenInfo (address buyer, uint256 tokenId, uint256 eventId)
        external view returns (uint256 tokenPrice, address paymentToken, bool availableForBuyer);
    function countTokensBought(uint256 eventId, address buyer) external;
}

interface IPreSale1155 {
    function getTokenInfo(address buyer, uint256 tokenId, uint256 quantity, uint256 eventId)
        external view returns (uint256 tokenPrice, address paymentToken, bool availableForBuyer);
    function countTokensBought(address buyer, uint256 tokenId, uint256 amount, uint256 eventId) external;
}

pragma solidity ^0.8.0;

interface IRoyaltyDistribution {
    function globalRoyaltyEnabled() external returns(bool);
    function royaltyDistributionEnabled() external returns(bool);
    function defaultCollaboratorsRoyaltyShare() external returns(RoyaltyShare[] memory);


    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function getDefaultRoyaltyDistribution() external view returns(RoyaltyShare[] memory);

    function getTokenRoyaltyDistribution(uint256 tokenId) external view returns(RoyaltyShare[] memory);

}

struct RoyaltyShare {
    address collaborator;
    uint256 share;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

//interface IERC165 {
//    /// @notice Query if a contract implements an interface
//    /// @param interfaceID The interface identifier, as specified in ERC-165
//    /// @dev Interface identification is specified in ERC-165. This function
//    ///  uses less than 30,000 gas.
//    /// @return `true` if the contract implements `interfaceID` and
//    ///  `interfaceID` is not 0xffffffff, `false` otherwise
//    function supportsInterface(bytes4 interfaceID) external view returns (bool);
//}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";