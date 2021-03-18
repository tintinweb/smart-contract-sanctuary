/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// File: contracts\IERC165.sol

pragma solidity ^0.6.0;

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

// File: contracts\IERC1155.sol

pragma solidity ^0.6.0;


interface IERC1155 is IERC165{
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    
}

// File: contracts\ERC165.sol

pragma solidity ^0.6.0;


 abstract contract ERC165 is IERC165{
    
    bytes4 private constant interface_id = 0x01ffc9a7;
    
    mapping(bytes4 => bool)private supportedInterfaces;
    
    constructor()internal{
        //_registerInterface(interface_id);
    }
    
    function _registerInterface(bytes4 _interfaceId)internal virtual {
        require(_interfaceId != 0xffffffff,"Invalid interface id");
        supportedInterfaces[_interfaceId] = true;
    }
    
    function supportsInterface(bytes4 _interfaceId)public view override returns(bool){
        return supportedInterfaces[_interfaceId];
    }
    
}

// File: contracts\Math.sol

pragma solidity ^0.6.0;

contract SafeMath {
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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeSub(a, b, "SafeMath: subtraction overflow");
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
    function safeSub(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b <= a, error);
        uint256 c = a - b;
        return c;
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
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeDiv(a, b, "SafeMath: division by zero");
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
    function safeDiv(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b > 0, error);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function safeExponent(uint256 a,uint256 b) internal pure returns (uint256) {
        uint256 result;
        assembly {
            result:=exp(a, b)
        }
        return result;
    }
}
//pragma solidity  >=0.4.21 <0.6.0;

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
library Math {
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

// File: contracts\IERC1155Receiver.sol

pragma solidity >=0.6.0 <0.8.0;


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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// File: contracts\IERC1155Metadata.sol

pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Metadata is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: contracts\ERC1155Data.sol

pragma solidity ^0.6.0;






contract ERC1155Data is ERC165,IERC1155,IERC1155Metadata{
    using Math for uint;
    
    string private  _uri;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
    
    constructor(string memory uri_) public{
         _setURI(uri_);
        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }
       
        
        mapping(address => mapping(address => bool)) private operatorApproval;
        mapping(uint256 => mapping(address => uint256))public balances;
        
        function balanceOf(address _account,uint256 _id)external view override returns(uint256){
            require(_account != address(0),"ERC1155: balance query for the zero address");
            return balances[_id][_account];
        }
        
        function balanceOfBatch(address[]memory _accounts,uint256[] memory _ids)external view override returns(uint256[] memory){
            
            require(_accounts.length == _ids.length,"ERC1155: accounts and ids length vary");
            
            uint256[] memory batchBalance = new uint256[](_accounts.length);
            
            for(uint256 i = 0 ;i< _accounts.length; i++){
                 require(_accounts[i] != address(0),"ERC1155: balance query for the zero address");
                 batchBalance[i] =  balances[_ids[i]][_accounts[i]];
                
            }
            return batchBalance;
        }
        
        function setApprovalForAll(address _operator, bool _approved)external override{
            
             require(_operator != msg.sender,"ERC1155: Cannot approve the owner itself");
             
             operatorApproval[msg.sender][_operator] = _approved;
             emit ApprovalForAll(msg.sender, _operator, _approved);
        }
        
        function isApprovedForAll(address _account, address _operator)public view override returns(bool){
            return operatorApproval[_account][_operator];
        }
        
        function safeTransferFrom(address _from, address _to,uint256 _id,uint256 _amount, bytes calldata data)public override{
            require(_to != address(0),"ERC1155: transfer to zero address");
        
            require(_from == msg.sender || isApprovedForAll(_from,msg.sender),"ERC1155: the is sender not the owner nor approved");
            
            balances[_id][_from] = balances[_id][_from].sub(_amount,"ERC1155: insufficient balance for transfer");
            balances[_id][_to] = balances[_id][_to].add(_amount);
            
            emit TransferSingle(msg.sender, _from, _to, _id, _amount);

            _safeTransferCheck(msg.sender, _from, _to, _id, _amount, data);
            
        }
        
         function safeBatchTransferFrom(address _from, address _to,uint256[] memory _ids,uint256[] memory _amounts, bytes calldata data)public override
         {
            require(_to != address(0),"ERC1155: transfer to zero address");
            
            require(_from == msg.sender || isApprovedForAll(_from,msg.sender),"ERC1155: the is sender not the owner nor approved");
            
            for(uint i = 0;i< _ids.length;i++)
            {
                balances[_ids[i]][_from] = balances[_ids[i]][_from].sub(_amounts[i],"ERC1155: insufficient balance for transfer");
                balances[_ids[i]][_to] = balances[_ids[i]][_to].add(_amounts[i]);
             }
            
           emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
           
          _safeBatchTransferCheck(msg.sender, _from, _to, _ids, _amounts, data);
         }
         
         function _safeTransferCheck(address _operator,address _from , address _to,uint256 _id,uint256 _amount, bytes memory _data) internal{
             if(isContract(_to))
             {
                 try IERC1155Receiver(_to).onERC1155Received(_operator,_from,_id,_amount,_data)returns(bytes4 result){
                    if(result != IERC1155Receiver(_to).onERC1155Received.selector){
                        revert("ERC1155: IERC1155Receiver rejected tokens");
                    } 
                 } catch Error(string memory error) {
                    revert(error);
                } catch {
                    revert("ERC1155: transfer to non ERC1155Receiver implementer");
                }
             }
          }
         
         function _safeBatchTransferCheck(address _operator,address _from , address _to,uint256[] memory _ids,uint256[] memory  _amounts, bytes memory _data) internal{
             if(isContract(_to))
             {
                     try IERC1155Receiver(_to).onERC1155BatchReceived(_operator,_from,_ids,_amounts,_data)returns(bytes4 result){
                    if(result != IERC1155Receiver(_to).onERC1155BatchReceived.selector){
                        revert("ERC1155: IERC1155Receiver rejected tokens");
                    } 
                 } catch Error(string memory error) {
                    revert(error);
                } catch {
                    revert("ERC1155: transfer to non ERC1155Receiver implementer");
                }
             }
           }
           
           
          function _setURI(string memory _metauri)internal {
               _uri = _metauri;
               
           }
           
          function uri(uint256) external view override returns (string memory){
                   return _uri;
            }
               
           function isContract(address account) internal view returns (bool) {
                uint256 size;
                assembly { size := extcodesize(account) }
                return size > 0;
            }
    }

// File: contracts\ERC1155Receiver.sol

pragma solidity ^0.6.0;




contract ERC1155Receiver is ERC165,IERC1155Receiver{
    constructor()public{
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
            );
    }
    
    function onERC1155Received(address ,address ,uint256 ,uint256 ,bytes memory )public override returns(bytes4){
      return this.onERC1155Received.selector;   
    }
    
     function onERC1155BatchReceived(address ,address ,uint256[] memory ,uint256[] memory ,bytes memory )public override returns(bytes4){
      return this.onERC1155BatchReceived.selector;   
    }
    
}

