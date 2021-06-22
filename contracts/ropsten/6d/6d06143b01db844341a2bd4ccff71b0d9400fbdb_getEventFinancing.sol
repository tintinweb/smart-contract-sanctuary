/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: contracts/utils/Initializable.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

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

// File: contracts/utils/ContextUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;


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

// File: contracts/interfaces/IwrapGETNFT.sol

pragma solidity >=0.5.0 <0.7.0;

interface IwrapGETNFT {
    function depositNFTAndMintTokens(
        address eventAddress,
        uint256 amountNFTs,
        uint256 collaterizationPrice
    ) external;
 }

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0 <0.7.0;

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

// File: contracts/interfaces/IbaseGETNFT.sol

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IbaseGETNFT {

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside;
        bool scanned;
        bool valid;
    }

    function returnStruct(
        uint256 nftIndex
    ) external view returns (TicketData memory);


    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
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

    function editTokenURIbyAddress(
        address originAddress,
        string calldata _newTokenURI
        ) external;

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external returns(uint256);

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
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      );

    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 issuePrice,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
        ) external returns(uint256);

}

// File: contracts/interfaces/IeventMetadataStorage.sol

pragma solidity >=0.5.0 <0.7.0;

interface IMetadataStorage {

    function registerEvent(
      address eventAddress,
      address integratorAccountPublicKeyHash,
      string calldata eventName, 
      string calldata shopUrl,
      string calldata imageUrl,
      bytes32[4] calldata eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] calldata eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool setAside, // -> false = default
      // bytes[] memory extraData
      bytes32[] calldata extraData,
      bool isPrivate
      ) external;


    function isInventoryUnderwritten(
        address eventAddress
    ) external view returns(bool);

    function getUnderwriterAddress(
        address eventAddress
    ) external view returns(address);

    function doesEventExist(
      address eventAddress
    ) external view returns(bool);

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

// File: contracts/interfaces/IgetEventFinancing.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEventFinancing {
    // function mintColleterizedNFTTicket(
    //     address underwriterAddress, 
    //     address eventAddress,
    //     uint256 orderTime,
    //     uint256 ticketDebt,
    //     string calldata ticketURI,
    //     bytes32[] calldata ticketMetadata
    // ) external;

    function registerCollaterization(
        uint256 nftIndex,
        address eventAddress,
        uint256 strikeValue
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

    event ticketCollaterized(
        uint256 nftIndex,
        address eventAddress
    );

}

// File: contracts/interfaces/IgetNFT_ERC721.sol

pragma solidity >=0.5.0 <0.7.0;

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
    function isNftIndex(
        uint256 nftIndex
    ) external view returns(bool);
}

// File: contracts/interfaces/IEconomicsGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEconomicsGET {
    function editCoreAddresses(
        address newBouncerAddress,
        address newFuelAddress,
        address newDepotAddress
    ) external;

    function getGETPrice() 
    external view returns(uint64);

    function balanceOfRelayer(
        address relayerAddress
    ) external;

    function setPriceGETUSD(
        uint256 newGETPrice)
        external;
    
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) external;

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns(uint256);

    function fuelBackpackTicketBackfill(
        uint256 nftIndex,
        address relayerAddress,
        uint256 baseGETFee
        ) external returns(bool);


    function calcBackpackValue(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    function calcBackpackGET(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint256 indexed amountPacked
    );

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

}

// File: contracts/interfaces/IticketFuelDepotGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IticketFuelDepotGET {

    function getActiveFuel() 
    external view returns(address);

    function calcNeededGET(
         uint256 dollarvalue)
         external view returns(uint256);

    function chargeProtocolTax(
        uint256 nftIndex
    ) external returns(uint256); 

    function fuelBackpack(
        uint256 nftIndex,
        uint256 amountBackpack
    ) external returns(bool);

    function swipeCollected() 
    external returns(uint256);

    function deductNFTTankIndex(
        uint256 nftIndex,
        uint256 amountDeduct
    ) external;

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

    event statechangeTaxed(
        uint256 nftIndex,
        uint256 GETTaxedAmount
    );

}

