pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./interfaces/IwrapGETNFT.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IbaseGETNFT_V4.sol";
import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

contract getEventFinancing is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    IEconomicsGET public ECONOMICS;

    IbaseGETNFT_V4 public BASE;
    IwrapGETNFT public wrapNFT;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant GET_TEAM_MULTISIG = keccak256("GET_TEAM_MULTISIG");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    struct LoanStruct {
        address event_address; // address of event (primary key)
        address loaned_token_address; // ERC20 token address of loaned token
        address loaned_amount_token; // Total amound of token raised
        address debt_token_address; // er20 token address of published token
        address underwriter_address; // address of underwriter
        uint256 colleterized_inv_total; // total securitized
        uint256 active_nft_count; // current count of securitiztied
        // uint256 block_size; //  ??? 
        uint finalized_by_block;
        uint256 total_staked;
        // bool published_loan;
        bool finalized_loan; // default = false
    }

    function addLoanInfo(
        address _eventAddress,
        address _loanedTokenAddress,
        address _loanedTokenAmount,
        address _underwriterAddress,
        uint256 _collaterizedInvTotal,
        uint256 _stakedUnderwriter,
        uint _finalizedBy
    ) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "addLoanInfo: ILLEGAL RELAYER");

        // TODO if publishedLoad == True, revert
        // TODO if finalizedLoan == True, revert
        // TODO if finalizedBy > now, revert

        LoanStruct storage ldata = allProposalLoans[_eventAddress];
        ldata.event_address = _eventAddress;
        ldata.loaned_token_address = _loanedTokenAddress;
        ldata.loaned_amount_token = _loanedTokenAmount;
        ldata.debt_token_address = address(0);
        ldata.underwriter_address = _underwriterAddress;
        ldata.colleterized_inv_total = _collaterizedInvTotal;
        ldata.active_nft_count = 0;
        ldata.finalized_by_block = 1000; // placeholder
        ldata.total_staked = _stakedUnderwriter;
        ldata.finalized_by_block = _finalizedBy;
        ldata.finalized_loan = false;

        // emit something
    }

    function publishLoanOffer(
        address eventAddress
        ) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "addLoanInfo: ILLEGAL RELAYER");

        // require finalized = false
        // require current count = false
        // require _collaterizedInvTotal = Balance on eventAddress 

        } 

    mapping(address => LoanStruct) public allProposalLoans; // all loans that are still not published (no ERC20, no pool)
    mapping(address => LoanStruct) public allActiveLoans;
    mapping(address => LoanStruct) public allFinalizedLoans;

    event fromCollaterizedInventory(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 primaryPrice,
        uint256 orderTime,
        uint _timestamp
    );

    event txMintUnderwriter(
        address underwriterAddress,
        address eventAddress,
        uint256 ticketDebt,
        string ticketURI,
        uint256 orderTime,
        uint _timestamp
    );

    event BaseConfigured(
        address baseAddress,
        address requester
    );

    function initialize_event_financing(
        address address_bouncer
        ) public virtual initializer {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
        }

    function configureBase(address baseAddress) public {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "configureBase: WRONG RELAYER");
        BASE = IbaseGETNFT_V4(baseAddress);
        emit BaseConfigured(baseAddress, msg.sender);
    }


    /**
    @dev mints getNFT to underwriterAddress
    @dev function is called by primarySale
    @notice only called if the events ticket inventory is collaterized
    @notice this function requires an wrapping contract to be deployed
    */
    function mintColleterizedNFTTicket(
        address underwriterAddress, // equiv to destinationAddress in primarySale
        address eventAddress,
        uint256 orderTime,
        uint256 ticketDebt,
        string memory ticketURI,
        bytes32[] memory ticketMetadata
    ) public returns (uint256 nftIndex) {

        // TODO Should only be callable by relayer of an underwriter
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "mintToUnderwriter: WRONG RELAYER");

        nftIndex = BASE.relayColleterizedMint(
            eventAddress,  // 'to' address destinationAddress
            eventAddress,  // eventAddress (the nft belongs to this adres)
            ticketDebt, // value of ticket in currency
            orderTime,
            ticketURI,
            ticketMetadata,
            true // setAsideNFT is set to true
        );

        // TODO Add colleterization logic / wrapping logic

        emit txMintUnderwriter(
            underwriterAddress,
            eventAddress,
            ticketDebt,
            ticketURI,
            orderTime,
            block.timestamp
        );

        return nftIndex;

    }


    // Moves NFT from collateral contract adres to user 
    function collateralizedNFTSold(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 orderTime,
        uint256 primaryPrice
    ) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "mintToUnderwriter: WRONG RELAYER");

        // TODO insert logic that creates debt for underwriter

        // uint256 nftIndex = tokenOfOwnerByIndex(underwriterAddress, 0);
        // require(_ticketInfo[nftIndex].valid == false, "_primaryCollateralTransfer - NFT INVALIDATED");
        // require(ownerOf(nftIndex) == underwriterAddress, "_primaryCollateralTransfer - WRONG UNDERWRITER");     

        // getNFTBase.relayerTransferFrom(
        //     underwriterAddress, 
        //     destinationAddress, 
        //     nftIndex
        // );

        emit fromCollaterizedInventory(
            nftIndex,
            underwriterAddress,
            destinationAddress,
            primaryPrice,
            orderTime,
            block.timestamp
        );

    }
}

