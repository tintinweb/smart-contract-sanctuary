/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// File contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}


// File contracts/libraries/Address.sol

pragma solidity 0.7.5;


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}


// File contracts/interfaces/IERC20.sol

pragma solidity 0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/SafeERC20.sol

pragma solidity 0.7.5;


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.7.5;

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


// File contracts/mocks/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.7.5;

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


// File contracts/interfaces/IERC1155.sol

pragma solidity ^0.7.5;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


// File contracts/OP1155/IParagonBondingTreasury.sol

pragma solidity 0.7.5;

interface IParagonBondingTreasury {
    function sendPDT(uint _amountPayoutToken) external;
    function valueOfToken( address _principalToken, uint _amount ) external view returns ( uint value_ );
    function PDT() external view returns (address);
}


// File contracts/types/Ownable.sol

pragma solidity 0.7.5;

contract Ownable {

    address public policy;

    constructor () {
        policy = msg.sender;
    }

    modifier onlyPolicy() {
        require( policy == msg.sender, "Ownable: caller is not the owner" );
        _;
    }
    
    function transferManagment(address _newOwner) external onlyPolicy() {
        require( _newOwner != address(0) );
        policy = _newOwner;
    }
}


// File contracts/OP1155/ParallelBondingContract.sol

pragma solidity 0.7.5;