// File: contracts/interfaces/IGETAccessControl.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

// File: contracts/getEventFinancing.sol

pragma solidity >=0.5.0 <0.7.0;













contract getEventFinancing is Initializable, ContextUpgradeable {

    IGETAccessControl private GET_BOUNCER;
    IMetadataStorage private METADATA;
    IEconomicsGET private ECONOMICS;
    IbaseGETNFT private BASE;
    IwrapGETNFT private wrapNFT;
    IticketFuelDepotGET private DEPOT;

    string public constant contractName = "getEventFinancing";
    string public constant contractVersion = "1";

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");

    function _initialize_event_financing(
        address address_bouncer
        ) public virtual initializer 
        {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
        }

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

    mapping(address => LoanStruct) private allProposalLoans; // all loans that are still not published (no ERC20, no pool)
    mapping(address => LoanStruct) private allActiveLoans;
    mapping(address => LoanStruct) private allFinalizedLoans;

    event fromCollaterizedInventory(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 primaryPrice,
        uint256 orderTime,
        uint timestamp
    );

    event txMintUnderwriter(
        address underwriterAddress,
        address eventAddress,
        uint256 ticketDebt,
        string ticketURI,
        uint256 orderTime,
        uint timestamp
    );

    event ticketCollaterized(
        uint256 nftIndex,
        address eventAddress
    );

    event ConfigurationChanged(
        address addressBouncer, 
        address addressMetadata, 
        address addressEconomics,
        address addressBase
    );

    // MODIFIERS 

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY");
        _;
    }

    // CONTRACT ADMINSTRATION

    function changeConfiguration(
        address newAddressBouncer,
        address newAddressMetadata,
        address newAddressEconomics,
        address newAddressBase
    ) external onlyAdmin {
        
        GET_BOUNCER = IGETAccessControl(newAddressBouncer);
        METADATA = IMetadataStorage(newAddressMetadata);
        ECONOMICS = IEconomicsGET(newAddressEconomics);
        BASE = IbaseGETNFT(newAddressBase);

        emit ConfigurationChanged(
            newAddressBouncer,
            newAddressMetadata,
            newAddressEconomics,
            newAddressBase
        );
    }

    function addLoanInfo(
        address eventAddress,
        address loanedTokenAddress,
        address loanedTokenAmount,
        address underwriterAddress,
        uint256 collaterizedInvTotal,
        uint256 stakedUnderwriter,
        uint finalizedBy
    ) public onlyRelayer {

        LoanStruct storage ldata = allProposalLoans[eventAddress];
        ldata.event_address = eventAddress;
        ldata.loaned_token_address = loanedTokenAddress;
        ldata.loaned_amount_token = loanedTokenAmount;
        ldata.debt_token_address = address(0);
        ldata.underwriter_address = underwriterAddress;
        ldata.colleterized_inv_total = collaterizedInvTotal;
        ldata.active_nft_count = 0;
        ldata.finalized_by_block = 1000; // placeholder
        ldata.total_staked = stakedUnderwriter;
        ldata.finalized_by_block = finalizedBy;
        ldata.finalized_loan = false;
    }

    /**
    @dev function can only be called by a factory contract
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint - this is the index that is being collaterized 
    @param eventAddress unique identifier of the event, assigned by GETCustordy
    @param strikeValue value in USD of the nft when it is sold in the primary market, in the futere, ie strike value 
     */
    function registerCollaterization(
        uint256 nftIndex,
        address eventAddress,
        uint256 strikeValue
    ) external onlyFactory {


        emit ticketCollaterized(
            nftIndex,
            eventAddress
        );
    }


    // Moves NFT from collateral contract adres to user 
    function collateralizedNFTSold(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 orderTime,
        uint256 primaryPrice
    ) external onlyFactory {

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