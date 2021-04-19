// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/IControllable.sol";

abstract contract Controllable is IControllable {
    mapping(address => bool) _controllers;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function _addController(address _controller) internal {
        _controllers[_controller] = true;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address _controller) external override onlyController {
        _controllers[_controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address _address) external view override returns (bool allowed) {
        allowed = _controllers[_address];
    }

    /**
     * @dev Check if this address is a controller
     */
    function relinquishControl() external view override onlyController {
        _controllers[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../interfaces/IProposal.sol";
import "../interfaces/IProposalFactory.sol";
import "../access/Controllable.sol";
import "../libs/Create2.sol";
import "../governance/GovernanceLib.sol";
import "../governance/Proposal.sol";

contract ProposalFactory is Controllable, IProposalFactory {
    address private operator;

    mapping(uint256 => address) private _getProposal;
    address[] private _allProposals;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev get the proposal for this
     */
    function getProposal(uint256 _symbolHash) external view override returns (address proposal) {
        proposal = _getProposal[_symbolHash];
    }

    /**
     * @dev get the proposal for this
     */
    function allProposals(uint256 idx) external view override returns (address proposal) {
        proposal = _allProposals[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allProposalsLength() external view override returns (uint256 proposal) {
        proposal = _allProposals.length;
    }

    /**
     * @dev deploy a new proposal using create2
     */
    function createProposal(
        address submitter,
        string memory title,
        address proposalData,
        IProposal.ProposalType proposalType
    ) external override onlyController returns (address payable proposal) {

        // make sure this proposal doesnt already exist
        bytes32 salt = keccak256(abi.encodePacked(submitter, title));
        require(_getProposal[uint256(salt)] == address(0), "PROPOSAL_EXISTS"); // single check is sufficient

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(Proposal).creationCode;

        // use create2 to deploy the quantized erc20 contract
        proposal = payable(Create2.deploy(0, salt, bytecode));

        // initialize  the proposal with submitter, proposal type, and proposal data
        Proposal(proposal).initialize(submitter, title, proposalData, IProposal.ProposalType(proposalType));

        // add teh new proposal to our lists for management
        _getProposal[uint256(salt)] = proposal;
        _allProposals.push(proposal);

        // emit an event about the new proposal being created
        emit ProposalCreated(submitter, uint256(proposalType), proposal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../interfaces/IERC1155.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemPoolFactory.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/INFTGemPool.sol";
import "../interfaces/IProposal.sol";
import "../interfaces/IProposalData.sol";


library GovernanceLib {

    // calculates the CREATE2 address for the quantized erc20 without making any external calls
    function addressOfPropoal(
        address factory,
        address submitter,
        string memory title
    ) public pure returns (address govAddress) {
        govAddress = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(submitter, title)),
                        hex"74f827a6bb3b7ed4cd86bd3c09b189a9496bc40d83635649e1e4df1c4e836ebf" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev create vote tokens to vote on given proposal
     */
    function createProposalVoteTokens(address multitoken, uint256 proposalHash) external {
        for (uint256 i = 0; i < INFTGemMultiToken(multitoken).allTokenHoldersLength(0); i++) {
            address holder = INFTGemMultiToken(multitoken).allTokenHolders(0, i);
            INFTGemMultiToken(multitoken).mint(holder, proposalHash,
                IERC1155(multitoken).balanceOf(holder, 0)
            );
        }
    }

    /**
     * @dev destroy the vote tokens for the given proposal
     */
    function destroyProposalVoteTokens(address multitoken, uint256 proposalHash) external {
        for (uint256 i = 0; i < INFTGemMultiToken(multitoken).allTokenHoldersLength(0); i++) {
            address holder = INFTGemMultiToken(multitoken).allTokenHolders(0, i);
            INFTGemMultiToken(multitoken).burn(holder, proposalHash,
                IERC1155(multitoken).balanceOf(holder, proposalHash)
            );
        }
    }

        /**
     * @dev execute craete pool proposal
     */
    function execute(
        address factory,
        address proposalAddress) public returns (address newPool) {

        // get the data for the new pool from the proposal
        address proposalData = IProposal(proposalAddress).proposalData();

        (
            string memory symbol,
            string memory name,

            uint256 ethPrice,
            uint256 minTime,
            uint256 maxTime,
            uint256 diffStep,
            uint256 maxClaims,

            address allowedToken
        ) = ICreatePoolProposalData(proposalData).data();

        // create the new pool
        newPool = createPool(
            factory,

            symbol,
            name,

            ethPrice,
            minTime,
            maxTime,
            diffStep,
            maxClaims,

            allowedToken
        );
    }

    /**
     * @dev create a new pool
     */
    function createPool(
        address factory,

        string memory symbol,
        string memory name,

        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,

        address allowedToken
    ) public returns (address pool) {
        pool = INFTGemPoolFactory(factory).createNFTGemPool(
            symbol,
            name,

            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,

            allowedToken
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../utils/Initializable.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemGovernor.sol";
import "../interfaces/INFTGemPool.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IProposal.sol";
import "../interfaces/IProposalFactory.sol";
import "../tokens/ERC1155Holder.sol";
import "../libs/SafeMath.sol";

contract Proposal is Initializable, ERC1155Holder, IProposal {
    using SafeMath for uint256;

    uint256 private constant MONTH = 2592000;
    uint256 private constant PROPOSAL_COST = 1 ether;

    string private _title;
    address private _creator;
    address private _funder;
    address private _multitoken;
    address private _governor;
    uint256 private _expiration;

    address private _proposalData;
    ProposalType private _proposalType;

    bool private _funded;
    bool private _executed;
    bool private _closed;

    constructor() {}

    function initialize(
        address __creator,
        string memory __title,
        address __proposalData,
        ProposalType __proposalType
    ) external override initializer {
        _title = __title;
        _creator = __creator;
        _proposalData = __proposalData;
        _proposalType = __proposalType;
    }

    function setMultiToken(address token) external override {
        require(_multitoken == address(0), "IMMUTABLE");
        _multitoken = token;
    }

    function setGovernor(address gov) external override {
        require(_governor == address(0), "IMMUTABLE");
        _governor = gov;
    }

    function title() external view override returns (string memory) {
        return _title;
    }

    function creator() external view override returns (address) {
        return _creator;
    }

    function funder() external view override returns (address) {
        return _creator;
    }

    function expiration() external view override returns (uint256) {
        return _expiration;
    }

    function _status() internal view returns (ProposalStatus curCtatus) {
        curCtatus = ProposalStatus.ACTIVE;
        if (!_funded) {
            curCtatus = ProposalStatus.NOT_FUNDED;
        } else if (_executed) {
            curCtatus = ProposalStatus.EXECUTED;
        } else if (_closed) {
            curCtatus = ProposalStatus.CLOSED;
        } else {
            uint256 totalVotesSupply = INFTGemMultiToken(_multitoken).totalBalances(uint256(address(this)));
            uint256 totalVotesInFavor = IERC1155(_multitoken).balanceOf(address(this), uint256(address(this)));
            uint256 votesToPass = totalVotesSupply.div(2).add(1);
            curCtatus = totalVotesInFavor >= votesToPass ? ProposalStatus.PASSED : ProposalStatus.ACTIVE;
            if (block.timestamp > _expiration) {
                curCtatus = totalVotesInFavor >= votesToPass ? ProposalStatus.PASSED : ProposalStatus.FAILED;
            }
        }

    }

    function status() external view override returns (ProposalStatus curCtatus) {
        curCtatus = _status();
    }

    function proposalData() external view override returns (address) {
        return _proposalData;
    }

    function proposalType() external view override returns (ProposalType) {
        return _proposalType;
    }

    function fund() external payable override {
        // ensure we cannot fund while in an invalida state
        require(!_funded, "ALREADY_FUNDED");
        require(!_closed, "ALREADY_CLOSED");
        require(!_executed, "ALREADY_EXECUTED");
        require(msg.value >= PROPOSAL_COST, "MISSING_FEE");

        // proposal is now funded and clock starts ticking
        _funded = true;
        _expiration = block.timestamp + MONTH;
        _funder = msg.sender;

        // create the vote tokens that will be used to vote on the proposal.
        INFTGemGovernor(_governor).createProposalVoteTokens(uint256(address(this)));

        // check for overpayment and if found then return remainder to user
        uint256 overpayAmount = msg.value.sub(PROPOSAL_COST);
        if (overpayAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: overpayAmount}("");
            require(success, "REFUND_FAILED");
        }
    }

    function execute() external override {
        // ensure we are funded and open and not executed
        require(_funded, "NOT_FUNDED");
        require(!_closed, "IS_CLOSED");
        require(!_executed, "IS_EXECUTED");
        require(_status() == ProposalStatus.PASSED, "IS_FAILED");

        // create the vote tokens that will be used to vote on the proposal.
        INFTGemGovernor(_governor).executeProposal(address(this));

        // this proposal is now executed
        _executed = true;

        // dewstroy the now-useless vote tokens used to vote for this proposal
        INFTGemGovernor(_governor).destroyProposalVoteTokens(uint256(address(this)));

        // refurn the filing fee to the funder of the proposal
        (bool success, ) = _funder.call{value: PROPOSAL_COST}("");
        require(success, "EXECUTE_FAILED");
    }

    function close() external override {
        // ensure we are funded and open and not executed
        require(_funded, "NOT_FUNDED");
        require(!_closed, "IS_CLOSED");
        require(!_executed, "IS_EXECUTED");
        require(block.timestamp > _expiration, "IS_ACTIVE");
        require(_status() == ProposalStatus.FAILED, "IS_PASSED");

        // this proposal is now closed - no action was taken
        _closed = true;

        // destroy the now-useless vote tokens used to vote for this proposal
        INFTGemGovernor(_governor).destroyProposalVoteTokens(uint256(address(this)));

        // send the proposal funder their filing fee back
        (bool success, ) = _funder.call{value: PROPOSAL_COST}("");
        require(success, "EXECUTE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IControllable {
    event ControllerAdded(address indexed contractAddress, address indexed controllerAddress);
    event ControllerRemoved(address indexed contractAddress, address indexed controllerAddress);

    function addController(address controller) external;

    function isController(address controller) external view returns (bool);

    function relinquishControl() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./IERC165.sol";

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

pragma solidity >=0.7.0;

import "../interfaces/IERC165.sol";

/**
 * _Available since v3.1._
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

pragma solidity >=0.7.0;

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

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTGemGovernor {
    event GovernanceTokenIssued(address indexed receiver, uint256 amount);
    event FeeUpdated(address indexed proposal, address indexed token, uint256 newFee);
    event AllowList(address indexed proposal, address indexed token, bool isBanned);
    event ProjectFunded(address indexed proposal, address indexed receiver, uint256 received);
    event StakingPoolCreated(
        address indexed proposal,
        address indexed pool,
        string symbol,
        string name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,
        address alllowedToken
    );

    function initialize(
        address _multitoken,
        address _factory,
        address _feeTracker,
        address _proposalFactory,
        address _swapHelper
    ) external;

    function createProposalVoteTokens(uint256 proposalHash) external;

    function destroyProposalVoteTokens(uint256 proposalHash) external;

    function executeProposal(address propAddress) external;

    function issueInitialGovernanceTokens(address receiver) external returns (uint256);

    function maybeIssueGovernanceToken(address receiver) external returns (uint256);

    function issueFuelToken(address receiver, uint256 amount) external returns (uint256);

    function createPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external returns (address);

    function createSystemPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external returns (address);

    function createNewPoolProposal(
        address,
        string memory,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external returns (address);

    function createChangeFeeProposal(
        address,
        string memory,
        address,
        address,
        uint256
    ) external returns (address);

    function createFundProjectProposal(
        address,
        string memory,
        address,
        string memory,
        uint256
    ) external returns (address);

    function createUpdateAllowlistProposal(
        address,
        string memory,
        address,
        address,
        bool
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTGemMultiToken {
    // called by controller to mint a claim or a gem
    function mint(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external;

    // called by controller to burn a claim
    function burn(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external;

    function allHeldTokens(address holder, uint256 _idx) external view returns (uint256);

    function allHeldTokensLength(address holder) external view returns (uint256);

    function allTokenHolders(uint256 _token, uint256 _idx) external view returns (address);

    function allTokenHoldersLength(uint256 _token) external view returns (uint256);

    function totalBalances(uint256 _id) external view returns (uint256);

    function allProxyRegistries(uint256 _idx) external view returns (address);

    function allProxyRegistriesLength() external view returns (uint256);

    function addProxyRegistry(address registry) external;

    function removeProxyRegistryAt(uint256 index) external;

    function getRegistryManager() external view returns (address);

    function setRegistryManager(address newManager) external;

    function lock(uint256 token, uint256 timeframe) external;

    function unlockTime(address account, uint256 token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface INFTGemPool {

    /**
     * @dev Event generated when an NFT claim is created using ETH
     */
    event NFTGemClaimCreated(address account, address pool, uint256 claimHash, uint256 length, uint256 quantity, uint256 amountPaid);

    /**
     * @dev Event generated when an NFT claim is created using ERC20 tokens
     */
    event NFTGemERC20ClaimCreated(
        address account,
        address pool,
        uint256 claimHash,
        uint256 length,
        address token,
        uint256 quantity,
        uint256 conversionRate
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemClaimRedeemed(
        address account,
        address pool,
        uint256 claimHash,
        uint256 amountPaid,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemERC20ClaimRedeemed(
        address account,
        address pool,
        uint256 claimHash,
        address token,
        uint256 ethPrice,
        uint256 tokenAmount,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when a gem is created
     */
    event NFTGemCreated(address account, address pool, uint256 claimHash, uint256 gemHash, uint256 quantity);

    function setMultiToken(address token) external;

    function setGovernor(address addr) external;

    function setFeeTracker(address addr) external;

    function setSwapHelper(address addr) external;

    function mintGenesisGems(address creator, address funder) external;

    function createClaim(uint256 timeframe) external payable;

    function createClaims(uint256 timeframe, uint256 count) external payable;

    function createERC20Claim(address erc20token, uint256 tokenAmount) external;

    function createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) external;

    function collectClaim(uint256 claimHash) external;

    function initialize(
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface INFTGemPoolFactory {
    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event NFTGemPoolCreated(
        string gemSymbol,
        string gemName,
        uint256 ethPrice,
        uint256 mintTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    );

    function getNFTGemPool(uint256 _symbolHash) external view returns (address);

    function allNFTGemPools(uint256 idx) external view returns (address);

    function allNFTGemPoolsLength() external view returns (uint256);

    function createNFTGemPool(
        string memory gemSymbol,
        string memory gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    ) external returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IProposal {
    enum ProposalType {CREATE_POOL, FUND_PROJECT, CHANGE_FEE, UPDATE_ALLOWLIST}

    enum ProposalStatus {NOT_FUNDED, ACTIVE, PASSED, FAILED, EXECUTED, CLOSED}

    event ProposalCreated(address creator, address pool, uint256 proposalHash);

    event ProposalExecuted(uint256 proposalHash);

    event ProposalClosed(uint256 proposalHash);

    function creator() external view returns (address);

    function title() external view returns (string memory);

    function funder() external view returns (address);

    function expiration() external view returns (uint256);

    function status() external view returns (ProposalStatus);

    function proposalData() external view returns (address);

    function proposalType() external view returns (ProposalType);

    function setMultiToken(address token) external;

    function setGovernor(address gov) external;

    function fund() external payable;

    function execute() external;

    function close() external;

    function initialize(
        address,
        string memory,
        address,
        ProposalType
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ICreatePoolProposalData {
    function data()
        external
        view
        returns (
            string memory,
            string memory,

            uint256,
            uint256,
            uint256,
            uint256,
            uint256,

            address
        );
}

interface IChangeFeeProposalData {
    function data()
        external
        view
        returns (
            address,
            address,
            uint256
        );
}

interface IFundProjectProposalData {
    function data()
        external
        view
        returns (
            address,
            string memory,
            uint256
        );
}

interface IUpdateAllowlistProposalData {
    function data()
        external
        view
        returns (
            address,
            address,
            bool
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


import "./IProposal.sol";

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IProposalFactory {
    /**
     * @dev emitted when a new gem pool proposal has been added to the system
     */
    event ProposalCreated(address creator, uint256 proposalType, address proposal);

    event ProposalFunded(uint256 indexed proposalHash, address indexed funder, uint256 expDate);

    event ProposalExecuted(uint256 indexed proposalHash, address pool);

    event ProposalClosed(uint256 indexed proposalHash, address pool);

    function getProposal(uint256 _symbolHash) external view returns (address);

    function allProposals(uint256 idx) external view returns (address);

    function allProposalsLength() external view returns (uint256);

    function createProposal(
        address submitter,
        string memory title,
        address proposalData,
        IProposal.ProposalType proposalType
    ) external returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

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
library SafeMath {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/IERC1155Receiver.sol";
import "../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
                ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {
    "src/factories/ProposalFactory.sol:ProposalFactory": {
      "GovernanceLib": "0x8B4207A13a5a13bDb2bBf15c137820e61e3c4AAc",
      "Strings": "0x98ccd9cb27398a6595f15cbc4b63ac525b942aad",
      "SafeMath": "0xD34a551B4a262230a373D376dDf8aADb2B0D49FD",
      "ProposalsLib": "0x54812b41409912bd065e9d3920ce196ff9bfc995",
      "Create2": "0xa511e209a01e27d134b4f564263f7db8fcbdeba6"
    }
  },
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 9999
  },
  "remappings": [],
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