// File: contracts\Constant.sol

pragma solidity ^0.6.0;
contract Constant {
    string constant ERR_CONTRACT_SELF_ADDRESS = "ERR_CONTRACT_SELF_ADDRESS";
    string constant ERR_ZERO_ADDRESS = "ERR_ZERO_ADDRESS";
    string constant ERR_NOT_OWN_ADDRESS = "ERR_NOT_OWN_ADDRESS";
    string constant ERR_VALUE_IS_ZERO = "ERR_VALUE_IS_ZERO";
    string constant ERR_AUTHORIZED_ADDRESS_ONLY = "ERR_AUTHORIZED_ADDRESS_ONLY";
    string constant ERR_NOT_ENOUGH_BALANCE = "ERR_NOT_ENOUGH_BALANCE";

    modifier notOwnAddress(address _which) {
        require(msg.sender != _which, ERR_NOT_OWN_ADDRESS);
        _;
    }

    // validates an address is not zero
    modifier notZeroAddress(address _which) {
        require(_which != address(0), ERR_ZERO_ADDRESS);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThisAddress(address _which) {
        require(_which != address(this), ERR_CONTRACT_SELF_ADDRESS);
        _;
    }

    modifier notZeroValue(uint256 _value) {
        require(_value > 0, ERR_VALUE_IS_ZERO);
        _;
    }
}

// File: contracts\Ownable.sol

pragma solidity ^0.6.0;


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
contract Ownable is Constant {
    
    address payable public owner;
    
    address payable public newOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _trasnferOwnership(msg.sender);
    }
    
    function _trasnferOwnership(address payable _whom) internal {
        emit OwnershipTransferred(owner,_whom);
        owner = _whom;
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, ERR_AUTHORIZED_ADDRESS_ONLY);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable _newOwner)
        external
        virtual
        notZeroAddress(_newOwner)
        onlyOwner
    {
        // emit OwnershipTransferred(owner, newOwner);
        newOwner = _newOwner;
    }
    
    function acceptOwnership() external
        virtual
        returns (bool){
            require(msg.sender == newOwner,"ERR_ONLY_NEW_OWNER");
            owner = newOwner;
            emit OwnershipTransferred(owner, newOwner);
            newOwner = address(0);
            return true;
        }
    
    
}

// File: contracts\Micon.sol

