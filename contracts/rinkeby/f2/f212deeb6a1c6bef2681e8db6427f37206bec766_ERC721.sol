/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

/*
name
symbol
Risk Factor
# of Collateral
Past & Current Loans:
Loan Amount
Amount Remaining
Interest Rate
Payment Details
Time Period on Payments
Type of currency
USD Value
Total number of payments/loans
Total Interest
# of Voters - Payout Amount
Any failed loans
Ask: Do we need to make info public when loan is missed? Isnt it better to just show the voters all the info upfront? What kind of info should we show at the start vs make public?
*/
pragma solidity ^0.8.0;

contract ERC721 {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /* Emitted when `owner` enables `approved` to manage the `tokenId` token.*/
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /* Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.*/
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /* @dev Returns the number of tokens in ``owner``'s account. */
    //function balanceOf(address owner) external view returns (uint256 balance);

    /* @dev Returns the owner of the `tokenId` token. Requirements: - `tokenId` must exist.*/
    //function ownerOf(uint256 tokenId) external view returns (address owner);

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        //override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        //override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
}