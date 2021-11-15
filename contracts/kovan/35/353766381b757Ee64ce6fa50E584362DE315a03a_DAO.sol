//SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IDAO.sol";
import "../utils/Context.sol";
import "../token/interfaces/IBEP20.sol";

contract DAO is Context, IDAO {
    struct Proposal {
        bytes hash;
        address merchant;
        uint8 platformTax;
        uint8 listingFee;
        uint256 votes;
        bool approved;
    }

    address private _token;
    address private _admin;

    uint256 private _merchantsCount;
    uint256 private _proposalsCount;

    mapping(address => bool) private _merchant;
    mapping(uint256 => Proposal) private _proposal;

    modifier onlyOwner() {
        require(_msgSender() == _admin);
        _;
    }

    event CreateMerchant(bytes hash, address merchant, uint8 listingFee, uint8 platformTax, uint256 proposalId);
    event Vote(uint256 proposalId, address voter, uint256 znftShares);

    constructor(address _tokenContract) {
        _token = _tokenContract;
        _admin = _msgSender();
    }

    function createMerchant(
        string memory hash,
        uint8 listingFee,
        uint8 platformTax
    ) public virtual override returns (bool) {
        _proposalsCount += 1;

        _proposal[_proposalsCount] = Proposal(
            bytes(hash),
            _msgSender(),
            platformTax,
            listingFee,
            0,
            false
        );
        emit CreateMerchant(bytes(hash), _msgSender(), listingFee, platformTax, _proposalsCount);
        return true;
    }

    function vote(uint256 proposalId) public virtual override returns (bool) {
        uint256 balance = IBEP20(_token).balanceOf(_msgSender());
        uint256 totalSupply = IBEP20(_token).totalSupply();

        require(balance > 0, "Error: Voter should have ZNFT Shares");
        require(
            proposalId > 0 && proposalId <= _proposalsCount,
            "Error: Invalid Proposal ID"
        );

        Proposal storage p = _proposal[proposalId];
        require(!p.approved, "Error: Proposal already approved");

        p.votes += balance;
        if (p.votes > totalSupply / 2) {
            p.approved = true;
            _merchantsCount += 1;
            _merchant[p.merchant] = true;
        }
        emit Vote(proposalId, _msgSender(), balance);
        return true;
    }

    function updateTokenContract(address _newTokenContract)
        public
        virtual
        returns (bool)
    {
        require(
            _newTokenContract != address(0),
            "Error: New token contract can never be zero"
        );
        _token = _newTokenContract;
        return true;
    }

    function isMerchant(address _merchantAddress)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _merchant[_merchantAddress];
    }

    function totalProposals() public view virtual returns (uint256) {
        return _proposalsCount;
    }

    function totalMerchants() public view virtual returns (uint256) {
        return _merchantsCount;
    }

    function proposal(uint256 proposalId)
        public
        view
        virtual
        returns (
            string memory hash,
            address merchant,
            uint256 totalVotes,
            bool approved
        )
    {
        require(
            proposalId > 0 && proposalId <= _proposalsCount,
            "Error: Invalid Proposal ID"
        );

        Proposal storage p = _proposal[proposalId];
        return (string(p.hash), p.merchant, p.votes, p.approved);
    }
}

//SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface IDAO {
    /**
     * @dev receives the listing for adding new merchants to the marketplace.
     *
     *`hash` is the ipfs hash of the company-info JSON. To reduce gas usuage we're following this approach.
     */
    function createMerchant(
        string memory hash,
        uint8 listingFee,
        uint8 platformTax
    ) external returns (bool);

    /**
     * @dev vote for the approval of merchants.
     *
     * `proposalId` will be the listing Id of the proposal.
     */
    function vote(uint256 proposalId) external returns (bool);

    /**
     * @dev returns if an address is a valid `merchant`
     */
    function isMerchant(address _merchantAddress) external view returns (bool);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * @dev provides information about the current execution context.
 *
 * This includes the sender of the transaction & it's data.
 * Useful for meta-transaction as the message sender & gas payer can be different.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Interface of ZNFT Shares ERC20 Token As in EIP
 */

interface IBEP20 {
    /**
     * @dev returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