/// @title   Parallel Bonding Contract
/// @author  JeffX
/// @notice  Bonding Parallel ERC1155s in return for PDT tokens
contract ParallelBondingContract is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    
    /// EVENTS ///

    /// @notice Emitted when A bond is created
    /// @param deposit Address of where bond is deposited to
    /// @param payout Amount of PDT to be paid out
    /// @param expires Block number bond will be fully redeemable
    event BondCreated( uint deposit, uint payout, uint expires );

    /// @notice Emitted when a bond is redeemed
    /// @param recipient Address receiving PDT
    /// @param payout Amount of PDT redeemed
    /// @param remaining Amount of PDT left to be paid out
    event BondRedeemed( address recipient, uint payout, uint remaining );

    
    /// STATE VARIABLES ///
    
    /// @notice Paragon DAO Token
    IERC20 immutable public PDT;
    /// @notice Parallel ERC1155
    IERC1155 immutable public LL;
    /// @notice Custom Treasury
    IParagonBondingTreasury immutable public customTreasury;
    /// @notice Olympus DAO address
    address immutable public olympusDAO;
    /// @notice Olympus treasury address
    address public olympusTreasury;

    /// @notice Total Parallel tokens that have been bonded
    uint public totalPrincipalBonded;
    /// @notice Total PDT tokens given as payout
    uint public totalPayoutGiven;
    /// @notice Vesting term in blocks
    uint public vestingTerm;
    /// @notice Percent fee that goes to Olympus
    uint public immutable olympusFee = 33300;

    /// @notice Array of IDs that have been bondable
    uint[] public bondedIds;

    /// @notice Bool if bond contract has been initialized
    bool public initialized;

    /// @notice Stores bond information for depositors
    mapping( address => Bond ) public bondInfo;

    /// @notice Stores bond information for a Parallel ID
    mapping( uint => IdDetails ) public idDetails;

    
    /// STRUCTS ///

    /// @notice           Details of an addresses current bond
    /// @param payout     PDT tokens remaining to be paid
    /// @param vesting    Blocks left to vest
    /// @param lastBlock  Last interaction
    struct Bond {
        uint payout;
        uint vesting;
        uint lastBlock;
    }

    /// @notice                   Details of an ID that is to be bonded
    /// @param bondPrice          Payout price of the ID
    /// @param remainingToBeSold  Remaining amount of tokens that can be bonded
    /// @param inArray            Bool if ID is in array that keeps track of IDs
    struct IdDetails {
        uint bondPrice;
        uint remainingToBeSold;
        bool inArray;
    }

    
    /// CONSTRUCTOR ///

    /// @param _customTreasury   Address of cusotm treasury
    /// @param _LL               Address of the Parallel token
    /// @param _olympusTreasury  Address of the Olympus treasury
    /// @param _initialOwner     Address of the initial owner
    /// @param _olympusDAO       Address of Olympus DAO
    constructor(
        address _customTreasury, 
        address _LL, 
        address _olympusTreasury,
        address _initialOwner, 
        address _olympusDAO
    ) {
        require( _customTreasury != address(0) );
        customTreasury = IParagonBondingTreasury( _customTreasury );
        PDT = IERC20( IParagonBondingTreasury(_customTreasury).PDT() );
        require( _LL != address(0) );
        LL = IERC1155( _LL );
        require( _olympusTreasury != address(0) );
        olympusTreasury = _olympusTreasury;
        require( _initialOwner != address(0) );
        policy = _initialOwner;
        require( _olympusDAO != address(0) );
        olympusDAO = _olympusDAO;
    }


    /// POLICY FUNCTIONS ///

    /// @notice              Initializes bond and sets vesting rate
    /// @param _vestingTerm  Vesting term in blocks
    function initializeBond(uint _vestingTerm) external onlyPolicy() {
        require(!initialized, "Already initialized");
        vestingTerm = _vestingTerm;
        initialized = true;
    }

    /// @notice          Updates current vesting term
    /// @param _vesting  New vesting in blocks
    function setVesting( uint _vesting ) external onlyPolicy() {
        require(initialized, "Not initalized");
        vestingTerm = _vesting;
    }

    /// @notice           Set bond price and how many to be sold for each ID
    /// @param _ids       Array of IDs that will be sold
    /// @param _prices    PDT given to bond correspond ID in `_ids`
    /// @param _toBeSold  Number of IDs looking to be acquired
    function setIdDetails(uint[] calldata _ids, uint[] calldata _prices, uint _toBeSold) external onlyPolicy() {
        require(_ids.length == _prices.length, "Lengths do not match");
        for(uint i; i < _ids.length; i++) {
            IdDetails memory idDetail = idDetails[_ids[i]];
            idDetail.bondPrice = _prices[i];
            idDetail.remainingToBeSold = _toBeSold;
            if(!idDetail.inArray) {
                bondedIds.push(_ids[i]);
                idDetail.inArray = true;
            }
            idDetails[_ids[i]] = idDetail;

        }
    }

    /// @notice                  Updates address to send Olympus fee to
    /// @param _olympusTreasury  Address of new Olympus treasury
    function changeOlympusTreasury(address _olympusTreasury) external {
        require( msg.sender == olympusDAO, "Only Olympus DAO" );
        olympusTreasury = _olympusTreasury;
    }

    /// USER FUNCTIONS ///
    
    /// @notice            Bond Parallel ERC1155 to get PDT tokens
    /// @param _id         ID number that is being bonded
    /// @param _amount     Amount of sepcific `_id` to bond
    /// @param _depositor  Address that PDT tokens will be redeemable for
    function deposit(uint _id, uint _amount, address _depositor) external returns (uint) {
        require(initialized, "Not initalized");
        require( idDetails[_id].bondPrice > 0 && idDetails[_id].remainingToBeSold >= _amount, "Not bondable");
        require( _amount > 0, "Cannot bond 0" );
        require( _depositor != address(0), "Invalid address" );

        uint payout;
        uint fee;

        (payout, fee) = payoutFor( _id ); // payout and fee is computed

        payout = payout.mul(_amount);
        fee = fee.mul(_amount);
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: vestingTerm,
            lastBlock: block.number
        });

        idDetails[_id].remainingToBeSold = idDetails[_id].remainingToBeSold.sub(_amount);

        totalPrincipalBonded = totalPrincipalBonded.add(_amount); // total bonded increased
        totalPayoutGiven = totalPayoutGiven.add(payout); // total payout increased

        customTreasury.sendPDT( payout.add(fee) );

        PDT.safeTransfer(olympusTreasury, fee);

        LL.safeTransferFrom( msg.sender, address(customTreasury), _id, _amount, "" ); // transfer principal bonded to custom treasury

        // indexed events are emitted
        emit BondCreated( _id, payout, block.number.add( vestingTerm ) );

        return payout; 
    }
    
    /// @notice            Redeem bond for `depositor`
    /// @param _depositor  Address of depositor being redeemed
    /// @return            Amount of PDT redeemed
    function redeem(address _depositor) external returns (uint) {
        Bond memory info = bondInfo[ _depositor ];
        uint percentVested = percentVestedFor( _depositor ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _depositor ]; // delete user info
            emit BondRedeemed( _depositor, info.payout, 0 ); // emit bond data
            PDT.safeTransfer( _depositor, info.payout );
            return info.payout;

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _depositor ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub( block.number.sub( info.lastBlock ) ),
                lastBlock: block.number
            });

            emit BondRedeemed( _depositor, payout, bondInfo[ _depositor ].payout );
            PDT.safeTransfer( _depositor, payout );
            return payout;
        }
        
    }

    /// VIEW FUNCTIONS ///
    
    /// @notice          Payout and fee for a specific bond ID
    /// @param _id       ID to get payout and fee for
    /// @return payout_  Amount of PDT user will recieve for bonding `_id`
    /// @return fee_     Amount of PDT Olympus will recieve for the bonding of `_id`
    function payoutFor( uint _id ) public view returns ( uint payout_, uint fee_) {
        uint price = idDetails[_id].bondPrice;
        fee_ = price.mul( olympusFee ).div( 1e6 );
        payout_ = price.sub(fee_);
    }

    /// @notice                 Calculate how far into vesting `_depositor` is
    /// @param _depositor       Address of depositor
    /// @return percentVested_  Percent `_depositor` is into vesting
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ];
        uint blocksSinceLast = block.number.sub( bond.lastBlock );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /// @notice                 Calculate amount of payout token available for claim by `_depositor`
    /// @param _depositor       Address of depositor
    /// @return pendingPayout_  Pending payout for `_depositor`
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }

    /// @notice  Returns all the ids that are bondable and the amounts that can be bonded for each
    /// @return  Array of all IDs that are bondable
    /// @return  Array of amount remaining to be bonded for each bondable ID
    function bondableIds() external view returns (uint[] memory, uint[] memory) {
        uint numberOfBondable;

        for(uint i = 0; i < bondedIds.length; i++) {
            uint id = bondedIds[i];
            (bool active,) = canBeBonded(id);
            if(active) numberOfBondable++;
        }

        uint256[] memory ids = new uint256[](numberOfBondable);
        uint256[] memory leftToBond = new uint256[](numberOfBondable);

        uint nonce;
        for(uint i = 0; i < bondedIds.length; i++) {
            uint id = bondedIds[i];
            (bool active, uint amount) = canBeBonded(id);
            if(active) {
                ids[nonce] = id;
                leftToBond[nonce] = amount;
                nonce++;
            }
        }

        return (ids, leftToBond);
    }

    /// @notice     Determines if `_id` can be bonded, and if so how much is left
    /// @param _id  ID to check if can be bonded
    /// @return     Bool if `_id` can be bonded
    /// @return     Amount of tokens that be bonded for `_id`
    function canBeBonded(uint _id) public view returns (bool, uint) {
        IdDetails memory idDetail = idDetails[_id];
        if(idDetail.bondPrice > 0 && idDetail.remainingToBeSold > 0) {
            return (true, idDetail.remainingToBeSold);
        } else {
            return (false, 0);
        }
    }

    
}