pragma solidity ^0.6.0;




abstract contract MiconStorage{
    uint256 constant MAX_EDITION = 10;
    
    uint256 internal miconId = 1;
    
    //Mapping
    mapping(uint256 => uint256[])public miconEditions;
    mapping(uint256 => mapping(uint256 => address))public editionOwner;
    mapping(uint256 => address)public miconCreator;
    mapping(uint256 => mapping(uint256 => address[]))public previouslyOwnedEditionOwners;
    mapping(uint256 => bool)public editionExists;
    mapping(uint256 => address)public miconOwner; // only for micon with no editions
    
    
    //Events
    event MiconCreated(
     address indexed _miconCreator,
     uint256 _miconId,
     uint256 _miconCreationDate
    );
    
    event Edition(
     address indexed _editionOwner,
     address indexed _newEditionOwner,
     uint256 _miconId,
     uint256 _editionId
    );
   
}
    
contract Micon is ERC1155Data,MiconStorage,ERC1155Receiver,Ownable{
    constructor()public ERC1155Data(""){}
   
     /*
     * @dev To create the micon.
     * 
     * @param
     *  '_supply' - specifies number of supply
     */
    function createMicon(uint256 _supply)external onlyOwner(){
         require(_supply != 0 && _supply <= MAX_EDITION,"ERR_EDITION_SHOULD_BE_BETWEEN_1_AND_10");
         miconCreator[miconId] = msg.sender;
        _mintEditions(miconId,_supply);
         emit MiconCreated(address(this),miconId,now);
         miconId++;
    }
    
    //To mint the editions of micon
    function _mintEditions(uint256 _miconId,uint256 _supply)internal{
        if(_supply > 1){
            
               for(uint256 i = 1; i <= _supply; i++){
                miconEditions[_miconId].push(i);
                editionOwner[_miconId][i] = address(this);
                editionExists[_miconId] = true;
            } 
        }
        else{
             miconOwner[miconId] = address(this);
        }
        balances[_miconId][ address(this)] = _supply;
    }
    
    /*
     * @dev To buy the edition of micon.
     * 
     * @param
     *  '_miconId' - specifies the micon id
     *  '_editionNumber' - specifies the edition number of the micon
     */
    function buyEdition(uint256 _miconId, uint256 _editionNumber)external{
        address buyer = msg.sender;
        
        require(_exists(_miconId),"ERR_MICON_DOESNOT_EXISTS");
       
        require(_editionNumber <= miconEditions[_miconId].length,"ERR_EDITION_NUMBER_MISMATCH");
        require(balances[_miconId][buyer] < 1,"ERR_CAN_OWN_ONLY_1_EDITION");
        require(ownerOfEdition(_miconId,_editionNumber) == address(this) || miconOwner[_miconId] == address(this),"ERR_EDITION_ALREADY_SOLD_OR_DOESNOT_EXISTS");
        IERC1155(address(this)).safeTransferFrom(address(this),buyer,_miconId,1,"");
        
        if(editionExists[_miconId]) 
        {
            editionOwner[_miconId][_editionNumber] = buyer;
        }
        else{
            miconOwner[_miconId] = buyer;
            
        }
        emit Edition(address(this),buyer,_miconId,_editionNumber);
    }
    
    //To determine whether micon exists or not
    function _exists(uint256 _miconId) internal view returns (bool) {
       return miconCreator[_miconId] != address(0);
    }
     
     /*
     * @dev To sell the edition of micon.
     * 
     * @param
     *  '_miconId' - specifies the micon id
     *  '_editionNumber' - specifies the edition number of the micon
     */
    function sellEdition(uint256 _miconId, uint256 _editionNumber)external{
        address  seller = msg.sender ;
        
        require(_exists(_miconId),"ERR_MICON_DOESNOT_EXISTS");
        
        if(editionExists[_miconId])
        {
           require(ownerOfEdition(_miconId,_editionNumber) == seller,"ERR_NOT_AN_OWNER_OF_EDITION"); 
           IERC1155(address(this)).safeTransferFrom(seller,address(this),_miconId,1,"");
           editionOwner[_miconId][_editionNumber] = address(this);
        
        }
        else{
             IERC1155(address(this)).safeTransferFrom(seller,address(this),_miconId,1,"");
             miconOwner[_miconId] = address(this);
        }
        previouslyOwnedEditionOwners[_miconId][_editionNumber].push(seller);
        emit Edition(seller,address(this),_miconId,_editionNumber);
    }
    
    // To retrieve the owner of edition of micon.
    function ownerOfEdition(uint256 _miconId , uint256 _editionNumber)internal view returns(address){
       return editionOwner[_miconId][_editionNumber];
    }

}