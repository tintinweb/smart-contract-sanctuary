/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/TOEIMarketplace.sol

pragma solidity 0.8.4;

/// @title Marketplace to list, sell and buy fixed price tokens
contract TOEIMarketplace {
    /// @dev To store data in specific format
    struct saleStruct {
        uint256 amount;
        uint256 keyId; /// index of listedTokenKeys - makes easier to trace
        address owner;
        bool active;
    }
    /// @dev To return data in required format
    struct saleResponseStruct {
        address contractAddress;
        uint32 tokenId;
        uint256 amount;
        address owner;
    }
    /// @dev Contains address and token Id
    struct KeyStruct {
        address contractAddress;
        uint32 tokenId;
    }
    /// @dev Contract Address to tokenID to Sell Token Struct. For easier access later
    mapping(address => mapping(uint256 => saleStruct)) public salesList;
    /// @dev Easier looping for data while retrieving
    KeyStruct[] public listedTokenKeys;

    bool private initialized;
    /// @dev Responsible for fund transfer, change in gross pay and transferring admin privileges
    address public TOEIAdmin;
    /// @dev Gross pay percent in terms of gross pay precent * 100 to support two decimal digits
    uint256 public grossPay;

    /// @notice Store TOEI Admin address and gross pay
    /// @dev Supply commission percent multiplied by 100
    /// @param _admin Address of the TOEI Admin
    /// @param _commissionPercent Commission percent to calculate gross pay
    function initialize(address _admin, uint256 _commissionPercent) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        TOEIAdmin = _admin;
        grossPay = (10000 - _commissionPercent);
    }

    /// @notice Change of TOEI Admin
    /// @param _prevAdmin Address of the previous TOEI Admin
    /// @param _newAdmin Address of the new TOEI Admin
    event TOEIAdminAddressChanged(
        address indexed _prevAdmin,
        address indexed _newAdmin
    );

    /// @notice Change in Gross pay
    event GrossPayChanged(
        uint256 indexed _prevGrossPay,
        uint256 indexed _newGrossPay
    );

    /// @notice TOEI Admin transferred funds to their address
    /// @param _amount In terms of wei
    event TransferredToTOEIAdmin(uint256 _amount);

    /// @notice Token listed for sale
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _owner Owner of the token
    /// @param _amount Fixed price for buyer in Wei
    event TokenListed(
        address indexed _contractAddress,
        uint32 indexed _tokenId,
        address indexed _owner,
        uint256 _amount
    );

    /// @notice Seller updated the price
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _owner Owner of the token
    /// @param _prevAmount Price before the change
    /// @param _updatedAmount Price after the change
    event AmountUpdated(
        address indexed _contractAddress,
        uint32 indexed _tokenId,
        address indexed _owner,
        uint256 _prevAmount,
        uint256 _updatedAmount
    );

    /// @notice Someone bought the token
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token sold
    /// @param _owner Owner of the token
    /// @param _buyer Address of the buyer
    /// @param _grossPay Amount paid to the seller/owner
    /// @param _commission Amount deducted as commission
    event TokenSold(
        address indexed _contractAddress,
        uint32 indexed _tokenId,
        address indexed _owner,
        address _buyer,
        uint256 _grossPay,
        uint256 _commission
    );

    /// @notice Seller canceled the listing for sale
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    event ListingCanceled(
        address indexed _contractAddress,
        uint32 indexed _tokenId
    );

    /// modifiers
    modifier checkDuplicate(address _contractAddress, uint32 _tokenId) {
        require(
            !salesList[_contractAddress][_tokenId].active,
            "TOEI: Duplicate listing."
        );
        _;
    }

    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0, "TOEI: Must be greater than zero.");
        _;
    }

    modifier amountShouldBeAskingPrice(
        address _contractAddress,
        uint32 _tokenId
    ) {
        require(
            msg.value == salesList[_contractAddress][_tokenId].amount,
            "TOEI: Asking price did not match."
        );
        _;
    }

    modifier onlyTOEIAdmin() {
        require(msg.sender == TOEIAdmin, "TOEI: only TOEI admin.");
        _;
    }

    /// @notice Returns owner of the ERC-721 token
    /// @dev Re-used multiple times
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @return Address of the token owner
    function getTokenOwner(address _contractAddress, uint32 _tokenId)
        private
        view
        returns (address)
    {
        return IERC721(_contractAddress).ownerOf(_tokenId);
    }

    /// @notice Changes the existing TOEI Admin
    /// @param _newAdmin Address of the new TOEI Admin
    /// @custom:modifier Only existing TOEI Admin can change the address
    function changeTOEIAdmin(address _newAdmin) external onlyTOEIAdmin {
        TOEIAdmin = _newAdmin;
        emit TOEIAdminAddressChanged(msg.sender, TOEIAdmin);
        delete _newAdmin;
    }

    /// @notice Changes the existing gross pay
    /// @param _newCommissionPercent New commission percent multiplied by 100
    /// @custom:modifier Only existing TOEI Admin can change the gross pay
    function changeCommission(uint256 _newCommissionPercent)
        external
        onlyTOEIAdmin
    {
        uint256 _grossPay = grossPay;
        grossPay = (10000 - _newCommissionPercent);
        emit GrossPayChanged(_grossPay, grossPay);
        delete _grossPay;
        delete _newCommissionPercent;
    }

    /// @notice Transfers ETH to TOEI Admin address
    /// @param _amount Amount to be transferred in Wei
    /// @custom:modifier Only existing TOEI Admin can transfer funds
    function transferToTOEIAdmin(uint256 _amount) external onlyTOEIAdmin {
        payable(TOEIAdmin).transfer(_amount);
        emit TransferredToTOEIAdmin(_amount);
        delete _amount;
    }

    /// @notice Lists token for sell by owner
    /// @dev Approval part handled in the frontend
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _amount Amount for the token to be sold in Wei
    /// @custom:modifier No duplicate entry is allowed
    /// @custom:modifier Amount must be greater than zero
    /// @custom:modifier Only owner of the token can list token for sale
    /// @custom:modifier Owner should approve marketplace address for token tranfer
    function sellToken(
        address _contractAddress,
        uint32 _tokenId,
        uint256 _amount
    )
        external
        checkDuplicate(_contractAddress, _tokenId)
        greaterThanZero(_amount)
    {
        address owner = getTokenOwner(_contractAddress, _tokenId);
        require((owner == msg.sender), "TOEI: Only owner.");

        require(
            IERC721(_contractAddress).isApprovedForAll(owner, address(this)),
            "TOEI: Approval required."
        );

        listedTokenKeys.push(KeyStruct(_contractAddress, _tokenId));
        salesList[_contractAddress][_tokenId] = saleStruct(
            _amount,
            listedTokenKeys.length - 1,
            msg.sender,
            true
        );

        emit TokenListed(_contractAddress, _tokenId, msg.sender, _amount);

        delete _contractAddress;
        delete _tokenId;
        delete _amount;
        delete owner;
    }

    /// @notice Updates amount for listed token
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _amount Updated amount for the token to be sold in Wei
    /// @custom:modifier Only owner of the token can list token for sale
    function updateAmount(
        address _contractAddress,
        uint32 _tokenId,
        uint256 _amount
    ) external {
        require(
            (salesList[_contractAddress][_tokenId].owner == msg.sender),
            "TOEI: Only owner."
        );

        uint256 prevAmount = salesList[_contractAddress][_tokenId].amount;
        salesList[_contractAddress][_tokenId].amount = _amount;

        emit AmountUpdated(
            _contractAddress,
            _tokenId,
            msg.sender,
            prevAmount,
            _amount
        );

        delete _contractAddress;
        delete _tokenId;
        delete prevAmount;
        delete _amount;
    }

    /// @notice Cancels listed token
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @dev Triggered when token is transferred to other address
    /// @custom:modifier Only owner or holding contract of the token can list token for sale
    function cancelListing(address _contractAddress, uint32 _tokenId) external {
        require(
            (salesList[_contractAddress][_tokenId].owner == msg.sender) ||
                _contractAddress == msg.sender,
            "TOEI: Only owner or collectible contract."
        );

        delete listedTokenKeys[salesList[_contractAddress][_tokenId].keyId];
        delete salesList[_contractAddress][_tokenId];
        emit ListingCanceled(_contractAddress, _tokenId);
        delete _contractAddress;
        delete _tokenId;
    }

    /// @notice Buys token for the sender
    /// @dev payment is divided by 10000. 100 for percent and 100 for we manually added
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed to be bought
    /// @custom:modifier Amount should match
    /// @custom:modifier Only owner of the token can list token for sale
    /// @custom:modifier Owner should approve marketplace address for token tranfer
    function buyToken(address _contractAddress, uint32 _tokenId)
        external
        payable
        amountShouldBeAskingPrice(_contractAddress, _tokenId)
    {
        address owner = salesList[_contractAddress][_tokenId].owner;

        require(owner != msg.sender, "TOEI: Owner can not buy token.");
        require(
            IERC721(_contractAddress).isApprovedForAll(owner, address(this)),
            "TOEI: Approval required."
        );

        uint256 payment = (msg.value * grossPay) / 10000;

        delete listedTokenKeys[salesList[_contractAddress][_tokenId].keyId];
        delete salesList[_contractAddress][_tokenId];

        IERC721(_contractAddress).safeTransferFrom(owner, msg.sender, _tokenId);
        payable(owner).transfer(payment);

        emit TokenSold(
            _contractAddress,
            _tokenId,
            owner,
            msg.sender,
            payment,
            (msg.value - payment)
        );

        delete _contractAddress;
        delete _tokenId;
        delete payment;
        delete owner;
    }

    /// @notice Returns list of token listed for sale
    /// @dev Deleted tokens' slot will be occupied by zeros in the end of the array
    /// @return Sale list with details contract address, token id, amount and owner
    function getAllSales() external view returns (saleResponseStruct[] memory) {
        saleResponseStruct[] memory sales = new saleResponseStruct[](
            listedTokenKeys.length
        );
        uint256 _count = 0;

        for (uint256 index = 0; index < listedTokenKeys.length; index++) {
            saleResponseStruct memory saleRes;
            saleStruct memory sale = salesList[
                listedTokenKeys[index].contractAddress
            ][listedTokenKeys[index].tokenId];

            saleRes.contractAddress = listedTokenKeys[index].contractAddress;
            saleRes.tokenId = listedTokenKeys[index].tokenId;
            saleRes.amount = sale.amount;
            saleRes.owner = sale.owner;

            if (sale.active) {
                sales[_count] = saleRes;
                _count += 1;
            }
        }
        return sales;
    }
}