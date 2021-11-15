pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/CountersUpgradeable.sol";

import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";

contract baseGETNFT_V6 is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    IEconomicsGET public ECONOMICS;
    
    function initialize_base(
        address address_bouncer, 
        address address_metadata, 
        address address_finance,
        address address_erc721,
        address address_economics
        ) public virtual initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            METADATA = IMetadataStorage(address_metadata);
            FINANCE = IEventFinancing(address_finance);
            GET_ERC721 = IGET_ERC721(address_erc721);
            ECONOMICS = IEconomicsGET(address_economics);
    }

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant GET_TEAM_MULTISIG = keccak256("GET_TEAM_MULTISIG");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    mapping (uint256 => TicketData) private _ticket_data;

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside;
        bool scanned;
        bool valid;
    }

    event primarySaleMint(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 indexed orderTime
    );

    event secondarySale(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address destinationAddress, 
        address eventAddress,
        uint256 secondaryPrice,
        uint256 indexed orderTime
    );

    event saleCollaterizedIntentory(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address underwriterAddress,
        address destinationAddress, 
        address eventAddress,
        uint256 primaryPrice,
        uint256 indexed orderTime
    );

    event ticketScanned(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        uint256 indexed orderTime
    );

    event ticketInvalidated(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address originAddress,
        uint256 indexed orderTime
    ); 

    event nftClaimed(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address externalAddress,
        uint256 indexed orderTime
    );

    event nftMinted(
        uint256 indexed nftIndex,
        address indexed destinationAddress, 
        uint _timestamp
    );

    event nftTokenURIEdited(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        string _netTokenURI,
        uint _timestamp
    );

    event illegalScan(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        uint256 indexed orderTime
    );

    /**
    @dev primary sale function, moves or mints getNFT to EOA of a ticket buyer
    @notice this function is always called by flusher when a primary sale takes place
    @notice internal logic (based on metadata of event) will determine the flow/code that is executed
    @param destinationAddress address of the ticket buyer (EOA)
    @param eventAddress address of the event (EOA)
    @param primaryPrice TODO
    @param orderTime TODO
    @param ticketURI TODO
    @param ticketMetadata TODO
    */
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 orderTime,
        string memory ticketURI, 
        bytes32[] memory ticketMetadata
    ) public returns (uint256 nftIndex) {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "primarySale: INCORRECT RELAYER");

        bool _state = false;
        _state = METADATA.isInventoryUnderwritten(eventAddress);

        // Ticket inventory is 'set aside' - getNFTs already minted, inventory of event is collateralized.
        if (_state == true) {  
            
            // fetch underWriter address from metadata contract
            address underwriterAddress = METADATA.getUnderwriterAddress(eventAddress);
            
            nftIndex = GET_ERC721.tokenOfOwnerByIndex(underwriterAddress, 0);

            require(_ticket_data[nftIndex].valid == true, "primarySale - NFT INVALIDATED"); 
            require(GET_ERC721.ownerOf(nftIndex) == underwriterAddress, "primarySale - INCORRECT UNDERWRITER");   

            // getNFT transfer is relayed to FINANCE contract, as to perform accounting
            FINANCE.collateralizedNFTSold(
                nftIndex,
                underwriterAddress,
                destinationAddress,
                orderTime,
                primaryPrice     
            );

            GET_ERC721.relayerTransferFrom(
                underwriterAddress, 
                destinationAddress, 
                nftIndex
            );

            // push/append colleterization price to getNFT 
            _ticket_data[nftIndex].prices_sold.push(primaryPrice);

            emit saleCollaterizedIntentory(
                nftIndex,
                10000, // placeholder GET usage
                underwriterAddress,
                destinationAddress, 
                eventAddress, 
                primaryPrice,
                orderTime
            );

            return nftIndex;

            } else {

                // Event NFT is created for is not colleterized, getNFT minted to user 
                nftIndex = _mintGETNFT( 
                    destinationAddress,
                    eventAddress,
                    primaryPrice,
                    orderTime,
                    ticketURI,
                    ticketMetadata,
                    false 
                );

                emit primarySaleMint(
                    nftIndex,
                    10000, 
                    destinationAddress,
                    eventAddress,
                    primaryPrice,
                    orderTime
                );

                // push/append primary market sale data to getNFT
                _ticket_data[nftIndex].prices_sold.push(primaryPrice);
        }

        return nftIndex;
            
    }

    /**
    @dev function relays mint transaction from FINANCE contract to internal function _mintGETNFT
    @notice this as to prevent a relayer ever calling directly, going around colleterization rules 
    @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param eventAddress primary key of event (EOA account)
    @param pricepaid TODO
    @param orderTime TODO
    @param ticketURI  TODO
    @param ticketMetadata TODO
    @param setAsideNFT TODO
    */
    function relayColleterizedMint(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string memory ticketURI,
        bytes32[] memory ticketMetadata,
        bool setAsideNFT
    ) public returns (uint256 nftIndex) {

        // check if FINANCE contract is allowed to mint getNFT
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "relayColleterizedMint: INCORRECT RELAYER");

        nftIndex = _mintGETNFT(
            destinationAddress,
            eventAddress,
            pricepaid,
            orderTime,
            ticketURI,
            ticketMetadata,
            setAsideNFT
        );
    }
    

    /**
    @dev mints getNFT
    @notice this function can be called internally, as well as externally (in case of event financing)
    @param destinationAddress TODO
    @param eventAddress TODO
    @param pricepaid TODO
    @param orderTime TODO
    @param ticketURI TODO
    @param ticketMetadata TODO
    @param setAsideNFT TODO
    */
    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string memory ticketURI,
        bytes32[] memory ticketMetadata,
        bool setAsideNFT
        ) internal returns(uint256 nftIndex) {

        nftIndex = GET_ERC721.mintERC721(
            destinationAddress,
            ticketURI
        );

        TicketData storage tdata = _ticket_data[nftIndex];
        tdata.ticket_metadata = ticketMetadata;
        tdata.event_address = eventAddress;
        tdata.set_aside = setAsideNFT;
        tdata.scanned = false;
        tdata.valid = true;
        
        emit nftMinted(
            nftIndex,
            destinationAddress, 
            block.timestamp
        );

        return nftIndex;
    }


    /**
    @dev edits URI of getNFT
    @notice select getNFT by address TODO POSSIBLY REMOVE/RETIRE
    @param originAddress TODO
    @param _newTokenURI TODO
    */
    function editTokenURIbyAddress(
        address originAddress,
        string memory _newTokenURI
        ) public {
            uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
            require(nftIndex >= 0, "editTokenURI !nftIndex");
            GET_ERC721.editTokenURI(nftIndex, _newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                10000,
                _newTokenURI,
                block.timestamp
            );
        }

    /**
    @dev edits URI of getNFT
    @notice select getNFT by the nftIndex
    @param nftIndex TODO
    @param _newTokenURI TODO
    */
    function editTokenURIbyIndex(
        uint256 nftIndex,
        string memory _newTokenURI
        ) public {
            require(nftIndex >= 0, "editTokenURI !nftIndex");
            GET_ERC721.editTokenURI(nftIndex, _newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                10000,
                _newTokenURI,
                block.timestamp
            );
        }


    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "secondaryTransfer: INCORRECT RELAYER");

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        require(nftIndex >= 0, "scanNFT !nftIndex");

        require(_ticket_data[nftIndex].valid == true, "secondaryTransfer: ALREADY INVALIDATED");
        require(GET_ERC721.ownerOf(nftIndex) == originAddress, "secondaryTransfer: INVALID NFT OWNER");     
        
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            destinationAddress, 
            nftIndex
        );

        emit secondarySale(
            nftIndex,
            10000, // placeholder GET usage
            destinationAddress, 
            _ticket_data[nftIndex].event_address, 
            secondaryPrice,
            orderTime
        );
    
    }

    function scanNFT(
        address originAddress, 
        uint256 orderTime
        ) public returns(bool) {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        require(nftIndex >= 0, "scanNFT !nftIndex");

        require(_ticket_data[nftIndex].valid == true, "scanNFT: NFT INVALIDATED");

        if (_ticket_data[nftIndex].scanned == true) {
            // The getNFT has already been scanned. It will be allowed, but emmitted to the nodes.
            emit illegalScan(
                nftIndex,
                1000,
                orderTime
            );
            return false; 
        }

        _ticket_data[nftIndex].scanned = true;

        emit ticketScanned(
            nftIndex,
            10000, // placeholder GET usage
            orderTime
        );

        return true;
    }

    function invalidateAddressNFT(
        address originAddress, 
        uint256 orderTime) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "invalidateAddressNFT: WRONG RELAYER");
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        require(nftIndex >= 0, "invalidateAddressNFT !nftIndex");

        require(_ticket_data[nftIndex].valid != false, "invalidateAddressNFT - ALREADY INVALIDATED");
        _ticket_data[nftIndex].valid = false;

        emit ticketInvalidated(
            nftIndex, 
            10000, // getused placeholder
            originAddress,
            orderTime
        );
    } 

    function claimgetNFT(
        address originAddress, 
        address externalAddress,
        uint256 orderTime) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "claimgetNFT: WRONG RELAYER");

        require(GET_ERC721.balanceOf(originAddress) != 0, "claimgetNFT: NO BALANCE");

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT
        require(nftIndex >= 0, "claimgetNFT !nftIndex");

        bool _claimable = isNFTClaimable(nftIndex, originAddress);

        require(_claimable == false, "claimgetNFT - ILLEGAL ClAIM");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        // emit event of successfull 
        emit nftClaimed(
            nftIndex,
            10000, // get usage placeholder
            externalAddress,
            orderTime
        );

        }

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {
        if (_ticket_data[nftIndex].valid == true) {
            return false;
        }
        if (_ticket_data[nftIndex].scanned == false) {
            return false;
        }
        if (GET_ERC721.ownerOf(nftIndex) != ownerAddress) {
            return false;
        }
        return true;
    }

    function ticketMetadata(address originAddress)
      public 
      virtual 
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      )
      {
          uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
          require(nftIndex >= 0, "scanNFT !nftIndex");
          

          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
          _ticketMetadata = tdata.ticket_metadata;
          _setAsideNFT = tdata.set_aside;
          _prices_sold = tdata.prices_sold;
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

import "./SafeMathUpgradeable.sol";

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

pragma solidity ^0.6.2;

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