pragma solidity ^0.6.2;

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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

pragma solidity ^0.6.2;

import "./Initializable.sol";

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

pragma solidity ^0.6.2;

interface IwrapGETNFT {
    function depositNFTAndMintTokens(
        address eventAddress,
        uint256 amountNFTs,
        uint256 collaterizationPrice
    ) external;
 }

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;

interface IbaseGETNFT_V4 {
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 orderTime,
        string calldata ticketURI, 
        bytes32[] calldata ticketMetadata
    ) external returns (uint256 nftIndex);
    function relayColleterizedMint(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
    ) external returns(uint256);
    function editTokenURI(
        address originAddress,
        string calldata _newTokenURI
        ) external;
    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external;
    function scanNFT(
        address originAddress,
        uint256 orderTime
        ) external returns(bool);
    function invalidateAddressNFT(
        address originAddress,
        uint256 orderTime
        ) external;
    function claimgetNFT(
        address originAddress, 
        address externalAddress) external;
    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);
    function ticketMetadata(address originAddress)
      external 
      virtual 
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      );
}

pragma solidity ^0.6.2;

interface IMetadataStorage {

    function isInventoryUnderwritten(
        address eventAddress
    ) external view returns(
        bool isUnderwritten
    );

    function getUnderwriterAddress(
        address eventAddress
    ) external view returns(
        address underwriterAddress
    );

    event newEventRegistered(
      address indexed eventAddress, 
      string indexed eventName,
      uint256 indexed timestamp
    );

    event AccessControlSet(
      address requester,
      address new_accesscontrol
    );

    event UnderWriterSet(
      address eventAddress,
      address underWriterAddress,
      address requester
    );

}

pragma solidity ^0.6.2;

interface IEventFinancing {
    function mintColleterizedNFTTicket(
        address underwriterAddress, 
        address eventAddress,
        uint256 orderTime,
        uint256 ticketDebt,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata
    ) external;

    function collateralizedNFTSold(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 orderTime,
        uint256 primaryPrice
    ) external;

    event txMintUnderwriter(
        address underwriterAddress,
        address eventAddress,
        uint256 ticketDebt,
        string ticketURI,
        uint256 orderTime,
        uint _timestamp
    );

    event fromCollaterizedInventory(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 primaryPrice,
        uint256 orderTime,
        uint _timestamp
    );

    event BaseConfigured(
        address baseAddress,
        address requester
    );

}

pragma solidity ^0.6.2;

interface IGET_ERC721 {
    function mintERC721(
        address destinationAddress,
        string calldata ticketURI
    ) external returns(uint256);
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
        ) external view returns(uint256);
    function balanceOf(
        address owner
        ) external view returns(uint256);
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex
        ) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function editTokenURI(
        uint256 nftIndex,
        string calldata _newTokenURI
        ) external;
}

pragma solidity ^0.6.2;

interface IEconomicsGET {
    function editCoreAddresses(
        address _address_burn_new,
        address _address_treasury_new
    ) external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}