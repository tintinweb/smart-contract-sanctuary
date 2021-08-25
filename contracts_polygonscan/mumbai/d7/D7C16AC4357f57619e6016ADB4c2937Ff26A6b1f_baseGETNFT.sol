/**
 *Submitted for verification at polygonscan.com on 2021-08-24
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

// File: contracts/utils/SafeMathUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/utils/CountersUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
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

// File: contracts/interfaces/IGETAccessControl.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

// File: contracts/baseGETNFT.sol

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;











/**

                    ####
                  ###  ###
                ####     ###
              ###  ###    ###
            ####     ###    ###
          ###  ###     ###    ###
        ####     ###     ###   ##
      ###  ###     #################
     ###     ###     ###           ##
      ###      ###     ###         ##
        ###      ##########      ###
          ###      ######      ###
            ###      ##      ###
              ###          ###
                ###      ###
                  ###  ###
                    ####

           #####  ####  #####  
          #       #       #   
          #  ###  ####    #    
          #    #  #       #        
           #####  ####    #  
 
            GOT GUTS? GET PROTOCOL IS HIRING!
      -----------------------------------
         info (at) get-protocol (dot) io

*/

contract baseGETNFT is Initializable, ContextUpgradeable {
    IGETAccessControl private GET_BOUNCER;
    IGET_ERC721 private GET_ERC721;
    IMetadataStorage private METADATA;
    IEventFinancing private FINANCE;
    IEconomicsGET private ECONOMICS;
    IticketFuelDepotGET private DEPOT;

    using SafeMathUpgradeable for uint256;

    string public constant contractName = "baseGETNFT PLAYGROUND";
    string public constant contractVersion = "3";
    
    function _initialize_base(
        address address_bouncer, 
        address address_metadata, 
        address address_finance,
        address address_erc721,
        address address_economics,
        address address_fueldepot
        ) public virtual initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            METADATA = IMetadataStorage(address_metadata);
            FINANCE = IEventFinancing(address_finance);
            GET_ERC721 = IGET_ERC721(address_erc721);
            ECONOMICS = IEconomicsGET(address_economics);
            DEPOT = IticketFuelDepotGET(address_fueldepot);
            baseGETFee = 140000000;
    }

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    mapping (uint256 => TicketData) private _ticket_data;

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside; // true = collaterized ticket/nft
        bool scanned; // true = ticket is scanned, false = ticket is not scanned (so still scanable)
        bool valid; // true = ticket can be used,sold,claimed. false = ticket has been invalidated for whatever reason by issuer. 
    }

    uint64 private baseGETFee;

    function setBaseGETFee(uint64 newBaseGETFee) public onlyAdmin {
        baseGETFee = newBaseGETFee;
    }

    event ConfigurationChanged(
        address addressBouncer, 
        address addressMetadata, 
        address addressFinance,
        address addressERC721
    );

    event primarySaleMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint64 indexed orderTime
    );

    event secondarySale(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        address destinationAddress, 
        address eventAddress,
        uint256 secondaryPrice,
        uint64 indexed orderTime
    );

    event saleCollaterizedIntentory(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        address eventAddress,
        uint64 indexed orderTime
    );

    event ticketInvalidated(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        address originAddress,
        uint64 indexed orderTime
    ); 

    event nftClaimed(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        address externalAddress,
        uint64 indexed orderTime
    );

    event nftMinted(
        uint256 indexed nftIndex,
        address indexed destinationAddress
    );

    event nftTokenURIEdited(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        string netTokenURI
    );

    // event illegalScan(
    //     uint256 indexed nftIndex,
    //     uint64 indexed getUsed,
    //     uint64 indexed orderTime
    // );

    event illegalScan(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event NFTCheckedIn(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event NFTScanned(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event ConfigurationChangedEcon(
        address AddressEconomics,
        address DepotAddress
    );


    // MODIFIERS BASE_GETNFT //

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
            GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "CALLER_NOT_ADMIN");
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


    // MAINTENANCE FUNCTIONS

    function changeConfiguration(
        address newAddressBouncer,
        address newAddressMetadata,
        address newAddressFinance,
        address newAddressERC721
    ) external onlyAdmin {
        
        GET_BOUNCER = IGETAccessControl(newAddressBouncer);
        METADATA = IMetadataStorage(newAddressMetadata);
        FINANCE = IEventFinancing(newAddressFinance);
        GET_ERC721 = IGET_ERC721(newAddressERC721);

        emit ConfigurationChanged(
            newAddressBouncer,
            newAddressMetadata,
            newAddressFinance,
            newAddressERC721
        );
    }

    function changeConfigurationEcon(
        address newAddressEconomics,
        address newDepotAddress
    ) external onlyAdmin {
        
        ECONOMICS = IEconomicsGET(newAddressEconomics);
        DEPOT = IticketFuelDepotGET(newDepotAddress);

        emit ConfigurationChangedEcon(
            newAddressEconomics,
            newDepotAddress
        );
    }

   // OPERATIONAL TICKETING FUNCTIONS //

    /**
    @dev primary sale function, transfers or mints NFT to EOA of a primary market ticket buyer
    @notice function called directly by relayer or via financing contract
    @notice path determined by event config in metadata contract
    @param destinationAddress EOA address of the ticket buyer (GETcustody)
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
    @param primaryPrice price paid by primary ticket buyer in the local/event currenct
    @param basePrice price as charged to the ticketeer in USD 
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param ticketURI string stored in metadata of NFT
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 

    @return nftIndexP as assigned by the contract when minted
    */
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        string memory ticketURI, 
        bytes32[] memory ticketMetadata
    ) public onlyRelayer returns (uint256 nftIndexP) {

        // Event NFT is created for is not colleterized, getNFT minted to user 
        nftIndexP = _mintGETNFT( 
            destinationAddress,
            eventAddress,
            primaryPrice,
            ticketURI,
            ticketMetadata,
            false 
        );

        require(nftIndexP > 0, "PRIMARYMINT_NO_INDEX");

        // // fuel the tank of the NFT, passing on the base price
        // uint256 reserved = ECONOMICS.fuelBackpackTicketBackfill(
        //     nftIndexP,
        //     msg.sender,
        //     baseGETFee
        // );

        // // require(reserved > 0, "PRIMARYMINT_NO_GET_RESERVED");

        // // charge the protocol tax rate on the tank balance
        // uint256 charged = DEPOT.chargeProtocolTax(nftIndexP).div(100000000);
        // require(charged > 0, "PRIMARYMINT_NO_GET_FEE_PAID");

        emit primarySaleMint(
            nftIndexP,
            baseGETFee,
            destinationAddress,
            eventAddress,
            primaryPrice,
            uint64(orderTime)
        );

        return nftIndexP;
    }

    /** transfers a getNFT from EOA to EOA
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param secondaryPrice price paid for the getNFT on the secondary market
     */
    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) public onlyRelayer returns(uint256) {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(nftIndex > 0, "SECONDARY_NO_INDEX");

        // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);

        // require(charged > 0, "SECONDARY_NO_GET_FEE_PAID");
        require(isNFTSellable(nftIndex, originAddress), "RE/SALE_ERROR");

        _ticket_data[nftIndex].prices_sold.push(secondaryPrice);
        
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            destinationAddress, 
            nftIndex
        );

        emit secondarySale(
            nftIndex,
            baseGETFee,
            destinationAddress, 
            _ticket_data[nftIndex].event_address, 
            secondaryPrice,
            uint64(orderTime)
        );
        
        return nftIndex;
    
    }

    /** scans a getNFT, validates it, but DOES NOT MAKE NFT CLAIMABLE
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function checkIn(
        address originAddress, 
        uint256 orderTime
        ) public onlyRelayer {
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(nftIndex > 0, "SCAN_NO_INDEX");
        
        // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);

        // require(charged > 0, "SCAN_NO_GET_FEE_PAID");
        require(_ticket_data[nftIndex].valid == true, "SCAN_INVALID_TICKET");

        emit NFTCheckedIn(
            nftIndex,
            baseGETFee,
            uint64(orderTime)
        );

    }

    /** scanning the NFT
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator    
    
     */
    function scanNFT(
        address originAddress,
        uint256 orderTime
    ) public onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        require(nftIndex > 0, "SCAN_NO_INDEX");

        // check if ticket wasn't already invalidated / claimable
        require(_ticket_data[nftIndex].valid == true, "SCAN_INVALID_TICKET");

        if (_ticket_data[nftIndex].scanned == true) { // The getNFT was already in the scanned state (so a dubble scan was performed) 
            emit illegalScan(
                nftIndex,
                baseGETFee,
                uint64(orderTime)
            );
        } else { // valid scan - getNFT was unscanned
            _ticket_data[nftIndex].scanned = true;

            emit NFTScanned(
                nftIndex,
                baseGETFee,
                uint64(orderTime)
            );
        }
    }

    /** invalidates a getNFT, making it unusable and untransferrable
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    */
    function invalidateAddressNFT(
        address originAddress, 
        uint256 orderTime) public onlyRelayer {
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(nftIndex > 0, "INVALIDATE_NO_INDEX");

        // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);
        
        // require(charged > 0, "INVALIDATE_NO_GET_FEE_PAID");
        require(_ticket_data[nftIndex].valid == true, "DOUBLE_INVALIDATION");
        
        _ticket_data[nftIndex].valid = false;

        emit ticketInvalidated(
            nftIndex, 
            baseGETFee,
            originAddress,
            uint64(orderTime)
        );
    } 

    /** Claims a scanned and valid NFT to an external EOA address
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param externalAddress EOA address of user that is claiming the gtNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function claimgetNFT(
        address originAddress, 
        address externalAddress,
        uint256 orderTime) public onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT

        require(nftIndex > 0, "CLAIM_NO_INDEX");

        // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);

        // require(charged > 0, "CLAIM_NO_GET_FEE_PAID");
        require(isNFTClaimable(nftIndex, originAddress), "CLAIM_ERROR");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        emit nftClaimed(
            nftIndex,
            baseGETFee,
            externalAddress,
            uint64(orderTime)
        );

    }

    // /**
    // @dev function relays mint transaction from FINANCE contract to internal function _mintGETNFT
    // @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    // @param eventAddress EOA address of the event (GETcustody)
    // @param strikeValue price that will be paid by primary ticket buyer
    // @param basePrice price that can be used to charge a dynamic GET fee over a tickets base price 
    // @param orderTime timestamp the statechange was triggered in the system of the integrator
    // @param ticketURI string stored in metadata of NFT
    // @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    // */
    // function eventFinancingMint(
    //     address destinationAddress, 
    //     address eventAddress, 
    //     uint256 strikeValue,
    //     uint256 basePrice,
    //     uint256 orderTime,
    //     string memory ticketURI,
    //     bytes32[] memory ticketMetadata
    // ) public onlyRelayer returns (uint256 nftIndex) {

    //     // TODO NFT FIRST NEEDS TO BE FUELED
    //     // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);

    //     // require(charged > 0, "FINANCE_NO_GET_FEE_PAID");

    //     nftIndex = _mintGETNFT(
    //         eventAddress, // TAKE NOTE MINTING TO EVENT ADDRESS
    //         eventAddress,
    //         strikeValue,
    //         ticketURI,
    //         ticketMetadata,
    //         true
    //     );

    //     FINANCE.registerCollaterization(
    //         nftIndex,
    //         eventAddress,
    //         strikeValue
    //     );

    //     emit colleterizedMint(
    //         nftIndex,
    //         baseGETFee, 
    //         destinationAddress,
    //         eventAddress,
    //         strikeValue,
    //         uint64(orderTime)
    //     );

    //     return nftIndex;
    // }
    


    /**
    @dev internal getNFT minting function 
    @notice this function can be called internally, as well as externally (in case of event financing)
    @notice should only mint to EOA addresses managed by GETCustody
    @param destinationAddress EOA address that is the 'future owner' of a getNFT
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
    @param issuePrice the price the getNFT will be offered or collaterized at
    @param ticketURI string stored in metadata of NFT
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    @param setAsideNFT bool if a getNFT has been securitized 
    */
    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 issuePrice,
        string memory ticketURI,
        bytes32[] memory ticketMetadata,
        bool setAsideNFT
        ) onlyRelayer public returns(uint256 nftIndexM) {

        nftIndexM = GET_ERC721.mintERC721(
            destinationAddress,
            ticketURI
        );

        require(nftIndexM > 0, "MINT_NO_INDEX");

        TicketData storage tdata = _ticket_data[nftIndexM];
        tdata.ticket_metadata = ticketMetadata;
        tdata.event_address = eventAddress;
        tdata.prices_sold = [issuePrice];
        tdata.set_aside = setAsideNFT;
        tdata.scanned = false;
        tdata.valid = true;
        
        // emit nftMinted(
        //     nftIndexM,
        //     destinationAddress
        // );

        return nftIndexM;
    }


    /** edits URI of getNFT
    @notice select getNFT by address TODO POSSIBLY REMOVE/RETIRE
    @param originAddress originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyAddress(
        address originAddress,
        string memory newTokenURI
        ) public onlyRelayer {
            
            uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

            // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);

            // require(charged > 0, "EDIT_NO_GET_FEE_PAID");
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                baseGETFee,
                newTokenURI
            );
        }

    /** edits metadataURI stored in the getNFT
    @dev unused function can be commented
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyIndex(
        uint256 nftIndex,
        string memory newTokenURI
        ) public onlyRelayer {

            // uint256 charged = DEPOT.chargeProtocolTax(nftIndex).div(100000000);
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                baseGETFee,
                newTokenURI
            );
        }

    // VIEW FUNCTIONS 

    /** Returns if an getNFT can be claimed by an external EOA
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param ownerAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {

        if (_ticket_data[nftIndex].valid == true || _ticket_data[nftIndex].scanned == true) {
            if (GET_ERC721.ownerOf(nftIndex) == ownerAddress) {
                return true;
            }
        } else {
            return false;
        }
    }

    /** Returns if an getNFT can be resold
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param ownerAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTSellable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {

        if (_ticket_data[nftIndex].valid == true || _ticket_data[nftIndex].scanned == false) {
            if (GET_ERC721.ownerOf(nftIndex) == ownerAddress) {
                return true;
            }
        } else {
            return false;
        }
    }

    /** Returns getNFT metadata by current owner (EOA address)
    @param ownerAddress EOA address of the address that currently owns the getNFT
    @dev this function assumes the NFT is still owned by an address controlled by GETCustody. 
     */
    function ticketMetadataAddress(
        address ownerAddress)
      public virtual view returns (
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint256[] memory _prices_sold,
          bool _setAsideNFT,
          bool _scanned,
          bool _valid
      )
      {
          
          TicketData storage tdata = _ticket_data[GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0)];
          _eventAddress = tdata.event_address;
          _ticketMetadata = tdata.ticket_metadata;
          _prices_sold = tdata.prices_sold;
          _setAsideNFT = tdata.set_aside;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
      }

    function ticketMetadataIndex(
        uint256 nftIndex
    ) public view returns(
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint256[] memory _prices_sold,
          bool _setAsideNFT,
          bool _scanned,
          bool _valid
    ) 
    {
          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _ticketMetadata = tdata.ticket_metadata;
          _prices_sold = tdata.prices_sold;
          _setAsideNFT = tdata.set_aside;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
    }

    /**
    @param ownerAddress address of the owner of the getNFT
    @notice the ownerAddress of an active ticket is generally held by GETCustody
     */
    function addressToIndex(
        address ownerAddress
    ) public virtual view returns(uint256)
    {
        return GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0);
    }

    /** returns the metadata struct of the ticket (base data)
    @param nftIndex unique indentifier of getNFT
     */
    function returnStructTicket(
        uint256 nftIndex
    ) public view returns (TicketData memory)
    {
        return _ticket_data[nftIndex];
    }

}